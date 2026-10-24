import { Suspense, lazy, useMemo } from 'react';
import { HardHat } from 'lucide-react';
import { Card, CardHeader } from '@/shared/ui/Card';
import { Chip, StatusBadge } from '@/shared/ui/Badges';
import { DataTable } from '@/shared/ui/DataTable';
import { Time } from '@/shared/ui/Time';
import { MapSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { parsePosition } from '@/shared/lib/geo';
import { humanize } from '@/shared/lib/format';
import { strings } from '@/shared/lib/strings';
import { useEngineers } from './hooks';

const MapView = lazy(() => import('@/shared/map/MapView'));

export default function EngineersPage() {
  const query = useEngineers();
  const rows = useMemo(() => query.data ?? [], [query.data]);
  const markers = useMemo(
    () =>
      rows
        .map((e) => ({ id: e.profile_id, label: e.profiles?.full_name ?? 'Engineer', latlng: parsePosition(e.last_location ?? e) }))
        .filter((m) => m.latlng),
    [rows],
  );

  const columns = [
    { id: 'name', header: 'Name', cell: ({ row }) => <span className="font-medium">{row.original.profiles?.full_name ?? '—'}</span> },
    { id: 'status', header: 'Status', cell: ({ row }) => <StatusBadge domain="engineerStatus" value={row.original.status} /> },
    {
      id: 'skills',
      header: 'Skills',
      cell: ({ row }) => (
        <span className="flex flex-wrap gap-1">{(row.original.skills ?? []).map((s) => <Chip key={s}>{humanize(s)}</Chip>)}</span>
      ),
    },
    { id: 'jobs', header: 'Active jobs', cell: ({ row }) => row.original.active_jobs },
    { id: 'seen', header: 'Last seen', cell: ({ row }) => <Time value={row.original.last_location_at} relative className="text-ink-2" /> },
  ];

  return (
    <div className="space-y-4">
      <Card>
        {query.error ? <ErrorState error={query.error} onRetry={() => query.refetch()} /> : (
          <DataTable
            columns={columns}
            data={rows}
            isPending={query.isPending}
            skeletonRows={6}
            getRowId={(r) => r.profile_id}
            empty={<EmptyState icon={HardHat} title={strings.empty.engineers} />}
          />
        )}
      </Card>
      {markers.length > 0 && (
        <Card className="overflow-hidden">
          <CardHeader title="Positions" />
          <div className="h-80">
            <Suspense fallback={<MapSkeleton />}>
              <MapView markers={markers} fitPoints={markers.map((m) => m.latlng)} />
            </Suspense>
          </div>
        </Card>
      )}
    </div>
  );
}
