"""Public impact worker: recompute aggregate leak impact every 60 seconds (aggregate only)."""
from __future__ import annotations

import logging
from datetime import datetime, timezone

from sqlalchemy import text

from app.db import fetchall, get_setting, session_scope
from app.services.impact import compute_impact
from app.workers import periodic

log = logging.getLogger("AquaPulse.public-impact")


async def refresh() -> None:
    cfg = await get_setting("public_impact")
    lpcd = float(cfg.get("lpcd", 135))
    persons_per_household = float(cfg.get("persons_per_household", 4))
    now = datetime.now(timezone.utc)

    async with session_scope() as s:
        open_events = await fetchall(s, """
            select le.id, le.est_leak_rate_lpm, le.detected_at,
                   (select min(ia.isolated_at) from isolation_advisories ia
                    where ia.leak_event_id = le.id and ia.isolated_at is not null) as isolated_at
            from leak_events le
            where le.status not in ('CLOSED', 'FALSE_ALARM')""")
        advisory_pipe_ids = [r["pipe_id"] for r in await fetchall(s, """
            select distinct le.pipe_id
            from isolation_advisories a
            join leak_events le on le.id = a.leak_event_id
            where a.status in ('OPEN', 'ACKNOWLEDGED', 'ISOLATED')
              and le.status not in ('CLOSED', 'FALSE_ALARM')""")]
        pipes = {r["id"]: r for r in await fetchall(s, "select id, from_node, to_node from pipe_segments")}
        nodes = {r["id"]: r for r in await fetchall(s, "select id, kind::text as kind, served_connections from network_nodes")}
        valves = await fetchall(s, "select id, pipe_id, at_node, kind::text as kind, state::text as state from valves")

        values = compute_impact(open_events, advisory_pipe_ids, pipes, nodes, valves,
                                lpcd=lpcd, persons_per_household=persons_per_household, now=now)
        await s.execute(text("""
            insert into public_impact (id, status, active_leaks, water_lost_l, households_affected, household_days, updated_at)
            values (true, :status, :active_leaks, :water_lost_l, :households_affected, :household_days, :updated_at)
            on conflict (id) do update set
                status = excluded.status,
                active_leaks = excluded.active_leaks,
                water_lost_l = excluded.water_lost_l,
                households_affected = excluded.households_affected,
                household_days = excluded.household_days,
                updated_at = excluded.updated_at"""),
            {**values, "updated_at": now})


async def run() -> None:
    await periodic("public-impact", 60, refresh, 0)
