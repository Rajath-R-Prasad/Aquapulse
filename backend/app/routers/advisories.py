"""Isolation advisories: acknowledge, confirm valves closed / restored, dismiss (11.3)."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Body, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, get_session
from app.schemas.common import ActionBody
from app.schemas.events import DismissBody
from app.security import CurrentUser, staff_user
from app.services import state

router = APIRouter(prefix="/v1/isolation-advisories", tags=["Isolation advisories"], route_class=TransactionalRoute)


@router.post("/{advisory_id}/acknowledge")
async def acknowledge(advisory_id: UUID, body: ActionBody | None = Body(default=None),
                      user: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    return await state.acknowledge_advisory(s, advisory_id, user, body.expected_status if body else None)


@router.post("/{advisory_id}/valves/{valve_id}/confirm-closed")
async def confirm_closed(advisory_id: UUID, valve_id: UUID, body: ActionBody | None = Body(default=None),
                         user: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    return await state.confirm_valve_closed(s, advisory_id, valve_id, user, body.expected_status if body else None)


@router.post("/{advisory_id}/valves/{valve_id}/confirm-restored")
async def confirm_restored(advisory_id: UUID, valve_id: UUID, body: ActionBody | None = Body(default=None),
                           user: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    return await state.confirm_valve_restored(s, advisory_id, valve_id, user, body.expected_status if body else None)


@router.post("/{advisory_id}/dismiss")
async def dismiss(advisory_id: UUID, body: DismissBody, user: CurrentUser = Depends(staff_user),
                  s: AsyncSession = Depends(get_session)):
    return await state.dismiss_advisory(s, advisory_id, user, body.reason, body.expected_status)
