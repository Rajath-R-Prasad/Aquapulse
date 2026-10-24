"""Test environment. Unit tests need nothing. Integration tests need a database with migrations 001+002 applied:
   TEST_DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/jr pytest
(On Supabase use a throw-away project: the integration test truncates operational tables.)"""
import os

os.environ.setdefault("ENABLE_WORKERS", "false")
os.environ.setdefault("SUPABASE_JWT_SECRET", "test-secret-test-secret-test-secret-0123456789")
os.environ.setdefault("TWIN_SERVICE_TOKEN", "twin-test-token")
if os.environ.get("TEST_DATABASE_URL"):
    os.environ["DATABASE_URL"] = os.environ["TEST_DATABASE_URL"]
