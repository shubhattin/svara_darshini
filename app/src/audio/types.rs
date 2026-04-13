use crate::music::constants::NoteType;

/// A frame of audio analysis sent from the processing thread to the GUI.
/// Always includes signal level; pitch info is optional (None when silent/unclear).
#[derive(Debug, Clone)]
pub struct AudioFrame {
    /// RMS signal level (0.0–1.0). Always present, even when no pitch detected.
    pub signal_level: f32,
    /// Pitch detection result. `None` if signal too weak or unclear.
    pub pitch: Option<PitchInfo>,
}

/// Detected pitch information.
#[derive(Debug, Clone)]
pub struct PitchInfo {
    pub frequency: f64,
    pub clarity: f64,
    pub note: NoteType,
    pub note_name: String,
    pub scale: i32,
    pub detune: f64,
}

/// Information about an available audio input device.
#[derive(Debug, Clone)]
pub struct DeviceInfo {
    pub name: String,
    pub index: usize,
    pub is_default: bool,
}
