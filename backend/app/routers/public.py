"""Unauthenticated public impact status: aggregate numbers only, never network or staff details."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, fetchone, get_session

router = APIRouter(prefix="/v1/public", tags=["Public"], route_class=TransactionalRoute)


@router.get("/status", summary="Public leak impact status")
async def public_status(s: AsyncSession = Depends(get_session)):
    row = await fetchone(s, """
        select status, active_leaks, households_affected, household_days, updated_at
        from public_impact where id = true""")
    if not row:
        row = {"status": "NORMAL", "active_leaks": 0, "households_affected": 0,
               "household_days": 0, "updated_at": datetime.now(timezone.utc)}
    return {
        "status": row["status"],
        "active_leaks": row["active_leaks"],
        "households_affected": row["households_affected"],
        "household_days": float(row["household_days"]),
        "estimated": True,
        "updated_at": row["updated_at"],
    }
