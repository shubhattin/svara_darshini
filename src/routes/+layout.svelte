<script lang="ts">
  import { ModeWatcher } from 'mode-watcher';
  import TopAppBar from '~/components/TopAppBar.svelte';
  import { onMount, type Snippet } from 'svelte';
  import '@fontsource/roboto/latin.css';
  import '../app.css';
  import '../app.scss';
  import { pwa_state } from '~/state/main.svelte';
  import PostHogInit from '~/components/tags/PostHogInit.svelte';
  import { browser } from '$app/environment';
  import { Capacitor } from '@capacitor/core';
  import { StatusBar, Style } from '@capacitor/status-bar';

  const IS_ANDROID_BUILD = import.meta.env.IS_ANDROID_BUILD === 'true';

  let { children }: { children: Snippet } = $props();

  onMount(async () => {
    window.addEventListener('beforeinstallprompt', (event) => {
      event.preventDefault();
      pwa_state.event_triggerer = event;
      pwa_state.install_event_fired = true;
    });

    // Configure status bar for mobile platforms
    if (Capacitor.isNativePlatform()) {
      try {
        await StatusBar.setStyle({ style: Style.Dark });
        await StatusBar.setBackgroundColor({ color: '#1e293b' }); // slate-800
        await StatusBar.setOverlaysWebView({ overlay: false });
      } catch (error) {
        console.log('Status bar configuration error:', error);
      }
    }
  });
</script>

<ModeWatcher />
<!-- Full viewport background with safe area support -->
<div
  class="min-h-screen bg-linear-to-br from-slate-50 via-blue-50 to-indigo-100 dark:from-slate-900 dark:via-slate-800 dark:to-indigo-950"
>
  <!-- Content container -->
  <div class="container mx-auto mb-1 max-w-7xl">
    <TopAppBar />
    <div class="mx-2">
      {@render children()}
    </div>
  </div>
</div>
<PostHogInit />

{#if browser && import.meta.env.PROD && !IS_ANDROID_BUILD}
  {#await import('~/components/tags/ServiceWorker.svelte') then ServiceWorker}
    <ServiceWorker.default />
  {/await}
{/if}
