declare module 'showcqt' {
  interface ShowCQTInstance {
    fft_size: number;
    width: number;
    inputs: [Float32Array, Float32Array];
    output: Uint8ClampedArray;
    color: Float32Array;
    init(
      rate: number,
      width: number,
      height: number,
      bar_v: number,
      sono_v: number,
      supersampling: boolean
    ): void;
    calc(): void;
    render_line_alpha(y: number, alpha: number): void;
    render_line_opaque(y: number): void;
    set_height(height: number): void;
    set_volume(bar_v: number, sono_v: number): void;
    detect_silence(): boolean;
  }

  interface ShowCQTStatic {
    version: string;
    instantiate(opt?: { simd?: boolean }): Promise<ShowCQTInstance>;
  }

  export const ShowCQT: ShowCQTStatic;
  export default ShowCQT;
}
