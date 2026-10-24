"""All state transitions (section 8) and the core workflows (section 10).

Every public function runs inside the caller's transaction (one request = one transaction), locks the row
with `select ... for update`, checks `expected_status` (409 on mismatch), writes event_log, and lets
Realtime publish the change. Transitions that are not listed in section 8 are rejected with 409.
"""
from __future__ import annotations

from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import dumps, fetchall, fetchone, get_setting, scalar
from app.schemas.common import conflict, forbidden, not_found, unprocessable
from app.services import dispatch, evidence, isolation, twin_sync
from app.services.notify import notify_staff, notify_users
from app.services.severity import PRIORITY_FOR, URGENCY_FOR, URGENCY_ORDER, rank

LIVE_WO = ("ASSIGNED", "ACCEPTED", "EN_ROUTE", "ON_SITE", "REWORK", "SUBMITTED")
EVENT_FOR_WO = {"ASSIGNED": "DISPATCHED", "ACCEPTED": "DISPATCHED", "EN_ROUTE": "DISPATCHED", "ON_SITE": "IN_PROGRESS",
                "REWORK": "IN_PROGRESS", "SUBMITTED": "REPAIR_SUBMITTED", "COMPLETED": "CLOSED"}


# ---------------------------------------------------------------- helpers
def check_expected(actual: str, expected: str | None) -> None:
    if expected is not None and expected != actual:
        raise conflict(f"Expected status {expected} but current status is {actual}", "status-mismatch")


async def log_event(s: AsyncSession, entity_type: str, entity_id: UUID, action: str, from_status: str | None = None,
                    to_status: str | None = None, actor_kind: str = "SYSTEM", actor_id: UUID | None = None,
                    payload: dict | None = None) -> None:
    await s.execute(
        text("insert into event_log (entity_type, entity_id, action, from_status, to_status, actor_kind, actor_id, payload) "
             "values (:et, :ei, :a, :f, :t, :ak, :ai, CAST(:p AS jsonb))"),
        {"et": entity_type, "ei": entity_id, "a": action, "f": from_status, "t": to_status, "ak": actor_kind,
         "ai": actor_id, "p": dumps(payload) if payload is not None else None})


async def set_pipe_state(s: AsyncSession, pipe_id: UUID, to: str, reason: str, event_id: UUID | None = None,
                         by: str = "SYSTEM") -> bool:
    """The only way pipe state changes: fn_set_pipe_state + SET_PIPE_STATE mirrored to the twin (8.1)."""
    cur = await scalar(s, "select state::text from pipe_segments where id = :p", {"p": pipe_id})
    if cur is None:
        raise not_found("pipe")
    if cur == to:
        return False
    await s.execute(text("select fn_set_pipe_state(:p, CAST(:to AS pipe_state), :r, :e, :by)"),
                    {"p": pipe_id, "to": to, "r": reason, "e": event_id, "by": by})
    await twin_sync.queue_command(s, "SET_PIPE_STATE", pipe_id=pipe_id, leak_event_id=event_id, params={"state": to})
    await log_event(s, "PIPE", pipe_id, "STATE_CHANGE", cur, to, by if by in ("USER", "TWIN") else "SYSTEM",
                    payload={"reason": reason})
    return True


async def _set_event_status(s: AsyncSession, event_id: UUID, to: str, actor_kind: str = "SYSTEM",
                            actor_id: UUID | None = None) -> None:
    cur = await scalar(s, "select status::text from leak_events where id = :i", {"i": event_id})
    if cur == to:
        return
    await s.execute(text("update leak_events set status = CAST(:t AS event_status) where id = :i"), {"t": to, "i": event_id})
    await log_event(s, "LEAK_EVENT", event_id, "STATUS_CHANGE", cur, to, actor_kind, actor_id)


async def _refresh_engineer(s: AsyncSession, engineer_id: UUID | None) -> None:
    """Engineer status follows the work order; AVAILABLE again when no live job remains (8.3)."""
    if engineer_id is None:
        return
    rows = await fetchall(s, "select status::text as st from work_orders where assigned_engineer_id = :e "
                             "and status::text = any(:live)", {"e": engineer_id, "live": list(LIVE_WO)})
    sts = {r["st"] for r in rows}
    if sts & {"ON_SITE", "REWORK", "SUBMITTED"}:
        new = "ON_SITE"
    elif "EN_ROUTE" in sts:
        new = "EN_ROUTE"
    elif sts & {"ASSIGNED", "ACCEPTED"}:
        new = "ASSIGNED"
    else:
        new = "AVAILABLE"
    await s.execute(text("update engineers set status = CAST(:n AS engineer_status) "
                         "where profile_id = :e and status <> 'OFF_DUTY'"), {"n": new, "e": engineer_id})


