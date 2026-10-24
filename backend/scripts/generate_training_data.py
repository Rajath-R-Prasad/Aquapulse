"""Generate synthetic simulation runs (normal + leak campaign) and train both ML models.

Usage:
    python -m scripts.generate_training_data
"""
import asyncio
import random
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pandas as pd
from sqlalchemy import text

from app.db import SessionLocal
from app.ml.dataset import pipe_table
from app.ml.train_anomaly import fit as fit_anomaly, false_alarm_rate
from app.ml.train_severity import evaluate as evaluate_severity
from app.ml.dataset import build_dataset
from app.ml.registry import register_model
from app.services.features import FEATURE_ORDER
from app.services.severity import classify, est_loss_pct, rank
from sklearn.ensemble import HistGradientBoostingRegressor


async def generate_runs():
    print("Connecting to database...")
    pipes = await pipe_table()
    if not pipes:
        raise SystemExit("No pipes found in pipe_segments. Run migrations 001 and 002 first!")

    async with SessionLocal() as s:
        async with s.begin():
            # Get pipe UUID mapping
            rows = (await s.execute(text("select id, code, design_flow_lpm from pipe_segments"))).mappings().all()
            pipe_map = {r["code"]: (r["id"], float(r["design_flow_lpm"])) for r in rows}

            # 1. Create Normal Twin Run
            normal_run_id = (await s.execute(
                text("insert into twin_runs (name, scenario, network_version, status) values ('training-normal', 'normal', 'dma-01', 'STOPPED') returning id")
            )).scalar_one()

            # 2. Create Leak Campaign Twin Run
            campaign_run_id = (await s.execute(
                text("insert into twin_runs (name, scenario, network_version, status) values ('training-campaign', 'leak-campaign', 'dma-01', 'STOPPED') returning id")
            )).scalar_one()

            # Generate 200 time steps at 5s interval (~1000s of data)
            t0 = datetime.now(timezone.utc) - timedelta(hours=2)
            normal_readings = []
            campaign_readings = []

            # Set leak injection for campaign run on several pipes
            leak_schedule = {
                "P05": 12.0,
                "P07": 8.5,
                "P10": 18.0,
                "P14": 25.0,
                "P15": 14.0,
            }

            for step in range(250):
                sim_time = t0 + timedelta(seconds=5 * step)
                for code, (pipe_id, design_flow) in pipe_map.items():
                    q = max(1.0, design_flow * 0.6) + random.gauss(0, 0.1)

                    # Normal run reading (leak = 0)
                    normal_readings.append({
                        "r": normal_run_id,
                        "p": pipe_id,
                        "t": sim_time,
                        "fi": round(q, 2),
                        "fo": round(q - 0.1 + random.gauss(0, 0.1), 2),
                        "pi": round(190 + random.gauss(0, 0.2), 2),
                        "po": round(188 + random.gauss(0, 0.2), 2),
                        "v": 0.3,
                        "il": 0.0,
                    })

                    # Campaign run reading
                    # Injects leak on scheduled pipes after step 30
                    lk = leak_schedule.get(code, 0.0) if step >= 30 else 0.0
                    campaign_readings.append({
                        "r": campaign_run_id,
                        "p": pipe_id,
                        "t": sim_time,
                        "fi": round(q, 2),
                        "fo": round(q - 0.1 - lk + random.gauss(0, 0.1), 2),
                        "pi": round(190 + random.gauss(0, 0.2) - lk * 0.5, 2),
                        "po": round(188 + random.gauss(0, 0.2) - lk * 0.5, 2),
                        "v": 0.3,
                        "il": float(lk),
                    })

            # Bulk insert readings
            insert_sql = text("""
                insert into twin_pipe_readings (run_id, pipe_id, sim_time, flow_in_lpm, flow_out_lpm,
                                               pressure_in_kpa, pressure_out_kpa, velocity_mps, injected_leak_lpm)
                values (:r, :p, :t, :fi, :fo, :pi, :po, :v, :il)
            """)
            await s.execute(insert_sql, normal_readings)
            await s.execute(insert_sql, campaign_readings)

    print(f"✓ Generated {len(normal_readings)} normal telemetry rows for run: {normal_run_id}")
    print(f"✓ Generated {len(campaign_readings)} campaign telemetry rows for run: {campaign_run_id}")
    return str(normal_run_id), str(campaign_run_id), pipes


