import { lazy, Suspense, useEffect, useMemo } from 'react';
import { Activity, RefreshCw, TriangleAlert } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/shared/api/client';
import { useCriticalAlert } from '@/features/alerts/CriticalAlertContext';
import { Card, CardHeader } from '@/shared/ui/Card';
import { KpiCard } from '@/shared/ui/KpiCard';
import { ErrorState, EmptyState } from '@/shared/ui/States';
import { StatusBadge, SourceBadge } from '@/shared/ui/Badges';
import { lineToLatLngs, pointToLatLng } from '@/shared/lib/geo';

const MapView = lazy(() => import('@/shared/map/MapView'));

const fmtTime = (value) =>
  value ? new Date(value).toLocaleString() : 'Waiting for first twin reading';

export default function PublicDashboardPage() {
  const { triggerAlert } = useCriticalAlert();
  const query = useQuery({
    queryKey: ['public-demo-dashboard'],
    queryFn: () => api.get('/v1/demo/dashboard'),
    refetchInterval: 2_000,
    staleTime: 1_000,
  });
  const data = query.data;

  // React to critical events from the digital twin public feed
  useEffect(() => {
    if (!data) return;
    const criticalEvent = (data.events ?? []).find(
      (e) => e.severity === 'CRITICAL' || (typeof e.severity_score === 'number' && e.severity_score >= 0.8)
    );
    if (criticalEvent) {
      triggerAlert(criticalEvent);
    } else if ((data.open_events_by_severity?.CRITICAL ?? 0) > 0) {
      triggerAlert({
        id: 'open-demo-critical',
        event_no: 'CRITICAL TWIN EVENT',
        pipe_code: 'Twin Network',
        severity: 'CRITICAL',
        severity_score: 1.0,
      });
    }
  }, [data, triggerAlert]);

  const mapped = useMemo(() => {
    const pipes = [];
    const nodes = [];
    const valves = [];
    for (const feature of data?.network?.features ?? []) {
      const properties = feature.properties ?? {};
      if (properties.feature_type === 'PIPE') {
        pipes.push({ ...properties, id: properties.code, latlngs: lineToLatLngs(feature.geometry) });
      } else if (properties.feature_type === 'NODE') {
        nodes.push({ ...properties, node_kind: properties.kind, latlng: pointToLatLng(feature.geometry) });
      } else if (properties.feature_type === 'VALVE') {
        valves.push({ ...properties, latlng: pointToLatLng(feature.geometry) });
      }
    }
    return { pipes, nodes, valves };
  }, [data?.network]);

  if (query.isPending) {
    return (
      <main className="min-h-full p-6">
        <header className="mx-auto mb-6 max-w-[1440px]">
          <h1 className="text-2xl font-semibold text-primary">AquaPulse Operations</h1>
          <p className="text-sm text-ink-2">Connecting to the digital twin…</p>
        </header>
        <div className="mx-auto max-w-[1440px]"><Card><div className="p-8 text-center">Loading live network data…</div></Card></div>
      </main>
    );
  }

  if (query.error) {
    return (
      <main className="min-h-full p-6">
        <div className="mx-auto max-w-2xl">
          <h1 className="mb-4 text-2xl font-semibold text-primary">AquaPulse Operations</h1>
          <Card>
            <ErrorState
              error={query.error}
              title="Could not load digital-twin data"
              onRetry={() => query.refetch()}
            />
          </Card>
        </div>
      </main>
    );
  }

  const events = data.events ?? [];
  const signals = data.signals ?? [];
  const signalByPipe = new Map(signals.map((signal) => [signal.pipe_code, signal]));
  const attentionCodes = new Set([
    ...mapped.pipes.filter((pipe) => ['WARNING', 'LEAK'].includes(pipe.state)).map((pipe) => pipe.code),
    ...signals.filter((signal) => Number(signal.injected_leak_lpm) > 0).map((signal) => signal.pipe_code),
  ]);
  const activePipes = mapped.pipes.filter((pipe) => attentionCodes.has(pipe.code));
  const latestReading = signals.reduce((latest, signal) => {
    if (!signal.ts) return latest;
    return !latest || new Date(signal.ts) > new Date(latest) ? signal.ts : latest;
  }, null);
  const severeCount = events.filter((event) => ['MAJOR', 'CRITICAL'].includes(event.severity)).length;
  const bySeverity = data.open_events_by_severity ?? {};
  const openCount = Object.values(bySeverity).reduce((sum, count) => sum + count, 0);

  return (
    <main className="min-h-full bg-app p-4 sm:p-6">
      <div className="mx-auto max-w-[1600px] space-y-5">
        <header className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <Activity className="size-6 text-primary" aria-hidden="true" />
              <h1 className="text-2xl font-semibold text-primary">AquaPulse Operations</h1>
            </div>
            <p className="mt-1 text-sm text-ink-2">
              Public live monitoring · no sign-in required · updates every 2 seconds
            </p>
          </div>
          <div className="flex items-center gap-3">
            <span className="flex items-center gap-2 text-xs font-medium text-success" role="status">
              <span className="size-2 rounded-full bg-success" />
              {query.isFetching ? 'Updating' : 'Live'}
            </span>
            <button
              type="button"
              onClick={() => query.refetch()}
              aria-label="Refresh dashboard"
              className="flex size-9 items-center justify-center rounded-md border border-line-strong bg-surface hover:bg-muted"
            >
              <RefreshCw className="size-4" />
            </button>
          </div>
        </header>

        <section className="grid grid-cols-2 gap-3 lg:grid-cols-4" aria-label="Twin summary">
          <KpiCard label="Open twin events" value={openCount} />
          <KpiCard label="Major / critical" value={severeCount} />
          <KpiCard label="Warning / leak / injected pipes" value={activePipes.length} />
          <KpiCard label="Latest twin reading" value={fmtTime(latestReading)} />
        </section>

        <section className="grid gap-4 xl:grid-cols-[minmax(0,1.6fr)_minmax(340px,0.8fr)]">
          <Card className="relative h-[480px] overflow-hidden sm:h-[620px]">
            <CardHeader title="Digital-twin network" fetching={query.isFetching} />
            <div className="h-[calc(100%-56px)]">
              {mapped.pipes.length ? (
                <Suspense fallback={<div className="p-6">Loading map…</div>}>
                  <MapView
                    {...mapped}
                    events={events}
                    popup={false}
                    legend
                  />
                </Suspense>
              ) : (
                <EmptyState title="No network data" className="h-full" />
              )}
            </div>
          </Card>

          <Card className="flex h-[480px] min-h-0 flex-col sm:h-[620px]">
            <CardHeader title="Twin warnings and leak events" fetching={query.isFetching} />
            <div className="min-h-0 flex-1 space-y-3 overflow-y-auto p-4 pt-2">
              {!activePipes.length && !events.length ? (
                <EmptyState icon={TriangleAlert} title="No open twin warnings">
                  Twin warning states and confirmed leak events will appear here.
                </EmptyState>
              ) : (
                <>
                  {activePipes.map((pipe) => {
                    const signal = signalByPipe.get(pipe.code);
                    const injectedLeak = Number(signal?.injected_leak_lpm) || 0;
                    return (
                      <article key={`pipe-${pipe.code}`} className="rounded-md border border-line p-3">
                        <div className="flex flex-wrap items-center gap-2">
                          {injectedLeak > 0 ? (
                            <span className="rounded-full bg-danger-soft px-2 py-0.5 text-xs font-medium text-danger">
                              Simulated leak
                            </span>
                          ) : <StatusBadge domain="pipeState" value={pipe.state} />}
                          <span className="font-semibold">Pipe {pipe.code}</span>
                        </div>
                        <p className="mt-2 text-xs text-ink-2">
                          {injectedLeak > 0
                            ? `Twin injection: ${injectedLeak.toFixed(1)} L/min`
                            : signal?.ts ? `Latest reading: ${fmtTime(signal.ts)}` : 'Waiting for the next twin reading'}
                        </p>
                      </article>
                    );
                  })}
                  {events.map((event) => (
                    <article key={event.id} className="rounded-md border border-line p-3">
                      <div className="flex flex-wrap items-center gap-2">
                        <StatusBadge domain="severity" value={event.severity} />
                        <span className="font-semibold">{event.event_no}</span>
                        <SourceBadge source={event.source} />
                      </div>
                      <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-ink-2">
                        <span>Pipe {event.pipe_code}</span>
                        <StatusBadge domain="eventStatus" value={event.status} />
                        <span>{fmtTime(event.detected_at)}</span>
                      </div>
                      <p className="mt-2 text-sm">
                        Estimated leak: {Number(event.est_leak_rate_lpm ?? 0).toFixed(1)} L/min
                        {event.est_loss_pct != null && ` · ${Number(event.est_loss_pct).toFixed(1)}% loss`}
                      </p>
                    </article>
                  ))}
                </>
              )}
            </div>
          </Card>
        </section>

        <Card>
          <CardHeader title="Latest simulated-pipe readings" fetching={query.isFetching} />
          <div className="overflow-x-auto p-4 pt-2">
            <table className="w-full min-w-[650px] text-left text-sm">
              <thead className="border-b border-line text-xs text-ink-2">
                <tr>
                  <th className="py-2 pr-4 font-medium">Pipe</th>
                  <th className="py-2 pr-4 font-medium">State</th>
                  <th className="py-2 pr-4 font-medium">Flow in</th>
                  <th className="py-2 pr-4 font-medium">Flow out</th>
                  <th className="py-2 pr-4 font-medium">Pressure in</th>
                  <th className="py-2 font-medium">Last reading</th>
                </tr>
              </thead>
              <tbody>
                {signals.map((signal) => (
                  <tr key={signal.pipe_code} className="border-b border-line last:border-0">
                    <td className="py-2.5 pr-4 font-medium">{signal.pipe_code}</td>
                    <td className="py-2.5 pr-4"><StatusBadge domain="pipeState" value={signal.pipe_state} /></td>
                    <td className="py-2.5 pr-4">{signal.flow_in_lpm == null ? '—' : `${Number(signal.flow_in_lpm).toFixed(1)} L/min`}</td>
                    <td className="py-2.5 pr-4">{signal.flow_out_lpm == null ? '—' : `${Number(signal.flow_out_lpm).toFixed(1)} L/min`}</td>
                    <td className="py-2.5 pr-4">{signal.pressure_in_kpa == null ? '—' : `${Number(signal.pressure_in_kpa).toFixed(1)} kPa`}</td>
                    <td className="py-2.5 text-xs text-ink-2">{signal.ts ? fmtTime(signal.ts) : 'Waiting for reading'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </main>
  );
}
