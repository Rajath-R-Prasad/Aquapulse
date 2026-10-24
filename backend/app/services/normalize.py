"""Unit normalisation to canonical storage units (section 5): flow L/min, pressure kPa."""
from __future__ import annotations

from app.schemas.common import ProblemException

FLOW_TO_LPM = {"L/min": 1.0, "L/s": 60.0, "m3/s": 60000.0, "m3/h": 1000.0 / 60.0}
PRESSURE_TO_KPA = {"kPa": 1.0, "Pa": 0.001, "bar": 100.0}

FLOW_RANGE = (0.0, 2000.0)       # L/min
PRESSURE_RANGE = (0.0, 2000.0)   # kPa
ACOUSTIC_RANGE = (0.0, 1.0)

SENSOR_KIND = {"FLOW_IN": "flow", "FLOW_OUT": "flow", "PRESSURE_IN": "pressure",
               "PRESSURE_OUT": "pressure", "ACOUSTIC_RMS": "acoustic"}
SENSOR_COLUMN = {"FLOW_IN": "flow_in_lpm", "FLOW_OUT": "flow_out_lpm", "PRESSURE_IN": "pressure_in_kpa",
                 "PRESSURE_OUT": "pressure_out_kpa", "ACOUSTIC_RMS": "acoustic_rms"}


class UnitError(ValueError):
    pass


def to_canonical(kind: str, value: float, unit: str) -> float:
    if kind == "flow":
        table = FLOW_TO_LPM
    elif kind == "pressure":
        table = PRESSURE_TO_KPA
    elif kind == "acoustic":
        table = {"1": 1.0}
    elif kind == "velocity":
        table = {"m/s": 1.0}
    else:
        raise UnitError(f"unknown measurement kind {kind}")
    if unit not in table:
        raise UnitError(f"unit '{unit}' is not accepted for {kind}; accepted: {', '.join(table)}")
    return value * table[unit]


def in_range(kind: str, canonical_value: float) -> bool:
    lo, hi = {"flow": FLOW_RANGE, "pressure": PRESSURE_RANGE, "acoustic": ACOUSTIC_RANGE}.get(kind, (-1e30, 1e30))
    return lo <= canonical_value <= hi


def normalize_reading(sensor: str, value: float, unit: str) -> tuple[float, bool]:
    """Returns (canonical_value, in_range). Raises 422 problem for a unit that is not accepted."""
    kind = SENSOR_KIND[sensor]
    try:
        v = to_canonical(kind, value, unit)
    except UnitError as exc:
        raise ProblemException(422, "unit-not-accepted", "Unit not accepted", str(exc),
                               errors=[{"sensor": sensor, "unit": unit}]) from None
    return v, in_range(kind, v)
