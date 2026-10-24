"""Advisory re-notifier (8.4): IMMEDIATE advisories still OPEN after 5 minutes are re-sent every 5 minutes."""
from __future__ import annotations

from app.db import fetchall, session_scope
from app.services.notify import notify_staff
from app.workers import periodic

SQL = """
select a.id, a.leak_event_id, a.message, le.event_no, p.code as pipe_code, le.severity::text as severity
from isolation_advisories a
join leak_events le on le.id = a.leak_event_id
join pipe_segments p on p.id = le.pipe_id
where a.urgency = 'IMMEDIATE' and a.status = 'OPEN' and a.created_at < now() - interval '5 minutes'
  and coalesce((select max(n.created_at) from notifications n
                where n.type = 'ISOLATION_ADVISORY' and n.payload->>'advisory_id' = a.id::text), a.created_at)
      < now() - interval '5 minutes'"""


async def renotify() -> None:
    async with session_scope() as s:
        for a in await fetchall(s, SQL):
            await notify_staff(s, "ISOLATION_ADVISORY", f"Reminder: isolate {a['pipe_code']}", a["message"],
                               {"leak_event_id": str(a["leak_event_id"]), "advisory_id": str(a["id"]),
                                "pipe_code": a["pipe_code"], "severity": a["severity"], "reminder": True})


async def run() -> None:
    await periodic("advisory-renotifier", 60, renotify, 20)
