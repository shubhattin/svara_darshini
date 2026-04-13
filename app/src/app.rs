use std::collections::VecDeque;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use crossbeam_channel::Receiver;
use eframe::egui;
use egui::{pos2, Color32, CornerRadius, FontId, Rect, RichText, Stroke, Vec2};

use crate::audio::capture::AudioCapture;
use crate::audio::processing::{spawn_processing_thread, ProcessingConfig};
use crate::audio::types::{AudioFrame, DeviceInfo, PitchInfo};
use crate::music::constants::NoteType;
use crate::music::note_mapping::sargam_for_note;
use crate::ui::device_selector::{self, DeviceAction};
use crate::ui::note_selectors::{self, StepDirection};
use crate::ui::time_graph;

// ── PitchLab-inspired palette ───────────────────────────────────────────────

const BG_DEEP: Color32 = Color32::from_rgb(8, 10, 18);
const BG_PANEL: Color32 = Color32::from_rgb(12, 15, 26);
const BG_SURFACE: Color32 = Color32::from_rgb(18, 22, 38);
const TEXT_PRIMARY: Color32 = Color32::from_rgb(225, 230, 245);
const TEXT_DIM: Color32 = Color32::from_rgb(110, 120, 145);
const ACCENT_GREEN: Color32 = Color32::from_rgb(34, 197, 94);
const ACCENT_AMBER: Color32 = Color32::from_rgb(245, 158, 11);
const ACCENT_RED: Color32 = Color32::from_rgb(239, 68, 68);
const ACCENT_BLUE: Color32 = Color32::from_rgb(96, 165, 250);

const MAX_PITCH_HISTORY: usize = 100;

// ── App state ───────────────────────────────────────────────────────────────

pub struct SvaraDarshiniApp {
    // Audio
    audio_capture: AudioCapture,
    frame_receiver: Option<Receiver<AudioFrame>>,
    pitch_history: VecDeque<PitchInfo>,
    processing_stop_flag: Option<Arc<AtomicBool>>,
    processing_handle: Option<std::thread::JoinHandle<()>>,

    // Current state
    current_pitch: Option<PitchInfo>,
    signal_level: f32,

    // Devices
    device_list: Vec<DeviceInfo>,
    selected_device_index: usize,

    // Settings
    sa_at: NoteType,
    bottom_start_note: NoteType,

    // UI state
    is_running: bool,
    is_paused: bool,
    paused_data: Vec<PitchInfo>,
}

impl SvaraDarshiniApp {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        // Dark theme
        let mut visuals = egui::Visuals::dark();
        visuals.panel_fill = BG_DEEP;
        visuals.window_fill = BG_PANEL;
        visuals.extreme_bg_color = BG_DEEP;
        visuals.faint_bg_color = BG_SURFACE;
        visuals.widgets.noninteractive.bg_fill = BG_SURFACE;
        visuals.widgets.inactive.bg_fill = BG_SURFACE;
        cc.egui_ctx.set_visuals(visuals);

        let audio_capture = AudioCapture::new();
        let device_list = audio_capture.device_list();

