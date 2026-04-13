use std::collections::VecDeque;

use egui::epaint::CubicBezierShape;
use egui::{pos2, Color32, CornerRadius, FontId, Rect, Shape, Stroke, Ui};

use crate::audio::types::PitchInfo;
use crate::music::constants::NoteType;
use crate::music::note_mapping::{
    color_at_y_ratio, frequency_to_y_ratio, note_band_color, note_color, notes_custom_start,
    sargam_custom_start,
};

// ── PitchLab-inspired palette ───────────────────────────────────────────────

const BG_DARK: Color32 = Color32::from_rgb(8, 10, 18);        // deepest layer
const BAND_EVEN: Color32 = Color32::from_rgb(14, 18, 30);     // alternating bands
const BAND_ODD: Color32 = Color32::from_rgb(10, 13, 24);
const GRID_LINE: Color32 = Color32::from_rgba_premultiplied(255, 255, 255, 10);
const LABEL_DIM: Color32 = Color32::from_rgb(120, 130, 155);
const LABEL_BRIGHT: Color32 = Color32::from_rgb(210, 220, 240);
const AXIS_COLOR: Color32 = Color32::from_rgb(50, 58, 80);

const PADDING_TOP: f32 = 4.0;
const PADDING_BOTTOM: f32 = 4.0;
const LABEL_AREA_W: f32 = 56.0;   // space for sargam + western labels
const PADDING_RIGHT: f32 = 8.0;

/// Smoothing factor for cubic bezier control points.
const CURVE_SMOOTH: f32 = 0.3;

/// Maximum visible data points (≈ 8 s at 80 ms interval).
const MAX_POINTS: usize = 100;

// ── Public API ──────────────────────────────────────────────────────────────

