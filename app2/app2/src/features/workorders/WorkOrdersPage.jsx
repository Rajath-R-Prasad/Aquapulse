import { Link, useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import { ClipboardCheck } from 'lucide-react';
import { Card } from '@/shared/ui/Card';
import { Tabs } from '@/shared/ui/Tabs';
import { Button } from '@/shared/ui/Button';
import { DataTable } from '@/shared/ui/DataTable';
import { StatusBadge } from '@/shared/ui/Badges';
import { SlaTimer } from '@/shared/ui/SlaTimer';
import { Time } from '@/shared/ui/Time';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { usePipeMap } from '@/shared/data/network';
import { strings } from '@/shared/lib/strings';
import { PAGE_SIZE, useWorkOrders } from './hooks';

const TABS = [{ id: 'active', label: 'Active' }, { id: 'approval', label: 'Awaiting approval' }, { id: 'completed', label: 'Completed' }];

export default function WorkOrdersPage() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();
  const tab = pathname === '/approvals' ? 'approval' : params.get('tab') ?? 'active';
  const page = Number(params.get('page') ?? 0);
  const query = useWorkOrders(tab, page);
  const { byId } = usePipeMap();
  const items = query.data?.items ?? [];
  const total = query.data?.count ?? 0;

  const columns = [
    { id: 'wo', header: 'Work order', cell: ({ row }) => <Link to={`/work-orders/${row.original.id}`} className="font-semibold text-primary hover:underline" onClick={(e) => e.stopPropagation()}>{row.original.wo_no}</Link> },
    { id: 'event', header: 'Event', cell: ({ row }) => (row.original.leak_events ? <Link to={`/events/${row.original.leak_event_id}`} className="hover:underline" onClick={(e) => e.stopPropagation()}>{row.original.leak_events.event_no}</Link> : '—') },
    { id: 'pipe', header: 'Pipe', cell: ({ row }) => byId.get(row.original.leak_events?.pipe_id)?.code ?? '—' },
    { id: 'priority', header: 'Priority', cell: ({ row }) => <StatusBadge domain="priority" value={row.original.priority} /> },
    { id: 'status', header: 'Status', cell: ({ row }) => <StatusBadge domain="woStatus" value={row.original.status} /> },
    { id: 'engineer', header: 'Engineer', cell: ({ row }) => row.original.engineers?.profiles?.full_name ?? '—' },
    { id: 'sla', header: 'SLA', cell: ({ row }) => <SlaTimer due={row.original.sla_due_at} stopped={['COMPLETED', 'CANCELLED'].includes(row.original.status)} /> },
    { id: 'updated', header: 'Updated', cell: ({ row }) => <Time value={row.original.updated_at} relative className="text-ink-2" /> },
  ];

  const setTab = (id) => navigate(`/work-orders?tab=${id}`);
  const setPage = (p) => {
    const next = new URLSearchParams(params);
    next.set('page', String(p));
    setParams(next);
  };

  return (
    <div className="space-y-4">
      <Tabs tabs={TABS} value={tab} onChange={setTab} />
      <Card>
        {query.error ? <ErrorState error={query.error} onRetry={() => query.refetch()} /> : (
          <DataTable
            columns={columns}
            data={items}
            isPending={query.isPending}
            getRowId={(r) => r.id}
            onRowClick={(r) => navigate(`/work-orders/${r.id}`)}
            empty={<EmptyState icon={ClipboardCheck} title={tab === 'approval' ? strings.empty.approvals : strings.empty.workOrders} />}
          />
        )}
        {total > PAGE_SIZE && (
          <div className="flex items-center justify-between border-t border-line px-4 py-3 text-sm text-ink-2">
            <span>{page * PAGE_SIZE + 1}–{Math.min(total, (page + 1) * PAGE_SIZE)} of {total}</span>
            <div className="flex gap-2">
              <Button variant="outline" disabled={page === 0} onClick={() => setPage(page - 1)}>Previous</Button>
              <Button variant="outline" disabled={(page + 1) * PAGE_SIZE >= total} onClick={() => setPage(page + 1)}>Next</Button>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
