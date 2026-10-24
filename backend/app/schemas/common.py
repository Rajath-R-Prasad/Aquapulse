"""Shared schemas, RFC 9457 problem details and cursor pagination helpers."""
from __future__ import annotations

import base64
import json
from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel

PROBLEM_BASE = "https://AquaPulse.example/problems/"

Source = Literal["HARDWARE", "TWIN"]
Severity = Literal["NONE", "MINOR", "MODERATE", "MAJOR", "CRITICAL"]
EventStatus = Literal["DETECTED", "ACKNOWLEDGED", "DISPATCHED", "IN_PROGRESS", "REPAIR_SUBMITTED", "CLOSED", "FALSE_ALARM"]


class ProblemException(Exception):
    """Raised anywhere; rendered as application/problem+json by the handler in main.py."""

    def __init__(self, status: int, slug: str, title: str, detail: str | None = None,
                 errors: list[dict] | None = None, headers: dict[str, str] | None = None):
        self.status, self.slug, self.title = status, slug, title
        self.detail, self.errors, self.headers = detail, errors, headers or {}
        super().__init__(title)

    def body(self, instance: str) -> dict:
        out: dict[str, Any] = {"type": PROBLEM_BASE + self.slug, "title": self.title, "status": self.status}
        if self.detail:
            out["detail"] = self.detail
        out["instance"] = instance
        if self.errors:
            out["errors"] = self.errors
        return out


def unauthorized(detail: str = "Missing or invalid credentials") -> ProblemException:
    return ProblemException(401, "unauthorized", "Unauthorized", detail, headers={"WWW-Authenticate": "Bearer"})


def forbidden(detail: str = "Not allowed") -> ProblemException:
    return ProblemException(403, "forbidden", "Forbidden", detail)


def not_found(what: str = "resource") -> ProblemException:
    return ProblemException(404, "not-found", "Not found", f"{what} not found")


def conflict(detail: str, slug: str = "state-conflict") -> ProblemException:
    return ProblemException(409, slug, "Conflict", detail)


def unprocessable(slug: str, title: str, detail: str | None = None, errors: list[dict] | None = None) -> ProblemException:
    return ProblemException(422, slug, title, detail, errors)


class ActionBody(BaseModel):
    """Optional body accepted by every action endpoint (11.4)."""
    expected_status: str | None = None


# ---------- cursor pagination: ?limit=50&cursor=... -> {items, next_cursor} ----------
def encode_cursor(ts: datetime, id_: UUID | str) -> str:
    raw = json.dumps({"t": ts.isoformat(), "i": str(id_)}).encode()
    return base64.urlsafe_b64encode(raw).decode()


def decode_cursor(cursor: str) -> tuple[datetime, str]:
    try:
        d = json.loads(base64.urlsafe_b64decode(cursor.encode()))
        return datetime.fromisoformat(d["t"]), d["i"]
    except Exception:
        raise unprocessable("invalid-cursor", "Invalid cursor", "The cursor value is not valid") from None
