<script lang="ts">
  import { PitchDetector } from 'pitchy';
  import { NOTES, SARGAM, notesToSargam } from './constants';
  import { onMount } from 'svelte';
  import { FiPlay } from 'svelte-icons-pack/fi';
  import Icon from '~/tools/Icon.svelte';
  import { BiStopCircle } from 'svelte-icons-pack/bi';
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
  let mic_stream: MediaStream | null = null;

  let audioDevices = $state<MediaDeviceInfo[]>([]);
  let selectedDevice = $state<string>('default');

  const getAudioDevices = async () => {
    const devices = await navigator.mediaDevices.enumerateDevices();
    audioDevices = devices.filter((device) => device.kind === 'audioinput');
  };
  onMount(async () => {
    await getAudioDevices();
  });

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

    // stop mic stream
    mic_stream?.getTracks().forEach((track) => track.stop());

    // destroy analyzer node
    analyzer_node?.disconnect();

    // stop audio context
    audio_context?.close();

    audio_info = null;
    audio_context = null;
    analyzer_node = null;
    mic_stream = null;
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

      // connect analyzer node to audio context destination
      navigator.mediaDevices.getUserMedia({ audio: true }).then((stream) => {
        if (!audio_context) return;
        if (!analyzer_node) return;

        if (!stream) return;
        mic_stream = stream;

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

  const centsToRotation = (cents: number, note: string) => {
    // Get the base rotation for the note
    const noteIndex = NOTES.indexOf(note);
    const baseRotation = noteIndex * 30; // 360/12 = 30 degrees per note

    // Add fine rotation from cents (-50 to +50 maps to ±15 degrees)
    const centsRotation = (cents / 50) * 15;

    // Return total rotation
    return baseRotation + centsRotation;
  };

  const isInTune = (cents: number) => Math.abs(cents) <= 5;
</script>

<select class="select" bind:value={selectedDevice}>
  <!-- onchange={handleDeviceChange} -->
  {#each audioDevices as device}
    <option value={device.deviceId}>
      {device.label || `Microphone ${audioDevices.indexOf(device) + 1}`}
    </option>
  {/each}
</select>
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
  <div class="z-10 mb-4">
    {#if audio_info}
      {@const { clarity, detune, note, pitch, scale } = audio_info}
      <div class="flex flex-col items-center justify-center space-y-4">
        <div class="relative h-96 w-96 select-none">
          <svg viewBox="-100 -100 200 200" class="h-full w-full">
            <!-- Outer circle for Sargam -->
            <circle
              cx="0"
              cy="0"
              r="90"
              fill="none"
              stroke="currentColor"
              stroke-width="1"
              class="opacity-20"
            />

            <!-- Inner circle for Notes -->
            <circle cx="0" cy="0" r="70" fill="none" stroke="currentColor" stroke-width="1" />

            <!-- Frequency circles -->
            <circle
              cx="0"
              cy="0"
              r="50"
              fill="none"
              stroke="currentColor"
              stroke-width="0.5"
              class="opacity-50"
            />

            <!-- Note markers and labels -->
            {#each NOTES as note, i}
              {@const angle = i * 30 - 90}
              <!-- Start from top (-90 deg) -->
              <!-- Note tick -->
              <line
                x1="0"
                y1="-70"
                x2="0"
                y2="-65"
                transform="rotate({angle})"
                stroke="currentColor"
                stroke-width="1.5"
              />
              <!-- Note label -->
              <text
                x={50 * Math.cos((angle * Math.PI) / 180)}
                y={50 * Math.sin((angle * Math.PI) / 180)}
                text-anchor="middle"
                dominant-baseline="middle"
                class="fill-black text-xs font-semibold dark:fill-white"
                transform={`rotate(${angle + 90} ${50 * Math.cos((angle * Math.PI) / 180)} ${50 * Math.sin((angle * Math.PI) / 180)})`}
              >
                {note}
              </text>
            {/each}

            <!-- Sargam labels -->
            {#each SARGAM as swar, i}
              {@const angle = i * (360 / 7) - 90}
              <text
                x={85 * Math.cos((angle * Math.PI) / 180)}
                y={85 * Math.sin((angle * Math.PI) / 180)}
                text-anchor="middle"
                dominant-baseline="middle"
                class="fill-black text-xs font-medium opacity-90 dark:fill-white"
                transform={`rotate(${angle + 90} ${85 * Math.cos((angle * Math.PI) / 180)} ${85 * Math.sin((angle * Math.PI) / 180)})`}
              >
                {swar}
              </text>
            {/each}

            <!-- Fine tick marks for cents -->
            {#each Array(60) as _, i}
              {@const angle = i * 6 - 90}
              {@const isMajor = i % 5 === 0}
              <line
                x1="0"
                y1="-70"
                x2="0"
                y2={isMajor ? -65 : -67}
                transform="rotate({angle})"
                stroke="currentColor"
                stroke-width={isMajor ? 1 : 0.5}
                class="opacity-70"
              />
            {/each}

            <!-- Needle -->
            <g transform={`rotate(${centsToRotation(detune, note)})`}>
              <line
                x1="0"
                y1="0"
                x2="0"
                y2="-60"
                stroke={isInTune(detune) ? '#22c55e' : '#ef4444'}
                stroke-width="2"
              />
              <circle cx="0" cy="-60" r="2" fill={isInTune(detune) ? '#22c55e' : '#ef4444'} />
            </g>

            <!-- Center display -->
            <circle cx="0" cy="0" r="30" class="fill-white opacity-90 dark:fill-black" />
            <text
              x="0"
              y="-10"
              text-anchor="middle"
              class="text-md fill-black font-bold dark:fill-white"
            >
              {note}{scale !== 0 ? scale : ''}
            </text>
            <text x="0" y="10" text-anchor="middle" class="fill-black text-xs dark:fill-white">
              {detune > 0 ? '+' : ''}{detune} cents
            </text>
          </svg>
        </div>

        <div class="text-3xl">{pitch} Hz</div>
        <progress class="progress-success progress w-56" value={clarity} max="100"></progress>

        <!-- Stop button -->
        <div class="mt-6 flex items-center justify-center">
          <button
            class="btn gap-1 rounded-lg bg-error-600 px-2 py-1 text-xl font-bold text-white dark:bg-error-500"
            onclick={Stop}
          >
            <Icon src={BiStopCircle} class="text-2xl" />
            Stop
          </button>
        </div>
      </div>
    {/if}
  </div>
</div>
