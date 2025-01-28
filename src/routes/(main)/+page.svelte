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
  title="SvaraDarshini"
  description="SvaraDarshini is an intuitive tool to understand Principles of Music that are common across the world."
/>

<PitchTuner
  bind:selected_device={$default_selected_device}
  bind:selected_Sa_at={$default_Sa_at}
  bind:selected_sargam_orientation={$default_sargam_orientation}
  bind:selected_note_orientation={$default_note_orientation}
/>
