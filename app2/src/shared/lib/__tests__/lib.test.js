import { describe, expect, it } from 'vitest';
import { fmtNum, fmtKm } from '../format';
import { getStatus } from '../statusMap';
import { fmtDuration, istDateToIso } from '../time';
import { toLatLng } from '../geo';

describe('format', () => {
  it('formats numbers with fallback', () => {
    expect(fmtNum(18.44)).toBe('18.4');
    expect(fmtNum(null)).toBe('—');
    expect(fmtKm(2500)).toBe('2.5 km');
  });
});

describe('statusMap', () => {
  it('maps known and unknown values', () => {
    expect(getStatus('severity', 'CRITICAL').label).toBe('Critical');
    expect(getStatus('severity', 'WHATEVER')).toMatchObject({ label: 'WHATEVER', tone: 'grey' });
  });
});

describe('time and geo', () => {
  it('formats durations', () => {
    expect(fmtDuration(3_660_000)).toBe('1h 1m');
  });
  it('converts IST dates', () => {
    expect(istDateToIso('2026-10-15')).toBe('2026-10-14T18:30:00.000Z');
  });
  it('swaps lon/lat', () => {
    expect(toLatLng([76.6, 12.2])).toEqual([12.2, 76.6]);
  });
});
