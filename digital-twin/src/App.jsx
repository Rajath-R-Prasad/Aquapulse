import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Activity, AlertTriangle, ArrowUpRight, Check, ChevronRight, CircleHelp, Droplets,
  Gauge, Pause, Play, Plus, RefreshCw, RotateCcw, Waves, X,
} from 'lucide-react';

const fmt = (value, digits = 1) => (
  value == null || !Number.isFinite(Number(value)) ? '—' : Number(value).toFixed(digits)
);

async function request(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: {
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...options.headers,
    },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || `${path} failed with HTTP ${response.status}`);
  return data;
}

function geometryPoints(geometry) {
  if (geometry?.type === 'Point') return [geometry.coordinates];
  if (geometry?.type === 'LineString') return geometry.coordinates ?? [];
  if (geometry?.type === 'MultiLineString') return geometry.coordinates?.flat() ?? [];
  return [];
}

function NetworkDiagram({ features, leaks, selectedCode, onSelect }) {
  const layout = useMemo(() => {
    const pipeFeatures = features.filter((feature) => feature.properties?.feature_type === 'PIPE');
    const nodeFeatures = features.filter((feature) => feature.properties?.feature_type === 'NODE');
    const coordinates = features.flatMap((feature) => geometryPoints(feature.geometry));
    if (!coordinates.length) return { pipes: [], nodes: [], width: 1000, height: 620 };

    const xs = coordinates.map(([x]) => Number(x));
    const ys = coordinates.map(([, y]) => Number(y));
    const minX = Math.min(...xs);
    const maxX = Math.max(...xs);
    const minY = Math.min(...ys);
    const maxY = Math.max(...ys);
    const padding = 70;
    const width = 1000;
    const height = 620;
    const mapPoint = ([lon, lat]) => [
      padding + ((Number(lon) - minX) / Math.max(maxX - minX, 0.00001)) * (width - padding * 2),
      height - padding - ((Number(lat) - minY) / Math.max(maxY - minY, 0.00001)) * (height - padding * 2),
    ];
    const pipes = pipeFeatures.map((feature) => {
      const segments = feature.geometry?.type === 'MultiLineString'
        ? feature.geometry.coordinates
        : [feature.geometry?.coordinates ?? []];
      const points = segments.flat().map(mapPoint);
      const middle = points[Math.floor(points.length / 2)] ?? [width / 2, height / 2];
      return {
        feature,
        points,
        middle,
        path: segments.map((segment) => segment.map(mapPoint)
          .map(([x, y], index) => `${index ? 'L' : 'M'}${x},${y}`).join(' ')).join(' '),
      };
    });
    const nodes = nodeFeatures.map((feature) => ({
      feature,
      point: mapPoint(feature.geometry?.coordinates ?? [0, 0]),
    }));
    return { pipes, nodes, width, height };
  }, [features]);

  const pipeColors = { NORMAL: '#2dd4bf', WARNING: '#fbbf24', LEAK: '#fb7185', ISOLATED: '#a78bfa' };
  if (!layout.pipes.length) {
    return <div className="grid h-full place-items-center text-sm text-slate-600">Network geometry is unavailable.</div>;
  }

  return (
    <svg
      className="grid-bg h-full w-full"
      viewBox={`0 0 ${layout.width} ${layout.height}`}
      role="img"
      aria-label="Interactive pipeline network; select a simulated pipe to create a leak"
    >
      <defs>
        <pattern id="water-dots" width="30" height="30" patternUnits="userSpaceOnUse">
          <circle cx="1" cy="1" r="1" fill="#94a3b8" opacity="0.22" />
        </pattern>
      </defs>
      <rect width={layout.width} height={layout.height} fill="url(#water-dots)" />
      {layout.pipes.map(({ feature, points, middle, path }) => {
        const pipe = feature.properties;
        const active = pipe.code in leaks;
        const isSelected = pipe.code === selectedCode;
        const color = active ? pipeColors.LEAK : pipeColors[pipe.state] || pipeColors.NORMAL;
        return (
          <g
            key={pipe.code}
            role={pipe.monitoring === 'SIMULATED' ? 'button' : undefined}
            tabIndex={pipe.monitoring === 'SIMULATED' ? 0 : undefined}
            aria-label={`${pipe.code}, ${pipe.state}, ${pipe.monitoring}`}
            onClick={() => pipe.monitoring === 'SIMULATED' && onSelect(pipe.code)}
            onKeyDown={(event) => {
              if (pipe.monitoring === 'SIMULATED' && (event.key === 'Enter' || event.key === ' ')) {
                event.preventDefault();
                onSelect(pipe.code);
              }
            }}
            className={pipe.monitoring === 'SIMULATED' ? 'cursor-pointer' : ''}
          >
            <path d={path} fill="none" stroke="transparent" strokeWidth="26" />
            <path
              d={path}
              fill="none"
              stroke={color}
              strokeWidth={isSelected ? 7 : active ? 6 : 4}
              strokeLinecap="round"
              strokeLinejoin="round"
              opacity={pipe.monitoring === 'SIMULATED' ? 0.94 : 0.35}
            />
            {active && (
              <g transform={`translate(${middle[0]} ${middle[1]})`} pointerEvents="none">
                <circle r="16" fill="#fb7185" opacity="0.35" className="leak-pulse" />
                <circle r="7" fill="#fb7185" stroke="#ffe4e6" strokeWidth="2" />
                <text y="-17" textAnchor="middle" fill="#9f1239" className="fill-rose-100 text-[12px] font-bold">
                  {pipe.code}
                </text>
              </g>
            )}
            {!active && (
              <text
                x={middle[0]}
                y={middle[1] - 10}
                textAnchor="middle"
                fill={isSelected ? '#0f766e' : '#64748b'}
                className="pointer-events-none text-[10px] font-medium"
              >
                {pipe.code}
              </text>
            )}
            {isSelected && points.length > 0 && (
              <circle cx={points[0][0]} cy={points[0][1]} r="8" fill="#ecfeff" stroke="#0f766e" strokeWidth="4" />
            )}
          </g>
        );
      })}
      {layout.nodes.map(({ feature, point }) => (
        <g key={feature.properties.code} pointerEvents="none">
          <circle cx={point[0]} cy={point[1]} r="6" fill="#dbeafe" stroke="#64748b" strokeWidth="3" />
          <text x={point[0] + 11} y={point[1] + 4} fill="#64748b" className="text-[10px]">
            {feature.properties.code}
          </text>
        </g>
      ))}
    </svg>
  );
}

