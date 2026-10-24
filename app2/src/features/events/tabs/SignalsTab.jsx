import { Suspense, lazy } from 'react';
import { Card } from '@/shared/ui/Card';
import { ChartSkeleton } from '@/shared/ui/Skeletons';

const PipeSignals = lazy(() => import('@/shared/ui/PipeSignals'));

export function SignalsTab({ event }) {
  return (
    <Card className="p-4">
      <Suspense fallback={<ChartSkeleton />}>
        <PipeSignals pipeId={event.pipe.id} source={event.source} simulated={event.is_simulated} />
      </Suspense>
    </Card>
  );
}
