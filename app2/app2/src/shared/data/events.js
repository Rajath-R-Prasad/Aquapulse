import { useQuery } from '@tanstack/react-query';
import { sb } from '../api/errors';
import { supabase } from '../supabase/client';
import { SEVERITY_RANK } from '../lib/statusMap';

export const bySeverityThenTime = (a, b) =>
  (SEVERITY_RANK[b.severity] ?? 0) - (SEVERITY_RANK[a.severity] ?? 0) || new Date(b.detected_at) - new Date(a.detected_at);

export const useOpenEvents = (limit = 20) =>
  useQuery({
    queryKey: ['events', 'open', limit],
    queryFn: async () => {
      const rows = await sb(
        supabase
          .from('v_leak_events_enriched')
          .select('*')
          .not('status', 'in', '(CLOSED,FALSE_ALARM)')
          .order('detected_at', { ascending: false })
          .limit(limit),
      );
      return rows.sort(bySeverityThenTime);
    },
    staleTime: 15_000,
  });

export const useGlobalSearch = (q) =>
  useQuery({
    queryKey: ['events', 'search', q],
    queryFn: () => {
      const term = q.replace(/[%,()]/g, '');
      return sb(
        supabase
          .from('v_leak_events_enriched')
          .select('id,event_no,pipe_code,severity,status')
          .or(`event_no.ilike.%${term}%,pipe_code.ilike.%${term}%`)
          .order('detected_at', { ascending: false })
          .limit(6),
      );
    },
    enabled: q.trim().length >= 2,
    staleTime: 15_000,
  });
