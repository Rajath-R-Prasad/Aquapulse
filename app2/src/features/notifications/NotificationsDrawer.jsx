import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Ban, Bell, ClipboardCheck, ClipboardX, Octagon, Siren, TriangleAlert, UserCheck, WifiOff } from 'lucide-react';
import { Overlay } from '@/shared/ui/Overlay';
import { Button } from '@/shared/ui/Button';
import { Time } from '@/shared/ui/Time';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { ListSkeleton } from '@/shared/ui/Skeletons';
import { dayKey } from '@/shared/lib/time';
import { strings } from '@/shared/lib/strings';
import { cn } from '@/shared/lib/cn';
import { useMarkRead, useNotifications } from './hooks';

const ICONS = {
  LEAK_DETECTED: TriangleAlert,
  SEVERITY_ESCALATED: Siren,
  ISOLATION_ADVISORY: Octagon,
  WO_ASSIGNED: UserCheck,
  WO_SUBMITTED: ClipboardCheck,
  WO_APPROVED: ClipboardCheck,
  WO_REJECTED: ClipboardX,
  DEVICE_OFFLINE: WifiOff,
};

function target(n) {
  const p = n.payload ?? {};
  if (['LEAK_DETECTED', 'SEVERITY_ESCALATED', 'ISOLATION_ADVISORY'].includes(n.type) && p.leak_event_id) return `/events/${p.leak_event_id}`;
  if (n.type.startsWith('WO_') && p.work_order_id) return `/work-orders/${p.work_order_id}`;
  if (n.type === 'DEVICE_OFFLINE') return '/map';
  return null;
}

export default function NotificationsDrawer({ open, onClose }) {
  const query = useNotifications();
  const { markOne, markAll } = useMarkRead();
  const navigate = useNavigate();
  const [busy, setBusy] = useState(false);
  const items = query.data?.items ?? [];
  const unread = items.filter((n) => !n.read_at);
  const today = dayKey(new Date());
  const groups = [
    ['Today', items.filter((n) => dayKey(n.created_at) === today)],
    ['Earlier', items.filter((n) => dayKey(n.created_at) !== today)],
  ].filter(([, list]) => list.length);

  const openItem = async (n) => {
    const to = target(n);
    if (!n.read_at) markOne(n.id);
    onClose();
    if (to) navigate(to);
  };

  return (
    <Overlay
      open={open}
      onClose={onClose}
      side="right"
      title="Notifications"
      footer={
        <Button
          variant="outline"
          disabled={!unread.length}
          loading={busy}
          onClick={async () => { setBusy(true); await markAll(unread.map((n) => n.id)); setBusy(false); }}
        >
          Mark all read
        </Button>
      }
    >
      {query.isPending ? <ListSkeleton rows={5} /> : query.error ? (
        <ErrorState error={query.error} onRetry={() => query.refetch()} />
      ) : items.length === 0 ? (
        <EmptyState icon={Bell} title={strings.empty.notifications} />
      ) : (
        groups.map(([label, list]) => (
          <section key={label} className="mb-4">
            <h3 className="mb-2 text-xs font-medium text-ink-3">{label}</h3>
            <ul className="space-y-1">
              {list.map((n) => {
                const Icon = ICONS[n.type] ?? Ban;
                return (
                  <li key={n.id}>
                    <button type="button" onClick={() => openItem(n)} className="flex w-full items-start gap-3 rounded-md p-2 text-left hover:bg-muted">
                      <span className="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full bg-primary-soft text-primary">
                        <Icon className="size-4" aria-hidden="true" />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className={cn('block text-sm', !n.read_at && 'font-semibold')}>{n.title}</span>
                        {n.body && <span className="block truncate text-xs text-ink-2">{n.body}</span>}
                        <Time value={n.created_at} relative className="text-xs text-ink-3" />
                      </span>
                      {!n.read_at && <span className="mt-2 size-2 shrink-0 rounded-full bg-primary" aria-label="Unread" />}
                    </button>
                  </li>
                );
              })}
            </ul>
          </section>
        ))
      )}
    </Overlay>
  );
}
