import { Suspense, lazy, useState } from 'react';
import { Link } from 'react-router-dom';
import { X } from 'lucide-react';
import { SourceBadge, StatusBadge } from '@/shared/ui/Badges';
import { Tabs } from '@/shared/ui/Tabs';
import { Timeline } from '@/shared/ui/Timeline';
import { ChartSkeleton, DrawerSkeleton, ListSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { signalFor, sourceOf, usePipeHistory } from '@/shared/data/network';
import { fmtKpa, fmtLpm, humanize } from '@/shared/lib/format';
import { Time } from '@/shared/ui/Time';

const PipeSignals = lazy(() => import('@/shared/ui/PipeSignals'));
const TABS = [{ id: 'overview', label: 'Overview' }, { id: 'signals', label: 'Signals' }, { id: 'history', label: 'History' }];

function Overview({ pipe, signals, event }) {
  const s = signalFor(signals, pipe);
  const rows = [
    ['Diameter', pipe.diameter_mm ? `${pipe.diameter_mm} mm` : '—'],
    ['Material', pipe.material ?? '—'],
    ['Install year', pipe.install_year ?? '—'],
    ['Flow in', fmtLpm(s?.flow_in_lpm)],
    ['Flow out', fmtLpm(s?.flow_out_lpm)],
    ['Pressure in', fmtKpa(s?.pressure_in_kpa)],
    ['Pressure out', fmtKpa(s?.pressure_out_kpa)],
  ];
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2">
        <StatusBadge domain="pipeState" value={pipe.state} />
        <SourceBadge source={sourceOf(pipe)} />
        <span className="text-xs text-ink-2">Monitoring: {humanize(pipe.monitoring)}</span>
      </div>
      {event && (
        <Link to={`/events/${event.id}`} className="block rounded-md border border-danger/30 bg-danger-soft px-3 py-2 text-sm font-medium text-danger">
          Active event {event.event_no}
        </Link>
      )}
      <dl className="divide-y divide-line">
        {rows.map(([k, v]) => (
          <div key={k} className="flex justify-between py-2 text-sm">
            <dt className="text-ink-2">{k}</dt>
            <dd className="font-medium">{v}</dd>
          </div>
        ))}
      </dl>
      {s?.ts && <p className="text-xs text-ink-3">Last reading <Time value={s.ts} relative /></p>}
    </div>
  );
}

function History({ pipeId }) {
  const q = usePipeHistory(pipeId);
  if (q.isPending) return <ListSkeleton rows={4} />;
  if (q.error) return <ErrorState error={q.error} onRetry={() => q.refetch()} />;
  if (!q.data.length) return <EmptyState title="No state changes yet" />;
  return (
    <Timeline
      items={q.data.map((h) => ({
        id: h.id,
        title: `${humanize(h.from_state)} → ${humanize(h.to_state)}`,
        meta: [h.reason, h.changed_by_kind && humanize(h.changed_by_kind)].filter(Boolean).join(' · '),
        time: h.changed_at,
      }))}
    />
  );
}

export function PipeDrawer({ pipe, signals, event, onClose }) {
  const [tab, setTab] = useState('overview');
  return (
    <aside className="flex h-full w-[360px] shrink-0 flex-col border-l border-line bg-surface" aria-label={`Pipe ${pipe.code}`}>
      <header className="flex items-center justify-between border-b border-line px-4 py-3">
        <h2 className="text-base font-semibold">Pipe {pipe.code}</h2>
        <button type="button" onClick={onClose} aria-label="Close drawer" className="rounded-sm p-1 text-ink-2 hover:bg-muted">
          <X className="size-4" />
        </button>
      </header>
      <Tabs tabs={TABS} value={tab} onChange={setTab} className="px-2" />
      <div className="min-h-0 flex-1 overflow-y-auto p-4">
        {!pipe.id ? <DrawerSkeleton /> : tab === 'overview' ? (
          <Overview pipe={pipe} signals={signals} event={event} />
        ) : tab === 'signals' ? (
          <Suspense fallback={<ChartSkeleton />}>
            <PipeSignals pipeId={pipe.id} source={sourceOf(pipe)} simulated={pipe.monitoring === 'SIMULATED'} />
          </Suspense>
        ) : (
          <History pipeId={pipe.id} />
        )}
      </div>
    </aside>
  );
}
