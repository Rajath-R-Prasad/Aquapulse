import { useQuery } from '@tanstack/react-query';
import { api } from '@/shared/api/client';

export const useSummary = () =>
  useQuery({ queryKey: ['summary'], queryFn: () => api.get('/v1/dashboard/summary'), staleTime: 30_000 });

export const usePublicStatus = () =>
  useQuery({
    queryKey: ['public-status'],
    queryFn: () => api.get('/v1/public/status'),
    refetchInterval: 60_000,
    staleTime: 30_000,
    retry: 1,
  });
