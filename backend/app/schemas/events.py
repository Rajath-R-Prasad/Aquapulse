"""Leak events, isolation advisories and device admin bodies."""
from __future__ import annotations

from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.common import ActionBody


class FalseAlarmBody(ActionBody):
    reason: str = Field(min_length=1, max_length=500)


class DismissBody(ActionBody):
    reason: str = Field(min_length=1, max_length=500)


class InjectLeakBody(BaseModel):
    pipe_id: UUID
    leak_rate_lpm: float = Field(gt=0, le=2000)
    position_fraction: float = Field(default=0.5, ge=0, le=1)


class ClearLeakBody(BaseModel):
    pipe_id: UUID


class DeviceCreate(BaseModel):
    device_uid: str = Field(min_length=1, max_length=64)
    pipe_id: UUID
    report_interval_s: int = Field(default=5, ge=1, le=3600)
    calibration: dict = Field(default_factory=dict)


class DevicePatch(BaseModel):
    status: Literal["PROVISIONED", "ONLINE", "OFFLINE", "MAINTENANCE", "RETIRED"] | None = None
    pipe_id: UUID | None = None
    report_interval_s: int | None = Field(default=None, ge=1, le=3600)
    calibration: dict | None = None
    rotate_token: bool = False
