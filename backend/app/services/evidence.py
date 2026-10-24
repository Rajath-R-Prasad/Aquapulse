"""Repair evidence (6.5, 10.4): signed URLs, registration with geotag check, submit validation, post-repair check."""
from __future__ import annotations

import asyncio
import uuid
from datetime import datetime, timedelta, timezone
from uuid import UUID

import pandas as pd
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db import fetchall, fetchone, get_setting
from app.schemas.common import unprocessable
from app.services.features import DEFAULT_DQ_STD, local_hour_dow

ALLOWED_MIME = {"image/jpeg": "jpg", "image/png": "png"}
EXT_MIME = {"jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png"}


def _client():
    from supabase import create_client

    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def object_path(storage_path: str) -> str:
    """'repair-evidence/<wo>/<uuid>.jpg' -> '<wo>/<uuid>.jpg' (path inside the bucket)."""
    prefix = settings.evidence_bucket + "/"
    return storage_path[len(prefix):] if storage_path.startswith(prefix) else storage_path


async def create_upload_url(work_order_id: UUID, mime_type: str, size_bytes: int) -> dict:
    cfg = await get_setting("evidence")
    if mime_type not in ALLOWED_MIME:
        raise unprocessable("evidence-bad-type", "Unsupported file type", "Only JPEG or PNG photos are accepted")
    if size_bytes > cfg["max_size_mb"] * 1024 * 1024:
        raise unprocessable("evidence-too-large", "File too large", f"Photos may be at most {cfg['max_size_mb']} MB")
    obj = f"{work_order_id}/{uuid.uuid4()}.{ALLOWED_MIME[mime_type]}"

    def _make() -> dict:
        return _client().storage.from_(settings.evidence_bucket).create_signed_upload_url(obj)

    res = await asyncio.to_thread(_make)
    return {"path": obj, "storage_path": f"{settings.evidence_bucket}/{obj}",
            "token": res.get("token"), "signed_url": res.get("signed_url") or res.get("signedUrl"),
            "bucket": settings.evidence_bucket}


async def signed_download_urls(paths: list[str], ttl_s: int = 900) -> dict[str, str | None]:
    def _make() -> dict[str, str | None]:
        bucket = _client().storage.from_(settings.evidence_bucket)
        out = {}
        for p in paths:
            try:
                r = bucket.create_signed_url(object_path(p), ttl_s)
                out[p] = r.get("signedURL") or r.get("signedUrl")
            except Exception:
                out[p] = None
        return out

    return await asyncio.to_thread(_make) if paths else {}


async def register(s: AsyncSession, wo: dict, event_id: UUID, user_id: UUID, body) -> dict:
    cfg = await get_setting("evidence")
    ext = body.storage_path.rsplit(".", 1)[-1].lower() if "." in body.storage_path else ""
    mime = body.mime_type or EXT_MIME.get(ext)
    if mime not in ALLOWED_MIME:
        raise unprocessable("evidence-bad-type", "Unsupported file type", "Only JPEG or PNG photos are accepted")
    if not body.storage_path.removeprefix(settings.evidence_bucket + "/").startswith(f"{wo['id']}/"):
        raise unprocessable("evidence-wrong-path", "Wrong storage path", "Path must be under this work order's folder")
    dist = geo_valid = None
    if body.lat is not None and body.lon is not None:
        dist = await s.scalar(text(
            "select ST_Distance(ST_SetSRID(ST_MakePoint(:lon,:lat),4326)::geography, location) from leak_events where id=:e"),
            {"lon": body.lon, "lat": body.lat, "e": event_id})
        dist = float(dist) if dist is not None else None
        geo_valid = dist is not None and dist <= cfg["max_distance_m"]
    else:
        geo_valid = False
    row = await fetchone(s, """
        insert into repair_evidence (work_order_id, kind, storage_path, mime_type, size_bytes, sha256, captured_at,
                                     captured_location, distance_to_leak_m, geo_valid, uploaded_by)
        values (:w, CAST(:k AS evidence_kind), :sp, :mt, :sz, :sha, :ca,
                case when CAST(:lat AS double precision) is null then null
                     else ST_SetSRID(ST_MakePoint(CAST(:lon AS double precision), CAST(:lat AS double precision)),4326)::geography end,
                :d, :g, :u)
        on conflict (storage_path) do update set captured_at = excluded.captured_at
        returning id, kind::text as kind, storage_path, distance_to_leak_m, geo_valid, captured_at""",
        {"w": wo["id"], "k": body.kind, "sp": body.storage_path, "mt": mime, "sz": body.size_bytes, "sha": body.sha256,
         "ca": body.captured_at, "lat": body.lat, "lon": body.lon, "d": dist, "g": geo_valid, "u": user_id})
    return row  # type: ignore[return-value]


