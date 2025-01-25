<script lang="ts">
  import { NOTES, SARGAM } from './constants';

  let {
    clarity,
    detune,
    note,
    pitch,
    scale
  }: { clarity: number; detune: number; note: string; pitch: number; scale: number } = $props();

  const centsToRotation = (cents: number, note: string) => {
    // Get the base rotation for the note
    const noteIndex = NOTES.indexOf(note);
    const baseRotation = noteIndex * 30; // 360/12 = 30 degrees per note

    // Add fine rotation from cents (-50 to +50 maps to ±15 degrees)
    const centsRotation = (cents / 50) * 15;

    // Return total rotation
    return baseRotation + centsRotation;
  };

  const isInTune = (cents: number) => Math.abs(cents) <= 5;
</script>

<svg viewBox="-100 -100 200 200" class="h-full w-full">
  <!-- Outer circle for Sargam -->
  <circle
    cx="0"
    cy="0"
    r="90"
    fill="none"
    stroke="currentColor"
    stroke-width="1"
    class="opacity-20"
  />

  <!-- Inner circle for Notes -->
  <circle cx="0" cy="0" r="70" fill="none" stroke="currentColor" stroke-width="1" />

  <!-- Frequency circles -->
  <circle
    cx="0"
    cy="0"
    r="50"
    fill="none"
    stroke="currentColor"
    stroke-width="0.5"
    class="opacity-50"
  />

  <!-- Note markers and labels -->
  {#each NOTES as note, i}
    {@const angle = i * 30 - 90}
    <!-- Start from top (-90 deg) -->
    <!-- Note tick -->
    <line
      x1="0"
      y1="-70"
      x2="0"
      y2="-65"
      transform="rotate({angle})"
      stroke="currentColor"
      stroke-width="1.5"
    />
    <!-- Note label -->
    <text
      x={50 * Math.cos((angle * Math.PI) / 180)}
      y={50 * Math.sin((angle * Math.PI) / 180)}
      text-anchor="middle"
      dominant-baseline="middle"
      class="fill-black text-xs font-semibold dark:fill-white"
      transform={`rotate(${angle + 90} ${50 * Math.cos((angle * Math.PI) / 180)} ${50 * Math.sin((angle * Math.PI) / 180)})`}
    >
      {note}
    </text>
  {/each}

  <!-- Sargam labels -->
  {#each SARGAM as swar, i}
    {@const angle = i * (360 / 7) - 90}
    <text
      x={85 * Math.cos((angle * Math.PI) / 180)}
      y={85 * Math.sin((angle * Math.PI) / 180)}
      text-anchor="middle"
      dominant-baseline="middle"
      class="fill-black text-xs font-medium opacity-90 dark:fill-white"
      transform={`rotate(${angle + 90} ${85 * Math.cos((angle * Math.PI) / 180)} ${85 * Math.sin((angle * Math.PI) / 180)})`}
    >
      {swar}
    </text>
  {/each}

  <!-- Fine tick marks for cents -->
  {#each Array(60) as _, i}
    {@const angle = i * 6 - 90}
    {@const isMajor = i % 5 === 0}
    <line
      x1="0"
      y1="-70"
      x2="0"
      y2={isMajor ? -65 : -67}
      transform="rotate({angle})"
      stroke="currentColor"
      stroke-width={isMajor ? 1 : 0.5}
      class="opacity-70"
    />
  {/each}

  <!-- Needle -->
  <g transform={`rotate(${centsToRotation(detune, note)})`}>
    <line
      x1="0"
      y1="0"
      x2="0"
      y2="-60"
      stroke={isInTune(detune) ? '#22c55e' : '#ef4444'}
      stroke-width="2"
    />
    <circle cx="0" cy="-60" r="2" fill={isInTune(detune) ? '#22c55e' : '#ef4444'} />
  </g>

  <!-- Center display -->
  <circle cx="0" cy="0" r="30" class="fill-white opacity-90 dark:fill-black" />
  <text x="0" y="-10" text-anchor="middle" class="text-md fill-black font-bold dark:fill-white">
    {note}{scale !== 0 ? scale : ''}
  </text>
  <text x="0" y="10" text-anchor="middle" class="fill-black text-xs dark:fill-white">
    {detune > 0 ? '+' : ''}{detune} cents
  </text>
</svg>
