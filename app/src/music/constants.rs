use std::fmt;

/// All 12 chromatic notes starting from C (MIDI convention).
/// C is index 0 because MIDI note 0 is C-1 and `note_number % 12` yields
/// the correct index when the array starts at C.
pub const NOTES_STARTING_WITH_C: [NoteType; 12] = [
    NoteType::C,
    NoteType::CSharp,
    NoteType::D,
    NoteType::DSharp,
    NoteType::E,
    NoteType::F,
    NoteType::FSharp,
    NoteType::G,
    NoteType::GSharp,
    NoteType::A,
    NoteType::ASharp,
    NoteType::B,
];

/// All 12 chromatic notes starting from A.
/// Used for UI selectors and Y-axis alignment (A0 = 27.5 Hz is the
/// natural base for semitone-offset calculations).
pub const NOTES_STARTING_WITH_A: [NoteType; 12] = [
    NoteType::A,
    NoteType::ASharp,
    NoteType::B,
    NoteType::C,
    NoteType::CSharp,
    NoteType::D,
    NoteType::DSharp,
    NoteType::E,
    NoteType::F,
    NoteType::FSharp,
    NoteType::G,
    NoteType::GSharp,
];

/// The primary note array used for MIDI → note-name lookups.
pub const NOTES: [NoteType; 12] = NOTES_STARTING_WITH_C;

/// Indian Sargam notation mapped to semitone offsets from Sa.
/// Each entry is (full name, short key used on the graph).
pub const SARGAM: [(&str, &str); 12] = [
    ("Sa", "s"),
    ("Flat Re", "R"),
    ("Re", "r"),
    ("Flat Ga", "G"),
    ("Ga", "g"),
    ("Ma", "m"),
    ("Sharp Ma", "M"),
    ("Pa", "p"),
    ("Flat Dha", "D"),
    ("Dha", "d"),
    ("Flat Ni", "N"),
    ("Ni", "n"),
];

// ---------------------------------------------------------------------------
// NoteType enum
// ---------------------------------------------------------------------------

/// Represents one of the 12 chromatic pitch classes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum NoteType {
    C,
    CSharp,
    D,
    DSharp,
    E,
    F,
    FSharp,
    G,
    GSharp,
    A,
    ASharp,
    B,
}

impl NoteType {
    /// Index in the C-starting array (matches MIDI `note_number % 12`).
    pub fn index_c(self) -> usize {
        match self {
            Self::C => 0,
            Self::CSharp => 1,
            Self::D => 2,
            Self::DSharp => 3,
            Self::E => 4,
            Self::F => 5,
            Self::FSharp => 6,
            Self::G => 7,
            Self::GSharp => 8,
            Self::A => 9,
            Self::ASharp => 10,
            Self::B => 11,
        }
    }

    /// Index in the A-starting array (used for Y-axis math).
    pub fn index_a(self) -> usize {
        NOTES_STARTING_WITH_A
            .iter()
            .position(|&n| n == self)
            .unwrap()
    }

    /// Build a NoteType from a C-based index (0..12).
    pub fn from_index_c(idx: usize) -> Self {
        NOTES_STARTING_WITH_C[idx % 12]
    }
}

impl fmt::Display for NoteType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s = match self {
            Self::C => "C",
            Self::CSharp => "C#",
            Self::D => "D",
            Self::DSharp => "D#",
            Self::E => "E",
            Self::F => "F",
            Self::FSharp => "F#",
            Self::G => "G",
            Self::GSharp => "G#",
            Self::A => "A",
            Self::ASharp => "A#",
            Self::B => "B",
        };
        write!(f, "{}", s)
    }
}

// ---------------------------------------------------------------------------
// MIDI / pitch math  (direct port of constants.ts)
// ---------------------------------------------------------------------------

/// Convert frequency (Hz) → MIDI note number.
///
/// `note_number = round(12 × log₂(freq / 440) + 69)`
pub fn get_note_number_from_pitch(frequency: f64) -> i32 {
    let note_num = 12.0 * (frequency / 440.0).log2();
    (note_num.round() as i32) + 69
}

/// Convert MIDI note number → frequency (Hz).
///
/// `freq = 440 × 2^((note - 69) / 12)`
pub fn get_note_frequency(note: i32) -> f64 {
    440.0 * 2.0_f64.powf((note - 69) as f64 / 12.0)
}

/// Convert MIDI note number → octave/scale number.
///
/// `scale = floor(note / 12) - 1`
pub fn get_scale_from_note_number(note_number: i32) -> i32 {
    (note_number as f64 / 12.0).floor() as i32 - 1
}

/// How many cents the `pitch` deviates from the nearest MIDI note.
///
/// `detune = floor(1200 × log₂(pitch / note_freq))`
pub fn get_detune_from_pitch(pitch: f64, note_number: i32) -> f64 {
    let note_freq = get_note_frequency(note_number);
    (1200.0 * (pitch / note_freq).log2()).floor()
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a4_maps_to_midi_69() {
        assert_eq!(get_note_number_from_pitch(440.0), 69);
    }

    #[test]
    fn midi_69_maps_to_440() {
        let freq = get_note_frequency(69);
        assert!((freq - 440.0).abs() < 0.01);
    }

    #[test]
    fn c4_is_octave_4() {
        assert_eq!(get_scale_from_note_number(60), 4);
    }

    #[test]
    fn a4_is_octave_4() {
        assert_eq!(get_scale_from_note_number(69), 4);
    }

    #[test]
    fn note_name_from_midi() {
        let note_num = get_note_number_from_pitch(440.0);
        let note = NOTES[(note_num as usize) % 12];
        assert_eq!(note, NoteType::A);
    }

    #[test]
    fn perfect_tuning_zero_detune() {
        let detune = get_detune_from_pitch(440.0, 69);
        assert!((detune).abs() < 1.0);
    }
}