async def validate_for_submit(
    s: AsyncSession,
    wo: dict,
    evidence_ids: list[UUID] | None,
    *,
    allow_location_override: bool = False,
) -> None:
    """422 unless: >=1 BEFORE and >=1 AFTER photo, each captured on/after arrival and within the distance limit."""
    cfg = await get_setting("evidence")
    q = "select id, kind::text as kind, captured_at, distance_to_leak_m, geo_valid from repair_evidence where work_order_id=:w"
    params: dict = {"w": wo["id"]}
    if evidence_ids:
        q += " and id = any(:ids)"
        params["ids"] = list(evidence_ids)
    rows = await fetchall(s, q, params)
    kinds = {r["kind"] for r in rows}
    missing = [k for k in ("BEFORE_PHOTO", "AFTER_PHOTO") if k not in kinds]
    if missing:
        raise unprocessable("evidence-missing", "Required evidence is missing",
                            f"Missing: {', '.join(missing)}", [{"missing_kind": k} for k in missing])
    far = [] if allow_location_override else [r for r in rows if not r["geo_valid"]]
    if far:
        n = len(far)
        worst = max((float(r["distance_to_leak_m"]) for r in far if r["distance_to_leak_m"] is not None), default=None)
        detail = (f"{n} of {len(rows)} photos failed the location check"
                  + (f" (up to {worst:.0f} m from the leak location, limit {cfg['max_distance_m']:.0f} m)." if worst else
                     " (no capture position supplied)."))
        raise unprocessable("evidence-geotag-too-far", "Evidence location too far from leak", detail,
                            [{"evidence_id": str(r["id"]),
                              "distance_m": float(r["distance_to_leak_m"]) if r["distance_to_leak_m"] is not None else None}
                             for r in far])
    arrived = wo.get("arrived_at")
    if arrived:
        early = [r for r in rows if r["captured_at"] is None or r["captured_at"] < arrived]
        if early:
            raise unprocessable("evidence-before-arrival", "Evidence captured before arrival",
                                "Photos must be captured at or after the arrival time",
                                [{"evidence_id": str(r["id"])} for r in early])


async def post_repair_check(s: AsyncSession, wo: dict, event: dict) -> dict:
    """Readings comparison shown to the approver (10.5)."""
    if event["source"] == "TWIN":
        return {"status": "NOT_APPLICABLE_SIMULATED"}
    if not wo.get("submitted_at"):
        return {"status": "INSUFFICIENT_DATA", "reason": "not submitted"}
    start = wo["submitted_at"]
    end = min(start + timedelta(minutes=5), datetime.now(timezone.utc))
    rows = await fetchall(s, """select recorded_at, flow_in_lpm, flow_out_lpm, pressure_in_kpa from hw_readings
                                where pipe_id=:p and recorded_at between :a and :b""",
                          {"p": event["pipe_id"], "a": start, "b": end})
    if len(rows) < 3:
        return {"status": "INSUFFICIENT_DATA", "samples": len(rows), "window_start": start.isoformat()}
    df = pd.DataFrame(rows)
    hour, dow = local_hour_dow(end)
    base = await fetchone(s, "select * from pipe_baselines where pipe_id=:p and source='HARDWARE' and dow=:d and hour=:h",
                          {"p": event["pipe_id"], "d": dow, "h": hour}) or {}
    b_mean = base.get("delta_q_mean_lpm") or 0.0
    b_std = base.get("delta_q_std_lpm") or DEFAULT_DQ_STD
    resid = float((df["flow_in_lpm"] - df["flow_out_lpm"]).mean() - b_mean)
    p_mean = base.get("pressure_in_mean_kpa")
    pdev = float((df["pressure_in_kpa"].mean() - p_mean) / p_mean * 100) if p_mean else 0.0
    ok = abs(resid) <= 2 * b_std and abs(pdev) <= 5
    return {"status": "PASS" if ok else "FAIL", "mean_delta_q_resid_lpm": resid, "baseline_delta_q_std_lpm": b_std,
            "pressure_dev_pct": pdev, "samples": len(rows), "window_start": start.isoformat(), "window_end": end.isoformat()}
