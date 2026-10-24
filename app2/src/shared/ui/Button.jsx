import { Loader2 } from 'lucide-react';
import { cn } from '../lib/cn';

const VARIANTS = {
  primary: 'bg-primary text-white hover:bg-primary-hover',
  outline: 'border border-line-strong bg-surface text-ink hover:bg-muted',
  danger: 'bg-danger text-white hover:opacity-90',
  dangerOutline: 'border border-danger bg-surface text-danger hover:bg-danger-soft',
  ghost: 'text-ink-2 hover:bg-muted',
};

export function Button({ variant = 'primary', loading = false, disabled, className, children, icon: Icon, type = 'button', ...props }) {
  return (
    <button
      type={type}
      disabled={disabled || loading}
      className={cn(
        'inline-flex h-9 items-center justify-center gap-2 rounded-md px-3.5 text-sm font-medium transition-colors duration-150 disabled:cursor-not-allowed disabled:opacity-50',
        VARIANTS[variant],
        className,
      )}
      {...props}
    >
      {loading ? <Loader2 className="size-4 animate-spin" /> : Icon ? <Icon className="size-4" /> : null}
      {children}
    </button>
  );
}
