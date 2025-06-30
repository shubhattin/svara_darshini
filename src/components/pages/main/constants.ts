export const NOTES_STARTING_WITH_A = [
  'A',
  'A#',
  'B',
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#'
] as const;
export const NOTES_STARTING_WITH_C = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B'
] as const;
export const NOTES = NOTES_STARTING_WITH_C;
export type note_types = (typeof NOTES)[number];

export const SARGAM: { name: string; key: string }[] = [
  { name: 'Sa', key: 's' },
  { name: 'Flat Re', key: 'R' },
  { name: 'Re', key: 'r' },
  { name: 'Flat G', key: 'G' },
  { name: 'Ga', key: 'g' },
  { name: 'Ma', key: 'm' },
  { name: 'Sharp Ma', key: 'M' },
  { name: 'Pa', key: 'p' },
  { name: 'Flat Dha', key: 'D' },
  { name: 'Dha', key: 'd' },
  { name: 'Flat Ni', key: 'N' },
  { name: 'Ni', key: 'n' }
];

export const getNoteNumberFromPitch = (frequency: number) => {
  const noteNum = 12 * (Math.log(frequency / 440) / Math.log(2));
  return Math.round(noteNum) + 69;
};

export const getNoteFrequency = (note: number) => {
  return 440 * Math.pow(2, (note - 69) / 12);
};

export const getScaleFromNoteNumber = (noteNumber: number) => {
  return Math.floor(noteNumber / 12) - 1;
};

export const getDetuneFromPitch = (pitch: number, noteNumber: number) => {
  return Math.floor((1200 * Math.log(pitch / getNoteFrequency(noteNumber))) / Math.log(2));
};

// export const PURE_NOTES = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
// export const PURE_SARGAM = ['Sa', 'Re', 'Ga', 'Ma', 'Pa', 'Dha', 'Ni'];
// function to generate NOTES to sa re ga ma pa dha ni mapping from base note, no half steps
// Sa to Re - 2 half steps
// Re to Ga - 2 half steps
// Ga to Ma - 1 half steps
// Ma to Pa - 2 half steps
// Pa to Dha - 2 half steps
// Dha to Ni - 2 half steps
// Ni to Sa - 1 half steps
// eg : notesToSargam("A") => ["A", "B", "C#", "D", "E", "F#", "G#"]
// export const notesToSargam = (baseNote: string) => {
//   const baseNoteIndex = NOTES.indexOf(baseNote as note_types);
//   const sargam = [];
//   sargam.push(NOTES[baseNoteIndex]);
//   sargam.push(NOTES[(baseNoteIndex + 2) % 12]);
//   sargam.push(NOTES[(baseNoteIndex + 4) % 12]);
//   sargam.push(NOTES[(baseNoteIndex + 5) % 12]);
//   sargam.push(NOTES[(baseNoteIndex + 7) % 12]);
//   sargam.push(NOTES[(baseNoteIndex + 9) % 12]);
//   sargam.push(NOTES[(baseNoteIndex + 11) % 12]);
//   return sargam;
// };

// export const getSargamForNote = (note: string, scale: string) => {
//   // create an array by moving all notes before scale to infront
//   const notes = notesToSargam(scale);
//   const noteIndex = notes.indexOf(note);
//   return SARGAM[noteIndex];
// };
