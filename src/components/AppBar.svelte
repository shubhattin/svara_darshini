<script lang="ts">
  import type { Snippet } from 'svelte';

  let {
    lead,
    trail,
    class: className = ''
  }: {
    lead?: Snippet;
    trail?: Snippet;
    class?: string;
  } = $props();
</script>

<header class="flex w-full items-center justify-between px-4 py-3 {className}">
  <!-- Lead section -->
  <div class="flex items-center space-x-3">
    {#if lead}
      {@render lead()}
    {/if}
  </div>

  <!-- Trail section -->
  <div class="flex items-center space-x-2">
    {#if trail}
      {@render trail()}
    {/if}
  </div>
</header>
