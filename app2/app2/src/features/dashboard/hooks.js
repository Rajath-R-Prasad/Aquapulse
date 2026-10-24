import { useQuery } from '@tanstack/react-query';
import { api } from '@/shared/api/client';

export const useSummary = () =>
  useQuery({ queryKey: ['summary'], queryFn: () => api.get('/v1/dashboard/summary'), staleTime: 30_000 });
