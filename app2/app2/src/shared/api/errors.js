import { toast } from 'sonner';
import { supabase } from '../supabase/client';
import { strings } from '../lib/strings';

export class ApiError extends Error {
  constructor(status, problem, requestId) {
    super(problem?.detail ?? problem?.title ?? `HTTP ${status}`);
    this.status = status;
    this.problem = problem;
    this.requestId = requestId;
  }
}

export function expireSession() {
  sessionStorage.setItem('jr_expired', '1');
  supabase.auth.signOut();
}

function toApiError(error) {
  const status = error.code === 'PGRST301' ? 401 : error.code === 'PGRST116' ? 404 : 500;
  if (status === 401) expireSession();
  return new ApiError(status, { title: 'Request failed', detail: error.message });
}

export async function sb(query) {
  const { data, error } = await query;
  if (error) throw toApiError(error);
  return data;
}

export async function sbPage(query) {
  const { data, error, count } = await query;
  if (error) throw toApiError(error);
  return { items: data ?? [], count: count ?? 0 };
}

export async function sbCount(query) {
  const { count, error } = await query;
  if (error) throw toApiError(error);
  return count ?? 0;
}

export const isInline = (e) => !e?.status || e.status >= 500 || (e.status === 422 && Array.isArray(e.problem?.errors) && e.problem.errors.length > 0);

export function handleApiError(e, qc) {
  const s = e?.status;
  if (isInline(e)) return;
  if (s === 401) expireSession();
  else if (s === 403) toast.error(strings.errors.forbidden);
  else if (s === 409) {
    toast.error(strings.errors.conflict);
    qc?.invalidateQueries();
  } else if (s === 429) toast.error(strings.errors.rate);
  else if (s !== 404) toast.error(e.message);
}
