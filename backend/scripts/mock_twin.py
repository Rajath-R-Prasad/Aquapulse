"""Minimal stand-in for the digital twin (milestones M3/M4). Pulls the network, starts a run, posts a snapshot per
step for every SIMULATED pipe, polls commands every 2 s and applies INJECT_LEAK / CLEAR_LEAK / RESET_PIPE_NORMAL.
It is NOT hydraulic: flow_out = flow_in - leak. Replace it by the real WNTR twin.

  python scripts/mock_twin.py --url http://localhost:8000 --token <TWIN_SERVICE_TOKEN> [--leak P05:12]
"""
import argparse
import random
import time
from datetime import datetime, timedelta, timezone

import httpx


def response_json(response: httpx.Response, endpoint: str, expected_type: type):
    try:
        response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        raise RuntimeError(
            f"{endpoint} returned HTTP {response.status_code}: {response.text[:500]}"
        ) from exc
    try:
        data = response.json()
    except ValueError as exc:
        raise RuntimeError(f"{endpoint} returned invalid JSON") from exc
    if not isinstance(data, expected_type):
        raise RuntimeError(
            f"{endpoint} returned {type(data).__name__}, expected "
            f"{expected_type.__name__}: {str(data)[:500]}"
        )
    return data


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="http://localhost:8000")
    ap.add_argument("--token", required=True)
    ap.add_argument("--step", type=float, default=5.0)
    ap.add_argument("--leak", default="", help="PIPE:LPM leak injected from the start, e.g. P05:12")
    a = ap.parse_args()
    h = {"Authorization": f"Bearer {a.token}"}
    c = httpx.Client(base_url=a.url, headers=h, timeout=15)
    net = response_json(c.get("/v1/twin/network"), "GET /v1/twin/network", dict)
    if not isinstance(net.get("features"), list):
        raise RuntimeError("GET /v1/twin/network did not return GeoJSON features")
    pipes = {}
    for feature in net["features"]:
        properties = feature.get("properties") if isinstance(feature, dict) else None
        if not isinstance(properties, dict):
            raise RuntimeError("GET /v1/twin/network returned a feature without properties")
        if properties.get("feature_type") == "PIPE" and properties.get("monitoring") == "SIMULATED":
            if not properties.get("code") or "design_flow_lpm" not in properties:
                raise RuntimeError("GET /v1/twin/network returned a simulated pipe without required fields")
            pipes[properties["code"]] = properties
    if not pipes:
        raise RuntimeError("GET /v1/twin/network contains no SIMULATED pipes")
    leaks: dict[str, float] = {}
    if a.leak:
        try:
            code, lpm = a.leak.split(":", maxsplit=1)
        except ValueError as exc:
            raise SystemExit("--leak must use PIPE:LPM format, for example P05:12") from exc
        if code not in pipes:
            raise SystemExit(f"Unknown pipe {code!r}; choose a simulated pipe from the network")
        try:
            leak_rate = float(lpm)
        except ValueError as exc:
            raise SystemExit("--leak rate must be a number in L/min") from exc
        if leak_rate <= 0:
            raise SystemExit("--leak rate must be greater than zero")
        leaks[code] = leak_rate
    run_data = response_json(
        c.post("/v1/ingest/twin/runs", json={"action": "START", "name": "mock-twin", "network_version": "dma-01"}),
        "POST /v1/ingest/twin/runs",
        dict,
    )
    if "run_id" not in run_data:
        raise RuntimeError("POST /v1/ingest/twin/runs response did not contain run_id")
    run = run_data["run_id"]
    sim, last_poll = datetime.now(timezone.utc), 0.0
    print("run", run)
    try:
        while True:
            body = []
            for code, p in pipes.items():
                q = max(1.0, float(p["design_flow_lpm"]) * 0.6) + random.gauss(0, 0.1)
                lk = leaks.get(code, 0.0)
                body.append({"pipe_code": code, "flow_in": round(q, 2), "flow_out": round(q - 0.1 - lk + random.gauss(0, 0.1), 2),
                             "pressure_in": round(190 + random.gauss(0, 0.2) - lk * 0.5, 2),
                             "pressure_out": round(188 + random.gauss(0, 0.2) - lk * 0.5, 2), "velocity": 0.3, "injected_leak": lk})
            response_json(
                c.post("/v1/ingest/twin/snapshots", json={"schema": "AquaPulse.twin.snapshot/1.0", "run_id": run, "sim_time": sim.isoformat().replace("+00:00", "Z"),
                                                          "units": {"flow": "L/min", "pressure": "kPa", "velocity": "m/s"}, "pipes": body}),
                "POST /v1/ingest/twin/snapshots",
                dict,
            )
            sim += timedelta(seconds=a.step)
            t_end = time.time() + a.step
            while time.time() < t_end:
                if time.time() - last_poll >= 2:
                    last_poll = time.time()
                    commands = response_json(
                        c.get("/v1/twin/commands", params={"status": "PENDING"}),
                        "GET /v1/twin/commands",
                        list,
                    )
                    for cmd in commands:
                        if not isinstance(cmd, dict):
                            raise RuntimeError(
                                "GET /v1/twin/commands returned a non-object item: "
                                f"{str(cmd)[:500]}"
                            )
                        code = cmd["pipe_code"]
                        if cmd["type"] == "INJECT_LEAK":
                            leaks[code] = float(cmd["params"]["leak_rate_lpm"])
                        elif cmd["type"] in ("CLEAR_LEAK", "RESET_PIPE_NORMAL"):
                            leaks.pop(code, None)
                        print("applied", cmd["type"], code, cmd["params"])
                        response_json(
                            c.post(f"/v1/twin/commands/{cmd['id']}/ack", json={"status": "APPLIED"}),
                            "POST /v1/twin/commands/{id}/ack",
                            dict,
                        )
                time.sleep(0.25)
    except KeyboardInterrupt:
        c.post("/v1/ingest/twin/runs", json={"action": "STOP", "run_id": run}).raise_for_status()


if __name__ == "__main__":
    main()
