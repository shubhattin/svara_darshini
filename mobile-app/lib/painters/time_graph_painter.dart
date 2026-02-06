import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/audio_info.dart';

/// Data point for the time graph
class GraphDataPoint {
  final double yRatio;
  final double pitch;
  final String note;
  final int clarity;
  final int originalIndex;
  final int scale;

  GraphDataPoint({
    required this.yRatio,
    required this.pitch,
    required this.note,
    required this.clarity,
    required this.originalIndex,
    required this.scale,
  });
}

/// Custom painter for the pitch time graph
class TimeGraphPainter extends CustomPainter {
  final List<PitchHistoryPoint> pitchHistory;
  final String saAt;
  final String bottomStartNote;
  final bool isDarkMode;
  final int maxPoints;

  TimeGraphPainter({
    required this.pitchHistory,
    required this.saAt,
    required this.bottomStartNote,
    required this.isDarkMode,
    required this.maxPoints,
  });

  // Graph dimensions (relative)
  static const double graphWidth = 720;
  static const double graphHeight = 280;
  static const double paddingTop = 10;
  static const double paddingLeft = 60;

  List<String> get notesCustomStart {
    final startIndex = notes.indexOf(bottomStartNote);
    return [...notes.sublist(startIndex), ...notes.sublist(0, startIndex)];
  }

  List<String> get sargamCustomStart {
    final sargamKeys = sargam.map((s) => s.key).toList();
    final notesIndex = notesCustomStart.indexOf(saAt);
    final result = List<String>.filled(notes.length, '');
    for (int i = 0; i < notes.length; i++) {
      result[(i + notesIndex) % notes.length] = sargamKeys[i];
    }
    return result;
  }

  double getXPosOnGraph(int index) {
    return (index / (maxPoints - 1)) * graphWidth + paddingLeft;
  }

  double getYPosOnGraph(double yRatio) {
    return graphHeight + paddingTop - yRatio * graphHeight;
  }

  double? frequencyToYPositionRatio(double frequency) {
    if (!frequency.isFinite || frequency <= 0) return null;

    const a0Freq = 27.5;
    final semitoneOffset = 12 * (log(frequency / a0Freq) / log(2));
    final semitoneInOctave = ((semitoneOffset % 12) + 12) % 12;
    final baseIndex = notesStartingWithA.indexOf(bottomStartNote);
    final semitoneRelative = (semitoneInOctave - baseIndex + 12) % 12;
    final normalized = ((semitoneRelative + 1) / 12) * 100;
    return min(max(normalized, 0), 100) / 100;
  }

  List<GraphDataPoint> get graphData {
    return pitchHistory
        .asMap()
        .entries
        .map((entry) {
          final yPos = frequencyToYPositionRatio(entry.value.pitch);
          if (yPos == null) return null;
          return GraphDataPoint(
            yRatio: yPos,
            pitch: entry.value.pitch,
            note: entry.value.note,
            clarity: entry.value.clarity,
            originalIndex: entry.key,
            scale: entry.value.scale,
          );
        })
        .where((p) => p != null)
        .cast<GraphDataPoint>()
        .toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / (graphWidth + paddingLeft + 20);
    final scaleY = size.height / (graphHeight + paddingTop + 10);
    final scale = min(scaleX, scaleY);

    canvas.save();
    canvas.scale(scale);

    // Draw grid lines and labels
    _drawGridAndLabels(canvas);

    // Draw data path
    final data = graphData;
    if (data.isNotEmpty) {
      _drawDataPath(canvas, data);
      _drawCurrentIndicator(canvas, data);
    }

    // Draw axes
    _drawAxes(canvas);

    canvas.restore();
  }