        Self {
            audio_capture,
            frame_receiver: None,
            pitch_history: VecDeque::with_capacity(MAX_PITCH_HISTORY),
            processing_stop_flag: None,
            processing_handle: None,

            current_pitch: None,
            signal_level: 0.0,

            device_list,
            selected_device_index: 0,

            sa_at: NoteType::C,
            bottom_start_note: NoteType::C,

            is_running: false,
            is_paused: false,
            paused_data: Vec::new(),
        }
    }

    fn start(&mut self) {
        if self.is_running {
            return;
        }
        match self.audio_capture.start(self.selected_device_index) {
            Ok(consumer) => {
                let (sender, receiver) = crossbeam_channel::unbounded();
                let stop_flag = Arc::new(AtomicBool::new(false));
                let config = ProcessingConfig {
                    sample_rate: self.audio_capture.sample_rate,
                    ..Default::default()
                };
                let handle =
                    spawn_processing_thread(consumer, sender, config, stop_flag.clone());

                self.frame_receiver = Some(receiver);
                self.processing_stop_flag = Some(stop_flag);
                self.processing_handle = Some(handle);
                self.is_running = true;
                self.is_paused = false;
                self.pitch_history.clear();
                self.paused_data.clear();
                self.current_pitch = None;
                self.signal_level = 0.0;
            }
            Err(e) => log::error!("Failed to start: {}", e),
        }
    }

    fn stop(&mut self) {
        if !self.is_running {
            return;
        }
        if let Some(flag) = self.processing_stop_flag.take() {
            flag.store(true, Ordering::Relaxed);
        }
        if let Some(h) = self.processing_handle.take() {
            let _ = h.join();
        }
        self.audio_capture.stop();
        self.frame_receiver = None;
        self.is_running = false;
        self.is_paused = false;
        self.pitch_history.clear();
        self.paused_data.clear();
        self.current_pitch = None;
        self.signal_level = 0.0;
    }

    fn toggle_pause(&mut self) {
        if self.is_paused {
            self.is_paused = false;
        } else {
            self.paused_data = self.pitch_history.iter().cloned().collect();
            self.is_paused = true;
        }
    }

    fn poll_audio_frames(&mut self) {
        if let Some(ref receiver) = self.frame_receiver {
            for frame in receiver.try_iter() {
                self.signal_level = frame.signal_level;
                if let Some(pitch) = frame.pitch {
                    self.current_pitch = Some(pitch.clone());
                    if !self.is_paused {
                        self.pitch_history.push_back(pitch);
                        while self.pitch_history.len() > MAX_PITCH_HISTORY {
                            self.pitch_history.pop_front();
                        }
                    }
                }
            }
        }
    }

    fn switch_device(&mut self, idx: usize) {
        if idx == self.selected_device_index {
            return;
        }
        self.selected_device_index = idx;
        if self.is_running {
            self.stop();
            self.start();
        }
    }

    fn refresh_devices(&mut self) {
        self.audio_capture.refresh_devices();
        self.device_list = self.audio_capture.device_list();
        if self.selected_device_index >= self.device_list.len() {
            self.selected_device_index = 0;
        }
    }
}

impl eframe::App for SvaraDarshiniApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.poll_audio_frames();

        if self.is_running {
            ctx.request_repaint();
        }

        // ── TOP: Note display + selectors ───────────────────────────────
        egui::TopBottomPanel::top("top_panel")
            .frame(
                egui::Frame::NONE
                    .fill(BG_PANEL)
                    .inner_margin(egui::Margin::symmetric(12, 8)),
            )
            .show(ctx, |ui| {
                if self.is_running {
                    self.draw_note_display(ui);
                } else {
                    self.draw_welcome(ui);
                }

                ui.add_space(6.0);

                // Selectors row
                ui.horizontal(|ui| {
                    if let Some(n) = note_selectors::draw_sa_selector(ui, self.sa_at) {
                        self.sa_at = n;
                    }
                    ui.add_space(16.0);
                    if let Some(n) =
                        note_selectors::draw_bottom_note_selector(ui, self.bottom_start_note)
                    {
                        self.bottom_start_note = n;
                    }
                    ui.add_space(8.0);
                    // Step arrows
                    if ui.small_button("▲").on_hover_text("Note up").clicked() {
                        self.bottom_start_note = note_selectors::step_bottom_start_note(
                            self.bottom_start_note,
                            StepDirection::Up,
                        );
                    }
                    if ui.small_button("▼").on_hover_text("Note down").clicked() {
                        self.bottom_start_note = note_selectors::step_bottom_start_note(
                            self.bottom_start_note,
                            StepDirection::Down,
                        );
                    }
                });
            });

        // ── BOTTOM: Controls + device ───────────────────────────────────
        egui::TopBottomPanel::bottom("bottom_panel")
            .frame(
                egui::Frame::NONE
                    .fill(BG_PANEL)
                    .inner_margin(egui::Margin::symmetric(12, 8)),
            )
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    self.draw_controls(ui);
                    ui.add_space(16.0);
                    self.draw_signal_meter(ui);
                });

                ui.add_space(4.0);

                // Device selector
                match device_selector::draw_device_selector(
                    ui,
                    &self.device_list,
                    self.selected_device_index,
                ) {
                    DeviceAction::Select(i) => self.switch_device(i),
                    DeviceAction::Refresh => self.refresh_devices(),
                    DeviceAction::None => {}
                }
            });

        // ── CENTER: Time graph ──────────────────────────────────────────
        egui::CentralPanel::default()
            .frame(egui::Frame::NONE.fill(BG_DEEP).inner_margin(2.0))
            .show(ctx, |ui| {
                time_graph::draw_time_graph(
                    ui,
                    &self.pitch_history,
                    self.bottom_start_note,
                    self.sa_at,
                    self.is_paused,
                    &self.paused_data,
                );
            });
    }
}

