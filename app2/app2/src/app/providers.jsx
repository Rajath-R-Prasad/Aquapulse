import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider } from 'react-router-dom';
import { Toaster } from 'sonner';
import { SessionProvider } from '@/features/auth/useSession';
import { router } from './router';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 15_000,
      retry: (count, e) => !(e?.status >= 400 && e?.status < 500) && count < 2,
    },
  },
});

export function Providers() {
  return (
    <QueryClientProvider client={queryClient}>
      <SessionProvider>
        <RouterProvider router={router} />
        <Toaster position="top-right" richColors closeButton />
      </SessionProvider>
    </QueryClientProvider>
  );
}
