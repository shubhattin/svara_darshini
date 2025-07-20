<script lang="ts">
  import Icon from '~/tools/Icon.svelte';
  import { FiUploadCloud, FiPlay, FiPause, FiX } from 'svelte-icons-pack/fi';
  import { BiMusic } from 'svelte-icons-pack/bi';
  import { fade, slide } from 'svelte/transition';

  let {
    audio_file = $bindable(),
    is_playing = $bindable(false),
    current_time = $bindable(0),
    duration = $bindable(0),
    on_audio_ready,
    handle_stop
  }: {
    audio_file: File | null;
    is_playing: boolean;
    current_time: number;
    duration: number;
    on_audio_ready: (audio: HTMLAudioElement) => void;
    handle_stop: () => void;
  } = $props();

  let audio_element: HTMLAudioElement | null = $state(null);
  let file_input: HTMLInputElement | null = $state(null);
  let is_dragging = $state(false);
  let file_url = $state<string | null>(null);

  const handleFileSelect = (file: File) => {
    if (!file.type.startsWith('audio/')) {
      alert('Please select an audio file');
      return;
    }

    if (file_url) {
      URL.revokeObjectURL(file_url);
    }

    audio_file = file;
    file_url = URL.createObjectURL(file);
    is_playing = false;
    current_time = 0;
  };

  const handleDrop = (e: DragEvent) => {
    e.preventDefault();
    is_dragging = false;

    const files = e.dataTransfer?.files;
    if (files && files.length > 0) {
      handleFileSelect(files[0]);
    }
  };

  const handleDragOver = (e: DragEvent) => {
    e.preventDefault();
    is_dragging = true;
  };

  const handleDragLeave = (e: DragEvent) => {
    e.preventDefault();
    // Only set dragging to false if we're leaving the drop zone completely
    if (!(e.currentTarget as Element)?.contains(e.relatedTarget as Node)) {
      is_dragging = false;
    }
  };

  const handleFileInput = (e: Event) => {
    const target = e.target as HTMLInputElement;
    const files = target.files;
    if (files && files.length > 0) {
      handleFileSelect(files[0]);
    }
  };

  const clearFile = () => {
    if (file_url) {
      URL.revokeObjectURL(file_url);
    }
    audio_file = null;
    file_url = null;
    is_playing = false;
    current_time = 0;
    duration = 0;
    if (audio_element) {
      audio_element.pause();
      audio_element.currentTime = 0;
    }
    handle_stop();
  };

  const togglePlayPause = () => {
    if (!audio_element) return;

    if (is_playing) {
      audio_element.pause();
      is_playing = false;
    } else {
      audio_element.play();
      is_playing = true;
    }
    is_playing = !is_playing;
  };

  const handleSeek = (e: Event) => {
    const target = e.target as HTMLInputElement;
    if (audio_element) {
      const time = (parseFloat(target.value) / 100) * duration;
      audio_element.currentTime = time;
      current_time = time;
    }
  };

  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  // Audio element event handlers
  $effect(() => {
    if (audio_element && file_url) {
      const handleLoadedMetadata = () => {
        duration = audio_element!.duration;
        on_audio_ready(audio_element!);
      };

      const handleTimeUpdate = () => {
        current_time = audio_element!.currentTime;
      };

      const handleEnded = () => {
        is_playing = false;
        current_time = 0;
        audio_element!.currentTime = 0;
      };

      audio_element.addEventListener('loadedmetadata', handleLoadedMetadata);
      audio_element.addEventListener('timeupdate', handleTimeUpdate);
      audio_element.addEventListener('ended', handleEnded);
      audio_element.addEventListener('play', () => (is_playing = true));
      audio_element.addEventListener('pause', () => (is_playing = false));

      return () => {
        audio_element?.removeEventListener('loadedmetadata', handleLoadedMetadata);
        audio_element?.removeEventListener('timeupdate', handleTimeUpdate);
        audio_element?.removeEventListener('ended', handleEnded);
      };
    }
  });
</script>

<div class="flex flex-col items-center space-y-1 p-1">
  {#if !audio_file}
    <!-- File Drop Zone -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="relative w-full max-w-md rounded-xl border-1 border-dashed border-surface-300 bg-surface-50 p-1 text-center transition-all duration-200 hover:border-primary-400 hover:bg-surface-100 lg:p-4 dark:border-surface-600 dark:bg-surface-800 dark:hover:border-primary-400 dark:hover:bg-surface-700
             {is_dragging ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20' : ''}"
      ondrop={handleDrop}
      ondragover={handleDragOver}
      ondragleave={handleDragLeave}
      in:fade
    >
      <div class="space-y-0.5">
        <div
          class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-primary-100 dark:bg-primary-900/30"
        >
          <Icon
            src={is_dragging ? BiMusic : FiUploadCloud}
            class="size-5 text-primary-600 dark:text-primary-400"
          />
        </div>

        <div class="space-y-2">
          <h3 class="text-sm font-semibold text-surface-900 dark:text-surface-100">
            {is_dragging ? 'Drop your audio file here' : 'Upload Audio File'}
          </h3>
          <p class="text-xs text-surface-600 dark:text-surface-400">
            {is_dragging ? 'Release to upload' : 'Drag and drop or click to browse'}
          </p>
        </div>

        <button
          class="variant-filled-primary mx-auto btn"
          onclick={() => file_input && file_input.click()}
        >
          <Icon src={FiUploadCloud} class="mr-2" />
          Choose File
        </button>
      </div>

      <input
        bind:this={file_input}
        type="file"
        accept="audio/*"
        class="hidden"
        onchange={handleFileInput}
      />
    </div>
  {:else}
    <!-- Audio Player -->
    <div
      class="w-full max-w-sm rounded-lg bg-surface-100 px-4 py-1.5 shadow-md dark:bg-surface-700"
      in:slide
      out:fade
    >
      <!-- Header with file name and close button -->
      <div class="flex items-center justify-between">
        <div class="flex min-w-0 flex-1 items-center space-x-2">
          <Icon src={BiMusic} class="flex-shrink-0 text-primary-600 dark:text-primary-400" />
          <span class="truncate text-sm font-medium text-surface-900 dark:text-surface-100">
            {audio_file.name}
          </span>
        </div>
        <button class="ml-2 btn-icon btn-icon-sm" onclick={clearFile} title="Remove file">
          <Icon src={FiX} class="text-lg" />
        </button>
      </div>

      <!-- Audio element -->
      {#if file_url}
        <audio bind:this={audio_element} src={file_url} preload="metadata"></audio>
      {/if}

      <!-- Controls -->
      <div class="space-y-1">
        <!-- Progress bar and time -->
        {#if duration > 0}
          <div class="flex items-center justify-center">
            <button class="btn-icon btn-icon-lg" onclick={togglePlayPause} disabled={!duration}>
              <Icon src={is_playing ? FiPause : FiPlay} class="text-xl" />
            </button>
            <input
              type="range"
              min="0"
              max="100"
              value={(current_time / duration) * 100}
              class="range w-full"
              oninput={handleSeek}
            />
            <!-- <div class="flex justify-between text-xs text-surface-600 dark:text-surface-400">
              <span>{formatTime(current_time)}</span>
              <span>{formatTime(duration)}</span>
            </div> -->
          </div>
        {/if}
      </div>
    </div>
  {/if}
</div>
