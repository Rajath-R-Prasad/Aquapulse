import { Check } from 'lucide-react';
import { cn } from '../lib/cn';

export function Stepper({ steps }) {
  const current = steps.findIndex((s) => !s.done);
  return (
    <ol className="flex items-center" aria-label="Progress">
      {steps.map((s, i) => {
        const active = i === current;
        return (
          <li key={s.label} className="flex flex-1 items-center last:flex-none" aria-current={active ? 'step' : undefined}>
            <div className="flex flex-col items-center gap-1">
              <span
                className={cn(
                  'flex size-6 items-center justify-center rounded-full border-2 text-xs',
                  s.done ? 'border-primary bg-primary text-white' : active ? 'border-primary bg-surface text-primary' : 'border-line-strong bg-surface text-ink-3',
                )}
              >
                {s.done ? <Check className="size-3.5" /> : i + 1}
              </span>
              <span className={cn('whitespace-nowrap text-xs', s.done || active ? 'font-medium text-ink' : 'text-ink-3')}>{s.label}</span>
            </div>
            {i < steps.length - 1 && <span className={cn('mx-2 mb-5 h-0.5 flex-1', s.done ? 'bg-primary' : 'bg-line')} />}
          </li>
        );
      })}
    </ol>
  );
}