async def _lock_wo(s: AsyncSession, wo_id: UUID, expected: str | None = None) -> dict:
    wo = await fetchone(s, """
        select w.id, w.wo_no, w.status::text as status, w.priority::text as priority, w.assigned_engineer_id,
               w.arrived_at, w.submitted_at, w.rework_count, w.leak_event_id, le.pipe_id, le.source::text as source,
               le.status::text as event_status, le.event_no, p.code as pipe_code
        from work_orders w join leak_events le on le.id = w.leak_event_id join pipe_segments p on p.id = le.pipe_id
        where w.id = :i for update of w""", {"i": wo_id})
    if not wo:
        raise not_found("work order")
    check_expected(wo["status"], expected)
    return wo


def _own(wo: dict, user: Any) -> None:
    if wo["assigned_engineer_id"] != user.id:
        raise forbidden("This work order is not assigned to you")


def _bad(wo: dict, action: str) -> Exception:
    return conflict(f"Cannot {action} a work order in status {wo['status']}", "invalid-transition")


async def _staff_ids(s: AsyncSession, roles: tuple[str, ...]) -> list[UUID]:
    return [r["id"] for r in await fetchall(s, "select id from profiles where is_active and role::text = any(:r)", {"r": list(roles)})]


def _ev_payload(wo: dict, **extra: Any) -> dict:
    return {"leak_event_id": str(wo["leak_event_id"]), "work_order_id": str(wo["id"]), "pipe_code": wo["pipe_code"], **extra}


# ---------------------------------------------------------------- 10.1 detection -> event
async def open_leak_event(s: AsyncSession, pipe: dict, source: str, device_id: UUID | None, run_id: UUID | None,
                          parameters: dict, inference_id: int | None, grade: dict, confidence: float,
                          position_fraction: float | None = None) -> dict | None:
    """Creates event, pipe LEAK, work order, advisory, notifications and twin commands in one transaction."""
    if await scalar(s, "select 1 from leak_events where pipe_id = :p and status not in ('CLOSED','FALSE_ALARM')",
                    {"p": pipe["id"]}):
        return None
    frac = 0.5 if position_fraction is None else min(1.0, max(0.0, position_fraction))
    method = "SEGMENT_MIDPOINT" if position_fraction is None else "SEGMENT_CHAINAGE"
    sev = grade["severity"]
    try:
        async with s.begin_nested():
            ev = await fetchone(s, """
                insert into leak_events (source, pipe_id, device_id, twin_run_id, severity, severity_score, priority,
                    est_leak_rate_lpm, est_loss_pct, confidence, location, search_geom, chainage_m, location_method,
                    trigger_inference_id, parameters, recurrence_of)
                select CAST(:src AS data_source), ps.id, :dev, :run, CAST(:sev AS severity_level), :score,
                       CAST(:prio AS priority_level), :rate, :loss, :conf,
                       ST_LineInterpolatePoint(ps.geom::geometry, CAST(:frac AS double precision))::geography, ps.geom,
                       ps.length_m * CAST(:frac AS double precision), :method, :inf, CAST(:params AS jsonb),
                       (select r.id from leak_events r where r.pipe_id = ps.id and r.status = 'CLOSED'
                          and r.closed_at > now() - interval '24 hours' order by r.closed_at desc limit 1)
                from pipe_segments ps where ps.id = :pipe
                returning id, event_no""",
                {"src": source, "dev": device_id, "run": run_id, "sev": sev,
                 "score": min(1.0, max(0.0, grade["severity_score"])), "prio": grade["priority"],
                 "rate": grade["est_leak_rate_lpm"], "loss": grade["est_loss_pct"],
                 "conf": min(1.0, max(0.0, confidence)), "frac": frac, "method": method, "inf": inference_id,
                 "params": dumps(parameters), "pipe": pipe["id"]})
    except IntegrityError:          # another evaluation opened an event first (one_open_event_per_pipe)
        return None
    eid = ev["id"]
    await log_event(s, "LEAK_EVENT", eid, "CREATED", None, "DETECTED", "SYSTEM", payload={"source": source, "severity": sev})
    await set_pipe_state(s, pipe["id"], "LEAK", "Leak confirmed", eid, "SYSTEM")

    sla = (await get_setting("sla_arrive_minutes")).get(grade["priority"], 240)
    wo = await fetchone(s, "insert into work_orders (leak_event_id, priority, sla_due_at) values "
                           "(:e, CAST(:p AS priority_level), now() + make_interval(mins => :m)) "
                           "returning id, wo_no, sla_due_at",
                        {"e": eid, "p": grade["priority"], "m": int(sla)})
    await log_event(s, "WORK_ORDER", wo["id"], "CREATED", None, "UNASSIGNED", "SYSTEM")

    adv = await isolation.create_advisory(s, eid, pipe["id"], pipe["code"], sev, grade["est_leak_rate_lpm"])
    await log_event(s, "ADVISORY", adv["id"], "CREATED", None, "OPEN", "SYSTEM", payload={"valves": adv["valves"]})

    prefix = "[SIMULATED] " if source == "TWIN" else ""
    payload = {"leak_event_id": str(eid), "work_order_id": str(wo["id"]), "advisory_id": str(adv["id"]),
               "pipe_code": pipe["code"], "severity": sev, "source": source}
    await notify_staff(s, "LEAK_DETECTED", f"{prefix}Leak detected on {pipe['code']}",
                       f"{sev} leak, about {round(grade['est_leak_rate_lpm'])} L/min "
                       f"({grade['est_loss_pct']:.0f}% of flow). {ev['event_no']}", payload)
    await notify_staff(s, "ISOLATION_ADVISORY", f"{prefix}Isolation advisory for {pipe['code']}", adv["message"], payload)

    if source == "HARDWARE":                 # the twin mirrors reality (4.1 rule 3)
        await twin_sync.mirror_leak(s, pipe["id"], eid, grade["est_leak_rate_lpm"], frac)
    return {"event_id": eid, "event_no": ev["event_no"], "work_order_id": wo["id"], "advisory_id": adv["id"]}


