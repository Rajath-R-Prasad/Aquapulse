# AquaPulse Backend (FastAPI + Supabase)

Implementation of *AquaPulse — Backend Technical Implementation Document v1.0*. Layout follows section 11.1.

```
backend/
  app/
    main.py config.py db.py security.py
    schemas/   hardware.py twin.py events.py workorders.py common.py
    routers/   ingest_hardware.py ingest_twin.py events.py workorders.py advisories.py
               engineers.py network.py dashboard.py me.py
    services/  normalize.py features.py detector.py severity.py isolation.py dispatch.py
               evidence.py state.py notify.py twin_sync.py
    workers/   evaluator.py offline.py renotify.py timeouts.py baselines.py retention.py
    ml/        registry.py train_anomaly.py train_severity.py dataset.py
  migrations/  001_init.sql  002_seed_dma01.sql
  scripts/     seed_users.py provision_device.py post_hw_reading.py mock_twin.py
  tests/       test_units.py test_acceptance.py
```

## Setup
1. Supabase project -> SQL editor: run `migrations/001_init.sql`, then `migrations/002_seed_dma01.sql`
   (001 also creates the private buckets `repair-evidence` and `ml-models`).
   For an existing deployment, apply new numbered migrations in order; current dispatch behavior is in
   `migrations/003_dispatch_without_fresh_location.sql`.
2. `cp .env.example .env` and fill it in (Appendix A). `DATABASE_URL` = the Supabase **Transaction pooler**
   connection string from the project's Connect dialog (`postgresql+asyncpg://...`, normally port 6543; add
   `?ssl=require` if needed). Do not use the Session pooler string for a long-running app process: its per-user
   limit is easily exhausted by development restarts. The DB user must bypass RLS (the default `postgres` user does).
   The backend limits its SQLAlchemy pool to five connections; run one backend process.
3. `pip install -r requirements.txt`
4. Demo users and the ESP32 device (need the service-role key):
   `python -m scripts.seed_users` and `python -m scripts.provision_device --uid JR-ESP32-0001 --pipe P17`
5. Run: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1`
   OpenAPI: `/openapi.json` (generate the React / Flutter clients from it).

Mobile engineers can self-register with `POST /v1/auth/signup`; the backend creates a confirmed Supabase Auth
account and an `ENGINEER` profile. Keep the backend on the hackathon network; this public signup endpoint must not
be exposed to the public internet without abuse controls.

### One-time operator account setup

Before starting the backend, add a private `OPERATOR_SIGNUP_CODE` value to `backend/.env`. Generate a strong value
locally (for example, with `python -c "import secrets; print(secrets.token_urlsafe(24))"`); do not commit it or put
it in the web app's environment. Restart the backend, open the operator web app's `/login` page, select **First-time
setup? Create operator account**, and submit your name, email, password, and setup code once. The backend creates a
confirmed Supabase Auth account with the `OPERATOR` role and deactivates the seeded demo operator profile. The web
app checks that it and the backend point to the same Supabase project, then signs in with the new credentials after
signup. For every later visit, use **Sign in** with the email and password you created; do not reseed demo users.
Signup is permanently closed after the first successful claim. The public `GET /v1/auth/operator-signup-status`
endpoint reports the backend project reference and whether an operator claim/profile already exists; it never
returns credentials or account email addresses.

Keep the backend and the setup code on the trusted hackathon network. The configured code stays server-side; the
browser sends the code entered on the signup form only for the initial account claim. It is not needed for later logins.

The operator web app's root route is a public, read-only hackathon dashboard. It reads only the digital-twin network,
simulated readings, and open twin events from `GET /v1/demo/dashboard`. Mutations and the rest of the API still require
Supabase authentication. This endpoint exposes demo pipe locations and telemetry; do not expose it to the public
internet unless that data is intended to be public.

**Run exactly one process.** The workers (section 10.8) run as asyncio tasks inside the app, and the detector's
consecutive-window counters, the 1 msg/s rate limiter and the Idempotency-Key cache live in memory.

## Try it without hardware
- `python scripts/mock_twin.py --token $TWIN_SERVICE_TOKEN --leak P05:12` (Tunnel B; event within about a minute)
- `python scripts/post_hw_reading.py --token <device_token> --count 40 --leak 18.4` (Tunnel A, pipe P17)

For an interactive React + Tailwind twin control room that uses the same twin run and snapshot endpoints, see
[`../digital-twin/README.md`](../digital-twin/README.md). Its local Node API keeps the twin service token out of the browser.

## Tests
- `pytest tests/test_units.py` (no database needed)
- `TEST_DATABASE_URL=postgresql+asyncpg://... pytest` also runs `test_acceptance.py`: one scenario covering AT01-AT13
  (plus false alarm, pagination, idempotency, auth failures) against a real PostgreSQL/PostGIS database with
  migrations 001+002. It **deletes operational data**; use a scratch database. On plain Postgres (not Supabase) create
  stubs first: `auth.users`, `auth.uid()`, roles `authenticated`/`anon`, publication `supabase_realtime`, `storage.buckets`.

