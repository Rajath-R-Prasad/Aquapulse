"""Assignment timeout (every 60 s) and refresh of the post-repair check shown to the approver."""
from __future__ import annotations

import logging

from sqlalchemy import text

from app.db import dumps, fetchall, get_setting, session_scope
from app.services import evidence, state
from app.workers import periodic

log = logging.getLogger("AquaPulse.timeouts")


async def time_out_assignments() -> None:
    timeout = (await get_setting("dispatch"))["accept_timeout_s"]
    async with session_scope() as s:
        rows = await fetchall(s, """
            select w.id from work_orders w
            join work_order_assignments a on a.work_order_id = w.id and a.response = 'PENDING'
            where w.status = 'ASSIGNED' and a.assigned_at < now() - make_interval(secs => :t)""", {"t": float(timeout)})
    for r in rows:
        try:
            async with session_scope() as s:
                await state.timeout_assignment(s, r["id"])
        except Exception:
            log.exception("timeout failed for %s", r["id"])


async def refresh_post_repair_checks() -> None:
    """HARDWARE only: mean residuals over the 5 minutes after submission; recomputed until the window is complete."""
    async with session_scope() as s:
        rows = await fetchall(s, """
            select w.id, w.submitted_at, le.pipe_id, le.source::text as source
            from work_orders w join leak_events le on le.id = w.leak_event_id
            where w.status = 'SUBMITTED' and le.source = 'HARDWARE' and w.submitted_at > now() - interval '30 minutes'""")
        for w in rows:
            check = await evidence.post_repair_check(s, w, w)
            await s.execute(text("update work_orders set post_repair_check = CAST(:c AS jsonb) where id = :i"),
                            {"c": dumps(check), "i": w["id"]})


async def run() -> None:
    import asyncio

    await asyncio.gather(periodic("assignment-timeout", 60, time_out_assignments, 30),
                         periodic("post-repair-check", 60, refresh_post_repair_checks, 45))
