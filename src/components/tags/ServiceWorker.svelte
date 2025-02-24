<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { registerSW } from 'virtual:pwa-register';

  onMount(() => {
    if (browser && import.meta.env.PROD) {
      registerSW({ immediate: true });
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
    }
  });
</script>
