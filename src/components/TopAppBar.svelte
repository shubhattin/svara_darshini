<script lang="ts">
  import { AppBar, Modal, Popover } from '@skeletonlabs/skeleton-svelte';
  import ThemeChanger from './ThemeChanger.svelte';
  import Icon from '~/tools/Icon.svelte';
  import { SiGithub } from 'svelte-icons-pack/si';
  import { AiOutlineMenu } from 'svelte-icons-pack/ai';
  import { page } from '$app/stores';
  import { PAGE_TITLES } from '~/state/page_titles';
  import type { Snippet } from 'svelte';
  import { OiDownload24 } from 'svelte-icons-pack/oi';
  import { pwa_state } from '~/state/main.svelte';
  import { ContributeIcon } from '~/components/icons';

  let { start, headline, end }: { start?: Snippet; headline?: Snippet; end?: Snippet } = $props();

  let route_id = $derived($page.route.id as keyof typeof PAGE_TITLES);

  let app_bar_popover_status = $state(false);
  let support_modal_status = $state(false);

  const preload_component = () => import('~/components/pages/main/SupportOptions.svelte');
</script>

<AppBar>
  {#snippet lead()}
    {#if start}
      {@render start()}
    {/if}
    {#if headline}
      {@render headline()}
    {:else if route_id in PAGE_TITLES}
      <span class={PAGE_TITLES[route_id as keyof typeof PAGE_TITLES][1]}>
        {PAGE_TITLES[route_id as keyof typeof PAGE_TITLES][0]}
      </span>
    {/if}
  {/snippet}
  {#snippet trail()}
    {@render end?.()}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <span
      onclick={() => {
        support_modal_status = true;
      }}
      class="-mt-1 mr-2 btn gap-2 rounded-md px-2 py-1 font-semibold outline-hidden select-none hover:bg-gray-200 sm:mr-3 dark:hover:bg-gray-700"
      onmouseover={preload_component}
      onfocus={preload_component}
    >
      <Icon src={ContributeIcon} class="text-3xl" />
      <span class="hidden text-sm sm:inline">Support Our Projects</span>
    </span>
    <Popover
      open={app_bar_popover_status}
      onOpenChange={(e) => (app_bar_popover_status = e.open)}
      positioning={{ placement: 'left-start' }}
      arrow={false}
      contentBase="card z-50 space-y-2 rounded-lg px-3 py-2 shadow-xl bg-surface-100-900"
      triggerBase="btn p-0 gap-0 outline-hidden select-none"
    >
      {#snippet trigger()}
        <Icon
          src={AiOutlineMenu}
          class="text-3xl hover:text-gray-500 active:text-blue-600 dark:hover:text-gray-400 dark:active:text-blue-400"
        />
      {/snippet}
      {#snippet content()}
        <a
          href="https://github.com/shubhattin/svara_darshini"
          target="_blank"
          rel="noopener noreferrer"
          class="will-close group flex space-x-1 rounded-md px-2 py-1 hover:bg-gray-200 dark:hover:bg-gray-700"
          onclick={() => (app_bar_popover_status = false)}
        >
          <Icon
            src={SiGithub}
            class="-mt-1 mr-1 text-2xl group-hover:fill-indigo-700 dark:group-hover:fill-zinc-400"
          />
          <span>Github</span>
        </a>
        <!-- {@render support('sm:hidden block')} -->
        {#if pwa_state.install_event_fired}
          <button
            class="gap-1 px-2 py-1 text-sm outline-hidden select-none"
            onclick={async () => {
              app_bar_popover_status = false;
              if (pwa_state.install_event_fired && pwa_state.event_triggerer)
                await pwa_state.event_triggerer.prompt();
            }}
          >
            <Icon src={OiDownload24} class="-mt-1 text-base" />
            Install
          </button>
        {/if}
        <div class="wont-close flex space-x-3 rounded-md px-2 py-1">
          <span class="mt-1">Set Theme</span>
          <ThemeChanger />
        </div>
      {/snippet}
    </Popover>
  {/snippet}
</AppBar>

<Modal
  open={support_modal_status}
  onOpenChange={(e) => (support_modal_status = e.open)}
  contentBase="card z-40 px-3 py-2 shadow-xl rounded-md select-none outline-hidden bg-slate-100 dark:bg-surface-900"
  backdropBackground="backdrop-blur-xs"
>
  {#snippet content()}
    {#await preload_component() then SupportOptions}
      <SupportOptions.default />
    {/await}
  {/snippet}
</Modal>
