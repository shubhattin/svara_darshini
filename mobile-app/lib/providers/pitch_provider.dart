import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import '../core/audio_info.dart';
import '../core/constants.dart';

/// Provider for pitch detection and audio state
class PitchProvider extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  PitchDetector? _pitchDetector;
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // Audio buffer for accumulating samples
  List<double> _audioBuffer = [];

  // State
  bool _isStarted = false;
  bool get isStarted => _isStarted;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  AudioInfo _currentAudioInfo = AudioInfo.empty;
  AudioInfo get currentAudioInfo => _currentAudioInfo;

  AudioInfo? _pausedAudioInfo;
  AudioInfo get displayAudioInfo => _isPaused && _pausedAudioInfo != null
      ? _pausedAudioInfo!
      : _currentAudioInfo;

  List<PitchHistoryPoint> _pitchHistory = [];
  List<PitchHistoryPoint> get pitchHistory => _pitchHistory;

  List<PitchHistoryPoint>? _pausedPitchHistory;
  List<PitchHistoryPoint> get displayPitchHistory =>
      _isPaused && _pausedPitchHistory != null
      ? _pausedPitchHistory!
      : _pitchHistory;

  InputMode _inputMode = InputMode.mic;
  InputMode get inputMode => _inputMode;

  List<InputDevice> _availableDevices = [];
  List<InputDevice> get availableDevices => _availableDevices;

  bool _devicesLoaded = false;
  bool get devicesLoaded => _devicesLoaded;

  String? _selectedDeviceId;
  String? get selectedDeviceId => _selectedDeviceId;

  // Debug state
  String _lastError = '';
  String get lastError => _lastError;
  int _samplesProcessed = 0;
  int get samplesProcessed => _samplesProcessed;

  PitchProvider() {
    _initPitchDetector();
    _loadDevices();
  }

  void _initPitchDetector() {
    _pitchDetector = PitchDetector(audioSampleRate: 44100, bufferSize: fftSize);
    debugPrint(
      'PitchDetector initialized with sampleRate=44100, bufferSize=$fftSize',
    );
  }

  Future<void> _loadDevices() async {
    try {
      _availableDevices = await _recorder.listInputDevices();
      _devicesLoaded = true;
      if (_availableDevices.isNotEmpty && _selectedDeviceId == null) {
        _selectedDeviceId = _availableDevices.first.id;
      }
      debugPrint('Loaded ${_availableDevices.length} input devices');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading devices: $e');
      _lastError = 'Error loading devices: $e';
      _devicesLoaded = true;
      notifyListeners();
    }
  }

  Future<void> refreshDevices() async {
    _devicesLoaded = false;
    notifyListeners();
    await _loadDevices();
  }

  void setInputMode(InputMode mode) {
    if (_isStarted && _inputMode != mode) {
      stop();
    }
    _inputMode = mode;
    notifyListeners();
  }

  void setSelectedDevice(String deviceId) {
    _selectedDeviceId = deviceId;
    if (_isStarted) {
      stop();
      start();
    }
    notifyListeners();
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    debugPrint('Microphone permission status: $status');
    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      debugPrint('Microphone permission request result: $result');
      return result.isGranted;
    }

    return false;
  }

  Future<void> start() async {
    if (_inputMode == InputMode.mic) {
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        debugPrint('Microphone permission not granted');
        _lastError = 'Microphone permission not granted';
        notifyListeners();
        return;
      }

      try {
        debugPrint('Starting audio stream...');

        // Start recording audio stream
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 44100,
            numChannels: 1,
          ),
        );

        debugPrint('Audio stream started successfully');

        _isStarted = true;
        _isPaused = false;
        _pitchHistory = [];
        _audioBuffer = [];
        _samplesProcessed = 0;
        _lastError = '';
        notifyListeners();

        // Process audio stream
        _audioStreamSubscription = stream.listen(
          (data) {
            _processAudioData(data);
          },
          onError: (error) {
            debugPrint('Audio stream error: $error');
            _lastError = 'Audio stream error: $error';
            notifyListeners();
          },
          onDone: () {
            debugPrint('Audio stream completed');
          },
        );
      } catch (e) {
        debugPrint('Error starting recording: $e');
        _lastError = 'Error starting recording: $e';
        notifyListeners();
      }
    }
  }

  void _processAudioData(Uint8List data) {
    if (_isPaused || !_isStarted) return;

    try {
      // Convert PCM16 bytes to float samples (-1.0 to 1.0)
      for (int i = 0; i < data.length - 1; i += 2) {
        // Little-endian 16-bit signed integer
        final sample = (data[i] | (data[i + 1] << 8)).toSigned(16);
        _audioBuffer.add(sample / 32768.0);
      }

      _samplesProcessed += data.length ~/ 2;

      // Process when we have enough samples
      while (_audioBuffer.length >= fftSize) {
        _detectPitch(_audioBuffer.sublist(0, fftSize));
        // Overlap: keep half of the buffer for next detection
        _audioBuffer = _audioBuffer.sublist(fftSize ~/ 2);
      }
    } catch (e) {
      debugPrint('Error processing audio data: $e');
      _lastError = 'Error processing audio: $e';
    }
  }

  Future<void> _detectPitch(List<double> samples) async {
    try {
      final result = await _pitchDetector?.getPitchFromFloatBuffer(samples);

      if (result != null && result.pitched && result.pitch > 0) {
        final pitch = result.pitch;
        final clarity = (result.probability * 100).round();

        final noteNumber = getNoteNumberFromPitch(pitch);
        final noteName = getNoteNameFromNumber(noteNumber);
        final scale = getScaleFromNoteNumber(noteNumber);
        final detune = getDetuneFromPitch(pitch, noteNumber);

        _currentAudioInfo = AudioInfo(
          pitch: pitch,
          clarity: clarity,
          note: noteName,
          scale: scale,
          detune: detune,
        );

        // Add to history
        _pitchHistory.add(
          PitchHistoryPoint(
            time: DateTime.now(),
            pitch: pitch,
            note: noteName,
            clarity: clarity,
            scale: scale,
          ),
        );

        // Keep only last N points
        if (_pitchHistory.length > maxPitchHistoryPoints) {
          _pitchHistory = _pitchHistory.sublist(
            _pitchHistory.length - maxPitchHistoryPoints,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error detecting pitch: $e');
      _lastError = 'Error detecting pitch: $e';
    }
  }

  void pause() {
    if (!_isStarted) return;
    _isPaused = true;
    _pausedAudioInfo = _currentAudioInfo;
    _pausedPitchHistory = List.from(_pitchHistory);
    notifyListeners();
  }

  void resume() {
    if (!_isStarted) return;
    _isPaused = false;
    notifyListeners();
  }

  void togglePause() {
    if (_isPaused) {
      resume();
    } else {
      pause();
    }
  }

  Future<void> stop() async {
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }

    _isStarted = false;
    _isPaused = false;
    _currentAudioInfo = AudioInfo.empty;
    _pitchHistory = [];
    _audioBuffer = [];
    _pausedAudioInfo = null;
    _pausedPitchHistory = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioStreamSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
