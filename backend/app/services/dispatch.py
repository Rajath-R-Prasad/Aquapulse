"""Engineer ranking for dispatch (10.3). Scoring lives in the rank_engineers SQL function."""
from __future__ import annotations

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.db import fetchall, fetchone


def breakdown(row: dict, max_active_jobs: int) -> dict:
    """Re-derives the weighted components of the score for storage in work_order_assignments."""
    distance = row["distance_m"]
    prox = max(0.0, 1 - distance / 20000.0) if distance is not None else 0.0
    avail = 1.0 if row["status"] == "AVAILABLE" else 0.0
    load = 1 - (row["active_jobs"] or 0) / max(max_active_jobs, 1)
    skill = 1.0 if row["has_skill"] else 0.0
    return {"proximity": {"value": round(prox, 3), "weight": 0.50}, "availability": {"value": avail, "weight": 0.25},
            "workload": {"value": round(load, 3), "weight": 0.15}, "skill": {"value": skill, "weight": 0.10},
            "distance_m": distance}


async def rank(s: AsyncSession, event_id: UUID, skill: str = "PIPE_REPAIR", limit: int = 5) -> list[dict]:
    rows = await fetchall(s, "select * from rank_engineers(:e, :sk, :l)", {"e": event_id, "sk": skill, "l": limit})
    out = []
    for r in rows:
        eng = await fetchone(s, "select max_active_jobs from engineers where profile_id = :i", {"i": r["engineer_id"]})
        r["score_breakdown"] = breakdown(r, eng["max_active_jobs"] if eng else 1)
        r["score"] = float(r["score"])
        out.append(r)
    return out
