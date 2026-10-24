import { useQueryClient } from '@tanstack/react-query';
import { Siren } from 'lucide-react';
import { supabase } from '@/shared/supabase/client';
import { useMe } from '@/features/auth/useMe';
import { useCriticalAlert } from '@/features/alerts/CriticalAlertContext';
import { Card, CardHeader } from '@/shared/ui/Card';
import { Button } from '@/shared/ui/Button';
import { Skeleton } from '@/shared/ui/Skeletons';
import { ErrorState } from '@/shared/ui/States';

export default function SettingsPage() {
  const me = useMe();
  const qc = useQueryClient();
  const { testAlert } = useCriticalAlert();

  const rows = [
    ['Name', me.data?.full_name],
    ['Role', me.data?.role],
    ['Phone', me.data?.phone || '—'],
    ['App version', __APP_VERSION__],
  ];

  return (
    <div className="max-w-xl space-y-4">
      <Card>
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

      <Card>
        <CardHeader title="Emergency Alert System" />
        <div className="space-y-3 px-4 pb-4">
          <p className="text-sm text-ink-2">
            Verify the alarming siren audio and global emergency pop-up triggered when critical leak severity conditions are reflected from the backend.
          </p>
          <Button
            variant="danger"
            onClick={testAlert}
            icon={Siren}
            className="font-semibold shadow-sm"
          >
            Test Critical Alert & Alarm Sound
          </Button>
        </div>
      </Card>
    </div>
  );
}
