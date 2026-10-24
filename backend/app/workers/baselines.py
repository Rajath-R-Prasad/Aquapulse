"""Nightly baseline updater (10.8): recompute pipe_baselines from no-event periods only."""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import text

from app.config import settings
from app.db import session_scope

log = logging.getLogger("AquaPulse.baselines")
LOOKBACK_DAYS = 14

# Periods from 5 minutes before detection until 10 minutes after closure are excluded.
NO_EVENT = """not exists (select 1 from leak_events e where e.pipe_id = r.pipe_id
                and r.received_at >= e.detected_at - interval '5 minutes'
                and r.received_at <= coalesce(e.closed_at, now()) + interval '10 minutes')"""

HW_SQL = f"""
insert into pipe_baselines (pipe_id, source, dow, hour, flow_in_mean_lpm, flow_in_std_lpm, delta_q_mean_lpm, delta_q_std_lpm,
                            pressure_in_mean_kpa, pressure_in_std_kpa, samples, updated_at)
select r.pipe_id, CAST('HARDWARE' AS data_source),
       extract(dow from (r.recorded_at at time zone :tz))::int, extract(hour from (r.recorded_at at time zone :tz))::int,
       avg(r.flow_in_lpm), coalesce(stddev_samp(r.flow_in_lpm), 0),
       avg(r.flow_in_lpm - r.flow_out_lpm), coalesce(stddev_samp(r.flow_in_lpm - r.flow_out_lpm), 0),
       avg(r.pressure_in_kpa), coalesce(stddev_samp(r.pressure_in_kpa), 0), count(*), now()
from hw_readings r
where r.recorded_at > now() - make_interval(days => :d)
  and r.flow_in_lpm is not null and r.flow_out_lpm is not null and r.pressure_in_kpa is not null
  and not exists (select 1 from jsonb_each_text(r.quality) q where q.value = 'BAD')
  and {NO_EVENT}
group by 1, 3, 4
on conflict (pipe_id, source, dow, hour) do update set
  flow_in_mean_lpm = excluded.flow_in_mean_lpm, flow_in_std_lpm = excluded.flow_in_std_lpm,
  delta_q_mean_lpm = excluded.delta_q_mean_lpm, delta_q_std_lpm = excluded.delta_q_std_lpm,
  pressure_in_mean_kpa = excluded.pressure_in_mean_kpa, pressure_in_std_kpa = excluded.pressure_in_std_kpa,
  samples = excluded.samples, updated_at = now()"""

TWIN_SQL = f"""
insert into pipe_baselines (pipe_id, source, dow, hour, flow_in_mean_lpm, flow_in_std_lpm, delta_q_mean_lpm, delta_q_std_lpm,
                            pressure_in_mean_kpa, pressure_in_std_kpa, samples, updated_at)
select r.pipe_id, CAST('TWIN' AS data_source),
       extract(dow from (r.sim_time at time zone :tz))::int, extract(hour from (r.sim_time at time zone :tz))::int,
       avg(r.flow_in_lpm), coalesce(stddev_samp(r.flow_in_lpm), 0),
       avg(r.flow_in_lpm - r.flow_out_lpm), coalesce(stddev_samp(r.flow_in_lpm - r.flow_out_lpm), 0),
       avg(r.pressure_in_kpa), coalesce(stddev_samp(r.pressure_in_kpa), 0), count(*), now()
from twin_pipe_readings r
where r.received_at > now() - make_interval(days => :d)
  and r.flow_in_lpm is not null and r.flow_out_lpm is not null and r.pressure_in_kpa is not null
  and coalesce(r.injected_leak_lpm, 0) = 0
  and {NO_EVENT}
group by 1, 3, 4
on conflict (pipe_id, source, dow, hour) do update set
  flow_in_mean_lpm = excluded.flow_in_mean_lpm, flow_in_std_lpm = excluded.flow_in_std_lpm,
  delta_q_mean_lpm = excluded.delta_q_mean_lpm, delta_q_std_lpm = excluded.delta_q_std_lpm,
  pressure_in_mean_kpa = excluded.pressure_in_mean_kpa, pressure_in_std_kpa = excluded.pressure_in_std_kpa,
  samples = excluded.samples, updated_at = now()"""


async def update_baselines() -> None:
    async with session_scope() as s:
        for sql in (HW_SQL, TWIN_SQL):
            await s.execute(text(sql), {"tz": settings.app_timezone, "d": LOOKBACK_DAYS})
    log.info("baselines recomputed")


def seconds_until(hour: int) -> float:
    now = datetime.now(ZoneInfo(settings.app_timezone))
    nxt = now.replace(hour=hour, minute=0, second=0, microsecond=0)
    if nxt <= now:
        nxt += timedelta(days=1)
    return (nxt - now).total_seconds()


async def run() -> None:
    await asyncio.sleep(120)            # one early pass so a fresh demo gets baselines
    while True:
        try:
            await update_baselines()
        except asyncio.CancelledError:
            raise
        except Exception:
            log.exception("baseline update failed")
        await asyncio.sleep(seconds_until(2))   # nightly at 02:00 local time
