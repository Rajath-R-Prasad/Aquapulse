import { memo, useEffect, useMemo, useRef } from 'react';
import L from 'leaflet';
import { CircleMarker, MapContainer, Marker, Polyline, Popup, TileLayer, Tooltip, useMap } from 'react-leaflet';
import { AssetPopup } from './AssetPopup';
import { MAP_CENTER, MAP_ZOOM, TILE_ATTRIBUTION, TILE_URL } from '../lib/geo';
import { PIPE_STATES, getStatus } from '../lib/statusMap';

const icons = new Map();
const icon = (key, html, size) => {
  if (!icons.has(key)) icons.set(key, L.divIcon({ className: '', html, iconSize: size, iconAnchor: [size[0] / 2, size[1] / 2] }));
  return icons.get(key);
};
const valveIcon = (closed) => icon(`valve-${closed}`, `<div class="jr-valve ${closed ? 'closed' : ''}"></div>`, [14, 14]);
const reservoirIcon = () => icon('reservoir', '<div class="jr-reservoir"></div>', [14, 14]);
const engineerIcon = () => icon('eng', '<div class="jr-eng"></div>', [16, 16]);
const eventIcon = (color, pulse) =>
  icon(`event-${color}-${pulse}`, `<div class="jr-event ${pulse ? 'pulse' : ''}" style="--c:${color}"></div>`, [20, 20]);

const isSource = (n) => ['RESERVOIR', 'TANK'].includes(n.node_kind ?? n.node_type);

function FitOnce({ bounds }) {
  const map = useMap();
  const done = useRef(false);
  useEffect(() => {
    if (done.current || !bounds) return;
    map.fitBounds(bounds, { padding: [24, 24], maxZoom: 19 });
    done.current = true;
  }, [bounds, map]);
  return null;
}

function Resizer() {
  const map = useMap();
  useEffect(() => {
    const el = map.getContainer();
    const ro = new ResizeObserver(() => map.invalidateSize());
    ro.observe(el);
    return () => ro.disconnect();
  }, [map]);
  return null;
}

const PipeLine = memo(function PipeLine({ pipe, selected, onSelect, popup, signals, event }) {
  const color = getStatus('pipeState', pipe.state).color;
  const base = pipe.state === 'LEAK' ? 7 : 4;
  const options = useMemo(
    () => ({
      color,
      weight: selected ? base + 3 : base,
      opacity: selected ? 1 : 0.9,
      dashArray: pipe.monitoring === 'SIMULATED' ? '6 6' : undefined,
    }),
    [color, selected, base, pipe.monitoring],
  );
  return (
    <Polyline
      positions={pipe.latlngs}
      pathOptions={options}
      eventHandlers={{
        click: () => onSelect?.(pipe),
        mouseover: (e) => e.target.setStyle({ weight: options.weight + 2 }),
        mouseout: (e) => e.target.setStyle({ weight: options.weight }),
      }}
    >
      <Tooltip sticky>{pipe.code}</Tooltip>
      {popup && (
        <Popup>
          <AssetPopup pipe={pipe} signals={signals} event={event} />
        </Popup>
      )}
    </Polyline>
  );
});

function Legend() {
  return (
    <div className="absolute bottom-4 left-3 z-10 rounded-md border border-line bg-surface/95 p-2 text-xs shadow-sm">
      {PIPE_STATES.map((s) => {
        const st = getStatus('pipeState', s);
        return (
          <div key={s} className="flex items-center gap-2 py-0.5">
            <span className="h-1 w-5 rounded-full" style={{ background: st.color }} />
            {st.label}
          </div>
        );
      })}
      <div className="mt-1 flex items-center gap-2 border-t border-line pt-1 text-ink-2">
        <span className="w-5 border-t-2 border-dashed border-ink-2" /> Simulated
      </div>
    </div>
  );
}

export default function MapView({
  pipes = [], nodes = [], valves = [], events = [], markers = [], lines = [], signals = [],
  selectedCode, onSelectPipe, onSelectEvent, popup = false, legend = false, fitPoints, fitKey,
}) {
  const hasPipes = pipes.length > 0;
  const bounds = useMemo(() => {
    const pts = fitPoints ?? pipes.flatMap((p) => p.latlngs);
    return pts.length ? L.latLngBounds(pts) : null;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fitPoints, hasPipes]);

  const eventByCode = useMemo(() => new Map(events.map((e) => [e.pipe_code, e])), [events]);

  return (
    <div className="relative h-full w-full">
      <MapContainer key={fitKey} center={MAP_CENTER} zoom={MAP_ZOOM} preferCanvas className="h-full w-full" scrollWheelZoom>
        <TileLayer url={TILE_URL} attribution={TILE_ATTRIBUTION} maxZoom={19} />
        <FitOnce bounds={bounds} />
        <Resizer />

        {pipes.map((p) => (
          <PipeLine
            key={p.id ?? p.code}
            pipe={p}
            selected={p.code === selectedCode}
            onSelect={onSelectPipe}
            popup={popup}
            signals={signals}
            event={eventByCode.get(p.code)}
          />
        ))}

        {lines.map((l, i) => (
          <Polyline key={i} positions={l.positions} pathOptions={{ color: l.color ?? '#DC2626', weight: l.weight ?? 6, dashArray: l.dashArray, opacity: 0.85 }} />
        ))}

        {nodes.filter((n) => n.latlng).map((n) =>
          isSource(n) ? (
            <Marker key={n.id ?? n.code} position={n.latlng} icon={reservoirIcon()}><Tooltip>{n.code}</Tooltip></Marker>
          ) : (
            <CircleMarker key={n.id ?? n.code} center={n.latlng} radius={3} pathOptions={{ color: '#334155', fillColor: '#fff', fillOpacity: 1, weight: 1.5 }}>
              <Tooltip>{n.code}</Tooltip>
            </CircleMarker>
          ),
        )}

        {valves.filter((v) => v.latlng).map((v) => (
          <Marker key={v.id ?? v.code} position={v.latlng} icon={valveIcon(v.state === 'CLOSED')}>
            <Tooltip>{v.code} · {getStatus('valveState', v.state).label}</Tooltip>
          </Marker>
        ))}

        {events.filter((e) => Number.isFinite(e.lat) && Number.isFinite(e.lon)).map((e) => (
          <Marker
            key={e.id}
            position={[e.lat, e.lon]}
            icon={eventIcon(getStatus('severity', e.severity).color, e.status === 'DETECTED' && ['MAJOR', 'CRITICAL'].includes(e.severity))}
            eventHandlers={{ click: () => onSelectEvent?.(e) }}
            zIndexOffset={500}
          >
            <Tooltip>{e.event_no} · {getStatus('severity', e.severity).label}</Tooltip>
          </Marker>
        ))}

        {markers.map((m) => (
          <Marker key={m.id} position={m.latlng} icon={engineerIcon()}><Tooltip>{m.label}</Tooltip></Marker>
        ))}
      </MapContainer>
      {legend && <Legend />}
    </div>
  );
}