async def escalate_event(s: AsyncSession, event: dict, grade: dict) -> bool:
    """8.2: raise severity and priority (never lower), upgrade advisory urgency, shorten SLA, notify once."""
    new = grade["severity"]
    if rank(new) <= rank(event["severity"]):
        return False
    eid = event["id"]
    await s.execute(text("""update leak_events set severity = CAST(:s AS severity_level), severity_score = :sc,
                            priority = CAST(:p AS priority_level), est_leak_rate_lpm = :r, est_loss_pct = :l where id = :i"""),
                    {"s": new, "sc": min(1.0, grade["severity_score"]), "p": grade["priority"],
                     "r": grade["est_leak_rate_lpm"], "l": grade["est_loss_pct"], "i": eid})
    minutes = (await get_setting("sla_arrive_minutes")).get(grade["priority"], 240)
    await s.execute(text("update work_orders set priority = CAST(:p AS priority_level), "
                         "sla_due_at = least(sla_due_at, now() + make_interval(mins => :m)) "
                         "where leak_event_id = :e and status <> 'CANCELLED'"),
                    {"p": grade["priority"], "m": int(minutes), "e": eid})
    adv = await fetchone(s, "select id, urgency::text as urgency from isolation_advisories where leak_event_id = :e "
                            "order by created_at desc limit 1", {"e": eid})
    new_urg = URGENCY_FOR[new]
    if adv and URGENCY_ORDER.index(new_urg) > URGENCY_ORDER.index(adv["urgency"]):
        await s.execute(text("update isolation_advisories set urgency = CAST(:u AS advisory_urgency) where id = :a"),
                        {"u": new_urg, "a": adv["id"]})
    await log_event(s, "LEAK_EVENT", eid, "SEVERITY_ESCALATED", event["severity"], new, "SYSTEM")
    code = await scalar(s, "select code from pipe_segments where id = :p", {"p": event["pipe_id"]})
    await notify_staff(s, "SEVERITY_ESCALATED", f"Leak on {code} escalated to {new}",
                       f"Severity raised from {event['severity']} to {new}.",
                       {"leak_event_id": str(eid), "pipe_code": code, "severity": new})
    return True


# ---------------------------------------------------------------- event actions
async def _lock_event(s: AsyncSession, event_id: UUID) -> dict:
    ev = await fetchone(s, "select id, pipe_id, source::text as source, status::text as status, acknowledged_at "
                           "from leak_events where id = :i for update", {"i": event_id})
    if not ev:
        raise not_found("leak event")
    return ev


