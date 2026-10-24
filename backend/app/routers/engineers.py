"""Engineer candidates for dispatch (10.3)."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, fetchall, get_session
from app.schemas.common import not_found
from app.security import CurrentUser, staff_user
from app.services import dispatch

router = APIRouter(tags=["Dispatch"], route_class=TransactionalRoute)


@router.get("/v1/leak-events/{event_id}/engineer-candidates", summary="Ranked engineers (advisory)")
async def engineer_candidates(event_id: UUID, limit: int = Query(5, ge=1, le=20), skill: str = "PIPE_REPAIR",
                              _: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    if not await fetchall(s, "select 1 from leak_events where id = :e", {"e": event_id}):
        raise not_found("leak event")
    items = await dispatch.rank(s, event_id, skill, limit)
    return {"items": items}


@router.get("/v1/engineers", summary="All engineers with status and last known position")
async def list_engineers(_: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    rows = await fetchall(s, """select e.profile_id as id, p.full_name, e.employee_code, e.status::text as status, e.skills,
                                e.max_active_jobs, e.last_location_at,
                                ST_X(e.last_location::geometry) as lon, ST_Y(e.last_location::geometry) as lat
                                from engineers e join profiles p on p.id = e.profile_id where p.is_active order by p.full_name""")
    return {"items": rows}
