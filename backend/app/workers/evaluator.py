"""Evaluator: event driven, debounced to eval_interval_s per pipe (stages 1-5 of 9.1)."""
from __future__ import annotations

import asyncio
import logging
import time

from app.db import get_setting, session_scope
from app.services import detector

log = logging.getLogger("AquaPulse.evaluator")
_dirty: set[tuple[str, str]] = set()
_last: dict[tuple[str, str], float] = {}
_wake = asyncio.Event()


def mark_dirty(pipe_id, source: str) -> None:
    """Called after a reading is committed. Cheap and safe from any task."""
    _dirty.add((str(pipe_id), source))
    _wake.set()


async def _evaluate(key: tuple[str, str], sem: asyncio.Semaphore) -> None:
    async with sem:
        try:
            async with session_scope() as s:
                await detector.evaluate(s, key[0], key[1])      # type: ignore[arg-type]
        except Exception:
            log.exception("evaluation failed for %s", key)


async def run() -> None:
    sem = asyncio.Semaphore(4)
    while True:
        try:
            await asyncio.wait_for(_wake.wait(), timeout=1.0)
        except asyncio.TimeoutError:
            pass
        _wake.clear()
        if not _dirty:
            continue
        interval = (await get_setting("detection"))["eval_interval_s"]
        now = time.monotonic()
        due = [k for k in list(_dirty) if now - _last.get(k, 0.0) >= interval]
        for k in due:
            _dirty.discard(k)
            _last[k] = now
        if due:
            await asyncio.gather(*(_evaluate(k, sem) for k in due))
        if _dirty:                      # not yet due: look again shortly
            await asyncio.sleep(0.5)
            _wake.set()
