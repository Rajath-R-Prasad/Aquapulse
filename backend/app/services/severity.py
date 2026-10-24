"""Severity grading (9.4) and the severity / priority / urgency / SLA mapping (8.5)."""
from __future__ import annotations

import math

SEVERITY_ORDER = ["NONE", "MINOR", "MODERATE", "MAJOR", "CRITICAL"]
PRIORITY_FOR = {"MINOR": "P4", "MODERATE": "P3", "MAJOR": "P2", "CRITICAL": "P1", "NONE": "P4"}
URGENCY_FOR = {"MINOR": "ADVISORY", "MODERATE": "RECOMMENDED", "MAJOR": "IMMEDIATE", "CRITICAL": "IMMEDIATE", "NONE": "ADVISORY"}
URGENCY_ORDER = ["ADVISORY", "RECOMMENDED", "IMMEDIATE"]
DEFAULT_CUTOFFS = {"MINOR": 5, "MODERATE": 10, "MAJOR": 20, "CRITICAL": 40}


def rank(severity: str) -> int:
    return SEVERITY_ORDER.index(severity) if severity in SEVERITY_ORDER else 0


def est_loss_pct(est_leak_rate_lpm: float, flow_in_lpm: float, design_flow_lpm: float) -> float:
    denom = max(flow_in_lpm, 0.25 * design_flow_lpm, 1e-6)
    return est_leak_rate_lpm / denom * 100.0


def severity_score(loss_pct: float, pressure_dev_pct: float) -> float:
    s = 0.7 * min(1.0, loss_pct / 50.0) + 0.3 * min(1.0, abs(pressure_dev_pct) / 40.0)
    return float(min(1.0, max(0.0, s)))


def classify(loss_pct: float, cutoffs: dict | None = None, burst: bool = False) -> str:
    c = {**DEFAULT_CUTOFFS, **(cutoffs or {})}
    if burst or loss_pct >= c["CRITICAL"]:
        return "CRITICAL"
    if loss_pct >= c["MAJOR"]:
        return "MAJOR"
    if loss_pct >= c["MODERATE"]:
        return "MODERATE"
    if loss_pct >= c["MINOR"]:
        return "MINOR"
    return "NONE"


def is_burst(feats: dict, cfg: dict) -> bool:
    return (feats["pressure_dev_pct"] <= cfg.get("burst_pressure_dev_pct", -30)
            and feats["delta_q_pct"] >= cfg.get("burst_delta_q_pct", 30))


def grade(est_rate_lpm: float, feats: dict, design_flow_lpm: float, cutoffs: dict | None, burst: bool) -> dict:
    rate = max(0.0, float(est_rate_lpm))
    loss = est_loss_pct(rate, feats["flow_in_lpm"], design_flow_lpm)
    if not math.isfinite(loss):
        loss = 0.0
    sev = classify(loss, cutoffs, burst)
    return {"severity": sev, "severity_score": severity_score(loss, feats["pressure_dev_pct"]),
            "est_loss_pct": loss, "est_leak_rate_lpm": rate, "priority": PRIORITY_FOR[sev], "urgency": URGENCY_FOR[sev]}
