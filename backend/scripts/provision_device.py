"""Provision an ESP32 device and print its bearer token once (token_hash = SHA-256 is stored, never the token).

  python -m scripts.provision_device --uid JR-ESP32-0001 --pipe P17
"""
import argparse
import asyncio
import secrets

from sqlalchemy import text

from app.db import SessionLocal
from app.security import hash_token


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--uid", default="JR-ESP32-0001")
    ap.add_argument("--pipe", default="P17")
    ap.add_argument("--interval", type=int, default=5)
    a = ap.parse_args()
    token = secrets.token_hex(32)
    async with SessionLocal() as s:
        async with s.begin():
            pid = (await s.execute(text("select id from pipe_segments where code = :c"), {"c": a.pipe})).scalar_one()
            await s.execute(text("insert into devices (device_uid, pipe_id, token_hash, report_interval_s) values (:u, :p, :h, :r)"),
                            {"u": a.uid, "p": pid, "h": hash_token(token), "r": a.interval})
            await s.execute(text("update pipe_segments set monitoring = 'HARDWARE' where id = :p"), {"p": pid})
    print(f"device {a.uid} -> pipe {a.pipe}\ntoken (store it in the firmware, shown once): {token}")


if __name__ == "__main__":
    asyncio.run(main())
