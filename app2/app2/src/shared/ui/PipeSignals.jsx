import { useState } from 'react';
import { SIGNAL_RANGES, usePipeMl, usePipeSignals } from '../data/network';
import { Segmented } from './FormControls';
import { SourceBadge } from './Badges';
import { SignalChart, AnomalyChart } from './SignalChart';
import { ChartSkeleton } from './Skeletons';
import { EmptyState, ErrorState, StillLoading } from './States';

const rangeOptions = Object.entries(SIGNAL_RANGES).map(([value, r]) => ({ value, label: r.label }));
const metricOptions = [{ value: 'flow', label: 'Flow' }, { value: 'pressure', label: 'Pressure' }];

export default function PipeSignals({ pipeId, source, simulated }) {
  const [range, setRange] = useState('1h');
  const [metric, setMetric] = useState('flow');
  const signals = usePipeSignals(pipeId, source, range);
  const ml = usePipeMl(pipeId);
  const points = signals.data?.points ?? [];

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <Segmented label="Range" value={range} onChange={setRange} options={rangeOptions} />
        <Segmented label="Metric" value={metric} onChange={setMetric} options={metricOptions} />
      </div>

      <div>
        <div className="mb-1 flex items-center justify-between">
          <h3 className="text-sm font-semibold">{metric === 'flow' ? 'Flow (L/min)' : 'Pressure (kPa)'}</h3>
          <SourceBadge source={source} simulated={simulated} />
        </div>
        {signals.isPending ? (
          <>
            <ChartSkeleton />
            <StillLoading active onRetry={() => signals.refetch()} />
          </>
        ) : signals.error ? (
          <ErrorState error={signals.error} onRetry={() => signals.refetch()} />
        ) : points.length === 0 ? (
          <EmptyState title="No readings in this range" />
        ) : (
          <SignalChart points={points} metric={metric} />
        )}
      </div>

      <div>
        <div className="mb-1 flex items-center justify-between">
          <h3 className="text-sm font-semibold">Anomaly score (last 60 min)</h3>
          <SourceBadge source={source} simulated={simulated} />
        </div>
        {ml.isPending ? <ChartSkeleton className="h-32" /> : ml.error ? (
          <ErrorState error={ml.error} onRetry={() => ml.refetch()} />
        ) : (ml.data ?? []).length === 0 ? (
          <EmptyState title="No inferences yet" />
        ) : (
          <AnomalyChart rows={ml.data} />
        )}
      </div>
    </div>
  );
}
