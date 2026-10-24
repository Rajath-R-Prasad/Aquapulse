"""Feature extraction (9.2): identical schema for hardware and twin sources. injected_leak_lpm is never used."""
from __future__ import annotations

import math
from datetime import datetime
from zoneinfo import ZoneInfo

import numpy as np
import pandas as pd
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db import fetchall, fetchone

MATERIAL_CODES = {"PVC": 0, "HDPE": 1, "DI": 2, "CI": 3, "GI": 4, "STEEL": 5, "AC": 6, "OTHER": 7}
FEATURE_ORDER = [
    "flow_in_lpm", "flow_out_lpm", "delta_q_lpm", "delta_q_pct", "delta_q_resid", "delta_q_z",
    "pressure_in_kpa", "pressure_out_kpa", "dp_kpa", "pressure_dev_pct",
    "roc_delta_q", "roc_pressure", "flow_std_60s", "acoustic_rms", "has_acoustic",
    "diameter_mm", "material", "age_years", "design_flow_lpm", "hour_sin", "hour_cos",
]
DEFAULT_DQ_STD = 0.5   # L/min when no baseline exists yet
CORE = ("FLOW_IN", "FLOW_OUT", "PRESSURE_IN", "PRESSURE_OUT")


def local_hour_dow(ts: datetime) -> tuple[int, int]:
    """(hour 0-23, dow 0-6 with Sunday=0, matching PostgreSQL extract(dow)) in the utility's timezone."""
    loc = ts.astimezone(ZoneInfo(settings.app_timezone))
    return loc.hour, (loc.weekday() + 1) % 7


def _slope_per_min(t: np.ndarray, y: np.ndarray) -> float:
    if len(t) < 3 or np.ptp(t) <= 0:
        return 0.0
    return float(np.polyfit(t, y, 1)[0] * 60.0)


def build_features(df: pd.DataFrame, pipe: dict, baseline: dict | None) -> dict | None:
    """df columns: ts (tz-aware), flow_in, flow_out, pressure_in, pressure_out, acoustic (BAD rows already removed).
    Uses the last 60 s for medians/slopes and the 300 s window for the pressure fallback baseline."""
    if df is None or df.empty:
        return None
    df = df.sort_values("ts")
    t_end = df["ts"].max()
    w60 = df[df["ts"] > t_end - pd.Timedelta(seconds=60)]
    if len(w60) < 3:
        return None
    med = w60[["flow_in", "flow_out", "pressure_in", "pressure_out"]].median()
    flow_in, flow_out = float(med["flow_in"]), float(med["flow_out"])
    p_in, p_out = float(med["pressure_in"]), float(med["pressure_out"])
    if any(math.isnan(v) for v in (flow_in, flow_out, p_in, p_out)):
        return None
    dq_series = (w60["flow_in"] - w60["flow_out"]).to_numpy(dtype=float)
    secs = (w60["ts"] - w60["ts"].iloc[0]).dt.total_seconds().to_numpy(dtype=float)
    dq = flow_in - flow_out
    dq_pct = dq / flow_in * 100.0 if flow_in > 1e-6 else 0.0

    hour, dow = local_hour_dow(t_end.to_pydatetime())
    b_mean = b_std = p_mean = None
    if baseline:
        b_mean, b_std, p_mean = baseline.get("delta_q_mean_lpm"), baseline.get("delta_q_std_lpm"), baseline.get("pressure_in_mean_kpa")
    if b_mean is None:
        b_mean = 0.0
    if not b_std or b_std <= 0:
        b_std = DEFAULT_DQ_STD
    if p_mean is None or p_mean <= 0:   # fallback: pressure before the last 60 s of the window
        older = df[df["ts"] <= t_end - pd.Timedelta(seconds=60)]["pressure_in"]
        p_mean = float(older.median()) if len(older) >= 5 else p_in
    resid = dq - b_mean
    ac = w60["acoustic"].dropna()
    has_ac = 1 if len(ac) else 0
    install_year = pipe.get("install_year")
    age = max(0, t_end.year - int(install_year)) if install_year else 0

    return {
        "flow_in_lpm": flow_in, "flow_out_lpm": flow_out, "delta_q_lpm": dq, "delta_q_pct": dq_pct,
        "delta_q_resid": resid, "delta_q_z": resid / max(b_std, 1e-3),
        "pressure_in_kpa": p_in, "pressure_out_kpa": p_out, "dp_kpa": p_in - p_out,
        "pressure_dev_pct": (p_in - p_mean) / p_mean * 100.0 if p_mean > 1e-6 else 0.0,
        "roc_delta_q": _slope_per_min(secs, dq_series),
        "roc_pressure": _slope_per_min(secs, w60["pressure_in"].to_numpy(dtype=float)),
        "flow_std_60s": float(w60["flow_in"].std(ddof=0)),
        "acoustic_rms": float(ac.median()) if has_ac else 0.0, "has_acoustic": has_ac,
        "diameter_mm": float(pipe["diameter_mm"]), "material": MATERIAL_CODES.get(str(pipe["material"]), 7),
        "age_years": float(age), "design_flow_lpm": float(pipe["design_flow_lpm"]),
        "hour_sin": math.sin(2 * math.pi * hour / 24), "hour_cos": math.cos(2 * math.pi * hour / 24),
        # not model inputs (kept for the audit record / event parameters)
        "baseline_delta_q_lpm": float(b_mean), "baseline_delta_q_std_lpm": float(b_std), "_hour": hour, "_dow": dow,
        "_ts": t_end.isoformat(),
    }


