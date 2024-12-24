<script lang="ts">
  import {
    Chart,
    LineController,
    LineElement,
    PointElement,
    LinearScale,
    Title,
    Tooltip,
    Legend,
    CategoryScale
  } from 'chart.js';
  import { onMount } from 'svelte';
  import { scale, slide } from 'svelte/transition';

  let frequency = $state(0);
  let is_listening = $state(false);
  let chart: Chart | null = null;
  let freequency_data = $state<number[]>(Array.from({ length: 100 }).map(() => 0));

  onMount(() => {
    Chart.register(
      LineController,
      LineElement,
      PointElement,
      LinearScale,
      Title,
      Tooltip,
      Legend,
      CategoryScale
    );
  });

  let graph_canvas: HTMLCanvasElement = $state(null!);

  $effect(() => {
    if (!is_listening) {
      freequency_data = [];
      return;
    }
    // const data = freequency_data.slice(-100);
    // chart!.data.datasets[0].data = data;
  });

  $effect(() => {
    if (!is_listening || !graph_canvas) return;
    if (chart) chart.destroy();
    chart = new Chart(graph_canvas, {
      type: 'line',
      data: {
        labels: freequency_data.map((v, i) => `${i + 1}`),
        datasets: [
          {
            label: 'Frequency',
            data: freequency_data,
            borderColor: '#007bff',
            backgroundColor: '#007bff',
            fill: false,
            tension: 0.4,
            pointRadius: 0,
            pointHoverRadius: 0,
            pointHitRadius: 0
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            display: false
          },
          title: {
            display: true,
            text: 'Frequency'
          },
          tooltip: {
            enabled: false
          }
        },
        scales: {
          x: {
            display: false
          },
          y: {
            display: true
          }
        }
      }
    });
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

{#if is_listening}
  <div in:scale out:slide class="mt-4 text-xl font-bold">
    <div class="font-semibold">
      Detected Frequency: <span class="font-bold text-primary-500 dark:text-primary-400"
        >{frequency} Hz</span
      >
    </div>
    <div class="mt-4 rounded-lg border-2 border-gray-700 p-1.5">
      <canvas bind:this={graph_canvas}></canvas>
    </div>
  </div>
{/if}
