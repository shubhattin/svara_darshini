/// Music theory constants and pitch calculation utilities for Svara Darshini.

import 'dart:math';

/// Notes starting with A (used for time graph bottom note selection)
const List<String> notesStartingWithA = [
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
  'G#',
];

/// Notes starting with C (default note ordering)
const List<String> notesStartingWithC = [
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
  'B',
];

/// Default note list (starting with C)
const List<String> notes = notesStartingWithC;

/// Sargam notation mapping (Indian classical music)
class SargamNote {
  final String name;
  final String key;

  const SargamNote(this.name, this.key);
}

const List<SargamNote> sargam = [
  SargamNote('Sa', 's'),
  SargamNote('Flat Re', 'R'),
  SargamNote('Re', 'r'),
  SargamNote('Flat Ga', 'G'),
  SargamNote('Ga', 'g'),
  SargamNote('Ma', 'm'),
  SargamNote('Sharp Ma', 'M'),
  SargamNote('Pa', 'p'),
  SargamNote('Flat Dha', 'D'),
  SargamNote('Dha', 'd'),
  SargamNote('Flat Ni', 'N'),
  SargamNote('Ni', 'n'),
];

/// Color mapping for each note (used in gradient visualization)
const Map<String, int> noteColors = {
  'A': 0xFFFF0000, // hsla(0, 100%, 50%, 1)
  'A#': 0xFFFF8000, // hsla(30, 100%, 50%, 1)
  'B': 0xFFFFFF00, // hsla(60, 100%, 50%, 1)
  'C': 0xFF80FF00, // hsla(90, 100%, 50%, 1)
  'C#': 0xFF00FF00, // hsla(120, 100%, 50%, 1)
  'D': 0xFF00FF80, // hsla(150, 100%, 50%, 1)
  'D#': 0xFF00FFFF, // hsla(180, 100%, 50%, 1)
  'E': 0xFF0080FF, // hsla(210, 100%, 50%, 1)
  'F': 0xFF0000FF, // hsla(240, 100%, 50%, 1)
  'F#': 0xFF8000FF, // hsla(270, 100%, 50%, 1)
  'G': 0xFFFF00FF, // hsla(300, 100%, 50%, 1)
  'G#': 0xFFFF0080, // hsla(330, 100%, 50%, 1)
};

/// Get MIDI note number from frequency
/// Reference: A4 = 440Hz = MIDI 69
int getNoteNumberFromPitch(double frequency) {
  if (frequency <= 0) return 0;
  final noteNum = 12 * (log(frequency / 440) / log(2));
  return noteNum.round() + 69;
}

/// Get frequency from MIDI note number
double getNoteFrequency(int noteNumber) {
  return 440.0 * pow(2, (noteNumber - 69) / 12).toDouble();
}

/// Get octave/scale number from MIDI note number
int getScaleFromNoteNumber(int noteNumber) {
  return (noteNumber / 12).floor() - 1;
}

/// Get detune in cents from pitch and note number
int getDetuneFromPitch(double pitch, int noteNumber) {
  if (pitch <= 0) return 0;
  return ((1200 * log(pitch / getNoteFrequency(noteNumber))) / log(2)).floor();
}

/// Get note name from MIDI note number
String getNoteNameFromNumber(int noteNumber) {
  return notes[noteNumber % 12];
}

/// Audio info update interval in milliseconds
const int audioInfoUpdateInterval = 100;

/// Graph total time in milliseconds
const int graphTotalTimeMs = 8000;

/// Maximum pitch history points (8 seconds at 100ms intervals)
const int maxPitchHistoryPoints = graphTotalTimeMs ~/ audioInfoUpdateInterval;

/// FFT size for pitch detection
const int fftSize = 4096;