def vectorize(feats: dict, order: list[str] | None = None) -> np.ndarray:
    order = order or FEATURE_ORDER
    return np.array([[float(feats.get(k, 0.0) or 0.0) for k in order]], dtype=float)


def gate_passed(feats: dict, cfg: dict) -> bool:
    """Physics gate (9.1 stage 2) on the 60 s median."""
    std = feats.get("baseline_delta_q_std_lpm", DEFAULT_DQ_STD)
    return (feats["delta_q_resid"] >= max(3.0 * std, cfg.get("gate_min_delta_q_lpm", 1.0))
            and feats["delta_q_pct"] >= cfg.get("gate_delta_q_pct", 5))


def summary(feats: dict, anomaly_score: float) -> dict:
    """Subset stored in leak_events.parameters (6.4)."""
    return {
        "flow_in_lpm": feats["flow_in_lpm"], "flow_out_lpm": feats["flow_out_lpm"],
        "delta_q_lpm": feats["delta_q_lpm"], "delta_q_pct": feats["delta_q_pct"],
        "pressure_in_kpa": feats["pressure_in_kpa"], "pressure_out_kpa": feats["pressure_out_kpa"],
        "dp_kpa": feats["dp_kpa"], "pressure_dev_pct": feats["pressure_dev_pct"],
        "acoustic_rms": feats["acoustic_rms"] if feats["has_acoustic"] else None,
        "baseline_delta_q_lpm": feats["baseline_delta_q_lpm"], "roc_delta_q_lpm_per_min": feats["roc_delta_q"],
        "anomaly_score": anomaly_score,
    }


# ---------- data access ----------
async def load_frame(s: AsyncSession, pipe_id, source: str) -> tuple[pd.DataFrame | None, dict]:
    """Last 300 s of readings, anchored on the newest reading. BAD readings are dropped.
    Returns (frame, meta) where meta has quality_factor, device_id, run_id."""
    if source == "HARDWARE":
        rows = await fetchall(s, """
            select recorded_at as ts, device_id, flow_in_lpm, flow_out_lpm, pressure_in_kpa, pressure_out_kpa,
                   acoustic_rms, quality
            from hw_readings
            where pipe_id = :p and recorded_at > (select max(recorded_at) from hw_readings where pipe_id = :p)
                                                  - interval '300 seconds'
            order by recorded_at""", {"p": pipe_id})
    else:
        rows = await fetchall(s, """
            select sim_time as ts, run_id, flow_in_lpm, flow_out_lpm, pressure_in_kpa, pressure_out_kpa
            from twin_pipe_readings
            where pipe_id = :p and sim_time > (select max(sim_time) from twin_pipe_readings where pipe_id = :p)
                                              - interval '300 seconds'
            order by sim_time""", {"p": pipe_id})
    meta: dict = {"quality_factor": 1.0, "device_id": None, "run_id": None}
    if not rows:
        return None, meta
    from app.db import as_json

    keep, uncertain_recent = [], False
    t_last = rows[-1]["ts"]
    for r in rows:
        q = as_json(r.get("quality")) or {}
        if any(q.get(k) == "BAD" for k in CORE):
            continue
        if any(q.get(k) == "UNCERTAIN" for k in CORE) and (t_last - r["ts"]).total_seconds() <= 60:
            uncertain_recent = True
        keep.append(r)
    if not keep:
        return None, meta
    meta["quality_factor"] = 0.8 if uncertain_recent else 1.0
    meta["device_id"] = rows[-1].get("device_id")
    meta["run_id"] = rows[-1].get("run_id")
    df = pd.DataFrame([{"ts": r["ts"], "flow_in": r["flow_in_lpm"], "flow_out": r["flow_out_lpm"],
                        "pressure_in": r["pressure_in_kpa"], "pressure_out": r["pressure_out_kpa"],
                        "acoustic": r.get("acoustic_rms")} for r in keep])
    df["ts"] = pd.to_datetime(df["ts"], utc=True)
    for c in ("flow_in", "flow_out", "pressure_in", "pressure_out", "acoustic"):
        df[c] = pd.to_numeric(df[c], errors="coerce")
    return df, meta


async def load_baseline(s: AsyncSession, pipe_id, source: str, hour: int, dow: int) -> dict | None:
    return await fetchone(s, "select * from pipe_baselines where pipe_id=:p and source=CAST(:s AS data_source) "
                             "and dow=:d and hour=:h",
                          {"p": pipe_id, "s": source, "d": dow, "h": hour})
