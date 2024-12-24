<script>
	import { onMount } from 'svelte';

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

<div class="frequency-display">
	{#if isListening}
		Detected Frequency: <strong>{frequency} Hz</strong>
	{:else}
		Click "Start" to detect frequency
	{/if}
</div>

<div>
	<button onclick={startFrequencyDetection} disabled={isListening}> Start </button>
	<button onclick={stopFrequencyDetection} disabled={!isListening}> Stop </button>
</div>

<style>
	.frequency-display {
		font-size: 2rem;
		margin: 1rem;
		text-align: center;
	}
	button {
		margin: 0.5rem;
		padding: 0.5rem 1rem;
		font-size: 1rem;
		cursor: pointer;
	}
</style>
