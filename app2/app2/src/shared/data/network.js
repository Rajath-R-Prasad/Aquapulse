import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { sb } from '../api/errors';
import { supabase } from '../supabase/client';
import { lineToLatLngs, pointToLatLng } from '../lib/geo';

export const SIGNAL_RANGES = {
  '15m': { label: '15 min', ms: 15 * 60_000, bucket: '10s' },
  '1h': { label: '1 h', ms: 60 * 60_000, bucket: '1m' },
  '6h': { label: '6 h', ms: 6 * 60 * 60_000, bucket: '5m' },
  '24h': { label: '24 h', ms: 24 * 60 * 60_000, bucket: '5m' },
};

export const sourceOf = (pipe) => (pipe?.monitoring === 'HARDWARE' ? 'HARDWARE' : 'TWIN');
export const signalFor = (rows, pipe) => (rows ?? []).find((r) => r.pipe_id === pipe?.id && r.source === sourceOf(pipe));

export const useNetwork = () =>
  useQuery({ queryKey: ['network'], queryFn: () => api.get('/v1/network'), staleTime: 10 * 60_000 });

export function usePipeMap() {
  const network = useNetwork();
  const live = useQuery({
    queryKey: ['pipemap'],
    queryFn: async () => {
      const [pipes, valves] = await Promise.all([
        sb(supabase.from('v_pipe_map').select('id,code,state,monitoring,diameter_mm,material,signal_ts,flow_in_lpm,flow_out_lpm,pressure_in_kpa,pressure_out_kpa')),
        sb(supabase.from('valves').select('id,code,pipe_id,kind,state')),
      ]);
      return { pipes, valves };
    },
    staleTime: 30_000,
  });

  const merged = useMemo(() => {
    const features = network.data?.features ?? [];
    const rowsById = new Map((live.data?.pipes ?? []).map((r) => [r.id, r]));
    const rowsByCode = new Map((live.data?.pipes ?? []).map((r) => [r.code, r]));
    const valveRows = new Map((live.data?.valves ?? []).map((r) => [r.id, r]));
    const pipes = [];
    const nodes = [];
    const valves = [];
    features.forEach((f) => {
      const p = f.properties ?? {};
      if (p.kind === 'PIPE') {
        const row = rowsById.get(p.id) ?? rowsByCode.get(p.code) ?? {};
        pipes.push({ ...p, ...row, id: p.id ?? row.id, latlngs: lineToLatLngs(f.geometry) });
      } else if (p.kind === 'NODE') {
        nodes.push({ ...p, latlng: pointToLatLng(f.geometry) });
      } else if (p.kind === 'VALVE') {
        valves.push({ ...p, ...(valveRows.get(p.id) ?? {}), latlng: pointToLatLng(f.geometry) });
      }
    });
    return {
      pipes,
      nodes,
      valves,
      byId: new Map(pipes.map((p) => [p.id, p])),
      byCode: new Map(pipes.map((p) => [p.code, p])),
    };
  }, [network.data, live.data]);

  return {
    ...merged,
    isPending: network.isPending || live.isPending,
    isFetching: network.isFetching || live.isFetching,
    error: network.error ?? live.error,
    refetch: () => Promise.all([network.refetch(), live.refetch()]),
  };
}

export const useSignalLatest = () =>
  useQuery({ queryKey: ['signal-latest'], queryFn: () => sb(supabase.from('signal_latest').select('*')), staleTime: 30_000 });

export function usePipeSignals(pipeId, source, range) {
  return useQuery({
    queryKey: ['signals', pipeId, source, range],
    queryFn: () => {
      const to = new Date();
      const from = new Date(to.getTime() - SIGNAL_RANGES[range].ms);
      return api.get(`/v1/pipes/${pipeId}/signals`, {
        query: { source, from: from.toISOString(), to: to.toISOString(), bucket: SIGNAL_RANGES[range].bucket },
      });
    },
    enabled: !!pipeId,
    staleTime: 10_000,
    refetchInterval: 10_000,
  });
}

export function usePipeMl(pipeId) {
  return useQuery({
    queryKey: ['ml', pipeId],
    queryFn: () =>
      sb(
        supabase
          .from('ml_inferences')
          .select('window_end,anomaly_score,is_anomaly')
          .eq('pipe_id', pipeId)
          .gte('window_end', new Date(Date.now() - 3_600_000).toISOString())
          .order('window_end', { ascending: true }),
      ),
    enabled: !!pipeId,
    staleTime: 10_000,
    refetchInterval: 10_000,
  });
}

export function usePipeHistory(pipeId) {
  return useQuery({
    queryKey: ['pipe-history', pipeId],
    queryFn: () =>
      sb(supabase.from('pipe_state_history').select('*').eq('pipe_id', pipeId).order('changed_at', { ascending: false }).limit(30)),
    enabled: !!pipeId,
    staleTime: 30_000,
  });
}
