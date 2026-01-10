<script lang="ts">
  import { Modal, Popover } from '@skeletonlabs/skeleton-svelte';
  import AppBar from './AppBar.svelte';
  import ThemeChanger from './ThemeChanger.svelte';
  import Icon from '~/tools/Icon.svelte';
  import { SiGithub } from 'svelte-icons-pack/si';
  import { AiOutlineMenu, AiOutlineYoutube, AiOutlineInstagram } from 'svelte-icons-pack/ai';
  import { IoExtensionPuzzle, IoSettingsSharp } from 'svelte-icons-pack/io';
  import {
    BsPalette,
    BsDownload,
    BsBoxArrowUpRight,
    BsBook,
    BsMusicNote,

    BsVectorPen

  } from 'svelte-icons-pack/bs';
  import { FiMonitor, FiSun, FiMoon } from 'svelte-icons-pack/fi';
  import { page } from '$app/state';
  import { PAGE_TITLES } from '~/state/page_titles';
  import type { Snippet } from 'svelte';
  import { pwa_state } from '~/state/main.svelte';
  import { ContributeIcon } from '~/components/icons';
  import { setMode, mode } from 'mode-watcher';
  import { browser } from '$app/environment';

  let { start, headline, end }: { start?: Snippet; headline?: Snippet; end?: Snippet } = $props();

  let route_id = $derived(page.route.id as keyof typeof PAGE_TITLES);

  let app_bar_popover_status = $state(false);
  let support_modal_status = $state(false);

  const preload_component = () => import('~/components/pages/main/SupportOptions.svelte');

  // Get the user's actual theme preference (not resolved theme)
  let userThemePreference = $state('system');

  $effect(() => {
    if (browser) {
      // Check localStorage for the user's preference
      const stored = localStorage.getItem('mode-watcher-mode');
      userThemePreference = stored || 'system';
    }
  });

  const themeOptions = [
    {
      value: 'system',
      label: 'System',
      icon: FiMonitor
    },
    {
      value: 'light',
      label: 'Light',
      icon: FiSun
    },
    {
      value: 'dark',
      label: 'Dark',
      icon: FiMoon
    }
  ];

  const socialLinks = [
    {
      href: 'https://github.com/shubhattin/svara_darshini',
      icon: SiGithub,
      title: 'GitHub',
      colorClass:
        'border-gray-800/20 bg-gray-50 text-gray-800 hover:border-gray-800/40 hover:bg-gray-100 dark:border-gray-300/20 dark:bg-gray-800/50 dark:text-gray-300 dark:hover:border-gray-300/40 dark:hover:bg-gray-700/50'
    },
    {
      href: 'https://www.youtube.com/@TheSanskritChannel',
      icon: AiOutlineYoutube,
      title: 'YouTube',
      colorClass:
        'border-red-500/20 bg-red-50 text-red-600 hover:border-red-500/40 hover:bg-red-100 dark:border-red-400/20 dark:bg-red-950/30 dark:text-red-400 dark:hover:border-red-400/40 dark:hover:bg-red-900/40'
    },
    {
      href: 'https://www.instagram.com/thesanskritchannel/',
      icon: AiOutlineInstagram,
      title: 'Instagram',
      colorClass:
        'border-pink-500/20 bg-gradient-to-br from-pink-50 to-purple-50 text-pink-600 hover:border-pink-500/40 hover:from-pink-100 hover:to-purple-100 dark:border-pink-400/20 dark:from-pink-950/30 dark:to-purple-950/30 dark:text-pink-400 dark:hover:border-pink-400/40 dark:hover:from-pink-900/40 dark:hover:to-purple-900/40'
    }
  ];

  const projectLinks = [
    {
      href: 'http://projects.thesanskritchannel.org/',
      icon: BsBook,
      title: 'Projects',
      subtitle: 'Sanskrit Channel Projects',
      iconClass: 'bg-gradient-to-br from-green-500 to-emerald-600'
    },
    {
      href: 'https://krida.thesanskritchannel.org/padavali',
      icon: IoExtensionPuzzle,
      title: 'Padavali',
      subtitle: 'A Sanskrit Word Game',
      iconClass: 'bg-gradient-to-br from-indigo-500 to-purple-600'
    },
    {
      href: 'https://akshara.thesanskritchannel.org/',
      icon: BsVectorPen,
      title: 'Akshara Shikshaka',
      subtitle: 'Learn to Write Indian Scripts',
      iconClass: 'bg-gradient-to-br from-orange-400 to-orange-600'
    }
  ];