// ── UI drawing helpers ──────────────────────────────────────────────────────

impl SvaraDarshiniApp {
    /// Large current-note display (PitchLab-style).
    fn draw_note_display(&self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| {
            ui.vertical(|ui| {
                if let Some(ref p) = self.current_pitch {
                    // Note name — BIG
                    let note_text = format!("{}{}", p.note_name, p.scale);
                    ui.label(
                        RichText::new(&note_text)
                            .font(FontId::monospace(42.0))
                            .color(TEXT_PRIMARY),
                    );

                    // Frequency + Sargam
                    let (sargam_name, sargam_key) = sargam_for_note(p.note, self.sa_at);
                    ui.horizontal(|ui| {
                        ui.label(
                            RichText::new(format!("{:.1} Hz", p.frequency))
                                .font(FontId::monospace(14.0))
                                .color(TEXT_DIM),
                        );
                        ui.add_space(12.0);
                        ui.label(
                            RichText::new(sargam_name)
                                .font(FontId::proportional(14.0))
                                .color(ACCENT_BLUE),
                        );
                        ui.label(
                            RichText::new(format!("({})", sargam_key))
                                .font(FontId::monospace(14.0))
                                .color(ACCENT_BLUE),
                        );
                    });
                } else {
                    ui.label(
                        RichText::new("—")
                            .font(FontId::monospace(42.0))
                            .color(Color32::from_rgb(40, 45, 60)),
                    );
                    ui.label(
                        RichText::new("No pitch detected")
                            .font(FontId::proportional(12.0))
                            .color(TEXT_DIM),
                    );
                }
            });

            ui.add_space(24.0);

            // Cents deviation meter
            if let Some(ref p) = self.current_pitch {
                ui.vertical(|ui| {
                    ui.add_space(8.0);
                    self.draw_cents_meter(ui, p.detune);
                });
            }
        });
    }

    /// Horizontal cents deviation gauge.
    fn draw_cents_meter(&self, ui: &mut egui::Ui, cents: f64) {
        let desired = Vec2::new(200.0, 28.0);
        let (resp, painter) = ui.allocate_painter(desired, egui::Sense::hover());
        let r = resp.rect;

        // Track background
        let track_h = 6.0;
        let track_rect = Rect::from_center_size(r.center(), Vec2::new(r.width() - 20.0, track_h));
        painter.rect_filled(track_rect, CornerRadius::same(3), BG_SURFACE);

        // Center tick
        painter.line_segment(
            [
                pos2(track_rect.center().x, track_rect.top() - 2.0),
                pos2(track_rect.center().x, track_rect.bottom() + 2.0),
            ],
            Stroke::new(1.5, Color32::from_rgb(80, 90, 110)),
        );

        // Dot position (clamped ±50 cents)
        let clamped = (cents as f32).clamp(-50.0, 50.0);
        let t = (clamped + 50.0) / 100.0; // 0..1
        let dot_x = track_rect.left() + t * track_rect.width();

        // Color: green in center → yellow → red at edges
        let abs_c = clamped.abs();
        let dot_color = if abs_c < 5.0 {
            ACCENT_GREEN
        } else if abs_c < 20.0 {
            ACCENT_AMBER
        } else {
            ACCENT_RED
        };

        // Glow
        painter.circle_filled(
            pos2(dot_x, track_rect.center().y),
            8.0,
            Color32::from_rgba_unmultiplied(dot_color.r(), dot_color.g(), dot_color.b(), 30),
        );
        painter.circle_filled(pos2(dot_x, track_rect.center().y), 4.5, dot_color);

        // Labels
        painter.text(
            pos2(track_rect.left(), r.bottom()),
            egui::Align2::LEFT_BOTTOM,
            "-50",
            FontId::monospace(8.0),
            TEXT_DIM,
        );
        painter.text(
            pos2(track_rect.center().x, r.bottom()),
            egui::Align2::CENTER_BOTTOM,
            "0",
            FontId::monospace(8.0),
            Color32::from_rgb(80, 90, 110),
        );
        painter.text(
            pos2(track_rect.right(), r.bottom()),
            egui::Align2::RIGHT_BOTTOM,
            "+50",
            FontId::monospace(8.0),
            TEXT_DIM,
        );
    }

    /// Signal level VU-style meter.
    fn draw_signal_meter(&self, ui: &mut egui::Ui) {
        let desired = Vec2::new(80.0, 18.0);
        let (resp, painter) = ui.allocate_painter(desired, egui::Sense::hover());
        let r = resp.rect;

        // Track
        painter.rect_filled(r, CornerRadius::same(3), BG_SURFACE);

        // Fill
        let fill_w = self.signal_level.clamp(0.0, 1.0) * r.width();
        if fill_w > 0.5 {
            let fill_color = if self.signal_level > 0.7 {
                ACCENT_RED
            } else if self.signal_level > 0.3 {
                ACCENT_GREEN
            } else {
                Color32::from_rgb(60, 120, 90)
            };
            let fill_rect = Rect::from_min_max(r.min, pos2(r.left() + fill_w, r.bottom()));
            painter.rect_filled(fill_rect, CornerRadius::same(3), fill_color);
        }

        // Label
        painter.text(
            r.center(),
            egui::Align2::CENTER_CENTER,
            "🔊",
            FontId::proportional(10.0),
            TEXT_PRIMARY,
        );
    }

    /// Welcome / Start screen.
    fn draw_welcome(&self, ui: &mut egui::Ui) {
        ui.vertical_centered(|ui| {
            ui.add_space(4.0);
            ui.label(
                RichText::new("Svara Darshini")
                    .font(FontId::proportional(22.0))
                    .color(TEXT_PRIMARY),
            );
            ui.label(
                RichText::new("Real-time pitch visualizer")
                    .font(FontId::proportional(12.0))
                    .color(TEXT_DIM),
            );
        });
    }

    /// Start / Pause / Stop buttons.
    fn draw_controls(&mut self, ui: &mut egui::Ui) {
        if !self.is_running {
            let btn = egui::Button::new(
                RichText::new("▶  Start")
                    .color(Color32::WHITE)
                    .strong()
                    .size(15.0),
            )
            .fill(ACCENT_AMBER)
            .corner_radius(6.0)
            .min_size(Vec2::new(90.0, 32.0));

            if ui.add(btn).clicked() {
                self.start();
            }
        } else {
            let pause_label = if self.is_paused { "▶  Play" } else { "⏸ Pause" };
            let pause_btn = egui::Button::new(
                RichText::new(pause_label)
                    .color(Color32::WHITE)
                    .strong()
                    .size(13.0),
            )
            .fill(ACCENT_BLUE)
            .corner_radius(5.0)
            .min_size(Vec2::new(80.0, 28.0));

            if ui.add(pause_btn).clicked() {
                self.toggle_pause();
            }

            ui.add_space(6.0);

            let stop_btn = egui::Button::new(
                RichText::new("⏹  Stop")
                    .color(Color32::WHITE)
                    .strong()
                    .size(13.0),
            )
            .fill(ACCENT_RED)
            .corner_radius(5.0)
            .min_size(Vec2::new(80.0, 28.0));

            if ui.add(stop_btn).clicked() {
                self.stop();
            }
        }
    }
}
