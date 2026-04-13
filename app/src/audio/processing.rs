use crossbeam_channel::Sender;
use pitch_detection::detector::mcleod::McLeodDetector;
use pitch_detection::detector::PitchDetector;
use ringbuf::traits::{Consumer, Observer};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

use crate::music::constants::{
    get_detune_from_pitch, get_note_number_from_pitch, get_scale_from_note_number, NOTES,
};

use super::types::{AudioFrame, PitchInfo};

/// Configuration for the pitch processing pipeline.
pub struct ProcessingConfig {
    pub sample_rate: u32,
    pub window_size: usize,
    pub update_interval_ms: u64,
    pub power_threshold: f64,
    pub clarity_threshold: f64,
}

impl Default for ProcessingConfig {
    fn default() -> Self {
        Self {
            sample_rate: 44100,
            window_size: 2048,
            update_interval_ms: 80,
            // ──────────────────────────────────────────────────────────────
            // KEY FIX: The McLeod power threshold is compared against
            //   m[0] = 2 * Σ(x[i]²)  (twice the signal energy over the window).
            // A typical quiet laptop mic produces amplitudes ~0.001–0.01,
            // so m[0] ≈ 2 * 2048 * 0.01² ≈ 0.4.
            // Old value of 0.5 rejected nearly all mic input!
            // ──────────────────────────────────────────────────────────────
            power_threshold: 0.0,     // never skip — let clarity decide
            clarity_threshold: 0.15,  // accept marginal detections
        }
    }
}

/// Spawn a background thread that reads audio samples, runs MPM pitch
/// detection, and sends `AudioFrame`s to the GUI every update interval.
pub fn spawn_processing_thread(
    mut consumer: ringbuf::HeapCons<f32>,
    sender: Sender<AudioFrame>,
    config: ProcessingConfig,
    stop_flag: Arc<AtomicBool>,
) -> thread::JoinHandle<()> {
    thread::spawn(move || {
        let padding = config.window_size / 2;
        let mut detector = McLeodDetector::new(config.window_size, padding);
        let mut buffer = vec![0.0_f64; config.window_size];
        let mut samples_accumulated: usize = 0;
        let interval = Duration::from_millis(config.update_interval_ms);
        let mut frame_count: u64 = 0;
        let mut pitch_count: u64 = 0;
        let diag_interval = Duration::from_secs(3);
        let mut last_diag = Instant::now();

        log::info!(
            "Processing: window={}, rate={} Hz, interval={}ms, pow_thr={}, clar_thr={}",
            config.window_size,
            config.sample_rate,
            config.update_interval_ms,
            config.power_threshold,
            config.clarity_threshold,
        );

        loop {
            if stop_flag.load(Ordering::Relaxed) {
                break;
            }

            thread::sleep(interval);

            let available = consumer.occupied_len();
            if available == 0 {
                // No audio data at all — might be a capture issue
                if frame_count == 0 && last_diag.elapsed() > Duration::from_secs(2) {
                    log::warn!("No audio samples received yet — check device selection");
                    last_diag = Instant::now();
                }
                continue;
            }

            // Drain all available samples
            let mut temp = vec![0.0_f32; available];
            let read = consumer.pop_slice(&mut temp);
            if read == 0 {
                continue;
            }

            frame_count += 1;

            // ── RMS signal level ────────────────────────────────────────
            let rms = {
                let sum: f32 = temp[..read].iter().map(|s| s * s).sum();
                (sum / read as f32).sqrt()
            };
            // Amplify heavily — laptop mics produce tiny amplitudes (~0.001–0.01)
            let signal_level = (rms * 80.0).min(1.0);

            // ── Buffer management ───────────────────────────────────────
            if read >= config.window_size {
                let start = read - config.window_size;
                for (i, &s) in temp[start..read].iter().enumerate() {
                    buffer[i] = s as f64;
                }
                samples_accumulated = config.window_size;
            } else {
                let keep = config.window_size - read;
                buffer.copy_within(read.., 0);
                for (i, &s) in temp[..read].iter().enumerate() {
                    buffer[keep + i] = s as f64;
                }
                samples_accumulated = (samples_accumulated + read).min(config.window_size);
            }

            if samples_accumulated < config.window_size {
                let _ = sender.send(AudioFrame {
                    signal_level,
                    pitch: None,
                });
                continue;
            }

            // ── McLeod pitch detection ──────────────────────────────────
            let result = detector.get_pitch(
                &buffer,
                config.sample_rate as usize,
                config.power_threshold,
                config.clarity_threshold,
            );

            let had_raw_detection = result.is_some();
            let pitch_info = result.and_then(|pitch| {
                let freq = pitch.frequency;
                let clarity = pitch.clarity;

                if freq > 25.0 && freq < 8000.0 {
                    let note_number = get_note_number_from_pitch(freq);
                    let note = NOTES[(note_number as usize) % 12];
                    let scale = get_scale_from_note_number(note_number);
                    let detune = get_detune_from_pitch(freq, note_number);

                    pitch_count += 1;

                    Some(PitchInfo {
                        frequency: (freq * 10.0).round() / 10.0,
                        clarity,
                        note,
                        note_name: note.to_string(),
                        scale,
                        detune,
                    })
                } else {
                    None
                }
            });

            // ── Periodic diagnostics ────────────────────────────────────
            if last_diag.elapsed() > diag_interval {
                log::info!(
                    "DIAG: frames={}, pitches={}, rms={:.6}, signal_lvl={:.3}, read={}, avail={}",
                    frame_count, pitch_count, rms, signal_level, read, available
                );
                if let Some(ref p) = pitch_info {
                    log::info!(
                        "  ↳ detected: {:.1} Hz ({}{}) clarity={:.3}",
                        p.frequency, p.note_name, p.scale, p.clarity
                    );
                } else if had_raw_detection {
                    log::info!("  ↳ raw detection exists but filtered (freq out of range)");
                } else {
                    log::info!("  ↳ no pitch detected (clarity too low or silence)");
                }
                last_diag = Instant::now();
            }

            if sender
                .send(AudioFrame {
                    signal_level,
                    pitch: pitch_info,
                })
                .is_err()
            {
                break;
            }
        }

        log::info!("Processing thread stopped (frames={}, pitches={})", frame_count, pitch_count);
    })
}