async def acknowledge_event(s: AsyncSession, event_id: UUID, user: Any, expected: str | None = None) -> dict:
    ev = await _lock_event(s, event_id)
    check_expected(ev["status"], expected)
    if ev["status"] != "DETECTED":
        raise conflict(f"Cannot acknowledge an event in status {ev['status']}", "invalid-transition")
    await s.execute(text("update leak_events set status = 'ACKNOWLEDGED', acknowledged_at = now(), acknowledged_by = :u "
                         "where id = :i"), {"u": user.id, "i": event_id})
    await log_event(s, "LEAK_EVENT", event_id, "ACKNOWLEDGED", "DETECTED", "ACKNOWLEDGED", "USER", user.id)
    return {"id": event_id, "status": "ACKNOWLEDGED"}


async def _close_as_false_alarm(s: AsyncSession, ev: dict, reason: str, user: Any, actor_note: str) -> None:
    eid = ev["id"]
    await s.execute(text("update leak_events set status = 'FALSE_ALARM', closed_at = now(), false_alarm_reason = :r "
                         "where id = :i"), {"r": reason, "i": eid})
    await log_event(s, "LEAK_EVENT", eid, actor_note, ev["status"], "FALSE_ALARM", "USER", user.id, {"reason": reason})
    cancelled = await fetchall(s, "update work_orders set status = 'CANCELLED' where leak_event_id = :e "
                                  "and status not in ('COMPLETED','CANCELLED') returning id, assigned_engineer_id, status::text as st",
                               {"e": eid})
    for w in cancelled:
        await log_event(s, "WORK_ORDER", w["id"], "CANCELLED", None, "CANCELLED", "USER", user.id, {"reason": reason})
        await s.execute(text("update work_order_assignments set response = 'REASSIGNED', responded_at = now() "
                             "where work_order_id = :w and response = 'PENDING'"), {"w": w["id"]})
        await _refresh_engineer(s, w["assigned_engineer_id"])
    await s.execute(text("update isolation_advisories set status = 'DISMISSED', dismiss_reason = :r "
                         "where leak_event_id = :e and status in ('OPEN','ACKNOWLEDGED')"),
                    {"r": f"False alarm: {reason}", "e": eid})
    await set_pipe_state(s, ev["pipe_id"], "NORMAL", f"False alarm: {reason}", eid, "USER")
    await twin_sync.clear_pipe(s, ev["pipe_id"], eid, user.id)


async def mark_false_alarm(s: AsyncSession, event_id: UUID, user: Any, reason: str, expected: str | None = None) -> dict:
    ev = await _lock_event(s, event_id)
    check_expected(ev["status"], expected)
    if ev["status"] not in ("DETECTED", "ACKNOWLEDGED", "DISPATCHED"):
        raise conflict(f"Cannot mark a {ev['status']} event as false alarm", "invalid-transition")
    await _close_as_false_alarm(s, ev, reason, user, "FALSE_ALARM")
    return {"id": event_id, "status": "FALSE_ALARM"}


# ---------------------------------------------------------------- work-order transitions (8.3)
async def assign_work_order(s: AsyncSession, wo_id: UUID, engineer_id: UUID, user: Any, expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    if wo["status"] != "UNASSIGNED":
        raise _bad(wo, "assign")
    eng = await fetchone(s, "select e.profile_id from engineers e join profiles p on p.id = e.profile_id "
                            "where e.profile_id = :e and p.is_active and p.role = 'ENGINEER'", {"e": engineer_id})
    if not eng:
        raise unprocessable("engineer-not-found", "Engineer not found", "No active engineer with this id")
    ranking = await dispatch.rank(s, wo["leak_event_id"], limit=200)
    match = next((r for r in ranking if r["engineer_id"] == engineer_id), None)
    score = match["score"] if match else None
    breakdown = match["score_breakdown"] if match else {"note": "outside ranked list (operator override)"}
    await s.execute(text("insert into work_order_assignments (work_order_id, engineer_id, assigned_by, score, score_breakdown) "
                         "values (:w, :e, :u, CAST(:sc AS double precision), CAST(:b AS jsonb))"),
                    {"w": wo_id, "e": engineer_id, "u": user.id, "sc": score, "b": dumps(breakdown)})
    await s.execute(text("update work_orders set status = 'ASSIGNED', assigned_engineer_id = :e, assigned_by = :u, "
                         "assigned_at = now() where id = :w"), {"e": engineer_id, "u": user.id, "w": wo_id})
    await log_event(s, "WORK_ORDER", wo_id, "ASSIGNED", "UNASSIGNED", "ASSIGNED", "USER", user.id,
                    {"engineer_id": str(engineer_id), "score": score})
    await _refresh_engineer(s, engineer_id)
    await _set_event_status(s, wo["leak_event_id"], "DISPATCHED", "USER", user.id)
    await notify_users(s, [engineer_id], "WO_ASSIGNED", f"New job {wo['wo_no']}",
                       f"Leak repair on {wo['pipe_code']}", _ev_payload(wo))
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "ASSIGNED"}


