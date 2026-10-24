"""Train the leak-rate regressor on the twin leak campaign (9.3, 9.5).

The label is injected_leak_lpm. Hold out whole pipes and time periods for testing.
  python -m app.ml.train_severity --run-id <campaign_run_uuid> [--run-id ...] --holdout-pipes P03,P11 --activate
Do not retrain on rig data alone: calibrate rig thresholds in app_settings instead (9.5).
"""
from __future__ import annotations

import argparse
import asyncio
from datetime import datetime, timezone

import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingRegressor

from app.ml.dataset import build_dataset, load_twin_runs, pipe_table
from app.ml.registry import register_model
from app.services.features import FEATURE_ORDER
from app.services.severity import classify, est_loss_pct, rank


def evaluate(model, X: pd.DataFrame, y: np.ndarray, truth_class: list[str]) -> dict:
    pred = np.clip(model.predict(X[FEATURE_ORDER].to_numpy()), 0, None)
    pred_class = [classify(est_loss_pct(p, f, d)) for p, f, d in zip(pred, X["flow_in_lpm"], X["design_flow_lpm"])]
    within_one = np.mean([abs(rank(a) - rank(b)) <= 1 for a, b in zip(pred_class, truth_class)])
    return {"mae_lpm": float(np.mean(np.abs(pred - y))), "within_one_class": float(within_one), "n": int(len(y))}


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run-id", action="append", required=True, help="twin leak-campaign run(s)")
    ap.add_argument("--holdout-pipes", default="")
    ap.add_argument("--holdout-fraction-time", type=float, default=0.2, help="last fraction of each pipe's time kept for testing")
    ap.add_argument("--stride", type=int, default=6)
    ap.add_argument("--version", default=datetime.now(timezone.utc).strftime("%Y%m%d%H%M"))
    ap.add_argument("--activate", action="store_true")
    ap.add_argument("--no-upload", action="store_true")
    a = ap.parse_args()

    pipes = await pipe_table()
    readings = await load_twin_runs(a.run_id)
    hold = {c for c in a.holdout_pipes.split(",") if c}
    X, meta = build_dataset(readings, pipes, stride=a.stride, with_labels=True)
    X["pipe_code"], X["ts"], X["y"] = meta["pipe_code"].values, meta["ts"].values, meta["injected_leak_lpm"].values
    cut = X.groupby("pipe_code")["ts"].transform(lambda t: t.quantile(1 - a.holdout_fraction_time))
    is_test = X["pipe_code"].isin(hold) | (X["ts"] > cut)
    train, test = X[~is_test], X[is_test]
    if len(train) < 200:
        raise SystemExit(f"only {len(train)} training windows; extend the leak campaign")
    model = HistGradientBoostingRegressor(max_iter=300, learning_rate=0.08, random_state=42)
    model.fit(train[FEATURE_ORDER].to_numpy(), train["y"].to_numpy())
    truth = [classify(est_loss_pct(y, f, d)) for y, f, d in zip(test["y"], test["flow_in_lpm"], test["design_flow_lpm"])]
    metrics = {"train_windows": int(len(train)), "test": evaluate(model, test, test["y"].to_numpy(), truth) if len(test) else None}
    mid = await register_model("hgb-leak-rate", a.version, "SEVERITY", {"model": model, "features": FEATURE_ORDER}, metrics,
                               f"runs={a.run_id}", activate=a.activate, upload=not a.no_upload)
    print("registered SEVERITY model", mid, metrics)


if __name__ == "__main__":
    asyncio.run(main())
