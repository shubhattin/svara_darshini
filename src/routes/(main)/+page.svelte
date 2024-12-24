<script lang="ts">
  let frequency = $state(0); // Store the detected frequency
  let isListening = $state(false); // Toggle listening state

  async function startFrequencyDetection() {
    if (isListening) return; // Prevent multiple calls
    isListening = true;

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
      frequency = (maxIndex / bufferLength) * nyquist;

      // Loop
      if (isListening) {
        requestAnimationFrame(detectFrequency);
      }
    }

    detectFrequency();
  }

  function stopFrequencyDetection() {
    isListening = false;
    frequency = 0;
  }
</script>

<svelte:head>
  <title>Freequency Reader</title>
</svelte:head>

<div class="m-4 text-center text-2xl">
  {#if isListening}
    Detected Frequency: <strong>{frequency} Hz</strong>
  {/if}
</div>

<div class="spaxe-x-6">
  <button
    class="btn cursor-pointer bg-green-400 px-2 py-1"
    onclick={startFrequencyDetection}
    disabled={isListening}
  >
    Start
  </button>
  <button
    class="btn m-2 cursor-pointer px-2 py-1"
    onclick={stopFrequencyDetection}
    disabled={!isListening}
  >
    Stop
  </button>
</div>