async def train_anomaly(normal_run_id: str, pipes: dict):
    print("\nTraining ANOMALY (Isolation Forest) model...")
    from app.ml.dataset import load_twin_runs

    readings = await load_twin_runs([normal_run_id])
    readings = readings[readings["injected_leak_lpm"].fillna(0) == 0]
    holdout = {"P03"}
    train_df = readings[~readings["pipe_code"].isin(holdout)]
    test_df = readings[readings["pipe_code"].isin(holdout)]

    X, _ = build_dataset(train_df, pipes, stride=6)
    if len(X) < 200:
        print(f"Warning: {len(X)} windows generated")
    art = fit_anomaly(X[FEATURE_ORDER].to_numpy())
    metrics = {
        "n_train_windows": int(len(X)),
        "false_alarm_rate_train": false_alarm_rate(art, X[FEATURE_ORDER].to_numpy()),
    }
    if len(test_df):
        Xt, _ = build_dataset(test_df, pipes, stride=6)
        if len(Xt):
            metrics["false_alarm_rate_holdout_pipes"] = false_alarm_rate(art, Xt[FEATURE_ORDER].to_numpy())

    mid = await register_model(
        name="isolation-forest",
        version=datetime.now(timezone.utc).strftime("%Y%m%d%H%M"),
        task="ANOMALY",
        artifact=art,
        metrics=metrics,
        trained_on=f"run={normal_run_id}",
        activate=True,
        upload=True,
    )
    print(f"✓ ANOMALY model registered and activated! Model ID: {mid}")
    print(f"  Metrics: {metrics}")


async def train_severity(campaign_run_id: str, pipes: dict):
    print("\nTraining SEVERITY (HistGradientBoosting) model...")
    from app.ml.dataset import load_twin_runs

    readings = await load_twin_runs([campaign_run_id])
    holdout = {"P03", "P11"}
    X, meta = build_dataset(readings, pipes, stride=6, with_labels=True)
    X["pipe_code"] = meta["pipe_code"].values
    X["ts"] = meta["ts"].values
    X["y"] = meta["injected_leak_lpm"].values

    cut = X.groupby("pipe_code")["ts"].transform(lambda t: t.quantile(0.8))
    is_test = X["pipe_code"].isin(holdout) | (X["ts"] > cut)
    train, test = X[~is_test], X[is_test]

    model = HistGradientBoostingRegressor(max_iter=300, learning_rate=0.08, random_state=42)
    model.fit(train[FEATURE_ORDER].to_numpy(), train["y"].to_numpy())

    truth = [classify(est_loss_pct(y, f, d)) for y, f, d in zip(test["y"], test["flow_in_lpm"], test["design_flow_lpm"])]
    metrics = {
        "train_windows": int(len(train)),
        "test": evaluate_severity(model, test, test["y"].to_numpy(), truth) if len(test) else None,
    }

    mid = await register_model(
        name="hgb-leak-rate",
        version=datetime.now(timezone.utc).strftime("%Y%m%d%H%M"),
        task="SEVERITY",
        artifact={"model": model, "features": FEATURE_ORDER},
        metrics=metrics,
        trained_on=f"run={campaign_run_id}",
        activate=True,
        upload=True,
    )
    print(f"✓ SEVERITY model registered and activated! Model ID: {mid}")
    print(f"  Metrics: {metrics}")


async def main():
    normal_id, campaign_id, pipes = await generate_runs()
    await train_anomaly(normal_id, pipes)
    await train_severity(campaign_id, pipes)
    print("\n✓ ALL ML MODELS TRAINED, REGISTERED, AND ACTIVATED SUCCESSFULLY!")
    print("The backend hot-reloader will automatically pick them up.")


if __name__ == "__main__":
    asyncio.run(main())
