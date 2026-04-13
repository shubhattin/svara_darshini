<script lang="ts">
  import type { Snippet } from 'svelte';
  import { onMount } from 'svelte';
  import { NOTES, NOTES_STARTING_WITH_A, type note_types, SARGAM } from '../constants';
  import { cl_join } from '~/tools/cl_join';
  import { Popover } from '@skeletonlabs/skeleton-svelte';
  import { BsChevronDown, BsChevronUp, BsPauseFill, BsPlayFill } from 'svelte-icons-pack/bs';
  import Icon from '~/tools/Icon.svelte';
  import { mode } from 'mode-watcher';

  type GraphPoint = {
    yRatio: number;
    pitch: number;
    note: string;
    clarity: number;
    originalIndex: number;
    scale: number;
  };

  let Sa_at_popup_status = $state(false);
  let bottom_start_note_popup_status = $state(false);

  let {
    pitch_history,
    stop_button,
    MAX_PITCH_HISTORY_POINTS,
    bottom_start_note = $bindable(),
    selected_Sa_at = $bindable(),
    input_mode
  }: {
    pitch_history: Array<{
      time: number;
      pitch: number;
      note: string;
      clarity: number;
      scale: number;
    }>;
    stop_button: Snippet;
    MAX_PITCH_HISTORY_POINTS: number;
    bottom_start_note: note_types;
    selected_Sa_at: note_types;
    input_mode: 'mic' | 'file';
  } = $props();

  let is_paused = $state(false);
  let containerEl: HTMLDivElement | undefined = $state(undefined);
  let containerWidth = $state(800);
  let containerHeight = $state(300);
  let fontsReady = $state(false);
  let PitchTimeGraphStage = $state<typeof import('./PitchTimeGraphStage.svelte').default | null>(
    null
  );

  const VIEWBOX_H = 300;
  const GRAPH_PADDING = {
    top: 26,
    left: 50,
    right: 10,
    bottom: 26
  } as const;
  const NOTE_STEP_CONTROL_SIZE = 18;
  const NOTE_STEP_CONTROL_TOP_INSET = 2;
  const NOTE_STEP_CONTROL_BOTTOM_INSET = 6;

  const NOTE_COLORS: Record<note_types, string> = {
    A: 'hsla(0, 100%, 50%, 1)',
    'A#': 'hsla(30, 100%, 50%, 1)',
    B: 'hsla(60, 100%, 50%, 1)',
    C: 'hsla(90, 100%, 50%, 1)',
    'C#': 'hsla(120, 100%, 50%, 1)',
    D: 'hsla(150, 100%, 50%, 1)',
    'D#': 'hsla(180, 100%, 50%, 1)',
    E: 'hsla(210, 100%, 50%, 1)',
    F: 'hsla(240, 100%, 50%, 1)',
    'F#': 'hsla(270, 100%, 50%, 1)',
    G: 'hsla(300, 100%, 50%, 1)',
    'G#': 'hsla(330, 100%, 50%, 1)'
  };

  const SARGAM_KEYS = SARGAM.map((sargam) => sargam.key);

  const isDarkMode = $derived($mode === 'dark');
  const aspectRatio = $derived(containerHeight > 0 ? containerWidth / containerHeight : 800 / 300);
  const VIEWBOX_W = $derived(Math.round(VIEWBOX_H * aspectRatio));
  const GRAPH_WIDTH = $derived(VIEWBOX_W - GRAPH_PADDING.left - GRAPH_PADDING.right);
  const GRAPH_HEIGHT = VIEWBOX_H - GRAPH_PADDING.top - GRAPH_PADDING.bottom;
  const VISIBLE_POINTS = $derived(
    Math.max(
      20,
      Math.min(MAX_PITCH_HISTORY_POINTS, Math.round(MAX_PITCH_HISTORY_POINTS * (VIEWBOX_W / 800)))
    )
  );

  const graphPalette = $derived({
    background: '#0f172a',
    grid: 'rgba(255,255,255,0.15)',
    axis: '#64748b',
    label: '#cbd5e1',
    labelStrong: '#f8fafc',
    point: '#ef4444',
    buttonBg: 'rgba(51, 65, 85, 0.95)',
    buttonHoverBg: 'rgba(71, 85, 105, 0.95)',
    buttonText: '#f1f5f9',
    buttonRing: 'rgba(148, 163, 184, 0.75)',
    overlayShadow: '0 1px 2px rgba(15, 23, 42, 0.25)',
    popoverSurface: isDarkMode ? 'bg-surface-900 text-slate-100' : 'bg-slate-100 text-slate-900',
    inactiveOption: isDarkMode
      ? 'bg-slate-800 hover:bg-primary-600/80'
      : 'bg-slate-400 hover:bg-primary-500/80',
    activeOption: isDarkMode ? 'bg-primary-600' : 'bg-primary-500',
    pauseButton: isDarkMode ? 'bg-primary-500' : 'bg-primary-600'
  });

  const NOTES_CUSTOM_START = $derived(
    NOTES.slice(NOTES.indexOf(bottom_start_note)).concat(
      NOTES.slice(0, NOTES.indexOf(bottom_start_note))
    )
  );

  const SARGAM_CUSTOM_START = $derived.by(() => {
    const NOTES_INDEX = NOTES_CUSTOM_START.indexOf(selected_Sa_at);
    const new_arr: string[] = Array.from({ length: NOTES.length });
    for (let i = 0; i < NOTES.length; i++) {
      new_arr[(i + NOTES_INDEX) % NOTES.length] = SARGAM_KEYS[i];
    }
    return new_arr;
  });

  $effect(() => {
    const el = containerEl;
    if (!el) return;
    const ro = new ResizeObserver((entries) => {
      const entry = entries[0];
      if (entry) {
        containerWidth = Math.round(entry.contentRect.width);
        containerHeight = Math.round(entry.contentRect.height);
      }
    });
    ro.observe(el);
    return () => ro.disconnect();
  });

  $effect(() => {
    if (typeof document === 'undefined' || !('fonts' in document)) {
      fontsReady = true;
      return;
    }

    let cancelled = false;
    fontsReady = document.fonts.check('10px ome_bhatkhande_en');

    const ready = async () => {
      await document.fonts.load('10px ome_bhatkhande_en');
      if (!cancelled) {
        fontsReady = true;
      }
    };

    ready();

    return () => {
      cancelled = true;
    };
  });

  onMount(async () => {
    const module = await import('./PitchTimeGraphStage.svelte');
    PitchTimeGraphStage = module.default;
  });

  const stepBottomStartNote = (direction: 'up' | 'down') => {
    const currentIndex = NOTES_STARTING_WITH_A.indexOf(bottom_start_note);
    if (currentIndex === -1) return;

    const nextIndex =
      direction === 'up'
        ? (currentIndex + 1) % NOTES_STARTING_WITH_A.length
        : (currentIndex - 1 + NOTES_STARTING_WITH_A.length) % NOTES_STARTING_WITH_A.length;

    bottom_start_note = NOTES_STARTING_WITH_A[nextIndex];
  };

  const getXPosOnGraph = (index: number) =>
    (index / Math.max(VISIBLE_POINTS - 1, 1)) * GRAPH_WIDTH + GRAPH_PADDING.left;
  const getYPosOnGraph = (yRatio: number) =>
    GRAPH_HEIGHT + GRAPH_PADDING.top - yRatio * GRAPH_HEIGHT;

  const frequencyToYPositionRatio = (frequency: number) => {
    if (!Number.isFinite(frequency) || frequency <= 0) {
      return null;
    }

    const A0_freq = 27.5;
    const semitoneOffset = 12 * (Math.log(frequency / A0_freq) / Math.log(2));
    const semitoneInOctave = ((semitoneOffset % 12) + 12) % 12;
    const baseIndex = NOTES_STARTING_WITH_A.indexOf(bottom_start_note);
    const semitoneRelative = (semitoneInOctave - baseIndex + 12) % 12;
    const normalized = ((semitoneRelative + 1) / 12) * 100;
    return Math.min(Math.max(normalized, 0), 100) / 100;
  };

  const graphDataMain = $derived(
    pitch_history
      .map((point, index) => {
        const yPos = frequencyToYPositionRatio(point.pitch);
        return yPos !== null
          ? {
              yRatio: yPos,
              pitch: point.pitch,
              note: point.note,
              clarity: point.clarity,
              originalIndex: index,
              scale: point.scale
            }
          : null;
      })
      .filter((point): point is GraphPoint => point !== null)
  );

  let paused_graph_data = $state<{
    history: GraphPoint[];
    audio_info_scale?: number;
  }>({
    history: [],
    audio_info_scale: undefined
  });

  const graphData = $derived.by(() => {
    const source = is_paused ? paused_graph_data.history : graphDataMain;
    return source.length > VISIBLE_POINTS ? source.slice(-VISIBLE_POINTS) : source;
  });

  const lastPoint = $derived(graphData[graphData.length - 1]);
  const lastX = $derived(lastPoint ? getXPosOnGraph(graphData.length - 1) : GRAPH_PADDING.left);
  const lastY = $derived(lastPoint ? getYPosOnGraph(lastPoint.yRatio) : GRAPH_PADDING.top);
  const isRightSide = $derived(lastX > VIEWBOX_W * 0.85);
  const isNearTop = $derived(lastY < GRAPH_PADDING.top + 20);
  const indicatorX = $derived(isRightSide ? lastX - 10 : lastX + 10);
  const indicatorY = $derived(isNearTop ? lastY + 20 : lastY - 10);

  const makeOverlayStyle = (x: number, y: number, width: number, height: number) =>
    [
      `left:${(x / VIEWBOX_W) * 100}%`,
      `top:${(y / VIEWBOX_H) * 100}%`,
      `width:${(width / VIEWBOX_W) * 100}%`,
      `height:${(height / VIEWBOX_H) * 100}%`
    ].join(';');
  const noteRows = $derived(
    Array.from({ length: 13 }, (_, noteIndex) => {
      const y = (noteIndex / 12) * GRAPH_HEIGHT + GRAPH_PADDING.top;
      const noteName = NOTES_CUSTOM_START[NOTES_CUSTOM_START.length - noteIndex - 1];
      const sargamKey = SARGAM_CUSTOM_START[SARGAM_CUSTOM_START.length - noteIndex - 1];

      return {
        y,
        noteName,
        sargamKey,
        noteColor: noteName ? NOTE_COLORS[noteName] : undefined,
        highlightNote: noteIndex === NOTES_CUSTOM_START.length - 1,
        highlightSargam: sargamKey === 's',
        drawGrid: noteIndex < 12
      };
    })
  );
