import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '@/shared/api/client';
import { useAction } from '@/shared/api/useAction';

export const useCandidates = (eventId, enabled) =>
  useQuery({
    queryKey: ['candidates', eventId],
    queryFn: async () => {
      const response = await api.get(`/v1/leak-events/${eventId}/engineer-candidates`);
      if (!Array.isArray(response.items)) {
        throw new Error('The server returned an invalid engineer-candidates response.');
      }
      return response.items;
    },
    enabled: !!eventId && enabled,
    staleTime: 0,
    gcTime: 0,
  });

export function useAssign(woId, eventId) {
  const qc = useQueryClient();
  return useAction(
    ({ key, engineerId, expectedStatus }) =>
      api.post(`/v1/work-orders/${woId}/assign`, { key, body: { engineer_id: engineerId, expected_status: expectedStatus } }),
    [['event', eventId], ['events'], ['workorders'], ['workorder', woId], ['candidates', eventId], ['engineers'], ['summary']],
  );
}
