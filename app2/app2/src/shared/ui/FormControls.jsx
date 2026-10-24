import { useEffect, useRef, useState } from 'react';
import { Check, ChevronDown, MoreVertical } from 'lucide-react';
import { cn } from '../lib/cn';

const control = 'h-9 rounded-md border border-line-strong bg-surface px-3 text-sm text-ink';

export const TextInput = ({ className, ...p }) => <input className={cn(control, 'w-full', className)} {...p} />;

export function Select({ value, onChange, options, label, className }) {
  return (
    <select aria-label={label} value={value} onChange={(e) => onChange(e.target.value)} className={cn(control, className)}>
      {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
    </select>
  );
}

export function Field({ label, htmlFor, children, hint }) {
  return (
    <div>
      <label htmlFor={htmlFor} className="mb-1 block text-sm font-medium">{label}</label>
      {children}
      {hint && <p className="mt-1 text-xs text-ink-3">{hint}</p>}
    </div>
  );
}

function usePopover() {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  useEffect(() => {
    if (!open) return undefined;
    const down = (e) => !ref.current?.contains(e.target) && setOpen(false);
    const key = (e) => e.key === 'Escape' && setOpen(false);
    document.addEventListener('mousedown', down);
    document.addEventListener('keydown', key);
    return () => {
      document.removeEventListener('mousedown', down);
      document.removeEventListener('keydown', key);
    };
  }, [open]);
  return { open, setOpen, ref };
}

export function MultiSelect({ label, options, value, onChange }) {
  const { open, setOpen, ref } = usePopover();
  const toggle = (v) => onChange(value.includes(v) ? value.filter((x) => x !== v) : [...value, v]);
  return (
    <div ref={ref} className="relative">
      <button type="button" aria-haspopup="listbox" aria-expanded={open} onClick={() => setOpen(!open)} className={cn(control, 'flex items-center gap-2')}>
        {label}
        {value.length > 0 && <span className="rounded-full bg-primary px-1.5 text-xs text-white">{value.length}</span>}
        <ChevronDown className="size-4 text-ink-3" />
      </button>
      {open && (
        <ul role="listbox" aria-multiselectable="true" className="absolute left-0 z-30 mt-1 max-h-72 min-w-48 overflow-auto rounded-md border border-line bg-surface p-1 shadow-md">
          {options.map((o) => {
            const on = value.includes(o.value);
            return (
              <li key={o.value} role="option" aria-selected={on}>
                <button type="button" onClick={() => toggle(o.value)} className="flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-left text-sm hover:bg-muted">
                  <span className={cn('flex size-4 items-center justify-center rounded-sm border', on ? 'border-primary bg-primary text-white' : 'border-line-strong')}>
                    {on && <Check className="size-3" />}
                  </span>
                  {o.label}
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}

export function Menu({ items, label = 'More actions' }) {
  const { open, setOpen, ref } = usePopover();
  return (
    <div ref={ref} className="relative">
      <button type="button" aria-label={label} aria-haspopup="menu" aria-expanded={open} onClick={() => setOpen(!open)} className="flex size-9 items-center justify-center rounded-md border border-line-strong bg-surface hover:bg-muted">
        <MoreVertical className="size-4" />
      </button>
      {open && (
        <div role="menu" className="absolute right-0 z-30 mt-1 min-w-52 rounded-md border border-line bg-surface p-1 shadow-md">
          {items.map((it) => (
            <button
              key={it.label}
              role="menuitem"
              type="button"
              disabled={it.disabled}
              onClick={() => { setOpen(false); it.onClick(); }}
              className={cn('block w-full rounded-sm px-3 py-2 text-left text-sm hover:bg-muted disabled:opacity-50', it.danger && 'text-danger')}
            >
              {it.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export function Segmented({ value, onChange, options, label }) {
  return (
    <div role="radiogroup" aria-label={label} className="inline-flex rounded-md border border-line-strong bg-surface p-0.5">
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="radio"
          aria-checked={value === o.value}
          onClick={() => onChange(o.value)}
          className={cn('h-8 rounded-sm px-3 text-sm font-medium', value === o.value ? 'bg-primary text-white' : 'text-ink-2 hover:bg-muted')}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function FilterBar({ children, onClear, active }) {
  return (
    <div className="flex flex-wrap items-center gap-2">
      {children}
      {active && <button type="button" onClick={onClear} className="px-2 text-sm text-primary hover:underline">Clear filters</button>}
    </div>
  );
}
