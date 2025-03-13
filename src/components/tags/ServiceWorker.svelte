<script lang="ts">
  import { useRegisterSW } from 'virtual:pwa-register/svelte';
  import { fade, slide } from 'svelte/transition';

  let popup_open = $state(true);
  const { needRefresh, updateServiceWorker } = useRegisterSW({
    immediate: true
  });
</script>

{#if $needRefresh && popup_open}
  <div
    class="outline-hidden fixed top-20 flex w-full select-none items-center justify-center"
    in:slide
    out:fade
  >
    <div
      class="card dark:bg-surface-800 z-50 rounded-lg bg-zinc-100 px-2 py-1.5 opacity-90 shadow-2xl"
    >
      <span class="font-semibold">New Version Available</span>
      <span class="ml-1 space-x-1">
        <button
          onclick={async () => {
            await updateServiceWorker(true);
          }}
          class="btn preset-tonal-primary px-2 py-1 font-bold">Reload</button
        >
        <button onclick={() => (popup_open = false)} class="btn preset-tonal-error font-bold"
          >Dismiss</button
        >
      </span>
    </div>
  </div>
{/if}
