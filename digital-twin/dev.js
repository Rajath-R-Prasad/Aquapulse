import { spawn } from 'node:child_process';
import { createServer as createNetServer } from 'node:net';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(fileURLToPath(import.meta.url));
const backendDir = path.resolve(root, '..', 'backend');
const backendPort = Number(process.env.API_PORT || 8000);
const twinApiPort = Number(process.env.DIGITAL_TWIN_PORT || 4174);
const webPort = 5174;
const backendUrl = process.env.AQUAPULSE_API_URL || `http://127.0.0.1:${backendPort}`;
let backendProcess;
let twinApi;
let vite;
let stopping = false;

function parseEnv(content) {
  const values = {};
  for (const line of content.split(/\r?\n/)) {
    const match = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (!match) continue;
    let value = match[2];
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    } else {
      value = value.replace(/\s+#.*$/, '');
    }
    values[match[1]] = value;
  }
  return values;
}

async function loadBackendEnvironment() {
  const envFile = path.join(backendDir, '.env');
  let values;
  try {
    values = parseEnv(await readFile(envFile, 'utf8'));
  } catch (error) {
    throw new Error(`Could not read backend/.env: ${error.message}`);
  }
  if (values.TWIN_SERVICE_TOKEN) process.env.TWIN_SERVICE_TOKEN = values.TWIN_SERVICE_TOKEN;
  if (!process.env.AQUAPULSE_API_URL) process.env.AQUAPULSE_API_URL = backendUrl;
  if (!process.env.TWIN_SERVICE_TOKEN) {
    throw new Error('TWIN_SERVICE_TOKEN is missing from backend/.env');
  }
}

async function isPortAvailable(port) {
  return new Promise((resolve, reject) => {
    const server = createNetServer();
    server.once('error', (error) => {
      if (error.code === 'EADDRINUSE') resolve(false);
      else reject(error);
    });
    server.listen(port, '127.0.0.1', () => server.close(() => resolve(true)));
  });
}

async function checkBackend() {
  try {
    const health = await fetch(`${backendUrl}/health`, { signal: AbortSignal.timeout(2_000) });
    if (!health.ok) return { ready: false, reason: `Backend health returned HTTP ${health.status}` };
  } catch (error) {
    return { ready: false, reason: error.message };
  }
  try {
    const response = await fetch(`${backendUrl}/v1/twin/network`, {
      headers: { Authorization: `Bearer ${process.env.TWIN_SERVICE_TOKEN}` },
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) {
      const text = await response.text();
      const message = response.status === 401
        ? 'Twin token in backend/.env does not match the running backend. Restart Uvicorn after updating the token.'
        : `Twin network endpoint returned HTTP ${response.status}: ${text.slice(0, 300)}`;
      return { ready: false, reason: message, fatal: response.status === 401 };
    }
    const data = await response.json();
    if (!Array.isArray(data.features)) {
      return { ready: false, reason: 'Twin network endpoint did not return GeoJSON features', fatal: true };
    }
    return { ready: true };
  } catch (error) {
    return { ready: false, reason: `Backend is running but its database/network request failed: ${error.message}` };
  }
}

async function waitForBackend(timeoutMs = 60_000) {
  const deadline = Date.now() + timeoutMs;
  let lastReason = 'waiting for backend';
  while (Date.now() < deadline) {
    if (stopping) throw new Error('Startup cancelled');
    if (backendProcess?.exitCode != null) {
      throw new Error(`FastAPI exited during startup with code ${backendProcess.exitCode}`);
    }
    const result = await checkBackend();
    if (result.ready) return;
    if (result.fatal) throw new Error(result.reason);
    lastReason = result.reason;
    await new Promise((resolve) => setTimeout(resolve, 1_000));
  }
  throw new Error(
    `FastAPI did not become ready within ${timeoutMs / 1000}s. Last check: ${lastReason}. See the backend terminal output for details.`,
  );
}

async function startBackendIfNeeded() {
  const health = await fetch(`${backendUrl}/health`, { signal: AbortSignal.timeout(2_000) }).catch(() => null);
  if (health?.ok) {
    console.log('Using the already-running FastAPI backend.');
    return;
  }
  if (!(await isPortAvailable(backendPort))) {
    throw new Error(`Port ${backendPort} is occupied, but FastAPI health check failed. Check the existing process on that port.`);
  }

  const python = path.join(backendDir, '.venv', 'Scripts', 'python.exe');
  console.log('Starting FastAPI from backend/.venv...');
  backendProcess = spawn(python, ['-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', String(backendPort), '--workers', '1'], {
    cwd: backendDir,
    env: process.env,
    stdio: 'inherit',
    windowsHide: true,
  });
  backendProcess.once('error', (error) => {
    console.error(`Could not start FastAPI: ${error.message}`);
  });
  backendProcess.once('exit', (code, signal) => {
    if (stopping) return;
    console.error(`FastAPI stopped${signal ? ` (${signal})` : ` with exit code ${code}`}.`);
    void shutdown(code || 1);
  });
  await waitForBackend();
}

async function startTwinApi() {
  if (!(await isPortAvailable(twinApiPort))) {
    try {
      const existing = await fetch(`http://127.0.0.1:${twinApiPort}/api/network`, {
        signal: AbortSignal.timeout(10_000),
      });
      if (existing.ok) {
        console.log(`Using the already-running twin API on http://127.0.0.1:${twinApiPort}.`);
        return;
      }
    } catch {
      // Port is occupied by another service or an unhealthy twin process.
    }
    throw new Error(`Port ${twinApiPort} is occupied by an unresponsive service. Stop its own terminal, then retry.`);
  }
  const { createApiServer } = await import('./server.js');
  twinApi = createApiServer();
  await new Promise((resolve, reject) => {
    twinApi.once('error', reject);
    twinApi.listen(twinApiPort, '127.0.0.1', resolve);
  });
  console.log(`Digital-twin API listening on http://127.0.0.1:${twinApiPort}.`);
}

async function startWeb() {
  if (!(await isPortAvailable(webPort))) {
    throw new Error(`Port ${webPort} is already in use. Stop the old digital-twin Vite terminal, then run npm run dev again.`);
  }
  const { createServer } = await import('vite');
  vite = await createServer({
    configFile: path.join(root, 'vite.config.js'),
    server: { host: '127.0.0.1', port: webPort, strictPort: true },
  });
  await vite.listen();
  console.log(`Digital-twin UI ready at http://127.0.0.1:${webPort}/`);
}

async function shutdown(exitCode = 0) {
  if (stopping) return;
  stopping = true;
  try {
    if (vite) await vite.close();
    if (twinApi) await new Promise((resolve) => twinApi.close(resolve));
  } finally {
    if (backendProcess && backendProcess.exitCode == null) {
      backendProcess.kill();
    }
    process.exitCode = exitCode;
  }
}

async function main() {
  try {
    await loadBackendEnvironment();
    await startBackendIfNeeded();
    await waitForBackend();
    await startTwinApi();
    await startWeb();
    console.log('Press Ctrl+C to stop the digital-twin app and any backend it started.');
  } catch (error) {
    console.error(`Digital-twin startup failed: ${error.message}`);
    await shutdown(1);
  }
}

process.once('SIGINT', () => void shutdown(0));
process.once('SIGTERM', () => void shutdown(0));

main();
