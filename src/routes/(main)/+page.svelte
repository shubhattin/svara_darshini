<script lang="ts">
  import type { note_types } from '~/components/pages/main/constants';
  import PitchTuner from '~/components/pages/main/PitchTuner.svelte';
  import CircularPitchDisplay from '~/components/pages/main/circular/CircularPitchDisplay.svelte';
  import MetaTags from '~/components/tags/MetaTags.svelte';
  import { persistedStore } from '~/tools/persisted_store';
  import { onMount } from 'svelte';
  import { NOTES_STARTING_WITH_C } from '~/components/pages/main/constants';

  let default_selected_device = persistedStore('prev_selected_device', 'default');
  let default_Sa_at = persistedStore<note_types>('prev_Sa_at', 'C');
  let default_sargam_orientation = persistedStore<'vertical' | 'radial'>(
    'saved_sargam_orientation',
    'vertical'
  );
  let default_note_orientation = persistedStore<'vertical' | 'radial'>(
    'saved_note_orientation',
    'vertical'
  );
  let default_pitch_display_type = persistedStore<'circular_scale' | 'time_graph'>(
    'saved_pitch_display_type',
    'circular_scale'
  );
  let default_timegraph_Sa_at = persistedStore<note_types>('prev_timegraph_Sa_at', 'C');
  let default_timegraph_bottom_start_note = persistedStore<note_types>(
    'prev_timegraph_bottom_start_note',
    'C'
  );

  // Demo animation state for the circular display
  let demo_pitch = $state(108);
  let demo_direction = $state(1); // 1 for increasing, -1 for decreasing
  const MIN_PITCH = 108; // A2
  const MAX_PITCH = 220; // A3

  // Helper functions from constants (imported inline for demo calculation)
  const getNoteNumberFromPitch = (frequency: number) => {
    const noteNum = 12 * (Math.log(frequency / 440) / Math.log(2));
    return Math.round(noteNum) + 69;
  };

  const getNoteFrequency = (note: number) => {
    return 440 * Math.pow(2, (note - 69) / 12);
  };

  const getDetuneFromPitch = (pitch: number, noteNumber: number) => {
    return Math.floor((1200 * Math.log(pitch / getNoteFrequency(noteNumber))) / Math.log(2));
  };

  const getScaleFromNoteNumber = (noteNumber: number) => {
    return Math.floor(noteNumber / 12) - 1;
  };

  // Calculate demo audio info based on current pitch
  let demo_audio_info = $derived.by(() => {
    const noteNumber = getNoteNumberFromPitch(demo_pitch);
    const noteName = NOTES_STARTING_WITH_C[noteNumber % 12];
    const scale = getScaleFromNoteNumber(noteNumber);
    const detune = getDetuneFromPitch(demo_pitch, noteNumber);

    // Simulate varying clarity (higher when closer to the note center)
    const clarity = Math.max(60, 95 - Math.abs(detune) / 2);

    return {
      pitch: Math.round(demo_pitch * 10) / 10,
      note: noteName,
      scale,
      detune,
      clarity
    };
  });

  onMount(() => {
    // Animate the pitch smoothly with random variations
    const interval = setInterval(() => {
      // Add subtle random variation to make it feel natural (±0.15 Hz)
      const randomError = (Math.random() - 0.5) * 0.3;

      // Increment pitch with minimal variance in speed
      const speed = 0.9 + Math.random() * 0.2; // Between 0.9 and 1.1 Hz per frame
      demo_pitch += demo_direction * speed + randomError;

      // Reverse direction at boundaries
      if (demo_pitch >= MAX_PITCH) {
        demo_pitch = MAX_PITCH;
        demo_direction = -1;
      } else if (demo_pitch <= MIN_PITCH) {
        demo_pitch = MIN_PITCH;
        demo_direction = 1;
      }
    }, 80); // ~12-13 fps for smooth but visible animation

    return () => clearInterval(interval);
  });
</script>

<MetaTags
  title="Svara Darshini"
  description="Svara Darshini(Interactive Music Pitch Tuner & Note Analyzer) is an intuitive tool to understand Principles of Music that are common across the world."
/>

<div class="flex h-full w-full flex-col items-center pt-2 pb-10">
  <PitchTuner
    bind:selected_device={$default_selected_device}
    bind:selected_Sa_at={$default_Sa_at}
    bind:selected_sargam_orientation={$default_sargam_orientation}
    bind:selected_note_orientation={$default_note_orientation}
    bind:selected_pitch_display_type={$default_pitch_display_type}
    bind:selected_timegraph_Sa_at={$default_timegraph_Sa_at}
    bind:selected_timegraph_bottom_start_note={$default_timegraph_bottom_start_note}
  >
    {#snippet welcome_msg()}
      <div class="flex flex-col items-center space-y-2 px-3 text-center sm:space-y-4 sm:px-4">
        <!-- Title with warm gradient -->
        <h1
          class="bg-linear-to-r from-amber-600 via-orange-600 to-yellow-600 bg-clip-text text-2xl font-extrabold tracking-tight text-transparent sm:text-4xl md:text-5xl"
        >
          Svara Darshini
        </h1>

        <!-- Short tagline -->
        <p
          class="max-w-xs text-xs leading-snug text-slate-700 sm:max-w-md sm:text-base sm:leading-relaxed md:max-w-lg md:text-lg dark:text-gray-300"
        >
          Visualize your pitch in real-time. Master your musical notes.
        </p>

        <!-- Demo Circular Display -->
        <div class="relative py-1 sm:py-3">
          <!-- Subtle glow effect behind the display -->
          <div
            class="absolute inset-0 -z-10 rounded-full bg-linear-to-br from-amber-500/20 via-orange-500/15 to-yellow-500/20 blur-2xl"
          ></div>

          <!-- Outer decorative ring -->
          <div class="absolute inset-0 -z-5 flex items-center justify-center">
            <div
              class="animate-spin-slow h-52 w-52 rounded-full border border-dashed border-amber-500/30 sm:h-64 sm:w-64 md:h-80 md:w-80"
            ></div>
          </div>

          <CircularPitchDisplay
            is_demo={true}
            audio_info={demo_audio_info}
            Sa_at="B"
            sargam_orientation="vertical"
            note_orientation="vertical"
          />
        </div>

        <!-- Brief instruction -->
        <p
          class="max-w-[280px] text-[0.7rem] leading-tight text-slate-600 sm:max-w-sm sm:text-sm dark:text-gray-400"
        >
          Tap <span class="font-semibold text-orange-600 dark:text-amber-400">Start</span> to analyze
          your voice or instrument
        </p>
      </div>
    {/snippet}
  </PitchTuner>
</div>

<style>
  @keyframes spin-slow {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }

  .animate-spin-slow {
    animation: spin-slow 20s linear infinite;
  }
</style>
