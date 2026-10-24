import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { CheckCircle2, TriangleAlert, XCircle } from 'lucide-react';
import { toast } from 'sonner';
import { Card, CardHeader } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { StatusBadge, Chip } from '@/shared/ui/Badges';
import { ConfirmDialog, ReasonDialog } from '@/shared/ui/ConfirmDialog';
import { CopyableCode } from '@/shared/ui/CopyableCode';
import { SlaTimer } from '@/shared/ui/SlaTimer';
import { Timeline } from '@/shared/ui/Timeline';
import { Skeleton, HeaderSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { usePipeMap } from '@/shared/data/network';
import { fmtNum, humanize } from '@/shared/lib/format';
import { fmtIST } from '@/shared/lib/time';
import { EvidenceGallery } from './EvidenceGallery';
import { useApprove, useEvidence, useReject, useWorkOrder } from './hooks';

function CheckCard({ check }) {
  if (!check) return <p className="text-sm text-ink-2">No check available yet.</p>;
  if (check.method === 'NOT_APPLICABLE_SIMULATED') {
    return <Chip tone="grey">Not applicable (simulated)</Chip>;
  }
  return (
    <div className="space-y-2 text-sm">
      {check.pass ? <Chip tone="success" icon={CheckCircle2}>Pass</Chip> : <Chip tone="danger" icon={XCircle}>Fail</Chip>}
      <dl className="grid grid-cols-2 gap-1 text-xs">
        <dt className="text-ink-3">Mean delta Q residual</dt><dd>{fmtNum(check.delta_q_resid_mean_lpm)} L/min</dd>
        <dt className="text-ink-3">Mean pressure deviation</dt><dd>{fmtNum(check.pressure_dev_pct_mean)}%</dd>
        <dt className="text-ink-3">Window</dt><dd>{check.window_minutes ?? '—'} min</dd>
      </dl>
    </div>
  );
}

export default function WorkOrderReviewPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const wo = useWorkOrder(id);
  const evidence = useEvidence(id);
  const { byId } = usePipeMap();
  const [dialog, setDialog] = useState(null);
  const w = wo.data;
  const approve = useApprove(id, w?.leak_event_id);
  const reject = useReject(id, w?.leak_event_id);

  if (wo.isPending) {
    return (
      <div className="space-y-4">
        <HeaderSkeleton />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }
  if (wo.error) return <ErrorState error={wo.error} onRetry={() => wo.refetch()} />;
  if (!w) {
    return (
      <EmptyState title="Work order not found">
        <Link to="/work-orders" className="text-primary underline">Back to work orders</Link>
      </EmptyState>
    );
  }

  const items = evidence.data ?? [];
  const badPhoto = items.some((i) => i.geo_valid === false);
  const failed = w.post_repair_check?.pass === false;
  const submitted = w.status === 'SUBMITTED';
  const pipe = byId.get(w.leak_events?.pipe_id);

  const steps = [
    ['Assigned', w.assigned_at], ['Accepted', w.accepted_at], ['En route', w.en_route_at], ['Arrived', w.arrived_at], ['Submitted', w.submitted_at],
  ].filter(([, t]) => t).map(([title, t]) => ({ id: title, title, meta: fmtIST(t), time: t }));

  return (
    <div className="space-y-4">
      <Card className="p-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="space-y-2">
            <div className="flex flex-wrap items-center gap-3">
              <h1 className="text-2xl font-semibold"><CopyableCode value={w.wo_no} /></h1>
              <StatusBadge domain="woStatus" value={w.status} />
              <StatusBadge domain="priority" value={w.priority} />
            </div>
            <p className="text-sm text-ink-2">
              Event <Link className="text-primary underline" to={`/events/${w.leak_event_id}`}>{w.leak_events?.event_no}</Link>
              {pipe && ` · Pipe ${pipe.code}`} · Engineer {w.engineers?.profiles?.full_name ?? 'unassigned'}
            </p>
          </div>
          <SlaTimer due={w.sla_due_at} stopped={['COMPLETED', 'CANCELLED'].includes(w.status)} />
        </div>
      </Card>

      {submitted && (badPhoto || failed) && (
        <div role="alert" className="flex items-start gap-2 rounded-md border border-warning bg-warning-soft p-3 text-sm text-warning">
          <TriangleAlert className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
          <span>
            {badPhoto && 'At least one photo was captured too far from the leak. '}
            {failed && 'The post-repair check failed. '}
            You can still approve, the decision is yours.
          </span>
        </div>
      )}

      <div className="grid gap-4 lg:grid-cols-[2fr_1fr]">
        <div className="space-y-4">
          <Card>
            <CardHeader title="Repair summary" />
            <dl className="grid gap-3 px-4 pb-4 text-sm sm:grid-cols-2">
              <div><dt className="text-ink-3">Repair type</dt><dd className="font-medium">{humanize(w.repair_type)}</dd></div>
              <div><dt className="text-ink-3">Labour</dt><dd className="font-medium">{w.labour_minutes != null ? `${w.labour_minutes} min` : '—'}</dd></div>
              <div className="sm:col-span-2">
                <dt className="text-ink-3">Materials</dt>
                <dd>{w.materials?.length ? <ul className="list-disc pl-5">{w.materials.map((m, i) => <li key={i}>{m.item} × {m.qty}</li>)}</ul> : '—'}</dd>
              </div>
              <div className="sm:col-span-2"><dt className="text-ink-3">Notes</dt><dd>{w.work_notes || '—'}</dd></div>
            </dl>
          </Card>

          <Card>
            <CardHeader title="Evidence" fetching={evidence.isFetching && !evidence.isPending} />
            <div className="px-4 pb-4">
              {evidence.error ? (
                <ErrorState error={evidence.error} onRetry={() => evidence.refetch()} />
              ) : (
                <EvidenceGallery items={items} loading={evidence.isPending} refetch={() => evidence.refetch()} />
              )}
            </div>
          </Card>
        </div>

        <div className="space-y-4">
          <Card>
            <CardHeader title="Post-repair check" />
            <div className="px-4 pb-4"><CheckCard check={w.post_repair_check} /></div>
          </Card>
          <Card>
            <CardHeader title="Timeline" />
            <div className="space-y-3 px-4 pb-4">
              {steps.length ? <Timeline items={steps} /> : <p className="text-sm text-ink-2">No activity yet.</p>}
              <p className="text-xs text-ink-2">Rework count: {w.rework_count}</p>
              {w.rejection_reason && <p className="rounded-md bg-orange-soft p-2 text-xs text-orange">Last rejection: {w.rejection_reason}</p>}
            </div>
          </Card>
        </div>
      </div>

      {submitted && (
        <div className="sticky bottom-0 flex justify-end gap-2 rounded-md border border-line bg-surface p-3 shadow-md">
          <Button variant="dangerOutline" onClick={() => setDialog('reject')}>Reject</Button>
          <Button disabled={evidence.isPending} onClick={() => setDialog('approve')}>Approve</Button>
        </div>
      )}
      {w.status === 'COMPLETED' && (
        <Link to={`/events/${w.leak_event_id}#isolation`} className="inline-block text-sm text-primary underline">Restore valves</Link>
      )}

      <ConfirmDialog
        open={dialog === 'approve'}
        onClose={() => setDialog(null)}
        title="Approve repair"
        description={`Approving ${w.wo_no} closes the event, returns the pipe to normal and resets the twin.`}
        reasonLabel="Comment (optional)"
        confirmLabel="Approve"
        onConfirm={async ({ key, reason }) => {
          await approve.mutateAsync({ key, comment: reason });
          toast.success('Repair approved', {
            action: { label: 'Restore valves', onClick: () => navigate(`/events/${w.leak_event_id}#isolation`) },
          });
        }}
      />
      <ReasonDialog
        open={dialog === 'reject'}
        onClose={() => setDialog(null)}
        title="Reject repair"
        description="The work order returns to the engineer for rework."
        reasonLabel="Reason (at least 10 characters)"
        minLength={10}
        confirmLabel="Reject"
        tone="danger"
        onConfirm={({ key, reason }) => reject.mutateAsync({ key, reason })}
      />
    </div>
  );
}
