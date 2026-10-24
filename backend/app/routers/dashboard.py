"""Dashboard summary and signal history (the only way clients read raw telemetry)."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, fetchall, fetchone, get_session
from app.schemas.common import not_found
from app.security import CurrentUser, staff_user

router = APIRouter(tags=["Dashboard"], route_class=TransactionalRoute)
BUCKETS = {"10s": 10.0, "1m": 60.0, "5m": 300.0}   # bucket width in seconds


@router.get("/v1/pipes/{pipe_id}/signals", summary="Signal history for charts")
async def pipe_signals(pipe_id: UUID, source: Literal["HARDWARE", "TWIN"] | None = None, from_: datetime | None = Query(None, alias="from"),
                       to: datetime | None = None, bucket: Literal["10s", "1m", "5m"] = "1m",
                       _: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    pipe = await fetchone(s, "select monitoring::text as monitoring from pipe_segments where id = :p", {"p": pipe_id})
    if not pipe:
        raise not_found("pipe")
    source = source or ("HARDWARE" if pipe["monitoring"] == "HARDWARE" else "TWIN")
    to = to or datetime.now(timezone.utc)
    from_ = from_ or to - timedelta(hours=1)
    table, tcol, extra = (("hw_readings", "recorded_at", ", avg(acoustic_rms) as acoustic_rms") if source == "HARDWARE"
                          else ("twin_pipe_readings", "sim_time", ""))
    rows = await fetchall(s, f"""
        select date_bin(make_interval(secs => :b), {tcol}, TIMESTAMPTZ '2001-01-01') as ts,
               avg(flow_in_lpm) as flow_in_lpm, avg(flow_out_lpm) as flow_out_lpm,
               avg(flow_in_lpm - flow_out_lpm) as delta_q_lpm, avg(pressure_in_kpa) as pressure_in_kpa,
               avg(pressure_out_kpa) as pressure_out_kpa{extra}
        from {table} where pipe_id = :p and {tcol} between :f and :t
        group by 1 order by 1 limit 5000""", {"b": BUCKETS[bucket], "p": pipe_id, "f": from_, "t": to})
    return {"pipe_id": pipe_id, "source": source, "is_simulated": source == "TWIN", "bucket": bucket, "points": rows}


@router.get("/v1/dashboard/summary", summary="Open events by severity, devices online, mean time to repair")
async def summary(_: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    sev = await fetchall(s, "select severity::text as severity, count(*)::int as n from leak_events "
                            "where status not in ('CLOSED','FALSE_ALARM') group by 1")
    dev = await fetchall(s, "select status::text as status, count(*)::int as n from devices group by 1")
    mttr = await fetchone(s, "select (extract(epoch from avg(closed_at - detected_at)) / 3600.0)::float as hours, count(*)::int as n "
                             "from leak_events where status = 'CLOSED' and closed_at > now() - interval '30 days'")
    pipes = await fetchall(s, "select state::text as state, count(*)::int as n from pipe_segments group by 1")
    return {"open_events_by_severity": {r["severity"]: r["n"] for r in sev}, "devices_by_status": {r["status"]: r["n"] for r in dev},
            "devices_online": next((r["n"] for r in dev if r["status"] == "ONLINE"), 0),
            "pipes_by_state": {r["state"]: r["n"] for r in pipes},
            "mean_time_to_repair_hours_30d": mttr["hours"], "repairs_closed_30d": mttr["n"]}
