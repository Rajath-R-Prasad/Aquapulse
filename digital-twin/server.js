import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';

const backendUrl = process.env.AQUAPULSE_API_URL || 'http://127.0.0.1:8000';
const apiBase = backendUrl.replace(/\/+$/, '');
const token = process.env.TWIN_SERVICE_TOKEN;
const port = Number(process.env.DIGITAL_TWIN_PORT || 4174);
const intervalMs = 5_000;

let network;
let runId;
let timer;
let lastError = null;
let lastSnapshotAt = null;
let lastReadings = [];
let snapshotQueue = Promise.resolve();
const leakRates = new Map();
class ApiError extends Error {
  constructor(message, status = 500) {
    super(message);
    this.status = status;
  }
}

async function backendJson(path, options = {}) {
  const response = await fetch(`${apiBase}${path}`, {
    ...options,
    signal: AbortSignal.timeout(15_000),
    headers: {
      Authorization: `Bearer ${token}`,
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...options.headers,
    },
  });
  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    throw new ApiError(`${path} returned invalid JSON (HTTP ${response.status})`, 502);
  }
  if (!response.ok) {
    const detail = data.detail || data.title || text || response.statusText;
    throw new ApiError(`${path} returned HTTP ${response.status}: ${detail}`, 502);
  }
  return data;
}

async function getNetwork(refresh = false) {
  if (!network || refresh) {
    const result = await backendJson('/v1/twin/network');
    if (!Array.isArray(result.features)) {
      throw new ApiError('Twin network response is missing GeoJSON features', 502);
    }
    const simulated = result.features.filter((feature) => (
      feature?.properties?.feature_type === 'PIPE'
      && feature.properties.monitoring === 'SIMULATED'
      && feature.properties.code
      && Number.isFinite(Number(feature.properties.design_flow_lpm))
    ));
    if (!simulated.length) {
      throw new ApiError('Twin network has no usable SIMULATED pipes', 502);
    }
    network = result;
  }
  return network;
}

function getState() {
  return {
    running: Boolean(runId && timer),
    run_id: runId ?? null,
    leak_rates_lpm: Object.fromEntries(leakRates),
    last_snapshot_at: lastSnapshotAt,
    last_error: lastError,
    readings: lastReadings,
  };
}

function makeSnapshot() {
  const pipes = network.features.filter((feature) => (
    feature?.properties?.feature_type === 'PIPE'
    && feature.properties.monitoring === 'SIMULATED'
  )).map(({ properties: pipe }) => {
    const designFlow = Number(pipe.design_flow_lpm);
    const flowIn = Math.max(1, designFlow * 0.6) + (Math.random() - 0.5) * 0.2;
    const leak = leakRates.get(pipe.code) || 0;
    const flowOut = flowIn - 0.1 - leak + (Math.random() - 0.5) * 0.2;
    const pressureDrop = leak * 0.5;
    return {
      pipe_code: pipe.code,
      flow_in: Number(flowIn.toFixed(2)),
      flow_out: Number(flowOut.toFixed(2)),
      pressure_in: Number((190 - pressureDrop + (Math.random() - 0.5) * 0.4).toFixed(2)),
      pressure_out: Number((188 - pressureDrop + (Math.random() - 0.5) * 0.4).toFixed(2)),
      velocity: 0.3,
      injected_leak: leak,
    };
  });
  return {
    schema: 'AquaPulse.twin.snapshot/1.0',
    run_id: runId,
    sim_time: new Date().toISOString(),
    units: { flow: 'L/min', pressure: 'kPa', velocity: 'm/s' },
    pipes,
  };
}

function sendSnapshot() {
  const task = async () => {
    if (!runId) return;
    const snapshot = makeSnapshot();
    await backendJson('/v1/ingest/twin/snapshots', {
      method: 'POST',
      body: JSON.stringify(snapshot),
    });
    lastReadings = snapshot.pipes;
    lastSnapshotAt = snapshot.sim_time;
    lastError = null;
  };
  snapshotQueue = snapshotQueue.then(task, task);
  return snapshotQueue.catch((error) => {
    lastError = error.message;
    throw error;
  });
}

function readJson(request) {
  return new Promise((resolve, reject) => {
    let body = '';
    request.setEncoding('utf8');
    request.on('data', (chunk) => {
      if (body === null) return;
      body += chunk;
      if (body.length > 16_384) {
        body = null;
        reject(new ApiError('Request body is too large', 413));
      }
    });
    request.on('end', () => {
      if (body === null) return;
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch {
        reject(new ApiError('Request body must be valid JSON', 400));
      }
    });
    request.on('error', reject);
  });
}

