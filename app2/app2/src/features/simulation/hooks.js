import { useQuery } from '@tanstack/react-query';
import { api } from '@/shared/api/client';
import { sb } from '@/shared/api/errors';
import { useAction } from '@/shared/api/useAction';
import { supabase } from '@/shared/supabase/client';

export const useTwinCommands = () =>
  useQuery({
    queryKey: ['twin-commands'],
    queryFn: () => sb(supabase.from('twin_commands').select('*').order('created_at', { ascending: false }).limit(20)),
    refetchInterval: 5000,
    staleTime: 0,
  });

export const useInjectLeak = () =>
  useAction(({ pipeId, rate }) => api.post('/v1/twin/inject-leak', { body: { pipe_id: pipeId, leak_rate_lpm: rate } }), [['twin-commands']]);

export const useClearLeak = () =>
  useAction(({ pipeId }) => api.post('/v1/twin/clear-leak', { body: { pipe_id: pipeId } }), [['twin-commands']]);
