"""Model registry: load active models (joblib), hot-reload, score, register new models (9.3, 9.6)."""
from __future__ import annotations

import asyncio
import io
import logging
import os
from pathlib import Path
from typing import Any

import joblib
import numpy as np
from sqlalchemy import text

from app.config import settings
from app.db import SessionLocal, as_json, dumps
from app.services.features import FEATURE_ORDER, vectorize

log = logging.getLogger("AquaPulse.ml")


def _supabase():
    from supabase import create_client

    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def scale_anomaly(decision: float, hi: float, lo: float) -> float:
    """Isolation Forest decision_function (higher = more normal) -> 0..1.
    `hi` = 5th percentile of the training scores (-> 0), `lo` = training minimum (-> 1)."""
    span = max(hi - lo, 1e-9)
    return float(min(1.0, max(0.0, (hi - decision) / span)))


class ModelRegistry:
    def __init__(self) -> None:
        self.anomaly: dict[str, Any] | None = None
        self.severity: dict[str, Any] | None = None
        self.anomaly_id = None
        self.severity_id = None

    # ----- scoring -----
    def anomaly_score(self, feats: dict) -> float:
        if self.anomaly:
            a = self.anomaly
            x = vectorize(feats, a.get("features") or FEATURE_ORDER)
            return scale_anomaly(float(a["model"].decision_function(x)[0]), a["hi"], a["lo"])
        # Fallback until a model is trained/activated: z-score of the flow-loss residual.
        return float(min(1.0, max(0.0, feats["delta_q_z"]) / 12.0))

    def estimate_rate(self, feats: dict) -> float:
        if self.severity:
            v = self.severity
            x = vectorize(feats, v.get("features") or FEATURE_ORDER)
            return max(0.0, float(v["model"].predict(x)[0]))
        return max(0.0, float(feats["delta_q_resid"]))

    # ----- loading -----
    async def _fetch_artifact(self, path: str) -> Any:
        if path.startswith("file://") or os.path.exists(path):
            return joblib.load(path.removeprefix("file://"))
        local = Path(settings.ml_local_dir) / path
        if local.exists():
            return joblib.load(local)

        def _dl() -> bytes:
            return _supabase().storage.from_(settings.ml_model_bucket).download(path)

        return joblib.load(io.BytesIO(await asyncio.to_thread(_dl)))

    async def load(self) -> bool:
        """Load the active model per task. Returns True if something changed."""
        changed = False
        async with SessionLocal() as s:
            rows = (await s.execute(text("select id, task, artifact_path from ml_models where is_active"))).mappings().all()
        active = {r["task"]: r for r in rows}
        for task, attr_id, attr in (("ANOMALY", "anomaly_id", "anomaly"), ("SEVERITY", "severity_id", "severity")):
            row = active.get(task)
            if row is None:
                if getattr(self, attr_id) is not None:
                    setattr(self, attr_id, None); setattr(self, attr, None); changed = True
                continue
            if row["id"] != getattr(self, attr_id):
                try:
                    setattr(self, attr, await self._fetch_artifact(row["artifact_path"]))
                    setattr(self, attr_id, row["id"]); changed = True
                    log.info("loaded %s model %s", task, row["id"])
                except Exception as exc:
                    log.error("could not load %s model: %s", task, exc)
        return changed

    async def watch(self, interval_s: int = 60) -> None:
        while True:
            await asyncio.sleep(interval_s)
            try:
                await self.load()
            except Exception as exc:
                log.warning("model reload failed: %s", exc)


registry = ModelRegistry()


async def register_model(name: str, version: str, task: str, artifact: dict, metrics: dict, trained_on: str,
                         activate: bool = False, upload: bool = True) -> str:
    """Save artifact with joblib, upload to the ml-models bucket (or ML_LOCAL_DIR), insert ml_models row."""
    rel = f"{task.lower()}/{name}-{version}.joblib"
    local = Path(settings.ml_local_dir) / rel
    local.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(artifact, local)
    if upload and settings.supabase_url:
        def _up() -> None:
            _supabase().storage.from_(settings.ml_model_bucket).upload(
                rel, local.read_bytes(), {"content-type": "application/octet-stream", "upsert": "true"})
        await asyncio.to_thread(_up)
    async with SessionLocal() as s:
        async with s.begin():
            if activate:
                await s.execute(text("update ml_models set is_active=false where task=:t"), {"t": task})
            mid = (await s.execute(
                text("insert into ml_models (name, version, task, artifact_path, feature_spec, metrics, trained_on, is_active) "
                     "values (:n,:v,:t,:p,CAST(:fs AS jsonb),CAST(:m AS jsonb),:tr,:a) returning id"),
                {"n": name, "v": version, "t": task, "p": rel, "fs": dumps({"features": artifact.get("features")}),
                 "m": dumps(metrics), "tr": trained_on, "a": activate})).scalar_one()
    return str(mid)
