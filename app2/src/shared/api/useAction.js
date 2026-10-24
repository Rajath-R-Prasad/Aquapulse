import { useMutation, useQueryClient } from '@tanstack/react-query';
import { handleApiError } from './errors';

export function useAction(fn, invalidate = []) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onError: (e) => handleApiError(e, qc),
    onSettled: (_d, _e, vars) => {
      const keys = typeof invalidate === 'function' ? invalidate(vars) : invalidate;
      keys.forEach((queryKey) => qc.invalidateQueries({ queryKey }));
    },
  });
}
