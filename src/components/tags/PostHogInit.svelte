<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { Capacitor } from '@capacitor/core';

  const is_native_platform = Capacitor.isNativePlatform();

  onMount(() => {
    if (
      import.meta.env.PROD &&
      import.meta.env.VITE_POSTHOG_KEY &&
      (import.meta.env.VITE_POSTHOG_URL || import.meta.env.VITE_SITE_URL)
    ) {
      if (browser && !is_native_platform) {
        import('posthog-js').then((posthog) => {
          posthog.default.init(import.meta.env.VITE_POSTHOG_KEY, {
            api_host: `${import.meta.env.VITE_POSTHOG_URL}`,
            person_profiles: 'identified_only',
            ui_host: 'https://us.posthog.com'
          });
        });
      }
      if (is_native_platform) {
        import('@capawesome/capacitor-posthog').then((posthog) => {
          posthog.Posthog.setup({
            apiKey: import.meta.env.VITE_POSTHOG_KEY,
            host: import.meta.env.VITE_POSTHOG_URL
          });
        });
      }
    }
  });
</script>
