<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { registerSW } from 'virtual:pwa-register';

  onMount(async () => {
    if (browser && import.meta.env.PROD) {
      registerSW({ immediate: true });
    }
  });
</script>

<!-- 
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
</svelte:head> -->
