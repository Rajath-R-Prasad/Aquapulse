import { Loader2 } from 'lucide-react';
import { cn } from '../lib/cn';

export const Skeleton = ({ className }) => <div className={cn('skeleton', className)} aria-hidden="true" />;

export const KpiSkeleton = () => (
  <div className="rounded-md border border-line bg-surface p-4 shadow-sm">
    <Skeleton className="h-3 w-24" />
    <Skeleton className="mt-4 h-8 w-16" />
  </div>
);

export const EventCardSkeleton = () => (
  <div className="rounded-md border border-line p-3">
    <div className="flex gap-2"><Skeleton className="h-5 w-16" /><Skeleton className="h-5 w-24" /></div>
    <Skeleton className="mt-3 h-3 w-2/3" />
  </div>
);

export const HeaderSkeleton = () => (
  <div className="space-y-3">
    <Skeleton className="h-7 w-64" />
    <div className="flex gap-2"><Skeleton className="h-6 w-20 rounded-full" /><Skeleton className="h-6 w-24 rounded-full" /><Skeleton className="h-6 w-16 rounded-full" /></div>
  </div>
);

export const StepperSkeleton = () => (
  <div className="flex items-center gap-6">{Array.from({ length: 7 }).map((_, i) => <Skeleton key={i} className="size-4 rounded-full" />)}</div>
);

export const ListSkeleton = ({ rows = 5 }) => (
  <div className="space-y-3">
    {Array.from({ length: rows }).map((_, i) => (
      <div key={i} className="flex items-center gap-3">
        <Skeleton className="size-8 rounded-full" />
        <div className="flex-1 space-y-2"><Skeleton className="h-3 w-3/4" /><Skeleton className="h-3 w-1/2" /></div>
      </div>
    ))}
  </div>
);

export const CandidateSkeleton = () => (
  <div className="space-y-3">
    {Array.from({ length: 4 }).map((_, i) => (
      <div key={i} className="rounded-md border border-line p-3">
        <Skeleton className="h-4 w-1/2" /><Skeleton className="mt-3 h-2 w-full" />
      </div>
    ))}
  </div>
);

export const BlockSkeleton = ({ className = 'h-40' }) => <Skeleton className={cn('w-full', className)} />;

export const DrawerSkeleton = () => (
  <div className="space-y-4">
    <Skeleton className="h-6 w-1/2" />
    {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-4 w-full" />)}
    <Skeleton className="h-40 w-full" />
  </div>
);

export const ChartSkeleton = ({ className = 'h-64' }) => (
  <div className={cn('flex items-end gap-2 px-2', className)} aria-hidden="true">
    {[40, 65, 50, 80, 60, 75, 55, 90, 70, 60, 85, 50].map((h, i) => <Skeleton key={i} className="flex-1" style={{ height: `${h}%` }} />)}
  </div>
);

export const MapSkeleton = () => (
  <div
    className="relative flex h-full min-h-72 w-full items-center justify-center bg-muted"
    style={{ backgroundImage: 'repeating-linear-gradient(45deg,#E7ECF2 0 12px,#EEF2F6 12px 24px)' }}
  >
    <Loader2 className="size-6 animate-spin text-ink-3" aria-label="Loading map" />
  </div>
);

export const TileSkeleton = () => <Skeleton className="aspect-[4/3] w-full" />;