async def accept_work_order(s: AsyncSession, wo_id: UUID, user: Any, expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    _own(wo, user)
    if wo["status"] != "ASSIGNED":
        raise _bad(wo, "accept")
    await s.execute(text("update work_orders set status = 'ACCEPTED', accepted_at = now() where id = :w"), {"w": wo_id})
    await s.execute(text("update work_order_assignments set response = 'ACCEPTED', responded_at = now() "
                         "where work_order_id = :w and response = 'PENDING'"), {"w": wo_id})
    await log_event(s, "WORK_ORDER", wo_id, "ACCEPTED", "ASSIGNED", "ACCEPTED", "USER", user.id)
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "ACCEPTED"}


async def _unassign(s: AsyncSession, wo: dict, response: str, reason: str | None, actor_kind: str, actor_id: UUID | None) -> dict:
    eng = wo["assigned_engineer_id"]
    await s.execute(text("update work_orders set status = 'UNASSIGNED', assigned_engineer_id = null, assigned_at = null, "
                         "assigned_by = null where id = :w"), {"w": wo["id"]})
    await s.execute(text("update work_order_assignments set response = :r, responded_at = now(), decline_reason = :d "
                         "where work_order_id = :w and response = 'PENDING'"), {"r": response, "d": reason, "w": wo["id"]})
    await log_event(s, "WORK_ORDER", wo["id"], response, "ASSIGNED", "UNASSIGNED", actor_kind, actor_id, {"reason": reason})
    await _refresh_engineer(s, eng)
    back = "ACKNOWLEDGED" if await scalar(s, "select acknowledged_at from leak_events where id = :e", {"e": wo["leak_event_id"]}) else "DETECTED"
    await _set_event_status(s, wo["leak_event_id"], back, actor_kind, actor_id)
    label = "declined" if response == "DECLINED" else "timed out"
    await notify_staff(s, "WO_REJECTED", f"Assignment {label}: {wo['wo_no']}",
                       f"{wo['pipe_code']} needs a new engineer." + (f" Reason: {reason}" if reason else ""),
                       _ev_payload(wo, kind="ASSIGNMENT_" + response))
    return {"id": wo["id"], "wo_no": wo["wo_no"], "status": "UNASSIGNED"}


