"""End-to-end acceptance tests (section 14.2, AT01-AT13) against a real PostgreSQL/PostGIS database that has
migrations 001_init.sql and 002_seed_dma01.sql applied. Skipped unless TEST_DATABASE_URL is set.

The test drives the real FastAPI app through ASGI. The background evaluator is replaced by direct calls to
`detector.evaluate` so the test does not have to wait for the 5 s evaluation interval. The Supabase Storage
calls are not exercised (evidence is registered by path)."""
import os
import uuid
from datetime import datetime, timedelta, timezone

import httpx
import jwt
import pytest
from sqlalchemy import text

pytestmark = pytest.mark.skipif(not os.environ.get("TEST_DATABASE_URL"), reason="TEST_DATABASE_URL not set")

SECRET = os.environ["SUPABASE_JWT_SECRET"]
TWIN = {"Authorization": "Bearer " + os.environ["TWIN_SERVICE_TOKEN"]}
ADMIN, OPER, ENG1, ENG2, ENG3, ENG4 = (uuid.uuid4() for _ in range(6))
DEVICE_TOKEN = "d" * 64
NOW = lambda: datetime.now(timezone.utc)  # noqa: E731


def bearer(uid):
    return {"Authorization": "Bearer " + jwt.encode({"sub": str(uid), "aud": "authenticated"}, SECRET, algorithm="HS256")}


def iso(t):
    return t.isoformat().replace("+00:00", "Z")


@pytest.fixture(scope="module")
async def env():
    from app.db import SessionLocal, session_scope
    from app.main import create_app
    from app.security import device_rate_limiter, hash_token

    async with session_scope() as s:
        await s.execute(text("update pipe_segments set state='NORMAL', active_event_id=null"))
        for t in ("notifications", "event_log", "pipe_state_history", "repair_evidence", "work_order_assignments", "work_orders",
                  "isolation_advisory_valves", "isolation_advisories", "twin_commands", "leak_events", "ml_inferences",
                  "hw_readings", "twin_pipe_readings", "twin_runs", "signal_latest", "pipe_baselines", "device_sensors",
                  "devices", "engineers", "device_tokens", "profiles"):
            await s.execute(text(f"delete from {t}"))
        await s.execute(text("update pipe_segments set state='NORMAL', active_event_id=null"))
        await s.execute(text("update valves set state='OPEN'"))
        await s.execute(text("delete from auth.users"))
        people = [(ADMIN, "Admin", "ADMIN"), (OPER, "Operator", "OPERATOR"), (ENG1, "Eng Near", "ENGINEER"),
                  (ENG2, "Eng OffDuty", "ENGINEER"), (ENG3, "Eng Stale", "ENGINEER"), (ENG4, "Eng Other", "ENGINEER")]
        for uid, name, role in people:
            await s.execute(text("insert into auth.users (id, email) values (:i, :e)"), {"i": uid, "e": f"{name}@x.test"})
            await s.execute(text("insert into profiles (id, full_name, role) values (:i, :n, CAST(:r AS user_role))"),
                            {"i": uid, "n": name, "r": role})
        for i, (uid, status) in enumerate([(ENG1, "AVAILABLE"), (ENG2, "OFF_DUTY"), (ENG3, "AVAILABLE"), (ENG4, "AVAILABLE")]):
            await s.execute(text("insert into engineers (profile_id, employee_code, status, skills) "
                                 "values (:i, :c, CAST(:s AS engineer_status), '{PIPE_REPAIR}')"), {"i": uid, "c": f"E{i}", "s": status})
        # ENG3: location older than 15 minutes (stale); ENG2 has a fresh location but is OFF_DUTY
        loc = "ST_SetSRID(ST_MakePoint(76.6395, 12.2975),4326)::geography"
        await s.execute(text(f"update engineers set last_location={loc}, last_location_at=now()-interval '2 hours' where profile_id=:i"), {"i": ENG3})
        await s.execute(text(f"update engineers set last_location={loc}, last_location_at=now() where profile_id=:i"), {"i": ENG2})
        p17 = (await s.execute(text("select id from pipe_segments where code='P17'"))).scalar_one()
        p05 = (await s.execute(text("select id from pipe_segments where code='P05'"))).scalar_one()
        await s.execute(text("insert into devices (device_uid, pipe_id, token_hash) values ('JR-ESP32-0001', :p, :h)"),
                        {"p": p17, "h": hash_token(DEVICE_TOKEN)})
        await s.execute(text("insert into devices (device_uid, pipe_id, token_hash) values ('JR-BAD-0002', :p, :h)"),
                        {"p": p05, "h": hash_token("e" * 64)})
    app = create_app()
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        yield {"c": client, "limiter": device_rate_limiter, "SessionLocal": SessionLocal}


