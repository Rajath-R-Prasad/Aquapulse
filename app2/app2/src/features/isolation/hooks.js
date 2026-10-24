import { useQuery } from '@tanstack/react-query';
import { api } from '@/shared/api/client';
import { sb } from '@/shared/api/errors';
import { useAction } from '@/shared/api/useAction';
import { supabase } from '@/shared/supabase/client';

const SELECT =
  '*,isolation_advisory_valves(*,valves(code,kind,state),closer:profiles!close_confirmed_by(full_name),restorer:profiles!restore_confirmed_by(full_name))';

export const useAdvisory = (eventId) =>
  useQuery({
    queryKey: ['advisories', eventId],
    queryFn: () =>
      sb(supabase.from('isolation_advisories').select(SELECT).eq('leak_event_id', eventId).order('created_at', { ascending: false }).limit(1).maybeSingle()),
    enabled: !!eventId,
    staleTime: 15_000,
  });

const keys = (eventId) => [['advisories', eventId], ['event', eventId], ['events'], ['pipemap'], ['summary']];

export const useAckAdvisory = (id, eventId) =>
  useAction(({ key, expected_status }) => api.post(`/v1/isolation-advisories/${id}/acknowledge`, { key, body: { expected_status } }), keys(eventId));

export const useDismissAdvisory = (id, eventId) =>
  useAction(({ key, reason, expected_status }) => api.post(`/v1/isolation-advisories/${id}/dismiss`, { key, body: { reason, expected_status } }), keys(eventId));

export const useConfirmClosed = (id, eventId) =>
  useAction(({ key, valveId }) => api.post(`/v1/isolation-advisories/${id}/valves/${valveId}/confirm-closed`, { key }), keys(eventId));

export const useConfirmRestored = (id, eventId) =>
  useAction(({ key, valveId }) => api.post(`/v1/isolation-advisories/${id}/valves/${valveId}/confirm-restored`, { key }), keys(eventId));
