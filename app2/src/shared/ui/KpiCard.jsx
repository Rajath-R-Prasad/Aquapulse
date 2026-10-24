import { Card } from './Card';
import { KpiSkeleton } from './Skeletons';
import { ErrorState } from './States';

export function KpiCard({ label, value, hint, children, loading, error, onRetry }) {
  if (loading) return <KpiSkeleton />;
  if (error) return <Card className="p-4"><ErrorState error={error} onRetry={onRetry} className="py-2" title="Unavailable" /></Card>;
  return (
    <Card className="p-4">
      <p className="text-xs font-medium text-ink-2">{label}</p>
      <p className="mt-1 text-[32px] font-semibold leading-10">{value}</p>
      {hint && <p className="text-xs text-ink-3">{hint}</p>}
      {children}
    </Card>
  );
}
