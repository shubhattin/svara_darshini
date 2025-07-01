<script lang="ts">
  import type { Snippet } from 'svelte';
  import { NOTES_STARTING_WITH_A } from '../constants';

  let {
    pitch_history,
    stop_button,
    MAX_PITCH_HISTORY_POINTS,
    AUDIO_INFO_UPDATE_INTERVAL,
    audio_info_scale
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
  } = $props();

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
    // Normalize so semitone 0 (A) maps just above axis, and semitone 11 (G#) maps to top
    const normalized = ((semitoneInOctave + 1) / 12) * 100;
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

  const Y_AXIS_LABEL_TITLE_POS = { y: 150, x: 20 } as const;
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

  const get_x_pos_on_graph = (index: number) => {
    return (index / (MAX_PITCH_HISTORY_POINTS - 1)) * GRAPH_INFO.width + GRAPH_PADDING.left;
  };
  const get_y_pos_on_graph = (yRatio: number) => {
    return GRAPH_INFO.height + GRAPH_PADDING.top - yRatio * GRAPH_INFO.height;
  };

  // Mapping of each note to a custom color for gradient encoding
  const NOTE_COLORS: Record<string, string> = {
    A: '#ff0000',
    'A#': '#ff7f00',
    B: '#ffff00',
    C: '#7fff00',
    'C#': '#00ff00',
    D: '#00ff7f',
    'D#': '#00ffff',
    E: '#007fff',
    F: '#0000ff',
    'F#': '#7f00ff',
    G: '#ff00ff',
    'G#': '#ff007f'
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
</script>

<!-- <div class="flex items-center justify-center">
  <div
    class=" mr-4 rounded-lg bg-gradient-to-r from-amber-600 via-orange-700 to-red-600 px-3 py-1 text-sm font-bold text-white select-none"
  >
    Alpha
  </div>
</div> -->
<div class="mt-2 h-[250px] w-full sm:h-[350px] md:h-[500px] lg:h-[600px]">
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
        <text
          x={GRAPH_PADDING.left - 10}
          y={y + 4}
          text-anchor="end"
          class="fill-gray-600 text-xs dark:fill-gray-400"
        >
          {NOTES_STARTING_WITH_A[12 - noteIndex - 1] || ''}
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
          {#each NOTES_STARTING_WITH_A as note, idx}
            {@const offset = (idx / (NOTES_STARTING_WITH_A.length - 1)) * 100}
            <stop offset={`${offset}%`} stop-color={NOTE_COLORS[note]} />
          {/each}
        </linearGradient>
      </defs>

      <!-- Current frequency display -->
      <circle cx={lastX} cy={lastY} r="4" fill="#ef4444" />
      <text
        x={lastX + 10}
        y={lastY - 10}
        class="fill-gray-800 text-sm font-medium dark:fill-gray-200"
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
      <text
        x={Y_AXIS_LABEL_TITLE_POS.x}
        y={Y_AXIS_LABEL_TITLE_POS.y}
        text-anchor="middle"
        transform="rotate(-90 {Y_AXIS_LABEL_TITLE_POS.x} {Y_AXIS_LABEL_TITLE_POS.y})"
        class="fill-gray-700 text-sm font-medium dark:fill-gray-300"
      >
        Notes
      </text>
    </svg>
  {/if}
</div>
{@render stop_button()}
