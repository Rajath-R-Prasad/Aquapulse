"""Authentication: device token, twin service token, Supabase JWT, role guards (11.2)."""
from __future__ import annotations

import asyncio
import hashlib
import hmac
import time
from dataclasses import dataclass
from uuid import UUID

import jwt
from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db import fetchone, get_session
from app.schemas.common import ProblemException, forbidden, unauthorized

bearer = HTTPBearer(auto_error=False)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _bearer_token(creds: HTTPAuthorizationCredentials | None) -> str:
    if creds is None or not creds.credentials:
        raise unauthorized("Missing bearer token")
    return creds.credentials


# ---------- ESP32 device token ----------
async def device_auth(creds: HTTPAuthorizationCredentials | None = Depends(bearer),
                      s: AsyncSession = Depends(get_session)) -> dict:
    token_hash = hash_token(_bearer_token(creds))
    row = await fetchone(
        s, "select id, device_uid, pipe_id, status::text as status, token_hash, report_interval_s, "
           "calibration from devices where token_hash = :h", {"h": token_hash})
    if not row or not hmac.compare_digest(row["token_hash"], token_hash):
        raise unauthorized("Invalid device token")
    if row["status"] == "RETIRED":
        raise forbidden("Device is RETIRED")
    return row


# ---------- digital twin service token ----------
async def twin_auth(creds: HTTPAuthorizationCredentials | None = Depends(bearer)) -> str:
    token = _bearer_token(creds)
    expected = settings.twin_service_token
    if not expected or not hmac.compare_digest(token.encode(), expected.encode()):
        raise unauthorized("Invalid twin service token")
    return "twin"


# ---------- Supabase JWT ----------
_jwk_client: jwt.PyJWKClient | None = None
_role_cache: dict[str, tuple[float, str | None]] = {}


async def verify_jwt(token: str) -> dict:
    global _jwk_client
    try:
        alg = jwt.get_unverified_header(token).get("alg")
        if alg not in ("HS256", "RS256", "ES256"):
            raise unauthorized("Unsupported token algorithm")
        if alg == "HS256":
            if not settings.supabase_jwt_secret:
                raise unauthorized("HS256 tokens are not accepted by this deployment")
            key: object = settings.supabase_jwt_secret
        else:
            if not settings.supabase_jwks_url:
                raise ProblemException(500, "auth-misconfigured", "Server error", "JWKS URL is not configured")
            if _jwk_client is None:
                _jwk_client = jwt.PyJWKClient(settings.supabase_jwks_url, cache_keys=True)
            key = (await asyncio.to_thread(_jwk_client.get_signing_key_from_jwt, token)).key
        return jwt.decode(token, key, algorithms=[alg], audience=settings.supabase_jwt_audience)  # type: ignore[arg-type]
    except jwt.PyJWTError:
        raise unauthorized("Invalid or expired token") from None


@dataclass
class CurrentUser:
    id: UUID
    role: str
    token: str

    @property
    def is_staff(self) -> bool:
        return self.role in ("ADMIN", "OPERATOR")


async def current_user(creds: HTTPAuthorizationCredentials | None = Depends(bearer),
                       s: AsyncSession = Depends(get_session)) -> CurrentUser:
    token = _bearer_token(creds)
    claims = await verify_jwt(token)
    uid = claims.get("sub")
    if not uid:
        raise unauthorized("Token has no subject")
    cached = _role_cache.get(uid)
    if cached and time.monotonic() - cached[0] < 60:
        role = cached[1]
    else:
        row = await fetchone(s, "select role::text as role, is_active from profiles where id = :i", {"i": UUID(uid)})
        role = row["role"] if row and row["is_active"] else None
        _role_cache[uid] = (time.monotonic(), role)
    if role is None:
        raise forbidden("No active profile for this user")
    return CurrentUser(id=UUID(uid), role=role, token=token)


def require_roles(*roles: str):
    async def guard(user: CurrentUser = Depends(current_user)) -> CurrentUser:
        if user.role not in roles:
            raise forbidden(f"Requires role: {', '.join(roles)}")
        return user
    return guard


staff_user = require_roles("ADMIN", "OPERATOR")
admin_user = require_roles("ADMIN")
engineer_user = require_roles("ENGINEER")
any_user = require_roles("ADMIN", "OPERATOR", "ENGINEER")


# ---------- hardware ingest limits ----------
class RateLimiter:
    """Max 1 message per second per device (13)."""

    def __init__(self, min_interval_s: float = 1.0):
        self.min_interval = min_interval_s
        self._last: dict[str, float] = {}

    def check(self, key: str) -> None:
        now = time.monotonic()
        last = self._last.get(key)
        if last is not None and now - last < self.min_interval:
            raise ProblemException(429, "rate-limited", "Too many requests",
                                   "More than 1 message per second", headers={"Retry-After": "1"})
        self._last[key] = now
        if len(self._last) > 10000:
            self._last = {k: v for k, v in self._last.items() if now - v < 60}


device_rate_limiter = RateLimiter()


def max_body(n_bytes: int):
    async def dep(request: Request) -> None:
        cl = request.headers.get("content-length")
        if cl and cl.isdigit() and int(cl) > n_bytes:
            raise ProblemException(413, "payload-too-large", "Payload too large", f"Limit is {n_bytes} bytes")
    return dep
