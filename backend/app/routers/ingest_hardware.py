"""Tunnel A: ESP32 -> FastAPI (6.1). Per-device bearer token; source = HARDWARE."""
from __future__ import annotations

import math
from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from pydantic import ValidationError
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, after_commit, as_json, dumps, fetchone, get_session
from app.schemas.common import ProblemException, forbidden, unprocessable
from app.schemas.hardware import HWBatch, HWMessage
from app.security import device_auth, device_rate_limiter, max_body
from app.services.normalize import SENSOR_COLUMN, normalize_reading
from app.workers import evaluator

router = APIRouter(prefix="/v1/ingest/hardware", tags=["Tunnel A: hardware"], route_class=TransactionalRoute)

MAX_CLOCK_SKEW_S = 300


def _calibrate(sensor: str, value: float, cal: dict) -> float:
    c = cal.get(sensor) or {}
    gain = float(c.get("gain", 1.0))
    offset = float(c.get("offset_lpm", c.get("offset_kpa", c.get("offset", 0.0))))
    return value * gain + offset


async def ingest_one(s: AsyncSession, device: dict, msg: HWMessage) -> dict:
    """Validates, normalises and stores one message. Raises ProblemException for 403/409/422."""
    if msg.device_uid != device["device_uid"]:
        raise forbidden("device_uid does not match the token")
    pipe = await fetchone(s, "select id, monitoring::text as monitoring from pipe_segments where id = :p", {"p": device["pipe_id"]})
    if pipe["monitoring"] == "SIMULATED":
        raise ProblemException(409, "device-mapped-to-simulated-pipe", "Device mapped to a SIMULATED pipe",
                               "This device is registered on a pipe whose monitoring mode is SIMULATED. Fix the registration.")
    server_now = datetime.now(timezone.utc)
    ts_uncertain = msg.ts is None
    recorded = server_now
    if msg.ts is not None:
        t = msg.ts if msg.ts.tzinfo else msg.ts.replace(tzinfo=timezone.utc)
        if abs((t - server_now).total_seconds()) > MAX_CLOCK_SKEW_S:
            ts_uncertain = True                  # replay / bad clock: store server time and mark UNCERTAIN
        else:
            recorded = t

    cal = as_json(device.get("calibration")) or {}
    values: dict[str, float | None] = {c: None for c in SENSOR_COLUMN.values()}
    quality: dict[str, str] = {}
    for r in msg.readings:
        if r.sensor in quality:
            raise unprocessable("duplicate-sensor", "Duplicate sensor", f"{r.sensor} appears twice in one message")
        v, ok = normalize_reading(r.sensor, r.value, r.unit)
        v = _calibrate(r.sensor, v, cal)
        q = r.quality
        if not ok or not math.isfinite(v):
            q = "BAD"                            # out of range: stored, excluded from detection
        elif ts_uncertain and q == "GOOD":
            q = "UNCERTAIN"
        values[SENSOR_COLUMN[r.sensor]] = v if math.isfinite(v) else None
        quality[r.sensor] = q

    row = await fetchone(s, """
        insert into hw_readings (device_id, pipe_id, boot_id, seq, recorded_at, flow_in_lpm, flow_out_lpm, pressure_in_kpa,
                                 pressure_out_kpa, acoustic_rms, quality, edge, health)
        values (:d, :p, :b, :q, :t, :fi, :fo, :pi, :po, :ac, CAST(:ql AS jsonb), CAST(:e AS jsonb), CAST(:h AS jsonb))
        on conflict (device_id, boot_id, seq) do nothing returning id""",
        {"d": device["id"], "p": device["pipe_id"], "b": msg.boot_id, "q": msg.seq, "t": recorded,
         "fi": values["flow_in_lpm"], "fo": values["flow_out_lpm"], "pi": values["pressure_in_kpa"],
         "po": values["pressure_out_kpa"], "ac": values["acoustic_rms"], "ql": dumps(quality),
         "e": dumps(msg.edge.model_dump()) if msg.edge else None,
         "h": dumps(msg.health.model_dump()) if msg.health else None})
    if row is None:                              # unique (device, boot_id, seq): duplicate
        dup = await fetchone(s, "select id from hw_readings where device_id = :d and boot_id = :b and seq = :q",
                             {"d": device["id"], "b": msg.boot_id, "q": msg.seq})
        return {"status": "duplicate", "reading_id": dup["id"] if dup else None}

    await s.execute(text("""
        update devices set last_seen_at = now(),
               status = case when status in ('PROVISIONED','OFFLINE') then 'ONLINE'::device_status else status end,
               firmware_version = coalesce(:fw, firmware_version)
        where id = :d"""), {"fw": msg.fw, "d": device["id"]})
    if msg.position:
        lon, lat = msg.position.coordinates[:2]
        await s.execute(text("update devices set position = ST_SetSRID(ST_MakePoint(:lon,:lat),4326)::geography where id = :d"),
                        {"lon": lon, "lat": lat, "d": device["id"]})
    await s.execute(text("""
        insert into signal_latest (pipe_id, source, ts, flow_in_lpm, flow_out_lpm, pressure_in_kpa, pressure_out_kpa, acoustic_rms)
        values (:p, 'HARDWARE', :t, :fi, :fo, :pi, :po, :ac)
        on conflict (pipe_id, source) do update set ts = excluded.ts, flow_in_lpm = excluded.flow_in_lpm,
          flow_out_lpm = excluded.flow_out_lpm, pressure_in_kpa = excluded.pressure_in_kpa,
          pressure_out_kpa = excluded.pressure_out_kpa, acoustic_rms = excluded.acoustic_rms
        where signal_latest.ts <= excluded.ts"""),
        {"p": device["pipe_id"], "t": recorded, "fi": values["flow_in_lpm"], "fo": values["flow_out_lpm"],
         "pi": values["pressure_in_kpa"], "po": values["pressure_out_kpa"], "ac": values["acoustic_rms"]})
    if device["status"] != "MAINTENANCE":
        pipe_id = device["pipe_id"]
        after_commit(s, lambda: evaluator.mark_dirty(pipe_id, "HARDWARE"))
    return {"status": "accepted", "reading_id": row["id"]}


