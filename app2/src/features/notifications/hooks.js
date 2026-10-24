import { useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '@/shared/api/client';
import { handleApiError } from '@/shared/api/errors';

export const useNotifications = () =>
  useQuery({
    queryKey: ['notifications'],
    queryFn: () => api.get('/v1/notifications', { query: { limit: 50 } }),
    staleTime: 30_000,
  });

export function useUnreadCount() {
  const { data } = useNotifications();
  return (data?.items ?? []).filter((n) => !n.read_at).length;
}

export function useMarkRead() {
  const qc = useQueryClient();
  const mark = (id) => api.post(`/v1/notifications/${id}/read`);
  return {
    markOne: async (id) => {
      try {
        await mark(id);
      } catch (e) {
        handleApiError(e, qc);
      } finally {
        qc.invalidateQueries({ queryKey: ['notifications'] });
      }
    },
    markAll: async (ids) => {
      for (const id of ids) {
        try {
          // eslint-disable-next-line no-await-in-loop
          await mark(id);
        } catch (e) {
          handleApiError(e, qc);
          break;
        }
      }
      qc.invalidateQueries({ queryKey: ['notifications'] });
    },
  };
}
