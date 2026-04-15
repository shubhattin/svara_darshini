import { PitchDetector as PitchyDetector } from 'pitchy';
import type { AudioInfo, PitchDetector } from './types';
import {
  NOTES,
  getNoteNumberFromPitch,
  getScaleFromNoteNumber,
  getDetuneFromPitch
} from '~/components/pages/main/constants';

const FFT_SIZE = 2048;
const FFT_MIN_CLARITY = 0.55;
const FFT_PITCH_SMOOTHING_ALPHA = 0.45;
const FFT_SMOOTHING_JUMP_SEMITONES = 4;
const FFT_SILENCE_HOLD_FRAMES = 3;

function ratioToSemitones(a: number, b: number): number {
  return 12 * Math.log2(a / b);
}

export class FftPitchDetector implements PitchDetector {
  private _ready = false;
  private _loading = false;
  private detector: PitchyDetector<Float32Array<ArrayBuffer>> | null = null;
  private inputBuffer: Float32Array<ArrayBuffer> | null = null;
  private smoothedPitch = 0;
  private lastAudioInfo: AudioInfo | null = null;
  private silentFrames = 0;

  get ready() {
    return this._ready;
  }

  get loading() {
    return this._loading;
  }

  async init(analyserNode: AnalyserNode, audioContext: AudioContext): Promise<void> {
    this._loading = true;

    try {
      analyserNode.fftSize = FFT_SIZE;
      this.detector = PitchyDetector.forFloat32Array(analyserNode.fftSize);
      this.inputBuffer = new Float32Array(this.detector.inputLength);
      this.smoothedPitch = 0;
      this.lastAudioInfo = null;
      this.silentFrames = 0;

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

    if (clarity < FFT_MIN_CLARITY || pitch <= 0 || !Number.isFinite(pitch)) {
      this.silentFrames++;

      if (this.silentFrames <= FFT_SILENCE_HOLD_FRAMES && this.lastAudioInfo) {
        return this.lastAudioInfo;
      }

      this.smoothedPitch = 0;
      this.lastAudioInfo = null;
      return null;
    }

    this.silentFrames = 0;

    if (this.smoothedPitch === 0) {
      this.smoothedPitch = pitch;
    } else {
      const jumpSemitones = Math.abs(ratioToSemitones(pitch, this.smoothedPitch));
      if (jumpSemitones > FFT_SMOOTHING_JUMP_SEMITONES) {
        this.smoothedPitch = pitch;
      } else {
        this.smoothedPitch =
          pitch * FFT_PITCH_SMOOTHING_ALPHA + this.smoothedPitch * (1 - FFT_PITCH_SMOOTHING_ALPHA);
      }
    }

    const rawNoteNumber = getNoteNumberFromPitch(this.smoothedPitch);
    const noteName = NOTES[rawNoteNumber % 12];

    this.lastAudioInfo = {
      pitch: Math.round(this.smoothedPitch * 10) / 10,
      clarity: Math.round(clarity * 100),
      note: noteName,
      scale: getScaleFromNoteNumber(rawNoteNumber),
      detune: getDetuneFromPitch(this.smoothedPitch, rawNoteNumber)
    };

    return this.lastAudioInfo;
  }

  destroy(): void {
    this.detector = null;
    this.inputBuffer = null;
    this.smoothedPitch = 0;
    this.lastAudioInfo = null;
    this.silentFrames = 0;
    this._ready = false;
    this._loading = false;
  }
}
