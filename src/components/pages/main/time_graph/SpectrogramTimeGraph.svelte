<script lang="ts">
  import { cl_join } from '~/tools/cl_join';
  import { mode } from 'mode-watcher';

  let {
    spectrum_history,
    MAX_PITCH_HISTORY_POINTS,
    cqt_width
  }: {
    spectrum_history: Array<{
      time: number;
      scanline: Uint8ClampedArray;
    }>;
    MAX_PITCH_HISTORY_POINTS: number;
    cqt_width: number;
  } = $props();

  // --- Canvas element refs ---
  let canvasEl: HTMLCanvasElement | undefined = $state(undefined);
  let containerEl: HTMLDivElement | undefined = $state(undefined);
  let containerWidth = $state(800);
  let containerHeight = $state(400);

  // ResizeObserver for container
  $effect(() => {
    const el = containerEl;
    if (!el) return;
    const ro = new ResizeObserver((entries) => {
      const entry = entries[0];
      if (entry) {
        containerWidth = Math.round(entry.contentRect.width);
        containerHeight = Math.round(entry.contentRect.height);
      }
    });
    ro.observe(el);
    return () => ro.disconnect();
  });

  // Graph background color
  const graphBgColor = $derived($mode === 'dark' ? '#0f172a' : '#1e293b');

  // Adaptive visible columns
  const VISIBLE_POINTS = $derived(
    Math.max(
      20,
      Math.min(
        MAX_PITCH_HISTORY_POINTS,
        Math.round(MAX_PITCH_HISTORY_POINTS * (containerWidth / 800))
      )
    )
  );

  // Main render effect — draws CQT scanlines as scrolling waterfall columns
  $effect(() => {
    const canvas = canvasEl;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const _bgColor = graphBgColor;
    const _visPoints = VISIBLE_POINTS;
    const _cqtWidth = cqt_width;

    // Set canvas resolution to match container
    const dpr = typeof window !== 'undefined' ? window.devicePixelRatio || 1 : 1;
    canvas.width = containerWidth * dpr;
    canvas.height = containerHeight * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    // Dark background
    ctx.fillStyle = _bgColor;
    ctx.fillRect(0, 0, containerWidth, containerHeight);

    if (_cqtWidth === 0 || spectrum_history.length === 0) return;

    // Get visible spectrum data (most recent N frames)
    const data =
      spectrum_history.length > _visPoints ? spectrum_history.slice(-_visPoints) : spectrum_history;

    // Each frame's scanline is _cqtWidth pixels of RGBA data (width * 4 bytes)
    // We draw each frame as a vertical column on the canvas
    // The CQT scanline represents frequencies from E0-50cents to E10-50cents (left to right = low to high)
    // For our display: Y axis = frequency (bottom = low, top = high), X axis = time

    const colWidth = containerWidth / _visPoints;

    for (let col = 0; col < data.length; col++) {
      const frame = data[col];
      const scanline = frame.scanline;
      const x = col * colWidth;

      // Create a temporary 1-pixel-tall ImageData from the scanline, then draw it rotated
      // scanline has _cqtWidth pixels (RGBA), which maps to the frequency axis

      // We need to draw this as a vertical column
      // Create an offscreen canvas for the column
      const colImageData = ctx.createImageData(1, _cqtWidth);
      const colData = colImageData.data;

      // Copy scanline data, but flip vertically (CQT: left=low freq, we want bottom=low freq)
      for (let freqIdx = 0; freqIdx < _cqtWidth; freqIdx++) {
        const srcIdx = freqIdx * 4;
        const dstIdx = (_cqtWidth - 1 - freqIdx) * 4;
        colData[dstIdx] = scanline[srcIdx]; // R
        colData[dstIdx + 1] = scanline[srcIdx + 1]; // G
        colData[dstIdx + 2] = scanline[srcIdx + 2]; // B
        colData[dstIdx + 3] = scanline[srcIdx + 3]; // A
      }

      // Draw the 1-pixel-wide column to an offscreen canvas, then stretch it
      // Use putImageData on a temporary canvas
      const tmpCanvas = new OffscreenCanvas(1, _cqtWidth);
      const tmpCtx = tmpCanvas.getContext('2d');
      if (!tmpCtx) continue;
      tmpCtx.putImageData(colImageData, 0, 0);

      // Draw stretched to fill the column width and full height
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';
      ctx.drawImage(tmpCanvas, x, 0, Math.ceil(colWidth) + 1, containerHeight);
    }
  });
</script>

<div
  bind:this={containerEl}
  class={cl_join('relative mt-1 w-full', 'h-[60vh] sm:h-[50vh] md:h-[500px] lg:h-[580px]')}
>
  <canvas bind:this={canvasEl} class="h-full w-full rounded-lg select-none" style="display: block;"
  ></canvas>
</div>
