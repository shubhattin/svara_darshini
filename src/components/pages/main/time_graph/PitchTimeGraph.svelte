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
  const frequencyToYPosition = (frequency: number) => {
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
    return Math.min(Math.max(normalized, 0), 100);
  };

  const graphData = $derived(
    pitch_history
      .map((point, index) => {
        const yPos = frequencyToYPosition(point.pitch);
        return yPos !== null
          ? {
              x: index * AUDIO_INFO_UPDATE_INTERVAL, // Time in milliseconds from start
              y: yPos,
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
    height: 240
  } as const; // without padding
  const GRAPH_PADDING = {
    top: 30,
    left: 60
  } as const;
</script>

<div class="flex items-center justify-center">
  <div
    class=" mr-4 rounded-lg bg-gradient-to-r from-amber-600 via-orange-700 to-red-600 px-3 py-1 text-sm font-bold text-white select-none"
  >
    Alpha
  </div>
</div>
<div class="mt-4 h-96 w-full">
  {#if graphData.length > 1}
    <div class="">
      <!-- <h3 class="mb-4 text-lg font-semibold">Pitch Over Time</h3> -->
      <svg
        class="h-80 w-full select-none"
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
        {#each Array.from({ length: 6 }, (_, i) => i) as timeIndex}
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
        {/each}

        <!-- Data line -->
        {#if graphData.length > 1}
          {@const [normalSegments, faintSegments] = graphData.reduce<[string[], string[]]>(
            ([norm, faint], point, index) => {
              const x =
                (point.originalIndex / (MAX_PITCH_HISTORY_POINTS - 1)) * GRAPH_INFO.width +
                GRAPH_PADDING.left;
              const y = GRAPH_INFO.height + GRAPH_PADDING.top - (point.y / 100) * GRAPH_INFO.height;

              if (index === 0) {
                norm.push(`M ${x} ${y}`);
              } else {
                const prev = graphData[index - 1];
                const prevX =
                  (prev.originalIndex / (MAX_PITCH_HISTORY_POINTS - 1)) * GRAPH_INFO.width +
                  GRAPH_PADDING.left;
                const prevY =
                  GRAPH_INFO.height + GRAPH_PADDING.top - (prev.y / 100) * GRAPH_INFO.height;
                const deltaPitch = point.pitch - prev.pitch;
                const deltaY = y - prevY;
                const isJump = (deltaPitch > 0 && deltaY > 0) || (deltaPitch < 0 && deltaY < 0);
                if (isJump) {
                  // break the normal line and add a faint jump segment
                  norm.push(`M ${x} ${y}`);
                  faint.push(`M ${prevX} ${prevY}`, `L ${x} ${y}`);
                } else {
                  norm.push(`L ${x} ${y}`);
                }
              }
              return [norm, faint];
            },
            [[], []] as [string[], string[]]
          )}
          {#if faintSegments.length}
            <path
              d={faintSegments.join(' ')}
              stroke="#3b82f6"
              stroke-width="2"
              fill="none"
              opacity="0.3"
            />
          {/if}
          <path d={normalSegments.join(' ')} stroke="#3b82f6" stroke-width="2" fill="none" />

          <!-- Current frequency display -->
          {@const lastPoint = graphData[graphData.length - 1]}
          {@const lastX =
            (lastPoint.originalIndex / (MAX_PITCH_HISTORY_POINTS - 1)) * GRAPH_INFO.width +
            GRAPH_PADDING.left}
          {@const lastY =
            GRAPH_INFO.height + GRAPH_PADDING.top - (lastPoint.y / 100) * GRAPH_INFO.height}
          <circle cx={lastX} cy={lastY} r="4" fill="#ef4444" />
          <text
            x={lastX + 10}
            y={lastY - 10}
            class="fill-gray-800 text-sm font-medium dark:fill-gray-200"
          >
            {lastPoint.pitch.toFixed(1)} Hz ({lastPoint.note}{audio_info_scale})
          </text>
        {/if}

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
    </div>
    {@render stop_button()}
  {/if}
</div>