async def q(env, sql, **p):
    async with env["SessionLocal"]() as s:
        return [dict(r) for r in (await s.execute(text(sql), p)).mappings().all()]


async def evaluate(pipe_code, source):
    from app.db import scalar, session_scope
    from app.services import detector

    async with session_scope() as s:
        pid = await scalar(s, "select id from pipe_segments where code = :c", {"c": pipe_code})
        return await detector.evaluate(s, pid, source)


def hw_msg(seq, ts, fi=79.6, fo=79.2, pi=182.0, po=181.0, boot="a3f9c1d2", unit_flow="L/min", device="JR-ESP32-0001"):
    return {"schema": "AquaPulse.hw.reading/1.0", "device_uid": device, "boot_id": boot, "seq": seq, "ts": iso(ts), "fw": "1.2.0",
            "readings": [{"sensor": "FLOW_IN", "value": fi, "unit": unit_flow, "quality": "GOOD"},
                         {"sensor": "FLOW_OUT", "value": fo, "unit": unit_flow, "quality": "GOOD"},
                         {"sensor": "PRESSURE_IN", "value": pi, "unit": "kPa", "quality": "GOOD"},
                         {"sensor": "PRESSURE_OUT", "value": po, "unit": "kPa", "quality": "GOOD"}]}


async def post_hw(env, msg, token=DEVICE_TOKEN):
    env["limiter"]._last.clear()
    return await env["c"].post("/v1/ingest/hardware/readings", json=msg, headers={"Authorization": f"Bearer {token}"})


