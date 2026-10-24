import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { isCriticalEvent } from '../CriticalAlertContext';
import { playCriticalAlertSound } from '../criticalAlertAudio';

describe('isCriticalEvent logic', () => {
  it('detects critical severity string', () => {
    expect(isCriticalEvent({ severity: 'CRITICAL' })).toBe(true);
    expect(isCriticalEvent({ severity: 'critical' })).toBe(true);
    expect(isCriticalEvent({ severity: 'CRITICAL', severity_score: 0.5 })).toBe(true);
  });

  it('detects critical severity score (>= 0.8)', () => {
    expect(isCriticalEvent({ severity_score: 0.85 })).toBe(true);
    expect(isCriticalEvent({ severity_score: 1.0 })).toBe(true);
    expect(isCriticalEvent({ severity_score: 0.79 })).toBe(false);
  });

  it('detects severity escalated notification', () => {
    expect(isCriticalEvent({ type: 'SEVERITY_ESCALATED', to_status: 'CRITICAL' })).toBe(true);
  });

  it('ignores non-critical and closed events', () => {
    expect(isCriticalEvent(null)).toBe(false);
    expect(isCriticalEvent(undefined)).toBe(false);
    expect(isCriticalEvent({ severity: 'MAJOR', severity_score: 0.6 })).toBe(false);
    expect(isCriticalEvent({ severity: 'MODERATE' })).toBe(false);
    expect(isCriticalEvent({ severity: 'MINOR' })).toBe(false);
    expect(isCriticalEvent({ severity: 'CRITICAL', status: 'CLOSED' })).toBe(false);
    expect(isCriticalEvent({ severity: 'CRITICAL', status: 'FALSE_ALARM' })).toBe(false);
  });
});

describe('playCriticalAlertSound audio engine', () => {
  let originalWindow;

  beforeEach(() => {
    originalWindow = globalThis.window;
  });

  afterEach(() => {
    globalThis.window = originalWindow;
    vi.restoreAllMocks();
  });

  it('gracefully returns no-op if window or AudioContext is absent', () => {
    globalThis.window = undefined;
    const stop = playCriticalAlertSound();
    expect(typeof stop).toBe('function');
    expect(() => stop()).not.toThrow();
  });

  it('instantiates Web Audio graph and stops cleanly when dismissed', () => {
    const mockOscillator = {
      type: '',
      frequency: {
        setValueAtTime: vi.fn(),
        exponentialRampToValueAtTime: vi.fn(),
      },
      connect: vi.fn(),
      start: vi.fn(),
      stop: vi.fn(),
    };

    const mockGain = {
      gain: {
        value: 1,
        setValueAtTime: vi.fn(),
        linearRampToValueAtTime: vi.fn(),
        exponentialRampToValueAtTime: vi.fn(),
        cancelScheduledValues: vi.fn(),
      },
      connect: vi.fn(),
    };

    const mockFilter = {
      type: '',
      frequency: {
        setValueAtTime: vi.fn(),
      },
      connect: vi.fn(),
    };

    const mockContext = {
      state: 'running',
      currentTime: 0,
      destination: {},
      createGain: vi.fn(() => ({ ...mockGain })),
      createBiquadFilter: vi.fn(() => ({ ...mockFilter })),
      createOscillator: vi.fn(() => ({ ...mockOscillator })),
      resume: vi.fn().mockResolvedValue(undefined),
      close: vi.fn().mockResolvedValue(undefined),
    };

    const mockAudioContextClass = vi.fn(() => mockContext);

    globalThis.window = {
      AudioContext: mockAudioContextClass,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    };

    const stopAudio = playCriticalAlertSound();
    expect(mockAudioContextClass).toHaveBeenCalled();
    expect(typeof stopAudio).toBe('function');

    // Dismissal / stopping
    expect(() => stopAudio()).not.toThrow();
  });
});

