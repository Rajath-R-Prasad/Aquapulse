import { Link } from 'react-router-dom';
import { CircleCheck, Octagon } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/Card';
import { SourceBadge, StatusBadge } from '@/shared/ui/Badges';
import { SlaTimer } from '@/shared/ui/SlaTimer';
import { EventCardSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { strings } from '@/shared/lib/strings';

export function ActiveEventsPanel({ query }) {
  const events = query.data ?? [];
  const urgent = events.filter((e) => e.advisory_status === 'OPEN' && e.advisory_urgency === 'IMMEDIATE');

  return (
    <Card className="flex h-full min-h-0 flex-col">
      <CardHeader title="Needs attention" fetching={query.isFetching && !query.isPending} />
      {urgent.length > 0 && (
        <Link
          to={`/events/${urgent[0].id}#isolation`}
          className="mx-4 mb-2 flex items-center gap-2 rounded-md bg-danger px-3 py-2 text-sm font-semibold text-white"
        >
          <Octagon className="size-4" aria-hidden="true" />
          Close valves now
          <span className="ml-auto rounded-full bg-white/20 px-2 text-xs">{urgent.length}</span>
        </Link>
      )}
      <div className="min-h-0 flex-1 space-y-2 overflow-y-auto px-4 pb-4">
        {query.isPending ? (
          Array.from({ length: 4 }).map((_, i) => <EventCardSkeleton key={i} />)
        ) : query.error ? (
          <ErrorState error={query.error} onRetry={() => query.refetch()} />
        ) : events.length === 0 ? (
          <EmptyState icon={CircleCheck} title={strings.empty.attention} />
        ) : (
          events.map((e) => (
            <Link key={e.id} to={`/events/${e.id}`} className="block rounded-md border border-line p-3 transition-colors hover:bg-muted">
              <div className="flex flex-wrap items-center gap-2">
                <StatusBadge domain="severity" value={e.severity} />
                <span className="font-semibold">{e.event_no}</span>
                {e.is_simulated && <SourceBadge simulated />}
              </div>
              <div className="mt-2 flex flex-wrap items-center justify-between gap-2 text-xs text-ink-2">
                <span>Pipe {e.pipe_code}</span>
                <StatusBadge domain="eventStatus" value={e.status} />
                <SlaTimer due={e.sla_due_at} />
              </div>
            </Link>
          ))
        )}
      </div>
    </Card>
  );
}
