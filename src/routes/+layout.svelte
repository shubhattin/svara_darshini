<script lang="ts">
  import { ModeWatcher } from 'mode-watcher';
  import TopAppBar from '~/components/TopAppBar.svelte';
  import { onMount, type Snippet } from 'svelte';
  import '@fontsource/roboto/latin.css';
  import '../app.scss';
  import PartyTown from '~/components/tags/PartyTown.svelte';
  import GA from '~/components/tags/GA.svelte';
  import { pwa_state } from '~/state/main.svelte';
  import GS from '~/components/tags/GS.svelte';

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
<div class="contaiiner mx-auto mb-1 max-w-screen-lg">
  <TopAppBar />
  <div class="mx-2">
    {@render children()}
  </div>
</div>
<PartyTown />
<GA />
<GS />
