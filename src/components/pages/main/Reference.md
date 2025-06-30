# Reference

## [`constants.ts`](./constants.ts)

### Constants

#### `NOTES`

Array of all 12 chromatic notes in Western music theory, representing one octave:

```typescript
['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
```

We start with C because it is the first note of the C major scale, which is the most commonly used scale in Western music. It is a common standard

**How it works:**

- A4 (440 Hz) → `getNoteNumberFromPitch(440)` → MIDI note 69
- Array lookup: `NOTES[69 % 12]` → `NOTES[9]` → `'A'` ✓ Correct!
- The modulo operation `% 12` ensures proper cyclical mapping regardless of starting note

**Index Mapping Table**

| Index | Note  | MIDI Example | Frequency (Hz) |
| ----- | ----- | ------------ | -------------- |
| 0     | C     | C4 = 60      | 261.63         |
| 1     | C#    | C#4 = 61     | 277.18         |
| 2     | D     | D4 = 62      | 293.66         |
| 3     | D#    | D#4 = 63     | 311.13         |
| 4     | E     | E4 = 64      | 329.63         |
| 5     | F     | F4 = 65      | 349.23         |
| 6     | F#    | F#4 = 66     | 369.99         |
| 7     | G     | G4 = 67      | 392.00         |
| 8     | G#    | G#4 = 68     | 415.30         |
| 9     | **A** | **A4 = 69**  | **440.00**     |
| 10    | A#    | A#4 = 70     | 466.16         |
| 11    | B     | B4 = 71      | 493.88         |

**Function Implementation**:

- `getNoteNumberFromPitch` : As this is a logoraithmic function and does not depend on the position of _C_ in the array, so it is independent of the array initialisation.
- `NOTES[noteNumber % 12]` : This is the note name for the given note number. This **does** depend on the position of _C_ in the array.

### Mathematical Functions

#### `getNoteNumberFromPitch`

**Purpose**: Converts frequency (Hz) to MIDI note number using equal temperament tuning.

**Mathematical Formula**:

```
note_number = 12 × log₂(frequency / 440) + 69
```

**Derivation**:

- Based on equal temperament where each semitone has frequency ratio of 2^(1/12)
- A4 (440 Hz) is MIDI note 69 (reference point)
- For any frequency f, the number of semitones above/below A4 is: `12 × log₂(f / 440)`
- Adding 69 gives the absolute MIDI note number

#### `getNoteFrequency`

**Purpose**: Converts MIDI note number to frequency (Hz) using equal temperament tuning. Inverse of `getNoteNumberFromPitch`

**Mathematical Formula**:

```
frequency = 440 × 2^((note - 69) / 12)
```

### MIDI and the Significance of Note 69

#### What is MIDI?

**MIDI** (Musical Instrument Digital Interface) is a technical standard that describes a communications protocol, digital interface, and electrical connectors that connect a wide variety of electronic musical instruments, computers, and related audio equipment.

#### MIDI Note Number System

**Range**: MIDI supports notes 0-127 (128 total notes, 7-bit value)

**Octave Structure**:

```
Octave -1: Notes 0-11   (C-1 to B-1)    - Sub-audio range
Octave  0: Notes 12-23  (C0 to B0)      - Deep bass
Octave  1: Notes 24-35  (C1 to B1)      - Bass
Octave  2: Notes 36-47  (C2 to B2)      - Bass/Baritone
Octave  3: Notes 48-59  (C3 to B3)      - Tenor/Alto
Octave  4: Notes 60-71  (C4 to B4)      - Middle range
Octave  5: Notes 72-83  (C5 to B5)      - Soprano
Octave  6: Notes 84-95  (C6 to B6)      - High soprano
Octave  7: Notes 96-107 (C7 to B7)      - Piccolo range
Octave  8: Notes 108-119 (C8 to B8)     - Ultra-high
Octave  9: Notes 120-127 (C9 to G9)     - Extreme high
```

**Key Reference Points**:

- **Note 0**: C-1 = 8.18 Hz (below human hearing)
- **Note 21**: A0 = 27.50 Hz (lowest A on piano)
- **Note 60**: C4 = 261.63 Hz (Middle C)
- **Note 69**: A4 = 440.00 Hz (Concert pitch standard)
- **Note 108**: C8 = 4186.01 Hz (highest C on piano)
- **Note 127**: G9 = 12543.85 Hz (MIDI maximum)

#### Instrument Ranges in MIDI Notes

**Piano**: Notes 21-108 (A0 to C8) - 88 keys
**Guitar**: Notes 40-84 (E2 to C6) - Standard tuning
**Human Voice**:

- Bass: Notes 41-65 (F2 to F4)
- Tenor: Notes 48-72 (C3 to C5)
- Alto: Notes 55-79 (G3 to G5)
- Soprano: Notes 60-84 (C4 to C6)

**Violin**: Notes 55-96+ (G3 to C7+)
**Flute**: Notes 60-96 (C4 to C7)

### Mathematical Relationships

#### Equal Temperament

Both functions implement the **12-tone equal temperament** system where:

- An octave is divided into 12 equal semitones
- Frequency ratio between adjacent semitones: `2^(1/12) ≈ 1.05946`
- Frequency doubles every 12 semitones (one octave)

#### Logarithmic Nature of Pitch Perception

- Human pitch perception is logarithmic, not linear
- Equal frequency ratios sound like equal musical intervals
- This is why we use logarithms in the conversion formulas
