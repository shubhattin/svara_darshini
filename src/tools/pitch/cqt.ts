import type { AudioInfo, PitchDetector } from './types';
import { CqtEngine, cqtBinToFrequency, type CqtFrameData } from './cqt_bind/cqt-engine';
import {
  NOTES,
  getNoteNumberFromPitch,
  getScaleFromNoteNumber,
  getDetuneFromPitch
} from '~/components/pages/main/constants';

// ─── CQT Configuration (tuned for tanpura drone + Indian classical voice) ──────

/** Number of Constant-Q bins across the full 10-octave span.
 *  1920 bins ÷ 10 octaves = 192 bins/octave ≈ 16 bins/semitone.
 *  Fine resolution is important for accurate shruti/gamaka tracking. */
const CQT_BIN_COUNT = 1920;

/** Hz floor — male tanpura Sa is typically ~100–130 Hz, lowest notes ~80 Hz.
 *  65 Hz gives headroom while cutting mains hum (50/60 Hz) and cable rumble. */
const CQT_MIN_FREQUENCY = 65;

/** Hz ceiling — voice fundamentals rarely exceed ~800 Hz (female high Sa).
 *  1500 Hz captures everything with margin while ignoring strong upper
 *  harmonics that confuse pitch detection (tanpura is very harmonic-rich). */
const CQT_MAX_FREQUENCY = 1500;

/** Minimum intensity for a bin to be considered a valid peak.
 *  Raised to reject ambient room noise and microphone self-noise.
 *  If you're in a quiet studio, you can lower this to ~0.04. */
const CQT_MIN_INTENSITY = 0.05;

/** When a sub-harmonic candidate's intensity is at least this fraction of the
 *  dominant peak, prefer it as the fundamental.  Tanpura fundamentals are
 *  often much quieter than their 2nd/3rd partials, so we use 0.10 to
 *  aggressively hunt for the true root. */
const CQT_HARMONIC_THRESHOLD = 0.1;

/** How many harmonic ratios (2×, 3×, 4×, 5×) we check.
 *  Tanpura partials are strong up to the 5th, so depth=5 helps. */
const CQT_HARMONIC_SEARCH_DEPTH = 5;

/** The frequency-domain tolerance (in semitones) when matching a candidate
 *  fundamental to an expected sub-harmonic position. Slightly wider to
 *  accommodate the natural inharmonicity of tanpura strings. */
const CQT_HARMONIC_TOLERANCE_SEMITONES = 0.7;

/** Exponential smoothing factor (0 < α ≤ 1).
 *  0.35 is responsive enough to track gamakas and quick ornaments
 *  while still filtering single-frame jitter. */
const CQT_PITCH_SMOOTHING_ALPHA = 0.35;

/** If the new pitch jumps by more than this many semitones from the smoothed
 *  value, reset the smoother immediately.  5 semitones (a perfect fourth)
 *  means only genuine large interval jumps cause a snap — meend, vibrato,
 *  and gamakas blend smoothly. */
const CQT_SMOOTHING_JUMP_SEMITONES = 5;

/** Number of consecutive "no detection" frames before we reset the
 *  smoothed pitch to 0.  6 frames ≈ 720 ms at 120 ms/frame — rides
 *  through brief pauses and breath gaps without resetting. */
const CQT_SILENCE_RESET_FRAMES = 6;

// ─── Helpers ────────────────────────────────────────────────────────────────────

/** Convert a frequency ratio to semitones. */
function ratioToSemitones(a: number, b: number): number {
  return 12 * Math.log2(a / b);
}

interface CandidatePeak {
  frequency: number;
  intensity: number;
  binIndex: number;
}

/**
 * Collect all local-maximum bins above `minIntensity` in the frequency range,
 * sorted by intensity descending.
 */
function findAllPeaks(
  frame: CqtFrameData,
  minFrequency: number,
  maxFrequency: number,
  minIntensity: number
): CandidatePeak[] {
  const peaks: CandidatePeak[] = [];
  const { intensities, binCount } = frame;

  for (let i = 1; i < binCount - 1; i++) {
    const freq = cqtBinToFrequency(i, binCount);
    if (freq < minFrequency || freq > maxFrequency) continue;

    const val = intensities[i];
    if (val < minIntensity) continue;

    // Local maximum: higher than both neighbours
    if (val > intensities[i - 1] && val > intensities[i + 1]) {
      peaks.push({ frequency: freq, intensity: val, binIndex: i });
    }
  }

  peaks.sort((a, b) => b.intensity - a.intensity);
  return peaks;
}

/**
 * Given the strongest peak, try to find a sub-harmonic that better represents
 * the true fundamental.  Walk through ratios 2:1, 3:1, 4:1 … and see if a
 * peak exists at freq/n.
 */