@router.post("/readings", status_code=202, dependencies=[Depends(max_body(16 * 1024))],
             summary="Single reading (6.1)")
async def post_reading(msg: HWMessage, device: dict = Depends(device_auth), s: AsyncSession = Depends(get_session)):
    device_rate_limiter.check(device["device_uid"])
    res = await ingest_one(s, device, msg)
    return JSONResponse(status_code=202, content={
        **res, "server_time": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "config": {"report_interval_s": device["report_interval_s"]}, "commands": []})


@router.post("/readings/batch", status_code=200, dependencies=[Depends(max_body(512 * 1024))],
             summary="Up to 50 buffered readings (per-message results)")
async def post_batch(batch: HWBatch, device: dict = Depends(device_auth), s: AsyncSession = Depends(get_session)):
    results = []
    for raw in batch.messages:
        seq = raw.get("seq") if isinstance(raw, dict) else None
        try:
            msg = HWMessage.model_validate(raw)
            async with s.begin_nested():             # one bad message must not poison the rest
                res = await ingest_one(s, device, msg)
            results.append({"seq": msg.seq, **res})
        except ValidationError as exc:
            results.append({"seq": seq, "status": "rejected", "status_code": 422,
                            "error": "; ".join(f"{'.'.join(map(str, e['loc']))}: {e['msg']}" for e in exc.errors())})
        except ProblemException as exc:
            results.append({"seq": seq, "status": "rejected", "status_code": exc.status, "error": exc.detail or exc.title})
    return {"results": results, "server_time": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
            "config": {"report_interval_s": device["report_interval_s"]}}


@router.get("/config", summary="Interval and calibration for the calling device")
async def get_config(device: dict = Depends(device_auth)):
    return {"report_interval_s": device["report_interval_s"], "calibration": as_json(device.get("calibration")) or {}}
