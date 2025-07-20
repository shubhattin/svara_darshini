<script lang="ts">
  import type { Snippet } from 'svelte';
  import { NOTES, NOTES_STARTING_WITH_A, type note_types, SARGAM } from '../constants';
  import { cl_join } from '~/tools/cl_join';
  import { Popover } from '@skeletonlabs/skeleton-svelte';
  import { BsChevronDown, BsChevronUp, BsPauseFill, BsPlayFill } from 'svelte-icons-pack/bs';
  import Icon from '~/tools/Icon.svelte';

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

  const SVG_BACKGROUND = {
    width: 800,
    height: 300
  } as const;

  const GRAPH_INFO = {
    width: 720,
    height: 280
  } as const; // without padding
  const GRAPH_PADDING = {
    top: 10,
    left: 60
  } as const;

  const NOTES_CUSTOM_START = $derived(
    NOTES.slice(NOTES.indexOf(bottom_start_note)).concat(
      NOTES.slice(0, NOTES.indexOf(bottom_start_note))
    )
  );
  const SARGAM_KEYS = SARGAM.map((sargam) => sargam.key);

  const SARGAM_CUSTOM_START = $derived.by(() => {
    const NOTES_INDEX = NOTES_CUSTOM_START.indexOf(selected_Sa_at);
    const new_arr: string[] = Array.from({ length: NOTES.length });
    for (let i = 0; i < NOTES.length; i++) {
      new_arr[(i + NOTES_INDEX) % NOTES.length] = SARGAM_KEYS[i];
    }
    return new_arr;
  });

  // Mapping of each note to a custom color for gradient encoding
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

  const get_x_pos_on_graph = (index: number) => {
    return (index / (MAX_PITCH_HISTORY_POINTS - 1)) * GRAPH_INFO.width + GRAPH_PADDING.left;
  };
  const get_y_pos_on_graph = (yRatio: number) => {
    return GRAPH_INFO.height + GRAPH_PADDING.top - yRatio * GRAPH_INFO.height;
  };

  // Convert frequency to y-position for graph based on semitone offset within one octave
  const frequencyToYPositionRatio = (frequency: number) => {
    // Validate input: must be a positive finite number
    if (!Number.isFinite(frequency) || frequency <= 0) {
      return null; // Return null for invalid frequencies
    }

    const A0_freq = 27.5;
    // Compute continuous semitone offset from A0
    const semitoneOffset = 12 * (Math.log(frequency / A0_freq) / Math.log(2));
    // Fractional semitone within one octave
    const semitoneInOctave = ((semitoneOffset % 12) + 12) % 12;
    // Shift semitone based on bottom_start_note baseline
    const baseIndex = NOTES_STARTING_WITH_A.indexOf(bottom_start_note);
    const semitoneRelative = (semitoneInOctave - baseIndex + 12) % 12;
    // Normalize so semitoneRelative 0 maps just above bottom axis, and max maps to top
    const normalized = ((semitoneRelative + 1) / 12) * 100;
    // Clamp to [0,100]
    return Math.min(Math.max(normalized, 0), 100) / 100;
  };

  const graphDataMain = $derived(
    pitch_history
      .map((point, index) => {
        const yPos = frequencyToYPositionRatio(point.pitch);
        return yPos !== null
          ? {
              // x: index * AUDIO_INFO_UPDATE_INTERVAL, // Time in milliseconds from start
              yRatio: yPos,
              pitch: point.pitch,
              note: point.note,
              clarity: point.clarity,
              originalIndex: index,
              scale: point.scale
            }
          : null;
      })
      .filter((point): point is NonNullable<typeof point> => point !== null)
  );
  let is_paused = $state(false);
  let paused_graph_data = $state<{
    history: typeof graphDataMain;
    audio_info_scale?: number;
  }>({
    history: [],
    audio_info_scale: undefined
  });
  let graphData = $derived(is_paused ? paused_graph_data.history : graphDataMain);

  // Helper function to create smooth curve control points
  const createCurveControlPoints = (
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    smoothing = 0.3
  ) => {
    // cubic bezier curve
    const dx = x2 - x1;
    const dy = y2 - y1;
    const controlPoint1X = x1 + dx * smoothing;
    const controlPoint1Y = y1;
    const controlPoint2X = x2 - dx * smoothing;
    const controlPoint2Y = y2;
    return { controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y };
  };

  // Compute normal and faint segments for jump highlights
  const [normalSegments, faintSegments] = $derived(
    graphData.reduce<[string[], string[]]>(
      ([norm, faint], point, index) => {
        const x = get_x_pos_on_graph(point.originalIndex);
        const y = get_y_pos_on_graph(point.yRatio);
        if (index === 0) {
          norm.push(`M ${x} ${y}`);
        } else {
          const prev = graphData[index - 1];
          const prevX = get_x_pos_on_graph(prev.originalIndex);
          const prevY = get_y_pos_on_graph(prev.yRatio);
          const deltaPitch = point.pitch - prev.pitch;
          const deltaY = y - prevY;
          // +ve deltaY : graph moved down
          // -ve deltaY : graph moved up
          // as in svg, y increases as we go down

          const isJump = (deltaPitch > 0 && deltaY > 0) || (deltaPitch < 0 && deltaY < 0);

          if (isJump) {
            norm.push(`M ${x} ${y}`);
            // Use smooth curve for faint segments too
            const { controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y } =
              createCurveControlPoints(prevX, prevY, x, y);
            faint.push(
              `M ${prevX} ${prevY}`,
              `C ${controlPoint1X} ${controlPoint1Y}, ${controlPoint2X} ${controlPoint2Y}, ${x} ${y}`
            );
          } else {
            // Create smooth curve for normal segments
            const { controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y } =
              createCurveControlPoints(prevX, prevY, x, y);
            norm.push(
              `C ${controlPoint1X} ${controlPoint1Y}, ${controlPoint2X} ${controlPoint2Y}, ${x} ${y}`
            );
            // for straight line
            // `L ${x} ${y}`;
          }
        }
        return [norm, faint];
      },
      [[], []] as [string[], string[]]
    )
  );

  // Reactive last point and its coordinates
  const lastPoint = $derived(graphData[graphData.length - 1]);
  const lastX = $derived(get_x_pos_on_graph(lastPoint.originalIndex));
  const lastY = $derived(get_y_pos_on_graph(lastPoint.yRatio));

  // Smart label positioning to avoid cropping
  const isRightSide = $derived(lastX > SVG_BACKGROUND.width * 0.85);
  const isNearTop = $derived(lastY < GRAPH_PADDING.top + 20);
  const indicatorX = $derived(isRightSide ? lastX - 10 : lastX + 10);
  const indicatorY = $derived(isNearTop ? lastY + 20 : lastY - 10);
  const textAnchor = $derived(isRightSide ? 'end' : 'start');
