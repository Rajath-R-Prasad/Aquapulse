import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { api } from '@/shared/api/client';
import { sb, sbPage } from '@/shared/api/errors';
import { useAction } from '@/shared/api/useAction';
import { supabase } from '@/shared/supabase/client';

export const WO_GROUPS = {
  active: ['UNASSIGNED', 'ASSIGNED', 'ACCEPTED', 'EN_ROUTE', 'ON_SITE', 'REWORK'],
  approval: ['SUBMITTED'],
  completed: ['COMPLETED', 'CANCELLED'],
};
export const PAGE_SIZE = 25;
const EMBED = '*,leak_events(event_no,severity,pipe_id),engineers(profiles(full_name))';

export const useWorkOrders = (group, page) =>
  useQuery({
    queryKey: ['workorders', { group, page }],
    queryFn: () =>
      sbPage(
        supabase
          .from('work_orders')
          .select(EMBED, { count: 'exact' })
          .in('status', WO_GROUPS[group])
          .order('updated_at', { ascending: false })
          .range(page * PAGE_SIZE, page * PAGE_SIZE + PAGE_SIZE - 1),
      ),
    placeholderData: keepPreviousData,
    staleTime: 15_000,
  });

export const useWorkOrder = (id) =>
  useQuery({
    queryKey: ['workorder', id],
    queryFn: () => sb(supabase.from('work_orders').select(EMBED).eq('id', id).maybeSingle()),
    enabled: !!id,
    staleTime: 15_000,
  });

export const useAssignments = (woId) =>
  useQuery({
    queryKey: ['assignments', woId],
    queryFn: () =>
      sb(supabase.from('work_order_assignments').select('*,engineers(profiles(full_name))').eq('work_order_id', woId).order('assigned_at', { ascending: false })),
    enabled: !!woId,
    staleTime: 15_000,
  });

export const useEvidence = (woId) =>
  useQuery({
    queryKey: ['evidence', woId],
    queryFn: async () => {
      const response = await api.get(`/v1/work-orders/${woId}/evidence`);
      if (!Array.isArray(response.items)) {
        throw new Error('The server returned an invalid work-order evidence response.');
      }
      return response.items;
    },
    enabled: !!woId,
    staleTime: 10 * 60_000,
    refetchOnWindowFocus: true,
  });

const after = (woId, eventId) => [['workorder', woId], ['workorders'], ['event', eventId], ['events'], ['summary'], ['pipemap'], ['advisories'], ['event-log']];

export const useApprove = (woId, eventId) =>
  useAction(({ key, comment }) => api.post(`/v1/work-orders/${woId}/approve`, { key, body: { comment, expected_status: 'SUBMITTED' } }), after(woId, eventId));

export const useReject = (woId, eventId) =>
  useAction(({ key, reason }) => api.post(`/v1/work-orders/${woId}/reject`, { key, body: { reason, expected_status: 'SUBMITTED' } }), after(woId, eventId));

export const useCancelWorkOrder = (woId, eventId) =>
  useAction(({ key, reason, expectedStatus }) => api.post(`/v1/work-orders/${woId}/cancel`, { key, body: { reason, expected_status: expectedStatus } }), after(woId, eventId));
