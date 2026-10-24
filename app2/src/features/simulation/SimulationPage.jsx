import { useMemo, useState } from 'react';
import { FlaskConical } from 'lucide-react';
import { toast } from 'sonner';
import { Card, CardHeader } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { Chip, StatusBadge } from '@/shared/ui/Badges';
import { DataTable } from '@/shared/ui/DataTable';
import { Field, Select } from '@/shared/ui/FormControls';
import { Time } from '@/shared/ui/Time';
import { Skeleton } from '@/shared/ui/Skeletons';
import { EmptyState, ErrorState } from '@/shared/ui/States';
import { usePipeMap } from '@/shared/data/network';
import { humanize } from '@/shared/lib/format';
import { strings } from '@/shared/lib/strings';
import { useClearLeak, useInjectLeak, useTwinCommands } from './hooks';

function PipeSelect({ pipes, value, onChange, label }) {
  const options = useMemo(
    () => [...pipes].sort((a, b) => (a.monitoring === 'SIMULATED' ? -1 : 1) - (b.monitoring === 'SIMULATED' ? -1 : 1) || a.code.localeCompare(b.code))
      .map((p) => ({ value: p.id, label: `${p.code}${p.monitoring === 'HARDWARE' ? ' (live sensor)' : ''}` })),
    [pipes],
  );
  return <Select label={label} value={value} onChange={onChange} options={[{ value: '', label: 'Select a pipe' }, ...options]} className="w-full" />;
}

export default function SimulationPage() {
  const network = usePipeMap();
  const commands = useTwinCommands();
  const inject = useInjectLeak();
  const clear = useClearLeak();
  const [injectPipe, setInjectPipe] = useState('');
  const [clearPipe, setClearPipe] = useState('');
  const [rate, setRate] = useState(10);
  const injected = network.byId.get(injectPipe);
  const hardware = injected?.monitoring === 'HARDWARE';

  const columns = [
    { id: 'type', header: 'Type', cell: ({ row }) => <span className="font-medium">{humanize(row.original.type)}</span> },
    { id: 'pipe', header: 'Pipe', cell: ({ row }) => network.byId.get(row.original.pipe_id)?.code ?? '—' },
    {
      id: 'status',
      header: 'Status',
      cell: ({ row }) => (
        <div className="space-y-1">
          <StatusBadge domain="twinStatus" value={row.original.status} />
          {row.original.status === 'FAILED' && row.original.error && <p className="text-xs text-danger">{row.original.error}</p>}
        </div>
      ),
    },
    { id: 'created', header: 'Created', cell: ({ row }) => <Time value={row.original.created_at} relative className="text-ink-2" /> },
    { id: 'applied', header: 'Applied', cell: ({ row }) => <Time value={row.original.applied_at} relative className="text-ink-2" /> },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Chip tone="purple" icon={FlaskConical} className="border border-dashed border-purple">Simulation</Chip>
        <p className="text-sm text-ink-2">{strings.twinHelp}</p>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader title="Inject leak" />
          <div className="space-y-4 px-4 pb-4">
            {network.isPending ? <Skeleton className="h-9 w-full" /> : network.error ? (
              <ErrorState error={network.error} onRetry={() => network.refetch()} />
            ) : (
              <>
                <Field label="Pipe" htmlFor="inject-pipe">
                  <PipeSelect pipes={network.pipes} value={injectPipe} onChange={setInjectPipe} label="Pipe to inject" />
                </Field>
                {hardware && <p role="alert" className="rounded-md bg-warning-soft px-3 py-2 text-sm text-warning">{strings.hardwarePipe}</p>}
                <Field label={`Leak rate: ${rate} L/min`} htmlFor="rate">
                  <div className="flex items-center gap-3">
                    <input id="rate" type="range" min={1} max={60} value={rate} onChange={(e) => setRate(Number(e.target.value))} className="flex-1" />
                    <input
                      type="number"
                      min={1}
                      max={60}
                      aria-label="Leak rate in litres per minute"
                      value={rate}
                      onChange={(e) => setRate(Math.min(60, Math.max(1, Number(e.target.value) || 1)))}
                      className="h-9 w-20 rounded-md border border-line-strong px-2 text-sm"
                    />
                  </div>
                </Field>
                <Button
                  disabled={!injectPipe || hardware}
                  loading={inject.isPending}
                  onClick={() => inject.mutate({ pipeId: injectPipe, rate }, { onSuccess: () => toast.success('Leak injection queued') })}
                >
                  Inject leak
                </Button>
              </>
            )}
          </div>
        </Card>

        <Card>
          <CardHeader title="Clear leak" />
          <div className="space-y-4 px-4 pb-4">
            {network.isPending ? <Skeleton className="h-9 w-full" /> : (
              <>
                <Field label="Pipe" htmlFor="clear-pipe">
                  <PipeSelect pipes={network.pipes} value={clearPipe} onChange={setClearPipe} label="Pipe to clear" />
                </Field>
                <Button
                  variant="outline"
                  disabled={!clearPipe}
                  loading={clear.isPending}
                  onClick={() => clear.mutate({ pipeId: clearPipe }, { onSuccess: () => toast.success('Clear command queued') })}
                >
                  Clear leak
                </Button>
              </>
            )}
          </div>
        </Card>
      </div>

      <Card>
        <CardHeader title="Recent twin commands" fetching={commands.isFetching && !commands.isPending} />
        {commands.error ? <ErrorState error={commands.error} onRetry={() => commands.refetch()} /> : (
          <DataTable
            columns={columns}
            data={commands.data}
            isPending={commands.isPending}
            skeletonRows={5}
            getRowId={(r) => r.id}
            empty={<EmptyState title="No commands yet" />}
          />
        )}
      </Card>
    </div>
  );
}
