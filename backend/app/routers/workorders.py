"""Work orders: utility actions and the field-engineer flow (6.5, 10.3-10.6, 11.3)."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Body, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, as_json, fetchall, fetchone, get_session
from app.schemas.common import ActionBody, conflict, forbidden, not_found
from app.schemas.workorders import (ApproveBody, ArriveBody, AssignBody, EvidenceBody, ReasonBody, SubmitBody,
                                    UploadUrlBody)
from app.security import CurrentUser, any_user, engineer_user, staff_user
from app.services import evidence, state

router = APIRouter(prefix="/v1/work-orders", tags=["Work orders"], route_class=TransactionalRoute)


def _exp(body: ActionBody | None) -> str | None:
    return body.expected_status if body else None


async def _wo_for_engineer(s: AsyncSession, wo_id: UUID, user: CurrentUser) -> dict:
    wo = await fetchone(s, "select id, status::text as status, assigned_engineer_id, leak_event_id from work_orders where id = :i",
                        {"i": wo_id})
    if not wo:
        raise not_found("work order")
    if wo["assigned_engineer_id"] != user.id:
        raise forbidden("This work order is not assigned to you")
    return wo


@router.get("/{wo_id}", summary="Work-order and leak details for the assigned engineer")
async def get_work_order(wo_id: UUID, user: CurrentUser = Depends(any_user),
                         s: AsyncSession = Depends(get_session)):
    row = await fetchone(s, """select w.id, w.wo_no, w.status::text as status, w.priority::text as priority,
                                  w.sla_due_at, w.assigned_at, w.accepted_at, w.en_route_at, w.arrived_at,
                                  w.submitted_at, w.approved_at, w.rejection_reason, w.created_at,
                                  w.assigned_engineer_id,
                                  w.repair_type, w.materials, w.labour_minutes, w.work_notes,
                                  e.id as event_id, e.event_no, e.severity::text as severity,
                                  e.source::text as source, e.confidence, e.detected_at,
                                  e.est_leak_rate_lpm, e.est_loss_pct, e.chainage_m,
                                  ST_X(e.location::geometry) as lon, ST_Y(e.location::geometry) as lat,
                                  p.code as pipe_code
                           from work_orders w
                           join leak_events e on e.id = w.leak_event_id
                           join pipe_segments p on p.id = e.pipe_id
                           where w.id = :id""", {"id": wo_id})
    if not row:
        raise not_found("work order")
    if user.role == "ENGINEER" and row["assigned_engineer_id"] != user.id:
        raise forbidden("This work order is not assigned to you")
    return {
        "id": str(row["id"]),
        "wo_no": row["wo_no"],
        "status": row["status"],
        "priority": row["priority"],
        "sla_due_at": row["sla_due_at"],
        "assigned_at": row["assigned_at"],
        "accepted_at": row["accepted_at"],
        "en_route_at": row["en_route_at"],
        "arrived_at": row["arrived_at"],
        "submitted_at": row["submitted_at"],
        "approved_at": row["approved_at"],
        "rejection_reason": row["rejection_reason"],
        "created_at": row["created_at"],
        "leak_event": {
            "id": str(row["event_id"]),
            "event_no": row["event_no"],
            "severity": row["severity"],
            "source": row["source"],
            "is_simulated": row["source"] == "TWIN",
            "pipe_code": row["pipe_code"],
            "lon": row["lon"],
            "lat": row["lat"],
            "leak_confidence": row["confidence"],
            "detected_at": row["detected_at"],
            "estimated_leak_rate_lpm": row["est_leak_rate_lpm"],
            "estimated_loss_pct": row["est_loss_pct"],
            "chainage_m": float(row["chainage_m"]) if row["chainage_m"] is not None else None,
        },
        "repair_details": ({
            "repair_type": row["repair_type"],
            "materials": as_json(row["materials"]),
            "labour_minutes": row["labour_minutes"],
            "work_notes": row["work_notes"],
        } if row["repair_type"] else None),
    }


# ----- utility (ADMIN, OPERATOR)
@router.post("/{wo_id}/assign", summary="Assign an engineer")
async def assign(wo_id: UUID, body: AssignBody, user: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    return await state.assign_work_order(s, wo_id, body.engineer_id, user, body.expected_status)


@router.post("/{wo_id}/approve", summary="Approve the repair (10.5)")
async def approve(wo_id: UUID, body: ApproveBody | None = Body(default=None), user: CurrentUser = Depends(staff_user),
                  s: AsyncSession = Depends(get_session)):
    return await state.approve_repair(s, wo_id, user, body.comment if body else None, _exp(body))


@router.post("/{wo_id}/reject", summary="Reject the repair (reason required)")
async def reject(wo_id: UUID, body: ReasonBody, user: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    return await state.reject_repair(s, wo_id, user, body.reason, body.expected_status)


@router.post("/{wo_id}/cancel", summary="Cancel (false alarm or duplicate)")
async def cancel(wo_id: UUID, body: ReasonBody, user: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    return await state.cancel_work_order(s, wo_id, user, body.reason, body.expected_status)


@router.get("/{wo_id}/evidence", summary="Evidence with 15-minute signed download URLs")
async def list_evidence(wo_id: UUID, user: CurrentUser = Depends(any_user), s: AsyncSession = Depends(get_session)):
    wo = await fetchone(s, "select id, assigned_engineer_id from work_orders where id = :i", {"i": wo_id})
    if not wo:
        raise not_found("work order")
    if user.role == "ENGINEER" and wo["assigned_engineer_id"] != user.id:
        raise forbidden("This work order is not assigned to you")
    rows = await fetchall(s, """select id, kind::text as kind, storage_path, mime_type, size_bytes, captured_at,
                                distance_to_leak_m, geo_valid, created_at,
                                ST_X(captured_location::geometry) as lon, ST_Y(captured_location::geometry) as lat
                                from repair_evidence where work_order_id = :w order by created_at""", {"w": wo_id})
    urls = await evidence.signed_download_urls([r["storage_path"] for r in rows])
    for r in rows:
        r["url"] = urls.get(r["storage_path"])
    return {"items": rows, "expires_in_s": 900}


# ----- field engineer
@router.post("/{wo_id}/accept", summary="ASSIGNED -> ACCEPTED")
async def accept(wo_id: UUID, body: ActionBody | None = Body(default=None), user: CurrentUser = Depends(engineer_user),
                 s: AsyncSession = Depends(get_session)):
    return await state.accept_work_order(s, wo_id, user, _exp(body))


@router.post("/{wo_id}/decline", summary="Decline the assignment")
async def decline(wo_id: UUID, body: ReasonBody, user: CurrentUser = Depends(engineer_user), s: AsyncSession = Depends(get_session)):
    return await state.decline_work_order(s, wo_id, user, body.reason, body.expected_status)


@router.post("/{wo_id}/en-route", summary="Start travel")
async def en_route(wo_id: UUID, body: ActionBody | None = Body(default=None), user: CurrentUser = Depends(engineer_user),
                   s: AsyncSession = Depends(get_session)):
    return await state.start_travel(s, wo_id, user, _exp(body))


@router.post("/{wo_id}/arrive", summary="Arrive on site (geofence check)")
async def arrive(wo_id: UUID, body: ArriveBody, user: CurrentUser = Depends(engineer_user), s: AsyncSession = Depends(get_session)):
    return await state.arrive(s, wo_id, user, body.lat, body.lon, body.override_reason, body.expected_status)


@router.post("/{wo_id}/evidence/upload-url", summary="Signed upload URL (step 1 of 3)")
async def evidence_upload_url(wo_id: UUID, body: UploadUrlBody, user: CurrentUser = Depends(engineer_user),
                              s: AsyncSession = Depends(get_session)):
    wo = await _wo_for_engineer(s, wo_id, user)
    if wo["status"] not in ("ON_SITE", "REWORK"):
        raise conflict(f"Evidence can be uploaded only while ON_SITE or REWORK (now {wo['status']})", "invalid-transition")
    return {**await evidence.create_upload_url(wo_id, body.mime_type, body.size_bytes), "kind": body.kind}


@router.post("/{wo_id}/evidence", status_code=201, summary="Register an uploaded photo (step 3 of 3)")
async def register_evidence(wo_id: UUID, body: EvidenceBody, user: CurrentUser = Depends(engineer_user),
                           s: AsyncSession = Depends(get_session)):
    wo = await _wo_for_engineer(s, wo_id, user)
    if wo["status"] not in ("ON_SITE", "REWORK"):
        raise conflict(f"Evidence can be registered only while ON_SITE or REWORK (now {wo['status']})", "invalid-transition")
    return await evidence.register(s, wo, wo["leak_event_id"], user.id, body)


@router.post("/{wo_id}/submit", summary="Submit the repair (needs valid evidence)")
async def submit(wo_id: UUID, body: SubmitBody, user: CurrentUser = Depends(engineer_user), s: AsyncSession = Depends(get_session)):
    return await state.submit_repair(s, wo_id, user, body, body.expected_status)
