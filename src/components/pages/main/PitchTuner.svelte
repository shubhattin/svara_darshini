<script lang="ts">
  import { type note_types } from './constants';
  import { onMount, type Snippet } from 'svelte';
  import { FiMusic, FiPlay, FiRefreshCcw, FiSettings } from 'svelte-icons-pack/fi';
  import Icon from '~/tools/Icon.svelte';
  import { BiMicrophone, BiStopCircle } from 'svelte-icons-pack/bi';
  import { fade, slide } from 'svelte/transition';
  import { BsMic } from 'svelte-icons-pack/bs';
  import { delay } from '~/tools/delay';
  import { cl_join } from '~/tools/cl_join';
  import { indactivity_timeout } from './inactivity';
  import ms from 'ms';
  import { Microphone } from '@mozartec/capacitor-microphone';
  import { Popover, Switch, Tabs } from '@skeletonlabs/skeleton-svelte';
  import CircularScale from './circular/CircularScale.svelte';
  import PitchTimeGraph from './time_graph/PitchTimeGraph.svelte';
  import AudioInputFile from './AudioInputFile.svelte';
  import type { AudioInfo, PitchDetector } from '~/tools/pitch/types';
  import { EMPTY_AUDIO_INFO } from '~/tools/pitch/types';
  import { FftPitchDetector } from '~/tools/pitch/fft';
  import { CqtPitchDetector } from '~/tools/pitch/cqt';

  let {
    selected_device = $bindable(),
    selected_Sa_at = $bindable(),
    selected_sargam_orientation = $bindable(),
    selected_note_orientation = $bindable(),
    selected_pitch_display_type = $bindable(),
    selected_timegraph_Sa_at = $bindable(),
    selected_timegraph_bottom_start_note = $bindable(),
    show_jumps = $bindable(),
    welcome_msg
  }: {
    selected_device: string;
    selected_Sa_at: note_types;
    selected_sargam_orientation: 'radial' | 'vertical';
    selected_note_orientation: 'radial' | 'vertical';
    selected_pitch_display_type: 'circular_scale' | 'time_graph';
    selected_timegraph_Sa_at: note_types;
    selected_timegraph_bottom_start_note: note_types;
    show_jumps: boolean;
    welcome_msg: Snippet;
  } = $props();

  let detection_method: 'cqt' | 'fft' = $state('cqt');
  let analysis_settings_popup_open = $state(false);

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
  let startToken = 0;

  // These constants control how responsive the graphing/detection feels.
  const AUDIO_INFO_UPDATE_INTERVAL = $derived(detection_method === 'cqt' ? 120 : 80);
  const GRAPH_TOTAL_TIME_MS = 8000;
  let enable_pitch_filtering = $state(false);
  // Gentle high-pass cutoff that removes handling noise, breath pops,
  // and low-frequency rumble without trimming normal voice/tanpura fundamentals.
  const PITCH_INPUT_HIGHPASS_HZ = 70;
  // Gentle low-pass cutoff that reduces upper-band hiss while keeping
  // enough harmonic content for stable pitch detection.
  const PITCH_INPUT_LOWPASS_HZ = 4000;

  // Pitch history for time graph
  const MAX_PITCH_HISTORY_POINTS = $derived(
    Math.floor(GRAPH_TOTAL_TIME_MS / AUDIO_INFO_UPDATE_INTERVAL)
  ); // 100 points

  let started = $state(false);
  let current_audio_info = $state<AudioInfo | null>(null);

  let pitch_history = $state<
    Array<{
      // time: number;
      pitch: number;
      note: string;
      // clarity: number;
      scale: number;
    }>
  >([]);
  let detector: PitchDetector | null = null;
  let is_detector_loading = $state(false);
  const display_audio_info = $derived(
    is_detector_loading ? EMPTY_AUDIO_INFO : (current_audio_info ?? EMPTY_AUDIO_INFO)
  );
  const display_pitch_history = $derived(is_detector_loading ? [] : pitch_history);

  // Seamlessly restart detection when the algorithm is switched mid-session.
  // We pass silent=true / keep_started=true so the display stays mounted
  // and no fade transition fires — only the pitch history clears.
  $effect(() => {
    const _method = detection_method; // track reactively

    return () => {
      if (started) {
        Stop(true); // tear down pipeline, keep started=true
        Start(true); // rebuild with new method, skip setting started=true
      }
    };
  });

  const buildAudioConstraints = (deviceId: string): MediaTrackConstraints | true => {
    if (!deviceId) return true;

    const supported = navigator.mediaDevices.getSupportedConstraints();
    const constraints: MediaTrackConstraints = {
      deviceId: { exact: deviceId }
    };

    // Prefer raw capture for pitch analysis so browser voice processing does not suppress mixed audio.
    if (supported.echoCancellation) constraints.echoCancellation = false;
    if (supported.noiseSuppression) constraints.noiseSuppression = false;
    if (supported.autoGainControl) constraints.autoGainControl = false;
    if (supported.channelCount) constraints.channelCount = { ideal: 2 };

    return constraints;
  };

  const logAudioTrackDebugInfo = (stream: MediaStream, requestedDeviceId: string) => {
    const track = stream.getAudioTracks()[0];
    if (!track) {
      console.warn('[PitchTuner] No audio track found on acquired stream');
      return;
    }

    const settings = track.getSettings();
    const constraints = track.getConstraints();
    const selectedDevice = audio_devices.find((device) => device.deviceId === requestedDeviceId);

    console.groupCollapsed('[PitchTuner] Audio capture debug');
    console.log('Requested deviceId:', requestedDeviceId);
    console.log('Requested device label:', selectedDevice?.label ?? '(unknown)');
    console.log('Actual track label:', track.label);
    console.log('Track settings:', settings);
    console.log('Track constraints:', constraints);

    if (settings.deviceId && requestedDeviceId && settings.deviceId !== requestedDeviceId) {
      console.warn(
        '[PitchTuner] Browser opened a different audio device than requested',
        settings.deviceId
      );
    }

    console.groupEnd();
  };

  const setEmptyAudioInfo = () => {
    current_audio_info = { ...EMPTY_AUDIO_INFO };
  };

  const connectPitchAnalysisInput = ({
    audioContext,
    source,
    analyzer
  }: {
    audioContext: AudioContext;
    source: AudioNode;
    analyzer: AnalyserNode;
  }) => {
    if (!enable_pitch_filtering) {
      source.connect(analyzer);
      return;
    }

    // Keep the filter chain gentle so we remove rumble and hiss
    // without flattening harmonics that help pitch detection.
    const highPass = audioContext.createBiquadFilter();
    highPass.type = 'highpass';
    highPass.frequency.value = PITCH_INPUT_HIGHPASS_HZ;

    const lowPass = audioContext.createBiquadFilter();
    lowPass.type = 'lowpass';
    lowPass.frequency.value = PITCH_INPUT_LOWPASS_HZ;

    source.connect(highPass);
    highPass.connect(lowPass);
    lowPass.connect(analyzer);
  };

  const cleanupPendingStart = async ({
    nextAudioContext,
    nextAnalyzerNode,
    nextMicStream,
    nextDetector,
    nextFileSource
  }: {
    nextAudioContext: AudioContext | null;
    nextAnalyzerNode: AnalyserNode | null;
    nextMicStream: MediaStream | null;
    nextDetector: PitchDetector | null;
    nextFileSource: MediaElementAudioSourceNode | null;
  }) => {
    nextFileSource?.disconnect();
    nextAnalyzerNode?.disconnect();
    nextDetector?.destroy();
    nextMicStream?.getTracks().forEach((track) => track.stop());

    if (nextAudioContext && nextAudioContext.state !== 'closed') {
      try {
        await nextAudioContext.close();
      } catch (error) {
        console.warn('[PitchTuner] Failed to close stale audio context', error);
      }
    }
  };

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

  /**
   * @param silent - if true, keeps `started` as-is so the display stays mounted
   *                 (used when restarting mid-session without the close/open transition)
   */
  const Stop = (silent = false) => {
    startToken++;
    if (!silent) started = false;
    //clear interval
    clearInterval(update_interval!);
    update_interval = null;

    // stop mic stream
    mic_stream?.getTracks().forEach((track) => track.stop());

    // stop file audio if playing
    if (input_mode === 'file' && file_audio_element) {
      file_audio_element.pause();
      file_is_playing = false;
    }

    // destroy analyzer node
    analyzer_node?.disconnect();
    detector?.destroy();
    detector = null;
    is_detector_loading = false;

    // stop audio context
    audio_context?.close();

    current_audio_info = null;
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

  /**
   * @param keep_started - if true, skips setting `started = true` (caller guarantees it's already true)
   *                       used for seamless algorithm hot-swap without the fade-in transition
   */
  const Start = async (keep_started = false) => {
    const token = ++startToken;
    let nextAudioContext: AudioContext | null = null;
    let nextAnalyzerNode: AnalyserNode | null = null;
    let nextMicStream: MediaStream | null = null;
    let nextDetector: PitchDetector | null = null;
    let nextFileSource: MediaElementAudioSourceNode | null = null;

    try {
      if (input_mode === 'mic') {
        // Microphone input mode
        const hasPermission = await checkAndRequestMicrophonePermission();
        if (!hasPermission) {
          console.error('Microphone permission not granted');
          return;
        }
        if (token !== startToken) return;
        console.log(
          'Selected Microphone: ',
          audio_devices.find((device, i) => device.deviceId === selected_device)?.label ??
            selected_device
        );

        // start audio context
        nextAudioContext = new AudioContext();
        // create analyzer node
        nextAnalyzerNode = nextAudioContext.createAnalyser();

        const constraints: MediaStreamConstraints = {
          audio: buildAudioConstraints(selected_device)
        };

        let stream: MediaStream;
        try {
          stream = await navigator.mediaDevices.getUserMedia(constraints);
        } catch (err) {
          console.warn(
            '[PitchTuner] Failed to open selected input device. Analysis will not start.',
            {
              selected_device,
              selected_label:
                audio_devices.find((device) => device.deviceId === selected_device)?.label ??
                '(unknown)',
              error: err
            }
          );
          await cleanupPendingStart({
            nextAudioContext,
            nextAnalyzerNode,
            nextMicStream,
            nextDetector,
            nextFileSource
          });
          return;
        }
        if (token !== startToken) {
          nextMicStream = stream;
          await cleanupPendingStart({
            nextAudioContext,
            nextAnalyzerNode,
            nextMicStream,
            nextDetector,
            nextFileSource
          });
          return;
        }
        get_audio_devices(false); // refresh list
        if (!nextAudioContext) return;
        if (!nextAnalyzerNode) return;
        if (!stream) return;
        nextMicStream = stream;

        logAudioTrackDebugInfo(stream, selected_device);
        const nextMicSource = nextAudioContext.createMediaStreamSource(stream);
        connectPitchAnalysisInput({
          audioContext: nextAudioContext,
          source: nextMicSource,
          analyzer: nextAnalyzerNode
        });
      } else if (input_mode === 'file') {
        // File input mode
        if (!file_audio_element || !input_file) {
          console.error('No audio file selected');
          return;
        }

        // start audio context
        nextAudioContext = new AudioContext();
        // create analyzer node
        nextAnalyzerNode = nextAudioContext.createAnalyser();

        // Create media element source
        nextFileSource = nextAudioContext.createMediaElementSource(file_audio_element);
        connectPitchAnalysisInput({
          audioContext: nextAudioContext,
          source: nextFileSource,
          analyzer: nextAnalyzerNode
        });
        nextFileSource.connect(nextAudioContext.destination); // So we can hear the audio
      }

      if (token !== startToken) {
        await cleanupPendingStart({
          nextAudioContext,
          nextAnalyzerNode,
          nextMicStream,
          nextDetector,
          nextFileSource
        });
        return;
      }

      clearInterval(update_interval!);
      pitch_history = [];
      setEmptyAudioInfo();
      if (!keep_started) started = true;

      if (!nextAnalyzerNode || !nextAudioContext) {
        throw new Error('Audio analyser could not be created.');
      }

      is_detector_loading = true;
      nextDetector = detection_method === 'cqt' ? new CqtPitchDetector() : new FftPitchDetector();

      try {
        await nextDetector.init(nextAnalyzerNode, nextAudioContext);
      } catch (error) {
        is_detector_loading = false;
        throw error;
      }

      if (token !== startToken || !started) {
        await cleanupPendingStart({
          nextAudioContext,
          nextAnalyzerNode,
          nextMicStream,
          nextDetector,
          nextFileSource
        });
        return;
      }

      audio_context = nextAudioContext;
      analyzer_node = nextAnalyzerNode;
      mic_stream = nextMicStream;
      detector = nextDetector;
      is_detector_loading = false;

      function updateAudioInfo() {
        if (token !== startToken) {
          return;
        }
        // For file mode, only analyze when audio is playing
        if (input_mode === 'file' && !file_is_playing) {
          setEmptyAudioInfo();
          return;
        }

        if (!nextAnalyzerNode || !nextAudioContext || !nextDetector?.ready) {
          setEmptyAudioInfo();
          return;
        }

        const currentAudioInfo = nextDetector.detect(nextAnalyzerNode, nextAudioContext);

        if (!currentAudioInfo) {
          setEmptyAudioInfo();
          return;
        }

        current_audio_info = currentAudioInfo;

        // Add to pitch history for time graph
        pitch_history = [
          ...pitch_history,
          {
            pitch: currentAudioInfo.pitch,
            note: currentAudioInfo.note,
            scale: currentAudioInfo.scale
          }
        ];

        // Keep only the last MAX_PITCH_HISTORY_POINTS entries
        if (pitch_history.length > MAX_PITCH_HISTORY_POINTS) {
          pitch_history = pitch_history.slice(-MAX_PITCH_HISTORY_POINTS);
        }
      }

      updateAudioInfo();
      update_interval = setInterval(updateAudioInfo, AUDIO_INFO_UPDATE_INTERVAL);
    } catch (error) {
      console.error('error in Start-->', error);
      if (token === startToken) {
        Stop();
      } else {
        await cleanupPendingStart({
          nextAudioContext,
          nextAnalyzerNode,
          nextMicStream,
          nextDetector,
          nextFileSource
        });
      }
    }
  };

  const handleDeviceChange = () => {
    if (started && input_mode === 'mic') {
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
    class="mt-2 flex flex-col items-center justify-center space-y-4 sm:mt-6 md:mt-8"
    in:fade
    out:slide
  >
    {@render welcome_msg()}
    <button
      in:slide
      out:slide
      class="group relative overflow-hidden rounded-xl bg-linear-to-r from-amber-500 via-orange-500 to-yellow-600
             px-4 py-2.5 text-base font-bold text-white shadow-xl
             transition-all duration-300 ease-out
             hover:scale-105 hover:from-amber-600
             hover:via-orange-600 hover:to-yellow-700 hover:shadow-2xl active:scale-95
             sm:rounded-2xl sm:px-8 sm:py-4 sm:text-xl
             dark:from-amber-600 dark:via-orange-600 dark:to-yellow-700
             dark:hover:from-amber-700 dark:hover:via-orange-700 dark:hover:to-yellow-800
             "
      onclick={() => Start()}
    >
      <!-- {input_mode === 'file' && !input_file ? 'cursor-not-allowed opacity-50' : ''} -->
      <!-- disabled={input_mode === 'file' && !input_file} -->
      <div
        class="absolute inset-0 -translate-x-full bg-linear-to-r from-white/0 via-white/20 to-white/0 transition-transform duration-700 ease-out group-hover:translate-x-full"
      ></div>
      <div class="relative flex items-center gap-1.5 sm:gap-3">
        <Icon
          src={FiPlay}
          class="-mt-0.5 text-lg transition-transform duration-200 group-hover:scale-110 sm:-mt-1 sm:text-2xl"
        />
        <span>Start</span>
      </div>
    </button>
  </div>
{/if}
{#snippet stop_button()}
  <button
    class="btn gap-0.5 rounded-md bg-error-600 px-1.5 py-0.5 text-base font-bold text-white sm:gap-1 sm:rounded-lg sm:px-2 sm:py-1 sm:text-xl dark:bg-error-500"
    onclick={() => Stop()}
  >
    <Icon src={BiStopCircle} class="-mt-0.5 text-xl sm:-mt-1 sm:text-2xl" />
    Stop
  </button>
{/snippet}

{#if started}
  <Tabs
    value={selected_pitch_display_type}
    onValueChange={(e) =>
      (selected_pitch_display_type = e.value as 'circular_scale' | 'time_graph')}
    listJustify="justify-center"
  >
    {#snippet list()}
      <Tabs.Control value="circular_scale">Vṛtta</Tabs.Control>
      <Tabs.Control value="time_graph">Rēkhā</Tabs.Control>
    {/snippet}
    {#snippet content()}
      <Tabs.Panel value="circular_scale">
        <CircularScale
          audio_info={display_audio_info}
          bind:selected_Sa_at
          bind:selected_sargam_orientation
          bind:selected_note_orientation
          {stop_button}
        />
        <!-- bind:is_paused -->
      </Tabs.Panel>
      <Tabs.Panel value="time_graph">
        <PitchTimeGraph
          pitch_history={display_pitch_history}
          {stop_button}
          {show_jumps}
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
{#if started}
  <div class="mt-4 flex items-center justify-center">
    <Popover
      contentBase="card z-50 space-y-2 p-2 rounded-lg shadow-xl dark:bg-surface-900 bg-slate-100"
      open={analysis_settings_popup_open}
      onOpenChange={(e) => (analysis_settings_popup_open = e.open)}
    >
      {#snippet trigger()}
        <div class="flex items-center justify-center gap-1.5 text-center font-bold outline-hidden">
          <span class="text-sm">Settings</span>
          <Icon
            src={FiSettings}
            class={cl_join(
              'size-4 transition-transform duration-200 ease-out',
              analysis_settings_popup_open ? 'rotate-90' : 'rotate-0'
            )}
          />
        </div>
      {/snippet}
      {#snippet content()}
        <div class="space-x-1">
          <span class="text-sm font-semibold">Algorithm</span>
          <label>
            <input type="radio" bind:group={detection_method} value="cqt" />
            <span class="text-sm">CQT</span>
          </label>
          <label>
            <input type="radio" bind:group={detection_method} value="fft" />
            <span class="text-sm">FFT</span>
          </label>
        </div>
        {#if selected_pitch_display_type === 'time_graph'}
          <div class="space-x-1">
            <span class="text-sm font-semibold">Jumps</span>
            <label>
              <input
                type="radio"
                name="show_jumps"
                checked={show_jumps}
                onchange={() => (show_jumps = true)}
              />
              <span class="text-sm">Show</span>
            </label>
            <label>
              <input
                type="radio"
                name="show_jumps"
                checked={!show_jumps}
                onchange={() => (show_jumps = false)}
              />
              <span class="text-sm">Hide</span>
            </label>
          </div>
        {/if}
        <!-- <label class="flex flex-wrap items-center gap-x-2 gap-y-1">
          <span class="text-xs font-semibold">Simple Pitch Filtering</span>
          <Switch
            checked={enable_pitch_filtering}
            onCheckedChange={(e) => (enable_pitch_filtering = e.checked)}
          />
        </label> -->
      {/snippet}
    </Popover>
  </div>
{/if}
