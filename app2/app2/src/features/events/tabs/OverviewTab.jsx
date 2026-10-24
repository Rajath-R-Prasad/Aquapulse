import { Card, CardHeader } from '@/shared/ui/Card';
import { fmtIST } from '@/shared/lib/time';
import { fmtNum, fmtRatioPct, humanize } from '@/shared/lib/format';

const PARAMS = [
  ['flow_in_lpm', 'Flow in', 'L/min'],
  ['flow_out_lpm', 'Flow out', 'L/min'],
  ['delta_q_lpm', 'Delta Q', 'L/min'],
  ['delta_q_pct', 'Delta Q', '%'],
  ['pressure_in_kpa', 'Pressure in', 'kPa'],
  ['pressure_out_kpa', 'Pressure out', 'kPa'],
  ['dp_kpa', 'Pressure drop', 'kPa'],
  ['pressure_dev_pct', 'Pressure deviation', '%'],
  ['acoustic_rms', 'Acoustic RMS', ''],
  ['anomaly_score', 'Anomaly score', ''],
  ['roc_delta_q_lpm_per_min', 'Rate of change', 'L/min per min'],
  ['baseline_delta_q_lpm', 'Baseline delta Q', 'L/min'],
];

function Fact({ label, value }) {
  return (
    <div>
      <dt className="text-xs text-ink-3">{label}</dt>
      <dd className="text-xl font-semibold">{value}</dd>
    </div>
  );
}

export function OverviewTab({ event }) {
  const score = Math.round((event.severity_score ?? 0) * 100);
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader title="Assessment" />
        <div className="space-y-4 px-4 pb-4">
          <div>
            <div className="mb-1 flex justify-between text-xs text-ink-2"><span>Severity score</span><span>{(event.severity_score ?? 0).toFixed(2)}</span></div>
            <div className="h-2 overflow-hidden rounded-full bg-muted" role="meter" aria-valuemin={0} aria-valuemax={1} aria-valuenow={event.severity_score} aria-label="Severity score">
              <div className="h-full rounded-full bg-gradient-to-r from-warning to-danger" style={{ width: `${score}%` }} />
            </div>
          </div>
          <dl className="grid grid-cols-2 gap-4 md:grid-cols-4">
            <Fact label="Est. leak rate" value={`${fmtNum(event.est_leak_rate_lpm)} L/min`} />
            <Fact label="Est. loss" value={`${fmtNum(event.est_loss_pct)}%`} />
            <Fact label="Confidence" value={fmtRatioPct(event.confidence)} />
            <Fact label="Location" value={<span className="text-base">{humanize(event.location_method)}</span>} />
          </dl>
          <p className="text-xs text-ink-2">Detected {fmtIST(event.detected_at)}</p>
        </div>
      </Card>

      <Card>
        <CardHeader title="Model parameters" />
        <dl className="grid grid-cols-2 gap-x-6 gap-y-3 px-4 pb-4 md:grid-cols-3">
          {PARAMS.map(([key, label, unit]) => (
            <div key={key}>
              <dt className="text-xs text-ink-3">{label}</dt>
              <dd className="text-sm font-medium">
                {fmtNum(event.parameters?.[key], key === 'acoustic_rms' || key === 'anomaly_score' ? 2 : 1)}
                {unit && event.parameters?.[key] != null && <span className="ml-1 text-xs font-normal text-ink-3">{unit}</span>}
              </dd>
            </div>
          ))}
        </dl>
      </Card>
    </div>
  );
}
