import { useState } from 'react';
import { Octagon, TriangleAlert } from 'lucide-react';
import { Card } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { StatusBadge, Chip } from '@/shared/ui/Badges';
import { ConfirmDialog, ReasonDialog } from '@/shared/ui/ConfirmDialog';
import { Time } from '@/shared/ui/Time';
import { Skeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { strings } from '@/shared/lib/strings';
import { cn } from '@/shared/lib/cn';
import { useAckAdvisory, useAdvisory, useConfirmClosed, useConfirmRestored, useDismissAdvisory } from './hooks';

const BANNER = {
  IMMEDIATE: 'border-danger bg-danger-soft text-danger',
  RECOMMENDED: 'border-warning bg-warning-soft text-warning',
  ADVISORY: 'border-line-strong bg-muted text-ink-2',
};

function Loading() {
  return (
    <div className="space-y-3">
      <Skeleton className="h-20 w-full" />
      {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-10 w-full" />)}
    </div>
  );
}

export function IsolationPanel({ eventId, pipeCode, woStatus }) {
  const query = useAdvisory(eventId);
  const advisory = query.data;
  const ack = useAckAdvisory(advisory?.id, eventId);
  const dismiss = useDismissAdvisory(advisory?.id, eventId);
  const closed = useConfirmClosed(advisory?.id, eventId);
  const restored = useConfirmRestored(advisory?.id, eventId);
  const [dialog, setDialog] = useState(null);

  if (query.isPending) return <Loading />;
  if (query.error) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;
  if (!advisory) return <EmptyState title="No isolation advisory for this event" />;

  const valves = advisory.isolation_advisory_valves ?? [];
  const closedCount = valves.filter((v) => v.close_confirmed_at).length;
  const live = ['OPEN', 'ACKNOWLEDGED'].includes(advisory.status);
  const canRestore = woStatus === 'COMPLETED' && advisory.status === 'ISOLATED';
  const bannerText = {
    IMMEDIATE: `Close these valves now to stop flow to ${pipeCode}`,
    RECOMMENDED: `Closing these valves is recommended for ${pipeCode}`,
    ADVISORY: `Advisory for ${pipeCode}`,
  }[advisory.urgency] ?? advisory.message;

  return (
    <div className="space-y-4" id="isolation">
      <div className={cn('flex flex-wrap items-center justify-between gap-4 rounded-md border p-4', BANNER[advisory.urgency] ?? BANNER.ADVISORY)}>
        <div className="flex items-start gap-3">
          <Octagon className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
          <div>
            <p className="font-semibold">{bannerText}</p>
            <p className="mt-1 text-sm text-ink">{advisory.message}</p>
          </div>
        </div>
        <div className="text-right">
          <p className="text-3xl font-semibold leading-none text-ink">{advisory.affected_connections ?? '—'}</p>
          <p className="text-xs text-ink-2">Affected connections</p>
        </div>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <StatusBadge domain="advisoryStatus" value={advisory.status} />
          <StatusBadge domain="urgency" value={advisory.urgency} />
          {valves.length > 0 && <span className="text-sm text-ink-2">{closedCount} of {valves.length} valves closed</span>}
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            disabled={advisory.status !== 'OPEN'}
            loading={ack.isPending}
            onClick={() => ack.mutate({ key: crypto.randomUUID(), expected_status: advisory.status })}
          >
            Acknowledge warning
          </Button>
          <Button variant="dangerOutline" disabled={!live} onClick={() => setDialog({ type: 'dismiss' })}>Dismiss</Button>
        </div>
      </div>

      {valves.length === 0 ? (
        <div className="flex items-center gap-2 rounded-md border border-warning bg-warning-soft p-3 text-sm text-warning">
          <TriangleAlert className="size-4" aria-hidden="true" />
          {strings.noValve}
        </div>
      ) : (
        <Card className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-line text-xs text-ink-2">
                {['Valve', 'Kind', 'State', 'Close', 'Restore'].map((h) => <th key={h} scope="col" className="px-4 py-2.5 font-medium">{h}</th>)}
              </tr>
            </thead>
            <tbody>
              {valves.map((v) => (
                <tr key={v.valve_id} className="border-b border-line last:border-0">
                  <td className="px-4 py-3 font-semibold">{v.valves?.code}</td>
                  <td className="px-4 py-3 text-ink-2">{v.valves?.kind ?? '—'}</td>
                  <td className="px-4 py-3"><StatusBadge domain="valveState" value={v.valves?.state} /></td>
                  <td className="px-4 py-3">
                    {v.close_confirmed_at ? (
                      <span className="text-xs text-ink-2"><Time value={v.close_confirmed_at} />{v.closer?.full_name && ` · ${v.closer.full_name}`}</span>
                    ) : (
                      <Button variant="outline" disabled={!live} onClick={() => setDialog({ type: 'close', valve: v })}>Confirm closed</Button>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {v.restore_confirmed_at ? (
                      <span className="text-xs text-ink-2"><Time value={v.restore_confirmed_at} />{v.restorer?.full_name && ` · ${v.restorer.full_name}`}</span>
                    ) : (
                      <Button variant="outline" disabled={!canRestore || !v.close_confirmed_at} onClick={() => setDialog({ type: 'restore', valve: v })}>Confirm reopened</Button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}
      {valves.length > 0 && !canRestore && advisory.status === 'ISOLATED' && (
        <Chip tone="grey">Restore unlocks after the work order is completed</Chip>
      )}

      <ConfirmDialog
        open={dialog?.type === 'close'}
        onClose={() => setDialog(null)}
        title="Confirm valve closed"
        description={`Confirm that ${dialog?.valve?.valves?.code} is physically closed.`}
        confirmLabel="Confirm closed"
        onConfirm={({ key }) => closed.mutateAsync({ key, valveId: dialog.valve.valve_id })}
      />
      <ConfirmDialog
        open={dialog?.type === 'restore'}
        onClose={() => setDialog(null)}
        title="Confirm valve reopened"
        description={`Confirm that ${dialog?.valve?.valves?.code} has been reopened.`}
        confirmLabel="Confirm reopened"
        onConfirm={({ key }) => restored.mutateAsync({ key, valveId: dialog.valve.valve_id })}
      />
      <ReasonDialog
        open={dialog?.type === 'dismiss'}
        onClose={() => setDialog(null)}
        title="Dismiss advisory"
        description="The affected area stays supplied. Say why isolation is not needed."
        reasonLabel="Reason"
        confirmLabel="Dismiss"
        tone="danger"
        onConfirm={({ key, reason }) => dismiss.mutateAsync({ key, reason, expected_status: advisory.status })}
      />
    </div>
  );
}
