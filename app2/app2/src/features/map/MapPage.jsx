import { Suspense, lazy, useMemo } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { MapSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState, StillLoading } from '@/shared/ui/States';
import { MultiSelect, Segmented } from '@/shared/ui/FormControls';
import { useOpenEvents } from '@/shared/data/events';
import { usePipeMap, useSignalLatest } from '@/shared/data/network';
import { useLiveSignals } from '@/shared/supabase/realtime';
import { PIPE_STATES, getStatus } from '@/shared/lib/statusMap';
import { strings } from '@/shared/lib/strings';
import { PipeDrawer } from './PipeDrawer';

const MapView = lazy(() => import('@/shared/map/MapView'));
const SOURCES = [{ value: 'ALL', label: 'All' }, { value: 'HARDWARE', label: 'Live sensor' }, { value: 'SIMULATED', label: 'Simulated' }];
const STATE_OPTIONS = PIPE_STATES.map((s) => ({ value: s, label: getStatus('pipeState', s).label }));

export default function MapPage() {
  useLiveSignals();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();
  const network = usePipeMap();
  const events = useOpenEvents();
  const signals = useSignalLatest();

  const selectedCode = params.get('pipe');
  const source = params.get('source') ?? 'ALL';
  const states = useMemo(() => (params.get('states') ?? '').split(',').filter(Boolean), [params]);

  const update = (patch) => {
    const next = new URLSearchParams(params);
    Object.entries(patch).forEach(([k, v]) => (v ? next.set(k, v) : next.delete(k)));
    setParams(next, { replace: true });
  };

  const pipes = useMemo(
    () => network.pipes.filter((p) => (source === 'ALL' || p.monitoring === source) && (!states.length || states.includes(p.state))),
    [network.pipes, source, states],
  );
  const selected = network.byCode.get(selectedCode) ?? null;
  const eventList = useMemo(() => events.data ?? [], [events.data]);
  const selectedEvent = eventList.find((e) => e.pipe_code === selectedCode);

  if (network.error) return <ErrorState error={network.error} onRetry={() => network.refetch()} title="Could not load the network" className="h-full" />;

  return (
    <div className="flex h-full">
      <div className="relative min-w-0 flex-1">
        {network.isPending ? (
          <>
            <MapSkeleton />
            <div className="absolute inset-x-0 bottom-4"><StillLoading active onRetry={() => network.refetch()} /></div>
          </>
        ) : network.pipes.length === 0 ? (
          <EmptyState title={strings.empty.network} className="h-full" />
        ) : (
          <>
            <Suspense fallback={<MapSkeleton />}>
              <MapView
                pipes={pipes}
                nodes={network.nodes}
                valves={network.valves}
                events={eventList}
                signals={signals.data}
                selectedCode={selectedCode}
                onSelectPipe={(p) => update({ pipe: p.code })}
                onSelectEvent={(e) => navigate(`/events/${e.id}`)}
                legend
              />
            </Suspense>
            <div className="absolute left-3 top-3 z-10 flex flex-wrap items-center gap-2 rounded-md border border-line bg-surface/95 p-2 shadow-sm">
              <Segmented label="Source" value={source} onChange={(v) => update({ source: v === 'ALL' ? '' : v })} options={SOURCES} />
              <MultiSelect label="State" options={STATE_OPTIONS} value={states} onChange={(v) => update({ states: v.join(',') })} />
            </div>
          </>
        )}
      </div>
      {selectedCode && (
        <PipeDrawer
          key={selectedCode}
          pipe={selected ?? { code: selectedCode }}
          signals={signals.data}
          event={selectedEvent}
          onClose={() => update({ pipe: '' })}
        />
      )}
    </div>
  );
}
