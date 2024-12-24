<script lang="ts">
  let frequency = $state(0);
  let is_listening = $state(false);

  let graph_canvas: HTMLCanvasElement = $state(null!);
  $effect(() => {
    if (!is_listening) return;
  });

  async function startFrequencyDetection() {
    if (is_listening) return; // Prevent multiple calls
    is_listening = true;

    const audioContext = new AudioContext();
    const analyser = audioContext.createAnalyser();
    analyser.fftSize = 2048; // Set FFT size for frequency resolution

    const bufferLength = analyser.frequencyBinCount;
    const frequencyData = new Uint8Array(bufferLength);

    // Access microphone
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const source = audioContext.createMediaStreamSource(stream);
    source.connect(analyser);

    function detectFrequency() {
      analyser.getByteFrequencyData(frequencyData);

      // Find the dominant frequency
      const maxIndex = frequencyData.indexOf(Math.max(...frequencyData));
      const nyquist = audioContext.sampleRate / 2;
      frequency = parseFloat(((maxIndex / bufferLength) * nyquist).toFixed(2));

      // Loop
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
  <title>Freequency Reader</title>
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

{#if is_listening}
  <div class="mt-4 text-xl font-bold">
    Detected Frequency: <strong>{frequency} Hz</strong>
    <div class="mt-4 rounded-lg border-2 border-gray-700">
      <canvas bind:this={graph_canvas}></canvas>
    </div>
  </div>
{/if}
