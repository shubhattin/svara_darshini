use egui::{Color32, RichText, Ui};

use crate::music::constants::{NoteType, NOTES_STARTING_WITH_A};

/// The accent color for the selected note button.
const ACCENT: Color32 = Color32::from_rgb(99, 102, 241); // indigo-500
/// The default button background.
const BTN_BG: Color32 = Color32::from_rgb(100, 116, 139); // slate-500
/// Button text color.
const BTN_TEXT: Color32 = Color32::WHITE;

/// Render a "Sa at" selector.
/// Returns `Some(note)` if the user picked a different note.
pub fn draw_sa_selector(ui: &mut Ui, current: NoteType) -> Option<NoteType> {
    draw_note_selector(ui, "Sa at", current, "sa_selector")
}

/// Render a "Bottom Start Note" selector.
/// Returns `Some(note)` if the user picked a different note.
pub fn draw_bottom_note_selector(ui: &mut Ui, current: NoteType) -> Option<NoteType> {
    draw_note_selector(ui, "Bottom Start Note", current, "bottom_note_selector")
}

/// Draw up/down step buttons for the bottom start note.
/// Returns `Some(NoteType)` if the user clicked a button.
pub fn step_bottom_start_note(current: NoteType, direction: StepDirection) -> NoteType {
    let idx = NOTES_STARTING_WITH_A
        .iter()
        .position(|&n| n == current)
        .unwrap_or(0);
    let new_idx = match direction {
        StepDirection::Up => (idx + 1) % 12,
        StepDirection::Down => (idx + 11) % 12,
    };
    NOTES_STARTING_WITH_A[new_idx]
}

pub enum StepDirection {
    Up,
    Down,
}

// ---------------------------------------------------------------------------
// Internal
// ---------------------------------------------------------------------------

fn draw_note_selector(
    ui: &mut Ui,
    label: &str,
    current: NoteType,
    id_salt: &str,
) -> Option<NoteType> {
    let mut selected = None;

    ui.horizontal(|ui| {
        ui.label(RichText::new(label).strong().size(13.0));

        egui::ComboBox::from_id_salt(id_salt)
            .selected_text(RichText::new(current.to_string()).size(13.0))
            .show_ui(ui, |ui| {
                // Render as a 4×3 grid
                egui::Grid::new(format!("{}_grid", id_salt))
                    .num_columns(4)
                    .spacing([4.0, 4.0])
                    .show(ui, |ui| {
                        for (i, &note) in NOTES_STARTING_WITH_A.iter().enumerate() {
                            let is_selected = note == current;
                            let bg = if is_selected { ACCENT } else { BTN_BG };

                            let btn = egui::Button::new(
                                RichText::new(note.to_string())
                                    .color(BTN_TEXT)
                                    .strong()
                                    .size(13.0),
                            )
                            .fill(bg)
                            .corner_radius(4.0)
                            .min_size(egui::vec2(32.0, 24.0));

                            if ui.add(btn).clicked() {
                                selected = Some(note);
                            }

                            if (i + 1) % 4 == 0 {
                                ui.end_row();
                            }
                        }
                    });
            });
    });

    selected
}
