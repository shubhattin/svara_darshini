import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/audio_info.dart';
import '../core/constants.dart';
import '../painters/time_graph_painter.dart';
import '../providers/settings_provider.dart';

/// Widget displaying the pitch time graph with controls
class TimeGraphDisplay extends StatelessWidget {
  final List<PitchHistoryPoint> pitchHistory;
  final VoidCallback onStop;
  final VoidCallback onTogglePause;
  final bool isPaused;
  final InputMode inputMode;

  const TimeGraphDisplay({
    super.key,
    required this.pitchHistory,
    required this.onStop,
    required this.onTogglePause,
    required this.isPaused,
    required this.inputMode,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Controls row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNoteSelector(
                context,
                label: 'Sa at',
                value: settings.timeGraphSaAt,
                onChanged: settings.setTimeGraphSaAt,
              ),
              const SizedBox(width: 24),
              _buildNoteSelector(
                context,
                label: 'Bottom Note',
                value: settings.timeGraphBottomNote,
                onChanged: settings.setTimeGraphBottomNote,
              ),
            ],
          ),
        ),

        // Graph
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomPaint(
              painter: TimeGraphPainter(
                pitchHistory: pitchHistory,
                saAt: settings.timeGraphSaAt,
                bottomStartNote: settings.timeGraphBottomNote,
                isDarkMode: isDarkMode,
                maxPoints: maxPitchHistoryPoints,
              ),
              size: Size.infinite,
            ),
          ),
        ),

        // Control buttons (only for mic mode)
        if (inputMode == InputMode.mic) ...[
          const SizedBox(height: 12),
          _buildControlButtons(context),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildNoteSelector(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => notesStartingWithA.map((note) {
        return PopupMenuItem(
          value: note,
          child: Text(
            note,
            style: TextStyle(
              fontWeight: value == note ? FontWeight.bold : FontWeight.normal,
              color: value == note
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
            Text(
              '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(value, style: const TextStyle(fontSize: 13)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onTogglePause,
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(isPaused ? 'Play' : 'Pause'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
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
