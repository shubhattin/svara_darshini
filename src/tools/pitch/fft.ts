import { PitchDetector as PitchyDetector } from 'pitchy';
import type { AudioInfo, PitchDetector } from './types';
import {
  NOTES,
  getNoteNumberFromPitch,
  getScaleFromNoteNumber,
  getDetuneFromPitch
} from '~/components/pages/main/constants';

export class FftPitchDetector implements PitchDetector {
  private _ready = false;
  private _loading = false;
  private detector: PitchyDetector<Float32Array<ArrayBuffer>> | null = null;
  private inputBuffer: Float32Array<ArrayBuffer> | null = null;
  private readonly FFT_SIZE = 4096;

  get ready() {
    return this._ready;
  }

  get loading() {
    return this._loading;
  }

  async init(analyserNode: AnalyserNode, audioContext: AudioContext): Promise<void> {
    this._loading = true;

    try {
      analyserNode.fftSize = this.FFT_SIZE;
      this.detector = PitchyDetector.forFloat32Array(analyserNode.fftSize);
      this.inputBuffer = new Float32Array(this.detector.inputLength);

      this._ready = true;
    } finally {
      this._loading = false;
    }
  }

  detect(analyserNode: AnalyserNode, audioContext: AudioContext): AudioInfo | null {
    if (!this._ready || !this.detector || !this.inputBuffer) {
      return null;
    }

    analyserNode.getFloatTimeDomainData(this.inputBuffer);
    const [pitch, clarity] = this.detector.findPitch(this.inputBuffer, audioContext.sampleRate);

    // Some threshold for clarity maybe? E.g., if clarity is very low, return null.
    // The previous implementation always mapped it, so we'll keep that behavior but
    // it's good practice to filter out extremely low confidence occasionally.
    if (clarity < 0.8 || pitch <= 0) {
      // Just basic sanity check
      return null;
    }

    const rawNoteNumber = getNoteNumberFromPitch(pitch);
    const noteName = NOTES[rawNoteNumber % 12];

    return {
      pitch: Math.round(pitch * 10) / 10,
      clarity: Math.round(clarity * 100),
      note: noteName,
      scale: getScaleFromNoteNumber(rawNoteNumber),
      detune: getDetuneFromPitch(pitch, rawNoteNumber)
    };
  }

  destroy(): void {
    this.detector = null;
    this.inputBuffer = null;
    this._ready = false;
    this._loading = false;
  }
}
