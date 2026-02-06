/// Data models for audio/pitch information.

/// Represents current pitch detection information
class AudioInfo {
  final double pitch;
  final int clarity;
  final String note;
  final int scale;
  final int detune;

  const AudioInfo({
    required this.pitch,
    required this.clarity,
    required this.note,
    required this.scale,
    required this.detune,
  });

  /// Empty/default audio info
  static const AudioInfo empty = AudioInfo(
    pitch: 0,
    clarity: 0,
    note: '',
    scale: 0,
    detune: 0,
  );

  bool get isValid => pitch > 0 && note.isNotEmpty;

  AudioInfo copyWith({
    double? pitch,
    int? clarity,
    String? note,
    int? scale,
    int? detune,
  }) {
    return AudioInfo(
      pitch: pitch ?? this.pitch,
      clarity: clarity ?? this.clarity,
      note: note ?? this.note,
      scale: scale ?? this.scale,
      detune: detune ?? this.detune,
    );
  }
}

/// Represents a single point in pitch history for time graph
class PitchHistoryPoint {
  final DateTime time;
  final double pitch;
  final String note;
  final int clarity;
  final int scale;

  const PitchHistoryPoint({
    required this.time,
    required this.pitch,
    required this.note,
    required this.clarity,
    required this.scale,
  });
}

/// Input mode for audio source
enum InputMode {
  mic,
  file,
}

/// Orientation type for labels
enum LabelOrientation {
  radial,
  vertical,
}

/// Pitch display type
enum PitchDisplayType {
  circularScale,
  timeGraph,
}
