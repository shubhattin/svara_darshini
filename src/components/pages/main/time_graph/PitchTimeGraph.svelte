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

  const Y_AXIS_LABEL_TITLE_POS = { y: 150, x: 20 };
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
      <svg class="h-80 w-full" viewBox="0 0 800 300">
        <!-- Background -->
        <rect width="800" height="300" fill="transparent" />

        <!-- Grid lines for notes -->
        {#each Array.from({ length: 13 }, (_, i) => i) as noteIndex}
          {@const y = (noteIndex / 12) * 240 + 30}
          <line x1="60" y1={y} x2="780" y2={y} stroke="#e5e7eb" stroke-width="1" opacity="0.5" />
          <text x="50" y={y + 4} text-anchor="end" class="fill-gray-600 text-xs dark:fill-gray-400">
            {NOTES_STARTING_WITH_A[12 - noteIndex - 1] || ''}
          </text>
        {/each}

        <!-- Time grid lines -->
        {#each Array.from({ length: 6 }, (_, i) => i) as timeIndex}
          {@const x = (timeIndex / 5) * 720 + 60}
          <line x1={x} y1="30" x2={x} y2="270" stroke="#e5e7eb" stroke-width="1" opacity="0.3" />
        {/each}

        <!-- Data line -->
        {#if graphData.length > 1}
          {@const pathData = graphData
            .map((point, index) => {
              const x = (point.originalIndex / (MAX_PITCH_HISTORY_POINTS - 1)) * 720 + 60;
              const y = 270 - (point.y / 100) * 240;
              return index === 0 ? `M ${x} ${y}` : `L ${x} ${y}`;
            })
            .join(' ')}
          <path d={pathData} stroke="#3b82f6" stroke-width="2" fill="none" />

          <!-- Current frequency display -->
          {@const lastPoint = graphData[graphData.length - 1]}
          {@const lastX = (lastPoint.originalIndex / (MAX_PITCH_HISTORY_POINTS - 1)) * 720 + 60}
          {@const lastY = 270 - (lastPoint.y / 100) * 240}
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
        <line x1="60" y1="30" x2="60" y2="270" stroke="#374151" stroke-width="2" />
        <line x1="60" y1="270" x2="780" y2="270" stroke="#374151" stroke-width="2" />

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
