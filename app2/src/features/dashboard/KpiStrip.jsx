import { KpiCard } from '@/shared/ui/KpiCard';
import { SEVERITIES, getStatus } from '@/shared/lib/statusMap';
import { fmtMinutes } from '@/shared/lib/time';
import { useAwaitingApprovalCount, useOpenAdvisoryCount } from '@/shared/data/counts';
import { useSummary } from './hooks';

function SeverityBars({ counts }) {
  const total = Object.entries(counts).filter(([k]) => k !== 'NONE').reduce((a, [, v]) => a + v, 0) || 1;
  return (
    <div className="mt-2 flex h-1.5 overflow-hidden rounded-full bg-muted" role="img" aria-label="Open events by severity">
      {SEVERITIES.filter((s) => s !== 'NONE').map((s) => (
        <span key={s} style={{ width: `${((counts[s] ?? 0) / total) * 100}%`, background: getStatus('severity', s).color }} />
      ))}
    </div>
  );
}

export function KpiStrip() {
  const summary = useSummary();
  const advisories = useOpenAdvisoryCount();
  const approvals = useAwaitingApprovalCount();
  const bySeverity = summary.data?.open_events_by_severity ?? {};
  const open = Object.entries(bySeverity).filter(([k]) => k !== 'NONE').reduce((a, [, v]) => a + v, 0);

  return (
    <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
      <KpiCard label="Open events" value={open} loading={summary.isPending} error={summary.error} onRetry={() => summary.refetch()}>
        <SeverityBars counts={bySeverity} />
      </KpiCard>
      <KpiCard label="Isolation actions pending" value={advisories.data} loading={advisories.isPending} error={advisories.error} onRetry={() => advisories.refetch()} />
      <KpiCard label="Awaiting approval" value={approvals.data} loading={approvals.isPending} error={approvals.error} onRetry={() => approvals.refetch()} />
      <KpiCard
        label="Devices online"
        value={`${summary.data?.devices_online ?? 0}/${summary.data?.devices_total ?? 0}`}
        loading={summary.isPending}
        error={summary.error}
        onRetry={() => summary.refetch()}
      />
      <KpiCard
        label="Mean time to repair"
        value={fmtMinutes(summary.data?.mean_time_to_repair_minutes)}
        loading={summary.isPending}
        error={summary.error}
        onRetry={() => summary.refetch()}
      />
    </div>
  );
}
