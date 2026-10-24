"""Create the demo users (1 ADMIN, 1 OPERATOR, 2 ENGINEERs) in Supabase Auth + profiles/engineers (section 7.6).

  python -m scripts.seed_users            # run from the backend/ folder, after migrations 001 and 002
  python -m scripts.seed_users --reset-passwords
Passwords are printed once. Change them for anything other than a demo.
"""
import argparse
import asyncio
import secrets
from typing import Any

from sqlalchemy import text

from app.config import settings
from app.db import SessionLocal

USERS = [("admin@AquaPulse.test", "Demo Admin", "ADMIN", None), ("operator@AquaPulse.test", "Demo Operator", "OPERATOR", None),
         ("engineer1@AquaPulse.test", "Ravi Kumar", "ENGINEER", "ENG-001"), ("engineer2@AquaPulse.test", "Anita Rao", "ENGINEER", "ENG-002")]


def find_existing_users(admin: Any) -> dict[str, Any]:
    existing = {}
    page, page_size = 1, 100
    while True:
        users = admin.list_users(page=page, per_page=page_size)
        for user in users:
            if user.email:
                existing[user.email.casefold()] = user
        if len(users) < page_size:
            return existing
        page += 1


async def main(reset_passwords: bool = False) -> None:
    from supabase import create_client

    admin = create_client(settings.supabase_url, settings.supabase_service_role_key).auth.admin
    existing_users = find_existing_users(admin)
    async with SessionLocal() as s:
        async with s.begin():
            for email, name, role, code in USERS:
                user = existing_users.get(email.casefold())
                password = None
                if user is None:
                    password = secrets.token_urlsafe(12)
                    user = admin.create_user(
                        {"email": email, "password": password, "email_confirm": True}
                    ).user
                    existing_users[email.casefold()] = user
                elif reset_passwords:
                    password = secrets.token_urlsafe(12)
                    user = admin.update_user_by_id(
                        user.id, {"password": password}
                    ).user

                await s.execute(text("insert into profiles (id, full_name, role) values (:i, :n, CAST(:r AS user_role)) "
                                     "on conflict (id) do nothing"), {"i": user.id, "n": name, "r": role})
                if code:
                    await s.execute(text("insert into engineers (profile_id, employee_code, status, skills, max_active_jobs) values "
                                         "(:i, :c, 'AVAILABLE', '{PIPE_REPAIR,VALVE}', 1) on conflict do nothing"),
                                    {"i": user.id, "c": code})
                if password:
                    print(f"{role:9} {email:28} password: {password}")
                else:
                    print(f"{role:9} {email:28} already exists; password unchanged")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create or repair AquaPulse demo users.")
    parser.add_argument(
        "--reset-passwords",
        action="store_true",
        help="Generate and set new passwords for all existing demo users.",
    )
    args = parser.parse_args()
    asyncio.run(main(reset_passwords=args.reset_passwords))