/// Render the PitchLab-style pitch time-graph.
pub fn draw_time_graph(
    ui: &mut Ui,
    pitch_history: &VecDeque<PitchInfo>,
    bottom_start_note: NoteType,
    sa_at: NoteType,
    is_paused: bool,
    paused_data: &[PitchInfo],
) {
    let source: Vec<&PitchInfo> = if is_paused {
        paused_data.iter().collect()
    } else {
        pitch_history.iter().collect()
    };

    // Convert to graph-space points
    let points: Vec<GPoint> = source
        .iter()
        .filter_map(|p| {
            let yr = frequency_to_y_ratio(p.frequency, bottom_start_note)?;
            Some(GPoint {
                y_ratio: yr,
                freq: p.frequency,
                note_name: p.note_name.clone(),
                scale: p.scale,
                note: p.note,
            })
        })
        .collect();

    let visible: &[GPoint] = if points.len() > MAX_POINTS {
        &points[points.len() - MAX_POINTS..]
    } else {
        &points
    };

    // ── Allocate painter ────────────────────────────────────────────────
    let size = ui.available_size();
    let (resp, painter) = ui.allocate_painter(size, egui::Sense::hover());
    let rect = resp.rect;

    let graph = Rect::from_min_max(
        pos2(rect.left() + LABEL_AREA_W, rect.top() + PADDING_TOP),
        pos2(rect.right() - PADDING_RIGHT, rect.bottom() - PADDING_BOTTOM),
    );
    let gw = graph.width();
    let gh = graph.height();
    let band_h = gh / 12.0;

    // ── Background fill ─────────────────────────────────────────────────
    painter.rect_filled(rect, CornerRadius::same(6), BG_DARK);

    // ── Semitone bands ──────────────────────────────────────────────────
    let notes_ord = notes_custom_start(bottom_start_note);
    let sargam_ord = sargam_custom_start(bottom_start_note, sa_at);

    for i in 0..12 {
        let note = notes_ord[i];
        // Band i starts at the bottom; band 11 is at the top.
        let y_top = graph.bottom() - (i as f32 + 1.0) * band_h;
        let y_bot = graph.bottom() - i as f32 * band_h;
        let band_rect = Rect::from_min_max(pos2(graph.left(), y_top), pos2(graph.right(), y_bot));

        // Alternating base + subtle note tint
        let base = if i % 2 == 0 { BAND_EVEN } else { BAND_ODD };
        let tint = note_band_color(note);
        painter.rect_filled(band_rect, CornerRadius::ZERO, base);
        painter.rect_filled(band_rect, CornerRadius::ZERO, tint);

        // Grid line at top of each band
        painter.line_segment(
            [pos2(graph.left(), y_top), pos2(graph.right(), y_top)],
            Stroke::new(0.5, GRID_LINE),
        );

        // ── Labels (in the left margin) ─────────────────────────────────
        let label_y = (y_top + y_bot) / 2.0;
        let is_sa = sargam_ord[i] == "s";

        // Sargam key
        let sargam_color = if is_sa { LABEL_BRIGHT } else { LABEL_DIM };
        painter.text(
            pos2(rect.left() + 8.0, label_y),
            egui::Align2::LEFT_CENTER,
            sargam_ord[i],
            FontId::monospace(11.0),
            sargam_color,
        );

        // Color dot
        painter.circle_filled(
            pos2(rect.left() + LABEL_AREA_W - 22.0, label_y),
            3.0,
            note_color(note),
        );

        // Western note name
        let note_col = if is_sa { LABEL_BRIGHT } else { LABEL_DIM };
        painter.text(
            pos2(rect.left() + LABEL_AREA_W - 6.0, label_y),
            egui::Align2::RIGHT_CENTER,
            note.to_string(),
            FontId::monospace(11.0),
            note_col,
        );
    }

    // ── Y axis ──────────────────────────────────────────────────────────
    painter.line_segment(
        [pos2(graph.left(), graph.top()), pos2(graph.left(), graph.bottom())],
        Stroke::new(1.0, AXIS_COLOR),
    );

    if visible.len() < 2 {
        // Show hint text when no data
        if visible.is_empty() {
            painter.text(
                graph.center(),
                egui::Align2::CENTER_CENTER,
                "Listening…",
                FontId::proportional(16.0),
                Color32::from_rgb(80, 90, 110),
            );
        }
        return;
    }

    let n = visible.len();

    // ── Coordinate helpers ──────────────────────────────────────────────
    let x_of = |idx: usize| -> f32 {
        graph.left() + (idx as f32 / (n - 1).max(1) as f32) * gw
    };
    let y_of = |yr: f32| -> f32 { graph.bottom() - yr * gh };

    // ── Pitch line — 3-pass glow effect ─────────────────────────────────
    for pass in 0..3 {
        let (width, alpha) = match pass {
            0 => (7.0_f32, 18_u8),   // outer glow
            1 => (3.5, 70),           // mid glow
            _ => (1.8, 230),          // crisp line
        };

        for i in 1..n {
            let prev = &visible[i - 1];
            let curr = &visible[i];

            let px = x_of(i - 1);
            let py = y_of(prev.y_ratio);
            let cx = x_of(i);
            let cy = y_of(curr.y_ratio);

            // Jump detection: pitch goes up but wrapped around octave boundary
            let dp = curr.freq - prev.freq;
            let dy = cy - py;
            let is_jump = (dp > 0.0 && dy > 0.0) || (dp < 0.0 && dy < 0.0);

            // Segment color from gradient
            let mid_yr = (prev.y_ratio + curr.y_ratio) / 2.0;
            let base_col = color_at_y_ratio(mid_yr, bottom_start_note);
            let seg_col = Color32::from_rgba_unmultiplied(
                base_col.r(),
                base_col.g(),
                base_col.b(),
                if is_jump { alpha / 4 } else { alpha },
            );

            // Bezier control points
            let dx = cx - px;
            let cp1 = pos2(px + dx * CURVE_SMOOTH, py);
            let cp2 = pos2(cx - dx * CURVE_SMOOTH, cy);

            painter.add(Shape::CubicBezier(
                CubicBezierShape::from_points_stroke(
                    [pos2(px, py), cp1, cp2, pos2(cx, cy)],
                    false,
                    Color32::TRANSPARENT,
                    Stroke::new(width, seg_col),
                ),
            ));
        }
    }

    // ── Current position indicator ──────────────────────────────────────
    let last = &visible[n - 1];
    let lx = x_of(n - 1);
    let ly = y_of(last.y_ratio);

    // Glow ring
    painter.circle_filled(
        pos2(lx, ly),
        8.0,
        Color32::from_rgba_unmultiplied(255, 140, 50, 25),
    );
    painter.circle_filled(
        pos2(lx, ly),
        5.0,
        Color32::from_rgba_unmultiplied(255, 140, 50, 50),
    );
    // Core dot
    painter.circle_filled(pos2(lx, ly), 3.0, Color32::from_rgb(255, 160, 60));

    // Frequency label — smart positioning
    let is_right = lx > graph.right() - gw * 0.18;
    let is_top = ly < graph.top() + 30.0;
    let lbl_x = if is_right { lx - 10.0 } else { lx + 10.0 };
    let lbl_y = if is_top { ly + 16.0 } else { ly - 14.0 };
    let anchor = if is_right {
        egui::Align2::RIGHT_CENTER
    } else {
        egui::Align2::LEFT_CENTER
    };

    // Background pill for readability
    let label_text = format!("{:.1} Hz  {}{}", last.freq, last.note_name, last.scale);
    let galley = painter.layout_no_wrap(
        label_text.clone(),
        FontId::monospace(10.0),
        Color32::from_rgb(230, 235, 245),
    );
    let text_rect = anchor.anchor_size(pos2(lbl_x, lbl_y), galley.size());
    let pill = text_rect.expand2(egui::vec2(5.0, 2.0));
    painter.rect_filled(
        pill,
        CornerRadius::same(4),
        Color32::from_rgba_unmultiplied(10, 14, 25, 200),
    );
    painter.galley(text_rect.min, galley, Color32::PLACEHOLDER);
}

// ── Internals ───────────────────────────────────────────────────────────────

struct GPoint {
    y_ratio: f32,
    freq: f64,
    note_name: String,
    scale: i32,
    note: NoteType,
}
