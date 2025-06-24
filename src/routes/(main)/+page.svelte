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
</script>

<MetaTags
  title="Svara Darshini"
  description="Svara Darshini(Interactive Music Pitch Tuner & Note Analyzer) is an intuitive tool to understand Principles of Music that are common across the world. Analyze pitch, tune instruments, and explore musical relationships with our interactive circular display."
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
  />
</div>
