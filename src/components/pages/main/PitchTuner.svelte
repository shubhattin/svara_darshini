<script lang="ts">
  import AudioMotionAnalyzer from 'audiomotion-analyzer';
  import { PitchDetector } from 'pitchy';
  import { NOTES } from './constants';
  import { onMount } from 'svelte';
  import { FiPlay } from 'svelte-icons-pack/fi';
  import Icon from '~/tools/Icon.svelte';
  import { slide } from 'svelte/transition';
  import { BiStopCircle } from 'svelte-icons-pack/bi';

  const getNoteNumberFromPitch = (frequency: number) => {
    const noteNum = 12 * (Math.log(frequency / 440) / Math.log(2));
    return Math.round(noteNum) + 69;
  };

  const getNoteFrequency = (note: number) => {
    return 440 * Math.pow(2, (note - 69) / 12);
  };

  let audio_context: AudioContext | null = null;
  let analyzer_node: AnalyserNode | null = null;
  let update_interval: NodeJS.Timeout = null!;
  let mic_stream: MediaStreamAudioSourceNode | null = null;
  let audio_motion: AudioMotionAnalyzer | null = null;
  let audio_div_element = $state<HTMLDivElement | null>(null);

  let audio_info = $state<{
    pitch: number;
    clarity: number;
    note: string;
    scale: number;
    detune: number;
  } | null>(null);

  const Stop = () => {
    //clear interval
    clearInterval(update_interval);

    audio_info = null;

    // stop mic stream
    mic_stream?.disconnect();
    // stop audio motion
    audio_motion?.disconnectInput(mic_stream, true);

    // destroy analyzer node
    analyzer_node?.disconnect();
    // stop audio context
    audio_context?.close();
  };

  onMount(() => {
    clearInterval(update_interval);

    return () => {
      Stop();
    };
  });

  const Start = () => {
    try {
      // start audio context
      audio_context = new AudioContext();
      // create analyzer node
      analyzer_node = audio_context.createAnalyser();

      audio_motion = new AudioMotionAnalyzer(audio_div_element!, {
        mode: 10,
        channelLayout: 'single',
        fillAlpha: 0.6,
        gradient: 'rainbow',
        lineWidth: 1.5,
        maxFreq: 20000,
        minFreq: 30,
        mirror: -1,
        radial: false,
        reflexAlpha: 1,
        reflexBright: 1,
        reflexRatio: 0.5,
        showPeaks: false,
        showScaleX: false
      });

      // connect analyzer node to audio context destination
      navigator.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
        // console.log(audio_context, analyzer_node);
        if (!audio_context) return;
        if (!analyzer_node) return;
        if (!audio_motion) return;

        if (!stream) return;
        mic_stream = audio_motion.audioCtx.createMediaStreamSource(stream);
        audio_motion.connectInput(mic_stream);
        // set vol to 0
        audio_motion.volume = 0;

        audio_context.createMediaStreamSource(stream).connect(analyzer_node);
        const detector = PitchDetector.forFloat32Array(analyzer_node.fftSize);
        const input = new Float32Array(detector.inputLength);

        clearInterval(update_interval);

        // update every 100ms
        update_interval = setInterval(() => {
          analyzer_node?.getFloatTimeDomainData(input);
          const [pitch, clarity] = detector.findPitch(input, audio_context!.sampleRate);
          // console.log(pitch, clarity);
          const rawNote = getNoteNumberFromPitch(pitch);
          const noteName = NOTES[rawNote % 12];
          // console.log(pitch);
          audio_info = {
            pitch: Math.round(pitch * 10) / 10,
            clarity: Math.round(clarity * 100),
            note: noteName,
            scale: Math.floor(rawNote / 12) - 1,
            detune: Math.floor((1200 * Math.log(pitch / getNoteFrequency(rawNote))) / Math.log(2))
          };
        }, 100);
      });
    } catch (error) {
      console.log('error in Start-->', error);
    }
  };
</script>

<div class="flex h-full w-full flex-col items-center">
  {#if !audio_info}
    <button
      class="btn mt-40 gap-1 rounded-lg bg-primary-600 text-xl font-bold text-white dark:bg-primary-500"
      onclick={Start}
    >
      <Icon src={FiPlay} class="text-2xl" />
      Start
    </button>
  {/if}
  <div class="relative h-full w-full">
    <!-- {#if audio_info} -->
    <div bind:this={audio_div_element} class="h-full w-full"></div>
    <!-- {/if} -->
    <div class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 transform">
      {#if audio_info}
        {@const { clarity, detune, note, pitch, scale } = audio_info}
        <div class="flex flex-col items-center justify-center">
          <div class="text-primary text-2xl">
            {`${note}`}
            {scale === 0 ? '' : scale}
          </div>
          <div class="text-accent text-3xl">{`${pitch} Hz`}</div>
          <br />
          <progress class="progress-success progress w-56" value={clarity} max="100"></progress>
          <br />
          <kbd class="kbd-lg kbd">{`${detune} cents`}</kbd>
        </div>
        <button
          class="btn mt-6 block gap-1 rounded-lg bg-error-600 px-2 py-1 text-xl font-bold text-white dark:bg-error-500"
          onclick={Stop}
        >
          <Icon src={BiStopCircle} class="text-2xl" />
          Stop
        </button>
      {/if}
    </div>
  </div>
</div>
