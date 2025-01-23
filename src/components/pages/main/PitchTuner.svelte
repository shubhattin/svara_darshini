<script lang="ts">
  import AudioMotionAnalyzer from 'audiomotion-analyzer';
  import { PitchDetector } from 'pitchy';
  import { NOTES } from './constants';
  import { onMount } from 'svelte';
  import { FiPlay } from 'svelte-icons-pack/fi';
  import Icon from '~/tools/Icon.svelte';
  import { BiStopCircle } from 'svelte-icons-pack/bi';
  import { cl_join } from '~/tools/cl_join';
  import { slide } from 'svelte/transition';

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

    // stop audio motion
    audio_motion?.disconnectInput(mic_stream, true);

    // stop mic stream
    mic_stream?.disconnect();

    // destroy analyzer node
    analyzer_node?.disconnect();

    // stop audio context
    audio_context?.close();

    audio_info = null;
    audio_context = null;
    analyzer_node = null;
    audio_motion = null;
    mic_stream = null;
    if (audio_div_element) {
      audio_div_element.innerHTML = '';
    }
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
      in:slide
      out:slide
      class="btn mt-40 gap-1 rounded-lg bg-primary-600 px-3 py-1 text-xl font-bold text-white dark:bg-primary-500"
      onclick={Start}
    >
      <Icon src={FiPlay} class="text-2xl" />
      Start
    </button>
  {/if}
  <div
    bind:this={audio_div_element}
    class={cl_join('h-full w-full', !audio_info && 'inset-0 z-[-10] hidden h-0 w-0')}
  ></div>
  <div class="z-10 mt-2">
    {#if audio_info}
      {@const { clarity, detune, note, pitch, scale } = audio_info}
      <div class="flex flex-col items-center justify-center space-y-2">
        <div class="text-primary text-2xl">
          {note}
          {#if scale !== 0}
            <span class="text-zinc-800 dark:text-zinc-300">{scale}</span>
          {/if}
        </div>
        <div class="text-3xl">{pitch} Hz</div>
        <progress class="progress-success progress w-56" value={clarity} max="100"></progress>
        <kbd class="kbd rounded-lg">{detune} cents</kbd>
      </div>
      <div class="mt-6 flex items-center justify-center">
        <button
          class="btn gap-1 rounded-lg bg-error-500 px-2 py-1 text-xl font-bold text-white"
          onclick={Stop}
        >
          <Icon src={BiStopCircle} class="text-2xl" />
          Stop
        </button>
      </div>
    {/if}
  </div>
</div>
