import { Suspense, lazy, useEffect, useMemo, useRef, useState } from 'react';
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom';
import { ChevronLeft } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { SourceBadge, StatusBadge } from '@/shared/ui/Badges';
import { ReasonDialog } from '@/shared/ui/ConfirmDialog';
import { CopyableCode } from '@/shared/ui/CopyableCode';
import { Menu } from '@/shared/ui/FormControls';
import { SlaTimer } from '@/shared/ui/SlaTimer';
import { Stepper } from '@/shared/ui/Stepper';
import { Tabs } from '@/shared/ui/Tabs';
import { BlockSkeleton, HeaderSkeleton, MapSkeleton, StepperSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { usePipeMap } from '@/shared/data/network';
import { lineToLatLngs, pointToLatLng } from '@/shared/lib/geo';
import { fmtNum, humanize } from '@/shared/lib/format';
import { fmtIST } from '@/shared/lib/time';
import { useCancelWorkOrder } from '@/features/workorders/hooks';
import { IsolationPanel } from '@/features/isolation/IsolationPanel';
import { useAdvisory } from '@/features/isolation/hooks';
import DispatchDialog from '@/features/dispatch/DispatchDialog';
import { useAcknowledgeEvent, useEvent, useFalseAlarm } from './hooks';
import { OverviewTab } from './tabs/OverviewTab';
import { SignalsTab } from './tabs/SignalsTab';
import { WorkOrderTab } from './tabs/WorkOrderTab';
import { TimelineTab } from './tabs/TimelineTab';

const MapView = lazy(() => import('@/shared/map/MapView'));
const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'signals', label: 'Signals' },
  { id: 'isolation', label: 'Isolation' },
  { id: 'workorder', label: 'Work order' },
  { id: 'timeline', label: 'Timeline' },
];

const WO_DISPATCHED = ['ASSIGNED', 'ACCEPTED', 'EN_ROUTE', 'ON_SITE', 'SUBMITTED', 'REWORK', 'COMPLETED'];
const WO_PROGRESS = ['ON_SITE', 'REWORK', 'SUBMITTED', 'COMPLETED'];
const CLOSED = ['CLOSED', 'FALSE_ALARM'];

function deriveSteps(event, advisory) {
  const wo = event.work_order?.status;
  return [
    { label: 'Detected', done: true },
    { label: 'Acknowledged', done: event.status !== 'DETECTED' },
    { label: 'Isolated', done: ['ISOLATED', 'RESTORED'].includes(advisory?.status ?? event.advisory?.status) },
    { label: 'Dispatched', done: WO_DISPATCHED.includes(wo) },
    { label: 'In progress', done: WO_PROGRESS.includes(wo) },
    { label: 'Review', done: ['SUBMITTED', 'COMPLETED'].includes(wo) },
    { label: 'Closed', done: event.status === 'CLOSED' },
  ];
}

function MiniMap({ event }) {
  const { valves } = usePipeMap();
  const line = useMemo(() => lineToLatLngs(event.search_geom), [event.search_geom]);
  const point = pointToLatLng(event.location);
  const pipeValves = useMemo(() => valves.filter((v) => v.pipe_id === event.pipe.id), [valves, event.pipe.id]);
  const marker = useMemo(
    () => [{ id: event.id, severity: event.severity, status: 'ACKNOWLEDGED', event_no: event.event_no, lat: point?.[0], lon: point?.[1] }],
    [event, point],
  );
  return (
    <Suspense fallback={<MapSkeleton />}>
      <MapView
        fitKey={event.id}
        fitPoints={line.length ? line : point ? [point] : undefined}
        lines={line.length ? [{ positions: line, color: '#DC2626', weight: 6 }] : []}
        valves={pipeValves}
        events={marker}
      />
    </Suspense>
  );
}

