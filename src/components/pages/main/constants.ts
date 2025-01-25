const NOTES_ = {
  C: null,
  'C#': null,
  D: null,
  'D#': null,
  E: null,
  F: null,
  'F#': null,
  G: null,
  'G#': null,
  A: null,
  'A#': null,
  B: null
};
export type note_types = keyof typeof NOTES_;
export const NOTES = Object.keys(NOTES_);

export const PURE_NOTES = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

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

export const PURE_SARGAM = ['Sa', 'Re', 'Ga', 'Ma', 'Pa', 'Dha', 'Ni'];

// function to generate NOTES to sa re ga ma pa dha ni mapping from base note, no half steps
// Sa to Re - 2 half steps
// Re to Ga - 2 half steps
// Ga to Ma - 1 half steps
// Ma to Pa - 2 half steps
// Pa to Dha - 2 half steps
// Dha to Ni - 2 half steps
// Ni to Sa - 1 half steps

//eg : notesToSargam("A") => ["A", "B", "C#", "D", "E", "F#", "G#"]

export const notesToSargam = (baseNote: string) => {
  const baseNoteIndex = NOTES.indexOf(baseNote);
  const sargam = [];
  sargam.push(NOTES[baseNoteIndex]);
  sargam.push(NOTES[(baseNoteIndex + 2) % 12]);
  sargam.push(NOTES[(baseNoteIndex + 4) % 12]);
  sargam.push(NOTES[(baseNoteIndex + 5) % 12]);
  sargam.push(NOTES[(baseNoteIndex + 7) % 12]);
  sargam.push(NOTES[(baseNoteIndex + 9) % 12]);
  sargam.push(NOTES[(baseNoteIndex + 11) % 12]);
  return sargam;
};

export const getSargamForNote = (note: string, scale: string) => {
  // create an array by moving all notes before scale to infront
  const notes = notesToSargam(scale);
  const noteIndex = notes.indexOf(note);
  return SARGAM[noteIndex];
};
