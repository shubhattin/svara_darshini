import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/audio_info.dart';
import '../core/constants.dart';
import '../painters/circular_pitch_painter.dart';
import '../providers/pitch_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/circular_scale_display.dart';
import '../widgets/time_graph_display.dart';

/// Main home screen of the app
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Demo animation
  late AnimationController _demoController;
  Timer? _demoUpdateTimer;
  AudioInfo _demoAudioInfo = const AudioInfo(
    pitch: 440,
    clarity: 85,
    note: 'A',
    scale: 4,
    detune: 0,
  );

  @override
  void initState() {
    super.initState();
    _initDemoAnimation();
  }

  void _initDemoAnimation() {
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Animate demo note changes
    _demoUpdateTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) {
      setState(() {
        final noteIndex =
            (notes.indexOf(_demoAudioInfo.note) + 1) % notes.length;
        final newNote = notes[noteIndex];
        final detune = (sin(DateTime.now().millisecondsSinceEpoch / 500) * 30)
            .round();

        _demoAudioInfo = AudioInfo(
          pitch: getNoteFrequency(60 + noteIndex),
          clarity:
              75 +
              (sin(DateTime.now().millisecondsSinceEpoch / 1000) * 20).round(),
          note: newNote,
          scale: 4,
          detune: detune,
        );
      });
    });
  }

  @override
  void dispose() {
    _demoController.dispose();
    _demoUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pitchProvider = context.watch<PitchProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: pitchProvider.isStarted
            ? _buildActiveContent(context, pitchProvider, settings)
            : _buildWelcomeContent(context, settings),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Svara Darshini'),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent(BuildContext context, SettingsProvider settings) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Demo circular display
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: CircularPitchPainter(
                audioInfo: _demoAudioInfo,
                saAt: settings.saAt,
                sargamOrientation: settings.sargamOrientation,
                noteOrientation: settings.noteOrientation,
                isDarkMode: isDarkMode,
                isDemo: true,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Welcome text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Welcome to',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Svara Darshini',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'स्वरदर्शिनी',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A pitch visualization tool for Indian classical music',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Display type selector
          _buildDisplayTypeSelector(context, settings),
          const SizedBox(height: 24),

          // Start button
          ElevatedButton.icon(
            onPressed: () => context.read<PitchProvider>().start(),
            icon: const Icon(Icons.mic, size: 24),
            label: const Text('Start', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDisplayTypeSelector(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDisplayTypeButton(
          context,
          icon: Icons.radio_button_unchecked,
          label: 'Circular',
          isSelected: settings.displayType == PitchDisplayType.circularScale,
          onTap: () => settings.setDisplayType(PitchDisplayType.circularScale),
        ),
        const SizedBox(width: 16),
        _buildDisplayTypeButton(
          context,
          icon: Icons.show_chart,
          label: 'Time Graph',
          isSelected: settings.displayType == PitchDisplayType.timeGraph,
          onTap: () => settings.setDisplayType(PitchDisplayType.timeGraph),
        ),
      ],
    );
  }

  Widget _buildDisplayTypeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent(
    BuildContext context,
    PitchProvider pitchProvider,
    SettingsProvider settings,
  ) {
    return Column(
      children: [
        // Display type tabs
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildDisplayTypeSelector(context, settings),
        ),

        // Debug info (temporary)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Samples: ${pitchProvider.samplesProcessed}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 16),
              if (pitchProvider.lastError.isNotEmpty)
                Text(
                  'Error: ${pitchProvider.lastError}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: settings.displayType == PitchDisplayType.circularScale
              ? CircularScaleDisplay(
                  audioInfo: pitchProvider.displayAudioInfo,
                  onStop: pitchProvider.stop,
                  onTogglePause: pitchProvider.togglePause,
                  isPaused: pitchProvider.isPaused,
                )
              : TimeGraphDisplay(
                  pitchHistory: pitchProvider.displayPitchHistory,
                  onStop: pitchProvider.stop,
                  onTogglePause: pitchProvider.togglePause,
                  isPaused: pitchProvider.isPaused,
                  inputMode: pitchProvider.inputMode,
                ),
        ),
      ],
    );
  }
}
