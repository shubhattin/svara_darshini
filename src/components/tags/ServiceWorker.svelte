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
    class="fixed top-20 flex w-full items-center justify-center outline-hidden select-none"
    in:slide
    out:fade
  >
    <div
      class="z-50 card rounded-lg bg-zinc-100 px-2 py-1.5 opacity-90 shadow-2xl dark:bg-surface-800"
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
