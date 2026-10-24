import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { once } from 'node:events';
import test from 'node:test';

const backendRequests = [];
const testPipe = (code, designFlow) => ({
  type: 'Feature',
  geometry: { type: 'LineString', coordinates: [[76.63, 12.29], [76.64, 12.30]] },
  properties: {
    feature_type: 'PIPE',
    code,
    monitoring: 'SIMULATED',
    design_flow_lpm: designFlow,
  },
});

test('local API relays interactive leaks through twin snapshot endpoints', async () => {
  const mockBackend = createServer(async (request, response) => {
    let body = '';
    for await (const chunk of request) body += chunk;
    backendRequests.push({ method: request.method, url: request.url, body: body ? JSON.parse(body) : null });
    response.setHeader('Content-Type', 'application/json');
    if (request.url === '/v1/twin/network') {
      response.end(JSON.stringify({ type: 'FeatureCollection', features: [testPipe('P05', 80), testPipe('P06', 60)] }));
    } else if (request.url === '/v1/ingest/twin/runs' && request.method === 'POST') {
      response.end(JSON.stringify({ run_id: 'test-run' }));
    } else if (request.url === '/v1/ingest/twin/snapshots' && request.method === 'POST') {
      response.end(JSON.stringify({ accepted: request.body?.pipes?.length ?? 2 }));
    } else {
      response.end(JSON.stringify({ status: 'STOPPED' }));
    }
  });
  mockBackend.listen(0, '127.0.0.1');
  await once(mockBackend, 'listening');
  process.env.AQUAPULSE_API_URL = `http://127.0.0.1:${mockBackend.address().port}`;
  process.env.TWIN_SERVICE_TOKEN = 'test-only-token';

  const { createApiServer } = await import('./server.js');
  const api = createApiServer();
  api.listen(0, '127.0.0.1');
  await once(api, 'listening');
  const base = `http://127.0.0.1:${api.address().port}`;

  try {
    const networkResponse = await fetch(`${base}/api/network`);
    assert.equal(networkResponse.status, 200);
    assert.equal((await networkResponse.json()).features.length, 2);

    const leakResponse = await fetch(`${base}/api/leaks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pipe_code: 'P05', leak_rate_lpm: 12 }),
    });
    assert.equal(leakResponse.status, 200);

    const startResponse = await fetch(`${base}/api/start`, { method: 'POST' });
    assert.equal(startResponse.status, 200);
    assert.equal((await startResponse.json()).running, true);
    const firstSnapshot = backendRequests.find((item) => item.url === '/v1/ingest/twin/snapshots').body;
    assert.equal(firstSnapshot.run_id, 'test-run');
    assert.equal(firstSnapshot.pipes.length, 2);
    assert.equal(firstSnapshot.pipes.find((pipe) => pipe.pipe_code === 'P05').injected_leak, 12);

    const clearResponse = await fetch(`${base}/api/leaks/P05`, { method: 'DELETE' });
    assert.equal(clearResponse.status, 200);
    const clearedSnapshot = backendRequests.filter((item) => item.url === '/v1/ingest/twin/snapshots').at(-1).body;
    assert.equal(clearedSnapshot.pipes.find((pipe) => pipe.pipe_code === 'P05').injected_leak, 0);

    const stopResponse = await fetch(`${base}/api/stop`, { method: 'POST' });
    assert.equal(stopResponse.status, 200);
    assert.equal((await stopResponse.json()).running, false);
    assert.ok(backendRequests.some((item) => item.url === '/v1/ingest/twin/runs' && item.body.action === 'STOP'));

    const invalidLeakResponse = await fetch(`${base}/api/leaks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pipe_code: 'P05', leak_rate_lpm: 500 }),
    });
    assert.equal(invalidLeakResponse.status, 400);
  } finally {
    await new Promise((resolve) => api.close(resolve));
    await new Promise((resolve) => mockBackend.close(resolve));
    delete process.env.AQUAPULSE_API_URL;
    delete process.env.TWIN_SERVICE_TOKEN;
  }
});
