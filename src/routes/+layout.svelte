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
<div class="contaiiner max-w-(--breakpoint-lg) mx-auto mb-1">
  <TopAppBar />
  <div class="mx-2">
    {@render children()}
  </div>
</div>
<PostHogInit />

{#if browser && import.meta.env.PROD}
  {#await import("~/components/tags/ServiceWorker.svelte") then ServiceWorker}
    <ServiceWorker.default />
  {/await}
{/if}
