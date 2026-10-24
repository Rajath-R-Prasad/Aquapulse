"""Leak events (11.3 utility endpoints, 6.4 event object)."""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Body, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, as_json, fetchall, fetchone, get_session
from app.schemas.common import ActionBody, decode_cursor, encode_cursor, forbidden, not_found
from app.schemas.events import FalseAlarmBody
from app.security import CurrentUser, any_user, staff_user
from app.services import state

router = APIRouter(prefix="/v1/leak-events", tags=["Leak events"], route_class=TransactionalRoute)


async def build_event_object(s: AsyncSession, event_id: UUID) -> dict:
    """The leak event object of section 6.4."""
    e = await fetchone(s, """
        select le.id, le.event_no, le.source::text as source, le.status::text as status, le.severity::text as severity,
               le.severity_score, le.priority::text as priority, le.est_leak_rate_lpm, le.est_loss_pct, le.confidence,
               le.detected_at, le.parameters, le.location_method, le.chainage_m, le.candidate_pipes, le.acknowledged_at,
               le.closed_at, le.false_alarm_reason, le.recurrence_of,
               ST_AsGeoJSON(le.location::geometry)::jsonb as location, ST_AsGeoJSON(le.search_geom::geometry)::jsonb as search_geom,
               ps.id as pipe_id, ps.code as pipe_code, ps.diameter_mm, ps.material::text as material, d.code as dma_code
        from leak_events le join pipe_segments ps on ps.id = le.pipe_id join dmas d on d.id = ps.dma_id
        where le.id = :i""", {"i": event_id})
    if not e:
        raise not_found("leak event")
    adv = await fetchone(s, "select id, urgency::text as urgency, status::text as status, affected_connections, message "
                            "from isolation_advisories where leak_event_id = :e order by created_at desc limit 1", {"e": event_id})
    if adv:
        adv["valves"] = await fetchall(s, """
            select v.id, v.code, 'CLOSE' as action, v.state::text as state, av.close_confirmed_at, av.restore_confirmed_at
            from isolation_advisory_valves av join valves v on v.id = av.valve_id where av.advisory_id = :a order by v.code""",
                                       {"a": adv["id"]})
    wo = await fetchone(s, """select w.id, w.wo_no, w.status::text as status, w.sla_due_at, w.assigned_engineer_id, p.full_name as engineer_name
                              from work_orders w left join profiles p on p.id = w.assigned_engineer_id
                              where w.leak_event_id = :e and w.status <> 'CANCELLED'""", {"e": event_id})
    return {
        "id": e["id"], "event_no": e["event_no"], "source": e["source"], "is_simulated": e["source"] == "TWIN",
        "status": e["status"],
        "pipe": {"id": e["pipe_id"], "code": e["pipe_code"], "diameter_mm": e["diameter_mm"], "material": e["material"],
                 "dma_code": e["dma_code"]},
        "location": as_json(e["location"]), "search_geom": as_json(e["search_geom"]), "location_method": e["location_method"],
        "chainage_m": e["chainage_m"], "candidate_pipes": as_json(e["candidate_pipes"]),
        "severity": e["severity"], "severity_score": e["severity_score"], "priority": e["priority"],
        "est_leak_rate_lpm": e["est_leak_rate_lpm"], "est_loss_pct": e["est_loss_pct"], "confidence": e["confidence"],
        "detected_at": e["detected_at"], "acknowledged_at": e["acknowledged_at"], "closed_at": e["closed_at"],
        "false_alarm_reason": e["false_alarm_reason"], "recurrence_of": e["recurrence_of"],
        "parameters": as_json(e["parameters"]), "advisory": adv, "work_order": wo,
    }


@router.get("", summary="List leak events (cursor pagination)")
async def list_events(status: str | None = None, severity: str | None = None, source: str | None = None,
                      from_: datetime | None = Query(None, alias="from"), to: datetime | None = None,
                      limit: int = Query(50, ge=1, le=200), cursor: str | None = None,
                      _: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    where, params = ["true"], {"l": limit + 1}
    for col, val in (("status", status), ("severity", severity), ("source", source)):
        if val:
            where.append(f"{col}::text = :{col}")
            params[col] = val
    if from_:
        where.append("detected_at >= :from_"); params["from_"] = from_
    if to:
        where.append("detected_at <= :to"); params["to"] = to
    if cursor:
        t, i = decode_cursor(cursor)
        where.append("(detected_at, id) < (:ct, CAST(:ci AS uuid))")
        params.update(ct=t, ci=i)
    rows = await fetchall(s, f"select * from v_leak_events_enriched where {' and '.join(where)} "
                             "order by detected_at desc, id desc limit :l", params)
    nxt = None
    if len(rows) > limit:
        rows = rows[:limit]
        nxt = encode_cursor(rows[-1]["detected_at"], rows[-1]["id"])
    for r in rows:
        r["parameters"] = as_json(r["parameters"])
    return {"items": rows, "next_cursor": nxt}


@router.get("/{event_id}", summary="Event object (6.4)")
async def get_event(event_id: UUID, user: CurrentUser = Depends(any_user), s: AsyncSession = Depends(get_session)):
    if user.role == "ENGINEER":      # engineers see only the events of their own work orders
        mine = await fetchone(s, "select 1 as x from work_orders where leak_event_id = :e and assigned_engineer_id = :u",
                              {"e": event_id, "u": user.id})
        if not mine:
            raise forbidden("This event is not part of one of your work orders")
    return await build_event_object(s, event_id)


@router.post("/{event_id}/acknowledge", summary="DETECTED -> ACKNOWLEDGED")
async def acknowledge(event_id: UUID, body: ActionBody | None = Body(default=None), user: CurrentUser = Depends(staff_user),
                      s: AsyncSession = Depends(get_session)):
    return await state.acknowledge_event(s, event_id, user, body.expected_status if body else None)


@router.post("/{event_id}/false-alarm", summary="Mark as false alarm (reason required)")
async def false_alarm(event_id: UUID, body: FalseAlarmBody, user: CurrentUser = Depends(staff_user),
                      s: AsyncSession = Depends(get_session)):
    return await state.mark_false_alarm(s, event_id, user, body.reason, body.expected_status)
