import { createContext, useContext, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { supabase } from './client';
import { debounce, throttle } from '../lib/hooks';
import { useCriticalAlert } from '@/features/alerts/CriticalAlertContext';

const LiveContext = createContext('reconnecting');
export const useLiveStatus = () => useContext(LiveContext);

const BAD = ['CHANNEL_ERROR', 'TIMED_OUT', 'CLOSED'];

export function RealtimeProvider({ children }) {
  const qc = useQueryClient();
  const navigate = useNavigate();
  const navRef = useRef(navigate);
  navRef.current = navigate;
  const { triggerAlert } = useCriticalAlert();
  const triggerAlertRef = useRef(triggerAlert);
  triggerAlertRef.current = triggerAlert;

  const [statuses, setStatuses] = useState({});
  const [live, setLive] = useState('reconnecting');
  const wasDown = useRef(false);
  const total = useRef(0);

  useEffect(() => {
    const inv = (...queryKey) => qc.invalidateQueries({ queryKey });
    const invPipemap = debounce(() => inv('pipemap'), 500);
    const invEngineers = throttle(() => inv('engineers'), 5000);

    const defs = [
      ['leak_events', '*', (p) => {
        const row = p.new?.id ? p.new : p.old;
        inv('events');
        if (row?.id) inv('event', row.id);
        inv('summary');

        // Check if event is or has escalated to critical
        const isCritical = p.new?.severity === 'CRITICAL' ||
          (typeof p.new?.severity_score === 'number' && p.new?.severity_score >= 0.8);
        const isOpen = p.new?.status !== 'CLOSED' && p.new?.status !== 'FALSE_ALARM';

        if (isCritical && isOpen) {
          triggerAlertRef.current?.(p.new);
        }

        if (p.eventType === 'INSERT' && ['MAJOR', 'CRITICAL'].includes(p.new?.severity)) {
          toast.error(`${p.new.severity === 'CRITICAL' ? 'Critical' : 'Major'} leak detected`, {
            description: p.new.event_no,
            duration: Infinity,
            action: { label: 'View', onClick: () => navRef.current(`/events/${p.new.id}`) },
          });
        }
      }],
      ['work_orders', '*', (p) => {
        const row = p.new?.id ? p.new : p.old;
        inv('workorders');
        inv('assignments');
        inv('events');
        inv('event-log');
        inv('summary');
        if (row?.id) inv('workorder', row.id);
        if (row?.leak_event_id) inv('event', row.leak_event_id);
      }],
      ['isolation_advisories', '*', (p) => {
        const row = p.new?.id ? p.new : p.old;
        inv('advisories');
        inv('events');
        if (row?.leak_event_id) inv('event', row.leak_event_id);
      }],
      ['pipe_segments', 'UPDATE', () => invPipemap()],
      ['valves', 'UPDATE', () => {
        inv('pipemap');
        inv('advisories');
      }],
      ['notifications', 'INSERT', (p) => {
        inv('notifications');
        if (p.new?.title) toast(p.new.title, { description: p.new.body ?? undefined });
        if (
          p.new?.payload?.severity === 'CRITICAL' ||
          p.new?.type === 'SEVERITY_ESCALATED' ||
          p.new?.title?.toLowerCase?.().includes('critical')
        ) {
          triggerAlertRef.current?.(p.new?.payload || p.new);
        }
      }],
      ['engineers', 'UPDATE', () => invEngineers()],
    ];
    total.current = defs.length;

    const channels = defs.map(([table, event, handler]) =>
      supabase
        .channel(`rt-${table}`)
        .on('postgres_changes', { event, schema: 'public', table }, handler)
        .subscribe((status) => setStatuses((s) => ({ ...s, [table]: status }))),
    );
    return () => channels.forEach((ch) => supabase.removeChannel(ch));
  }, [qc]);

  useEffect(() => {
    const values = Object.values(statuses);
    if (values.some((v) => BAD.includes(v))) wasDown.current = true;
    if (values.length === total.current && values.every((v) => v === 'SUBSCRIBED')) {
      setLive('live');
      if (wasDown.current) {
        wasDown.current = false;
        qc.invalidateQueries();
      }
      return undefined;
    }
    setLive((cur) => (cur === 'offline' ? cur : 'reconnecting'));
    const t = setTimeout(() => setLive('offline'), 30_000);
    return () => clearTimeout(t);
  }, [statuses, qc]);

  return <LiveContext.Provider value={live}>{children}</LiveContext.Provider>;
}

export function useLiveSignals() {
  const qc = useQueryClient();
  useEffect(() => {
    const ch = supabase
      .channel('rt-signal-latest')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'signal_latest' }, (p) => {
        const row = p.new;
        if (!row?.pipe_id) return;
        qc.setQueryData(['signal-latest'], (old = []) => {
          const i = old.findIndex((r) => r.pipe_id === row.pipe_id && r.source === row.source);
          if (i < 0) return [...old, row];
          const next = old.slice();
          next[i] = { ...old[i], ...row };
          return next;
        });
      })
      .subscribe();
    return () => {
      supabase.removeChannel(ch);
    };
  }, [qc]);
}
