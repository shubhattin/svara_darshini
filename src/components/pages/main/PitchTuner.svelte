<script lang="ts">
  import { PitchDetector } from 'pitchy';
  import { NOTES, type note_types } from './constants';
  import { onMount } from 'svelte';
  import { FiPlay, FiRefreshCcw } from 'svelte-icons-pack/fi';
  import Icon from '~/tools/Icon.svelte';
  import { BiStopCircle } from 'svelte-icons-pack/bi';
  import { fade, scale, slide } from 'svelte/transition';
  import { BsChevronDown, BsChevronUp, BsMic } from 'svelte-icons-pack/bs';
  import { delay } from '~/tools/delay';
  import { cl_join } from '~/tools/cl_join';
  import PitchDisplay from './PitchDisplay.svelte';
  import { Popover } from '@skeletonlabs/skeleton-svelte';
  import { indactivity_timeout } from './inactivity';
  import ms from 'ms';

  let {
    selected_device = $bindable(),
    selected_Sa_at = $bindable(),
    selected_sargam_orientation = $bindable(),
    selected_note_orientation = $bindable()
  }: {
    selected_device: string;
    selected_Sa_at: note_types;
    selected_sargam_orientation: 'radial' | 'vertical';
    selected_note_orientation: 'radial' | 'vertical';
  } = $props();

  let audio_devices = $state<MediaDeviceInfo[]>([]);
  let device_list_loaded = $state(false);

  let audio_context: AudioContext | null = null;
  let analyzer_node: AnalyserNode | null = null;
  let update_interval: NodeJS.Timeout | null = null;
  let mic_stream: MediaStream | null = null;

  let orientation_popup_status = $state(false);
  let Sa_at_popup_status = $state(false);

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
    indactivity_timeout(ms('30mins'), Stop);
  });

  let started = $state(false);

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
    started = false;
    //clear interval
    clearInterval(update_interval!);

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
    clearInterval(update_interval!);

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

      clearInterval(update_interval!);

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
      started = true;
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

