"""Shared helpers for the training scripts: load readings, slide windows, reuse the production feature code."""
from __future__ import annotations

import numpy as np
import pandas as pd

from app.db import SessionLocal, fetchall
from app.services.features import FEATURE_ORDER, build_features, local_hour_dow


async def pipe_table() -> dict[str, dict]:
    async with SessionLocal() as s:
        rows = await fetchall(s, "select code, diameter_mm, material::text as material, install_year, design_flow_lpm from pipe_segments")
    return {r["code"]: r for r in rows}


async def load_twin_runs(run_ids: list[str]) -> pd.DataFrame:
    async with SessionLocal() as s:
        rows = await fetchall(s, """select p.code as pipe_code, r.sim_time as ts, r.flow_in_lpm, r.flow_out_lpm, r.pressure_in_kpa,
                                    r.pressure_out_kpa, r.injected_leak_lpm from twin_pipe_readings r
                                    join pipe_segments p on p.id = r.pipe_id where r.run_id = any(CAST(:ids AS uuid[]))
                                    order by r.pipe_id, r.sim_time""", {"ids": run_ids})
    df = pd.DataFrame(rows)
    df["ts"] = pd.to_datetime(df["ts"], utc=True)
    return df


def load_csv(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df["ts"] = pd.to_datetime(df["ts"], utc=True)
    if "injected_leak_lpm" not in df:
        df["injected_leak_lpm"] = 0.0
    return df


def _baselines(normal: pd.DataFrame) -> dict[tuple[str, int, int], dict]:
    """Per pipe, weekday and hour: mean/std of delta_q and mean of pressure_in (same slots as pipe_baselines)."""
    out = {}
    d = normal.assign(dq=normal["flow_in_lpm"] - normal["flow_out_lpm"])
    slots = d["ts"].map(lambda t: local_hour_dow(t.to_pydatetime()))
    d["hour"], d["dow"] = [x[0] for x in slots], [x[1] for x in slots]
    for (code, dow, hour), g in d.groupby(["pipe_code", "dow", "hour"]):
        if len(g) >= 30:
            out[(code, dow, hour)] = {"delta_q_mean_lpm": float(g["dq"].mean()), "delta_q_std_lpm": float(g["dq"].std(ddof=1)),
                                      "pressure_in_mean_kpa": float(g["pressure_in_kpa"].mean()), "samples": len(g)}
    return out


def build_dataset(readings: pd.DataFrame, pipes: dict[str, dict], stride: int = 6, with_labels: bool = False):
    """Returns (feature DataFrame with FEATURE_ORDER columns, meta DataFrame). Baselines come from the no-leak rows."""
    base = _baselines(readings[readings["injected_leak_lpm"].fillna(0) == 0])
    feats, meta = [], []
    for code, g in readings.groupby("pipe_code"):
        pipe = pipes.get(code)
        if not pipe:
            continue
        g = g.sort_values("ts").reset_index(drop=True)
        w = g.rename(columns={"flow_in_lpm": "flow_in", "flow_out_lpm": "flow_out", "pressure_in_kpa": "pressure_in",
                              "pressure_out_kpa": "pressure_out"})
        if "acoustic_rms" in w:
            w = w.rename(columns={"acoustic_rms": "acoustic"})
        else:
            w["acoustic"] = np.nan
        for end in range(10, len(w), stride):
            window = w.iloc[max(0, end - 60): end + 1]            # ~300 s at the default 5 s step
            hour, dow = local_hour_dow(window["ts"].iloc[-1].to_pydatetime())
            f = build_features(window, pipe, base.get((code, dow, hour)))
            if f is None:
                continue
            feats.append({k: f[k] for k in FEATURE_ORDER})
            meta.append({"pipe_code": code, "ts": window["ts"].iloc[-1], "injected_leak_lpm": float(g["injected_leak_lpm"].iloc[end] or 0)})
    return pd.DataFrame(feats, columns=FEATURE_ORDER), pd.DataFrame(meta)
