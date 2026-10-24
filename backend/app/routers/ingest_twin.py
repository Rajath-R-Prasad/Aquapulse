"""Tunnel B: digital twin <-> FastAPI (6.2, 6.3). Service token with scope `twin`; source = TWIN."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, after_commit, as_json, dumps, fetchall, fetchone, get_session
from app.schemas.common import conflict, not_found, unprocessable
from app.schemas.events import ClearLeakBody, InjectLeakBody
from app.schemas.twin import TwinAck, TwinRunBody, TwinSnapshot
from app.security import CurrentUser, admin_user, twin_auth
from app.services import twin_sync
from app.services.normalize import UnitError, to_canonical
from app.services.state import log_event
from app.workers import evaluator

router = APIRouter(tags=["Tunnel B: digital twin"], route_class=TransactionalRoute)


@router.post("/v1/ingest/twin/runs", summary="Start or stop a simulation run")
async def twin_run(body: TwinRunBody, _: str = Depends(twin_auth), s: AsyncSession = Depends(get_session)):
    if body.action == "START":
        row = await fetchone(s, "insert into twin_runs (name, scenario, network_version) values (:n, :sc, :nv) "
                                "returning id, status, started_at",
                             {"n": body.name or "run", "sc": body.scenario, "nv": body.network_version})
        return {"run_id": row["id"], "status": row["status"], "started_at": row["started_at"]}
    q = "update twin_runs set status = 'STOPPED', stopped_at = now() where status = 'RUNNING' and "
    row = await fetchone(s, q + ("id = :r" if body.run_id else "id = (select id from twin_runs where status = 'RUNNING' "
                                                                "order by started_at desc limit 1)") + " returning id, status, stopped_at",
                         {"r": body.run_id} if body.run_id else {})
    if not row:
        raise not_found("running twin run")
    return {"run_id": row["id"], "status": row["status"], "stopped_at": row["stopped_at"]}


def _canon(kind: str, value: float | None, unit: str) -> float | None:
    if value is None:
        return None
    try:
        return to_canonical(kind, value, unit)
    except UnitError as exc:
        raise unprocessable("unit-not-accepted", "Unit not accepted", str(exc)) from None


@router.post("/v1/ingest/twin/snapshots", status_code=202, summary="Virtual readings for a simulation step (6.2)")
async def post_snapshot(snap: TwinSnapshot, _: str = Depends(twin_auth), s: AsyncSession = Depends(get_session)):
    run = await fetchone(s, "select status from twin_runs where id = :r", {"r": snap.run_id})
    if not run:
        raise not_found("twin run")
    if run["status"] != "RUNNING":
        raise conflict("This twin run is STOPPED", "run-stopped")
    u = snap.units
    pipes = {r["code"]: r for r in await fetchall(
        s, "select id, code, monitoring::text as monitoring from pipe_segments where code = any(:c)",
        {"c": [p.pipe_code for p in snap.pipes]})}
    rows, accepted, ignored, rejected = [], 0, [], []
    for p in snap.pipes:
        ref = pipes.get(p.pipe_code)
        if not ref:
            rejected.append({"pipe_code": p.pipe_code, "reason": "unknown pipe_code"})
            continue
        fi, fo = _canon("flow", p.flow_in, u.flow), _canon("flow", p.flow_out, u.flow)
        pi, po = _canon("pressure", p.pressure_in, u.pressure), _canon("pressure", p.pressure_out, u.pressure)
        if None in (fi, fo, pi, po):
            rejected.append({"pipe_code": p.pipe_code, "reason": "flow_in, flow_out, pressure_in and pressure_out are required"})
            continue
        rows.append({"r": snap.run_id, "p": ref["id"], "t": snap.sim_time, "fi": fi, "fo": fo, "pi": pi, "po": po,
                     "v": _canon("velocity", p.velocity, u.velocity), "il": _canon("flow", p.injected_leak, u.flow),
                     "mon": ref["monitoring"]})
        accepted += 1
        if ref["monitoring"] == "HARDWARE":        # stored, but a HARDWARE pipe ignores twin readings for detection
            ignored.append(p.pipe_code)
    if rows:
        await s.execute(text("""insert into twin_pipe_readings (run_id, pipe_id, sim_time, flow_in_lpm, flow_out_lpm, pressure_in_kpa,
                                pressure_out_kpa, velocity_mps, injected_leak_lpm)
                                values (:r, :p, :t, :fi, :fo, :pi, :po, :v, :il)"""), rows)
        await s.execute(text("""insert into signal_latest (pipe_id, source, ts, flow_in_lpm, flow_out_lpm, pressure_in_kpa, pressure_out_kpa)
                                values (:p, 'TWIN', :t, :fi, :fo, :pi, :po)
                                on conflict (pipe_id, source) do update set ts = excluded.ts, flow_in_lpm = excluded.flow_in_lpm,
                                flow_out_lpm = excluded.flow_out_lpm, pressure_in_kpa = excluded.pressure_in_kpa,
                                pressure_out_kpa = excluded.pressure_out_kpa"""),
                        [{k: r[k] for k in ("p", "t", "fi", "fo", "pi", "po")} for r in rows])
        to_eval = [r["p"] for r in rows if r["mon"] == "SIMULATED"]
        after_commit(s, lambda: [evaluator.mark_dirty(pid, "TWIN") for pid in to_eval])
    return {"accepted": accepted, "ignored_for_detection": ignored, "rejected": rejected}


@router.get("/v1/twin/network", summary="Network model as GeoJSON (the database is the master copy)")
async def twin_network(_: str = Depends(twin_auth), s: AsyncSession = Depends(get_session)):
    return await twin_sync.network_geojson(s)


@router.get("/v1/twin/commands", summary="Pending commands (twin polls every 2 s)")
async def twin_commands(status: str = Query("PENDING", pattern="^(PENDING|DELIVERED)$"), limit: int = Query(50, ge=1, le=200),
                        _: str = Depends(twin_auth), s: AsyncSession = Depends(get_session)):
    """At-least-once delivery: PENDING commands, plus DELIVERED ones not acknowledged within 30 s."""
    rows = await fetchall(s, """
        select c.id, c.type::text as type, p.code as pipe_code, v.code as valve_code, c.params, c.leak_event_id, c.created_at
        from twin_commands c left join pipe_segments p on p.id = c.pipe_id left join valves v on v.id = c.valve_id
        where c.status = 'PENDING' or (c.status = 'DELIVERED' and c.delivered_at < now() - interval '30 seconds')
        order by c.created_at limit :l""", {"l": limit})
    if rows:
        await s.execute(text("update twin_commands set status = 'DELIVERED', delivered_at = now() where id = any(:ids)"),
                        {"ids": [r["id"] for r in rows]})
    items = []
    for r in rows:
        params = dict(as_json(r["params"]) or {})
        if r["valve_code"]:
            params["valve_code"] = r["valve_code"]
        items.append({"id": r["id"], "type": r["type"], "pipe_code": r["pipe_code"], "params": params,
                      "leak_event_id": r["leak_event_id"], "created_at": r["created_at"]})
    return items


@router.post("/v1/twin/commands/{command_id}/ack", summary="Report APPLIED or FAILED")
async def twin_ack(command_id: UUID, body: TwinAck, _: str = Depends(twin_auth), s: AsyncSession = Depends(get_session)):
    cmd = await fetchone(s, "select id, status::text as status from twin_commands where id = :i for update", {"i": command_id})
    if not cmd:
        raise not_found("twin command")
    if cmd["status"] in ("APPLIED", "FAILED"):       # idempotent
        return {"id": command_id, "status": cmd["status"]}
    await s.execute(text("update twin_commands set status = CAST(:st AS twin_cmd_status), error = :e, "
                         "applied_at = case when CAST(:st AS twin_cmd_status) = 'APPLIED' then now() else applied_at end where id = :i"),
                    {"st": body.status, "e": body.error, "i": command_id})
    await log_event(s, "TWIN_COMMAND", command_id, body.status, cmd["status"], body.status, "TWIN", payload={"error": body.error})
    return {"id": command_id, "status": body.status}


# ---------------------------------------------------------------- dashboard demo controls (ADMIN)
@router.post("/v1/twin/inject-leak", summary="Demo control: inject a leak into the twin (ADMIN)")
async def inject_leak(body: InjectLeakBody, user: CurrentUser = Depends(admin_user), s: AsyncSession = Depends(get_session)):
    if not await fetchone(s, "select 1 as x from pipe_segments where id = :p", {"p": body.pipe_id}):
        raise not_found("pipe")
    cid = await twin_sync.queue_command(s, "INJECT_LEAK", pipe_id=body.pipe_id, created_by=user.id,
                                        params={"leak_rate_lpm": body.leak_rate_lpm, "position_fraction": body.position_fraction})
    return {"command_id": cid, "status": "PENDING"}


@router.post("/v1/twin/clear-leak", summary="Demo control: clear an injected leak (ADMIN)")
async def clear_leak(body: ClearLeakBody, user: CurrentUser = Depends(admin_user), s: AsyncSession = Depends(get_session)):
    if not await fetchone(s, "select 1 as x from pipe_segments where id = :p", {"p": body.pipe_id}):
        raise not_found("pipe")
    cid = await twin_sync.queue_command(s, "CLEAR_LEAK", pipe_id=body.pipe_id, created_by=user.id)
    return {"command_id": cid, "status": "PENDING"}
