<script lang="ts">
  import { ModeWatcher } from 'mode-watcher';
  import TopAppBar from '~/components/TopAppBar.svelte';
  import { onMount, type Snippet } from 'svelte';
  import '@fontsource/roboto/latin.css';
  import '../app.scss';
  import { pwa_state } from '~/state/main.svelte';
  import { browser } from '$app/environment';

  let { children }: { children: Snippet } = $props();

  onMount(() => {
    window.addEventListener('beforeinstallprompt', (event) => {
      event.preventDefault();
      pwa_state.event_triggerer = event;
      pwa_state.install_event_fired = true;
    });
    if (import.meta.env.PROD && import.meta.env.VITE_POSTHOG_ID && browser) {
      import('posthog-js').then((posthog) => {
        posthog.default.init(import.meta.env.VITE_POSTHOG_ID, {
          api_host: 'https://us.i.posthog.com',
          person_profiles: 'identified_only' // or 'always' to create profiles for anonymous users as well
        });
      });
    }
  });
</script>

<ModeWatcher />
<div class="contaiiner mx-auto mb-1 max-w-screen-lg">
  <TopAppBar />
  <div class="mx-2">
    {@render children()}
  </div>
</div>
