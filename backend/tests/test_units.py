"""Pure-logic tests: unit normalisation, severity grading, isolation algorithm, features, anomaly scaling."""
import math
from datetime import datetime, timedelta, timezone

import numpy as np
import pandas as pd
import pytest

from app.ml.registry import scale_anomaly
from app.schemas.auth import EngineerSignupBody, OperatorSignupBody
from app.schemas.common import ProblemException, decode_cursor, encode_cursor
from app.services import features as F
from app.services.dispatch import breakdown as dispatch_breakdown
from app.services import severity as sev
from app.services.isolation import affected_connections, build_message, compute_isolation
from app.services.normalize import normalize_reading


# ---------- normalize
def test_engineer_signup_normalizes_email_and_name():
    body = EngineerSignupBody(
        email="  Engineer@Example.com ",
        password="valid-demo-password",
        full_name="  Ravi Kumar  ",
    )
    assert body.email == "engineer@example.com"
    assert body.full_name == "Ravi Kumar"


def test_engineer_signup_rejects_short_password():
    with pytest.raises(ValueError):
        EngineerSignupBody(
            email="engineer@example.com",
            password="short",
            full_name="Ravi Kumar",
        )


def test_operator_signup_normalizes_email_name_and_setup_code():
    body = OperatorSignupBody(
        email="  Operator@Example.com ",
        password="long-enough-password",
        full_name="  AquaPulse Operator  ",
        setup_code="  setup-code-value  ",
    )
    assert body.email == "operator@example.com"
    assert body.full_name == "AquaPulse Operator"
    assert body.setup_code == "setup-code-value"


def test_operator_signup_requires_long_password_and_setup_code():
    with pytest.raises(ValueError):
        OperatorSignupBody(
            email="operator@example.com",
            password="short",
            full_name="AquaPulse Operator",
            setup_code="setup-code-value",
        )
    with pytest.raises(ValueError):
        OperatorSignupBody(
            email="operator@example.com",
            password="long-enough-password",
            full_name="AquaPulse Operator",
            setup_code="",
        )


def test_operator_signup_endpoint_is_public_and_in_openapi():
    from app.main import app

    operation = app.openapi()["paths"]["/v1/auth/operator-signup"]["post"]
    assert "security" not in operation
    assert operation["requestBody"]["content"]["application/json"]["schema"]["$ref"].endswith(
        "/OperatorSignupBody"
    )
    status_operation = app.openapi()["paths"]["/v1/auth/operator-signup-status"]["get"]
    assert "security" not in status_operation


def test_dispatch_candidate_without_location_gets_no_proximity_bonus():
    score_parts = dispatch_breakdown(
        {
            "distance_m": None,
            "status": "AVAILABLE",
            "active_jobs": 0,
            "has_skill": True,
        },
        max_active_jobs=1,
    )
    assert score_parts["proximity"] == {"value": 0.0, "weight": 0.5}
    assert score_parts["availability"]["value"] == 1.0
    assert score_parts["distance_m"] is None


@pytest.mark.parametrize(
    "url,expected",
    [
        ("https://example-project.supabase.co", "example-project"),
        ("http://localhost:54321", None),
        ("https://auth.example.com", None),
    ],
)
def test_supabase_project_ref(url, expected):
    from app.routers.auth import _supabase_project_ref

    assert _supabase_project_ref(url) == expected


def test_public_demo_dashboard_is_read_only_and_anonymous():
    from app.main import app

    operation = app.openapi()["paths"]["/v1/demo/dashboard"]["get"]
    assert "security" not in operation


def test_engineer_work_order_detail_route_is_registered():
    from app.main import app

    assert "/v1/work-orders/{wo_id}" in app.openapi()["paths"]


def test_repair_submission_location_override_defaults_off():
    from app.schemas.workorders import SubmitBody

    body = SubmitBody(repair_type="CLAMP")
    assert body.allow_simulated_location_override is False
    assert SubmitBody(
        repair_type="CLAMP",
        allow_simulated_location_override=True,
    ).allow_simulated_location_override is True


