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

<svelte:head>
  {#if import.meta.env.PROD}
    <script>
      if ('serviceWorker' in navigator) {
        window.addEventListener('load', () => {
          navigator.serviceWorker
            .register('/sw.js')
            .then((registration) => {})
            .catch((error) => {
              console.log('SW registration failed:', error);
            });
        });
      }
    </script>
  {/if}
</svelte:head>