async def test_full_loop(env):
    c = env["c"]

    # ---------------- AT01: same hardware message twice -> one row, second says duplicate
    t0 = NOW() - timedelta(minutes=3)
    r1 = await post_hw(env, hw_msg(1, t0))
    r2 = await post_hw(env, hw_msg(1, t0))
    assert r1.status_code == 202 and r1.json()["status"] == "accepted" and r1.json()["config"]["report_interval_s"] == 5
    assert r2.status_code == 202 and r2.json()["status"] == "duplicate"
    assert (await q(env, "select count(*) n from hw_readings"))[0]["n"] == 1
    assert (await q(env, "select flow_in_lpm from signal_latest where source='HARDWARE'"))[0]["flow_in_lpm"] == pytest.approx(79.6)

    # unit conversion on the wire: 1.3 L/s -> 78 L/min ; bad unit -> 422 problem+json ; bad token -> 401
    r = await post_hw(env, hw_msg(2, t0 + timedelta(seconds=5), fi=1.3, fo=1.3, unit_flow="L/s"))
    assert r.status_code == 202
    assert (await q(env, "select flow_in_lpm from hw_readings where seq=2"))[0]["flow_in_lpm"] == pytest.approx(78.0)
    bad = await post_hw(env, hw_msg(3, t0, unit_flow="gpm"))
    assert bad.status_code == 422 and bad.headers["content-type"].startswith("application/problem+json")
    assert (await post_hw(env, hw_msg(4, t0), token="x" * 64)).status_code == 401

    # ---------------- AT02: device mapped to a SIMULATED pipe -> 409
    r = await post_hw(env, hw_msg(1, t0, device="JR-BAD-0002"), token="e" * 64)
    assert r.status_code == 409 and r.json()["type"].endswith("device-mapped-to-simulated-pipe")

    # ---------------- Tunnel B: twin pulls the network, starts a run
    net = (await c.get("/v1/twin/network", headers=TWIN)).json()
    kinds = [f["properties"]["feature_type"] for f in net["features"]]
    assert kinds.count("PIPE") == 18 and kinds.count("NODE") == 13 and kinds.count("VALVE") == 36
    run = (await c.post("/v1/ingest/twin/runs", json={"action": "START", "name": "acceptance"}, headers=TWIN)).json()["run_id"]

    async def snapshot(step, leak_p05=0.0, leak_p17=None):
        pipes = [{"pipe_code": "P05", "flow_in": 60.0, "flow_out": 60.0 - leak_p05, "pressure_in": 190.0, "pressure_out": 188.0,
                  "velocity": 0.3, "injected_leak": leak_p05},
                 {"pipe_code": "P14", "flow_in": 9.8, "flow_out": 9.8, "pressure_in": 190.0, "pressure_out": 188.0}]
        if leak_p17 is not None:
            pipes.append({"pipe_code": "P17", "flow_in": 80.0, "flow_out": 79.5, "pressure_in": 182.0, "pressure_out": 181.0})
        body = {"schema": "AquaPulse.twin.snapshot/1.0", "run_id": run, "units": {"flow": "L/min", "pressure": "kPa", "velocity": "m/s"},
                "sim_time": iso(datetime(2026, 10, 15, 4, 0, tzinfo=timezone.utc) + timedelta(seconds=5 * step)), "pipes": pipes}
        return await c.post("/v1/ingest/twin/snapshots", json=body, headers=TWIN)

    # 24 h normal-style steps: no event, no pipe state change
    for i in range(14):
        r = await snapshot(i, leak_p17=0)
        assert r.status_code == 202
        await evaluate("P05", "TWIN")
    assert r.json()["ignored_for_detection"] == ["P17"]               # HARDWARE pipe: twin data stored but ignored
    assert (await q(env, "select count(*) n from leak_events"))[0]["n"] == 0

    # ---------------- AT03: injected ~20 % leak on a SIMULATED pipe
    outcome = None
    for i in range(14, 34):
        await snapshot(i, leak_p05=12.0)
        outcome = await evaluate("P05", "TWIN")
        if outcome and outcome["action"] == "LEAK_CONFIRMED":
            break
    assert outcome and outcome["action"] == "LEAK_CONFIRMED", outcome
    ev = (await q(env, "select * from v_leak_events_enriched where pipe_code='P05'"))[0]
    event_id, wo_id, adv_id = ev["id"], ev["work_order_id"], ev["advisory_id"]
    assert ev["source"] == "TWIN" and ev["is_simulated"] is True and ev["severity"] in ("MODERATE", "MAJOR", "CRITICAL")
    assert ev["wo_status"] == "UNASSIGNED" and ev["advisory_status"] == "OPEN" and ev["status"] == "DETECTED"
    assert (await q(env, "select state::text s from pipe_segments where code='P05'"))[0]["s"] == "LEAK"
    assert (await q(env, "select count(*) n from notifications where type='LEAK_DETECTED' and recipient_id in (:a,:o)", a=ADMIN, o=OPER))[0]["n"] == 2
    assert (await q(env, "select type::text t from twin_commands where leak_event_id=:e", e=event_id)) == [{"t": "SET_PIPE_STATE"}]  # twin source: no INJECT_LEAK

    # ---------------- AT04: advisory lists exactly the valves at both ends
    obj = (await c.get(f"/v1/leak-events/{event_id}", headers=bearer(OPER))).json()
    expect = {r["code"] for r in await q(env, "select v.code from valves v join pipe_segments p on p.id=v.pipe_id where p.code='P05'")}
    assert {v["code"] for v in obj["advisory"]["valves"]} == expect and len(expect) == 2
    assert obj["pipe"]["code"] == "P05" and obj["location"]["type"] == "Point" and obj["search_geom"]["type"] == "LineString"
    assert obj["location_method"] == "SEGMENT_MIDPOINT" and obj["parameters"]["delta_q_lpm"] == pytest.approx(12.0, abs=1.0)
    assert obj["advisory"]["message"].startswith("Close V")

    # ---------------- AT05: dispatch list excludes OFF_DUTY, stale-location and fully loaded engineers
    for uid in (ENG1, ENG4):
        pos = {"lat": 12.2975, "lon": 76.6395 if uid == ENG1 else 76.70}
        assert (await c.post("/v1/me/location", json=pos, headers=bearer(uid))).status_code == 200
    cands = (await c.get(f"/v1/leak-events/{event_id}/engineer-candidates", headers=bearer(OPER))).json()["items"]
    ids = [x["engineer_id"] for x in cands]
    assert ids == [str(ENG1), str(ENG4)] or [str(i) for i in ids] == [str(ENG1), str(ENG4)]        # ranked: near first
    assert cands[0]["score"] > cands[1]["score"]
    # engineers cannot use utility endpoints
    assert (await c.get(f"/v1/leak-events/{event_id}/engineer-candidates", headers=bearer(ENG1))).status_code == 403

    # acknowledge, advisory: acknowledge, confirm valves closed -> ISOLATED
    assert (await c.post(f"/v1/leak-events/{event_id}/acknowledge", json={"expected_status": "DETECTED"}, headers=bearer(OPER))).status_code == 200
    assert (await c.post(f"/v1/leak-events/{event_id}/acknowledge", json={"expected_status": "DETECTED"}, headers=bearer(OPER))).status_code == 409
    assert (await c.post(f"/v1/isolation-advisories/{adv_id}/acknowledge", headers=bearer(OPER))).status_code == 200
    for v in obj["advisory"]["valves"]:
        r = await c.post(f"/v1/isolation-advisories/{adv_id}/valves/{v['id']}/confirm-closed", headers=bearer(OPER))
        assert r.status_code == 200
    assert r.json()["status"] == "ISOLATED"
    assert (await q(env, "select state::text s from pipe_segments where code='P05'"))[0]["s"] == "ISOLATED"
    assert (await q(env, "select count(*) n from twin_commands where type='SET_VALVE_STATE'"))[0]["n"] == 2

    # ---------------- AT06: engineer B cannot see or touch engineer A's work order
    r = await c.post(f"/v1/work-orders/{wo_id}/assign", json={"engineer_id": str(ENG1)}, headers=bearer(OPER))
    assert r.status_code == 200 and r.json()["status"] == "ASSIGNED"
    detail = await c.get(f"/v1/work-orders/{wo_id}", headers=bearer(ENG1))
    assert detail.status_code == 200
    detail_json = detail.json()
    assert detail_json["id"] == str(wo_id)
    assert detail_json["status"] == "ASSIGNED"
    assert detail_json["leak_event"]["event_no"] == obj["event_no"]
    assert detail_json["leak_event"]["pipe_code"] == "P05"
    assert isinstance(detail_json["leak_event"]["lat"], (int, float))
    assert isinstance(detail_json["leak_event"]["lon"], (int, float))
    assert (await c.get(f"/v1/work-orders/{wo_id}", headers=bearer(ENG4))).status_code == 403
    assert (await q(env, "select status::text s from engineers where profile_id=:i", i=ENG1))[0]["s"] == "ASSIGNED"
    assert (await c.get(f"/v1/leak-events/{event_id}", headers=bearer(ENG4))).status_code == 403
    assert (await c.post(f"/v1/work-orders/{wo_id}/accept", headers=bearer(ENG4))).status_code == 403
    assert (await c.get("/v1/me/work-orders", headers=bearer(ENG4))).json()["items"] == []
    mine = (await c.get("/v1/me/work-orders", headers=bearer(ENG1))).json()["items"]
    assert len(mine) == 1 and mine[0]["is_simulated"] is True

    # accept -> en route -> arrive (geofence)
    assert (await c.post(f"/v1/work-orders/{wo_id}/accept", headers=bearer(ENG1))).json()["status"] == "ACCEPTED"
    assert (await c.post(f"/v1/work-orders/{wo_id}/en-route", headers=bearer(ENG1))).json()["status"] == "EN_ROUTE"
    lon, lat = obj["location"]["coordinates"]
    far = await c.post(f"/v1/work-orders/{wo_id}/arrive", json={"lat": lat + 0.01, "lon": lon}, headers=bearer(ENG1))
    assert far.status_code == 422 and far.json()["type"].endswith("arrival-outside-geofence")
    r = await c.post(f"/v1/work-orders/{wo_id}/arrive", json={"lat": lat, "lon": lon}, headers=bearer(ENG1))
    assert r.json()["status"] == "ON_SITE"
    assert (await q(env, "select state::text s from pipe_segments where code='P05'"))[0]["s"] == "UNDER_REPAIR"

    # ---------------- AT07 / AT08: evidence rules
    def evidence(kind, dlat=0.0, name=None):
        return {"storage_path": f"repair-evidence/{wo_id}/{name or uuid.uuid4()}.jpg", "kind": kind, "mime_type": "image/jpeg",
                "captured_at": iso(NOW()), "lat": lat + dlat, "lon": lon, "size_bytes": 1000}

    before = (await c.post(f"/v1/work-orders/{wo_id}/evidence", json=evidence("BEFORE_PHOTO"), headers=bearer(ENG1))).json()
    assert before["geo_valid"] is True
    sub = {"repair_type": "CLAMP", "materials": [{"item": "Repair clamp 150 mm", "qty": 1}], "labour_minutes": 95, "work_notes": "done"}
    r = await c.post(f"/v1/work-orders/{wo_id}/submit", json=sub, headers=bearer(ENG1))
    assert r.status_code == 422 and r.json()["type"].endswith("evidence-missing")                      # AT07
    far_photo = (await c.post(f"/v1/work-orders/{wo_id}/evidence", json=evidence("AFTER_PHOTO", dlat=0.0019), headers=bearer(ENG1))).json()
    assert far_photo["geo_valid"] is False and 150 < far_photo["distance_to_leak_m"] < 300
    far_submission = {**sub, "evidence_ids": [before["id"], far_photo["id"]]}
    r = await c.post(f"/v1/work-orders/{wo_id}/submit", json=far_submission, headers=bearer(ENG1))
    assert r.status_code == 422 and r.json()["type"].endswith("evidence-geotag-too-far")               # AT08
    assert r.json()["errors"][0]["distance_m"] > 150
    r = await c.post(
        f"/v1/work-orders/{wo_id}/submit",
        json={**far_submission, "allow_simulated_location_override": True},
        headers=bearer(ENG1),
    )
    assert r.status_code == 200 and r.json()["status"] == "SUBMITTED"

    # Return to rework so the normal, location-verified resubmission remains covered too.
    r = await c.post(f"/v1/work-orders/{wo_id}/reject", json={"reason": "Retake the after photo"}, headers=bearer(OPER))
    assert r.json()["status"] == "REWORK"
    after = (await c.post(f"/v1/work-orders/{wo_id}/evidence", json=evidence("AFTER_PHOTO"), headers=bearer(ENG1))).json()
    ok = {**sub, "evidence_ids": [before["id"], after["id"]]}
    r = await c.post(f"/v1/work-orders/{wo_id}/submit", json=ok, headers=bearer(ENG1))
    assert r.status_code == 200 and r.json()["status"] == "SUBMITTED"
    assert (await q(env, "select state::text s from pipe_segments where code='P05'"))[0]["s"] == "PENDING_VERIFICATION"

    # ---------------- AT10: reject with a reason -> REWORK, pipe UNDER_REPAIR, engineer notified
    assert (await c.post(f"/v1/work-orders/{wo_id}/reject", json={}, headers=bearer(OPER))).status_code == 422   # reason required
    r = await c.post(f"/v1/work-orders/{wo_id}/reject", json={"reason": "Clamp not tight"}, headers=bearer(OPER))
    assert r.json()["status"] == "REWORK" and r.json()["rework_count"] == 2
    assert (await q(env, "select state::text s from pipe_segments where code='P05'"))[0]["s"] == "UNDER_REPAIR"
    assert (await q(env, "select count(*) n from notifications where type='WO_REJECTED' and recipient_id=:e", e=ENG1))[0]["n"] == 2
    r = await c.post(f"/v1/work-orders/{wo_id}/submit", json=ok, headers=bearer(ENG1))
    assert r.json()["status"] == "SUBMITTED"

    # ---------------- AT09: approve -> pipe NORMAL, event CLOSED, twin commands reach APPLIED
    r = await c.post(f"/v1/work-orders/{wo_id}/approve", json={"comment": "Looks good"}, headers=bearer(OPER))
    assert r.status_code == 200 and r.json()["status"] == "COMPLETED"
    assert r.json()["post_repair_check"]["status"] == "NOT_APPLICABLE_SIMULATED"
    assert (await q(env, "select state::text s, active_event_id from pipe_segments where code='P05'")) == [{"s": "NORMAL", "active_event_id": None}]
    assert (await q(env, "select status::text s from leak_events where id=:e", e=event_id))[0]["s"] == "CLOSED"
    assert (await q(env, "select status::text s from engineers where profile_id=:i", i=ENG1))[0]["s"] == "AVAILABLE"
    cmds = (await c.get("/v1/twin/commands", headers=TWIN)).json()
    types = [x["type"] for x in cmds]
    assert "CLEAR_LEAK" in types and "RESET_PIPE_NORMAL" in types
    assert all(x["pipe_code"] == "P05" for x in cmds if x["type"] in ("CLEAR_LEAK", "RESET_PIPE_NORMAL"))
    assert any(x["type"] == "SET_VALVE_STATE" and x["params"].get("valve_code") for x in cmds)
    for x in cmds:
        assert (await c.post(f"/v1/twin/commands/{x['id']}/ack", json={"status": "APPLIED"}, headers=TWIN)).status_code == 200
    assert (await c.get("/v1/twin/commands", headers=TWIN)).json() == []
    assert (await q(env, "select count(*) n from twin_commands where status <> 'APPLIED'"))[0]["n"] == 0
    # valves are restored only after approval, one confirmation per valve
    for v in obj["advisory"]["valves"]:
        r = await c.post(f"/v1/isolation-advisories/{adv_id}/valves/{v['id']}/confirm-restored", headers=bearer(OPER))
        assert r.status_code == 200
    assert r.json()["status"] == "RESTORED"
    assert (await q(env, "select count(*) n from valves where state <> 'OPEN'"))[0]["n"] == 0

    # ---------------- AT11: device silent for > 3 report intervals -> OFFLINE + notification, never a leak
    from app.db import session_scope
    from app.workers import offline

    await q(env, "select 1")
    async with session_scope() as s:
        await s.execute(text("update devices set last_seen_at = now() - interval '5 minutes' where device_uid='JR-ESP32-0001'"))
    await offline.sweep()
    assert (await q(env, "select status::text s from devices where device_uid='JR-ESP32-0001'"))[0]["s"] == "OFFLINE"
    assert (await q(env, "select count(*) n from notifications where type='DEVICE_OFFLINE'"))[0]["n"] == 2
    assert (await q(env, "select count(*) n from leak_events where pipe_id=(select id from pipe_segments where code='P17')"))[0]["n"] == 0

    # ---------------- AT12: a real leak on the hardware pipe; the twin mirrors it
    base = NOW() - timedelta(minutes=2)
    for i in range(14):                                                    # normal first (data resumes -> device ONLINE again)
        await post_hw(env, hw_msg(10 + i, base + timedelta(seconds=5 * i), boot="b1b1b1b1"))
        out = await evaluate("P17", "HARDWARE")
    assert (await q(env, "select status::text s from devices where device_uid='JR-ESP32-0001'"))[0]["s"] == "ONLINE"
    assert (await q(env, "select count(*) n from leak_events where pipe_id=(select id from pipe_segments where code='P17')"))[0]["n"] == 0
    out = None
    for i in range(14, 36):
        await post_hw(env, hw_msg(10 + i, base + timedelta(seconds=min(5 * i, 119)) if i < 24 else NOW(), fi=80.0, fo=61.6, boot="b1b1b1b1"))
        out = await evaluate("P17", "HARDWARE")
        if out and out["action"] == "LEAK_CONFIRMED":
            break
    assert out and out["action"] == "LEAK_CONFIRMED", out
    ev2 = (await q(env, "select * from v_leak_events_enriched where pipe_code='P17'"))[0]
    assert ev2["source"] == "HARDWARE" and ev2["is_simulated"] is False and ev2["severity"] in ("MODERATE", "MAJOR")
    types = {r["t"] for r in await q(env, "select type::text t from twin_commands where leak_event_id=:e", e=ev2["id"])}
    assert types == {"INJECT_LEAK", "SET_PIPE_STATE"}                                              # twin mirrors reality
    inj = (await q(env, "select params from twin_commands where type='INJECT_LEAK' and leak_event_id=:e", e=ev2["id"]))[0]["params"]
    assert inj["leak_rate_lpm"] == pytest.approx(18.4, abs=2.0) and inj["position_fraction"] == 0.5

    # ---------------- AT13: severity rises while the event is open -> escalate everything once
    sev_before = ev2["severity"]
    n_before = (await q(env, "select count(*) n from notifications where type='SEVERITY_ESCALATED'"))[0]["n"]
    for i in range(36, 60):
        await post_hw(env, hw_msg(10 + i, NOW(), fi=80.0, fo=20.0, pi=120.0, po=100.0, boot="b1b1b1b1"))
        out = await evaluate("P17", "HARDWARE")
        if out and out["action"] == "ESCALATED":
            break
    assert out and out["action"] == "ESCALATED", out
    ev3 = (await q(env, "select * from v_leak_events_enriched where pipe_code='P17'"))[0]
    assert ev3["severity"] == "CRITICAL" and ev3["severity"] != sev_before and ev3["priority"] == "P1"
    assert ev3["advisory_urgency"] == "IMMEDIATE"
    wo2 = (await q(env, "select priority::text p, sla_due_at - now() as left_ from work_orders where id=:i", i=ev3["work_order_id"]))[0]
    assert wo2["p"] == "P1" and wo2["left_"] < timedelta(minutes=61)
    n_after = (await q(env, "select count(*) n from notifications where type='SEVERITY_ESCALATED'"))[0]["n"]
    assert n_after - n_before == 2                                                                 # one per staff user, once
    for _ in range(3):                                                                              # no further escalation
        await post_hw(env, hw_msg(500 + _, NOW(), fi=80.0, fo=20.0, pi=120.0, po=100.0, boot="b1b1b1b1"))
        out = await evaluate("P17", "HARDWARE")
    assert (await q(env, "select count(*) n from notifications where type='SEVERITY_ESCALATED'"))[0]["n"] == n_after

    # ---------------- false alarm closes the event, cancels the work order and clears the twin
    r = await c.post(f"/v1/leak-events/{ev3['id']}/false-alarm", json={"reason": "Sensor calibration test"}, headers=bearer(OPER))
    assert r.status_code == 200
    assert (await q(env, "select state::text s from pipe_segments where code='P17'"))[0]["s"] == "NORMAL"
    assert (await q(env, "select status::text s from work_orders where id=:i", i=ev3["work_order_id"]))[0]["s"] == "CANCELLED"
    assert (await q(env, "select count(*) n from twin_commands where type='CLEAR_LEAK' and leak_event_id=:e", e=ev3["id"]))[0]["n"] == 1

    # ---------------- reads: list, pagination, summary, signals, notifications, auth failures
    page = (await c.get("/v1/leak-events?limit=1", headers=bearer(OPER))).json()
    assert len(page["items"]) == 1 and page["next_cursor"]
    page2 = (await c.get(f"/v1/leak-events?limit=1&cursor={page['next_cursor']}", headers=bearer(OPER))).json()
    assert page2["items"][0]["id"] != page["items"][0]["id"] and page2["next_cursor"] is None
    assert (await c.get("/v1/leak-events?source=TWIN", headers=bearer(OPER))).json()["items"][0]["is_simulated"] is True
    s = (await c.get("/v1/dashboard/summary", headers=bearer(ADMIN))).json()
    assert s["devices_online"] == 1 and s["repairs_closed_30d"] == 1
    pid = (await q(env, "select id from pipe_segments where code='P05'"))[0]["id"]
    sig = (await c.get(f"/v1/pipes/{pid}/signals?bucket=10s&from={iso(datetime(2026, 10, 15, tzinfo=timezone.utc))}"
                       f"&to={iso(datetime(2026, 10, 16, tzinfo=timezone.utc))}", headers=bearer(OPER))).json()
    assert sig["source"] == "TWIN" and sig["is_simulated"] is True and len(sig["points"]) > 5
    assert (await c.get("/v1/me", headers=bearer(ENG1))).json()["role"] == "ENGINEER"
    notes = (await c.get("/v1/notifications", headers=bearer(ENG1))).json()["items"]
    assert {n["type"] for n in notes} >= {"WO_ASSIGNED", "WO_REJECTED", "WO_APPROVED"}
    assert (await c.post(f"/v1/notifications/{notes[0]['id']}/read", headers=bearer(ENG1))).status_code == 200
    assert (await c.get("/v1/me")).status_code == 401
    assert (await c.get("/v1/leak-events", headers={"Authorization": "Bearer junk"})).status_code == 401
    assert (await c.get("/v1/twin/network", headers={"Authorization": "Bearer nope"})).status_code == 401
    assert (await c.get(f"/v1/leak-events/{uuid.uuid4()}", headers=bearer(OPER))).status_code == 404
    # idempotency key replays the first response
    k = {"Idempotency-Key": "abc-123", **bearer(ENG1)}
    r1 = await c.put("/v1/me/engineer/status", json={"status": "OFF_DUTY"}, headers=k)
    r2 = await c.put("/v1/me/engineer/status", json={"status": "OFF_DUTY"}, headers=k)
    assert r1.status_code == 200 and r2.headers.get("idempotent-replay") == "true"
