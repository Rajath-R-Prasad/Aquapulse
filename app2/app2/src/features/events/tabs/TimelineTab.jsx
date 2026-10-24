import { Card } from '@/shared/ui/Card';
import { Timeline } from '@/shared/ui/Timeline';
import { ListSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { humanize } from '@/shared/lib/format';
import { useEventLog } from '../hooks';

const ACTORS = { USER: 'User', SYSTEM: 'System', DEVICE: 'Device', TWIN: 'Twin' };

export function TimelineTab({ eventId, entityIds }) {
  const q = useEventLog(eventId, entityIds);
  if (q.isPending) return <Card className="p-4"><ListSkeleton rows={5} /></Card>;
  if (q.error) return <Card><ErrorState error={q.error} onRetry={() => q.refetch()} /></Card>;

  const items = [
    ...q.data.log.map((l) => ({
      id: `l${l.id}`,
      title: humanize(l.action),
      meta: [l.from_status && l.to_status ? `${humanize(l.from_status)} → ${humanize(l.to_status)}` : null, ACTORS[l.actor_kind] ?? l.actor_kind, humanize(l.entity_type)].filter(Boolean).join(' · '),
      time: l.created_at,
    })),
    ...q.data.history.map((h) => ({
      id: `h${h.id}`,
      title: `Pipe ${humanize(h.from_state)} → ${humanize(h.to_state)}`,
      meta: [h.reason, ACTORS[(h.changed_by_kind ?? '').toUpperCase()] ?? h.changed_by_kind].filter(Boolean).join(' · '),
      time: h.changed_at,
    })),
  ].sort((a, b) => new Date(b.time) - new Date(a.time));

  return (
    <Card className="p-4">
      {items.length ? <Timeline items={items} /> : <EmptyState title="No activity recorded yet" />}
    </Card>
  );
}
