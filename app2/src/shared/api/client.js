import { supabase } from '../supabase/client';
import { ApiError, expireSession } from './errors';

const BASE = (import.meta.env.VITE_API_BASE_URL ?? '').replace(/\/$/, '');

function qs(query) {
  const p = new URLSearchParams();
  Object.entries(query ?? {}).forEach(([k, v]) => {
    if (v === undefined || v === null || v === '' || (Array.isArray(v) && !v.length)) return;
    p.set(k, Array.isArray(v) ? v.join(',') : v);
  });
  const s = p.toString();
  return s ? `?${s}` : '';
}

async function request(method, path, { query, body, key } = {}) {
  const { data } = await supabase.auth.getSession();
  const headers = { Accept: 'application/json' };
  if (data.session) headers.Authorization = `Bearer ${data.session.access_token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (key) headers['Idempotency-Key'] = key;

  let res;
  try {
    res = await fetch(`${BASE}${path}${qs(query)}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError(0, { title: 'Network error', detail: 'Could not reach the server.' });
  }

  const requestId = res.headers.get('x-request-id');
  if (!res.ok) {
    let problem;
    try {
      problem = await res.json();
    } catch {
      problem = undefined;
    }
    if (res.status === 401) expireSession();
    if (requestId) console.error(`API ${res.status} ${path} x-request-id=${requestId}`);
    throw new ApiError(res.status, problem, requestId);
  }
  return res.status === 204 ? null : res.json();
}

export const api = {
  get: (path, opts) => request('GET', path, opts),
  post: (path, opts = {}) => request('POST', path, { ...opts, body: opts.body ?? {} }),
};
