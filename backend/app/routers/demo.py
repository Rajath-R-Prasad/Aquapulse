"""Read-only, unauthenticated data for the hackathon operator dashboard."""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, fetchall, get_session
from app.services.twin_sync import network_geojson

router = APIRouter(prefix="/v1/demo", tags=["Public demo"], route_class=TransactionalRoute)


@router.get("/dashboard", summary="Read-only digital-twin dashboard data")
async def demo_dashboard(s: AsyncSession = Depends(get_session)):
    network = await network_geojson(s)
    events = await fetchall(
        s,
        """select id, event_no, source::text as source, status::text as status,
                  severity::text as severity, priority::text as priority,
                  est_leak_rate_lpm, est_loss_pct, detected_at, lon, lat, pipe_code,
                  advisory_status::text as advisory_status, advisory_urgency::text as advisory_urgency
           from v_leak_events_enriched
           where source = 'TWIN' and status not in ('CLOSED', 'FALSE_ALARM')
           order by detected_at desc limit 100""",
    )
    signals = await fetchall(
        s,
        """select p.code as pipe_code, p.state::text as pipe_state, sl.ts,
                  sl.flow_in_lpm, sl.flow_out_lpm, sl.pressure_in_kpa, sl.pressure_out_kpa,
                  latest.injected_leak_lpm
           from pipe_segments p
           left join signal_latest sl on sl.pipe_id = p.id and sl.source = 'TWIN'
           left join lateral (
               select tr.injected_leak_lpm
               from twin_pipe_readings tr
               join twin_runs r on r.id = tr.run_id
               where tr.pipe_id = p.id and r.status = 'RUNNING'
                 and tr.sim_time > now() - interval '30 seconds'
               order by r.started_at desc, tr.sim_time desc
               limit 1
           ) latest on true
           where p.monitoring = 'SIMULATED'
           order by p.code""",
    )
    severity_counts = await fetchall(
        s,
        """select severity::text as severity, count(*)::int as count
           from leak_events
           where source = 'TWIN' and status not in ('CLOSED', 'FALSE_ALARM')
           group by severity""",
    )
    return {
        "network": network,
        "events": events,
        "signals": signals,
        "open_events_by_severity": {row["severity"]: row["count"] for row in severity_counts},
    }
