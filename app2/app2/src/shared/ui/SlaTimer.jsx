import { Timer } from 'lucide-react';
import { cn } from '../lib/cn';
import { useNow } from '../lib/hooks';
import { fmtDuration, fmtIST, fmtUTC } from '../lib/time';

export function SlaTimer({ due, stopped = false, className }) {
  const now = useNow();
  if (!due) return <span className="text-ink-3">—</span>;
  if (stopped) return <span className="text-xs text-ink-3" title={fmtIST(due)}>Due {fmtIST(due, 'd MMM, h:mm aaa')}</span>;
  const left = new Date(due).getTime() - now;
  const overdue = left < 0;
  return (
    <span
      title={`Due ${fmtIST(due)} (${fmtUTC(due)})`}
      className={cn('inline-flex items-center gap-1 text-xs font-medium', overdue ? 'text-danger' : left < 900_000 ? 'text-warning' : 'text-ink-2', className)}
    >
      <Timer className="size-3.5" aria-hidden="true" />
      {overdue ? `Overdue ${fmtDuration(left)}` : `${fmtDuration(left)} left`}
    </span>
  );
}
