import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Bell, Search } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/shared/supabase/client';
import { useLiveStatus } from '@/shared/supabase/realtime';
import { useMe } from '@/features/auth/useMe';
import { useUnreadCount } from '@/features/notifications/hooks';
import { useGlobalSearch } from '@/shared/data/events';
import { usePipeMap } from '@/shared/data/network';
import { useDebounced } from '@/shared/lib/hooks';
import { StatusBadge } from '@/shared/ui/Badges';
import { cn } from '@/shared/lib/cn';

const LIVE = {
  live: { label: 'Live', dot: 'bg-success', text: 'text-success' },
  reconnecting: { label: 'Reconnecting', dot: 'bg-warning', text: 'text-warning' },
  offline: { label: 'Offline, data may be stale', dot: 'bg-danger', text: 'text-danger' },
};

export function LiveIndicator() {
  const s = LIVE[useLiveStatus()];
  return (
    <span role="status" className={cn('flex items-center gap-1.5 text-xs font-medium', s.text)}>
      <span className={cn('size-2 rounded-full', s.dot)} />
      {s.label}
    </span>
  );
}

function GlobalSearch() {
  const [q, setQ] = useState('');
  const [open, setOpen] = useState(false);
  const debounced = useDebounced(q.trim(), 250);
  const events = useGlobalSearch(debounced);
  const { pipes } = usePipeMap();
  const navigate = useNavigate();
  const ref = useRef(null);

  useEffect(() => {
    const down = (e) => !ref.current?.contains(e.target) && setOpen(false);
    document.addEventListener('mousedown', down);
    return () => document.removeEventListener('mousedown', down);
  }, []);

  const pipeHits = debounced.length >= 2 ? pipes.filter((p) => p.code.toLowerCase().includes(debounced.toLowerCase())).slice(0, 4) : [];
  const go = (path) => {
    setOpen(false);
    setQ('');
    navigate(path);
  };

  return (
    <div ref={ref} className="relative w-72">
      <Search className="pointer-events-none absolute left-3 top-2.5 size-4 text-ink-3" aria-hidden="true" />
      <input
        value={q}
        onChange={(e) => { setQ(e.target.value); setOpen(true); }}
        onFocus={() => setOpen(true)}
        placeholder="Search event number or pipe"
        aria-label="Search events and pipes"
        className="h-9 w-full rounded-md border border-line-strong bg-surface pl-9 pr-3 text-sm"
      />
      {open && debounced.length >= 2 && (
        <ul className="absolute z-40 mt-1 w-full overflow-hidden rounded-md border border-line bg-surface p-1 shadow-md">
          {(events.data ?? []).map((e) => (
            <li key={e.id}>
              <button type="button" onClick={() => go(`/events/${e.id}`)} className="flex w-full items-center justify-between gap-2 rounded-sm px-2 py-1.5 text-left text-sm hover:bg-muted">
                <span>{e.event_no} <span className="text-ink-3">· {e.pipe_code}</span></span>
                <StatusBadge domain="severity" value={e.severity} />
              </button>
            </li>
          ))}
          {pipeHits.map((p) => (
            <li key={p.id}>
              <button type="button" onClick={() => go(`/map?pipe=${p.code}`)} className="flex w-full items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm hover:bg-muted">
                <span>Pipe {p.code}</span>
                <StatusBadge domain="pipeState" value={p.state} />
              </button>
            </li>
          ))}
          {!events.isFetching && !(events.data ?? []).length && !pipeHits.length && <li className="px-2 py-2 text-sm text-ink-3">No results</li>}
        </ul>
      )}
    </div>
  );
}

function UserMenu() {
  const me = useMe();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!open) return undefined;
    const down = (e) => !ref.current?.contains(e.target) && setOpen(false);
    document.addEventListener('mousedown', down);
    return () => document.removeEventListener('mousedown', down);
  }, [open]);

  const name = me.data?.full_name ?? '';
  const initials = name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase() || '?';
  return (
    <div ref={ref} className="relative">
      <button type="button" aria-label="User menu" aria-expanded={open} onClick={() => setOpen(!open)} className="flex size-9 items-center justify-center rounded-full bg-primary-soft text-sm font-semibold text-primary">
        {initials}
      </button>
      {open && (
        <div className="absolute right-0 z-40 mt-2 w-56 rounded-md border border-line bg-surface p-1 shadow-md">
          <div className="border-b border-line px-3 py-2">
            <p className="text-sm font-medium">{name}</p>
            <p className="text-xs text-ink-3">{me.data?.role}</p>
          </div>
          <Link to="/settings" onClick={() => setOpen(false)} className="block rounded-sm px-3 py-2 text-sm hover:bg-muted">Settings</Link>
          <button
            type="button"
            onClick={async () => { await supabase.auth.signOut(); qc.clear(); }}
            className="block w-full rounded-sm px-3 py-2 text-left text-sm hover:bg-muted"
          >
            Sign out
          </button>
        </div>
      )}
    </div>
  );
}

export function Topbar({ title, onOpenNotifications }) {
  const unread = useUnreadCount();
  return (
    <header className="sticky top-0 z-30 flex h-14 items-center gap-4 border-b border-line bg-surface px-6">
      <h1 className="text-lg font-semibold">{title}</h1>
      <div className="ml-auto flex items-center gap-4">
        <GlobalSearch />
        <LiveIndicator />
        <button type="button" onClick={onOpenNotifications} aria-label={`Notifications${unread ? `, ${unread} unread` : ''}`} className="relative flex size-9 items-center justify-center rounded-md hover:bg-muted">
          <Bell className="size-5" />
          {unread > 0 && (
            <span className="absolute -right-0.5 -top-0.5 flex min-w-4 items-center justify-center rounded-full bg-danger px-1 text-[10px] font-semibold text-white">{unread > 99 ? '99+' : unread}</span>
          )}
        </button>
        <UserMenu />
      </div>
    </header>
  );
}
