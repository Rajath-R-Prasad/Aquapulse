export const fmtNum = (v, digits = 1) => (v == null || Number.isNaN(Number(v)) ? '—' : Number(v).toFixed(digits));
export const fmtLpm = (v) => (v == null ? '—' : `${fmtNum(v)} L/min`);
export const fmtKpa = (v) => (v == null ? '—' : `${fmtNum(v)} kPa`);
export const fmtPct = (v, digits = 0) => (v == null ? '—' : `${fmtNum(v, digits)}%`);
export const fmtRatioPct = (v, digits = 0) => (v == null ? '—' : `${fmtNum(v * 100, digits)}%`);
export const fmtKm = (m) => (m == null ? '—' : `${fmtNum(m / 1000)} km`);
export const humanize = (s) => (s ? String(s).toLowerCase().replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase()) : '—');
