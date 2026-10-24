import { formatInTimeZone } from 'date-fns-tz';
import { formatDistanceToNowStrict } from 'date-fns';

const TZ = 'Asia/Kolkata';

export const fmtIST = (v, pattern = 'd MMM yyyy, h:mm aaa') => (v ? formatInTimeZone(new Date(v), TZ, pattern) : '—');
export const fmtUTC = (v) => (v ? formatInTimeZone(new Date(v), 'UTC', "d MMM yyyy, HH:mm:ss 'UTC'") : '');
export const fmtRelative = (v) => (v ? formatDistanceToNowStrict(new Date(v), { addSuffix: true }) : '—');
export const dayKey = (v) => formatInTimeZone(new Date(v), TZ, 'yyyy-MM-dd');
export const istDateToIso = (d, end = false) => new Date(`${d}T${end ? '23:59:59' : '00:00:00'}+05:30`).toISOString();

export function fmtDuration(ms) {
  const abs = Math.abs(ms);
  const h = Math.floor(abs / 3_600_000);
  const m = Math.floor((abs % 3_600_000) / 60_000);
  const s = Math.floor((abs % 60_000) / 1000);
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${String(s).padStart(2, '0')}s`;
  return `${s}s`;
}

export function fmtMinutes(min) {
  if (min == null) return '—';
  const h = Math.floor(min / 60);
  const m = Math.round(min % 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}
