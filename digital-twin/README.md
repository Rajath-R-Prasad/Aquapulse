# AquaPulse Digital Twin

This standalone React + Tailwind interface lets you select a simulated pipe, inject or clear one or more leak scenarios, and inspect the generated telemetry. A small Node API runs only on `127.0.0.1`, keeps `TWIN_SERVICE_TOKEN` on the server side, and posts five-second snapshots to the existing FastAPI twin ingestion endpoint. The existing backend evaluator and database remain the source of truth; the public operator dashboard reads the resulting pipe states, readings, and confirmed events.

The simulator deliberately does not poll `/v1/twin/commands`. That command endpoint was returning HTTP 500 in the current backend process; this UI's leak controls do not depend on it. It uses the same run and snapshot endpoints as `backend/scripts/mock_twin.py`.

## Start it on Windows

Run the Vite UI, local twin API, and FastAPI backend with one command from this folder:

```bash
cd /d/AquaPulse/digital-twin
npm install
npm run dev
```

Open <http://127.0.0.1:5174>. `npm run dev` reads `TWIN_SERVICE_TOKEN` from `backend/.env`, checks for an existing FastAPI backend, starts one from `backend/.venv` when needed, then starts the local twin API and React UI. The token stays server-side and is never sent to the browser. Injecting a leak starts the twin feed automatically; snapshots continue every five seconds while this dev process stays running.

Detection takes several evaluation windows before a warning or confirmed event appears on the operator dashboard at <http://localhost:5173/>. The dashboard also displays a distinct “simulated injection” marker from the latest twin snapshot, so it can show the injected pipe before ML detection confirms it.

Run `npm install` once when setting up this separate app. Do not put the service token in a `VITE_*` variable, React source, or any frontend `.env` file. The local API binds to loopback and is intended for the hackathon demo on the same machine, not public hosting. Press Ctrl+C in the single terminal to stop the UI, twin API, and any FastAPI backend this command started. A FastAPI backend that was already running is left running.

## Troubleshooting

- If the UI says the network cannot load, make sure `backend/.env` contains the same `TWIN_SERVICE_TOKEN` as the running backend. Restart a previously running Uvicorn after changing `.env`.
- If ports 5174 or 4174 are already in use, stop the old digital-twin Vite/API terminal with Ctrl+C, then run `npm run dev` once. This command now starts both.
- If a snapshot fails, the UI reports the backend endpoint and HTTP status; the API terminal also logs unexpected server errors.
- The command polling failure (`GET /v1/twin/commands`) is separate from this simulator. Check the Uvicorn traceback for that request to identify the database error; the snapshot simulator does not call that endpoint.