function findFundamental(
  peaks: CandidatePeak[],
  dominant: CandidatePeak,
  harmonicDepth: number,
  harmonicThreshold: number,
  toleranceSemitones: number
): CandidatePeak {
  let best = dominant;

  for (let n = 2; n <= harmonicDepth + 1; n++) {
    const expectedFundamental = dominant.frequency / n;

    // Find the strongest peak close to expectedFundamental
    for (const candidate of peaks) {
      const distance = Math.abs(ratioToSemitones(candidate.frequency, expectedFundamental));
      if (distance > toleranceSemitones) continue;

      // Accept as fundamental if it's loud enough relative to the dominant
      if (candidate.intensity >= dominant.intensity * harmonicThreshold) {
        // Prefer the lowest plausible fundamental
        if (candidate.frequency < best.frequency) {
          best = candidate;
        }
      }
      break; // only check the loudest match per harmonic ratio
    }
  }

  return best;
}

// ─── Detector ───────────────────────────────────────────────────────────────────

export class CqtPitchDetector implements PitchDetector {
  private _ready = false;
  private _loading = false;
  private engine: CqtEngine | null = null;
  private smoothedPitch = 0;
  private silentFrames = 0;
  private initToken = 0;

  get ready() {
    return this._ready;
  }

  get loading() {
    return this._loading;
  }

  async init(analyserNode: AnalyserNode, audioContext: AudioContext): Promise<void> {
    this.destroy(); // Clear any existing instance

    const token = ++this.initToken;
    this._loading = true;

    this.engine = new CqtEngine();

    try {
      await this.engine.init({
        sampleRate: audioContext.sampleRate,
        width: CQT_BIN_COUNT
      });

      // If a newer init was called while we were awaiting, abort
      if (token !== this.initToken) {
        this.engine.destroy();
        this.engine = null;
        return;
      }

      analyserNode.fftSize = this.engine.fftSize;
      this.smoothedPitch = 0;
      this.silentFrames = 0;
      this._ready = true;
    } catch (error) {
      if (this.engine) {
        this.engine.destroy();
        this.engine = null;
      }
      throw error;
    } finally {
      if (token === this.initToken) {
        this._loading = false;
      }
    }
  }

  detect(analyserNode: AnalyserNode, audioContext: AudioContext): AudioInfo | null {
    if (!this._ready || !this.engine || !this.engine.ready) {
      return null;
    }

    const frame = this.engine.computeFrame(analyserNode);
    if (!frame) return null;

    // ── 1. Collect all local-maximum peaks ──────────────────────────────────
    const peaks = findAllPeaks(frame, CQT_MIN_FREQUENCY, CQT_MAX_FREQUENCY, CQT_MIN_INTENSITY);

    if (peaks.length === 0) {
      this.silentFrames++;
      if (this.silentFrames >= CQT_SILENCE_RESET_FRAMES) {
        this.smoothedPitch = 0; // next real note starts fresh
      }
      return null;
    }

    // ── 2. Find the true fundamental via sub-harmonic search ────────────────
    const dominant = peaks[0];
    const fundamental = findFundamental(
      peaks,
      dominant,
      CQT_HARMONIC_SEARCH_DEPTH,
      CQT_HARMONIC_THRESHOLD,
      CQT_HARMONIC_TOLERANCE_SEMITONES
    );

    const detectedFreq = fundamental.frequency;
    if (!Number.isFinite(detectedFreq) || detectedFreq <= 0) {
      return null;
    }

    this.silentFrames = 0;

    // ── 3. Pitch-aware EMA smoothing ────────────────────────────────────────
    if (this.smoothedPitch === 0) {
      // First valid detection — no history to blend with
      this.smoothedPitch = detectedFreq;
    } else {
      const jumpSemitones = Math.abs(ratioToSemitones(detectedFreq, this.smoothedPitch));
      if (jumpSemitones > CQT_SMOOTHING_JUMP_SEMITONES) {
        // Large jump → snap immediately
        this.smoothedPitch = detectedFreq;
      } else {
        // Normal EMA blend
        this.smoothedPitch =
          detectedFreq * CQT_PITCH_SMOOTHING_ALPHA +
          this.smoothedPitch * (1 - CQT_PITCH_SMOOTHING_ALPHA);
      }
    }

    // ── 4. Map to AudioInfo ─────────────────────────────────────────────────
    const rawNoteNumber = getNoteNumberFromPitch(this.smoothedPitch);
    const noteName = NOTES[rawNoteNumber % 12];

    return {
      pitch: Math.round(this.smoothedPitch * 10) / 10,
      clarity: Math.round(Math.min(Math.max(fundamental.intensity, 0), 1) * 100),
      note: noteName,
      scale: getScaleFromNoteNumber(rawNoteNumber),
      detune: getDetuneFromPitch(this.smoothedPitch, rawNoteNumber)
    };
  }

  destroy(): void {
    this.initToken++; // Invalidate any pending init
    if (this.engine) {
      this.engine.destroy();
      this.engine = null;
    }
    this._ready = false;
    this._loading = false;
    this.smoothedPitch = 0;
    this.silentFrames = 0;
  }
}