function Stat({ icon: Icon, label, value, detail, tone = 'teal' }) {
  const tones = {
    teal: 'text-teal-700 bg-teal-400/10',
    rose: 'text-rose-300 bg-rose-400/10',
    amber: 'text-amber-300 bg-amber-400/10',
    blue: 'text-sky-700 bg-sky-400/10',
  };
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4">
      <div className="flex items-start justify-between">
        <span className="text-xs font-medium uppercase tracking-[0.13em] text-slate-600">{label}</span>
        <span className={`grid size-9 place-items-center rounded-xl ${tones[tone]}`}><Icon size={17} /></span>
      </div>
      <div className="mt-4 text-2xl font-semibold tracking-tight text-slate-900">{value}</div>
      <div className="mt-1 text-xs text-slate-500">{detail}</div>
    </div>
  );
}

export default function App() {
  const [features, setFeatures] = useState([]);
  const [twinState, setTwinState] = useState(null);
  const [selectedCode, setSelectedCode] = useState('');
  const [leakRate, setLeakRate] = useState(12);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const pipes = useMemo(
    () => features.filter((feature) => feature.properties?.feature_type === 'PIPE'),
    [features],
  );
  const simulatedPipes = useMemo(
    () => pipes.filter((feature) => feature.properties.monitoring === 'SIMULATED'),
    [pipes],
  );
  const leaks = twinState?.leak_rates_lpm ?? {};
  const selectedPipe = simulatedPipes.find((feature) => feature.properties.code === selectedCode)?.properties;
  const maxLeak = selectedPipe
    ? Math.max(0.1, Math.min(2000, Number(selectedPipe.design_flow_lpm) * 0.55))
    : 100;
  const readings = new Map((twinState?.readings ?? []).map((reading) => [reading.pipe_code, reading]));

  const refresh = useCallback(async () => {
    try {
      const [network, state] = await Promise.all([request('/api/network'), request('/api/state')]);
      setFeatures(network.features ?? []);
      setTwinState(state);
      setSelectedCode((current) => current || network.features?.find(
        (feature) => feature.properties?.feature_type === 'PIPE' && feature.properties.monitoring === 'SIMULATED',
      )?.properties?.code || '');
      setError('');
    } catch (cause) {
      setError(cause.message);
    }
  }, []);

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 5_000);
    return () => clearInterval(timer);
  }, [refresh]);

  const perform = async (path, options = {}) => {
    setBusy(true);
    setError('');
    try {
      const state = await request(path, options);
      setTwinState(state);
    } catch (cause) {
      await refresh();
      setError(cause.message);
    } finally {
      setBusy(false);
    }
  };

  const addLeak = () => {
    if (!selectedPipe) return;
    perform('/api/leaks', {
      method: 'POST',
      body: JSON.stringify({ pipe_code: selectedPipe.code, leak_rate_lpm: Math.min(Number(leakRate), maxLeak) }),
    });
  };

  const activeLeakCount = Object.keys(leaks).length;
  const latest = twinState?.last_snapshot_at
    ? new Date(twinState.last_snapshot_at).toLocaleTimeString()
    : 'No readings yet';
  const liveState = twinState?.running;

  return (
    <main className="mx-auto min-h-screen max-w-[1600px] px-4 pb-12 pt-5 sm:px-7 lg:px-10 bg-slate-50">
      <header className="flex flex-wrap items-center justify-between gap-4 border-b border-slate-200 pb-5">
        <div className="flex items-center gap-3">
          <div className="grid size-11 place-items-center rounded-2xl border border-teal-200 bg-teal-50 text-teal-700">
            <Waves size={22} />
          </div>
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-teal-700">AquaPulse / Simulation lab</p>
            <h1 className="mt-0.5 text-xl font-semibold tracking-tight text-slate-900 sm:text-2xl">Digital twin control room</h1>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <div className={`flex items-center gap-2 rounded-full border px-3 py-2 text-xs font-medium ${liveState ? 'border-teal-200 bg-teal-50 text-teal-700' : 'border-slate-200 bg-slate-100 text-slate-600'}`}>
            <span className={`size-2 rounded-full ${liveState ? 'animate-pulse bg-teal-600' : 'bg-slate-500'}`} />
            {liveState ? 'Twin running' : 'Twin stopped'}
          </div>
          <button
            type="button"
            onClick={() => refresh()}
            className="grid size-10 place-items-center rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-100"
            aria-label="Refresh twin status"
          >
            <RefreshCw size={16} />
          </button>
        </div>
      </header>

      {error && (
        <div className="mt-5 flex items-start gap-3 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800" role="alert">
          <AlertTriangle size={18} className="mt-0.5 shrink-0 text-rose-300" />
          <div className="flex-1"><strong className="font-semibold">Twin connection issue</strong><p className="mt-1 text-rose-700">{error}</p></div>
          <button type="button" onClick={() => setError('')} aria-label="Dismiss error"><X size={16} /></button>
        </div>
      )}
      {twinState?.last_error && !error && (
        <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800" role="status">
          Latest snapshot failed: {twinState.last_error}
        </div>
      )}

      <section className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4" aria-label="Twin summary">
        <Stat icon={Activity} label="Network pipes" value={pipes.length} detail={`${simulatedPipes.length} controllable simulated assets`} />
        <Stat icon={AlertTriangle} label="Active leak scenarios" value={activeLeakCount} detail="Leaks currently injected into the twin" tone="rose" />
        <Stat icon={Gauge} label="Simulation feed" value={liveState ? 'Live' : 'Paused'} detail={liveState ? `Latest snapshot ${latest}` : 'Start the twin to publish readings'} tone={liveState ? 'teal' : 'amber'} />
        <Stat icon={Waves} label="Snapshot cadence" value="5 sec" detail="Readings pass through backend detection" tone="blue" />
      </section>

      <section className="mt-6 grid gap-5 xl:grid-cols-[minmax(0,1.7fr)_minmax(330px,0.8fr)]">
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-5 py-4">
            <div>
              <h2 className="font-semibold text-slate-900">Interactive pipeline network</h2>
              <p className="mt-1 text-xs text-slate-600">Select a dashed simulated pipe to configure a leak</p>
            </div>
            <div className="flex flex-wrap items-center gap-3 text-[11px] text-slate-600">
              <span className="flex items-center gap-1.5"><i className="h-1 w-5 rounded bg-teal-600" /> Normal</span>
              <span className="flex items-center gap-1.5"><i className="h-1 w-5 rounded bg-amber-300" /> Warning</span>
              <span className="flex items-center gap-1.5"><i className="h-1 w-5 rounded bg-rose-400" /> Leak</span>
              <span className="flex items-center gap-1.5"><i className="h-1 w-5 border-t border-dashed border-slate-400" /> Simulated</span>
            </div>
          </div>
          <div className="grid-bg h-[390px] p-2 sm:h-[540px] sm:p-4">
            <NetworkDiagram
              features={features}
              leaks={leaks}
              selectedCode={selectedCode}
              onSelect={setSelectedCode}
            />
          </div>
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1 border-t border-slate-200 px-5 py-3 text-xs text-slate-600">
            <CircleHelp size={14} className="text-teal-700" />
            Leak markers appear on the selected pipe. Detection warnings and confirmed events flow to the operator dashboard.
          </div>
        </div>

        <aside className="space-y-5">
          <section className="rounded-2xl border border-slate-200 bg-white p-5">
            <div className="flex items-start justify-between gap-3">
              <div>
                <div className="flex items-center gap-2 text-teal-700"><Droplets size={17} /><h2 className="font-semibold text-slate-900">Leak scenario controls</h2></div>
                <p className="mt-1.5 text-xs leading-relaxed text-slate-600">Inject a controlled flow loss into a simulated pipe. The backend analyzes the resulting snapshots.</p>
              </div>
              <span className="rounded-lg bg-slate-100 px-2 py-1 text-[10px] uppercase tracking-wider text-slate-600">Demo</span>
            </div>

            <label className="mt-5 block text-xs font-medium text-slate-600" htmlFor="pipe-select">Simulated pipe</label>
            <select
              id="pipe-select"
              value={selectedCode}
              onChange={(event) => setSelectedCode(event.target.value)}
              className="mt-2 h-11 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-sm text-slate-800"
            >
              {simulatedPipes.map((feature) => (
                <option key={feature.properties.code} value={feature.properties.code}>
                  {feature.properties.code} · {feature.properties.diameter_mm} mm · {fmt(feature.properties.design_flow_lpm, 0)} L/min design
                </option>
              ))}
            </select>

            <div className="mt-5 flex items-center justify-between">
              <label htmlFor="leak-rate" className="text-xs font-medium text-slate-600">Leak rate</label>
              <span className="rounded-lg border border-rose-200 bg-rose-50 px-2.5 py-1 text-sm font-semibold text-rose-700">
                {fmt(Math.min(leakRate, maxLeak))} <span className="text-xs font-normal text-rose-700">L/min</span>
              </span>
            </div>
            <input
              id="leak-rate"
              type="range"
              min="0.1"
              max={maxLeak}
              step={Math.max(0.1, maxLeak / 100)}
              value={Math.min(leakRate, maxLeak)}
              onChange={(event) => setLeakRate(Number(event.target.value))}
              className="mt-4 w-full accent-rose-400"
            />
            <div className="mt-1 flex justify-between text-[10px] text-slate-500">
              <span>0.1 L/min</span><span>Max {fmt(maxLeak)} L/min</span>
            </div>

            <button
              type="button"
              disabled={!selectedPipe || busy}
              onClick={addLeak}
              className="mt-5 flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-rose-400 font-semibold text-white transition hover:bg-rose-300 disabled:cursor-not-allowed disabled:opacity-50"
            >
              <Plus size={17} /> Inject / update leak
            </button>
            {leaks[selectedCode] != null && (
              <button
                type="button"
                disabled={busy}
                onClick={() => perform(`/api/leaks/${encodeURIComponent(selectedCode)}`, { method: 'DELETE' })}
                className="mt-2 flex h-10 w-full items-center justify-center gap-2 rounded-xl border border-slate-200 text-sm text-slate-600 hover:bg-slate-100 disabled:opacity-50"
              >
                <X size={15} /> Clear leak on {selectedCode}
              </button>
            )}

            <div className="mt-5 border-t border-slate-200 pt-4">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <p className="text-sm font-medium text-slate-700">Twin snapshot feed</p>
                  <p className="mt-1 text-xs text-slate-500">5-second readings · same backend pipeline</p>
                </div>
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => perform(liveState ? '/api/stop' : '/api/start', { method: 'POST' })}
                  className={`grid size-11 place-items-center rounded-full transition disabled:opacity-50 ${liveState ? 'border border-amber-200 bg-amber-50 text-amber-800 hover:bg-amber-300/20' : 'bg-teal-600 text-white hover:bg-teal-700'}`}
                  aria-label={liveState ? 'Stop twin feed' : 'Start twin feed'}
                >
                  {liveState ? <Pause size={18} /> : <Play size={18} fill="currentColor" />}
                </button>
              </div>
              <div className="mt-3 flex items-center gap-2 text-xs text-slate-500">
                {liveState ? <><span className="size-1.5 rounded-full bg-teal-600" /> Publishing live readings</> : <><span className="size-1.5 rounded-full bg-slate-400" /> Feed is stopped</>}
              </div>
            </div>
          </section>

          <section className="rounded-2xl border border-slate-200 bg-white p-5">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="font-semibold text-slate-900">Injected leaks</h2>
                <p className="mt-1 text-xs text-slate-600">Current simulated conditions</p>
              </div>
              {activeLeakCount > 0 && (
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => perform('/api/leaks', { method: 'DELETE' })}
                  className="flex items-center gap-1.5 text-xs text-slate-600 hover:text-slate-900 disabled:opacity-50"
                >
                  <RotateCcw size={13} /> Clear all
                </button>
              )}
            </div>
            <div className="mt-4 space-y-2">
              {Object.entries(leaks).length ? Object.entries(leaks).map(([code, rate]) => {
                const reading = readings.get(code);
                return (
                  <button
                    type="button"
                    key={code}
                    onClick={() => setSelectedCode(code)}
                    className={`flex w-full items-center justify-between rounded-xl border px-3 py-3 text-left ${selectedCode === code ? 'border-rose-200 bg-rose-50' : 'border-slate-200 bg-slate-50/60 hover:bg-slate-100'}`}
                  >
                    <span className="flex items-center gap-2.5">
                      <span className="grid size-8 place-items-center rounded-lg bg-rose-50 text-rose-300"><Droplets size={15} /></span>
                      <span><strong className="block text-sm font-semibold text-slate-800">{code}</strong><small className="text-xs text-slate-500">Pressure {fmt(reading?.pressure_in)} kPa</small></span>
                    </span>
                    <span className="flex items-center gap-2 text-sm font-medium text-rose-700">{fmt(rate)} L/min <ChevronRight size={14} className="text-slate-500" /></span>
                  </button>
                );
              }) : (
                <div className="rounded-xl border border-dashed border-slate-200 px-4 py-5 text-center text-xs text-slate-500">
                  No leaks injected. Select a dashed pipe on the network to begin.
                </div>
              )}
            </div>
          </section>
        </aside>
      </section>

      <section className="mt-5 overflow-hidden rounded-2xl border border-slate-200 bg-white">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-5 py-4">
          <div>
            <h2 className="font-semibold text-slate-900">Live pipe telemetry</h2>
            <p className="mt-1 text-xs text-slate-600">Values from the most recent twin snapshot · last update {latest}</p>
          </div>
          <span className="flex items-center gap-1.5 text-xs text-slate-600"><RefreshCw size={13} /> Refreshes automatically</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[690px] text-left text-sm">
            <thead className="bg-slate-50 text-[10px] uppercase tracking-[0.12em] text-slate-500">
              <tr>
                <th className="px-5 py-3 font-medium">Pipe</th>
                <th className="px-4 py-3 font-medium">Condition</th>
                <th className="px-4 py-3 font-medium">Leak injection</th>
                <th className="px-4 py-3 font-medium">Flow in</th>
                <th className="px-4 py-3 font-medium">Flow out</th>
                <th className="px-4 py-3 font-medium">Pressure</th>
                <th className="px-4 py-3 font-medium">Delta flow</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.05]">
              {simulatedPipes.map((feature) => {
                const pipe = feature.properties;
                const reading = readings.get(pipe.code);
                const isLeaking = leaks[pipe.code] != null;
                const condition = isLeaking ? 'LEAK' : pipe.state;
              const conditionClass =
  condition === 'LEAK'
    ? 'bg-red-100 text-red-700 ring-1 ring-inset ring-red-200'
    : condition === 'ISOLATED'
      ? 'bg-gray-100 text-gray-700 ring-1 ring-inset ring-gray-300'
      : condition === 'WARNING' ||
          condition === 'PENDING_VERIFICATION'
        ? 'bg-amber-50 text-amber-800'
        : 'bg-teal-50 text-teal-700';
                const delta = reading ? Number(reading.flow_in) - Number(reading.flow_out) : null;
                return (
                  <tr
                    key={pipe.code}
                    onClick={() => setSelectedCode(pipe.code)}
                    className={`cursor-pointer transition hover:bg-slate-100 ${selectedCode === pipe.code ? 'bg-teal-600/[0.04]' : ''}`}
                  >
                    <td className="px-5 py-3 font-semibold text-slate-800">{pipe.code}<small className="ml-2 font-normal text-slate-500">{pipe.diameter_mm} mm</small></td>
                    <td className="px-4 py-3"><span className={`rounded-full px-2 py-1 text-[10px] font-medium ${conditionClass}`}>{condition}</span></td>
                    <td className="px-4 py-3 text-slate-600">{isLeaking ? `${fmt(leaks[pipe.code])} L/min` : '—'}</td>
                    <td className="px-4 py-3 text-slate-600">{reading ? `${fmt(reading.flow_in)} L/min` : '—'}</td>
                    <td className="px-4 py-3 text-slate-600">{reading ? `${fmt(reading.flow_out)} L/min` : '—'}</td>
                    <td className="px-4 py-3 text-slate-600">{reading ? `${fmt(reading.pressure_in)} kPa` : '—'}</td>
                    <td className={`px-4 py-3 ${isLeaking ? 'text-rose-700' : 'text-slate-500'}`}>{delta == null ? '—' : `${delta >= 0 ? '+' : ''}${fmt(delta)} L/min`}</td>
                  </tr>
                );
              })}
              {!simulatedPipes.length && (
                <tr><td colSpan="7" className="px-5 py-10 text-center text-sm text-slate-500">Load the twin network to see simulated pipe telemetry.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <footer className="mt-5 flex flex-wrap items-center justify-between gap-2 text-[11px] text-slate-500">
        <span className="flex items-center gap-1.5"><Check size={13} className="text-teal-700" /> Simulator posts readings to the shared AquaPulse backend</span>
        <a href="http://localhost:5173/" target="_blank" rel="noreferrer" className="flex items-center gap-1.5 text-teal-700 hover:text-teal-700">
          Open operator dashboard <ArrowUpRight size={13} />
        </a>
      </footer>
    </main>
  );
}
