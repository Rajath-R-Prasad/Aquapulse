import { NavLink } from 'react-router-dom';
import {
  ClipboardCheck, Droplets, FlaskConical, HardHat, LayoutDashboard, Map, PanelLeftClose, PanelLeftOpen, Settings, TriangleAlert, Wrench,
} from 'lucide-react';
import { useMe } from '@/features/auth/useMe';
import { useAwaitingApprovalCount } from '@/shared/data/counts';
import { strings } from '@/shared/lib/strings';
import { cn } from '@/shared/lib/cn';

function Item({ to, icon: Icon, label, collapsed, badge, end }) {
  return (
    <NavLink
      to={to}
      end={end}
      title={collapsed ? label : undefined}
      className={({ isActive }) =>
        cn(
          'relative flex h-9 items-center gap-3 rounded-md px-3 text-sm font-medium transition-colors',
          isActive ? 'bg-primary-soft text-primary' : 'text-ink-2 hover:bg-muted',
          collapsed && 'justify-center px-0',
        )
      }
    >
      <Icon className="size-4 shrink-0" aria-hidden="true" />
      {!collapsed && <span className="truncate">{label}</span>}
      {badge > 0 && (
        <span className={cn('rounded-full bg-teal px-1.5 text-xs text-white', collapsed ? 'absolute right-1 top-0.5' : 'ml-auto')}>{badge}</span>
      )}
    </NavLink>
  );
}

function Group({ title, collapsed, children }) {
  return (
    <div className="space-y-1">
      {!collapsed && <p className="px-3 pb-1 text-xs font-medium text-ink-3">{title}</p>}
      {children}
    </div>
  );
}

export function Sidebar({ collapsed, onToggle }) {
  const me = useMe();
  const approvals = useAwaitingApprovalCount();
  return (
    <aside className={cn('sticky top-0 flex h-screen shrink-0 flex-col border-r border-line bg-surface transition-[width] duration-200', collapsed ? 'w-16' : 'w-[232px]')}>
      <div className={cn('flex h-14 items-center gap-2 border-b border-line px-4 text-primary', collapsed && 'justify-center px-0')}>
        <Droplets className="size-6" aria-hidden="true" />
        {!collapsed && <span className="text-lg font-semibold">{strings.appName}</span>}
      </div>
      <nav className="flex-1 space-y-5 overflow-y-auto p-3" aria-label="Main">
        <Group title="Operations" collapsed={collapsed}>
          <Item to="/" end icon={LayoutDashboard} label="Dashboard" collapsed={collapsed} />
          <Item to="/map" icon={Map} label="Map" collapsed={collapsed} />
          <Item to="/events" icon={TriangleAlert} label="Events" collapsed={collapsed} />
        </Group>
        <Group title="Field" collapsed={collapsed}>
          <Item to="/work-orders" icon={Wrench} label="Work orders" collapsed={collapsed} />
          <Item to="/approvals" icon={ClipboardCheck} label="Approvals" collapsed={collapsed} badge={approvals.data ?? 0} />
          <Item to="/engineers" icon={HardHat} label="Engineers" collapsed={collapsed} />
        </Group>
        {me.data?.role === 'ADMIN' && (
          <Group title="Admin" collapsed={collapsed}>
            <Item to="/simulation" icon={FlaskConical} label="Simulation" collapsed={collapsed} />
          </Group>
        )}
      </nav>
      <div className="space-y-1 border-t border-line p-3">
        <Item to="/settings" icon={Settings} label="Settings" collapsed={collapsed} />
        <button
          type="button"
          onClick={onToggle}
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          className={cn('flex h-9 w-full items-center gap-3 rounded-md px-3 text-sm text-ink-2 hover:bg-muted', collapsed && 'justify-center px-0')}
        >
          {collapsed ? <PanelLeftOpen className="size-4" /> : <PanelLeftClose className="size-4" />}
          {!collapsed && 'Collapse'}
        </button>
      </div>
    </aside>
  );
}
