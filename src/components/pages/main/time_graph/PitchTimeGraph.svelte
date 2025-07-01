<script lang="ts">
  import type { Snippet } from 'svelte';
  import { NOTES, NOTES_STARTING_WITH_A, type note_types, SARGAM } from '../constants';
  import { cl_join } from '~/tools/cl_join';

  let {
    pitch_history,
    stop_button,
    MAX_PITCH_HISTORY_POINTS,
    AUDIO_INFO_UPDATE_INTERVAL,
    audio_info_scale,
    bottom_start_note = $bindable(),
    selected_Sa_at = $bindable()
  }: {
    pitch_history: Array<{
      time: number;
      pitch: number;
      note: string;
      clarity: number;
    }>;
    stop_button: Snippet;
    MAX_PITCH_HISTORY_POINTS: number;
    AUDIO_INFO_UPDATE_INTERVAL: number;
    audio_info_scale?: number;
    bottom_start_note: note_types;
    selected_Sa_at: note_types;
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

  const graphData = $derived(
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
              originalIndex: index
            }
          : null;
      })
      .filter((point): point is NonNullable<typeof point> => point !== null)
  );

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
          const isJump = (deltaPitch > 0 && deltaY > 0) || (deltaPitch < 0 && deltaY < 0);
          if (isJump) {
            norm.push(`M ${x} ${y}`);
            faint.push(`M ${prevX} ${prevY}`, `L ${x} ${y}`);
          } else {
            norm.push(`L ${x} ${y}`);
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
    <span class="text-xs font-semibold sm:text-sm">Sa at</span>
    <select
      class="select w-12 rounded-md border border-gray-300 px-2 py-0.5 text-xs sm:py-1 sm:text-sm"
      bind:value={selected_Sa_at}
    >
      {#each NOTES_STARTING_WITH_A as note}
        <option value={note}>{note}</option>
      {/each}
    </select>
  </div>
  <div class="flex items-center gap-x-2">
    <span class="text-xs font-semibold sm:text-sm">Bottom Start Note</span>
    <select
      class="select w-12 rounded-md border border-gray-300 px-2 py-0.5 text-xs sm:py-1 sm:text-sm"
      bind:value={bottom_start_note}
    >
      {#each NOTES_STARTING_WITH_A as note}
        <option value={note}>{note}</option>
      {/each}
    </select>
  </div>
</div>

<div class="mt-1 h-[250px] w-full sm:h-[350px] md:h-[500px] lg:h-[600px]">
  {#if graphData.length > 1}
    <!-- <h3 class="mb-4 text-lg font-semibold">Pitch Over Time</h3> -->
    <svg
      preserveAspectRatio="none"
      class="h-full w-full select-none"
      viewBox={`0 0 ${SVG_BACKGROUND.width} ${SVG_BACKGROUND.height}`}
    >
      <!-- Background -->
      <rect width={SVG_BACKGROUND.width} height={SVG_BACKGROUND.height} fill="transparent" />

      <!-- Grid lines for notes -->
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
          <circle cx={GRAPH_PADDING.left - 5} cy={y} r="2" fill={NOTE_COLORS[noteName] || '#ccc'} />
        {/if}
        <text
          x={GRAPH_PADDING.left - 10}
          y={y + 4}
          text-anchor="end"
          class="fill-gray-600 text-xs dark:fill-gray-400"
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

      <!-- Time grid lines -->
      <!-- {#each Array.from({ length: 6 }, (_, i) => i) as timeIndex}
        {@const x = (timeIndex / 5) * GRAPH_INFO.width + GRAPH_PADDING.left}
        <line
          x1={x}
          y1={GRAPH_PADDING.top}
          x2={x}
          y2={GRAPH_INFO.height + GRAPH_PADDING.top}
          stroke="#e5e7eb"
          stroke-width="1"
          opacity="0.3"
        />
      {/each} -->

      <!-- Data line & jump highlights -->
      {#if faintSegments.length}
        <path
          d={faintSegments.join(' ')}
          stroke="url(#noteGradient)"
          stroke-width="2"
          fill="none"
          opacity="0.4"
        />
      {/if}
      <path d={normalSegments.join(' ')} stroke="url(#noteGradient)" stroke-width="2" fill="none" />

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

      <!-- Current frequency display -->
      <circle cx={lastX} cy={lastY} r="4" fill="#ef4444" />
      <text
        x={indicatorX}
        y={indicatorY}
        text-anchor={textAnchor}
        class="fill-gray-800 text-xs font-medium opacity-85 dark:fill-gray-200"
      >
        {lastPoint.pitch.toFixed(1)} Hz ({lastPoint.note}{audio_info_scale})
      </text>

      <!-- Axes -->
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

      <!-- Y-axis label -->
      <!-- <text
        x={Y_AXIS_LABEL_TITLE_POS.x}
        y={Y_AXIS_LABEL_TITLE_POS.y}
        text-anchor="middle"
        transform="rotate(-90 {Y_AXIS_LABEL_TITLE_POS.x} {Y_AXIS_LABEL_TITLE_POS.y})"
        class="fill-gray-700 text-sm font-medium dark:fill-gray-300"
      >
        Notes
      </text> -->
    </svg>
  {/if}
</div>
{@render stop_button()}
