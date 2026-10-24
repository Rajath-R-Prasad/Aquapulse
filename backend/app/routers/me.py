"""Calling user: profile, own jobs, engineer status/location, push token, notifications."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, fetchall, fetchone, get_session
from app.schemas.common import conflict, decode_cursor, encode_cursor, not_found
from app.schemas.workorders import EngineerStatusBody, LocationBody, PushTokenBody
from app.security import CurrentUser, any_user, engineer_user

router = APIRouter(tags=["Me"], route_class=TransactionalRoute)


@router.get("/v1/me", summary="Profile and role")
async def me(user: CurrentUser = Depends(any_user), s: AsyncSession = Depends(get_session)):
    p = await fetchone(s, "select id, full_name, role::text as role, phone from profiles where id = :i", {"i": user.id})
    eng = await fetchone(s, "select employee_code, status::text as status, skills, max_active_jobs from engineers where profile_id = :i",
                         {"i": user.id}) if user.role == "ENGINEER" else None
    return {**p, "engineer": eng}


@router.get("/v1/me/work-orders", summary="Own jobs, filter by status")
async def my_work_orders(status: str | None = None, limit: int = Query(50, ge=1, le=200), cursor: str | None = None,
                         user: CurrentUser = Depends(engineer_user), s: AsyncSession = Depends(get_session)):
    where, params = ["w.assigned_engineer_id = :u"], {"u": user.id, "l": limit + 1}
    if status:
        where.append("w.status::text = :st"); params["st"] = status
    if cursor:
        t, i = decode_cursor(cursor)
        where.append("(w.created_at, w.id) < (:ct, CAST(:ci AS uuid))"); params.update(ct=t, ci=i)
    rows = await fetchall(s, f"""select w.id, w.wo_no, w.status::text as status, w.priority::text as priority, w.sla_due_at,
                                 w.assigned_at, w.accepted_at, w.arrived_at, w.rejection_reason, w.created_at,
                                 w.leak_event_id, e.event_no, e.severity::text as severity, e.source::text as source,
                                 (e.source = 'TWIN') as is_simulated, p.code as pipe_code,
                                 ST_X(e.location::geometry) as lon, ST_Y(e.location::geometry) as lat
                                 from work_orders w join leak_events e on e.id = w.leak_event_id
                                 join pipe_segments p on p.id = e.pipe_id where {' and '.join(where)}
                                 order by w.created_at desc, w.id desc limit :l""", params)
    nxt = None
    if len(rows) > limit:
        rows = rows[:limit]
        nxt = encode_cursor(rows[-1]["created_at"], rows[-1]["id"])
    return {"items": rows, "next_cursor": nxt}


@router.put("/v1/me/engineer/status", summary="AVAILABLE or OFF_DUTY")
async def set_status(body: EngineerStatusBody, user: CurrentUser = Depends(engineer_user), s: AsyncSession = Depends(get_session)):
    live = await fetchone(s, "select count(*)::int as n from work_orders where assigned_engineer_id = :u "
                             "and status in ('ASSIGNED','ACCEPTED','EN_ROUTE','ON_SITE','REWORK','SUBMITTED')", {"u": user.id})
    if body.status == "OFF_DUTY" and live["n"] > 0:
        raise conflict("Cannot go off duty while you have a live job", "live-job")
    if body.status == "AVAILABLE" and live["n"] > 0:
        return {"status": "ASSIGNED"}          # status follows the work order while a job is live
    await s.execute(text("update engineers set status = CAST(:st AS engineer_status) where profile_id = :u"),
                    {"st": body.status, "u": user.id})
    return {"status": body.status}


@router.post("/v1/me/location", summary="Engineer position (latest only; no history is stored)")
async def post_location(body: LocationBody, user: CurrentUser = Depends(engineer_user), s: AsyncSession = Depends(get_session)):
    await s.execute(text("""update engineers set last_location = ST_SetSRID(ST_MakePoint(:lon,:lat),4326)::geography,
                            last_location_at = least(coalesce(CAST(:ts AS timestamptz), now()), now()) where profile_id = :u"""),
                    {"lon": body.lon, "lat": body.lat, "ts": body.captured_at, "u": user.id})
    return {"ok": True}


@router.post("/v1/me/push-token", summary="Register an FCM token")
async def push_token(body: PushTokenBody, user: CurrentUser = Depends(any_user), s: AsyncSession = Depends(get_session)):
    await s.execute(text("""insert into device_tokens (profile_id, token, platform) values (:u, :t, :p)
                            on conflict (token) do update set profile_id = excluded.profile_id, platform = excluded.platform"""),
                    {"u": user.id, "t": body.token, "p": body.platform})
    return {"ok": True}


@router.get("/v1/notifications", summary="Own notifications")
async def notifications(unread_only: bool = False, limit: int = Query(50, ge=1, le=200), cursor: str | None = None,
                        user: CurrentUser = Depends(any_user), s: AsyncSession = Depends(get_session)):
    where, params = ["recipient_id = :u"], {"u": user.id, "l": limit + 1}
    if unread_only:
        where.append("read_at is null")
    if cursor:
        t, i = decode_cursor(cursor)
        where.append("(created_at, id) < (:ct, CAST(:ci AS uuid))"); params.update(ct=t, ci=i)
    rows = await fetchall(s, f"select id, type::text as type, title, body, payload, read_at, created_at from notifications "
                             f"where {' and '.join(where)} order by created_at desc, id desc limit :l", params)
    nxt = None
    if len(rows) > limit:
        rows = rows[:limit]
        nxt = encode_cursor(rows[-1]["created_at"], rows[-1]["id"])
    return {"items": rows, "next_cursor": nxt}


@router.post("/v1/notifications/{notification_id}/read", summary="Mark read")
async def mark_read(notification_id: UUID, user: CurrentUser = Depends(any_user), s: AsyncSession = Depends(get_session)):
    r = await s.execute(text("update notifications set read_at = coalesce(read_at, now()) where id = :i and recipient_id = :u"),
                        {"i": notification_id, "u": user.id})
    if r.rowcount == 0:
        raise not_found("notification")
    return {"ok": True}
