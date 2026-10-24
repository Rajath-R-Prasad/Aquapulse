"""Network GeoJSON for dashboards and device administration (ADMIN)."""
from __future__ import annotations

import secrets
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import TransactionalRoute, dumps, fetchall, fetchone, get_session
from app.schemas.common import conflict, not_found
from app.schemas.events import DeviceCreate, DevicePatch
from app.security import CurrentUser, admin_user, any_user, hash_token, staff_user
from app.services import twin_sync
from app.services.state import log_event

router = APIRouter(tags=["Network and devices"], route_class=TransactionalRoute)


@router.get("/v1/network", summary="Pipes, nodes and valves as GeoJSON with current state")
async def network(_: CurrentUser = Depends(any_user), s: AsyncSession = Depends(get_session)):
    return await twin_sync.network_geojson(s)


@router.get("/v1/devices", summary="Registered devices (never exposes token hashes)")
async def list_devices(_: CurrentUser = Depends(staff_user), s: AsyncSession = Depends(get_session)):
    rows = await fetchall(s, """select d.id, d.device_uid, p.code as pipe_code, d.status::text as status, d.firmware_version,
                                d.report_interval_s, d.last_seen_at from devices d join pipe_segments p on p.id = d.pipe_id
                                order by d.device_uid""")
    return {"items": rows}


@router.post("/v1/devices", status_code=201, summary="Provision a device; the token is returned once")
async def create_device(body: DeviceCreate, user: CurrentUser = Depends(admin_user), s: AsyncSession = Depends(get_session)):
    token = secrets.token_hex(32)                      # 32 random bytes, hex
    if await fetchone(s, "select 1 as x from devices where device_uid = :u", {"u": body.device_uid}):
        raise conflict("A device with this device_uid already exists", "device-exists")
    row = await fetchone(s, "insert into devices (device_uid, pipe_id, token_hash, report_interval_s, calibration) "
                            "values (:u, :p, :h, :r, CAST(:c AS jsonb)) returning id",
                         {"u": body.device_uid, "p": body.pipe_id, "h": hash_token(token), "r": body.report_interval_s,
                          "c": dumps(body.calibration)})
    await log_event(s, "DEVICE", row["id"], "PROVISIONED", None, "PROVISIONED", "USER", user.id)
    return {"id": row["id"], "device_uid": body.device_uid, "token": token}


@router.patch("/v1/devices/{device_id}", summary="Update a device, retire it, or rotate its token (ADMIN)")
async def patch_device(device_id: UUID, body: DevicePatch, user: CurrentUser = Depends(admin_user),
                       s: AsyncSession = Depends(get_session)):
    cur = await fetchone(s, "select id, status::text as status from devices where id = :i for update", {"i": device_id})
    if not cur:
        raise not_found("device")
    sets, params = [], {"i": device_id}
    if body.status:
        sets.append("status = CAST(:st AS device_status)"); params["st"] = body.status
    if body.pipe_id:
        sets.append("pipe_id = :p"); params["p"] = body.pipe_id
    if body.report_interval_s:
        sets.append("report_interval_s = :r"); params["r"] = body.report_interval_s
    if body.calibration is not None:
        sets.append("calibration = CAST(:c AS jsonb)"); params["c"] = dumps(body.calibration)
    token = None
    if body.rotate_token:
        token = secrets.token_hex(32)
        sets.append("token_hash = :h"); params["h"] = hash_token(token)
    if sets:
        await s.execute(text(f"update devices set {', '.join(sets)} where id = :i"), params)
        await log_event(s, "DEVICE", device_id, "UPDATED", cur["status"], body.status, "USER", user.id,
                        {"rotated_token": bool(token)})
    out = {"id": device_id, "updated": bool(sets)}
    if token:
        out["token"] = token
    return out
