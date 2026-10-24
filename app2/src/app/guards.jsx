import { Navigate, Outlet } from 'react-router-dom';
import { Droplets } from 'lucide-react';
import { useSession } from '@/features/auth/useSession';
import { useMe } from '@/features/auth/useMe';
import AccessDenied from '@/features/auth/AccessDenied';
import { ErrorState } from '@/shared/ui/States';

export function Splash() {
  return (
    <div className="flex h-full items-center justify-center bg-app">
      <div className="flex items-center gap-2 text-2xl font-semibold text-primary">
        <Droplets className="size-7" aria-hidden="true" />
        AquaPulse
      </div>
    </div>
  );
}

export function RequireAuth() {
  const { session, loading } = useSession();
  if (loading) return <Splash />;
  if (!session) return <Navigate to="/login" replace />;
  return <Outlet />;
}

export function RequireStaff() {
  const me = useMe();
  if (me.isPending) return <Splash />;
  if (me.error) return <ErrorState error={me.error} onRetry={() => me.refetch()} title="Could not load your profile" />;
  if (me.data.role === 'ENGINEER') return <AccessDenied />;
  return <Outlet />;
}

export function RequireAdmin() {
  const me = useMe();
  if (me.data?.role !== 'ADMIN') return <Navigate to="/" replace />;
  return <Outlet />;
}
