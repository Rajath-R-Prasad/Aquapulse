import { Cpu, FlaskConical } from 'lucide-react';
import { cn } from '../lib/cn';
import { getStatus } from '../lib/statusMap';

export const TONES = {
  success: 'bg-success-soft text-success',
  warning: 'bg-warning-soft text-warning',
  danger: 'bg-danger-soft text-danger',
  info: 'bg-info-soft text-info',
  orange: 'bg-orange-soft text-orange',
  purple: 'bg-purple-soft text-purple',
  teal: 'bg-teal-soft text-teal',
  grey: 'bg-muted text-ink-2',
  primary: 'bg-primary-soft text-primary',
};

export function Chip({ tone = 'grey', icon: Icon, className, children, ...props }) {
  return (
    <span
      className={cn('inline-flex items-center gap-1 whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium', TONES[tone] ?? TONES.grey, className)}
      {...props}
    >
      {Icon && <Icon className="size-3.5" aria-hidden="true" />}
      {children}
    </span>
  );
}

export function StatusBadge({ domain, value, className }) {
  const s = getStatus(domain, value);
  return <Chip tone={s.tone} icon={s.icon} className={className}>{s.label}</Chip>;
}

export function SourceBadge({ source, simulated, className }) {
  const sim = simulated ?? source === 'TWIN';
  return sim ? (
    <Chip tone="purple" icon={FlaskConical} className={cn('border border-dashed border-purple', className)}>Simulated</Chip>
  ) : (
    <Chip tone="primary" icon={Cpu} className={className}>Live sensor</Chip>
  );
}
