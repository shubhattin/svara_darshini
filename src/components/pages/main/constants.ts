export const NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

export const PURE_NOTES = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

export const SARGAM = ['Sa', 'Re', 'Ga', 'Ma', 'Pa', 'Dha', 'Ni'];

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
