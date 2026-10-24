"""Train the Isolation Forest on NORMAL data only (9.3, 9.5).

Data: twin runs without leaks (and, optionally, rig no-leak recordings exported as CSV).
  python -m app.ml.train_anomaly --run-id <twin_run_uuid> [--run-id ...] [--csv rig_normal.csv] --activate
CSV columns: ts,pipe_code,flow_in_lpm,flow_out_lpm,pressure_in_kpa,pressure_out_kpa[,acoustic_rms]
"""
from __future__ import annotations

import argparse
import asyncio
from datetime import datetime, timezone

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest

from app.ml.dataset import build_dataset, load_csv, load_twin_runs, pipe_table
from app.ml.registry import register_model
from app.services.features import FEATURE_ORDER


def fit(X: np.ndarray, seed: int = 42) -> dict:
    model = IsolationForest(n_estimators=200, contamination="auto", random_state=seed, n_jobs=-1).fit(X)
    dec = model.decision_function(X)
    # decision_function: higher = more normal. Scale so the 5th percentile of normal data -> 0 and the minimum -> 1.
    return {"model": model, "features": FEATURE_ORDER, "hi": float(np.percentile(dec, 5)), "lo": float(dec.min())}


def false_alarm_rate(art: dict, X: np.ndarray, threshold: float = 0.6) -> float:
    from app.ml.registry import scale_anomaly

    dec = art["model"].decision_function(X)
    return float(np.mean([scale_anomaly(d, art["hi"], art["lo"]) >= threshold for d in dec]))


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run-id", action="append", default=[], help="twin run(s) with NO injected leaks")
    ap.add_argument("--csv", action="append", default=[])
    ap.add_argument("--holdout-pipes", default="", help="comma separated pipe codes kept out of training")
    ap.add_argument("--stride", type=int, default=6)
    ap.add_argument("--version", default=datetime.now(timezone.utc).strftime("%Y%m%d%H%M"))
    ap.add_argument("--activate", action="store_true")
    ap.add_argument("--no-upload", action="store_true")
    a = ap.parse_args()

    pipes = await pipe_table()
    frames = [await load_twin_runs(a.run_id)] if a.run_id else []
    frames += [load_csv(p) for p in a.csv]
    if not frames:
        raise SystemExit("give --run-id and/or --csv")
    readings = pd.concat(frames, ignore_index=True)
    readings = readings[readings["injected_leak_lpm"].fillna(0) == 0]          # normal data only
    hold = {c for c in a.holdout_pipes.split(",") if c}
    train_df, test_df = readings[~readings["pipe_code"].isin(hold)], readings[readings["pipe_code"].isin(hold)]
    X, _ = build_dataset(train_df, pipes, stride=a.stride)
    if len(X) < 200:
        raise SystemExit(f"only {len(X)} training windows; run the twin longer (target: 7 simulated days)")
    art = fit(X[FEATURE_ORDER].to_numpy())
    metrics = {"n_train_windows": int(len(X)), "false_alarm_rate_train": false_alarm_rate(art, X[FEATURE_ORDER].to_numpy())}
    if len(test_df):
        Xt, _ = build_dataset(test_df, pipes, stride=a.stride)
        if len(Xt):
            metrics["false_alarm_rate_holdout_pipes"] = false_alarm_rate(art, Xt[FEATURE_ORDER].to_numpy())
    mid = await register_model("isolation-forest", a.version, "ANOMALY", art, metrics,
                               f"runs={a.run_id} csv={a.csv}", activate=a.activate, upload=not a.no_upload)
    print("registered ANOMALY model", mid, metrics)


if __name__ == "__main__":
    asyncio.run(main())
