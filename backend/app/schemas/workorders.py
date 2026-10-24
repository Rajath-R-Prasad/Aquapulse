"""Work-order, evidence and engineer-app bodies (6.5, 11.3)."""
from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.common import ActionBody


class AssignBody(ActionBody):
    engineer_id: UUID


class ApproveBody(ActionBody):
    comment: str | None = None


class ReasonBody(ActionBody):
    reason: str = Field(min_length=1, max_length=500)


class ArriveBody(ActionBody):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    override_reason: str | None = None


class UploadUrlBody(BaseModel):
    kind: Literal["BEFORE_PHOTO", "AFTER_PHOTO"]
    mime_type: str
    size_bytes: int = Field(gt=0)


class EvidenceBody(BaseModel):
    storage_path: str
    kind: Literal["BEFORE_PHOTO", "AFTER_PHOTO"]
    captured_at: datetime | None = None
    lat: float | None = Field(default=None, ge=-90, le=90)
    lon: float | None = Field(default=None, ge=-180, le=180)
    sha256: str | None = None
    mime_type: str | None = None
    size_bytes: int | None = None


class Material(BaseModel):
    item: str
    qty: float = Field(gt=0)


class SubmitBody(ActionBody):
    repair_type: Literal["CLAMP", "COUPLING", "JOINT_REPAIR", "SECTION_REPLACE", "VALVE_REPLACE", "OTHER"]
    materials: list[Material] = Field(default_factory=list)
    labour_minutes: int | None = Field(default=None, ge=0)
    work_notes: str | None = None
    evidence_ids: list[UUID] | None = None
    allow_simulated_location_override: bool = False


class EngineerStatusBody(BaseModel):
    status: Literal["AVAILABLE", "OFF_DUTY"]


class LocationBody(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    accuracy_m: float | None = None
    captured_at: datetime | None = None


class PushTokenBody(BaseModel):
    token: str = Field(min_length=10)
    platform: Literal["ANDROID", "IOS", "WEB"] = "ANDROID"
