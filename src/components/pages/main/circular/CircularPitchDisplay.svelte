<script lang="ts">
  import { cl_join } from '~/tools/cl_join';
  import { NOTES, SARGAM, type note_types } from '../constants';

  let {
    audio_info,
    Sa_at = $bindable(),
    sargam_orientation,
    note_orientation
  }: {
    audio_info: { clarity: number; detune: number; note: string; pitch: number; scale: number };
    Sa_at: note_types;
    sargam_orientation: 'radial' | 'vertical';
    note_orientation: 'radial' | 'vertical';
  } = $props();

  let Sa_at_index = $derived(NOTES.indexOf(Sa_at));

  const { detune, note: note_, scale } = $derived(audio_info);

  let note_index = $derived(NOTES.indexOf(note_ as note_types));

  let OUTER_CIRCLE_SARGAM_RADIUS = $derived(92 - (sargam_orientation === 'vertical' ? 0 : 1.1));
  let SARGAM_LABEL_RADIUS = $derived(80 + (sargam_orientation === 'vertical' ? 0.55 : 1.52));
  let INNER_CIRCLE_NOTE_RADIUS = 70;
  let NOTE_TICK_LENGTH = 5;
  let FREQUENCY_CIRCLE_RADIUS = 43;
  let NOTE_LABEL_RADIUS = $derived(54 + (note_orientation === 'vertical' ? 1.5 : 0.8));
  let MIDDLE_CIRCLE_RADIUS = 30;

  let NEEDLE_LINE_LENGTH = 75;

  const cents_to_rotation = (cents: number, note: string) => {
    // Get the base rotation for the note
    const baseRotation = (note_index - Sa_at_index) * 30; // 360/12 = 30 degrees per note

    // Add fine rotation from cents (-50 to +50 maps to ±15 degrees)
    const centsRotation = (cents / 50) * 15;

    // Return total rotation
    return baseRotation + centsRotation;
  };
  const is_in_tune = (cents: number) => Math.abs(cents) <= 6;
  const to_radians = (degrees: number) => (degrees * Math.PI) / 180;
  const get_sector_path = () => {
    const radius = OUTER_CIRCLE_SARGAM_RADIUS - 2;
    const RANGE = 15;

    const arc_x = radius * Math.cos(to_radians(90 - RANGE));
    const arc_y = radius * Math.sin(to_radians(90 + RANGE));
    const arc = `A ${radius} ${radius} 0 0 1 ${arc_x} ${-arc_y} L`;
    // format :- rx ry x-axis-rotation large-arc-flag sweep-flag x y
    // sweep-flag = 0 for clockwise, 1 for anti-clockwise
    // large-arc-flag = 0 for minor arc, 1 for major arc

    const arc_start_x = radius * Math.cos(to_radians(90 + RANGE));
    const arc_start_y = radius * Math.sin(to_radians(90 - RANGE));

    return `M 0 0 L ${arc_start_x} ${-arc_start_y} ${arc} Z`;
  };
</script>