@pytest.mark.parametrize("sensor,val,unit,expected", [
    ("FLOW_IN", 1.0, "L/s", 60.0), ("FLOW_IN", 0.01, "m3/s", 600.0), ("FLOW_OUT", 6.0, "m3/h", 100.0),
    ("FLOW_OUT", 10, "L/min", 10), ("PRESSURE_IN", 1.5, "bar", 150.0), ("PRESSURE_OUT", 100000, "Pa", 100.0),
    ("PRESSURE_IN", 182, "kPa", 182), ("ACOUSTIC_RMS", 0.4, "1", 0.4)])
def test_units(sensor, val, unit, expected):
    v, ok = normalize_reading(sensor, val, unit)
    assert v == pytest.approx(expected) and ok


def test_unit_rejected_with_422():
    with pytest.raises(ProblemException) as e:
        normalize_reading("FLOW_IN", 1, "gpm")
    assert e.value.status == 422


def test_out_of_range_flagged():
    assert normalize_reading("FLOW_IN", 5000, "L/min")[1] is False
    assert normalize_reading("PRESSURE_IN", -3, "kPa")[1] is False


# ---------- severity (9.4 / 8.5)
@pytest.mark.parametrize("loss,expected", [(2, "NONE"), (5, "MINOR"), (9.9, "MINOR"), (10, "MODERATE"), (19.9, "MODERATE"),
                                           (20, "MAJOR"), (39.9, "MAJOR"), (40, "CRITICAL")])
def test_classes(loss, expected):
    assert sev.classify(loss) == expected


def test_burst_is_critical_and_priority_map():
    assert sev.classify(1, burst=True) == "CRITICAL"
    assert (sev.PRIORITY_FOR["CRITICAL"], sev.PRIORITY_FOR["MAJOR"], sev.PRIORITY_FOR["MODERATE"], sev.PRIORITY_FOR["MINOR"]) == ("P1", "P2", "P3", "P4")
    assert sev.URGENCY_FOR["MAJOR"] == "IMMEDIATE" and sev.URGENCY_FOR["MODERATE"] == "RECOMMENDED"


def test_loss_and_score_formula():
    assert sev.est_loss_pct(18.4, 79.6, 100) == pytest.approx(23.115, abs=1e-2)
    assert sev.est_loss_pct(10, 5, 100) == pytest.approx(40.0)        # denominator floor 0.25 x design flow
    assert sev.severity_score(50, 40) == 1.0
    assert sev.severity_score(25, -20) == pytest.approx(0.7 * 0.5 + 0.3 * 0.5)


def test_burst_signature():
    cfg = {"burst_pressure_dev_pct": -30, "burst_delta_q_pct": 30}
    assert sev.is_burst({"pressure_dev_pct": -31, "delta_q_pct": 30}, cfg)
    assert not sev.is_burst({"pressure_dev_pct": -29, "delta_q_pct": 50}, cfg)


# ---------- isolation (10.2)
def _grid():
    nodes = {"R": {"kind": "RESERVOIR", "served_connections": 0}, "A": {"kind": "JUNCTION", "served_connections": 10},
             "B": {"kind": "JUNCTION", "served_connections": 20}, "C": {"kind": "JUNCTION", "served_connections": 30}}
    pipes = {"p1": {"from_node": "R", "to_node": "A"}, "p2": {"from_node": "A", "to_node": "B"}, "p3": {"from_node": "B", "to_node": "C"}}
    return nodes, pipes


def _valves(pipes, skip=()):
    return [{"id": f"v_{p}_{n}", "pipe_id": p, "at_node": n, "kind": "ISOLATION", "state": "OPEN"}
            for p, d in pipes.items() for n in (d["from_node"], d["to_node"]) if (p, n) not in skip]


def test_isolation_valves_at_both_ends():
    nodes, pipes = _grid()
    valves, region = compute_isolation("p2", pipes, nodes, _valves(pipes))
    assert valves == {"v_p2_A", "v_p2_B"} and region == {"p2"}
    # removing p2 cuts B and C off the reservoir: 20 + 30 connections
    assert affected_connections(region, pipes, nodes) == 50


