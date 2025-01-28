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
  import { FaSolidMoneyBillWave } from 'svelte-icons-pack/fa';
  import { cl_join } from '~/tools/cl_join';

  let { start, headline, end }: { start?: Snippet; headline?: Snippet; end?: Snippet } = $props();

  let route_id = $derived($page.route.id as keyof typeof PAGE_TITLES);

  let app_bar_popover_status = $state(false);
  let support_modal_status = $state(false);
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
    {@render support('hidden sm:inline')}
    <Popover
      bind:open={app_bar_popover_status}
      positioning={{ placement: 'left-start' }}
      arrow={false}
      contentBase="card z-50 space-y-2 rounded-lg px-3 py-2 shadow-xl bg-surface-100-900"
      triggerBase="btn m-0 p-0 gap-0 outline-none select-none"
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
        {@render support('sm:hidden block')}
        {#if pwa_state.install_event_fired}
          <button
            class="select-none gap-1 px-2 py-1 text-sm outline-none"
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

{#snippet support(cl?: string)}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <span
    onclick={() => {
      app_bar_popover_status = false;
      support_modal_status = true;
    }}
    class={cl_join(
      'btn m-0 select-none gap-1 rounded-md px-2 py-1 text-xs font-semibold outline-none hover:bg-gray-200 sm:text-sm dark:hover:bg-gray-700',
      cl
    )}
  >
    <Icon src={FaSolidMoneyBillWave} class="text-2xl" />
    Support Our Projects
  </span>
{/snippet}
<Modal
  bind:open={support_modal_status}
  contentBase="card z-40 space-y-2 rounded-lg px-3 py-2 shadow-xl bg-surface-100-900"
  backdropBackground="backdrop-blur-sm"
>
  {#snippet content()}
    <div class="text-center text-lg font-bold text-amber-700 dark:text-warning-500">
      <div>Support Our Projects</div>
      <div class="text-sm">Pay as you wish</div>
    </div>
    <div>
      <div class="text-center text-lg font-bold">One Time Contributions:</div>
      <div class="text-center text-sm">
        UPI : <a
          href="upi://pay?pa=thesanskritchannel@okicici&pn=Udaya%20Shreyast&cu=INR"
          target="_blank"
          rel="noopener noreferrer">thesanskritchannel@okicici</a
        >
        <br />
        <a
          href="https://www.paypal.me/thesanskritchannel"
          target="_blank"
          rel="noopener noreferrer"
          class="text-blue-600 hover:text-blue-500 dark:text-blue-400 dark:hover:text-blue-300"
        >
          https://www.paypal.me/thesanskritchannel
        </a>
        <br />
        <a
          href="https://rzp.io/l/thesanskritchannel"
          target="_blank"
          rel="noopener noreferrer"
          class="text-blue-600 hover:text-blue-500 dark:text-blue-400 dark:hover:text-blue-300"
        >
          https://rzp.io/l/thesanskritchannel
        </a>
      </div>
      <div class="text-center text-lg font-bold">Monthly Memberships:</div>
      <div class="text-center text-sm">
        <a
          href="https://www.patreon.com/thesanskritchannel"
          target="_blank"
          rel="noopener noreferrer"
          class="text-blue-600 hover:text-blue-500 dark:text-blue-400 dark:hover:text-blue-300"
        >
          https://www.patreon.com/thesanskritchannel
        </a>
      </div>
    </div>
  {/snippet}
</Modal>
