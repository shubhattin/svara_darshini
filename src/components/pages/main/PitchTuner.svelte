<script lang="ts">
  import { PitchDetector } from 'pitchy';
  import {
    NOTES,
    type note_types,
    getNoteNumberFromPitch,
    getScaleFromNoteNumber,
    getDetuneFromPitch
  } from './constants';
  import { onMount, type Snippet } from 'svelte';
  import { FiMusic, FiPlay, FiRefreshCcw } from 'svelte-icons-pack/fi';
  import Icon from '~/tools/Icon.svelte';
  import { BiMicrophone, BiStopCircle } from 'svelte-icons-pack/bi';
  import { fade, slide } from 'svelte/transition';
  import { BsMic } from 'svelte-icons-pack/bs';
  import { delay } from '~/tools/delay';
  import { cl_join } from '~/tools/cl_join';
  import { indactivity_timeout } from './inactivity';
  import ms from 'ms';
  import { Microphone } from '@mozartec/capacitor-microphone';
  import { Tabs } from '@skeletonlabs/skeleton-svelte';
  import CircularScale from './circular/CircularScale.svelte';
  import PitchTimeGraph from './time_graph/PitchTimeGraph.svelte';
  import AudioInputFile from './AudioInputFile.svelte';
  import type { ZodMiniNumber } from 'zod/v4-mini';

  let {
    selected_device = $bindable(),
    selected_Sa_at = $bindable(),
    selected_sargam_orientation = $bindable(),
    selected_note_orientation = $bindable(),
    selected_pitch_display_type = $bindable(),
    selected_timegraph_Sa_at = $bindable(),
    selected_timegraph_bottom_start_note = $bindable(),
    welcome_msg
  }: {
    selected_device: string;
    selected_Sa_at: note_types;
    selected_sargam_orientation: 'radial' | 'vertical';
    selected_note_orientation: 'radial' | 'vertical';
    selected_pitch_display_type: 'circular_scale' | 'time_graph';
    selected_timegraph_Sa_at: note_types;
    selected_timegraph_bottom_start_note: note_types;
    welcome_msg: Snippet;
  } = $props();

  let input_mode = $state<'mic' | 'file'>('mic');
  let input_file = $state<File | null>(null);
  let audio_devices = $state<MediaDeviceInfo[]>([]);
  let device_list_loaded = $state(false);

  // File input states
  let file_is_playing = $state(false);
  let file_current_time = $state(0);
  let file_duration = $state(0);
  let file_audio_element: HTMLAudioElement | null = null;

  let audio_context: AudioContext | null = null;
  let analyzer_node: AnalyserNode | null = null;
  let update_interval: NodeJS.Timeout | null = null;
  let mic_stream: MediaStream | null = null;

  const AUDIO_INFO_UPDATE_INTERVAL = 100;
  const GRAPH_TOTAL_TIME_MS = 8000;

  const FFT_SIZE = Math.pow(2, 12); // 4096

  // Pitch history for time graph
  const MAX_PITCH_HISTORY_POINTS = Math.floor(GRAPH_TOTAL_TIME_MS / AUDIO_INFO_UPDATE_INTERVAL); // 25 points

  let started = $state(false);
  let audio_info = $state<{
    pitch: number;
    clarity: number;
    note: string;
    scale: number;
    detune: number;
  } | null>(null);

  let pitch_history = $state<
    Array<{
      time: number;
      pitch: number;
      note: string;
      clarity: number;
      scale: number;
    }>
  >([]);

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
    function func() {
      console.log('devicechange detected');
      get_audio_devices(false);
      handleDeviceChange();
    }
    navigator.mediaDevices.addEventListener('devicechange', func);
    return () => {
      navigator.mediaDevices.removeEventListener('devicechange', func);
    };
  });

  const Stop = () => {
    started = false;
    //clear interval
    clearInterval(update_interval!);

    // stop mic stream
    mic_stream?.getTracks().forEach((track) => track.stop());

    // stop file audio if playing
    if (input_mode === 'file' && file_audio_element) {
      file_audio_element.pause();
      file_is_playing = false;
    }

    // destroy analyzer node
    analyzer_node?.disconnect();

    // stop audio context
    audio_context?.close();

    audio_info = null;
    audio_context = null;
    analyzer_node = null;
    mic_stream = null;
    pitch_history = []; // Clear pitch history
  };

  onMount(() => {
    clearInterval(update_interval!);

    return () => {
      Stop();
    };
  });

  const checkAndRequestMicrophonePermission = async () => {
    // if (Capacitor.isNativePlatform()) {
    try {
      // Check current permission status
      const permissionStatus = await Microphone.checkPermissions();
      // console.log('Current microphone permission:', permissionStatus.microphone);

      if (permissionStatus.microphone === 'granted') {
        return true;
      } else if (permissionStatus.microphone === 'denied') {
        // Permission was denied, show message to user
        alert(
          'Microphone permission was denied. Please enable it in your device settings to use the pitch tuner.'
        );
        return false;
      } else {
        // Permission not yet requested or prompt
        const requestResult = await Microphone.requestPermissions();
        console.log('Permission request result:', requestResult.microphone);
        return requestResult.microphone === 'granted';
      }
    } catch (error) {
      console.error('Error checking/requesting microphone permission:', error);
      return false;
    }
  };

  const Start = async () => {
    try {
      if (input_mode === 'mic') {
        // Microphone input mode
        const hasPermission = await checkAndRequestMicrophonePermission();
        if (!hasPermission) {
          console.error('Microphone permission not granted');
          return;
        }
        console.log(
          'Selected Microphone: ',
          audio_devices.find((device, i) => device.deviceId === selected_device)?.label ??
            selected_device
        );

        // start audio context
        audio_context = new AudioContext();
        // create analyzer node
        analyzer_node = audio_context.createAnalyser();

        // connect analyzer node to audio context destination
        const constraints: MediaStreamConstraints = {
          audio: selected_device ? { deviceId: { ideal: selected_device } } : true
        };

        let stream: MediaStream;
        try {
          stream = await navigator.mediaDevices.getUserMedia(constraints);
        } catch (err) {
          console.warn("Couldn't open selected device, falling back to default", err);
          stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        }
        get_audio_devices(false); // refresh list
        if (!audio_context) return;
        if (!analyzer_node) return;
        if (!stream) return;
        mic_stream = stream;

        analyzer_node.fftSize = FFT_SIZE;
        audio_context.createMediaStreamSource(stream).connect(analyzer_node);
      } else if (input_mode === 'file') {
        // File input mode
        if (!file_audio_element || !input_file) {
          console.error('No audio file selected');
          return;
        }

        // start audio context
        audio_context = new AudioContext();
        // create analyzer node
        analyzer_node = audio_context.createAnalyser();
        analyzer_node.fftSize = FFT_SIZE;

        // Create media element source
        const source = audio_context.createMediaElementSource(file_audio_element);
        source.connect(analyzer_node);
        source.connect(audio_context.destination); // So we can hear the audio
      }

      const detector = PitchDetector.forFloat32Array(analyzer_node!.fftSize);
      const input = new Float32Array(detector.inputLength);

      clearInterval(update_interval!);
      pitch_history = [];

      function updateAudioInfo() {
        // For file mode, only analyze when audio is playing
        if (input_mode === 'file' && !file_is_playing) {
          audio_info = { pitch: 0, clarity: 0, note: '', scale: 0, detune: NaN };
          return;
        }

        analyzer_node?.getFloatTimeDomainData(input);
        const [pitch, clarity] = detector.findPitch(input, audio_context!.sampleRate);

        const rawNoteNumber = getNoteNumberFromPitch(pitch);
        const noteName = NOTES[rawNoteNumber % 12];

        const currentAudioInfo = {
          pitch: Math.round(pitch * 10) / 10,
          clarity: Math.round(clarity * 100),
          note: noteName,
          scale: getScaleFromNoteNumber(rawNoteNumber),
          detune: getDetuneFromPitch(pitch, rawNoteNumber)
        };

        audio_info = currentAudioInfo;
        // console.log('audio_info', audio_info);

        // Add to pitch history for time graph
        const currentTime = Date.now();
        pitch_history.push({
          time: currentTime,
          pitch: currentAudioInfo.pitch,
          note: currentAudioInfo.note,
          clarity: currentAudioInfo.clarity,
          scale: currentAudioInfo.scale
        });

        // Keep only the last MAX_PITCH_HISTORY_POINTS entries
        if (pitch_history.length > MAX_PITCH_HISTORY_POINTS) {
          pitch_history = pitch_history.slice(-MAX_PITCH_HISTORY_POINTS);
        }
      }

      updateAudioInfo();
      update_interval = setInterval(updateAudioInfo, AUDIO_INFO_UPDATE_INTERVAL);
      started = true;
    } catch (error) {
      console.error('error in Start-->', error);
    }
  };

  const handleDeviceChange = () => {
    if (audio_info) {
      // disconnect previous mic
      mic_stream?.getTracks().forEach((track) => track.stop());
      Start(); // Restart with new device if already running
    }
  };

  // File audio event handlers
  const handleAudioReady = (elm: HTMLAudioElement) => {
    file_audio_element = elm;
    // Auto-start analysis for file mode
    if (input_mode === 'file' && !started) {
      Start();
    }
  };

  // let is_paused = $state(false);
