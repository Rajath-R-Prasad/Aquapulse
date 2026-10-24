import { fmtIST, fmtRelative, fmtUTC } from '../lib/time';

export function Time({ value, relative = false, pattern, className }) {
  if (!value) return <span className={className}>—</span>;
  return (
    <time dateTime={value} title={fmtUTC(value)} className={className}>
      {relative ? fmtRelative(value) : fmtIST(value, pattern)}
    </time>
  );
}
