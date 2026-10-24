import { Time } from './Time';

export function Timeline({ items }) {
  return (
    <ol className="relative space-y-4 border-l border-line-strong pl-5">
      {items.map((it) => (
        <li key={it.id} className="relative">
          <span className="absolute -left-[25px] top-1.5 size-2.5 rounded-full border-2 border-surface bg-primary" />
          <div className="flex flex-wrap items-baseline justify-between gap-2">
            <p className="text-sm font-medium">{it.title}</p>
            <Time value={it.time} relative className="text-xs text-ink-3" />
          </div>
          {it.meta && <p className="text-xs text-ink-2">{it.meta}</p>}
        </li>
      ))}
    </ol>
  );
}
