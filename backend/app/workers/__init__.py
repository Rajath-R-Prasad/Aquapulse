"""Background workers (asyncio tasks inside the FastAPI process, 10.8)."""
from __future__ import annotations

import asyncio
import logging

log = logging.getLogger("AquaPulse.workers")


async def periodic(name: str, interval_s: float, fn, initial_delay_s: float = 0.0) -> None:
    """Runs `await fn()` every interval; an exception is logged and never kills the loop."""
    await asyncio.sleep(initial_delay_s)
    while True:
        try:
            await fn()
        except asyncio.CancelledError:
            raise
        except Exception:
            log.exception("worker %s failed", name)
        await asyncio.sleep(interval_s)
