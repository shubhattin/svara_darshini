<script lang="ts">
  interface Props {
    title: string;
    description?: string | null;
  }

  let { title, description = null }: Props = $props();
</script>

<svelte:head>
  <!-- <meta
    property="og:image"
    content=""
  /> -->
  <meta property="og:image:width" content="501.4" />
  <meta property="og:image:height" content="229.32" />
  <title>{title}</title>
  <meta property="og:title" content={title} />
  <meta property="og:site_name" content={title} />
  {#if description}
    <meta name="description" content={description} />
    <meta property="og:description" content={description} />
  {/if}
  <meta property="og:type" content="app" />
</svelte:head>