<div class="h-72 w-72 sm:h-80 sm:w-80 md:h-96 md:w-96">
  <svg
    viewBox={`-${100} -${100} ${200} ${200}`}
    class="block h-full w-full outline-hidden select-none"
  >
    <!-- Outer circle for Sargam -->
    <circle
      cx="0"
      cy="0"
      r={OUTER_CIRCLE_SARGAM_RADIUS}
      fill="none"
      stroke="currentColor"
      stroke-width="1"
      class="opacity-70"
    />

    <!-- Inner circle for Notes -->
    <circle
      cx="0"
      cy="0"
      r={INNER_CIRCLE_NOTE_RADIUS}
      fill="none"
      stroke="currentColor"
      stroke-width="1"
    />

    <!-- Frequency circles -->
    <circle
      cx="0"
      cy="0"
      r={FREQUENCY_CIRCLE_RADIUS}
      fill="none"
      stroke="currentColor"
      stroke-width="0.5"
      class="opacity-70"
    />

    <!-- Note markers and labels -->
    <g
      class="origin-[0_0] transition-transform duration-500 ease-in-out"
      style="transform: rotate({-Sa_at_index * 30}deg)"
    >
      {#each NOTES as note, i}
        {@const angle = i * 30 - 90}
        {@const x = NOTE_LABEL_RADIUS * Math.cos(to_radians(angle))}
        {@const y = NOTE_LABEL_RADIUS * Math.sin(to_radians(angle))}
        <!-- Note tick -->
        <line
          x1="0"
          y1={-INNER_CIRCLE_NOTE_RADIUS}
          x2="0"
          y2={-(INNER_CIRCLE_NOTE_RADIUS - NOTE_TICK_LENGTH)}
          transform="rotate({angle})"
          stroke="currentColor"
          stroke-width="1.5"
        />
        <!-- Note label -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <text
          {x}
          {y}
          ondblclick={() => (Sa_at = note as note_types)}
          text-anchor="middle"
          dominant-baseline="middle"
          class={cl_join(
            'fill-zinc-700 text-[0.7rem] font-semibold dark:fill-zinc-300',
            'origin-[0_0] transition-transform duration-600 ease-in-out'
          )}
          transform={note_orientation === 'radial'
            ? `rotate(${angle + 90} ${x} ${y})`
            : `rotate(${Sa_at_index * 30} ${x} ${y})`}
        >
          {note}
        </text>
      {/each}
    </g>

    <g>
      <!-- Sargam labels -->
      {#each SARGAM as swar, i}
        {@const angle = i * (360 / SARGAM.length) - 90}
        {@const x = SARGAM_LABEL_RADIUS * Math.cos(to_radians(angle))}
        {@const y = SARGAM_LABEL_RADIUS * Math.sin(to_radians(angle))}
        <text
          {x}
          {y}
          text-anchor="middle"
          dominant-baseline="middle"
          class={cl_join(
            'fill-gray-800 text-xs font-semibold opacity-90 dark:fill-gray-200',
            'origin-[0_0] transition-transform duration-600 ease-in-out'
          )}
          font-family="ome_bhatkhande_en"
          {...sargam_orientation === 'radial'
            ? {
                transform: `rotate(${angle + 90} ${x} ${y})`
              }
            : {}}
        >
          {swar.key}
        </text>
      {/each}
    </g>

    <g>
      <!-- Fine tick marks for cents -->
      {#each Array(60) as _, i}
        {@const angle = i * 6 - 90}
        {@const is_major = i % 5 === 0}
        <line
          x1="0"
          y1={-INNER_CIRCLE_NOTE_RADIUS}
          x2="0"
          y2={-(is_major
            ? INNER_CIRCLE_NOTE_RADIUS - NOTE_TICK_LENGTH
            : INNER_CIRCLE_NOTE_RADIUS - Math.ceil(NOTE_TICK_LENGTH / 2))}
          transform="rotate({angle})"
          stroke="currentColor"
          stroke-width={is_major ? 1 : 0.5}
          class="opacity-70"
        />
        <!-- y2={isMajor ? -65 : -67} -->
      {/each}
    </g>

    <!-- Needle -->
    <g
      transform={`rotate(${detune ? cents_to_rotation(detune, note_) : 0})`}
      class={cl_join(
        '-z-10',
        'origin-[0_0] transition-transform duration-[300ms] ease-linear',
        !detune && 'opacity-50'
      )}
    >
      <line
        x1="0"
        y1="0"
        x2="0"
        y2={-NEEDLE_LINE_LENGTH}
        stroke-width="2"
        class={is_in_tune(detune)
          ? 'stroke-green-500 dark:stroke-green-500'
          : 'stroke-rose-500 dark:stroke-rose-500'}
      />
      <!-- stroke={isInTune(detune) ? '#22c55e' : '#ef4444'} -->
      <circle
        cx="0"
        cy={-NEEDLE_LINE_LENGTH}
        r="2"
        class={is_in_tune(detune)
          ? 'fill-green-500 dark:fill-green-500'
          : 'fill-rose-500 dark:fill-rose-500'}
      />
    </g>

    <!-- Sector -->
    <path
      d={get_sector_path()}
      transform={`rotate(${detune ? (note_index - Sa_at_index) * 30 : 0} 0 0)`}
      class={cl_join(
        'fill-black opacity-10 dark:fill-white dark:opacity-15',
        'origin-[0_0] transition-transform duration-[300ms] ease-linear',
        !detune && 'hidden'
      )}
    />

    <!-- Center display -->
    <!-- <circle cx="0" cy="0" r={MIDDLE_CIRCLE_RADIUS} class="fill-white opacity-60 dark:fill-black" /> -->
    {#if detune}
      <g x="0" y="-5">
        <text text-anchor="middle" class="fill-black text-base font-bold dark:fill-white">
          {note_}
          <tspan class="text-[0.6em]" dy="-0.1em">{scale !== 0 ? scale : ''}</tspan>
        </text>
      </g>
      <text x="0" y="12" text-anchor="middle" class="fill-black text-[0.52rem] dark:fill-white">
        {detune > 0 ? '+' : ''}{detune} cents
      </text>
    {/if}
  </svg>
</div>
