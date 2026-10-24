import { useQuery } from '@tanstack/react-query';
import { sbCount } from '../api/errors';
import { supabase } from '../supabase/client';

export const useAwaitingApprovalCount = () =>
  useQuery({
    queryKey: ['workorders', 'count', 'SUBMITTED'],
    queryFn: () => sbCount(supabase.from('work_orders').select('id', { count: 'exact', head: true }).eq('status', 'SUBMITTED')),
    staleTime: 15_000,
  });

export const useOpenAdvisoryCount = () =>
  useQuery({
    queryKey: ['advisories', 'count', 'OPEN'],
    queryFn: () => sbCount(supabase.from('isolation_advisories').select('id', { count: 'exact', head: true }).eq('status', 'OPEN')),
    staleTime: 15_000,
  });
