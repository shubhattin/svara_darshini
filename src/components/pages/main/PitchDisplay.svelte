<script lang="ts">
  import { cl_join } from '~/tools/cl_join';
  import { NOTES, SARGAM, type note_types } from './constants';

  let {
    audio_info,
    Sa_at,
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

  const cents_to_rotation = (cents: number, note: string) => {
    // Get the base rotation for the note
    const noteIndex = NOTES.indexOf(note);
    const baseRotation = (noteIndex - Sa_at_index) * 30; // 360/12 = 30 degrees per note

    // Add fine rotation from cents (-50 to +50 maps to ±15 degrees)
    const centsRotation = (cents / 50) * 15;

    // Return total rotation
    return baseRotation + centsRotation;
  };

  const is_in_tune = (cents: number) => Math.abs(cents) <= 5;

  const to_radians = (degrees: number) => (degrees * Math.PI) / 180;

  let OUTER_CIRCLE_SARGAM_RADIUS = $derived(92 - (sargam_orientation === 'vertical' ? 1.5 : 0));
  let INNER_CIRCLE_NOTE_RADIUS = 70;
  let NOTE_TICK_LENGTH = 5;
  let FREQUENCY_CIRCLE_RADIUS = 43;
  let NOTE_LABEL_RADIUS = $derived(54 + (note_orientation === 'vertical' ? 1.5 : 0));
  let SARGAM_LABEL_RADIUS = $derived(80 + (sargam_orientation === 'vertical' ? 1.5 : 0));
  let MIDDLE_CIRCLE_RADIUS = 30;

  let NEEDLE_LINE_LENGTH = 75;
</script>

<svg viewBox={`-${100} -${100} ${200} ${200}`} class="block h-full w-full">
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
      <text
        {x}
        {y}
        text-anchor="middle"
        dominant-baseline="middle"
        class={cl_join(
          'fill-black text-[0.7rem] font-semibold dark:fill-zinc-300',
          'duration-600 origin-[0_0] transition-transform ease-in-out'
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
          'fill-black text-xs font-semibold opacity-90 dark:fill-gray-200',
          'duration-600 origin-[0_0] transition-transform ease-in-out'
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
  <g transform={`rotate(${cents_to_rotation(detune, note_)})`} class="-z-10">
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

  <!-- Center display -->
  <circle cx="0" cy="0" r={MIDDLE_CIRCLE_RADIUS} class="fill-white opacity-60 dark:fill-black" />
  <text x="0" y="-5" text-anchor="middle" class="fill-black text-base font-bold dark:fill-white">
    {note_}{scale !== 0 ? scale : ''}
  </text>
  <text x="0" y="12" text-anchor="middle" class="fill-black text-[0.7rem] dark:fill-white">
    {detune > 0 ? '+' : ''}{detune} cents
  </text>
</svg>