async def decline_work_order(s: AsyncSession, wo_id: UUID, user: Any, reason: str, expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    _own(wo, user)
    if wo["status"] != "ASSIGNED":
        raise _bad(wo, "decline")
    return await _unassign(s, wo, "DECLINED", reason, "USER", user.id)


async def timeout_assignment(s: AsyncSession, wo_id: UUID) -> dict | None:
    wo = await _lock_wo(s, wo_id)
    if wo["status"] != "ASSIGNED":
        return None
    return await _unassign(s, wo, "TIMED_OUT", "No response within the accept timeout", "SYSTEM", None)


async def start_travel(s: AsyncSession, wo_id: UUID, user: Any, expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    _own(wo, user)
    if wo["status"] != "ACCEPTED":
        raise _bad(wo, "start travel on")
    await s.execute(text("update work_orders set status = 'EN_ROUTE', en_route_at = now() where id = :w"), {"w": wo_id})
    await log_event(s, "WORK_ORDER", wo_id, "EN_ROUTE", "ACCEPTED", "EN_ROUTE", "USER", user.id)
    await _refresh_engineer(s, user.id)
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "EN_ROUTE"}


async def arrive(s: AsyncSession, wo_id: UUID, user: Any, lat: float, lon: float, override_reason: str | None,
                 expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    _own(wo, user)
    if wo["status"] != "EN_ROUTE":
        raise _bad(wo, "arrive at")
    cfg = await get_setting("evidence")
    dist = await scalar(s, "select ST_Distance(ST_SetSRID(ST_MakePoint(:lon,:lat),4326)::geography, location) "
                           "from leak_events where id = :e", {"lon": lon, "lat": lat, "e": wo["leak_event_id"]})
    dist = float(dist) if dist is not None else None
    limit = float(cfg["arrival_geofence_m"])
    if dist is not None and dist > limit and not override_reason:
        raise unprocessable("arrival-outside-geofence", "Not at the leak location",
                            f"Reported position is {dist:.0f} m from the leak (limit {limit:.0f} m). "
                            "Move closer or provide override_reason.", [{"distance_m": dist, "limit_m": limit}])
    await s.execute(text("update work_orders set status = 'ON_SITE', arrived_at = now() where id = :w"), {"w": wo_id})
    await log_event(s, "WORK_ORDER", wo_id, "ARRIVED", "EN_ROUTE", "ON_SITE", "USER", user.id,
                    {"distance_m": dist, "override_reason": override_reason})
    await _set_event_status(s, wo["leak_event_id"], "IN_PROGRESS", "USER", user.id)
    await set_pipe_state(s, wo["pipe_id"], "UNDER_REPAIR", "Engineer on site", wo["leak_event_id"], "USER")
    await _refresh_engineer(s, user.id)
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "ON_SITE", "distance_m": dist}


async def submit_repair(s: AsyncSession, wo_id: UUID, user: Any, body: Any, expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    _own(wo, user)
    if wo["status"] not in ("ON_SITE", "REWORK"):
        raise _bad(wo, "submit")
    if body.allow_simulated_location_override and wo["source"] != "TWIN":
        raise unprocessable(
            "simulated-location-override-not-allowed",
            "Location override is only available for simulated work",
            "Photo location checks can only be bypassed for TWIN-sourced work orders",
        )
    await evidence.validate_for_submit(
        s,
        wo,
        body.evidence_ids,
        allow_location_override=body.allow_simulated_location_override,
    )
    await s.execute(text("""update work_orders set status = 'SUBMITTED', submitted_at = now(), repair_type = :rt,
                            materials = CAST(:m AS jsonb), labour_minutes = :lm, work_notes = :wn, post_repair_check = null
                            where id = :w"""),
                    {"rt": body.repair_type, "m": dumps([m.model_dump() for m in body.materials]),
                     "lm": body.labour_minutes, "wn": body.work_notes, "w": wo_id})
    await log_event(
        s,
        "WORK_ORDER",
        wo_id,
        "SUBMITTED",
        wo["status"],
        "SUBMITTED",
        "USER",
        user.id,
        {"simulated_location_override": body.allow_simulated_location_override},
    )
    await _set_event_status(s, wo["leak_event_id"], "REPAIR_SUBMITTED", "USER", user.id)
    await set_pipe_state(s, wo["pipe_id"], "PENDING_VERIFICATION", "Repair submitted", wo["leak_event_id"], "USER")
    await notify_staff(s, "WO_SUBMITTED", f"Repair submitted: {wo['wo_no']}",
                       f"Review photos and readings for {wo['pipe_code']}.", _ev_payload(wo))
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "SUBMITTED"}


async def approve_repair(s: AsyncSession, wo_id: UUID, user: Any, comment: str | None, expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    if wo["status"] != "SUBMITTED":
        raise _bad(wo, "approve")
    full = await fetchone(s, "select submitted_at from work_orders where id = :w", {"w": wo_id})
    check = await evidence.post_repair_check(s, {**wo, **full}, {"source": wo["source"], "pipe_id": wo["pipe_id"]})
    await s.execute(text("update work_orders set status = 'COMPLETED', approved_by = :u, approved_at = now(), "
                         "post_repair_check = CAST(:c AS jsonb) where id = :w"), {"u": user.id, "c": dumps(check), "w": wo_id})
    await s.execute(text("update leak_events set status = 'CLOSED', closed_at = now() where id = :e"), {"e": wo["leak_event_id"]})
    await log_event(s, "WORK_ORDER", wo_id, "APPROVED", "SUBMITTED", "COMPLETED", "USER", user.id,
                    {"comment": comment, "post_repair_check": check.get("status")})
    await log_event(s, "LEAK_EVENT", wo["leak_event_id"], "CLOSED", wo["event_status"], "CLOSED", "USER", user.id)
    await set_pipe_state(s, wo["pipe_id"], "NORMAL", "Repair approved", wo["leak_event_id"], "USER")
    await twin_sync.clear_pipe(s, wo["pipe_id"], wo["leak_event_id"], user.id)      # CLEAR_LEAK + RESET_PIPE_NORMAL
    await _refresh_engineer(s, wo["assigned_engineer_id"])
    if wo["assigned_engineer_id"]:
        await notify_users(s, [wo["assigned_engineer_id"]], "WO_APPROVED", f"Repair approved: {wo['wo_no']}",
                           comment, _ev_payload(wo))
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "COMPLETED", "post_repair_check": check}


async def reject_repair(s: AsyncSession, wo_id: UUID, user: Any, reason: str, expected: str | None = None) -> dict:
    wo = await _lock_wo(s, wo_id, expected)
    if wo["status"] != "SUBMITTED":
        raise _bad(wo, "reject")
    count = wo["rework_count"] + 1
    await s.execute(text("update work_orders set status = 'REWORK', rejection_reason = :r, rework_count = :c where id = :w"),
                    {"r": reason, "c": count, "w": wo_id})
    await log_event(s, "WORK_ORDER", wo_id, "REJECTED", "SUBMITTED", "REWORK", "USER", user.id, {"reason": reason})
    await _set_event_status(s, wo["leak_event_id"], "IN_PROGRESS", "USER", user.id)
    await set_pipe_state(s, wo["pipe_id"], "UNDER_REPAIR", "Repair rejected", wo["leak_event_id"], "USER")
    await _refresh_engineer(s, wo["assigned_engineer_id"])
    if wo["assigned_engineer_id"]:
        await notify_users(s, [wo["assigned_engineer_id"]], "WO_REJECTED", f"Repair rejected: {wo['wo_no']}",
                           reason, _ev_payload(wo, reason=reason))
    if count >= 2:   # after two rejections the ADMIN users are told as well (10.6)
        await notify_staff(s, "WO_REJECTED", f"{wo['wo_no']} rejected {count} times",
                           f"{wo['pipe_code']}: {reason}", _ev_payload(wo, rework_count=count), roles=("ADMIN",))
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "REWORK", "rework_count": count}


