import ShowCQT from 'showcqt';

export interface CqtEngineConfig {
  sampleRate: number;
  width?: number;
  barVolume?: number;
  sonoVolume?: number;
  supersampling?: boolean;
}

export interface CqtFrameData {
  intensities: Float32Array;
  binCount: number;
}

export interface DetectedCqtPitch {
  frequency: number;
  intensity: number;
  binIndex: number;
}

export interface CqtPitchDetectionConfig {
  minFrequency?: number;
  maxFrequency?: number;
  minIntensity?: number;
}

export const CQT_FREQ_START = 440 * Math.pow(2, (16 - 69 - 0.5) / 12);
export const CQT_OCTAVE_SPAN = 10;

export function cqtBinToFrequency(binIndex: number, binCount: number): number {
  return CQT_FREQ_START * Math.pow(2, (CQT_OCTAVE_SPAN * binIndex) / binCount);
}

export function frequencyToNoteNumber(freq: number): number {
  return 12 * Math.log2(freq / 440) + 69;
}

const refinePeakFrequency = (
  intensities: Float32Array,
  peakBin: number,
  binCount: number,
  rawFrequency: number
) => {
  if (peakBin <= 0 || peakBin >= binCount - 1) {
    return rawFrequency;
  }

  const prev = intensities[peakBin - 1];
  const curr = intensities[peakBin];
  const next = intensities[peakBin + 1];
  const denominator = 2 * (2 * curr - prev - next);

  if (!Number.isFinite(denominator) || denominator <= 0) {
    return rawFrequency;
  }

  const offset = (next - prev) / denominator;
  const prevFrequency = cqtBinToFrequency(peakBin - 1, binCount);
  const nextFrequency = cqtBinToFrequency(peakBin + 1, binCount);

  return (
    rawFrequency +
    offset * (offset > 0 ? nextFrequency - rawFrequency : rawFrequency - prevFrequency)
  );
};

export function findDominantCqtPitch(
  frame: CqtFrameData,
  config: CqtPitchDetectionConfig = {}
): DetectedCqtPitch | null {
  const { minFrequency = 60, maxFrequency = 2200, minIntensity = 0.05 } = config;

  let peakIntensity = minIntensity;
  let peakBin = -1;

  for (let binIndex = 0; binIndex < frame.binCount; binIndex++) {
    const frequency = cqtBinToFrequency(binIndex, frame.binCount);
    if (frequency < minFrequency || frequency > maxFrequency) continue;

    const intensity = frame.intensities[binIndex];
    if (intensity > peakIntensity) {
      peakIntensity = intensity;
      peakBin = binIndex;
    }
  }

  if (peakBin < 0) {
    return null;
  }

  const rawFrequency = cqtBinToFrequency(peakBin, frame.binCount);

  return {
    frequency: refinePeakFrequency(frame.intensities, peakBin, frame.binCount, rawFrequency),
    intensity: peakIntensity,
    binIndex: peakBin
  };
}

export class CqtEngine {
  private cqt: Awaited<ReturnType<typeof ShowCQT.instantiate>> | null = null;
  private _fftSize = 0;
  private _width = 0;
  private _ready = false;
  private inputBuffer: Float32Array<ArrayBuffer> | null = null;

  get fftSize() {
    return this._fftSize;
  }

  get ready() {
    return this._ready;
  }

  async init(config: CqtEngineConfig) {
    const {
      sampleRate,
      width = 960,
      barVolume = 17,
      sonoVolume = 25,
      supersampling = true
    } = config;

    this.cqt = await ShowCQT.instantiate();
    this._width = width;
    this.cqt.init(sampleRate, width, 1, barVolume, sonoVolume, supersampling);
    this._fftSize = this.cqt.fft_size;
    this.inputBuffer = new Float32Array(
      new ArrayBuffer(this.cqt.inputs[0].length * Float32Array.BYTES_PER_ELEMENT)
    );
    this._ready = true;
  }

  computeFrame(analyserNode: AnalyserNode): CqtFrameData | null {
    if (!this.cqt || !this._ready || !this.inputBuffer) return null;

    analyserNode.getFloatTimeDomainData(this.inputBuffer);
    this.cqt.inputs[0].set(this.inputBuffer);
    this.cqt.inputs[1].set(this.inputBuffer);
    this.cqt.calc();

    const intensities = new Float32Array(this._width);
    const color = this.cqt.color;

    for (let index = 0; index < this._width; index++) {
      intensities[index] = color[index * 4 + 1];
    }

    return {
      intensities,
      binCount: this._width
    };
  }

  destroy() {
    this.cqt = null;
    this._ready = false;
    this._fftSize = 0;
    this._width = 0;
    this.inputBuffer = null;
  }
}