</script>

<div class="pt-safe-top z-50 mb-4">
  <div
    class="border-b border-gray-200/50 bg-linear-to-r from-slate-200 via-blue-100 to-zinc-200 shadow-lg backdrop-blur-sm dark:border-slate-600/50 dark:from-slate-800 dark:via-slate-700 dark:to-slate-800"
  >
    <AppBar class="border-0 bg-transparent shadow-none">
      {#snippet lead()}
        {#if start}
          {@render start()}
        {/if}
        {#if route_id === '/(main)'}
          <div class="flex items-center space-x-3 sm:space-x-4">
            <div
              class="flex size-8 items-center justify-center shadow-lg sm:size-8.5"
              style={`background-image: url('/img/icon_128.png'); background-size: cover; background-position: center;`}
            ></div>
            <div
              class="text-xl font-semibold tracking-wide text-gray-800 drop-shadow-sm dark:text-white"
            >
              {PAGE_TITLES[route_id][0]}
            </div>
          </div>
        {/if}
        {#if headline}
          {@render headline()}
        {/if}
        <!-- {:else if route_id in PAGE_TITLES}
          <span
            class="text-xl font-bold tracking-wide text-gray-800 drop-shadow-sm dark:text-white"
          >
            {PAGE_TITLES[route_id as keyof typeof PAGE_TITLES][0]}
          </span> -->
      {/snippet}
      {#snippet trail()}
        {@render end?.()}
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <span
          onclick={() => {
            support_modal_status = true;
          }}
          class="group mr-2 btn gap-2 rounded-xl px-4 py-2 font-semibold text-gray-700 outline-hidden
                 transition-all duration-200 ease-out select-none hover:scale-105
                 hover:bg-gray-200/70 hover:shadow-md active:scale-95 sm:mr-3
                 dark:text-white dark:hover:bg-slate-700/70"
          onmouseover={preload_component}
          onfocus={preload_component}
        >
          <Icon
            src={ContributeIcon}
            class="text-2xl transition-transform duration-200 group-hover:scale-110"
          />
          <span
            class="hidden text-sm transition-colors duration-200 group-hover:text-blue-600 sm:inline dark:group-hover:text-yellow-200"
            >Support Our Projects</span
          >
        </span>
        <!-- style={{
          maxHeight: '90vh',
          overflowY: 'auto',
          scrollbarWidth: 'none', // Firefox
          msOverflowStyle: 'none' // IE and Edge
        }} -->
        <Popover
          open={app_bar_popover_status}
          onOpenChange={(e) => (app_bar_popover_status = e.open)}
          positioning={{ placement: 'bottom-start' }}
          arrow={false}
          contentBase="w-80 p-0 border-slate-200/80 bg-white/95 backdrop-blur-md dark:border-slate-700/80 dark:bg-slate-800/95 rounded-xl shadow-2xl"
          triggerBase="btn p-1.5 gap-0 outline-hidden select-none rounded-lg bg-gray-100/80 dark:bg-slate-700/80 hover:bg-gray-200/80 dark:hover:bg-slate-600/80 hover:scale-105 active:scale-95 transition-all duration-200"
          zIndex="z-100"
        >
          {#snippet trigger()}
            <Icon
              src={AiOutlineMenu}
              class="text-xl text-gray-700 transition-colors duration-200 hover:text-blue-600 dark:text-white dark:hover:text-yellow-200"
            />
          {/snippet}
          {#snippet content()}
            <div
              class="p-4"
              style="max-height: 90vh; overflow-y: auto; scrollbar-width: none; ms-overflow-style: none"
            >
              <!-- Header -->
              <div class="mb-4 flex items-center gap-2">
                <div
                  class="flex h-8 w-8 items-center justify-center rounded-lg bg-linear-to-br from-blue-500 to-indigo-600"
                >
                  <Icon src={IoSettingsSharp} class="h-4 w-4 text-white" />
                </div>
                <div>
                  <h3 class="font-semibold text-slate-800 dark:text-slate-200">Settings</h3>
                </div>
              </div>

              <!-- Theme Section -->
              <div class="space-y-3">
                <div class="flex items-center gap-2">
                  <Icon src={BsPalette} class="-mt-1 size-4 text-slate-600 dark:text-slate-400" />
                  <span class="text-sm font-medium text-slate-700 dark:text-slate-300">Theme</span>
                </div>

                <div class="grid grid-cols-3 gap-2">
                  {#each themeOptions as option}
                    {@const isActive = userThemePreference === option.value}
                    <button
                      onclick={() => {
                        setMode(option.value as 'dark' | 'light' | 'system');
                        userThemePreference = option.value;
                        if (browser) {
                          localStorage.setItem('mode-watcher-mode', option.value);
                        }
                      }}
                      class="flex flex-col items-center gap-2 rounded-xl border-2 p-3 text-xs font-medium transition-all duration-200 hover:scale-105 active:scale-95
                             {isActive
                        ? 'border-blue-500 bg-blue-50 text-blue-700 shadow-md dark:border-blue-400 dark:bg-blue-950/50 dark:text-blue-300'
                        : 'border-slate-200 bg-slate-50 text-slate-600 hover:border-slate-300 hover:bg-slate-100 dark:border-slate-700 dark:bg-slate-800/50 dark:text-slate-400 dark:hover:border-slate-600 dark:hover:bg-slate-700/50'}"
                      title="Select {option.label} theme"
                    >
                      <Icon src={option.icon} class="h-5 w-5" />
                      <span>{option.label}</span>
                    </button>
                  {/each}
                </div>
              </div>

              <div class="my-4 h-px bg-slate-200 dark:bg-slate-700"></div>

              {#if pwa_state.install_event_fired}
                <!-- App Installation Section -->
                <div class="space-y-3">
                  <div class="flex items-center gap-2">
                    <Icon src={BsDownload} class="h-4 w-4 text-slate-600 dark:text-slate-400" />
                    <span class="text-sm font-medium text-slate-700 dark:text-slate-300"
                      >App Installation</span
                    >
                  </div>

                  <button
                    onclick={async () => {
                      app_bar_popover_status = false;
                      if (pwa_state.event_triggerer) await pwa_state.event_triggerer.prompt();
                    }}
                    class="flex w-full items-center gap-3 rounded-lg border-2 border-green-200 bg-linear-to-r from-green-50 to-emerald-50 p-3 text-left text-sm font-medium text-green-700 transition-all duration-200 hover:scale-[1.02] hover:border-green-300 hover:from-green-100 hover:to-emerald-100 hover:shadow-md active:scale-[0.98] dark:border-green-800 dark:from-green-950/30 dark:to-emerald-950/30 dark:text-green-300 dark:hover:border-green-700 dark:hover:from-green-900/40 dark:hover:to-emerald-900/40"
                    title="Install PWA App for offline access"
                  >
                    <div
                      class="flex h-8 w-8 items-center justify-center rounded-lg bg-linear-to-br from-green-500 to-emerald-600 shadow-sm"
                    >
                      <Icon src={BsDownload} class="h-4 w-4 text-white" />
                    </div>
                    <div class="flex-1">
                      <div class="font-semibold">Install App</div>
                      <div class="text-xs text-gray-500">Install for quick & offline access</div>
                    </div>
                  </button>
                </div>

                <div class="my-4 h-px bg-slate-200 dark:bg-slate-700"></div>
              {/if}

              <!-- Links Section -->
              <div class="space-y-3">
                <div class="flex items-center gap-2">
                  <Icon
                    src={BsBoxArrowUpRight}
                    class="-mt-1 size-4 text-slate-600 dark:text-slate-400"
                  />
                  <span class="text-sm font-medium text-slate-700 dark:text-slate-300">Links</span>
                </div>

                <div class="flex justify-center gap-8">
                  {#each socialLinks as link}
                    <a
                      href={link.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      onclick={() => (app_bar_popover_status = false)}
                      class="flex h-12 w-12 items-center justify-center rounded-xl border-2 transition-all duration-200 hover:scale-105 hover:shadow-md active:scale-95 {link.colorClass}"
                      title={link.title}
                    >
                      <Icon src={link.icon} class="h-6 w-6" />
                    </a>
                  {/each}
                </div>

                <!-- Project Links -->
                <div class="mt-4 space-y-2">
                  {#each projectLinks as project}
                    <a
                      href={project.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      onclick={() => (app_bar_popover_status = false)}
                      class="flex w-full items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3 text-left text-sm font-medium text-slate-700 transition-all duration-200 hover:scale-[1.02] hover:border-slate-300 hover:bg-slate-100 active:scale-[0.98] dark:border-slate-700 dark:bg-slate-800/50 dark:text-slate-300 dark:hover:border-slate-600 dark:hover:bg-slate-700/50"
                    >
                      <div
                        class="flex h-8 w-8 items-center justify-center rounded-lg {project.iconClass}"
                      >
                        <Icon src={project.icon} class="h-4 w-4 text-white" />
                      </div>
                      <div>
                        <div class="font-medium">{project.title}</div>
                        <div class="text-xs text-slate-500 dark:text-slate-400">
                          {project.subtitle}
                        </div>
                      </div>
                    </a>
                  {/each}
                  <a
                  href="https://lipilekhika.in"
                  target="_blank"
                  rel="noopener noreferrer"
                  onclick={() => app_bar_popover_status = false}
                  class="flex w-full items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3 text-left text-sm font-medium text-slate-700 transition-all duration-200 hover:scale-[1.02] hover:border-slate-300 hover:bg-slate-100 active:scale-[0.98] dark:border-slate-700 dark:bg-slate-800/50 dark:text-slate-300 dark:hover:border-slate-600 dark:hover:bg-slate-700/50"
                >
                  <span
                    class="inline-block size-8 bg-cover bg-center bg-no-repeat px-4"
                    style={`background-image: url('/lipi.svg');`}
                    title="Lipi Lekhika"
                    aria-label="Lipi Lekhika"
                  ></span>
                  <div>
                    <div class="font-medium">Lipi Lekhika</div>
                    <div class="text-xs text-slate-500 dark:text-slate-400">
                      Type Indian Languages with full Speed and Accuracy
                    </div>
                  </div>
                </a>
                </div>
              </div>
            </div>
          {/snippet}
        </Popover>
      {/snippet}
    </AppBar>
  </div>
</div>

<Modal
  open={support_modal_status}
  onOpenChange={(e) => (support_modal_status = e.open)}
  contentBase="card z-40 px-6 py-4 shadow-2xl rounded-2xl select-none outline-hidden 
              bg-gradient-to-br from-white to-gray-50 
              dark:from-slate-800 dark:to-slate-900 
              border border-gray-200/20 dark:border-slate-600/30 backdrop-blur-md"
  backdropBackground="backdrop-blur-sm bg-black/30 dark:bg-black/50"
>
  {#snippet content()}
    {#await preload_component() then SupportOptions}
      <SupportOptions.default />
    {/await}
  {/snippet}
</Modal>

<style global>
  /* Safe area utilities for mobile devices */
  .pt-safe-top {
    padding-top: env(safe-area-inset-top);
  }

  .pb-safe-bottom {
    padding-bottom: env(safe-area-inset-bottom);
  }

  .pl-safe-left {
    padding-left: env(safe-area-inset-left);
  }

  .pr-safe-right {
    padding-right: env(safe-area-inset-right);
  }

  .pt-safe {
    padding-top: max(1rem, env(safe-area-inset-top));
  }

  .pb-safe {
    padding-bottom: max(1rem, env(safe-area-inset-bottom));
  }
</style>