function sendJson(response, status, value) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  response.end(JSON.stringify(value));
}

async function startRun() {
  if (runId && timer) return getState();
  await getNetwork();
  const result = await backendJson('/v1/ingest/twin/runs', {
    method: 'POST',
    body: JSON.stringify({
      action: 'START',
      name: 'interactive-digital-twin',
      network_version: 'dma-01',
    }),
  });
  if (!result.run_id) {
    throw new ApiError('Twin run response did not include run_id', 502);
  }
  runId = result.run_id;
  timer = setInterval(() => {
    sendSnapshot().catch(() => {});
  }, intervalMs);
  await sendSnapshot();
  return getState();
}

async function stopRun() {
  if (!runId) return getState();
  clearInterval(timer);
  timer = undefined;
  const stoppedRunId = runId;
  try {
    await snapshotQueue.catch(() => undefined);
    await backendJson('/v1/ingest/twin/runs', {
      method: 'POST',
      body: JSON.stringify({ action: 'STOP', run_id: stoppedRunId }),
    });
    runId = undefined;
    lastError = null;
    return getState();
  } catch (error) {
    timer = setInterval(() => {
      sendSnapshot().catch(() => {});
    }, intervalMs);
    throw error;
  }
}

async function handleRequest(request, response) {
  const url = new URL(request.url, 'http://127.0.0.1');
  try {
    if (request.method === 'GET' && url.pathname === '/api/network') {
      return sendJson(response, 200, await getNetwork(true));
    }
    if (request.method === 'GET' && url.pathname === '/api/state') {
      return sendJson(response, 200, getState());
    }
    if (request.method === 'POST' && url.pathname === '/api/start') {
      return sendJson(response, 200, await startRun());
    }
    if (request.method === 'POST' && url.pathname === '/api/stop') {
      return sendJson(response, 200, await stopRun());
    }
    if (request.method === 'POST' && url.pathname === '/api/leaks') {
      const body = await readJson(request);
      const twinNetwork = await getNetwork();
      const pipe = twinNetwork.features.find((feature) => feature.properties.code === body.pipe_code)?.properties;
      const rate = Number(body.leak_rate_lpm);
      if (!pipe) throw new ApiError('Choose a simulated pipe from the network', 400);
      if (!Number.isFinite(rate) || rate <= 0 || rate > Math.min(2000, Number(pipe.design_flow_lpm) * 0.55)) {
        throw new ApiError('Leak rate must be greater than zero and no more than 55% of design flow', 400);
      }
      leakRates.set(pipe.code, rate);
      if (runId) await sendSnapshot();
      else await startRun();
      return sendJson(response, 200, getState());
    }
    if (request.method === 'DELETE' && url.pathname === '/api/leaks') {
      leakRates.clear();
      if (runId) await sendSnapshot();
      return sendJson(response, 200, getState());
    }
    const clearMatch = url.pathname.match(/^\/api\/leaks\/([^/]+)$/);
    if (request.method === 'DELETE' && clearMatch) {
      const code = decodeURIComponent(clearMatch[1]);
      leakRates.delete(code);
      if (runId) await sendSnapshot();
      return sendJson(response, 200, getState());
    }
    return sendJson(response, 404, { error: 'API route not found' });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    if (!(error instanceof ApiError)) {
      console.error('Digital-twin API request failed:', error);
    }
    return sendJson(response, status, { error: error.message || 'Digital-twin API request failed' });
  }
}

function startServer() {
  if (!token) {
    console.error('TWIN_SERVICE_TOKEN is required. Set it in the API server environment, not in Vite variables.');
    process.exitCode = 1;
    return;
  }
  const server = createApiServer();
  server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      console.error(
        `Digital-twin API port ${port} is already in use. Reuse the running API or stop its specific process before starting another.`,
      );
      process.exitCode = 1;
      return;
    }
    console.error('Could not start the digital-twin API:', error.message);
    process.exitCode = 1;
  });
  server.listen(port, '127.0.0.1', () => {
    console.log(`Digital-twin API listening on http://127.0.0.1:${port}`);
  });
  const shutdown = async () => {
    try {
      await stopRun();
    } catch (error) {
      console.error('Could not stop the backend twin run during shutdown:', error.message);
      if (timer) clearInterval(timer);
    } finally {
      server.close();
    }
  };
  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);
}

function createApiServer() {
  return createServer(handleRequest);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer();
}

export { createApiServer, getState, makeSnapshot };
