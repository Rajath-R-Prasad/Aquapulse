import { useRef, useState } from 'react';
import { Check, ImageOff, TriangleAlert, ZoomIn, ZoomOut } from 'lucide-react';
import { Overlay } from '@/shared/ui/Overlay';
import { Button } from '@/shared/ui/Button';
import { Chip } from '@/shared/ui/Badges';
import { Time } from '@/shared/ui/Time';
import { TileSkeleton } from '@/shared/ui/Skeletons';
import { EmptyState } from '@/shared/ui/States';
import { fmtNum } from '@/shared/lib/format';

function Photo({ item, refetch, className = '', zoom = 1 }) {
  const [loaded, setLoaded] = useState(false);
  const [failed, setFailed] = useState(false);
  const retried = useRef(false);

  const onError = () => {
    if (!retried.current) {
      retried.current = true;
      refetch();
    } else setFailed(true);
  };

  if (failed) {
    return (
      <div className={`flex flex-col items-center justify-center gap-2 bg-muted text-ink-2 ${className}`}>
        <ImageOff className="size-6" aria-hidden="true" />
        <Button variant="outline" onClick={() => { setFailed(false); retried.current = false; refetch(); }}>Retry</Button>
      </div>
    );
  }
  return (
    <div className={`relative overflow-hidden bg-muted ${className}`}>
      {!loaded && <div className="skeleton absolute inset-0" />}
      <img
        src={item.url}
        alt={`${item.kind === 'BEFORE_PHOTO' ? 'Before' : 'After'} repair`}
        onLoad={() => setLoaded(true)}
        onError={onError}
        style={{ transform: `scale(${zoom})`, transition: 'transform 150ms ease-out' }}
        className={`size-full object-cover ${loaded ? 'fade-img' : 'opacity-0'}`}
      />
    </div>
  );
}

function DistanceBadge({ item }) {
  if (item.geo_valid == null) return <Chip tone="grey">No location</Chip>;
  return item.geo_valid ? (
    <Chip tone="success" icon={Check}>Within 50 m</Chip>
  ) : (
    <Chip tone="danger" icon={TriangleAlert}>Too far{item.distance_to_leak_m != null && ` (${fmtNum(item.distance_to_leak_m, 0)} m)`}</Chip>
  );
}

function Lightbox({ item, before, after, onClose, refetch }) {
  const [zoom, setZoom] = useState(1);
  const [compare, setCompare] = useState(false);
  const [pos, setPos] = useState(50);
  const canCompare = before && after;

  return (
    <Overlay open onClose={onClose} title={item.kind === 'BEFORE_PHOTO' ? 'Before photo' : 'After photo'} className="!max-w-3xl">
      <div className="space-y-3">
        <div className="flex flex-wrap items-center gap-2">
          <Button variant="outline" icon={ZoomOut} onClick={() => setZoom((z) => Math.max(1, z - 0.5))} disabled={compare || zoom <= 1} aria-label="Zoom out" />
          <Button variant="outline" icon={ZoomIn} onClick={() => setZoom((z) => Math.min(4, z + 0.5))} disabled={compare || zoom >= 4} aria-label="Zoom in" />
          {canCompare && <Button variant={compare ? 'primary' : 'outline'} onClick={() => setCompare((c) => !c)}>Compare before / after</Button>}
          <DistanceBadge item={item} />
        </div>
        {compare && canCompare ? (
          <div>
            <div className="relative aspect-[4/3] w-full overflow-hidden rounded-md">
              <Photo item={before} refetch={refetch} className="absolute inset-0" />
              <div className="absolute inset-0" style={{ clipPath: `inset(0 0 0 ${pos}%)` }}>
                <Photo item={after} refetch={refetch} className="size-full" />
              </div>
              <div className="pointer-events-none absolute inset-y-0 w-0.5 bg-white shadow" style={{ left: `${pos}%` }} />
            </div>
            <input type="range" min={0} max={100} value={pos} onChange={(e) => setPos(Number(e.target.value))} aria-label="Compare slider" className="mt-2 w-full" />
            <div className="flex justify-between text-xs text-ink-2"><span>Before</span><span>After</span></div>
          </div>
        ) : (
          <Photo item={item} refetch={refetch} zoom={zoom} className="aspect-[4/3] w-full rounded-md" />
        )}
        <p className="text-xs text-ink-2">Captured <Time value={item.captured_at} /></p>
      </div>
    </Overlay>
  );
}

function Group({ title, items, onOpen, refetch }) {
  return (
    <div>
      <h3 className="mb-2 text-sm font-semibold">{title}</h3>
      {items.length === 0 ? (
        <EmptyState title={`No ${title.toLowerCase()} photos`} className="rounded-md border border-dashed border-line py-6" />
      ) : (
        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
          {items.map((it) => (
            <div key={it.id} className="space-y-1.5">
              <button type="button" onClick={() => onOpen(it)} className="block w-full overflow-hidden rounded-md border border-line" aria-label={`Open ${title.toLowerCase()} photo`}>
                <Photo item={it} refetch={refetch} className="aspect-[4/3] w-full" />
              </button>
              <DistanceBadge item={it} />
              <p className="text-xs text-ink-3"><Time value={it.captured_at} pattern="d MMM, h:mm aaa" /></p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export function EvidenceGallery({ items, loading, refetch }) {
  const [open, setOpen] = useState(null);
  if (loading) {
    return (
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => <TileSkeleton key={i} />)}
      </div>
    );
  }
  const before = items.filter((i) => i.kind === 'BEFORE_PHOTO');
  const after = items.filter((i) => i.kind === 'AFTER_PHOTO');
  return (
    <div className="space-y-5">
      <Group title="Before" items={before} onOpen={setOpen} refetch={refetch} />
      <Group title="After" items={after} onOpen={setOpen} refetch={refetch} />
      {open && <Lightbox item={open} before={before[0]} after={after[0]} onClose={() => setOpen(null)} refetch={refetch} />}
    </div>
  );
}
