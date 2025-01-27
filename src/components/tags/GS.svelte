<script lang="ts">
  import { page } from '$app/state';
  const ID: string = import.meta.env.VITE_GS_ID;
</script>

{#if ID && page.url.pathname !== '/'}
  <meta name="google-site-verification" content={ID} />
{/if}
