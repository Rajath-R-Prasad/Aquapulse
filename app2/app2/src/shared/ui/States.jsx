import { CircleAlert, Inbox, Loader2 } from 'lucide-react';
import { Button } from './Button';
import { useDelayedFlag } from '../lib/hooks';
import { cn } from '../lib/cn';

export function EmptyState({ icon: Icon = Inbox, title, children, action, className }) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-2 px-6 py-10 text-center', className)}>
      <Icon className="size-8 text-ink-3" aria-hidden="true" />
      <p className="font-medium">{title}</p>
      {children && <p className="max-w-sm text-sm text-ink-2">{children}</p>}
      {action}
    </div>
  );
}

export function ErrorState({ error, onRetry, title = 'Something went wrong', className }) {
  return (
    <div role="alert" className={cn('flex flex-col items-center justify-center gap-2 px-6 py-10 text-center', className)}>
      <CircleAlert className="size-8 text-danger" aria-hidden="true" />
      <p className="font-medium">{title}</p>
      {error?.message && <p className="max-w-sm text-sm text-ink-2">{error.message}</p>}
      {onRetry && <Button variant="outline" onClick={onRetry}>Retry</Button>}
    </div>
  );
}

export function StillLoading({ active, onRetry }) {
  const slow = useDelayedFlag(active, 8000);
  if (!slow) return null;
  return (
    <p className="flex items-center justify-center gap-2 py-2 text-xs text-ink-3">
      <Loader2 className="size-3 animate-spin" />
      Still loading
      {onRetry && <button type="button" onClick={onRetry} className="text-primary underline">Retry</button>}
    </p>
  );
}
