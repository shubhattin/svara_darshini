use super::constants::{NoteType, NOTES, NOTES_STARTING_WITH_A, SARGAM};
use egui::Color32;

// ---------------------------------------------------------------------------
// Note colors — HSL-based, one per chromatic pitch class
// ---------------------------------------------------------------------------

pub fn note_color(note: NoteType) -> Color32 {
    match note {
        NoteType::A => Color32::from_rgb(255, 0, 0),
        NoteType::ASharp => Color32::from_rgb(255, 128, 0),
        NoteType::B => Color32::from_rgb(255, 255, 0),
        NoteType::C => Color32::from_rgb(128, 255, 0),
        NoteType::CSharp => Color32::from_rgb(0, 255, 0),
        NoteType::D => Color32::from_rgb(0, 255, 128),
        NoteType::DSharp => Color32::from_rgb(0, 255, 255),
        NoteType::E => Color32::from_rgb(0, 128, 255),
        NoteType::F => Color32::from_rgb(0, 0, 255),
        NoteType::FSharp => Color32::from_rgb(128, 0, 255),
        NoteType::G => Color32::from_rgb(255, 0, 255),
        NoteType::GSharp => Color32::from_rgb(255, 0, 128),
    }
}

/// Slightly muted version of the note color for band backgrounds.
pub fn note_band_color(note: NoteType) -> Color32 {
    let c = note_color(note);
    Color32::from_rgba_unmultiplied(c.r(), c.g(), c.b(), 12)
}

// ---------------------------------------------------------------------------
// Note/Sargam ordering helpers
// ---------------------------------------------------------------------------

/// Build the 12-note array starting from `bottom_start_note`.
pub fn notes_custom_start(bottom_start_note: NoteType) -> [NoteType; 12] {
    let start_idx = NOTES
        .iter()
        .position(|&n| n == bottom_start_note)
        .unwrap_or(0);
    let mut arr = [NoteType::C; 12];
    for i in 0..12 {
        arr[i] = NOTES[(start_idx + i) % 12];
    }
    arr
}

/// Build Sargam key array aligned to `bottom_start_note` and `sa_at`.
pub fn sargam_custom_start(bottom_start_note: NoteType, sa_at: NoteType) -> [&'static str; 12] {
    let notes_cs = notes_custom_start(bottom_start_note);
    let sa_index = notes_cs.iter().position(|&n| n == sa_at).unwrap_or(0);
    let sargam_keys: Vec<&str> = SARGAM.iter().map(|(_, k)| *k).collect();
    let mut result = [""; 12];
    for i in 0..12 {
        result[(i + sa_index) % 12] = sargam_keys[i];
    }
    result
}

/// Get the Sargam (full name, key) for a detected note given the Sa setting.
pub fn sargam_for_note(note: NoteType, sa: NoteType) -> (&'static str, &'static str) {
    let offset = (note.index_c() + 12 - sa.index_c()) % 12;
    SARGAM[offset]
}

// ---------------------------------------------------------------------------
// Frequency → Y-ratio mapping
// ---------------------------------------------------------------------------

/// Convert frequency (Hz) to a Y-position ratio (0.0–1.0) for the graph.
/// All octaves collapse — only the position within the octave matters.
pub fn frequency_to_y_ratio(frequency: f64, bottom_start_note: NoteType) -> Option<f32> {
    if !frequency.is_finite() || frequency <= 0.0 {
        return None;
    }

    let a0_freq: f64 = 27.5;
    let semitone_offset = 12.0 * (frequency / a0_freq).log2();
    let semitone_in_octave = ((semitone_offset % 12.0) + 12.0) % 12.0;
    let base_index = NOTES_STARTING_WITH_A
        .iter()
        .position(|&n| n == bottom_start_note)
        .unwrap_or(0) as f64;
    let semitone_relative = ((semitone_in_octave - base_index) + 12.0) % 12.0;
    let normalized = ((semitone_relative + 0.5) / 12.0) * 100.0;
    let clamped = normalized.clamp(0.0, 100.0);
    Some((clamped / 100.0) as f32)
}

/// Interpolate a gradient color at a given y-ratio.
pub fn color_at_y_ratio(y_ratio: f32, bottom_start_note: NoteType) -> Color32 {
    let notes = notes_custom_start(bottom_start_note);
    let t = y_ratio.clamp(0.0, 1.0) * 11.0;
    let idx = (t as usize).min(10);
    let frac = t - idx as f32;
    let c1 = note_color(notes[idx]);
    let c2 = note_color(notes[(idx + 1).min(11)]);
    Color32::from_rgb(
        lerp_u8(c1.r(), c2.r(), frac),
        lerp_u8(c1.g(), c2.g(), frac),
        lerp_u8(c1.b(), c2.b(), frac),
    )
}

fn lerp_u8(a: u8, b: u8, t: f32) -> u8 {
    (a as f32 * (1.0 - t) + b as f32 * t)
        .round()
        .clamp(0.0, 255.0) as u8
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a440_with_a_bottom_maps_near_bottom() {
        let ratio = frequency_to_y_ratio(440.0, NoteType::A).unwrap();
        assert!(ratio < 0.15, "A with A-base should be near bottom, got {ratio}");
    }

    #[test]
    fn invalid_frequency_returns_none() {
        assert!(frequency_to_y_ratio(0.0, NoteType::C).is_none());
        assert!(frequency_to_y_ratio(-100.0, NoteType::C).is_none());
        assert!(frequency_to_y_ratio(f64::NAN, NoteType::C).is_none());
    }

    #[test]
    fn custom_start_wraps_correctly() {
        let arr = notes_custom_start(NoteType::D);
        assert_eq!(arr[0], NoteType::D);
        assert_eq!(arr[11], NoteType::CSharp);
    }

    #[test]
    fn sargam_for_sa_is_sa() {
        let (name, key) = sargam_for_note(NoteType::C, NoteType::C);
        assert_eq!(name, "Sa");
        assert_eq!(key, "s");
    }

    #[test]
    fn sargam_for_pa() {
        // C + 7 semitones = G = Pa
        let (name, _) = sargam_for_note(NoteType::G, NoteType::C);
        assert_eq!(name, "Pa");
    }
}