  void _drawGridAndLabels(Canvas canvas) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE5E7EB).withValues(alpha: 0.5);

    final notesReversed = notesCustomStart.reversed.toList();
    final sargamReversed = sargamCustomStart.reversed.toList();

    for (int i = 0; i <= 12; i++) {
      final noteName = i < 12 ? notesReversed[i] : null;
      final sargamKey = i < 12 ? sargamReversed[i] : null;
      final y = (i / 12) * graphHeight + paddingTop;

      // Grid line
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(paddingLeft + graphWidth, y),
        linePaint,
      );

      if (noteName != null) {
        // Color dot
        final noteColor = Color(noteColors[noteName] ?? 0xFFCCCCCC);
        canvas.drawCircle(
          Offset(paddingLeft - 5, y),
          2,
          Paint()..color = noteColor,
        );

        // Note label
        final noteTextPainter = TextPainter(
          text: TextSpan(
            text: noteName,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 10,
              fontWeight: i == notesCustomStart.length - 1
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
        );
        noteTextPainter.layout();
        noteTextPainter.paint(
          canvas,
          Offset(
            paddingLeft - 12 - noteTextPainter.width,
            y - noteTextPainter.height / 2,
          ),
        );

        // Sargam label
        if (sargamKey != null) {
          final sargamTextPainter = TextPainter(
            text: TextSpan(
              text: sargamKey,
              style: TextStyle(
                color: sargamKey == 's'
                    ? (isDarkMode ? Colors.grey[200] : Colors.grey[500])
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 10,
                fontWeight: sargamKey == 's'
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
          );
          sargamTextPainter.layout();
          sargamTextPainter.paint(
            canvas,
            Offset(
              paddingLeft - 32 - sargamTextPainter.width,
              y - sargamTextPainter.height / 2,
            ),
          );
        }
      }
    }
  }

  void _drawDataPath(Canvas canvas, List<GraphDataPoint> data) {
    if (data.isEmpty) return;

    // Create gradient shader
    final gradientColors = notesCustomStart
        .map((note) => Color(noteColors[note] ?? 0xFFCCCCCC))
        .toList();
    final stops = List.generate(
      notesCustomStart.length,
      (i) => i / (notesCustomStart.length - 1),
    );

    final gradient = ui.Gradient.linear(
      Offset(0, graphHeight + paddingTop),
      Offset(0, paddingTop),
      gradientColors,
      stops,
    );

    final normalPath = Path();
    final faintPath = Path();

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = getXPosOnGraph(point.originalIndex);
      final y = getYPosOnGraph(point.yRatio);

      if (i == 0) {
        normalPath.moveTo(x, y);
      } else {
        final prev = data[i - 1];
        final prevX = getXPosOnGraph(prev.originalIndex);
        final prevY = getYPosOnGraph(prev.yRatio);
        final deltaPitch = point.pitch - prev.pitch;
        final deltaY = y - prevY;

        final isJump =
            (deltaPitch > 0 && deltaY > 0) || (deltaPitch < 0 && deltaY < 0);

        if (isJump) {
          // Add to faint path
          faintPath.moveTo(prevX, prevY);
          _addCurve(faintPath, prevX, prevY, x, y);

          // Start new segment in normal path
          normalPath.moveTo(x, y);
        } else {
          _addCurve(normalPath, prevX, prevY, x, y);
        }
      }
    }

    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = gradient;

    // Draw faint path first
    if (faintPath.getBounds().width > 0) {
      canvas.drawPath(
        faintPath,
        pathPaint..color = pathPaint.color.withValues(alpha: 0.3),
      );
    }

    // Draw normal path
    canvas.drawPath(normalPath, pathPaint);
  }

  void _addCurve(Path path, double x1, double y1, double x2, double y2) {
    const smoothing = 0.3;
    final dx = x2 - x1;
    final cp1x = x1 + dx * smoothing;
    final cp2x = x2 - dx * smoothing;
    path.cubicTo(cp1x, y1, cp2x, y2, x2, y2);
  }

  void _drawCurrentIndicator(Canvas canvas, List<GraphDataPoint> data) {
    if (data.isEmpty) return;

    final lastPoint = data.last;
    final lastX = getXPosOnGraph(lastPoint.originalIndex);
    final lastY = getYPosOnGraph(lastPoint.yRatio);

    // Red dot
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = const Color(0xFFEF4444),
    );

    // Label
    final isRightSide = lastX > (graphWidth + paddingLeft) * 0.85;
    final isNearTop = lastY < paddingTop + 20;
    final indicatorX = isRightSide ? lastX - 10 : lastX + 10;
    final indicatorY = isNearTop ? lastY + 20 : lastY - 10;

    final labelText =
        '${lastPoint.pitch.toStringAsFixed(1)} Hz (${lastPoint.note}${lastPoint.scale})';
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: (isDarkMode ? Colors.grey[200] : Colors.grey[800])?.withValues(
            alpha: 0.85,
          ),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: isRightSide ? TextAlign.end : TextAlign.start,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        isRightSide ? indicatorX - textPainter.width : indicatorX,
        indicatorY - textPainter.height / 2,
      ),
    );
  }

  void _drawAxes(Canvas canvas) {
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF374151);

    // Y axis
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, graphHeight + paddingTop),
      axisPaint,
    );

    // X axis
    canvas.drawLine(
      Offset(paddingLeft, graphHeight + paddingTop),
      Offset(paddingLeft + graphWidth, graphHeight + paddingTop),
      axisPaint..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant TimeGraphPainter oldDelegate) {
    return pitchHistory.length != oldDelegate.pitchHistory.length ||
        saAt != oldDelegate.saAt ||
        bottomStartNote != oldDelegate.bottomStartNote ||
        isDarkMode != oldDelegate.isDarkMode;
  }
}
