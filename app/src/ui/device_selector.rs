use egui::Ui;

use crate::audio::types::DeviceInfo;

/// Render the audio device selector dropdown with a refresh button.
///
/// Returns `Some(index)` if the user selected a different device,
/// or special values:
/// - `DeviceAction::Refresh` if the refresh button was clicked.
pub enum DeviceAction {
    /// User selected a device at this index.
    Select(usize),
    /// User clicked the refresh button.
    Refresh,
    /// No action taken.
    None,
}

pub fn draw_device_selector(
    ui: &mut Ui,
    devices: &[DeviceInfo],
    selected_index: usize,
) -> DeviceAction {
    let mut action = DeviceAction::None;

    ui.horizontal(|ui| {
        ui.label("🎤");

        // Device dropdown
        let current_label = devices
            .get(selected_index)
            .map(|d| d.name.as_str())
            .unwrap_or("No device");

        egui::ComboBox::from_id_salt("audio_device_selector")
            .selected_text(current_label)
            .width(300.0)
            .show_ui(ui, |ui| {
                for device in devices {
                    let label = if device.is_default {
                        format!("{} (default)", device.name)
                    } else {
                        device.name.clone()
                    };
                    if ui
                        .selectable_label(device.index == selected_index, &label)
                        .clicked()
                    {
                        action = DeviceAction::Select(device.index);
                    }
                }
            });

        // Refresh button
        if ui
            .button("↻")
            .on_hover_text("Refresh device list")
            .clicked()
        {
            action = DeviceAction::Refresh;
        }
    });

    action
}
