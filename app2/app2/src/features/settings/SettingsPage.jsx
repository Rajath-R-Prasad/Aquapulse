import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/shared/supabase/client';
import { useMe } from '@/features/auth/useMe';
import { Card, CardHeader } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { Skeleton } from '@/shared/ui/Skeletons';
import { ErrorState } from '@/shared/ui/States';

export default function SettingsPage() {
  const me = useMe();
  const qc = useQueryClient();
  const rows = [
    ['Name', me.data?.full_name],
    ['Role', me.data?.role],
    ['Phone', me.data?.phone || '—'],
    ['App version', __APP_VERSION__],
  ];
  return (
    <Card className="max-w-xl">
      <CardHeader title="Profile" />
      <div className="px-4 pb-4">
        {me.error ? <ErrorState error={me.error} onRetry={() => me.refetch()} /> : (
          <dl className="divide-y divide-line">
            {rows.map(([k, v]) => (
              <div key={k} className="flex justify-between py-3 text-sm">
                <dt className="text-ink-2">{k}</dt>
                <dd className="font-medium">{me.isPending && k !== 'App version' ? <Skeleton className="h-4 w-32" /> : v}</dd>
              </div>
            ))}
          </dl>
        )}
        <Button variant="outline" className="mt-4" onClick={async () => { await supabase.auth.signOut(); qc.clear(); }}>Sign out</Button>
      </div>
    </Card>
  );
}