</script>

<div class="flex items-center justify-center gap-x-8 sm:gap-x-12 md:gap-x-16 lg:gap-x-20">
  <div class="flex items-center gap-x-2">
    <Popover
      open={Sa_at_popup_status}
      onOpenChange={(e) => (Sa_at_popup_status = e.open)}
      contentBase="card z-50 space-y-2 p-2 rounded-lg shadow-xl dark:bg-surface-900 bg-slate-100"
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
                selected_Sa_at === note
                  ? 'bg-primary-500 dark:bg-primary-600'
                  : 'bg-slate-400 hover:bg-primary-500/80 dark:bg-slate-800 dark:hover:bg-primary-600/80'
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
      contentBase="card z-50 space-y-2 p-2 rounded-lg shadow-xl dark:bg-surface-900 bg-slate-100"
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
                bottom_start_note === note
                  ? 'bg-primary-500 dark:bg-primary-600'
                  : 'bg-slate-400 hover:bg-primary-500/80 dark:bg-slate-800 dark:hover:bg-primary-600/80'
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

<div class={cl_join('mt-1 w-full', 'h-[250px] sm:h-[330px] md:h-[500px] lg:h-[570px]')}>
  {#if graphData.length > 0}
    <!-- <h3 class="mb-4 text-lg font-semibold">Pitch Over Time</h3> -->
    <svg
      preserveAspectRatio="none"
      class="h-full w-full select-none"
      viewBox={`0 0 ${SVG_BACKGROUND.width} ${SVG_BACKGROUND.height}`}
    >
      <!-- Background -->
      <rect width={SVG_BACKGROUND.width} height={SVG_BACKGROUND.height} fill="transparent" />

      <!-- Grid lines, notes & sargam labels -->
      <g>
        {#each Array.from({ length: 13 }, (_, i) => i) as noteIndex}
          {@const noteName = NOTES_CUSTOM_START[NOTES_CUSTOM_START.length - noteIndex - 1]}
          {@const y = (noteIndex / 12) * GRAPH_INFO.height + GRAPH_PADDING.top}
          <line
            x1={GRAPH_PADDING.left}
            y1={y}
            x2={GRAPH_PADDING.left + GRAPH_INFO.width}
            y2={y}
            stroke="#e5e7eb"
            stroke-width="1"
            opacity="0.5"
          />
          {#if noteName}
            <circle
              cx={GRAPH_PADDING.left - 5}
              cy={y}
              r="2"
              fill={NOTE_COLORS[noteName] || '#ccc'}
            />
          {/if}
          <text
            x={GRAPH_PADDING.left - 10}
            y={y + 4}
            text-anchor="end"
            class={cl_join(
              'fill-gray-600 text-xs dark:fill-gray-400',
              noteIndex === NOTES_CUSTOM_START.length - 1 && 'font-semibold '
            )}
          >
            {noteName}
          </text>
          <!-- Sargam  -->
          {@const sargam_key = SARGAM_CUSTOM_START[SARGAM_CUSTOM_START.length - noteIndex - 1]}
          <text
            x={GRAPH_PADDING.left - 30}
            y={y + 4}
            text-anchor="end"
            class={cl_join(
              'fill-gray-600 text-xs dark:fill-gray-400',
              sargam_key === 's' && 'fill-slate-500 font-semibold dark:fill-slate-200'
            )}
            font-family="ome_bhatkhande_en"
          >
            {sargam_key}
          </text>
        {/each}
      </g>

      <!-- Data line & jump highlights -->
      <g>
        {#if faintSegments.length}
          <path
            d={faintSegments.join(' ')}
            stroke="url(#noteGradient)"
            stroke-width="2"
            fill="none"
            opacity="0.3"
          />
        {/if}
        <path
          d={normalSegments.join(' ')}
          stroke="url(#noteGradient)"
          stroke-width="2"
          fill="none"
        />

        <defs>
          <linearGradient
            id="noteGradient"
            gradientUnits="userSpaceOnUse"
            x1="0"
            y1={GRAPH_PADDING.top + GRAPH_INFO.height}
            x2="0"
            y2={GRAPH_PADDING.top}
          >
            {#each NOTES_CUSTOM_START as note, idx}
              {@const offset = (idx / (NOTES_CUSTOM_START.length - 1)) * 100}
              <stop offset={`${offset}%`} stop-color={NOTE_COLORS[note]} />
            {/each}
          </linearGradient>
        </defs>
      </g>

      <!-- Current frequency display -->
      <g>
        <circle cx={lastX} cy={lastY} r="4" fill="#ef4444" />
        <text
          x={indicatorX}
          y={indicatorY}
          text-anchor={textAnchor}
          class="fill-gray-800 text-xs font-medium opacity-85 dark:fill-gray-200"
        >
          {lastPoint.pitch.toFixed(1)} Hz ({lastPoint.note}{lastPoint.scale})
        </text>
      </g>

      <!-- Axes -->
      <g>
        <line
          x1={GRAPH_PADDING.left}
          y1={GRAPH_PADDING.top}
          x2={GRAPH_PADDING.left}
          y2={GRAPH_INFO.height + GRAPH_PADDING.top}
          stroke="#374151"
          stroke-width="2"
        />
        <line
          x1={GRAPH_PADDING.left}
          y1={GRAPH_INFO.height + GRAPH_PADDING.top}
          x2={GRAPH_INFO.width + GRAPH_PADDING.left}
          y2={GRAPH_INFO.height + GRAPH_PADDING.top}
          stroke="#374151"
          stroke-width="1"
        />
      </g>
    </svg>
  {/if}
</div>
{#if input_mode === 'mic'}
  <div class="mt-4 flex items-center justify-center space-x-3 sm:mt-5 sm:space-x-4 md:space-x-5">
    <button
      class="btn gap-1 rounded-lg bg-primary-600 px-2 py-1 text-xl font-bold text-white dark:bg-primary-500"
      onclick={() => {
        paused_graph_data = { history: graphData };
        is_paused = !is_paused;
      }}
    >
      <Icon src={is_paused ? BsPlayFill : BsPauseFill} class="-mt-1 text-2xl" />
      {is_paused ? 'Play' : 'Pause'}
    </button>
    {@render stop_button()}
  </div>
{/if}
