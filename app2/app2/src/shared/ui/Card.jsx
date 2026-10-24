import { Loader2 } from 'lucide-react';
import { cn } from '../lib/cn';
import { useDelayedFlag } from '../lib/hooks';

export function Card({ className, children, ...props }) {
  return (
    <section className={cn('rounded-md border border-line bg-surface shadow-sm', className)} {...props}>
      {children}
    </section>
  );
}

export function CardHeader({ title, actions, fetching = false, className }) {
  const showUpdating = useDelayedFlag(fetching, 600);
  return (
    <header className={cn('flex items-center justify-between gap-3 px-4 pt-4 pb-2', className)}>
      <h2 className="text-base font-semibold">{title}</h2>
      <div className="flex items-center gap-3">
        {showUpdating && (
          <span className="flex items-center gap-1 text-xs text-ink-3">
            <Loader2 className="size-3 animate-spin" />
            Updating
          </span>
        )}
        {actions}
      </div>
    </header>
  );
}
