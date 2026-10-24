import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Search, TriangleAlert } from 'lucide-react';
import { Card } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { DataTable } from '@/shared/ui/DataTable';
import { FilterBar, MultiSelect, Select, TextInput } from '@/shared/ui/FormControls';
import { SourceBadge, StatusBadge } from '@/shared/ui/Badges';
import { Time } from '@/shared/ui/Time';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { EVENT_STATUSES, SEVERITIES, SEVERITY_RANK, getStatus } from '@/shared/lib/statusMap';
import { fmtNum, fmtRatioPct } from '@/shared/lib/format';
import { strings } from '@/shared/lib/strings';
import { useEvents, useUrlFilters } from './hooks';

const statusOptions = EVENT_STATUSES.map((v) => ({ value: v, label: getStatus('eventStatus', v).label }));
const severityOptions = SEVERITIES.map((v) => ({ value: v, label: getStatus('severity', v).label }));
const sourceOptions = [{ value: '', label: 'All sources' }, { value: 'HARDWARE', label: 'Live sensor' }, { value: 'TWIN', label: 'Simulated' }];

export default function EventsPage() {
  const navigate = useNavigate();
  const { filters, set, clear, active } = useUrlFilters();
  const query = useEvents(filters);
  const [flash, setFlash] = useState(new Set());
  const seen = useRef(null);

  const items = useMemo(() => {
    const all = (query.data?.pages ?? []).flatMap((p) => p.items);
    const q = filters.q.trim().toLowerCase();
    return q ? all.filter((e) => e.event_no?.toLowerCase().includes(q)) : all;
  }, [query.data, filters.q]);

  useEffect(() => {
    const first = query.data?.pages?.[0]?.items;
    if (!first) return;
    const ids = new Set(first.map((e) => e.id));
    if (seen.current) {
      const fresh = [...ids].filter((id) => !seen.current.has(id));
      if (fresh.length) {
        setFlash(new Set(fresh));
        setTimeout(() => setFlash(new Set()), 2000);
      }
    }
    seen.current = ids;
  }, [query.data]);

  const columns = [
    { id: 'severity', header: 'Severity', enableSorting: true, accessorFn: (r) => SEVERITY_RANK[r.severity] ?? 0, cell: ({ row }) => <StatusBadge domain="severity" value={row.original.severity} /> },
    {
      id: 'event',
      header: 'Event',
      cell: ({ row }) => (
        <span className="flex items-center gap-2">
          <Link to={`/events/${row.original.id}`} onClick={(e) => e.stopPropagation()} className="font-semibold text-primary hover:underline">{row.original.event_no}</Link>
          {row.original.is_simulated && <SourceBadge simulated />}
        </span>
      ),
    },
    { id: 'pipe', header: 'Pipe and DMA', cell: ({ row }) => <span>{row.original.pipe_code} <span className="text-ink-3">· {row.original.dma_code}</span></span> },
    { id: 'status', header: 'Status', cell: ({ row }) => <StatusBadge domain="eventStatus" value={row.original.status} /> },
    { id: 'rate', header: 'Est. leak (L/min)', enableSorting: true, accessorFn: (r) => r.est_leak_rate_lpm ?? -1, cell: ({ row }) => fmtNum(row.original.est_leak_rate_lpm) },
    { id: 'confidence', header: 'Confidence', cell: ({ row }) => fmtRatioPct(row.original.confidence) },
    { id: 'priority', header: 'Priority', cell: ({ row }) => <StatusBadge domain="priority" value={row.original.priority} /> },
    { id: 'wo', header: 'Work order', cell: ({ row }) => (row.original.wo_no ? <span>{row.original.wo_no}</span> : '—') },
    { id: 'engineer', header: 'Engineer', cell: ({ row }) => row.original.engineer_name ?? '—' },
    { id: 'detected', header: 'Detected', enableSorting: true, accessorFn: (r) => new Date(r.detected_at).getTime(), cell: ({ row }) => <Time value={row.original.detected_at} relative className="text-ink-2" /> },
  ];

  return (
    <div className="space-y-4">
      <FilterBar onClear={clear} active={active}>
        <MultiSelect label="Status" options={statusOptions} value={filters.status} onChange={(v) => set({ status: v })} />
        <MultiSelect label="Severity" options={severityOptions} value={filters.severity} onChange={(v) => set({ severity: v })} />
        <Select label="Source" value={filters.source} onChange={(v) => set({ source: v })} options={sourceOptions} />
        <TextInput type="date" aria-label="From date" value={filters.from} onChange={(e) => set({ from: e.target.value })} className="w-40" />
        <TextInput type="date" aria-label="To date" value={filters.to} onChange={(e) => set({ to: e.target.value })} className="w-40" />
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-2.5 size-4 text-ink-3" aria-hidden="true" />
          <TextInput placeholder="Event number" aria-label="Search by event number" value={filters.q} onChange={(e) => set({ q: e.target.value })} className="w-48 pl-9" />
        </div>
      </FilterBar>

      <Card>
        {query.error ? <ErrorState error={query.error} onRetry={() => query.refetch()} /> : (
          <DataTable
            columns={columns}
            data={items}
            isPending={query.isPending}
            getRowId={(r) => r.id}
            onRowClick={(r) => navigate(`/events/${r.id}`)}
            rowClassName={(r) => (flash.has(r.id) ? 'row-new' : '')}
            empty={
              active ? (
                <EmptyState icon={TriangleAlert} title={strings.empty.events} action={<Button variant="outline" onClick={clear}>Clear filters</Button>} />
              ) : (
                <EmptyState icon={TriangleAlert} title={strings.empty.eventsFirst} />
              )
            }
          />
        )}
        {query.hasNextPage && (
          <div className="flex justify-center border-t border-line p-3">
            <Button variant="outline" loading={query.isFetchingNextPage} onClick={() => query.fetchNextPage()}>Load more</Button>
          </div>
        )}
      </Card>
    </div>
  );
}
