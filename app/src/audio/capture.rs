use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use ringbuf::traits::{Producer, Split};

use super::types::DeviceInfo;

/// Manages audio device enumeration and capture via cpal.
///
/// On Linux PipeWire systems, the ALSA backend often fails to deliver data
/// even though `build_input_stream` and `play()` succeed. We work around
/// this by trying the JACK host first (PipeWire exposes a JACK server),
/// falling back to ALSA.
pub struct AudioCapture {
    host: cpal::Host,
    host_name: String,
    devices: Vec<(String, cpal::Device)>,
    default_device_name: Option<String>,
    active_stream: Option<cpal::Stream>,
    pub sample_rate: u32,
}

impl AudioCapture {
    pub fn new() -> Self {
        // Try hosts in preference order: JACK (works on PipeWire) → ALSA
        let (host, host_name) = Self::pick_host();

        let mut capture = Self {
            host,
            host_name,
            devices: Vec::new(),
            default_device_name: None,
            active_stream: None,
            sample_rate: 44100,
        };
        capture.refresh_devices();
        capture
    }

    /// Pick the best available audio host.
    fn pick_host() -> (cpal::Host, String) {
        let available = cpal::available_hosts();
        log::info!("Available audio hosts: {:?}", available);

        // Prefer JACK on Linux (PipeWire provides a JACK server)
        #[cfg(all(target_os = "linux", feature = "jack-backend"))]
        {
            if available.contains(&cpal::HostId::Jack) {
                match cpal::host_from_id(cpal::HostId::Jack) {
                    Ok(host) => {
                        log::info!("Using JACK host (PipeWire compatible)");
                        return (host, "JACK".to_string());
                    }
                    Err(e) => {
                        log::warn!("JACK host unavailable: {}", e);
                    }
                }
            }
        }

        let host = cpal::default_host();
        let name = format!("{:?}", host.id());
        log::info!("Using default host: {}", name);
        (host, name)
    }

    /// Re-enumerate all audio input devices.
    pub fn refresh_devices(&mut self) {
        self.default_device_name = self
            .host
            .default_input_device()
            .and_then(|d| d.description().ok())
            .map(|desc| desc.to_string());

        self.devices.clear();
        if let Ok(input_devices) = self.host.input_devices() {
            for device in input_devices {
                let name = device
                    .description()
                    .map(|d| d.to_string())
                    .unwrap_or_else(|_| "Unknown Device".to_string());
                // Log supported configs for each device (helps debugging)
                if let Ok(configs) = device.supported_input_configs() {
                    let formats: Vec<String> = configs
                        .map(|c| {
                            format!(
                                "{}ch {:?} {}-{}Hz",
                                c.channels(),
                                c.sample_format(),
                                c.min_sample_rate(),
                                c.max_sample_rate()
                            )
                        })
                        .collect();
                    log::info!("  Device [{}]: {} — {:?}", self.devices.len(), name, formats);
                }
                self.devices.push((name, device));
            }
        }

        log::info!(
            "[{}] Enumerated {} input devices (default: {:?})",
            self.host_name,
            self.devices.len(),
            self.default_device_name
        );
    }

    /// Return device info list for the UI.
    pub fn device_list(&self) -> Vec<DeviceInfo> {
        self.devices
            .iter()
            .enumerate()
            .map(|(i, (name, _))| DeviceInfo {
                name: name.clone(),
                index: i,
                is_default: Some(name.as_str()) == self.default_device_name.as_deref(),
            })
            .collect()
    }

    /// Return the current host name for display.
    pub fn host_name(&self) -> &str {
        &self.host_name
    }

    /// Start capturing audio from the device at `device_index`.
    ///
    /// Returns a ring-buffer consumer that yields mono f32 samples.
    pub fn start(&mut self, device_index: usize) -> Result<ringbuf::HeapCons<f32>, String> {
        self.stop();

        let (name, device) = self
            .devices
            .get(device_index)
            .ok_or_else(|| format!("Device index {} out of range", device_index))?;
        log::info!("Starting capture on: {}", name);

        // Get default config
        let supported_config = device
            .default_input_config()
            .map_err(|e| format!("No default input config: {}", e))?;

        let sample_format = supported_config.sample_format();
        let sample_rate = supported_config.sample_rate();
        let channels = supported_config.channels() as usize;

        log::info!(
            "  Config: format={:?}, rate={} Hz, channels={}",
            sample_format,
            sample_rate,
            channels
        );

        self.sample_rate = sample_rate;

        // Ring buffer: ~2 seconds of mono audio
        let buf_size = (sample_rate as usize) * 2;
        let rb = ringbuf::HeapRb::<f32>::new(buf_size);
        let (producer, consumer) = rb.split();

        let err_fn = |err: cpal::StreamError| {
            log::error!("Audio stream error: {}", err);
        };

        // Build the stream config
        let stream_config: cpal::StreamConfig = supported_config.config();

        // Build stream with the device's native sample format.
        // We convert everything to mono f32 in the callback.
        let stream = match sample_format {
            cpal::SampleFormat::F32 => {
                Self::build_stream::<f32>(device, &stream_config, producer, channels, err_fn)?
            }
            cpal::SampleFormat::I16 => {
                Self::build_stream::<i16>(device, &stream_config, producer, channels, err_fn)?
            }
            cpal::SampleFormat::I32 => {
                Self::build_stream::<i32>(device, &stream_config, producer, channels, err_fn)?
            }
            cpal::SampleFormat::U16 => {
                Self::build_stream::<u16>(device, &stream_config, producer, channels, err_fn)?
            }
            fmt => return Err(format!("Unsupported sample format: {:?}", fmt)),
        };

        stream
            .play()
            .map_err(|e| format!("Failed to play stream: {}", e))?;

        self.active_stream = Some(stream);
        log::info!(
            "Capturing: {} Hz, {} ch → mono, format {:?} [{}]",
            sample_rate, channels, sample_format, self.host_name
        );

        Ok(consumer)
    }

    /// Build an input stream for a specific sample type, converting to mono f32.
    fn build_stream<T>(
        device: &cpal::Device,
        config: &cpal::StreamConfig,
        mut producer: ringbuf::HeapProd<f32>,
        channels: usize,
        err_fn: impl FnMut(cpal::StreamError) + Send + 'static,
    ) -> Result<cpal::Stream, String>
    where
        T: cpal::SizedSample + Send + 'static,
        f32: cpal::FromSample<T>,
    {
        use cpal::Sample;

        device
            .build_input_stream(
                config,
                move |data: &[T], _: &cpal::InputCallbackInfo| {
                    for chunk in data.chunks(channels) {
                        let mono: f32 = chunk
                            .iter()
                            .map(|&s| <f32 as Sample>::from_sample(s))
                            .sum::<f32>()
                            / channels as f32;
                        let _ = producer.try_push(mono);
                    }
                },
                err_fn,
                None,
            )
            .map_err(|e| format!("Failed to build input stream: {}", e))
    }

    /// Stop the active capture stream.
    pub fn stop(&mut self) {
        if let Some(stream) = self.active_stream.take() {
            drop(stream);
            log::info!("Audio capture stopped");
        }
    }
}
