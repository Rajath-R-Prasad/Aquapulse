import { useInfiniteQuery, useQuery } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import { api } from '@/shared/api/client';
import { sb } from '@/shared/api/errors';
import { useAction } from '@/shared/api/useAction';
import { supabase } from '@/shared/supabase/client';
import { istDateToIso } from '@/shared/lib/time';

const split = (v) => (v ? v.split(',').filter(Boolean) : []);

export function useUrlFilters() {
  const [params, setParams] = useSearchParams();
  const filters = {
    status: split(params.get('status')),
    severity: split(params.get('severity')),
    source: params.get('source') ?? '',
    from: params.get('from') ?? '',
    to: params.get('to') ?? '',
    q: params.get('q') ?? '',
  };
  const set = (patch) => {
    const next = new URLSearchParams(params);
    Object.entries(patch).forEach(([k, v]) => {
      const val = Array.isArray(v) ? v.join(',') : v;
      if (val) next.set(k, val);
      else next.delete(k);
    });
    setParams(next, { replace: true });
  };
  const active = Object.values(filters).some((v) => (Array.isArray(v) ? v.length : v));
  return { filters, set, clear: () => setParams({}, { replace: true }), active };
}

export const useEvents = (f) =>
  useInfiniteQuery({
    queryKey: ['events', 'list', f.status, f.severity, f.source, f.from, f.to],
    queryFn: ({ pageParam }) =>
      api.get('/v1/leak-events', {
        query: {
          status: f.status,
          severity: f.severity,
          source: f.source,
          from: f.from ? istDateToIso(f.from) : undefined,
          to: f.to ? istDateToIso(f.to, true) : undefined,
          cursor: pageParam,
          limit: 50,
        },
      }),
    initialPageParam: undefined,
    getNextPageParam: (p) => p.next_cursor ?? undefined,
    staleTime: 15_000,
  });

export const useEvent = (id) =>
  useQuery({ queryKey: ['event', id], queryFn: () => api.get(`/v1/leak-events/${id}`), enabled: !!id, staleTime: 15_000 });

export const useEventLog = (eventId, entityIds) =>
  useQuery({
    queryKey: ['event-log', eventId, ...entityIds],
    queryFn: async () => {
      const [log, history] = await Promise.all([
        sb(supabase.from('event_log').select('*').in('entity_id', entityIds).order('created_at', { ascending: false }).limit(100)),
        sb(supabase.from('pipe_state_history').select('*').eq('leak_event_id', eventId).order('changed_at', { ascending: false })),
      ]);
      return { log, history };
    },
    enabled: !!eventId,
    staleTime: 30_000,
  });

const keys = (id) => [['event', id], ['events'], ['summary'], ['pipemap'], ['event-log']];

export const useAcknowledgeEvent = (id) =>
  useAction(({ key, expectedStatus }) => api.post(`/v1/leak-events/${id}/acknowledge`, { key, body: { expected_status: expectedStatus } }), keys(id));

export const useFalseAlarm = (id) =>
  useAction(({ key, reason, expectedStatus }) => api.post(`/v1/leak-events/${id}/false-alarm`, { key, body: { reason, expected_status: expectedStatus } }), keys(id));
