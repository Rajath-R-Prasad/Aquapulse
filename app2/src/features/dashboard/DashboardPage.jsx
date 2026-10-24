import { Suspense, lazy, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card } from '@/shared/ui/Card';
import { MapSkeleton } from '@/shared/ui/Skeletons';
import { ErrorState, StillLoading } from '@/shared/ui/States';
import { useOpenEvents } from '@/shared/data/events';
import { usePipeMap, useSignalLatest } from '@/shared/data/network';
import { useLiveSignals } from '@/shared/supabase/realtime';
import { KpiStrip } from './KpiStrip';
import { ActiveEventsPanel } from './ActiveEventsPanel';

const MapView = lazy(() => import('@/shared/map/MapView'));

export default function DashboardPage() {
  useLiveSignals();
  const navigate = useNavigate();
  const network = usePipeMap();
  const events = useOpenEvents();
  const signals = useSignalLatest();
  const eventList = useMemo(() => events.data ?? [], [events.data]);

  return (
    <div className="space-y-4">
      <KpiStrip />
      <div className="grid gap-4 lg:grid-cols-[65fr_35fr]">
        <Card className="relative h-[560px] overflow-hidden">
          {network.error ? (
            <ErrorState error={network.error} onRetry={() => network.refetch()} title="Could not load the map" className="h-full" />
          ) : network.isPending ? (
            <>
              <MapSkeleton />
              <div className="absolute inset-x-0 bottom-2"><StillLoading active onRetry={() => network.refetch()} /></div>
            </>
          ) : (
            <Suspense fallback={<MapSkeleton />}>
              <MapView
                pipes={network.pipes}
                nodes={network.nodes}
                valves={network.valves}
                events={eventList}
                signals={signals.data}
                popup
                legend
                onSelectEvent={(e) => navigate(`/events/${e.id}`)}
              />
            </Suspense>
          )}
        </Card>
        <div className="h-[560px]">
          <ActiveEventsPanel query={events} />
        </div>
      </div>
    </div>
  );
}
