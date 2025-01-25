<script lang="ts">
  import type { note_types } from '~/components/pages/main/constants';
  import PitchTuner from '~/components/pages/main/PitchTuner.svelte';
  import { persistedStore } from '~/tools/persisted_store';

  let default_selected_device = persistedStore('prev_selected_device', 'default');
  let default_Sa_at = persistedStore<note_types>('prev_Sa_at', 'C');
</script>

<svelte:head>
  <title>Pitch Tuner</title>
</svelte:head>

<PitchTuner bind:selected_device={$default_selected_device} bind:selected_Sa_at={$default_Sa_at} />