</script>

{#if !started}
  <div
    class="mt-12 flex flex-col items-center justify-center space-y-8 sm:mt-15 md:mt-18 xl:mt-20"
    in:fade
    out:slide
  >
    {@render welcome_msg()}
    <button
      in:slide
      out:slide
      class="group relative overflow-hidden rounded-2xl bg-linear-to-r from-blue-500 via-purple-500 to-indigo-600
             px-8 py-4 text-xl font-bold text-white shadow-xl
             transition-all duration-300 ease-out
             hover:scale-105 hover:from-blue-600
             hover:via-purple-600 hover:to-indigo-700 hover:shadow-2xl active:scale-95
             "
      onclick={Start}
    >
      <!-- {input_mode === 'file' && !input_file ? 'cursor-not-allowed opacity-50' : ''} -->
      <!-- disabled={input_mode === 'file' && !input_file} -->
      <div
        class="absolute inset-0 -translate-x-full bg-linear-to-r from-white/0 via-white/20 to-white/0 transition-transform duration-700 ease-out group-hover:translate-x-full"
      ></div>
      <div class="relative flex items-center gap-3">
        <Icon
          src={FiPlay}
          class="-mt-1 text-2xl transition-transform duration-200 group-hover:scale-110"
        />
        <span>Start</span>
      </div>
    </button>
  </div>
{/if}
{#snippet stop_button()}
  <button
    class="btn gap-1 rounded-lg bg-error-600 px-2 py-1 text-xl font-bold text-white dark:bg-error-500"
    onclick={Stop}
  >
    <Icon src={BiStopCircle} class="-mt-1 text-2xl" />
    Stop
  </button>
{/snippet}

{#if audio_info && started}
  <Tabs
    value={selected_pitch_display_type}
    onValueChange={(e) =>
      (selected_pitch_display_type = e.value as 'circular_scale' | 'time_graph')}
    listJustify="justify-center"
  >
    {#snippet list()}
      <Tabs.Control value="circular_scale">Circular Scale</Tabs.Control>
      <Tabs.Control value="time_graph">Time Graph</Tabs.Control>
    {/snippet}
    {#snippet content()}
      <Tabs.Panel value="circular_scale">
        <CircularScale
          audio_info={audio_info!}
          bind:selected_Sa_at
          bind:selected_sargam_orientation
          bind:selected_note_orientation
          {stop_button}
        />
        <!-- bind:is_paused -->
      </Tabs.Panel>
      <Tabs.Panel value="time_graph">
        <PitchTimeGraph
          {pitch_history}
          {stop_button}
          {MAX_PITCH_HISTORY_POINTS}
          {input_mode}
          bind:selected_Sa_at={selected_timegraph_Sa_at}
          bind:bottom_start_note={selected_timegraph_bottom_start_note}
        />
        <!-- bind:is_paused -->
      </Tabs.Panel>
    {/snippet}
  </Tabs>
{/if}
<Tabs
  value={input_mode}
  onValueChange={(e) => {
    if (started && input_mode !== e.value) {
      Stop(); // Stop current analysis when switching modes
    }
    input_mode = e.value as typeof input_mode;
  }}
  listJustify="justify-center"
  classes="mt-4"
>
  {#snippet list()}
    <Tabs.Control value="mic"><Icon src={BiMicrophone} class="-mt-1 size-6" />Mic</Tabs.Control>
    <Tabs.Control value="file"><Icon src={FiMusic} class="-mt-1 mr-1 size-5" />File</Tabs.Control>
  {/snippet}
  {#snippet content()}
    <Tabs.Panel value="mic">
      <div class="flex items-center justify-center">
        <label class="flex space-x-1">
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
      </div>
    </Tabs.Panel>
    <Tabs.Panel value="file">
      <AudioInputFile
        bind:audio_file={input_file}
        bind:is_playing={file_is_playing}
        bind:current_time={file_current_time}
        bind:duration={file_duration}
        on_audio_ready={handleAudioReady}
        handle_stop={Stop}
      />
    </Tabs.Panel>
  {/snippet}
</Tabs>
