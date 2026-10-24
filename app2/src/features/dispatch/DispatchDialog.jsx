import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Info, TriangleAlert } from 'lucide-react';
import { Overlay } from '@/shared/ui/Overlay';
import { ConfirmDialog } from '@/shared/ui/ConfirmDialog';
import { Chip, StatusBadge } from '@/shared/ui/Badges';
import { CandidateSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { fmtKm } from '@/shared/lib/format';
import { strings } from '@/shared/lib/strings';
import { useAssign, useCandidates } from './hooks';

export default function DispatchDialog({ open, onClose, eventId, workOrder, advisory }) {
  const query = useCandidates(eventId, open);
  const assign = useAssign(workOrder?.id, eventId);
  const [pick, setPick] = useState(null);
  const candidates = query.data ?? [];
  const notIsolated = advisory && ['OPEN', 'ACKNOWLEDGED'].includes(advisory.status) && advisory.urgency === 'IMMEDIATE';

  return (
    <>
      <Overlay open={open} onClose={onClose} side="right" title="Assign engineer">
        <div className="space-y-3">
          <p className="flex items-center gap-1.5 text-xs text-ink-2">
            <Info className="size-4 shrink-0" aria-hidden="true" />
            <span title={strings.rankingInfo}>{strings.rankingInfo}</span>
          </p>
          {notIsolated && (
            <Chip tone="warning" icon={TriangleAlert} className="whitespace-normal">Valves are not yet isolated</Chip>
          )}
          {query.isPending ? <CandidateSkeleton /> : query.error ? (
            <ErrorState error={query.error} onRetry={() => query.refetch()} />
          ) : candidates.length === 0 ? (
            <EmptyState title={strings.empty.dispatch}>
              <Link to="/engineers" onClick={onClose} className="text-primary underline">View engineers</Link>
            </EmptyState>
          ) : (
            <ol className="space-y-2">
              {candidates.map((c, i) => (
                <li key={c.engineer_id} className="rounded-md border border-line p-3">
                  <div className="flex items-center gap-3">
                    <span className="flex size-6 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-semibold">{i + 1}</span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-medium">{c.full_name}</p>
                      <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-ink-2">
                        <StatusBadge domain="engineerStatus" value={c.status} />
                        <span>{fmtKm(c.distance_m)}</span>
                        <span>{c.active_jobs} active {c.active_jobs === 1 ? 'job' : 'jobs'}</span>
                        <Chip tone={c.has_skill ? 'success' : 'grey'}>{c.has_skill ? 'Skill match' : 'No skill match'}</Chip>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => setPick(c)}
                      className="h-8 rounded-md bg-primary px-3 text-sm font-medium text-white hover:bg-primary-hover"
                    >
                      Assign
                    </button>
                  </div>
                  <div className="mt-2 flex items-center gap-2">
                    <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-muted" role="meter" aria-valuemin={0} aria-valuemax={1} aria-valuenow={c.score} aria-label="Score">
                      <div className="h-full bg-primary" style={{ width: `${Math.round(c.score * 100)}%` }} />
                    </div>
                    <span className="w-10 text-right text-xs text-ink-2">{Number(c.score).toFixed(2)}</span>
                  </div>
                </li>
              ))}
            </ol>
          )}
        </div>
      </Overlay>

      <ConfirmDialog
        open={!!pick}
        onClose={() => setPick(null)}
        title="Assign engineer"
        description={`Assign ${pick?.full_name} to ${workOrder?.wo_no}?`}
        confirmLabel="Assign"
        onConfirm={async ({ key }) => {
          await assign.mutateAsync({ key, engineerId: pick.engineer_id, expectedStatus: workOrder?.status });
          onClose();
        }}
      />
    </>
  );
}