async def cancel_work_order(s: AsyncSession, wo_id: UUID, user: Any, reason: str, expected: str | None = None) -> dict:
    """Operator cancels (false alarm or duplicate): the work order is cancelled and the event closed as FALSE_ALARM."""
    wo = await _lock_wo(s, wo_id, expected)
    if wo["status"] in ("COMPLETED", "CANCELLED"):
        raise _bad(wo, "cancel")
    ev = await _lock_event(s, wo["leak_event_id"])
    await _close_as_false_alarm(s, ev, f"Work order cancelled: {reason}", user, "CANCELLED_VIA_WORK_ORDER")
    return {"id": wo_id, "wo_no": wo["wo_no"], "status": "CANCELLED"}


# ---------------------------------------------------------------- isolation advisory (8.4)
async def _lock_advisory(s: AsyncSession, adv_id: UUID, expected: str | None) -> dict:
    a = await fetchone(s, "select a.id, a.status::text as status, a.leak_event_id, le.pipe_id, le.status::text as event_status, "
                          "le.event_no from isolation_advisories a join leak_events le on le.id = a.leak_event_id "
                          "where a.id = :i for update of a", {"i": adv_id})
    if not a:
        raise not_found("isolation advisory")
    check_expected(a["status"], expected)
    return a


async def acknowledge_advisory(s: AsyncSession, adv_id: UUID, user: Any, expected: str | None = None) -> dict:
    a = await _lock_advisory(s, adv_id, expected)
    if a["status"] != "OPEN":
        raise conflict(f"Cannot acknowledge an advisory in status {a['status']}", "invalid-transition")
    await s.execute(text("update isolation_advisories set status = 'ACKNOWLEDGED', acknowledged_by = :u, "
                         "acknowledged_at = now() where id = :i"), {"u": user.id, "i": adv_id})
    await log_event(s, "ADVISORY", adv_id, "ACKNOWLEDGED", "OPEN", "ACKNOWLEDGED", "USER", user.id)
    return {"id": adv_id, "status": "ACKNOWLEDGED"}


async def _advisory_valve(s: AsyncSession, adv_id: UUID, valve_id: UUID) -> dict:
    v = await fetchone(s, "select av.valve_id, av.close_confirmed_at, av.restore_confirmed_at from isolation_advisory_valves av "
                          "where av.advisory_id = :a and av.valve_id = :v for update", {"a": adv_id, "v": valve_id})
    if not v:
        raise not_found("valve in this advisory")
    return v


