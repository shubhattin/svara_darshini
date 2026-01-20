<script lang="ts">
  import { Popover } from '@skeletonlabs/skeleton-svelte';
  import { BsChevronDown, BsChevronUp, BsPauseFill, BsPlayFill } from 'svelte-icons-pack/bs';
  import Icon from '~/tools/Icon.svelte';
  import { cl_join } from '~/tools/cl_join';
  import { NOTES_STARTING_WITH_A, type note_types } from '../constants';
  import CircularPitchDisplay from './CircularPitchDisplay.svelte';
  import type { Snippet } from 'svelte';

  type AudioInfo = { clarity: number; detune: number; note: string; pitch: number; scale: number };

  let {
    audio_info,
    selected_Sa_at = $bindable(),
    selected_sargam_orientation = $bindable(),
    selected_note_orientation = $bindable(),
    stop_button
    // is_paused = $bindable()
  }: {
    audio_info: AudioInfo;
    selected_Sa_at: note_types;
    selected_sargam_orientation: 'radial' | 'vertical';
    selected_note_orientation: 'radial' | 'vertical';
    stop_button: Snippet;
    // is_paused: boolean;
  } = $props();

  let is_paused = $state(false);

  let paused_audio_info = $state<AudioInfo | null>(null);
  let audio_info_display = $derived(
    is_paused && paused_audio_info ? paused_audio_info : audio_info
  );

  let { clarity, pitch } = $derived(audio_info_display);
  let Sa_at_popup_status = $state(false);
  let orientation_popup_status = $state(false);
</script>

<div class="mb-4 select-none">
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
              {#each NOTES_STARTING_WITH_A as note}
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
      <CircularPitchDisplay
        audio_info={audio_info_display!}
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
      <div class="flex items-center justify-center gap-2">
        <button
          class="btn gap-1 rounded-lg bg-primary-600 px-2 py-1 text-xl font-bold text-white dark:bg-primary-500"
          onclick={() => {
            if (!is_paused) paused_audio_info = { ...audio_info };
            is_paused = !is_paused;
          }}
        >
          <Icon src={is_paused ? BsPlayFill : BsPauseFill} class="-mt-1 text-2xl" />
          {is_paused ? 'Play' : 'Pause'}
        </button>

        {@render stop_button()}
      </div>
    </div>
  </div>
</div>
