<script lang="ts">
  import { scale, slide } from 'svelte/transition';

  let frequency = $state(0);
  let is_listening = $state(false);
  let work_factor = $state(2048);

  async function startFrequencyDetection() {
    if (is_listening) return; // Prevent multiple calls
    is_listening = true;

    const audioContext = new AudioContext();
    const analyser = audioContext.createAnalyser();
    analyser.fftSize = work_factor; // Set FFT size for frequency resolution

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
  <span class="label-text">Factor</span>
  <input type="number" step={100} class="input w-32 rounded-md" bind:value={work_factor} />
</label>
{#if is_listening}
  <div in:scale out:slide class="mt-4 text-xl font-bold">
    <div class="font-semibold">
      Detected Frequency: <span class="font-bold text-primary-500 dark:text-primary-400"
        >{frequency} Hz</span
      >
    </div>
  </div>
{/if}
