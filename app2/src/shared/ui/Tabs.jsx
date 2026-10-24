import { cn } from '../lib/cn';

export function Tabs({ tabs, value, onChange, className }) {
  return (
    <div role="tablist" className={cn('flex gap-1 border-b border-line', className)}>
      {tabs.map((t) => (
        <button
          key={t.id}
          role="tab"
          type="button"
          aria-selected={value === t.id}
          onClick={() => onChange(t.id)}
          className={cn(
            '-mb-px flex h-10 items-center gap-2 border-b-2 px-3 text-sm font-medium transition-colors',
            value === t.id ? 'border-primary text-primary' : 'border-transparent text-ink-2 hover:text-ink',
          )}
        >
          {t.label}
          {t.count != null && <span className="rounded-full bg-muted px-1.5 text-xs text-ink-2">{t.count}</span>}
        </button>
      ))}
    </div>
  );
}