export default function EventDetailPage() {
  const { id } = useParams();
  const { hash } = useLocation();
  const navigate = useNavigate();
  const query = useEvent(id);
  const event = query.data;
  const advisory = useAdvisory(id).data;
  const [dialog, setDialog] = useState(null);
  const [dispatchOpen, setDispatchOpen] = useState(false);
  const isolationRef = useRef(null);

  const ack = useAcknowledgeEvent(id);
  const falseAlarm = useFalseAlarm(id);
  const cancelWo = useCancelWorkOrder(event?.work_order?.id, id);

  const tab = TABS.some((t) => `#${t.id}` === hash) ? hash.slice(1) : 'overview';
  useEffect(() => {
    if (tab === 'isolation') isolationRef.current?.scrollIntoView({ block: 'start' });
  }, [tab, event?.id]);

  if (query.isPending) {
    return (
      <div className="space-y-6">
        <HeaderSkeleton />
        <StepperSkeleton />
        <div className="grid gap-4 lg:grid-cols-[2fr_1fr]"><BlockSkeleton className="h-72" /><BlockSkeleton className="h-72" /></div>
      </div>
    );
  }
  if (query.error?.status === 404) {
    return (
      <EmptyState title="Event not found">
        <Link to="/events" className="text-primary underline">Back to events</Link>
      </EmptyState>
    );
  }
  if (query.error) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;

  const wo = event.work_order;
  const live = !CLOSED.includes(event.status);
  const woLive = wo && !['COMPLETED', 'CANCELLED'].includes(wo.status);
  const entityIds = [event.id, wo?.id, advisory?.id].filter(Boolean);

  let primary = null;
  if (event.status === 'DETECTED') {
    primary = <Button loading={ack.isPending} onClick={() => ack.mutate({ key: crypto.randomUUID(), expectedStatus: event.status })}>Acknowledge</Button>;
  } else if (live && wo?.status === 'UNASSIGNED') {
    primary = <Button onClick={() => setDispatchOpen(true)}>Assign engineer</Button>;
  } else if (wo?.status === 'SUBMITTED') {
    primary = <Button onClick={() => navigate(`/work-orders/${wo.id}`)}>Review repair</Button>;
  }

  const menu = [
    { label: 'Mark false alarm', disabled: !['DETECTED', 'ACKNOWLEDGED', 'DISPATCHED'].includes(event.status), onClick: () => setDialog('false-alarm') },
    { label: 'Cancel work order', danger: true, disabled: !woLive, onClick: () => setDialog('cancel') },
  ];

  return (
    <div className="space-y-5">
      <Link to="/events" className="inline-flex items-center gap-1 text-sm text-ink-2 hover:text-ink"><ChevronLeft className="size-4" />Events</Link>

      <Card className="p-4">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-2">
            <div className="flex flex-wrap items-center gap-3">
              <h1 className="text-2xl font-semibold"><CopyableCode value={event.event_no} /></h1>
              <span className="text-base text-ink-2">Pipe {event.pipe.code} · {event.pipe.dma_code}</span>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <StatusBadge domain="severity" value={event.severity} />
              <StatusBadge domain="eventStatus" value={event.status} />
              <SourceBadge source={event.source} />
              <StatusBadge domain="priority" value={event.priority} />
              <SlaTimer due={wo?.sla_due_at} stopped={!live || !woLive} />
            </div>
          </div>
          <div className="flex items-center gap-2">
            {primary}
            <Menu items={menu} />
          </div>
        </div>
        <div className="mt-6 overflow-x-auto pb-1"><Stepper steps={deriveSteps(event, advisory)} /></div>
      </Card>

      <div className="grid gap-4 lg:grid-cols-[2fr_1fr]">
        <div className="min-w-0 space-y-4">
          <Tabs tabs={TABS} value={tab} onChange={(t) => navigate({ hash: t }, { replace: true })} />
          {tab === 'overview' && <OverviewTab event={event} />}
          {tab === 'signals' && <SignalsTab event={event} />}
          {tab === 'isolation' && (
            <div ref={isolationRef}>
              <IsolationPanel eventId={event.id} pipeCode={event.pipe.code} woStatus={wo?.status} />
            </div>
          )}
          {tab === 'workorder' && <WorkOrderTab workOrderId={wo?.id} onDispatch={() => setDispatchOpen(true)} />}
          {tab === 'timeline' && <TimelineTab eventId={event.id} entityIds={entityIds} />}
        </div>

        <div className="space-y-4">
          <Card className="overflow-hidden">
            <div className="h-64"><MiniMap event={event} /></div>
          </Card>
          <Card>
            <CardHeader title="Key facts" />
            <dl className="divide-y divide-line px-4 pb-3 text-sm">
              {[
                ['Pipe', `${event.pipe.code} · ${event.pipe.diameter_mm} mm ${event.pipe.material}`],
                ['Location method', humanize(event.location_method)],
                ['Est. leak', `${fmtNum(event.est_leak_rate_lpm)} L/min`],
                ['Detected', fmtIST(event.detected_at)],
                ['Affected connections', event.advisory?.affected_connections ?? '—'],
              ].map(([k, v]) => (
                <div key={k} className="flex justify-between gap-3 py-2"><dt className="text-ink-2">{k}</dt><dd className="text-right font-medium">{v}</dd></div>
              ))}
            </dl>
          </Card>
        </div>
      </div>

      <DispatchDialog
        open={dispatchOpen}
        onClose={() => setDispatchOpen(false)}
        eventId={event.id}
        workOrder={wo}
        advisory={advisory ?? event.advisory}
      />
      <ReasonDialog
        open={dialog === 'false-alarm'}
        onClose={() => setDialog(null)}
        title="Mark as false alarm"
        description="The work order is cancelled and the pipe returns to normal."
        reasonLabel="Reason"
        confirmLabel="Mark false alarm"
        tone="danger"
        onConfirm={({ key, reason }) => falseAlarm.mutateAsync({ key, reason, expectedStatus: event.status })}
      />
      <ReasonDialog
        open={dialog === 'cancel'}
        onClose={() => setDialog(null)}
        title="Cancel work order"
        description={`Cancel ${wo?.wo_no}? Use this for duplicates or false alarms.`}
        reasonLabel="Reason"
        confirmLabel="Cancel work order"
        tone="danger"
        onConfirm={({ key, reason }) => cancelWo.mutateAsync({ key, reason, expectedStatus: wo.status })}
      />
    </div>
  );
}
