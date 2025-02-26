<script lang="ts">
  import { browser } from '$app/environment';
  import { onMount } from 'svelte';
  import { registerSW } from 'virtual:pwa-register';
  import { fade } from 'svelte/transition';
  import { z } from 'zod';
  import ms from 'ms';

  let new_build_available = $state(false);

  onMount(() => {
    if (browser && import.meta.env.PROD) {
      registerSW({ immediate: true });

      async function check_new_version() {
        try {
          const req = await fetch('/_app/version.json');
          const data = z.object({ version: z.string() }).parse(await req.json());
          const KEY_APP_VERSION = 'svara_darshini_sveltekit_version';
          const value = localStorage.getItem(KEY_APP_VERSION);
          if ((value && value !== data.version) || !value) {
            new_build_available = true;
            setTimeout(() => (new_build_available = false), ms('2mins'));
            localStorage.setItem(KEY_APP_VERSION, data.version);
          }
        } catch (e) {}
      }

      setInterval(async () => await check_new_version(), ms('45mins'));
      check_new_version();
    }
  });
</script>

{#if new_build_available}
  <div
    class="fixed top-20 flex w-full select-none items-center justify-center outline-none"
    transition:fade
  >
    <div
      class="card z-50 rounded-lg bg-zinc-100 px-2 py-1.5 opacity-90 shadow-2xl dark:bg-surface-800"
    >
      <span class="font-semibold">New Version Available</span>
      <span class="ml-1 space-x-1">
        <button
          onclick={() => window.location.reload()}
          class="btn px-2 py-1 font-bold preset-tonal-primary">Reload</button
        >
        <button
          onclick={() => (new_build_available = false)}
          class="btn font-bold preset-tonal-error">Close</button
        >
      </span>
    </div>
  </div>
{/if}
