export interface AudioInfo {
  pitch: number;
  clarity: number;
  note: string;
  scale: number;
  detune: number;
}

export const EMPTY_AUDIO_INFO: AudioInfo = {
  pitch: 0,
  clarity: 0,
  note: '',
  scale: 0,
  detune: NaN
};

export interface PitchDetector {
  /**
   * Initialize the pitch detector.
   * Can be asynchronous (e.g., to load WASM).
   * It should set the analyserNode's fftSize if necessary.
   */
  init(analyserNode: AnalyserNode, audioContext: AudioContext): Promise<void>;

  /**
   * Synchronously process a frame and detect pitch.
   * Return null if no confident pitch is detected.
   */
  detect(analyserNode: AnalyserNode, audioContext: AudioContext): AudioInfo | null;

  /**
   * Tear down ongoing processes, memory, or workers.
   */
  destroy(): void;

  /**
   * True once init() has successfully completed.
   */
  readonly ready: boolean;

  /**
   * True while init() is executing.
   */
  readonly loading: boolean;
}
