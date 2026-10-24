export const toLatLng = ([lon, lat]) => [lat, lon];
export const lineToLatLngs = (g) => (g?.coordinates ?? []).map(toLatLng);
export const pointToLatLng = (g) => (g?.coordinates ? toLatLng(g.coordinates) : null);

export const MAP_CENTER = (import.meta.env?.VITE_MAP_CENTER ?? '12.2958,76.6394').split(',').map(Number);
export const MAP_ZOOM = Number(import.meta.env?.VITE_MAP_ZOOM ?? 17);
export const TILE_URL = import.meta.env?.VITE_MAP_TILE_URL ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
export const TILE_ATTRIBUTION = import.meta.env?.VITE_MAP_ATTRIBUTION ?? 'Map data © OpenStreetMap contributors';

export function parsePosition(v) {
  if (!v) return null;
  if (typeof v === 'object' && v.type === 'Point') return pointToLatLng(v);
  if (typeof v === 'object' && Number.isFinite(v.lat) && Number.isFinite(v.lon)) return [v.lat, v.lon];
  return null;
}
