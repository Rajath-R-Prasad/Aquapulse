import { useQuery } from '@tanstack/react-query';
import { sb } from '@/shared/api/errors';
import { supabase } from '@/shared/supabase/client';
import { LIVE_WO_STATUSES } from '@/shared/lib/statusMap';

export const useEngineers = () =>
  useQuery({
    queryKey: ['engineers'],
    queryFn: async () => {
      const [engineers, jobs] = await Promise.all([
        sb(supabase.from('engineers').select('*,profiles(full_name,phone)')),
        sb(supabase.from('work_orders').select('assigned_engineer_id').in('status', LIVE_WO_STATUSES).not('assigned_engineer_id', 'is', null)),
      ]);
      const counts = jobs.reduce((m, j) => m.set(j.assigned_engineer_id, (m.get(j.assigned_engineer_id) ?? 0) + 1), new Map());
      return engineers.map((e) => ({ ...e, active_jobs: counts.get(e.profile_id) ?? 0 }));
    },
    staleTime: 5_000,
  });
