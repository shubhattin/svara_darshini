<script lang="ts">
  import PitchTuner from '~/components/pages/main/PitchTuner.svelte';
  import { persistedStore } from '~/tools/persisted_store';

  let default_selected_device = persistedStore('prev_selected_device', 'default');
</script>

<svelte:head>
  <title>Pitch Tuner</title>
</svelte:head>

<PitchTuner bind:selected_device={$default_selected_device} />
