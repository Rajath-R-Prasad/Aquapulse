"""Milestone M2: post the section 6.1 payload as an ESP32 would.

  python scripts/post_hw_reading.py --url http://localhost:8000 --token <device_token> [--leak 18.4] [--count 20]
"""
import argparse
import secrets
import time
from datetime import datetime, timezone

import httpx


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="http://localhost:8000")
    ap.add_argument("--token", required=True)
    ap.add_argument("--device", default="JR-ESP32-0001")
    ap.add_argument("--leak", type=float, default=0.0, help="L/min lost between inlet and outlet")
    ap.add_argument("--count", type=int, default=1)
    ap.add_argument("--interval", type=float, default=5.0)
    a = ap.parse_args()
    boot = secrets.token_hex(4)
    for seq in range(1, a.count + 1):
        fin = 79.6
        msg = {"schema": "AquaPulse.hw.reading/1.0", "device_uid": a.device, "boot_id": boot, "seq": seq,
               "ts": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"), "fw": "1.2.0",
               "readings": [{"sensor": "FLOW_IN", "value": fin, "unit": "L/min", "quality": "GOOD"},
                            {"sensor": "FLOW_OUT", "value": fin - 0.4 - a.leak, "unit": "L/min", "quality": "GOOD"},
                            {"sensor": "PRESSURE_IN", "value": 182.0 - a.leak, "unit": "kPa", "quality": "GOOD"},
                            {"sensor": "PRESSURE_OUT", "value": 151.5 if a.leak else 181.0, "unit": "kPa", "quality": "GOOD"}],
               "health": {"rssi_dbm": -61, "uptime_s": seq * 5, "free_heap_b": 182000}}
        r = httpx.post(f"{a.url}/v1/ingest/hardware/readings", json=msg, headers={"Authorization": f"Bearer {a.token}"}, timeout=10)
        print(seq, r.status_code, r.json())
        if seq < a.count:
            time.sleep(a.interval)


if __name__ == "__main__":
    main()
