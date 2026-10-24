import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { playCriticalAlertSound } from './criticalAlertAudio';

const CriticalAlertContext = createContext(null);

export const useCriticalAlert = () => {
  const ctx = useContext(CriticalAlertContext);
  if (!ctx) {
    throw new Error('useCriticalAlert must be used within a CriticalAlertProvider');
  }
  return ctx;
};

const STORAGE_KEY = 'aquapulse_dismissed_critical_alerts';

function getStoredDismissed() {
  if (typeof window === 'undefined') return new Set();
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    return raw ? new Set(JSON.parse(raw)) : new Set();
  } catch {
    return new Set();
  }
}

function persistDismissed(set) {
  if (typeof window === 'undefined') return;
  try {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify([...set]));
  } catch {
    // Ignore storage quota or disabled storage errors
  }
}

/**
 * Checks whether an object represents an open critical leak event or critical severity score.
 */
export function isCriticalEvent(item) {
  if (!item || typeof item !== 'object') return false;

  // Closed or false alarm events do not trigger alerts
  const status = item.status?.toUpperCase?.() ?? item.status;
  if (status === 'CLOSED' || status === 'FALSE_ALARM') return false;

  // 1. Severity string is CRITICAL
  const sev = item.severity?.toUpperCase?.() ?? item.severity;
  if (sev === 'CRITICAL') return true;

  // 2. Numerical severity_score is at or above critical threshold (>= 0.8)
  if (typeof item.severity_score === 'number' && item.severity_score >= 0.8) {
    return true;
  }

  // 3. Notification of escalated severity to CRITICAL
  if (item.type === 'SEVERITY_ESCALATED' && item.to_status?.toUpperCase?.() === 'CRITICAL') {
    return true;
  }

  return false;
}

export function CriticalAlertProvider({ children }) {
  const qc = useQueryClient();
  const [activeAlert, setActiveAlert] = useState(null);
  const dismissedIdsRef = useRef(getStoredDismissed());
  const stopAudioRef = useRef(null);

  // Synchronize audio playback with presence of activeAlert
  useEffect(() => {
    if (activeAlert) {
      if (!stopAudioRef.current) {
        stopAudioRef.current = playCriticalAlertSound();
      }
    } else {
      if (stopAudioRef.current) {
        stopAudioRef.current();
        stopAudioRef.current = null;
      }
    }

    return () => {
      if (stopAudioRef.current) {
        stopAudioRef.current();
        stopAudioRef.current = null;
      }
    };
  }, [activeAlert]);

  const triggerAlert = useCallback((eventData) => {
    if (!eventData) return;

    const alertId = eventData.id || eventData.event_no || `critical-${Date.now()}`;
    if (dismissedIdsRef.current.has(alertId)) {
      return;
    }

    setActiveAlert((current) => {
      // Don't replace if current alert is the same event
      if (current && (current.id === eventData.id || current.event_no === eventData.event_no)) {
        return current;
      }

      return {
        id: eventData.id || alertId,
        event_no: eventData.event_no || `EV-${String(alertId).slice(0, 8).toUpperCase()}`,
        pipe_code: eventData.pipe_code || eventData.pipe?.code || 'P17',
        severity: 'CRITICAL',
        severity_score: typeof eventData.severity_score === 'number' ? eventData.severity_score : 1.0,
        est_leak_rate_lpm: eventData.est_leak_rate_lpm,
        est_loss_pct: eventData.est_loss_pct,
        detected_at: eventData.detected_at || new Date().toISOString(),
        advisory_id: eventData.advisory_id,
        is_test: Boolean(eventData.is_test),
        raw: eventData,
      };
    });
  }, []);

  const dismissAlert = useCallback(() => {
    // 1. Instantly silence audio
    if (stopAudioRef.current) {
      stopAudioRef.current();
      stopAudioRef.current = null;
    }

    // 2. Mark this alert as dismissed so it doesn't re-trigger on subsequent polls/fetches
    if (activeAlert) {
      const idToDismiss = activeAlert.id || activeAlert.event_no;
      if (idToDismiss) {
        dismissedIdsRef.current.add(idToDismiss);
        persistDismissed(dismissedIdsRef.current);
      }
    }

    // 3. Close the popup
    setActiveAlert(null);
  }, [activeAlert]);

  const testAlert = useCallback(() => {
    const testId = `test-alert-${Date.now()}`;
    setActiveAlert({
      id: testId,
      event_no: 'EV-CRITICAL-DEMO',
      pipe_code: 'P17',
      severity: 'CRITICAL',
      severity_score: 0.95,
      est_leak_rate_lpm: 38.4,
      est_loss_pct: 45.0,
      detected_at: new Date().toISOString(),
      is_test: true,
    });
  }, []);

  // Listen to TanStack QueryCache for any data reflection of critical severity score / event
  useEffect(() => {
    const inspectValue = (val) => {
      if (!val) return false;
      if (Array.isArray(val)) {
        for (const item of val) {
          if (isCriticalEvent(item)) {
            triggerAlert(item);
            return true;
          }
        }
      } else if (typeof val === 'object') {
        if (isCriticalEvent(val)) {
          triggerAlert(val);
          return true;
        }
        if (Array.isArray(val.events)) {
          for (const ev of val.events) {
            if (isCriticalEvent(ev)) {
              triggerAlert(ev);
              return true;
            }
          }
        }
        if (Array.isArray(val.items)) {
          for (const it of val.items) {
            if (isCriticalEvent(it)) {
              triggerAlert(it);
              return true;
            }
          }
        }
        // Digital twin public dashboard summary check
        if (val.open_events_by_severity?.CRITICAL > 0) {
          triggerAlert({
            id: 'open-twin-critical',
            event_no: 'CRITICAL TWIN EVENT',
            pipe_code: 'Digital Twin Network',
            severity: 'CRITICAL',
            severity_score: 1.0,
          });
          return true;
        }
      }
      return false;
    };

    // Inspect already existing cached queries
    qc.getQueryCache().getAll().forEach((query) => {
      if (query.state.data) {
        inspectValue(query.state.data);
      }
    });

    // Subscribe to incoming query updates
    const unsubscribe = qc.getQueryCache().subscribe((event) => {
      if (event?.type === 'updated' && event?.action?.type === 'success') {
        inspectValue(event.query.state.data);
      }
    });

    return () => unsubscribe();
  }, [qc, triggerAlert]);

  return (
    <CriticalAlertContext.Provider
      value={{
        activeAlert,
        triggerAlert,
        dismissAlert,
        testAlert,
        isAlerting: Boolean(activeAlert),
      }}
    >
      {children}
    </CriticalAlertContext.Provider>
  );
}

