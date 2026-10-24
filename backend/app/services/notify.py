"""In-app notifications (rows -> Realtime) and best-effort FCM push after commit."""
from __future__ import annotations

import asyncio
import json
import logging
from typing import Iterable
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db import dumps

log = logging.getLogger("AquaPulse.notify")
_fcm_ready: bool | None = None


async def notify_users(s: AsyncSession, recipients: Iterable[UUID], type_: str, title: str, body: str | None = None,
                       payload: dict | None = None) -> None:
    recipients = list(dict.fromkeys(recipients))
    if not recipients:
        return
    await s.execute(
        text("insert into notifications (recipient_id, type, title, body, payload) "
             "values (:r, CAST(:t AS notif_type), :ti, :b, CAST(:p AS jsonb))"),
        [{"r": r, "t": type_, "ti": title, "b": body, "p": dumps(payload or {})} for r in recipients])
    if settings.fcm_credentials_json:
        rows = (await s.execute(text("select token from device_tokens where profile_id = any(:ids)"),
                                {"ids": recipients})).all()
        tokens = [r[0] for r in rows]
        if tokens:
            s.info.setdefault("pushes", []).append((tokens, title, body or "", {"type": type_, **(payload or {})}))


async def notify_staff(s: AsyncSession, type_: str, title: str, body: str | None = None, payload: dict | None = None,
                       roles: tuple[str, ...] = ("ADMIN", "OPERATOR")) -> None:
    rows = (await s.execute(text("select id from profiles where is_active and role::text = any(:r)"),
                            {"r": list(roles)})).all()
    await notify_users(s, [r[0] for r in rows], type_, title, body, payload)


def _init_fcm() -> bool:
    global _fcm_ready
    if _fcm_ready is not None:
        return _fcm_ready
    try:
        import firebase_admin
        from firebase_admin import credentials

        raw = settings.fcm_credentials_json
        cred = credentials.Certificate(json.loads(raw) if raw.strip().startswith("{") else raw)
        firebase_admin.initialize_app(cred)
        _fcm_ready = True
    except Exception as exc:  # optional feature: never break the request
        log.warning("FCM disabled: %s", exc)
        _fcm_ready = False
    return _fcm_ready


async def send_pushes(pushes: list[tuple[list[str], str, str, dict]]) -> None:
    if not settings.fcm_credentials_json or not _init_fcm():
        return

    def _send() -> None:
        from firebase_admin import messaging

        for tokens, title, body, data in pushes:
            msg = messaging.MulticastMessage(tokens=tokens, notification=messaging.Notification(title=title, body=body),
                                             data={k: str(v) for k, v in data.items()})
            try:
                messaging.send_each_for_multicast(msg)
            except Exception as exc:
                log.warning("push failed: %s", exc)

    await asyncio.to_thread(_send)
