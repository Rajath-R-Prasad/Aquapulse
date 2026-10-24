import { Droplets } from 'lucide-react';
import { fmtIST } from '@/shared/lib/time';

const Metric = ({ label, value }) => (
  <div>
    <p className="text-xs text-ink-2">{label}</p>
    <p className="text-lg font-semibold text-ink">{value}</p>
  </div>
);

export default function PublicImpactPanel({ query }) {
  const data = query.data;
  const failed = query.isError;
  const status = data?.status;
  const normal = status === 'NORMAL';
  const leak = status === 'LEAK';
  const updated = data?.updated_at ? fmtIST(data.updated_at) : '—';

  return (
    <section aria-label="Public impact" aria-live="polite" className="border-b border-line bg-surface/95 shadow-sm backdrop-blur">
      <div className="mx-auto max-w-[1600px] space-y-2 px-4 py-3 sm:px-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <Droplets className="size-5 text-primary" aria-hidden="true" />
            <h2 className="text-base font-semibold text-primary">Public impact</h2>
            {data && !failed && (
              <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${normal ? 'bg-success-soft text-success' : 'bg-danger-soft text-danger'}`}>
                {status}
              </span>
            )}
          </div>
          {data && !failed && <p className="text-xs text-ink-2">Last updated {updated}</p>}
        </div>

        {failed ? (
          <p role="alert" className="text-sm font-medium text-danger">
            Status unavailable, last updated {updated}
          </p>
        ) : !data ? (
          <p className="text-sm text-ink-2">Loading public status…</p>
        ) : (
          <>
            {normal && <p className="text-sm font-medium text-ink">No active leaks</p>}
            <div className="grid grid-cols-3 gap-4 sm:max-w-xl">
              <Metric label="Active leaks" value={data.active_leaks} />
              <Metric label="Households affected" value={data.households_affected} />
              <Metric label="Household-days lost" value={data.household_days} />
            </div>
            {leak && (
              <p className="text-sm text-ink-2">Estimated. Stops when the affected area is isolated.</p>
            )}
          </>
        )}

        <p className="text-xs text-ink-3">Estimates based on 135 litres per person per day.</p>
      </div>
    </section>
  );
}
