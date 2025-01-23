<script lang="ts">
  import { scale, slide } from 'svelte/transition';

  let frequency = $state(0);
  let is_listening = $state(false);
  let fft_size = $state(8192);

  async function startFrequencyDetection() {
    if (is_listening) return;
    is_listening = true;

    const audioContext = new AudioContext();
    const analyser = audioContext.createAnalyser();

    // Increase FFT size for better frequency resolution
    analyser.fftSize = fft_size; // Increased from 2048

    // Reduce smoothing for more accurate real-time detection
    analyser.smoothingTimeConstant = 0.3; // Default is 0.8

    const bufferLength = analyser.frequencyBinCount;
    const frequencyData = new Float32Array(bufferLength); // Using Float32Array for better precision

    const stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: false,
        noiseSuppression: false,
        autoGainControl: false
      }
    });

    const source = audioContext.createMediaStreamSource(stream);
    source.connect(analyser);

    function applyHannWindow(buffer: Float32Array) {
      for (let i = 0; i < buffer.length; i++) {
        const multiplier = 0.5 * (1 - Math.cos((2 * Math.PI * i) / buffer.length));
        buffer[i] *= multiplier;
      }
    }

    function findPeaks(buffer: Float32Array) {
      const peaks = [];
      const threshold = -60; // Adjust based on your needs

      for (let i = 1; i < buffer.length - 1; i++) {
        if (buffer[i] > threshold && buffer[i] > buffer[i - 1] && buffer[i] > buffer[i + 1]) {
          peaks.push(i);
        }
      }

      return peaks.sort((a, b) => buffer[b] - buffer[a]);
    }

    function interpolatePeakPosition(buffer: Float32Array, peakIndex: number) {
      if (peakIndex <= 0 || peakIndex >= buffer.length - 1) return peakIndex;

      const alpha = buffer[peakIndex - 1];
      const beta = buffer[peakIndex];
      const gamma = buffer[peakIndex + 1];
      const p = (0.5 * (alpha - gamma)) / (alpha - 2 * beta + gamma);

      return peakIndex + p;
    }

    // Implementation of moving average for smoothing
    const movingAverageWindow: number[] = [];
    const windowSize = 5;

    function applyMovingAverage(value: number) {
      movingAverageWindow.push(value);
      if (movingAverageWindow.length > windowSize) {
        movingAverageWindow.shift();
      }

      return movingAverageWindow.reduce((a, b) => a + b) / movingAverageWindow.length;
    }

    function detectFrequency() {
      // Use getFloatFrequencyData for better amplitude resolution
      analyser.getFloatFrequencyData(frequencyData);

      // Apply windowing to reduce spectral leakage
      applyHannWindow(frequencyData);

      // Find peaks instead of just maximum
      const peaks = findPeaks(frequencyData);

      // Calculate frequency with interpolation for better accuracy
      const dominantPeak = peaks[0];
      const interpolatedIndex = interpolatePeakPosition(frequencyData, dominantPeak);

      const nyquist = audioContext.sampleRate / 2;
      frequency = parseFloat(((interpolatedIndex / bufferLength) * nyquist).toFixed(2));

      // Apply moving average to smooth out fluctuations
      frequency = applyMovingAverage(frequency);

      if (is_listening) {
        requestAnimationFrame(detectFrequency);
      }
    }

    detectFrequency();
  }

  function stopFrequencyDetection() {
    is_listening = false;
    frequency = 0;
  }
</script>

<svelte:head>
  <title>Frequency Reader</title>
</svelte:head>

<div class="mt-4 space-x-6">
  <button
    class="btn rounded-md bg-green-600 px-2 py-1 text-lg font-bold text-white dark:bg-green-700"
    onclick={startFrequencyDetection}
    disabled={is_listening}
  >
    Start
  </button>
  <button
    class="btn rounded-md bg-red-600 px-2 py-1 text-lg font-bold text-white dark:bg-red-700"
    onclick={stopFrequencyDetection}
    disabled={!is_listening}
  >
    Stop
  </button>
</div>
<label class="mt-3 block">
  <span class="label-text">FFT Size</span>
  <select bind:value={fft_size} class="select w-32 rounded-md">
    {#each Array.from({ length: 8 }).map((_, i) => Math.pow(2, i + 9)) as size}
      <option value={size}>{size}</option>
    {/each}
  </select>
</label>
{#if is_listening}
  <div in:scale out:slide class="mt-4 text-xl font-bold">
    <div class="font-semibold">
      Detected Frequency: <span class="font-bold text-primary-500 dark:text-primary-400"
        >{parseFloat(frequency.toFixed(2))} Hz</span
      >
    </div>
  </div>
{/if}