def test_isolation_uses_neighbour_valve_when_own_end_has_none():
    nodes, pipes = _grid()
    valves, region = compute_isolation("p2", pipes, nodes, _valves(pipes, skip={("p2", "B")}))
    assert valves == {"v_p2_A", "v_p3_B"} and region == {"p2"}


def test_isolation_expands_region_when_no_valves_nearby():
    nodes, pipes = _grid()
    valves, region = compute_isolation("p2", pipes, nodes, _valves(pipes, skip={("p2", "B"), ("p3", "B")}))
    assert region == {"p2", "p3"} and valves == {"v_p2_A", "v_p3_C"}


def test_isolation_returns_none_when_source_reached():
    nodes, pipes = _grid()
    assert compute_isolation("p1", pipes, nodes, _valves(pipes, skip={("p1", "R")})) is None


def test_isolation_messages():
    assert build_message("P17", [], 0, "MAJOR", 18.4) == "No isolation valve mapped, contact the field team."
    assert build_message("P17", ["V1", "V2"], 124, "MAJOR", 18.4) == \
        "Close V1, V2 to isolate P17 (about 124 connections lose supply). Severity MAJOR, about 18 L/min."


# ---------- features (9.2)
PIPE = {"diameter_mm": 150, "material": "CI", "install_year": 1990, "design_flow_lpm": 100.0}


def _frame(n=14, leak=0.0, seed=1):
    rng = np.random.default_rng(seed)
    t0 = datetime(2026, 10, 15, 4, 0, tzinfo=timezone.utc)
    rows = [{"ts": t0 + timedelta(seconds=5 * i), "flow_in": 80 + rng.normal(0, 0.1), "flow_out": 79.6 - leak + rng.normal(0, 0.1),
             "pressure_in": 182 + rng.normal(0, 0.2), "pressure_out": 181 + rng.normal(0, 0.2), "acoustic": np.nan} for i in range(n)]
    return pd.DataFrame(rows)


def test_features_normal_vs_leak_and_gate():
    cfg = {"gate_delta_q_pct": 5, "gate_min_delta_q_lpm": 1.0}
    normal = F.build_features(_frame(), PIPE, None)
    leak = F.build_features(_frame(leak=18.4), PIPE, None)
    assert set(F.FEATURE_ORDER) <= set(normal) and "injected_leak_lpm" not in normal
    assert not F.gate_passed(normal, cfg) and F.gate_passed(leak, cfg)
    assert leak["delta_q_lpm"] == pytest.approx(18.8, abs=0.5) and leak["has_acoustic"] == 0 and leak["acoustic_rms"] == 0
    assert leak["hour_sin"] ** 2 + leak["hour_cos"] ** 2 == pytest.approx(1)
    assert F.vectorize(leak).shape == (1, len(F.FEATURE_ORDER))


def test_features_need_enough_samples():
    assert F.build_features(_frame(n=2), PIPE, None) is None


def test_baseline_changes_residual():
    f = F.build_features(_frame(), PIPE, {"delta_q_mean_lpm": 0.4, "delta_q_std_lpm": 0.2, "pressure_in_mean_kpa": 182.0})
    assert abs(f["delta_q_resid"]) < 0.5 and f["baseline_delta_q_std_lpm"] == 0.2


def test_anomaly_scaling():
    assert scale_anomaly(0.2, hi=0.1, lo=-0.3) == 0.0
    assert scale_anomaly(-0.3, hi=0.1, lo=-0.3) == 1.0
    assert 0 < scale_anomaly(-0.1, hi=0.1, lo=-0.3) < 1


def test_cursor_roundtrip():
    t = datetime(2026, 10, 15, 9, 30, tzinfo=timezone.utc)
    assert decode_cursor(encode_cursor(t, "abc"))[0] == t
    with pytest.raises(ProblemException):
        decode_cursor("not-a-cursor")
