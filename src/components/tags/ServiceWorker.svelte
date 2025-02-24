<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';

  onMount(async () => {
    if (browser && import.meta.env.PROD) {
      const { registerSW } = await import('virtual:pwa-register');
      registerSW({ immediate: true });
    }
  });
</script>
