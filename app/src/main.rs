mod app;
mod audio;
mod music;
mod ui;

fn main() -> eframe::Result {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"))
        .format_timestamp_millis()
        .init();

    let native_options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("Svara Darshini")
            .with_inner_size([960.0, 700.0])
            .with_min_inner_size([560.0, 440.0]),
        ..Default::default()
    };

    eframe::run_native(
        "Svara Darshini",
        native_options,
        Box::new(|cc| Ok(Box::new(app::SvaraDarshiniApp::new(cc)))),
    )
}
