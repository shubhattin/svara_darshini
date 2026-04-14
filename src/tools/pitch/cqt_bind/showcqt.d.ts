declare module 'showcqt' {
  export interface ShowCqtInstance {
    fft_size: number;
    inputs: [Float32Array, Float32Array];
    color: Float32Array;
    init(
      sampleRate: number,
      width: number,
      height: number,
      barVolume: number,
      sonoVolume: number,
      supersampling: boolean
    ): void;
    calc(): void;
  }

  interface ShowCqtModule {
    instantiate(): Promise<ShowCqtInstance>;
  }

  const ShowCQT: ShowCqtModule;
  export default ShowCQT;
}
