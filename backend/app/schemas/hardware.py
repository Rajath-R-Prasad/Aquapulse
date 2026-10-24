"""Tunnel A payloads (6.1)."""
from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class SensorValue(BaseModel):
    sensor: Literal["FLOW_IN", "FLOW_OUT", "PRESSURE_IN", "PRESSURE_OUT", "ACOUSTIC_RMS"]
    value: float = Field(allow_inf_nan=False)
    unit: str
    quality: Literal["GOOD", "UNCERTAIN", "BAD"] = "GOOD"


class GeoPoint(BaseModel):
    type: Literal["Point"]
    coordinates: list[float] = Field(min_length=2, max_length=3)  # [lon, lat]


class EdgeResult(BaseModel):
    delta_q_lpm: float | None = None
    leak_flag: bool | None = None
    confirm_s: float | None = None


class DeviceHealth(BaseModel):
    rssi_dbm: float | None = None
    uptime_s: int | None = None
    free_heap_b: int | None = None


class HWMessage(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    schema_: Literal["AquaPulse.hw.reading/1.0"] = Field(alias="schema")
    device_uid: str = Field(min_length=1, max_length=64)
    boot_id: str = Field(min_length=8, max_length=16)
    seq: int = Field(ge=0)
    ts: datetime | None                       # required key; null if the device clock is not synced
    fw: str | None = None
    position: GeoPoint | None = None
    readings: list[SensorValue] = Field(min_length=1, max_length=8)
    edge: EdgeResult | None = None
    health: DeviceHealth | None = None


class HWBatch(BaseModel):
    messages: list[dict] = Field(min_length=1, max_length=50)