async def confirm_valve_closed(s: AsyncSession, adv_id: UUID, valve_id: UUID, user: Any, expected: str | None = None) -> dict:
    a = await _lock_advisory(s, adv_id, expected)
    if a["status"] not in ("OPEN", "ACKNOWLEDGED"):
        raise conflict(f"Valves cannot be confirmed closed while the advisory is {a['status']}", "invalid-transition")
    await _advisory_valve(s, adv_id, valve_id)
    await s.execute(text("update isolation_advisory_valves set close_confirmed_at = now(), close_confirmed_by = :u "
                         "where advisory_id = :a and valve_id = :v"), {"u": user.id, "a": adv_id, "v": valve_id})
    await s.execute(text("update valves set state = 'CLOSED', state_updated_at = now() where id = :v"), {"v": valve_id})
    await twin_sync.queue_command(s, "SET_VALVE_STATE", valve_id=valve_id, leak_event_id=a["leak_event_id"],
                                  params={"state": "CLOSED"}, created_by=user.id)
    await log_event(s, "ADVISORY", adv_id, "VALVE_CLOSED", None, None, "USER", user.id, {"valve_id": str(valve_id)})
    open_left = await scalar(s, "select count(*) from isolation_advisory_valves where advisory_id = :a "
                                "and close_confirmed_at is null", {"a": adv_id})
    status = a["status"]
    if open_left == 0:
        await s.execute(text("update isolation_advisories set status = 'ISOLATED', isolated_at = now() where id = :i"), {"i": adv_id})
        await log_event(s, "ADVISORY", adv_id, "ISOLATED", a["status"], "ISOLATED", "USER", user.id)
        pipe_state = await scalar(s, "select state::text from pipe_segments where id = :p", {"p": a["pipe_id"]})
        if pipe_state == "LEAK":
            await set_pipe_state(s, a["pipe_id"], "ISOLATED", "All advisory valves closed", a["leak_event_id"], "USER")
        status = "ISOLATED"
    return {"id": adv_id, "status": status, "valves_remaining": int(open_left)}


async def confirm_valve_restored(s: AsyncSession, adv_id: UUID, valve_id: UUID, user: Any, expected: str | None = None) -> dict:
    a = await _lock_advisory(s, adv_id, expected)
    if a["status"] != "ISOLATED":
        raise conflict(f"Valves can only be reopened for an ISOLATED advisory (now {a['status']})", "invalid-transition")
    if a["event_status"] not in ("CLOSED", "FALSE_ALARM"):
        raise conflict("Valves can be reopened only after the repair is approved", "repair-not-approved")
    await _advisory_valve(s, adv_id, valve_id)
    await s.execute(text("update isolation_advisory_valves set restore_confirmed_at = now(), restore_confirmed_by = :u "
                         "where advisory_id = :a and valve_id = :v"), {"u": user.id, "a": adv_id, "v": valve_id})
    await s.execute(text("update valves set state = 'OPEN', state_updated_at = now() where id = :v"), {"v": valve_id})
    await twin_sync.queue_command(s, "SET_VALVE_STATE", valve_id=valve_id, leak_event_id=a["leak_event_id"],
                                  params={"state": "OPEN"}, created_by=user.id)
    await log_event(s, "ADVISORY", adv_id, "VALVE_RESTORED", None, None, "USER", user.id, {"valve_id": str(valve_id)})
    left = await scalar(s, "select count(*) from isolation_advisory_valves where advisory_id = :a "
                           "and restore_confirmed_at is null", {"a": adv_id})
    status = "ISOLATED"
    if left == 0:
        await s.execute(text("update isolation_advisories set status = 'RESTORED', restored_at = now() where id = :i"), {"i": adv_id})
        await log_event(s, "ADVISORY", adv_id, "RESTORED", "ISOLATED", "RESTORED", "USER", user.id)
        status = "RESTORED"
    return {"id": adv_id, "status": status, "valves_remaining": int(left)}


async def dismiss_advisory(s: AsyncSession, adv_id: UUID, user: Any, reason: str, expected: str | None = None) -> dict:
    a = await _lock_advisory(s, adv_id, expected)
    if a["status"] not in ("OPEN", "ACKNOWLEDGED"):
        raise conflict(f"Cannot dismiss an advisory in status {a['status']}", "invalid-transition")
    await s.execute(text("update isolation_advisories set status = 'DISMISSED', dismiss_reason = :r where id = :i"),
                    {"r": reason, "i": adv_id})
    await log_event(s, "ADVISORY", adv_id, "DISMISSED", a["status"], "DISMISSED", "USER", user.id, {"reason": reason})
    return {"id": adv_id, "status": "DISMISSED"}
