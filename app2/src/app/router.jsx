import { createBrowserRouter, Navigate, Outlet } from 'react-router-dom';
import { RequireAdmin, RequireAuth, RequireStaff } from './guards';
import AppShell from './AppShell';
import { CriticalAlertModal } from '@/features/alerts/CriticalAlertModal';
import { EmptyState } from '@/shared/ui/States';

const page = (loader) => () => loader().then((m) => ({ Component: m.default }));

const NotFound = () => (
  <EmptyState title="Not found">
    <a href="/" className="text-primary underline">Back to dashboard</a>
  </EmptyState>
);

function RootLayout() {
  return (
    <>
      <Outlet />
      <CriticalAlertModal />
    </>
  );
}

export const router = createBrowserRouter([
  {
    element: <RootLayout />,
    children: [
      { path: '/login', lazy: page(() => import('@/features/auth/LoginPage')) },
      { path: '/', lazy: page(() => import('@/features/dashboard/PublicDashboardPage')) },
      {
        element: <RequireAuth />,
        children: [
          {
            element: <RequireStaff />,
            children: [
              {
                element: <AppShell />,
                children: [
                  { path: '/map', handle: { title: 'Network map', fullBleed: true }, lazy: page(() => import('@/features/map/MapPage')) },
                  { path: '/events', handle: { title: 'Events' }, lazy: page(() => import('@/features/events/EventsPage')) },
                  { path: '/events/:id', handle: { title: 'Event' }, lazy: page(() => import('@/features/events/EventDetailPage')) },
                  { path: '/approvals', handle: { title: 'Approvals' }, lazy: page(() => import('@/features/workorders/WorkOrdersPage')) },
                  { path: '/work-orders', handle: { title: 'Work orders' }, lazy: page(() => import('@/features/workorders/WorkOrdersPage')) },
                  { path: '/work-orders/:id', handle: { title: 'Work order review' }, lazy: page(() => import('@/features/workorders/WorkOrderReviewPage')) },
                  { path: '/engineers', handle: { title: 'Engineers' }, lazy: page(() => import('@/features/engineers/EngineersPage')) },
                  {
                    element: <RequireAdmin />,
                    children: [{ path: '/simulation', handle: { title: 'Simulation' }, lazy: page(() => import('@/features/simulation/SimulationPage')) }],
                  },
                  { path: '/settings', handle: { title: 'Settings' }, lazy: page(() => import('@/features/settings/SettingsPage')) },
                  { path: '/home', element: <Navigate to="/map" replace /> },
                ],
              },
            ],
          },
        ],
      },
      { path: '*', element: <NotFound /> },
    ],
  },
]);
