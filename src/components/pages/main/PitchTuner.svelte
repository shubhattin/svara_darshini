<script lang="ts">
  import { PitchDetector } from 'pitchy';
  import { NOTES, type note_types } from './constants';
  import { onMount } from 'svelte';
  import { FiPlay, FiRefreshCcw } from 'svelte-icons-pack/fi';
  import Icon from '~/tools/Icon.svelte';
  import { BiStopCircle } from 'svelte-icons-pack/bi';
  import { slide } from 'svelte/transition';
  import { BsMic } from 'svelte-icons-pack/bs';
  import { delay } from '~/tools/delay';
  import { cl_join } from '~/tools/cl_join';
  import PitchDisplay from './PitchDisplay.svelte';

  let {
    selected_device = $bindable(),
    selected_Sa_at = $bindable()
  }: { selected_device: string; selected_Sa_at: note_types } = $props();

  let audio_devices = $state<MediaDeviceInfo[]>([]);
  let device_list_loaded = $state(false);

  let audio_context: AudioContext | null = null;
  let analyzer_node: AnalyserNode | null = null;
  let update_interval: NodeJS.Timeout = null!;
  let mic_stream: MediaStream | null = null;

  const FFT_SIZE = Math.pow(2, 12); // 4096

  const get_audio_devices = async (show_loading = true) => {
    if (show_loading) device_list_loaded = false;
    await delay(250, true);
    const devices = await navigator.mediaDevices.enumerateDevices();
    audio_devices = devices.filter((device) => device.kind === 'audioinput');
    if (!audio_devices.some((device) => device.deviceId === selected_device))
      selected_device = audio_devices[0].deviceId; // set to 1st available device (default)
    if (show_loading) device_list_loaded = true;
  };
  onMount(() => {
    get_audio_devices();
  });

  let audio_info = $state<{
    pitch: number;
    clarity: number;
    note: string;
    scale: number;
    detune: number;
  } | null>(null);

  const getNoteNumberFromPitch = (frequency: number) => {
    const noteNum = 12 * (Math.log(frequency / 440) / Math.log(2));
    return Math.round(noteNum) + 69;
  };

  const getNoteFrequency = (note: number) => {
    return 440 * Math.pow(2, (note - 69) / 12);
  };

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

  const Start = async () => {
    try {
      // start audio context
      audio_context = new AudioContext();
      // create analyzer node
      analyzer_node = audio_context.createAnalyser();

      // connect analyzer node to audio context destination
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          deviceId: selected_device ? { exact: selected_device } : undefined
        }
      });
      get_audio_devices(false); // refesh list
      if (!audio_context) return;
      if (!analyzer_node) return;

      if (!stream) return;
      mic_stream = stream;

      analyzer_node.fftSize = FFT_SIZE;

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
    } catch (error) {
      console.log('error in Start-->', error);
    }
  };

  const handleDeviceChange = () => {
    if (audio_info) {
      // disconnect previous mic
      mic_stream?.getTracks().forEach((track) => track.stop());
      Start(); // Restart with new device if already running
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
  <div class="z-10 mb-4">
    {#if audio_info}
      {@const { clarity, detune, note, pitch, scale } = audio_info}
      <div class="flex flex-col items-center justify-center space-y-4">
        <div
          class="relative mb-8 mt-4 h-72 w-72 select-none sm:mt-8 sm:h-80 sm:w-80 md:h-96 md:w-96"
        >
          <div class="flex items-start justify-center">
            <label class=" space-x-1">
              <span class="font-semibold">Sa at</span>
              <select
                class="select inline-block w-16 rounded-md px-2 py-1"
                bind:value={selected_Sa_at}
              >
                {#each NOTES as note}
                  <option value={note}>{note}</option>
                {/each}
              </select>
            </label>
          </div>
          <PitchDisplay {audio_info} Sa_at={selected_Sa_at} />
        </div>
        <div class=" text-3xl">{pitch} Hz</div>
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
  <label class="mt-3 flex space-x-1">
    <Icon src={BsMic} class="text-2xl sm:text-3xl" />
    {#if !device_list_loaded}
      <span
        class="placeholder -mt-1 inline-block h-10 w-44 animate-pulse rounded-md sm:w-56 md:w-60 lg:w-64"
      ></span>
    {:else}
      <select
        class="select inline-block w-44 rounded-md px-2 py-1 sm:w-56 md:w-60 lg:w-64"
        bind:value={selected_device}
        onchange={handleDeviceChange}
      >
        {#each audio_devices as device (device.deviceId)}
          <option value={device.deviceId}>
            {device.label || `Microphone ${audio_devices.indexOf(device) + 1}`}
          </option>
        {/each}
      </select>
    {/if}
    <button
      title="Refresh Device List"
      class={cl_join('btn m-0 select-none p-0 pl-2 outline-none')}
      onclick={() => get_audio_devices()}
      disabled={!device_list_loaded}
    >
      <Icon src={FiRefreshCcw} class=" text-lg" />
    </button>
  </label>
</div>
