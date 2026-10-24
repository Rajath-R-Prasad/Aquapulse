import { createContext, useContext, useEffect, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/shared/supabase/client';

const SessionContext = createContext({ session: null, loading: true });
export const useSession = () => useContext(SessionContext);

export function SessionProvider({ children }) {
  const qc = useQueryClient();
  const [state, setState] = useState({ session: null, loading: true });

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setState({ session: data.session, loading: false }));
    const { data } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT') qc.clear();
      setState({ session, loading: false });
    });
    return () => data.subscription.unsubscribe();
  }, [qc]);

  return <SessionContext.Provider value={state}>{children}</SessionContext.Provider>;
}
