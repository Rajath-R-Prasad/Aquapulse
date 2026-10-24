import { Link } from 'react-router-dom';
import { Card, CardHeader } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { StatusBadge } from '@/shared/ui/Badges';
import { SlaTimer } from '@/shared/ui/SlaTimer';
import { Time } from '@/shared/ui/Time';
import { ListSkeleton, Skeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { humanize } from '@/shared/lib/format';
import { useAssignments, useWorkOrder } from '@/features/workorders/hooks';

const STAMPS = [['assigned_at', 'Assigned'], ['accepted_at', 'Accepted'], ['en_route_at', 'En route'], ['arrived_at', 'Arrived'], ['submitted_at', 'Submitted'], ['approved_at', 'Approved']];

export function WorkOrderTab({ workOrderId, onDispatch }) {
  const wo = useWorkOrder(workOrderId);
  const assignments = useAssignments(workOrderId);
  if (!workOrderId) return <EmptyState title="No work order for this event" />;
  if (wo.isPending) return <Skeleton className="h-48 w-full" />;
  if (wo.error) return <ErrorState error={wo.error} onRetry={() => wo.refetch()} />;
  const w = wo.data;
  if (!w) return <EmptyState title="Work order not found" />;

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title={<Link to={`/work-orders/${w.id}`} className="text-primary hover:underline">{w.wo_no}</Link>}
          actions={w.status === 'UNASSIGNED' && <Button onClick={onDispatch}>Assign engineer</Button>}
        />
        <div className="space-y-3 px-4 pb-4">
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge domain="woStatus" value={w.status} />
            <StatusBadge domain="priority" value={w.priority} />
            <SlaTimer due={w.sla_due_at} stopped={['COMPLETED', 'CANCELLED'].includes(w.status)} />
          </div>
          <p className="text-sm">Engineer: <strong>{w.engineers?.profiles?.full_name ?? 'Unassigned'}</strong></p>
          <dl className="grid grid-cols-2 gap-3 md:grid-cols-3">
            {STAMPS.filter(([k]) => w[k]).map(([k, label]) => (
              <div key={k}><dt className="text-xs text-ink-3">{label}</dt><dd className="text-sm"><Time value={w[k]} /></dd></div>
            ))}
          </dl>
        </div>
      </Card>

      <Card>
        <CardHeader title="Assignment history" />
        <div className="px-4 pb-4">
          {assignments.isPending ? <ListSkeleton rows={2} /> : assignments.error ? (
            <ErrorState error={assignments.error} onRetry={() => assignments.refetch()} />
          ) : !assignments.data.length ? (
            <p className="text-sm text-ink-2">No assignments yet.</p>
          ) : (
            <ul className="divide-y divide-line">
              {assignments.data.map((a) => (
                <li key={a.id} className="flex flex-wrap items-center justify-between gap-2 py-2 text-sm">
                  <span className="font-medium">{a.engineers?.profiles?.full_name ?? 'Engineer'}</span>
                  <span className="text-ink-2">{humanize(a.response)}{a.decline_reason && ` · ${a.decline_reason}`}</span>
                  <span className="text-xs text-ink-3">Score {a.score != null ? Number(a.score).toFixed(2) : '—'} · <Time value={a.assigned_at} relative /></span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Card>
    </div>
  );
}
