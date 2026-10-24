import { Area, CartesianGrid, ComposedChart, Legend, Line, LineChart, ReferenceLine, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { fmtIST } from '../lib/time';

const axis = { fontSize: 11, fill: '#475569' };
const tick = (v) => fmtIST(v, 'HH:mm');
const tipLabel = (v) => fmtIST(v, 'd MMM, HH:mm:ss');

export function SignalChart({ points, metric }) {
  const data = (points ?? []).map((p) => ({
    ...p,
    t: new Date(p.ts).getTime(),
    delta: p.flow_in_lpm != null && p.flow_out_lpm != null ? Math.max(0, p.flow_in_lpm - p.flow_out_lpm) : null,
  }));
  const flow = metric === 'flow';
  return (
    <ResponsiveContainer width="100%" height={260}>
      <ComposedChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
        <CartesianGrid stroke="#E2E8F0" vertical={false} />
        <XAxis dataKey="t" type="number" scale="time" domain={['dataMin', 'dataMax']} tickFormatter={tick} tick={axis} />
        <YAxis tick={axis} width={44} unit={flow ? '' : ''} />
        <Tooltip labelFormatter={tipLabel} formatter={(v) => (v == null ? '—' : Number(v).toFixed(1))} />
        <Legend wrapperStyle={{ fontSize: 12 }} />
        {flow ? (
          <>
            <Area type="monotone" dataKey="delta" name="Delta Q (L/min)" stroke="none" fill="#DC2626" fillOpacity={0.18} connectNulls />
            <Line type="monotone" dataKey="flow_in_lpm" name="Flow in (L/min)" stroke="#0B7285" dot={false} strokeWidth={2} connectNulls />
            <Line type="monotone" dataKey="flow_out_lpm" name="Flow out (L/min)" stroke="#475569" dot={false} strokeWidth={2} connectNulls />
          </>
        ) : (
          <>
            <Line type="monotone" dataKey="pressure_in_kpa" name="Pressure in (kPa)" stroke="#0B7285" dot={false} strokeWidth={2} connectNulls />
            <Line type="monotone" dataKey="pressure_out_kpa" name="Pressure out (kPa)" stroke="#475569" dot={false} strokeWidth={2} connectNulls />
          </>
        )}
      </ComposedChart>
    </ResponsiveContainer>
  );
}

export function AnomalyChart({ rows }) {
  const data = (rows ?? []).map((r) => ({ t: new Date(r.window_end).getTime(), score: r.anomaly_score }));
  return (
    <ResponsiveContainer width="100%" height={160}>
      <LineChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
        <CartesianGrid stroke="#E2E8F0" vertical={false} />
        <XAxis dataKey="t" type="number" scale="time" domain={['dataMin', 'dataMax']} tickFormatter={tick} tick={axis} />
        <YAxis domain={[0, 1]} tick={axis} width={44} />
        <Tooltip labelFormatter={tipLabel} formatter={(v) => Number(v).toFixed(2)} />
        <ReferenceLine y={0.4} stroke="#F59E0B" strokeDasharray="4 4" label={{ value: 'warn', fontSize: 10, fill: '#B45309' }} />
        <ReferenceLine y={0.6} stroke="#DC2626" strokeDasharray="4 4" label={{ value: 'confirm', fontSize: 10, fill: '#B91C1C' }} />
        <Line type="monotone" dataKey="score" name="Anomaly score" stroke="#6D28D9" dot={false} strokeWidth={2} />
      </LineChart>
    </ResponsiveContainer>
  );
}
