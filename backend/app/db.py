"""Async engine, sessions, small query helpers and the cached app_settings reader."""
from __future__ import annotations

import json
import time
from contextlib import asynccontextmanager
from typing import Any, AsyncIterator
from uuid import uuid4

from fastapi import Request
from fastapi.routing import APIRoute
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import settings


def _async_url(url: str) -> str:
    for prefix in ("postgresql://", "postgres://"):
        if url.startswith(prefix):
            return "postgresql+asyncpg://" + url[len(prefix):]
    return url


# Supabase pooler (transaction mode) needs prepared-statement caching disabled.
engine = create_async_engine(
    _async_url(settings.database_url),
    pool_size=20,
    max_overflow=10,
    pool_timeout=45.0,
    pool_pre_ping=True,
    connect_args={
        "statement_cache_size": 0,
        "prepared_statement_cache_size": 0,
        "prepared_statement_name_func": lambda: f"__asyncpg_{uuid4()}__",
    },
)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def _flush_pushes(session: AsyncSession) -> None:
    """After commit: run registered callbacks (e.g. wake the evaluator) and send push notifications."""
    for fn in session.info.pop("after_commit", []):
        try:
            fn()
        except Exception:  # never fail a request because of a post-commit hook
            pass
    pushes = session.info.pop("pushes", None)
    if pushes:
        from app.services.notify import send_pushes  # lazy: avoid import cycle

        await send_pushes(pushes)


def after_commit(session: AsyncSession, fn) -> None:
    """Register a sync callable to run once this transaction has committed."""
    session.info.setdefault("after_commit", []).append(fn)


@asynccontextmanager
async def session_scope() -> AsyncIterator[AsyncSession]:
    """One transaction; commits on success, rolls back on error; pushes are sent after commit."""
    async with SessionLocal() as session:
        async with session.begin():
            yield session
        await _flush_pushes(session)


async def get_session(request: Request) -> AsyncSession:
    """FastAPI dependency: one session (= one transaction) per request.

    Commit/rollback is done by TransactionalRoute right after the endpoint returns, i.e. BEFORE the response is
    sent, so a client that reads through Supabase after getting the response always sees the committed change.
    """
    s = request.scope.get("jr_session")
    if s is None:
        s = SessionLocal()
        request.scope["jr_session"] = s
    return s


class TransactionalRoute(APIRoute):
    """Route class used by every router: commit on success, roll back on any exception, send pushes after commit."""

    def get_route_handler(self):
        original = super().get_route_handler()

        async def handler(request: Request):
            try:
                response = await original(request)
                s = request.scope.get("jr_session")
                if s is not None:
                    await s.commit()
                    await _flush_pushes(s)
                return response
            except BaseException:
                s = request.scope.get("jr_session")
                if s is not None:
                    await s.rollback()
                raise
            finally:
                s = request.scope.pop("jr_session", None)
                if s is not None:
                    await s.close()

        return handler


# ---------- helpers ----------
def as_json(value: Any) -> Any:
    """asyncpg may hand back jsonb as str or as an already-decoded object."""
    if isinstance(value, (str, bytes)):
        try:
            return json.loads(value)
        except ValueError:
            return value
    return value


def dumps(value: Any) -> str:
    return json.dumps(value, default=str)


async def fetchall(s: AsyncSession, sql: str, params: dict | None = None) -> list[dict]:
    res = await s.execute(text(sql), params or {})
    return [dict(r) for r in res.mappings().all()]


async def fetchone(s: AsyncSession, sql: str, params: dict | None = None) -> dict | None:
    res = await s.execute(text(sql), params or {})
    row = res.mappings().first()
    return dict(row) if row else None


async def scalar(s: AsyncSession, sql: str, params: dict | None = None) -> Any:
    return (await s.execute(text(sql), params or {})).scalar()


# ---------- app_settings (cached 30 s) ----------
_DEFAULTS: dict[str, dict] = {
    "detection": {"eval_interval_s": 5, "gate_delta_q_pct": 5, "gate_min_delta_q_lpm": 1.0, "confirm_windows": 3,
                  "warn_score": 0.4, "confirm_score": 0.6, "burst_pressure_dev_pct": -30, "burst_delta_q_pct": 30},
    "severity_cutoffs_loss_pct": {"MINOR": 5, "MODERATE": 10, "MAJOR": 20, "CRITICAL": 40},
    "sla_arrive_minutes": {"P1": 60, "P2": 240, "P3": 1440, "P4": 4320},
    "dispatch": {"accept_timeout_s": 600, "location_max_age_s": 900, "max_distance_m": 20000},
    "evidence": {"max_distance_m": 50, "max_size_mb": 10, "arrival_geofence_m": 100},
    "retention_days": {"hw_readings": 90, "twin_pipe_readings": 14, "ml_inferences": 90},
}
_cache: dict[str, tuple[float, dict]] = {}


async def get_setting(key: str) -> dict:
    hit = _cache.get(key)
    if hit and time.monotonic() - hit[0] < 30:
        return hit[1]
    try:
        async with SessionLocal() as s:
            row = (await s.execute(text("select value from app_settings where key = :k"), {"k": key})).first()
        value = {**_DEFAULTS.get(key, {}), **(as_json(row[0]) if row else {})}
    except Exception:  # DB unavailable: fall back to defaults
        value = dict(_DEFAULTS.get(key, {}))
    _cache[key] = (time.monotonic(), value)
    return value


def invalidate_settings() -> None:
    _cache.clear()
