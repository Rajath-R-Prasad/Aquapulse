"""Tunnel B payloads (6.2, 6.3)."""
from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class TwinUnits(BaseModel):
    flow: str = "L/min"
    pressure: str = "kPa"
    velocity: str = "m/s"


class TwinPipeReading(BaseModel):
    pipe_code: str
    flow_in: float | None = Field(default=None, allow_inf_nan=False)
    flow_out: float | None = Field(default=None, allow_inf_nan=False)
    pressure_in: float | None = Field(default=None, allow_inf_nan=False)
    pressure_out: float | None = Field(default=None, allow_inf_nan=False)
    velocity: float | None = Field(default=None, allow_inf_nan=False)
    injected_leak: float | None = Field(default=None, allow_inf_nan=False)  # ground truth: training/eval only


class TwinSnapshot(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    schema_: Literal["AquaPulse.twin.snapshot/1.0"] = Field(alias="schema")
    run_id: UUID
    sim_time: datetime
    units: TwinUnits = TwinUnits()
    pipes: list[TwinPipeReading] = Field(min_length=1, max_length=500)


class TwinRunBody(BaseModel):
    action: Literal["START", "STOP"]
    name: str | None = None
    scenario: str | None = None
    network_version: str | None = None
    run_id: UUID | None = None            # required for STOP (otherwise the latest RUNNING run is stopped)


class TwinAck(BaseModel):
    status: Literal["APPLIED", "FAILED"]
    error: str | None = None
