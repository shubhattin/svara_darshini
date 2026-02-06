import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/audio_info.dart';
import '../core/constants.dart';
import '../painters/circular_pitch_painter.dart';
import '../providers/settings_provider.dart';

/// Widget displaying the circular pitch scale with controls
class CircularScaleDisplay extends StatelessWidget {
  final AudioInfo audioInfo;
  final VoidCallback onStop;
  final VoidCallback onTogglePause;
  final bool isPaused;

  const CircularScaleDisplay({
    super.key,
    required this.audioInfo,
    required this.onStop,
    required this.onTogglePause,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sa at selector
        _buildSaAtSelector(context, settings),
        const SizedBox(height: 8),

        // Circular pitch display
        SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: CircularPitchPainter(
              audioInfo: audioInfo,
              saAt: settings.saAt,
              sargamOrientation: settings.sargamOrientation,
              noteOrientation: settings.noteOrientation,
              isDarkMode: isDarkMode,
            ),
            size: const Size(280, 280),
          ),
        ),
        const SizedBox(height: 16),

        // Frequency display
        Text(
          '${audioInfo.pitch.toStringAsFixed(1)} Hz',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // Clarity bar
        _buildClarityBar(context, audioInfo.clarity),
        const SizedBox(height: 12),

        // Orientation selector
        _buildOrientationSelector(context, settings),
        const SizedBox(height: 20),

        // Control buttons
        _buildControlButtons(context),
      ],
    );
  }

  Widget _buildSaAtSelector(BuildContext context, SettingsProvider settings) {
    return PopupMenuButton<String>(
      initialValue: settings.saAt,
      onSelected: settings.setSaAt,
      itemBuilder: (context) => notesStartingWithA.map((note) {
        return PopupMenuItem(
          value: note,
          child: Text(
            note,
            style: TextStyle(
              fontWeight: settings.saAt == note
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: settings.saAt == note
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('S at ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(settings.saAt),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildClarityBar(BuildContext context, int clarity) {
    return Column(
      children: [
        const Text(
          'Clarity',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 220,
          child: LinearProgressIndicator(
            value: clarity / 100,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationSelector(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return PopupMenuButton<void>(
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sargam',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<LabelOrientation>(
                        value: LabelOrientation.vertical,
                        groupValue: settings.sargamOrientation,
                        onChanged: (v) {
                          settings.setSargamOrientation(v!);
                          setState(() {});
                        },
                      ),
                      const Text('Vertical', style: TextStyle(fontSize: 13)),
                      Radio<LabelOrientation>(
                        value: LabelOrientation.radial,
                        groupValue: settings.sargamOrientation,
                        onChanged: (v) {
                          settings.setSargamOrientation(v!);
                          setState(() {});
                        },
                      ),
                      const Text('Radial', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<LabelOrientation>(
                        value: LabelOrientation.vertical,
                        groupValue: settings.noteOrientation,
                        onChanged: (v) {
                          settings.setNoteOrientation(v!);
                          setState(() {});
                        },
                      ),
                      const Text('Vertical', style: TextStyle(fontSize: 13)),
                      Radio<LabelOrientation>(
                        value: LabelOrientation.radial,
                        groupValue: settings.noteOrientation,
                        onChanged: (v) {
                          settings.setNoteOrientation(v!);
                          setState(() {});
                        },
                      ),
                      const Text('Radial', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Orientation', style: TextStyle(fontWeight: FontWeight.bold)),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Play button
        ElevatedButton.icon(
          onPressed: onTogglePause,
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(isPaused ? 'Play' : 'Pause'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        // Stop button
        ElevatedButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
