import { ShieldAlert } from 'lucide-react';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/shared/supabase/client';
import { strings } from '@/shared/lib/strings';
import { Button } from '@/shared/ui/Button';

export default function AccessDenied() {
  const qc = useQueryClient();
  return (
    <div className="flex h-full items-center justify-center bg-app p-6">
      <div className="w-full max-w-md rounded-lg border border-line bg-surface p-8 text-center shadow-md">
        <ShieldAlert className="mx-auto size-10 text-warning" aria-hidden="true" />
        <h1 className="mt-3 text-xl font-semibold">Access restricted</h1>
        <p className="mt-2 text-sm text-ink-2">{strings.accessDenied}</p>
        <Button className="mt-6" onClick={async () => { await supabase.auth.signOut(); qc.clear(); }}>Sign out</Button>
      </div>
    </div>
  );
}
