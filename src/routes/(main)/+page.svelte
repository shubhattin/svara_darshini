<script lang="ts">
  import type { note_types } from '~/components/pages/main/constants';
  import PitchTuner from '~/components/pages/main/PitchTuner.svelte';
  import MetaTags from '~/components/tags/MetaTags.svelte';
  import { persistedStore } from '~/tools/persisted_store';

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
</script>

<MetaTags
  title="Svara Darshini"
  description="Svara Darshini(Interactive Music Pitch Tuner & Note Analyzer) is an intuitive tool to understand Principles of Music that are common across the world."
/>

<!-- <div class="mb-6 space-y-4 text-center">
  <div class="mx-auto max-w-4xl space-y-6">
    <div class="grid grid-cols-1 gap-6 text-sm md:grid-cols-3">
      <div
        class="rounded-xl border border-blue-200/50 bg-gradient-to-br from-blue-50 to-indigo-100 p-4 dark:border-slate-600/50 dark:from-slate-800 dark:to-slate-700"
      >
        <div class="mb-2 font-semibold text-blue-600 dark:text-blue-400">
          🎵 Universal Music Theory
        </div>
        <p class="text-gray-600 dark:text-gray-300">
          Explore musical concepts that transcend cultural boundaries. From Western notes to Indian
          Sargam, understand how different musical systems connect.
        </p>
      </div>
      <div
        class="rounded-xl border border-purple-200/50 bg-gradient-to-br from-purple-50 to-pink-100 p-4 dark:border-slate-600/50 dark:from-slate-800 dark:to-slate-700"
      >
        <div class="mb-2 font-semibold text-purple-600 dark:text-purple-400">
          🎯 Precision Tuning
        </div>
        <p class="text-gray-600 dark:text-gray-300">
          Real-time pitch detection with cent-level accuracy. Perfect your intonation whether you're
          practicing vocals or tuning instruments.
        </p>
      </div>
      <div
        class="rounded-xl border border-emerald-200/50 bg-gradient-to-br from-emerald-50 to-teal-100 p-4 dark:border-slate-600/50 dark:from-slate-800 dark:to-slate-700"
      >
        <div class="mb-2 font-semibold text-emerald-600 dark:text-emerald-400">
          📊 Visual Learning
        </div>
        <p class="text-gray-600 dark:text-gray-300">
          Interactive circular display makes complex musical relationships intuitive. See how notes
          relate to each other in both Western and Indian classical systems.
        </p>
      </div>
    </div>
  </div>
</div> -->
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
      <div class="space-y-4 text-center">
        <h1
          class="bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-600 bg-clip-text text-4xl font-bold text-transparent md:text-5xl"
        >
          Svara Darshini
        </h1>
        <p
          class="mx-auto max-w-2xl text-lg leading-relaxed text-gray-600 md:text-xl dark:text-gray-300"
        >
          An intuitive tool to understand the principles of music that are common across the world.
          Discover the beauty of musical notes and their relationships through our interactive Pitch
          visualizer.
        </p>
        <p class="mx-auto max-w-xl text-base text-gray-500 dark:text-gray-400">
          Click the button below to start analyzing your voice or instrument. The circular display
          will show you exactly which note you're playing and how in-tune it is.
        </p>
      </div>
    {/snippet}
  </PitchTuner>
</div>
