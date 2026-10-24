"""App factory: routers, RFC 9457 problem handlers, CORS, Idempotency-Key, lifespan (ML models + workers)."""
from __future__ import annotations

import asyncio
import hashlib
import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import settings
from app.ml.registry import registry
from app.routers import (advisories, auth, dashboard, demo, engineers, events, ingest_hardware, ingest_twin, me,
                         network, public, workorders)
from app.schemas.common import PROBLEM_BASE, ProblemException
from app.workers import baselines, evaluator, offline, public_impact, renotify, retention, timeouts

log = logging.getLogger("AquaPulse")
PROBLEM_JSON = "application/problem+json"


def _problem(status: int, slug: str, title: str, request: Request, detail: str | None = None,
             errors: list | None = None, headers: dict | None = None) -> JSONResponse:
    body: dict = {"type": PROBLEM_BASE + slug, "title": title, "status": status}
    if detail:
        body["detail"] = detail
    body["instance"] = request.url.path
    if errors:
        body["errors"] = errors
    return JSONResponse(body, status_code=status, media_type=PROBLEM_JSON, headers=headers)


class IdempotencyMiddleware(BaseHTTPMiddleware):
    """Optional `Idempotency-Key` header on POST/PUT/PATCH: a repeated key (same caller, same path) replays the first
    response for 24 h. In-memory, so it is per process (run one worker, see README)."""
    TTL_S, MAX = 24 * 3600, 5000
    _cache: dict[str, tuple[float, int, bytes, str | None]] = {}

    async def dispatch(self, request: Request, call_next):
        key = request.headers.get("idempotency-key")
        if not key or request.method not in ("POST", "PUT", "PATCH"):
            return await call_next(request)
        ck = hashlib.sha256(f"{request.headers.get('authorization', '')}|{request.method}|{request.url.path}|{key}".encode()).hexdigest()
        hit = self._cache.get(ck)
        if hit and hit[0] > time.time():
            return Response(hit[2], status_code=hit[1], media_type=hit[3], headers={"Idempotent-Replay": "true"})
        resp = await call_next(request)
        body = b"".join([chunk async for chunk in resp.body_iterator])
        if resp.status_code < 500:
            if len(self._cache) >= self.MAX:
                self._cache.pop(next(iter(self._cache)))
            self._cache[ck] = (time.time() + self.TTL_S, resp.status_code, body, resp.media_type)
        headers = {k: v for k, v in resp.headers.items() if k.lower() not in ("content-length", "content-type")}
        return Response(body, status_code=resp.status_code, headers=headers, media_type=resp.headers.get("content-type"))


@asynccontextmanager
async def lifespan(app: FastAPI):
    logging.basicConfig(level=settings.log_level, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    try:
        await registry.load()                      # ML models are loaded at startup, hot-reloaded afterwards (9.6)
    except Exception as exc:
        log.warning("ML models not loaded (%s); heuristic fallback is used", exc)
    tasks: list[asyncio.Task] = []
    if settings.enable_workers:
        tasks = [asyncio.create_task(w.run(), name=n) for n, w in (
            ("evaluator", evaluator), ("offline-sweeper", offline), ("advisory-renotifier", renotify),
            ("assignment-timeout", timeouts), ("baselines", baselines), ("retention", retention),
            ("public-impact", public_impact))]
        tasks.append(asyncio.create_task(registry.watch(), name="model-reloader"))
    yield
    for t in tasks:
        t.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)


def create_app() -> FastAPI:
    app = FastAPI(title="AquaPulse Backend", version="1.0.0", lifespan=lifespan,
                  description="FastAPI + Supabase backend: two ingestion tunnels (hardware, digital twin), ML leak "
                              "detection, isolation advisories, dispatch and repair verification.")
    if settings.cors_list:
        app.add_middleware(CORSMiddleware, allow_origins=settings.cors_list, allow_credentials=True,
                           allow_methods=["*"], allow_headers=["*"])
    app.add_middleware(IdempotencyMiddleware)

    @app.exception_handler(ProblemException)
    async def _problem_exc(request: Request, exc: ProblemException):
        return JSONResponse(exc.body(request.url.path), status_code=exc.status, media_type=PROBLEM_JSON, headers=exc.headers)

    @app.exception_handler(StarletteHTTPException)
    async def _http_exc(request: Request, exc: StarletteHTTPException):
        slug = {404: "not-found", 405: "method-not-allowed"}.get(exc.status_code, f"http-{exc.status_code}")
        return _problem(exc.status_code, slug, str(exc.detail) if exc.status_code != 404 else "Not found", request,
                        headers=getattr(exc, "headers", None))

    @app.exception_handler(RequestValidationError)
    async def _validation(request: Request, exc: RequestValidationError):
        errs = [{"field": ".".join(str(p) for p in e["loc"]), "message": e["msg"]} for e in exc.errors()]
        return _problem(422, "validation-error", "Payload invalid", request, "The request did not pass validation", errs)

    @app.exception_handler(Exception)
    async def _unhandled(request: Request, exc: Exception):
        log.exception("unhandled error on %s", request.url.path)
        return _problem(500, "internal-error", "Internal server error", request)

    for r in (auth, demo, ingest_hardware, ingest_twin, events, engineers, workorders, advisories, network, dashboard,
              me, public):
        app.include_router(r.router)

    @app.get("/health", tags=["Health"])
    async def health():
        return {"status": "ok", "models": {"anomaly": str(registry.anomaly_id), "severity": str(registry.severity_id)}}

    return app


app = create_app()
