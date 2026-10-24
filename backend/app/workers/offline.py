"""Device offline sweeper (10.7): every 30 s. Offline is never treated as a leak."""
from __future__ import annotations

from app.db import fetchall, session_scope
from app.services.notify import notify_staff
from app.services.state import log_event
from app.workers import periodic


async def sweep() -> None:
    async with session_scope() as s:
        rows = await fetchall(s, """
            update devices set status = 'OFFLINE'
            where status = 'ONLINE' and last_seen_at < now() - make_interval(secs => greatest(30, 3 * report_interval_s))
            returning id, device_uid, pipe_id""")
        for d in rows:
            await log_event(s, "DEVICE", d["id"], "OFFLINE", "ONLINE", "OFFLINE", "SYSTEM")
            await notify_staff(s, "DEVICE_OFFLINE", f"Device {d['device_uid']} is offline",
                               "No readings received. This is not treated as a leak.",
                               {"device_uid": d["device_uid"], "pipe_id": str(d["pipe_id"])})


async def run() -> None:
    await periodic("offline-sweeper", 30, sweep, 10)