</script>

<div class="flex items-center justify-center gap-x-8 sm:gap-x-12 md:gap-x-16 lg:gap-x-20">
  <div class="flex items-center gap-x-2">
    <Popover
      open={Sa_at_popup_status}
      onOpenChange={(e) => (Sa_at_popup_status = e.open)}
      contentBase={cl_join(
        'card z-50 space-y-2 rounded-lg p-2 shadow-xl',
        graphPalette.popoverSurface
      )}
    >
      {#snippet trigger()}
        <div class="flex items-center justify-center gap-x-1 outline-hidden">
          <span class="text-xs font-semibold sm:text-sm md:text-base">Sa at</span>
          {#if !Sa_at_popup_status}
            <Icon src={BsChevronDown} class="-mt-1 size-4 sm:size-5" />
          {:else}
            <Icon src={BsChevronUp} class="-mt-1 size-4 sm:size-5" />
          {/if}
          <span class="text-xs sm:text-sm md:text-base">{selected_Sa_at}</span>
        </div>
      {/snippet}
      {#snippet content()}
        <div class="grid grid-cols-4 gap-x-2 gap-y-1 sm:grid-cols-6 sm:gap-x-2">
          {#each NOTES_STARTING_WITH_A as note}
            <button
              class={cl_join(
                'gap-0 rounded-md px-1 py-1 text-sm font-semibold text-white sm:text-base',
                selected_Sa_at === note ? graphPalette.activeOption : graphPalette.inactiveOption
              )}
              onclick={() => {
                selected_Sa_at = note;
                Sa_at_popup_status = false;
              }}>{note}</button
            >
          {/each}
        </div>
      {/snippet}
    </Popover>
  </div>
  <div class="flex items-center gap-x-2">
    <Popover
      open={bottom_start_note_popup_status}
      onOpenChange={(e) => (bottom_start_note_popup_status = e.open)}
      contentBase={cl_join(
        'card z-50 space-y-2 rounded-lg p-2 shadow-xl',
        graphPalette.popoverSurface
      )}
    >
      {#snippet trigger()}
        <div class="flex items-center justify-center gap-x-1 outline-hidden">
          <span class="text-xs font-semibold sm:text-sm md:text-base">Bottom Start Note</span>
          {#if !bottom_start_note_popup_status}
            <Icon src={BsChevronDown} class="-mt-1 size-4 sm:size-5" />
          {:else}
            <Icon src={BsChevronUp} class="-mt-1 size-4 sm:size-5" />
          {/if}
          <span class="text-xs sm:text-sm md:text-base">{bottom_start_note}</span>
        </div>
      {/snippet}
      {#snippet content()}
        <div class="grid grid-cols-4 gap-x-2 gap-y-1 sm:grid-cols-6 sm:gap-x-2">
          {#each NOTES_STARTING_WITH_A as note}
            <button
              class={cl_join(
                'gap-0 rounded-md px-1 py-1 text-sm font-semibold text-white sm:text-base',
                bottom_start_note === note ? graphPalette.activeOption : graphPalette.inactiveOption
              )}
              onclick={() => {
                bottom_start_note = note;
                bottom_start_note_popup_status = false;
              }}>{note}</button
            >
          {/each}
        </div>
      {/snippet}
    </Popover>
  </div>
</div>

<div
  bind:this={containerEl}
  class={cl_join(
    'relative mt-1 w-full overflow-hidden rounded-lg',
    'h-[60vh] sm:h-[50vh] md:h-[500px] lg:h-[580px]'
  )}
>
  {#if PitchTimeGraphStage}
    {#key fontsReady}
      <PitchTimeGraphStage
        {containerWidth}
        {containerHeight}
        {VIEWBOX_W}
        {VIEWBOX_H}
        {GRAPH_PADDING}
        {GRAPH_WIDTH}
        {GRAPH_HEIGHT}
        {VISIBLE_POINTS}
        {graphData}
        {noteRows}
        noteGradientNotes={NOTES_CUSTOM_START}
        noteColors={NOTE_COLORS}
        graphPalette={{
          background: graphPalette.background,
          grid: graphPalette.grid,
          axis: graphPalette.axis,
          label: graphPalette.label,
          labelStrong: graphPalette.labelStrong,
          point: graphPalette.point
        }}
      />
    {/key}
  {/if}

  <button
    type="button"
    class="absolute flex items-center justify-center rounded-md p-0 backdrop-blur-sm select-none"
    style={makeOverlayStyle(
      GRAPH_PADDING.left - 10 - NOTE_STEP_CONTROL_SIZE / 2,
      NOTE_STEP_CONTROL_TOP_INSET,
      NOTE_STEP_CONTROL_SIZE,
      NOTE_STEP_CONTROL_SIZE
    )}
    aria-label="Move bottom start note down"
    title="Move bottom start note down"
    onclick={() => stepBottomStartNote('down')}
    onmouseenter={(e) =>
      ((e.currentTarget as HTMLButtonElement).style.backgroundColor = graphPalette.buttonHoverBg)}
    onmouseleave={(e) =>
      ((e.currentTarget as HTMLButtonElement).style.backgroundColor = graphPalette.buttonBg)}
    style:background-color={graphPalette.buttonBg}
    style:color={graphPalette.buttonText}
    style:border={`1px solid ${graphPalette.buttonRing}`}
    style:box-shadow={graphPalette.overlayShadow}
  >
    <Icon src={BsChevronUp} class="text-sm" />
  </button>

  <button
    type="button"
    class="absolute flex items-center justify-center rounded-md p-0 backdrop-blur-sm select-none"
    style={makeOverlayStyle(
      GRAPH_PADDING.left - 10 - NOTE_STEP_CONTROL_SIZE / 2,
      VIEWBOX_H - NOTE_STEP_CONTROL_SIZE - NOTE_STEP_CONTROL_BOTTOM_INSET,
      NOTE_STEP_CONTROL_SIZE,
      NOTE_STEP_CONTROL_SIZE
    )}
    aria-label="Move bottom start note up"
    title="Move bottom start note up"
    onclick={() => stepBottomStartNote('up')}
    onmouseenter={(e) =>
      ((e.currentTarget as HTMLButtonElement).style.backgroundColor = graphPalette.buttonHoverBg)}
    onmouseleave={(e) =>
      ((e.currentTarget as HTMLButtonElement).style.backgroundColor = graphPalette.buttonBg)}
    style:background-color={graphPalette.buttonBg}
    style:color={graphPalette.buttonText}
    style:border={`1px solid ${graphPalette.buttonRing}`}
    style:box-shadow={graphPalette.overlayShadow}
  >
    <Icon src={BsChevronDown} class="text-sm" />
  </button>
</div>

{#if input_mode === 'mic'}
  <div class="mt-4 flex items-center justify-center space-x-3 sm:mt-5 sm:space-x-4 md:space-x-5">
    <button
      class={cl_join(
        'btn gap-0.5 rounded-md px-1.5 py-0.5 text-base font-bold text-white sm:gap-1 sm:rounded-lg sm:px-2 sm:py-1 sm:text-xl',
        graphPalette.pauseButton
      )}
      onclick={() => {
        paused_graph_data = { history: graphData };
        is_paused = !is_paused;
      }}
    >
      <Icon
        src={is_paused ? BsPlayFill : BsPauseFill}
        class="-mt-0.5 text-xl sm:-mt-1 sm:text-2xl"
      />
      {is_paused ? 'Play' : 'Pause'}
    </button>
    {@render stop_button()}
  </div>
{/if}