## ML
Without active models the backend uses a heuristic fallback (z-score of the flow-loss residual; leak rate = residual),
so the whole loop works from day one. Train real models from twin runs (9.5):
`python -m app.ml.train_anomaly --run-id <normal_run> --holdout-pipes P03 --activate`
`python -m app.ml.train_severity --run-id <campaign_run> --holdout-pipes P03 --activate`
Artifacts go to the `ml-models` bucket and are hot-reloaded within 60 s.

## Interpretation notes (where the document is silent or inconsistent)
- **Commit before response.** Every router uses `TransactionalRoute` (db.py): the transaction commits right after the
  endpoint returns, before the response is sent, so Supabase reads after an API call always see the change.
- **Evidence paths.** `storage_path` is `repair-evidence/<wo_id>/<uuid>.jpg` (as in 6.5). `upload-url` also returns `path`
  (`<wo_id>/<uuid>.jpg`) for `uploadToSignedUrl`, which expects the path inside the bucket.
- **Twin commands** are delivered at least once: `PENDING`, plus `DELIVERED` ones not acknowledged within 30 s. The valve
  code is added to `params` for `SET_VALVE_STATE`. `STOP` on `/runs` takes an optional `run_id`.
- **Dispatch GPS.** A recent engineer location increases proximity ranking, but missing or older-than-15-minute GPS no
  longer removes an otherwise available engineer from the candidate list. Use the app to collect current location
  before dispatch when travel-distance ranking is important.
- **Baseline slots** use `Asia/Kolkata`, `dow` 0 = Sunday (PostgreSQL `extract(dow)`); a baseline needs at least 30 samples,
  otherwise mean 0 / std 0.5 L/min is used (9.1). Without a pressure baseline the pressure before the last 60 s is the reference.
- **WARNING** is raised at `anomaly_score >= warn_score` while the leak is unconfirmed (table in 8.1) and clears after
  `warn_clear_windows` (default 6) evaluations below the threshold.
- **Cancel** (`/work-orders/{id}/cancel`) cancels the work order and closes the event as FALSE_ALARM (otherwise the event
  would be stuck without a work order). Declines and timeouts notify staff with type `WO_REJECTED` and `payload.kind`.
- **Post-repair check** (HARDWARE) is refreshed every 60 s while a work order is SUBMITTED and recomputed on approval.
- **Seed network.** The DMA-01 design drawing was not part of the document, so `002_seed_dma01.sql` builds a 3x4 junction
  grid + reservoir with P01-P18 and valves at both ends of every pipe; P17 is HARDWARE. Replace with your real layout.
  Because the grid is looped, closing a pipe's two valves usually leaves 0 connections without supply.
- Extra endpoints (additive): `GET /v1/engineers`, `GET/POST /v1/devices`, `PATCH /v1/devices/{id}` (retire / rotate token, section 13).

## Verified / not verified
Verified against PostgreSQL 16 + PostGIS 3.4: migrations, the main path of every endpoint, AT01-AT13, the live evaluator
worker with a mock twin, ML training + registry loading. **Not exercised:** Supabase Storage signed URLs, Supabase JWKS
(RS256/ES256; HS256 is tested), FCM push, Realtime, and the real ESP32 / WNTR twin.
