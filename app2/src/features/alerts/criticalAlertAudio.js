/**
 * Audio synthesis for the high-priority critical condition alert.
 * Uses Web Audio API to generate an alarming two-tone emergency siren in real-time.
 * Returns a cleanup function that immediately silences and destroys the audio graph.
 */
export function playCriticalAlertSound() {
  if (typeof window === 'undefined') {
    return () => {};
  }

  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
  if (!AudioContextClass) {
    console.warn('[CriticalAlertAudio] Web Audio API is not supported in this environment.');
    return () => {};
  }

  let ctx = null;
  let isStopped = false;
  let intervalId = null;
  let currentOsc = null;

  try {
    ctx = new AudioContextClass();
  } catch (err) {
    console.warn('[CriticalAlertAudio] Failed to instantiate AudioContext:', err);
    return () => {};
  }

  // Master gain for clean volume control and click-free fadeout on dismiss
  let masterGain;
  try {
    masterGain = ctx.createGain();
    masterGain.gain.setValueAtTime(0.35, ctx.currentTime);

    // Warm lowpass filter to produce a piercing yet clean alarm tone
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(2400, ctx.currentTime);

    masterGain.connect(filter);
    filter.connect(ctx.destination);
  } catch (err) {
    console.warn('[CriticalAlertAudio] Error setting up audio nodes:', err);
    return () => {};
  }

  // Handle browser autoplay policy: attempt resume and attach listener on user interaction
  if (ctx.state === 'suspended') {
    ctx.resume().catch(() => {});
  }

  const handleInteraction = () => {
    if (!isStopped && ctx && ctx.state === 'suspended') {
      ctx.resume().catch(() => {});
    }
  };

  window.addEventListener('click', handleInteraction, { once: true, passive: true });
  window.addEventListener('keydown', handleInteraction, { once: true, passive: true });

  let highTone = true;

  const playPulse = () => {
    if (isStopped || !ctx || ctx.state === 'closed') return;

    try {
      const now = ctx.currentTime;
      const duration = 0.22; // 220ms pulse with 30ms gap

      const osc = ctx.createOscillator();
      const toneGain = ctx.createGain();

      // Dual-tone emergency siren sweep: High (920Hz -> 840Hz) vs Low (680Hz -> 600Hz)
      const startFreq = highTone ? 920 : 680;
      const endFreq = highTone ? 840 : 600;

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(startFreq, now);
      osc.frequency.exponentialRampToValueAtTime(endFreq, now + duration);

      // Fast attack (15ms) and quick release (20ms)
      toneGain.gain.setValueAtTime(0.001, now);
      toneGain.gain.linearRampToValueAtTime(0.3, now + 0.015);
      toneGain.gain.setValueAtTime(0.3, now + duration - 0.025);
      toneGain.gain.exponentialRampToValueAtTime(0.001, now + duration);

      osc.connect(toneGain);
      toneGain.connect(masterGain);

      osc.start(now);
      osc.stop(now + duration);

      currentOsc = osc;
      highTone = !highTone;
    } catch (_) {
      // Ignore timing or transient audio node exceptions
    }
  };

  // Play immediately and cycle every 250ms
  playPulse();
  intervalId = setInterval(playPulse, 250);

  // Return dismiss / stop callback: immediately ends sound and closes context
  return () => {
    if (isStopped) return;
    isStopped = true;

    window.removeEventListener('click', handleInteraction);
    window.removeEventListener('keydown', handleInteraction);

    if (intervalId) {
      clearInterval(intervalId);
      intervalId = null;
    }

    try {
      if (currentOsc) {
        try { currentOsc.stop(); } catch (_) {}
        currentOsc = null;
      }

      if (ctx && ctx.state !== 'closed') {
        // Immediate linear ramp down to 0 volume in 15ms
        masterGain.gain.cancelScheduledValues(ctx.currentTime);
        masterGain.gain.setValueAtTime(masterGain.gain.value, ctx.currentTime);
        masterGain.gain.linearRampToValueAtTime(0.0001, ctx.currentTime + 0.015);

        setTimeout(() => {
          try {
            ctx.close();
          } catch (_) {}
        }, 30);
      }
    } catch (_) {}
  };
}

