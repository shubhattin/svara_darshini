<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { registerSW } from 'virtual:pwa-register';

  onMount(() => {
    if (browser && import.meta.env.PROD) {
      registerSW({ immediate: true });
    }
  });
</script>
