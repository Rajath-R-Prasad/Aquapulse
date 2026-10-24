"""Public engineer self-registration. New accounts are always assigned ENGINEER."""
from __future__ import annotations

import asyncio
import hmac
import logging
from urllib.parse import urlparse
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from supabase_auth.errors import AuthApiError

from app.config import settings
from app.db import TransactionalRoute, get_session
from app.schemas.auth import EngineerSignupBody, OperatorSignupBody
from app.schemas.common import ProblemException, conflict

router = APIRouter(prefix="/v1/auth", tags=["Authentication"], route_class=TransactionalRoute)
log = logging.getLogger("AquaPulse.auth")
DEMO_OPERATOR_EMAIL = "operator@aquapulse.test"


def _supabase_project_ref(url: str) -> str | None:
    host = urlparse(url).hostname or ""
    suffix = ".supabase.co"
    return host[:-len(suffix)] if host.endswith(suffix) else None


async def _operator_signup_state(s: AsyncSession) -> tuple[bool, bool]:
    claimed = await s.execute(
        text("select value from app_settings where key = 'operator_signup_claimed'")
    )
    claim_recorded = bool(claimed.scalar_one_or_none())
    operators = await s.execute(
        text("""select u.email
                from profiles p join auth.users u on u.id = p.id
                where p.role = 'OPERATOR' and p.is_active""")
    )
    active_operator_exists = any(
        (email or "").casefold() != DEMO_OPERATOR_EMAIL for email in operators.scalars().all()
    )
    return claim_recorded, active_operator_exists


@router.get("/operator-signup-status", summary="Check one-time operator setup state")
async def operator_signup_status(s: AsyncSession = Depends(get_session)):
    claim_recorded, active_operator_exists = await _operator_signup_state(s)
    return {
        "supabase_project_ref": _supabase_project_ref(settings.supabase_url),
        "claim_recorded": claim_recorded,
        "active_operator_exists": active_operator_exists,
    }


@router.post("/signup", status_code=201, summary="Create an engineer account")
async def signup_engineer(body: EngineerSignupBody, s: AsyncSession = Depends(get_session)):
    from supabase import create_client

    client = create_client(settings.supabase_url, settings.supabase_service_role_key)
    try:
        user = await asyncio.to_thread(
            client.auth.admin.create_user,
            {
                "email": body.email,
                "password": body.password,
                "email_confirm": True,
            },
        )
    except AuthApiError as exc:
        if exc.code == "email_exists":
            raise conflict("An account with this email already exists", "email-already-registered") from None
        raise ProblemException(400, "signup-rejected", "Could not create account", exc.message) from None

    user_id = UUID(str(user.user.id))
    employee_code = f"ENG-{user_id.hex[:8].upper()}"
    try:
        await s.execute(
            text("insert into profiles (id, full_name, role, phone) "
                 "values (:id, :name, 'ENGINEER', :phone)"),
            {"id": user_id, "name": body.full_name, "phone": body.phone},
        )
        await s.execute(
            text("insert into engineers (profile_id, employee_code, status, skills, max_active_jobs) "
                 "values (:id, :code, 'AVAILABLE', '{PIPE_REPAIR,VALVE}', 1)"),
            {"id": user_id, "code": employee_code},
        )
    except Exception:
        try:
            await asyncio.to_thread(client.auth.admin.delete_user, str(user_id))
        except Exception:
            log.exception("Could not remove Auth user after engineer profile creation failed")
        raise

    return {"id": str(user_id), "full_name": body.full_name, "role": "ENGINEER",
            "employee_code": employee_code}


@router.post("/operator-signup", status_code=201, summary="Claim the one-time operator account")
async def signup_operator(body: OperatorSignupBody, s: AsyncSession = Depends(get_session)):
    setup_code = settings.operator_signup_code.strip()
    if not setup_code:
        raise ProblemException(
            503,
            "operator-signup-disabled",
            "Operator signup is not configured",
            "Set OPERATOR_SIGNUP_CODE in backend/.env and restart the backend",
        )
    if not hmac.compare_digest(body.setup_code, setup_code):
        raise ProblemException(403, "invalid-setup-code", "Setup code invalid", "Check the one-time operator setup code")

    from supabase import create_client

    client = create_client(settings.supabase_url, settings.supabase_service_role_key)
    await s.execute(text("select pg_advisory_xact_lock(7042010123)"))
    claimed = await s.execute(
        text("select value from app_settings where key = 'operator_signup_claimed' for update")
    )
    if claimed.scalar_one_or_none():
        raise conflict("The one-time operator account has already been created", "operator-already-created")

    operators = await s.execute(
        text("""select p.id, u.email
                from profiles p join auth.users u on u.id = p.id
                where p.role = 'OPERATOR' and p.is_active
                for update of p""")
    )
    current_operators = operators.mappings().all()
    non_demo_operators = [
        row for row in current_operators
        if (row["email"] or "").casefold() != DEMO_OPERATOR_EMAIL
    ]
    if non_demo_operators:
        raise conflict("An active operator account already exists", "operator-already-created")

    try:
        user = await asyncio.to_thread(
            client.auth.admin.create_user,
            {"email": body.email, "password": body.password, "email_confirm": True},
        )
    except AuthApiError as exc:
        if exc.code == "email_exists":
            raise conflict("An account with this email already exists", "email-already-registered") from None
        raise ProblemException(400, "signup-rejected", "Could not create account", exc.message) from None

    user_id = UUID(str(user.user.id))
    try:
        await s.execute(
            text("update profiles set is_active = false where role = 'OPERATOR' and id in "
                 "(select id from auth.users where lower(email) = 'operator@aquapulse.test')")
        )
        await s.execute(
            text("insert into profiles (id, full_name, role) values (:id, :name, 'OPERATOR')"),
            {"id": user_id, "name": body.full_name},
        )
        await s.execute(
            text("insert into app_settings (key, value) values ('operator_signup_claimed', 'true'::jsonb)")
        )
    except Exception:
        try:
            await asyncio.to_thread(client.auth.admin.delete_user, str(user_id))
        except Exception:
            log.exception("Could not remove Auth user after operator profile creation failed")
        raise

    return {"id": str(user_id), "full_name": body.full_name, "role": "OPERATOR"}
