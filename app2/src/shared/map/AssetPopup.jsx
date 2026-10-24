import { Link } from 'react-router-dom';
import { StatusBadge, SourceBadge } from '../ui/Badges';
import { fmtKpa, fmtLpm } from '../lib/format';
import { signalFor, sourceOf } from '../data/network';

export function AssetPopup({ pipe, signals, event }) {
  const s = signalFor(signals, pipe);
  return (
    <div className="min-w-52 space-y-2 text-sm">
      <div className="flex items-center justify-between gap-2">
        <strong className="text-base">{pipe.code}</strong>
        <StatusBadge domain="pipeState" value={pipe.state} />
      </div>
      <SourceBadge source={sourceOf(pipe)} />
      <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-xs">
        <dt className="text-ink-3">Flow in</dt><dd>{fmtLpm(s?.flow_in_lpm ?? pipe.flow_in_lpm)}</dd>
        <dt className="text-ink-3">Flow out</dt><dd>{fmtLpm(s?.flow_out_lpm ?? pipe.flow_out_lpm)}</dd>
        <dt className="text-ink-3">Pressure in</dt><dd>{fmtKpa(s?.pressure_in_kpa ?? pipe.pressure_in_kpa)}</dd>
        <dt className="text-ink-3">Pressure out</dt><dd>{fmtKpa(s?.pressure_out_kpa ?? pipe.pressure_out_kpa)}</dd>
      </dl>
      <div className="flex gap-3 text-xs">
        <Link className="text-primary underline" to={`/map?pipe=${pipe.code}`}>Open on map</Link>
        {event && <Link className="text-primary underline" to={`/events/${event.id}`}>{event.event_no}</Link>}
      </div>
    </div>
  );
}
