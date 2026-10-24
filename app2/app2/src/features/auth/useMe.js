import { useQuery } from '@tanstack/react-query';
import { api } from '@/shared/api/client';
import { useSession } from './useSession';

export function useMe() {
  const { session } = useSession();
  return useQuery({
    queryKey: ['me'],
    queryFn: () => api.get('/v1/me'),
    enabled: !!session,
    staleTime: 5 * 60_000,
  });
}