{#if !started}
  <div
    class="mt-12 flex flex-col items-center justify-center space-y-8 sm:mt-15 md:mt-18 xl:mt-20"
    in:fade
    out:slide
  >
    <div class="space-y-4 text-center">
      <h1
        class="bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-600 bg-clip-text text-4xl font-bold text-transparent md:text-5xl"
      >
        Welcome to Svara Darshini
      </h1>
      <p
        class="mx-auto max-w-2xl text-lg leading-relaxed text-gray-600 md:text-xl dark:text-gray-300"
      >
        An intuitive tool to understand the principles of music that are common across the world.
        Discover the beauty of musical notes and their relationships through our interactive pitch
        tuner.
      </p>
      <p class="mx-auto max-w-xl text-base text-gray-500 dark:text-gray-400">
        Click the button below to start analyzing your voice or instrument. The circular display
        will show you exactly which note you're playing and how in-tune it is.
      </p>
    </div>
    <button
      in:slide
      out:slide
      class="group relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-500 via-purple-500 to-indigo-600
             px-8 py-4 text-xl font-bold text-white shadow-xl
             transition-all duration-300 ease-out
             hover:scale-105 hover:from-blue-600
             hover:via-purple-600 hover:to-indigo-700 hover:shadow-2xl active:scale-95"
      onclick={Start}
    >
      <div
        class="absolute inset-0 translate-x-[-100%] bg-gradient-to-r from-white/0 via-white/20 to-white/0 transition-transform duration-700 ease-out group-hover:translate-x-[100%]"
      ></div>
      <div class="relative flex items-center gap-3">
        <Icon
          src={FiPlay}
          class="text-2xl transition-transform duration-200 group-hover:scale-110"
        />
        <span>Start</span>
      </div>
    </button>
  </div>
{/if}
<div class="mb-4 select-none">
  {#if audio_info && started}
    {@const { clarity, pitch } = audio_info}
    <div class="flex flex-col items-center justify-center space-y-2 sm:space-y-3">
      <div class="mt-2 outline-hidden select-none sm:mt-4">
        <div class="flex items-start justify-center space-x-4">
          <Popover
            open={Sa_at_popup_status}
            onOpenChange={(e) => (Sa_at_popup_status = e.open)}
            contentBase="card z-50 space-y-2 p-2 rounded-lg shadow-xl dark:bg-surface-900 bg-slate-100"
          >
            {#snippet trigger()}
              <div class="text-center outline-hidden">
                <span class="mr-2 font-bold"><span>S</span> at</span>
                {#if !Sa_at_popup_status}
                  <Icon src={BsChevronDown} class="text-base" />
                {:else}
                  <Icon src={BsChevronUp} class="text-base" />
                {/if}
                {selected_Sa_at}
              </div>
            {/snippet}
            {#snippet content()}
              <div class="grid grid-cols-4 gap-x-2 gap-y-1 sm:grid-cols-6 sm:gap-x-2">
                {#each NOTES as _, i}
                  {@const note = NOTES[(i + 9) % NOTES.length]}
                  <button
                    class={cl_join(
                      'gap-0 rounded-md px-1 py-1 text-sm font-semibold text-white sm:text-base',
                      selected_Sa_at === note
                        ? 'bg-primary-500 dark:bg-primary-600'
                        : 'bg-slate-400 hover:bg-primary-500/80 dark:bg-slate-800 dark:hover:bg-primary-600/80'
                    )}
                    onclick={() => {
                      selected_Sa_at = note as note_types;
                      Sa_at_popup_status = false;
                    }}>{note}</button
                  >
                {/each}
              </div>
            {/snippet}
          </Popover>
        </div>
        <PitchDisplay
          {audio_info}
          bind:Sa_at={selected_Sa_at}
          sargam_orientation={selected_sargam_orientation}
          note_orientation={selected_note_orientation}
        />
        <!-- <PitchDisplay
            audio_info={{
              clarity: 100,
              note: 'D',
              scale: 0,
              detune: 0,
              pitch: 2
            }}
            bind:Sa_at={selected_Sa_at}
            sargam_orientation={selected_sargam_orientation}
            note_orientation={selected_note_orientation}
          /> -->
      </div>
      <div class="text-3xl">{pitch} Hz</div>
      <div class="space-y-0">
        <div class="-mb-1 text-center text-sm font-semibold">Clarity</div>
        <progress class="progress w-56" value={clarity} max="100"></progress>
      </div>
      <Popover
        contentBase="card z-50 space-y-2 p-2 rounded-lg shadow-xl dark:bg-surface-900 bg-slate-100"
        open={orientation_popup_status}
        onOpenChange={(e) => (orientation_popup_status = e.open)}
      >
        {#snippet trigger()}
          <div class="text-center font-bold outline-hidden">
            Orientation
            {#if !orientation_popup_status}
              <Icon src={BsChevronDown} class="text-lg" />
            {:else}
              <Icon src={BsChevronUp} class="text-lg" />
            {/if}
          </div>
        {/snippet}
        {#snippet content()}
          <div class="space-x-1">
            <span class="text-sm font-semibold">Sargam</span>
            <label>
              <input type="radio" bind:group={selected_sargam_orientation} value="vertical" />
              <span class="text-sm">Vertical</span>
            </label>
            <label>
              <input type="radio" bind:group={selected_sargam_orientation} value="radial" />
              <span class="text-sm">Radial</span>
            </label>
          </div>
          <div class="space-x-1">
            <span class="text-sm font-semibold">Note</span>
            <label>
              <input type="radio" bind:group={selected_note_orientation} value="vertical" />
              <span class="text-sm">Vertical</span>
            </label>
            <label>
              <input type="radio" bind:group={selected_note_orientation} value="radial" />
              <span class="text-sm">Radial</span>
            </label>
          </div>
        {/snippet}
      </Popover>

      <!-- Stop button -->
      <div class="mt-4 flex items-center justify-center sm:mt-5">
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
      class="-mt-1 inline-block h-10 placeholder w-44 animate-pulse rounded-md sm:w-56 md:w-60 lg:w-64"
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
    class={cl_join('btn p-0 pl-2 outline-hidden select-none')}
    onclick={() => get_audio_devices()}
    disabled={!device_list_loaded}
  >
    <Icon src={FiRefreshCcw} class=" text-lg" />
  </button>
</label>
