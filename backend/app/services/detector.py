"""Detection pipeline (9.1): prechecks -> features -> physics gate -> anomaly model -> severity model -> decision.

State between evaluations (consecutive-candidate counters, WARNING hysteresis) is held in memory per
(pipe, source); it is rebuilt within a few evaluations after a restart. Everything that changes the database
happens in the transaction of the caller (workers/evaluator.py), so one evaluation = one transaction.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from statistics import mean
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.db import dumps, fetchone, get_setting, scalar
from app.ml.registry import registry
from app.services import features as F
from app.services import severity as sev
from app.services import state

log = logging.getLogger("AquaPulse.detector")


@dataclass
class Runtime:
    candidates: list[float] = field(default_factory=list)   # consecutive candidate anomaly scores
    below_warn: int = 0                                     # consecutive evaluations under warn_score


_runtime: dict[tuple[str, str], Runtime] = {}
PIPE_SQL = """select id, code, state::text as state, monitoring::text as monitoring, diameter_mm, material::text as material,
              install_year, design_flow_lpm, length_m from pipe_segments where id = :p"""


async def evaluate(s: AsyncSession, pipe_id: UUID, source: str) -> dict | None:
    """Runs stages 0-5 for one pipe. Returns a small result dict (used by tests and logging)."""
    # ---- stage 0: prechecks
    pipe = await fetchone(s, PIPE_SQL, {"p": pipe_id})
    if not pipe:
        return None
    expected_source = "HARDWARE" if pipe["monitoring"] == "HARDWARE" else "TWIN"
    if source != expected_source:            # twin data for a HARDWARE pipe (or vice versa) is stored but ignored
        return None
    if source == "HARDWARE":
        dev = await fetchone(s, "select id, status::text as status from devices where pipe_id = :p and status <> 'RETIRED' limit 1",
                             {"p": pipe_id})
        if not dev or dev["status"] == "MAINTENANCE":
            return None

    # ---- stage 1: features
    df, meta = await F.load_frame(s, pipe_id, source)
    if df is None:
        return None
    hour, dow = F.local_hour_dow(df["ts"].max().to_pydatetime())
    baseline = await F.load_baseline(s, pipe_id, source, hour, dow)
    if baseline and (baseline.get("samples") or 0) < 30:      # too little history to trust
        baseline = None
    feats = F.build_features(df, pipe, baseline)
    if feats is None:
        return None
    pipe["design_flow_lpm"] = float(pipe["design_flow_lpm"])
    cfg = await get_setting("detection")
    cutoffs = await get_setting("severity_cutoffs_loss_pct")

    # ---- stage 2: physics gate; stage 3: anomaly model; stage 4: severity model
    gate = F.gate_passed(feats, cfg)
    score = registry.anomaly_score(feats)
    burst = gate and sev.is_burst(feats, cfg)
    grade = None
    if gate:
        grade = sev.grade(registry.estimate_rate(feats), feats, pipe["design_flow_lpm"], cutoffs, burst)

    inference_id = await scalar(s, """
        insert into ml_inferences (pipe_id, source, window_end, anomaly_model_id, severity_model_id, features,
                                   anomaly_score, is_anomaly, est_leak_rate_lpm, severity_score, severity)
        values (:p, CAST(:src AS data_source), :we, :am, :sm, CAST(:f AS jsonb), :sc, :ia, :r, :ss, CAST(:sv AS severity_level))
        returning id""",
        {"p": pipe_id, "src": source, "we": df["ts"].max().to_pydatetime(), "am": registry.anomaly_id,
         "sm": registry.severity_id, "f": dumps({k: v for k, v in feats.items() if not k.startswith("_")}),
         "sc": score, "ia": bool(gate and score >= cfg["confirm_score"]),
         "r": grade["est_leak_rate_lpm"] if grade else None, "ss": grade["severity_score"] if grade else None,
         "sv": grade["severity"] if grade else None})

    # ---- stage 5: decision
    open_ev = await fetchone(s, "select id, pipe_id, severity::text as severity from leak_events where pipe_id = :p "
                                "and status not in ('CLOSED','FALSE_ALARM')", {"p": pipe_id})
    if open_ev:                                # only evaluate escalation (8.2) and stop
        escalated = bool(grade) and await state.escalate_event(s, open_ev, grade)
        return {"action": "ESCALATED" if escalated else "OPEN_EVENT", "score": score}

    rt = _runtime.setdefault((str(pipe_id), source), Runtime())
    candidate = gate and score >= cfg["confirm_score"]
    rt.candidates = rt.candidates + [score] if candidate else []
    confirmed = bool(burst) or len(rt.candidates) >= int(cfg["confirm_windows"])

    if confirmed and grade:
        scores = rt.candidates or [score]
        confidence = mean(scores) * meta["quality_factor"]
        if grade["severity"] == "NONE":       # a confirmed leak is never below MINOR
            grade = {**grade, "severity": "MINOR", "priority": sev.PRIORITY_FOR["MINOR"], "urgency": sev.URGENCY_FOR["MINOR"]}
        params = {**F.summary(feats, score), "quality_factor": meta["quality_factor"]}
        created = await state.open_leak_event(s, pipe, source, meta["device_id"], meta["run_id"], params, inference_id,
                                              grade, confidence)
        rt.candidates, rt.below_warn = [], 0
        if created:
            log.info("leak confirmed on %s (%s): %s", pipe["code"], source, grade["severity"])
        return {"action": "LEAK_CONFIRMED", "score": score, "event": created}

    # WARNING hysteresis (8.1): up at warn_score, back to NORMAL after 6 consecutive evaluations below it
    action = "NONE"
    if score >= cfg["warn_score"]:
        rt.below_warn = 0
        if pipe["state"] == "NORMAL":
            await state.set_pipe_state(s, pipe_id, "WARNING", f"Anomaly score {score:.2f}", None, "SYSTEM")
            action = "WARNING"
    elif pipe["state"] == "WARNING":
        rt.below_warn += 1
        if rt.below_warn >= int(cfg.get("warn_clear_windows", 6)):
            await state.set_pipe_state(s, pipe_id, "NORMAL", "Anomaly score back to normal", None, "SYSTEM")
            rt.below_warn = 0
            action = "WARNING_CLEARED"
    return {"action": action, "score": score}
