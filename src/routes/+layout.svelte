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

  let { children }: { children: Snippet } = $props();

  onMount(() => {
    window.addEventListener('beforeinstallprompt', (event) => {
      event.preventDefault();
      pwa_state.event_triggerer = event;
      pwa_state.install_event_fired = true;
    });
  });
</script>

<ModeWatcher />
<!-- Full viewport background -->
<div
  class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 dark:from-slate-900 dark:via-slate-800 dark:to-indigo-950"
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

{#if browser && import.meta.env.PROD}
  {#await import("~/components/tags/ServiceWorker.svelte") then ServiceWorker}
    <ServiceWorker.default />
  {/await}
{/if}
