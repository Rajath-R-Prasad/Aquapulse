import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { BellOff, ExternalLink, Siren, TriangleAlert, Volume2 } from 'lucide-react';
import { useCriticalAlert } from './CriticalAlertContext';
import { Button } from '@/shared/ui/Button';
import { StatusBadge } from '@/shared/ui/Badges';
import { fmtIST } from '@/shared/lib/time';

export function CriticalAlertModal() {
  const { activeAlert, dismissAlert } = useCriticalAlert();
  const navigate = useNavigate();
  const modalRef = useRef(null);

  // Keyboard navigation & accessibility
  useEffect(() => {
    if (!activeAlert) return undefined;

    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        dismissAlert();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    // Prevent background scrolling while critical alert is active
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    // Focus the dismiss button or dialog
    modalRef.current?.focus();

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = originalOverflow;
    };
  }, [activeAlert, dismissAlert]);

  if (!activeAlert || typeof document === 'undefined') {
    return null;
  }

  const handleDismiss = () => {
    dismissAlert();
  };

  const handleViewEvent = () => {
    const id = activeAlert.id;
    dismissAlert();
    if (id && !activeAlert.is_test && !id.startsWith('open-twin')) {
      navigate(`/events/${id}`);
    }
  };

  const scorePct = typeof activeAlert.severity_score === 'number'
    ? Math.round(activeAlert.severity_score * 100)
    : 100;

  return createPortal(
    <div
      role="alertdialog"
      aria-modal="true"
      aria-labelledby="critical-alert-title"
      aria-describedby="critical-alert-description"
      className="fixed inset-0 z-[9999] flex items-center justify-center p-4"
    >
      {/* Dark backdrop with alarming red ambient pulse */}
      <div
        className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm transition-opacity"
        onClick={handleDismiss}
        aria-hidden="true"
      />

      {/* Main Alert Card */}
      <div
        ref={modalRef}
        tabIndex={-1}
        className="relative w-full max-w-lg overflow-hidden rounded-2xl border-2 border-danger bg-surface shadow-2xl shadow-danger/30 ring-4 ring-danger/25 transition-all outline-none"
      >
        {/* Urgent Emergency Header */}
        <div className="relative overflow-hidden bg-danger px-6 py-4.5 text-white">
          <div className="flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-white/20 ring-4 ring-white/30 animate-pulse">
                <Siren className="size-6 text-white" aria-hidden="true" />
              </div>
              <div>
                <span className="block text-[11px] font-extrabold uppercase tracking-widest text-red-200">
                  Critical Alarm Active
                </span>
                <h2 id="critical-alert-title" className="text-lg font-bold leading-tight text-white">
                  CRITICAL CONDITION DETECTED
                </h2>
              </div>
            </div>

            <div className="flex items-center gap-1.5 rounded-full bg-black/30 px-3 py-1 text-xs font-semibold text-white/95">
              <Volume2 className="size-3.5 animate-bounce text-red-200" aria-hidden="true" />
              <span>Alarm Sounding</span>
            </div>
          </div>
        </div>

        {/* Content Body */}
        <div className="space-y-4 p-6">
          <p id="critical-alert-description" className="text-sm font-medium text-ink">
            A critical severity leak has been detected in the network. Immediate isolation and response action is required.
          </p>

          {/* Event Details Box */}
          <div className="rounded-xl border border-danger/30 bg-danger-soft/40 p-4 space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2 border-b border-danger/20 pb-2.5">
              <div className="flex items-center gap-2">
                <StatusBadge domain="severity" value="CRITICAL" />
                <span className="font-bold text-ink">{activeAlert.event_no}</span>
              </div>
              <span className="text-xs font-semibold uppercase text-danger">
                Pipe {activeAlert.pipe_code}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <span className="text-ink-3 block">Severity score</span>
                <span className="text-base font-bold text-danger">
                  {scorePct}%{' '}
                  <span className="text-xs font-normal text-ink-2">
                    ({(activeAlert.severity_score ?? 1).toFixed(2)})
                  </span>
                </span>
              </div>

              <div>
                <span className="text-ink-3 block">Est. Leak Rate</span>
                <span className="text-base font-bold text-ink">
                  {activeAlert.est_leak_rate_lpm != null
                    ? `${Math.round(activeAlert.est_leak_rate_lpm)} L/min`
                    : 'High flow burst'}
                </span>
              </div>

              {activeAlert.est_loss_pct != null && (
                <div>
                  <span className="text-ink-3 block">Est. Supply Loss</span>
                  <span className="font-semibold text-ink">
                    {Math.round(activeAlert.est_loss_pct)}%
                  </span>
                </div>
              )}

              <div>
                <span className="text-ink-3 block">Detected</span>
                <span className="font-medium text-ink-2">
                  {fmtIST(activeAlert.detected_at)}
                </span>
              </div>
            </div>
          </div>

          <div className="flex items-start gap-2.5 rounded-lg bg-warning-soft/60 p-3 text-xs text-warning">
            <TriangleAlert className="size-4 shrink-0 mt-0.5" aria-hidden="true" />
            <p>
              Clicking <strong>Dismiss Alert</strong> will immediately silence the alarm sound and close this notification.
            </p>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="flex flex-wrap items-center justify-end gap-3 border-t border-line bg-muted/40 px-6 py-4">
          {activeAlert.id && !activeAlert.is_test && !activeAlert.id.startsWith('open-twin') && (
            <Button
              variant="outline"
              onClick={handleViewEvent}
              className="text-sm"
              icon={ExternalLink}
            >
              View Event
            </Button>
          )}

          <Button
            variant="danger"
            onClick={handleDismiss}
            className="h-10 px-5 text-sm font-bold shadow-md shadow-danger/20 hover:opacity-95 active:scale-95 transition-all"
            icon={BellOff}
            autoFocus
          >
            Dismiss Alert
          </Button>
        </div>
      </div>
    </div>,
    document.body,
  );
}

