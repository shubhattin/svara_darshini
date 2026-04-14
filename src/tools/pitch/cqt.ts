import type { AudioInfo, PitchDetector } from './types';
import {
  CqtEngine,
  findDominantCqtPitch
} from '../../components/pages/main/time_graph/cqt/cqt-engine';
import {
  NOTES,
  getNoteNumberFromPitch,
  getScaleFromNoteNumber,
  getDetuneFromPitch
} from '../../components/pages/main/constants';

/** Number of Constant-Q bins; higher values improve frequency detail but cost more work per frame.*/
const CQT_BIN_COUNT = 1200;
/** Ignore detected peaks below this Hz floor to avoid low-end rumble and handling noise.*/
const CQT_MIN_FREQUENCY = 60;
/** Ignore detected peaks above this Hz ceiling so the tuner stays focused on the vocal/instrument range we care about.*/
const CQT_MAX_FREQUENCY = 2200;
/** Minimum peak strength required before a CQT bin is treated as a valid pitch candidate.*/
const CQT_MIN_INTENSITY = 0.05;
/** Exponential smoothing factor: higher is faster/more reactive, lower is steadier/smoother.*/
const CQT_PITCH_SMOOTHING_ALPHA = 0.23;

export class CqtPitchDetector implements PitchDetector {
  private _ready = false;
  private _loading = false;
  private engine: CqtEngine | null = null;
  private smoothedPitch = 0;
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

    const dominantPitch = findDominantCqtPitch(frame, {
      minFrequency: CQT_MIN_FREQUENCY,
      maxFrequency: CQT_MAX_FREQUENCY,
      minIntensity: CQT_MIN_INTENSITY
    });

    if (
      !dominantPitch ||
      !Number.isFinite(dominantPitch.frequency) ||
      dominantPitch.frequency <= 0
    ) {
      return null;
    }

    this.smoothedPitch =
      this.smoothedPitch === 0
        ? dominantPitch.frequency
        : dominantPitch.frequency * CQT_PITCH_SMOOTHING_ALPHA +
          this.smoothedPitch * (1 - CQT_PITCH_SMOOTHING_ALPHA);

    const rawNoteNumber = getNoteNumberFromPitch(this.smoothedPitch);
    const noteName = NOTES[rawNoteNumber % 12];

    return {
      pitch: Math.round(this.smoothedPitch * 10) / 10,
      clarity: Math.round(Math.min(Math.max(dominantPitch.intensity, 0), 1) * 100),
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
  }
}
