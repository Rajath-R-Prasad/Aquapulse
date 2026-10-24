"""Daily retention (7.x / 13): delete raw rows older than app_settings.retention_days."""
from __future__ import annotations

import logging

from sqlalchemy import text

from app.db import get_setting, session_scope
from app.workers import periodic

log = logging.getLogger("AquaPulse.retention")


async def purge() -> None:
    cfg = await get_setting("retention_days")
    async with session_scope() as s:
        for table, col in (("hw_readings", "received_at"), ("twin_pipe_readings", "received_at")):
            days = int(cfg.get(table, 90))
            r = await s.execute(text(f"delete from {table} where {col} < now() - make_interval(days => :d)"), {"d": days})
            log.info("retention: %s deleted %s rows", table, r.rowcount)
        days = int(cfg.get("ml_inferences", 90))
        # inferences that triggered an event are kept (leak_events.trigger_inference_id references them)
        r = await s.execute(text("delete from ml_inferences i where i.created_at < now() - make_interval(days => :d) "
                                 "and not exists (select 1 from leak_events e where e.trigger_inference_id = i.id)"), {"d": days})
        log.info("retention: ml_inferences deleted %s rows", r.rowcount)


async def run() -> None:
    await periodic("retention", 24 * 3600, purge, 300)
