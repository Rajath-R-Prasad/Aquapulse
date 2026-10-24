import { useState } from 'react';
import { Outlet, useMatches, useNavigation } from 'react-router-dom';
import { useIsFetching } from '@tanstack/react-query';
import { RealtimeProvider } from '@/shared/supabase/realtime';
import { Sidebar } from './Sidebar';
import { Topbar } from './Topbar';
import NotificationsDrawer from '@/features/notifications/NotificationsDrawer';
import { cn } from '@/shared/lib/cn';

function TopProgress() {
  const fetching = useIsFetching({ predicate: (q) => q.state.data === undefined });
  const nav = useNavigation();
  const active = fetching > 0 || nav.state !== 'idle';
  return (
    <div className={cn('pointer-events-none fixed inset-x-0 top-0 z-[60] h-0.5 overflow-hidden transition-opacity', active ? 'opacity-100' : 'opacity-0')}>
      <div className="progress-bar h-full w-full bg-primary" />
    </div>
  );
}

export default function AppShell() {
  const [collapsed, setCollapsed] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const handle = [...useMatches()].reverse().find((m) => m.handle)?.handle ?? {};

  return (
    <RealtimeProvider>
      <div className="flex min-h-full">
        <Sidebar collapsed={collapsed} onToggle={() => setCollapsed((c) => !c)} />
        <div className="flex min-w-0 flex-1 flex-col">
          <TopProgress />
          <Topbar title={handle.title} onOpenNotifications={() => setNotifOpen(true)} />
          <main className={handle.fullBleed ? 'h-[calc(100vh-56px)]' : 'mx-auto w-full max-w-[1440px] p-6'}>
            <Outlet />
          </main>
        </div>
      </div>
      <NotificationsDrawer open={notifOpen} onClose={() => setNotifOpen(false)} />
    </RealtimeProvider>
  );
}
