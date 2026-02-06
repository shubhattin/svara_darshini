import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/audio_info.dart';

/// Provider for app-wide settings with persistence
class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _saAtKey = 'sa_at';
  static const String _sargamOrientationKey = 'sargam_orientation';
  static const String _noteOrientationKey = 'note_orientation';
  static const String _displayTypeKey = 'display_type';
  static const String _timeGraphSaAtKey = 'time_graph_sa_at';
  static const String _timeGraphBottomNoteKey = 'time_graph_bottom_note';
  static const String _selectedDeviceKey = 'selected_device';

  SharedPreferences? _prefs;

  // Theme
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Circular scale settings
  String _saAt = 'C';
  String get saAt => _saAt;

  LabelOrientation _sargamOrientation = LabelOrientation.vertical;
  LabelOrientation get sargamOrientation => _sargamOrientation;

  LabelOrientation _noteOrientation = LabelOrientation.vertical;
  LabelOrientation get noteOrientation => _noteOrientation;

  // Display type
  PitchDisplayType _displayType = PitchDisplayType.circularScale;
  PitchDisplayType get displayType => _displayType;

  // Time graph settings
  String _timeGraphSaAt = 'C';
  String get timeGraphSaAt => _timeGraphSaAt;

  String _timeGraphBottomNote = 'C';
  String get timeGraphBottomNote => _timeGraphBottomNote;

  // Selected audio device
  String _selectedDevice = 'default';
  String get selectedDevice => _selectedDevice;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Load theme
    final themeString = _prefs?.getString(_themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }

    // Load circular scale settings
    _saAt = _prefs?.getString(_saAtKey) ?? 'C';

    final sargamOrientationString = _prefs?.getString(_sargamOrientationKey);
    if (sargamOrientationString != null) {
      _sargamOrientation = LabelOrientation.values.firstWhere(
        (e) => e.name == sargamOrientationString,
        orElse: () => LabelOrientation.vertical,
      );
    }

    final noteOrientationString = _prefs?.getString(_noteOrientationKey);
    if (noteOrientationString != null) {
      _noteOrientation = LabelOrientation.values.firstWhere(
        (e) => e.name == noteOrientationString,
        orElse: () => LabelOrientation.vertical,
      );
    }

    // Load display type
    final displayTypeString = _prefs?.getString(_displayTypeKey);
    if (displayTypeString != null) {
      _displayType = PitchDisplayType.values.firstWhere(
        (e) => e.name == displayTypeString,
        orElse: () => PitchDisplayType.circularScale,
      );
    }

    // Load time graph settings
    _timeGraphSaAt = _prefs?.getString(_timeGraphSaAtKey) ?? 'C';
    _timeGraphBottomNote = _prefs?.getString(_timeGraphBottomNoteKey) ?? 'C';

    // Load selected device
    _selectedDevice = _prefs?.getString(_selectedDeviceKey) ?? 'default';

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString(_themeKey, mode.name);
    notifyListeners();
  }

  void setSaAt(String note) {
    _saAt = note;
    _prefs?.setString(_saAtKey, note);
    notifyListeners();
  }

  void setSargamOrientation(LabelOrientation orientation) {
    _sargamOrientation = orientation;
    _prefs?.setString(_sargamOrientationKey, orientation.name);
    notifyListeners();
  }

  void setNoteOrientation(LabelOrientation orientation) {
    _noteOrientation = orientation;
    _prefs?.setString(_noteOrientationKey, orientation.name);
    notifyListeners();
  }

  void setDisplayType(PitchDisplayType type) {
    _displayType = type;
    _prefs?.setString(_displayTypeKey, type.name);
    notifyListeners();
  }

  void setTimeGraphSaAt(String note) {
    _timeGraphSaAt = note;
    _prefs?.setString(_timeGraphSaAtKey, note);
    notifyListeners();
  }

  void setTimeGraphBottomNote(String note) {
    _timeGraphBottomNote = note;
    _prefs?.setString(_timeGraphBottomNoteKey, note);
    notifyListeners();
  }

  void setSelectedDevice(String deviceId) {
    _selectedDevice = deviceId;
    _prefs?.setString(_selectedDeviceKey, deviceId);
    notifyListeners();
  }
}
