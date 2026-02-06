import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/audio_info.dart';

/// Custom painter for the circular pitch display
class CircularPitchPainter extends CustomPainter {
  final AudioInfo audioInfo;
  final String saAt;
  final LabelOrientation sargamOrientation;
  final LabelOrientation noteOrientation;
  final bool isDarkMode;
  final bool isDemo;

  CircularPitchPainter({
    required this.audioInfo,
    required this.saAt,
    required this.sargamOrientation,
    required this.noteOrientation,
    required this.isDarkMode,
    this.isDemo = false,
  });

  // Radii constants (matching Svelte version)
  static const double outerCircleSargamRadius = 92;
  static const double sargamLabelRadius = 80;
  static const double innerCircleNoteRadius = 70;
  static const double noteLabelRadius = 54;
  static const double frequencyCircleRadius = 43;
  static const double middleCircleRadius = 30;
  static const double noteTickLength = 5;
  static const double needleLineLength = 75;

  int get saAtIndex => notes.indexOf(saAt);
  int get noteIndex => notes.indexOf(audioInfo.note);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = min(size.width, size.height) / 200; // viewBox was -100 to 100

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(
        alpha: 0.7,
      );

    // Outer circle for Sargam
    canvas.drawCircle(Offset.zero, outerCircleSargamRadius, circlePaint);

    // Inner circle for Notes
    canvas.drawCircle(
      Offset.zero,
      innerCircleNoteRadius,
      circlePaint..strokeWidth = 1,
    );

    // Frequency circle
    canvas.drawCircle(
      Offset.zero,
      frequencyCircleRadius,
      circlePaint..strokeWidth = 0.5,
    );

    // Draw note markers and labels (rotated based on Sa)
    _drawNoteLabels(canvas);

    // Draw Sargam labels
    _drawSargamLabels(canvas);

    // Draw fine tick marks for cents
    _drawCentsTicks(canvas);

    // Draw needle (if we have valid audio info)
    if (audioInfo.isValid) {
      _drawNeedle(canvas);
      _drawSector(canvas);
      _drawCenterText(canvas);
    }

    canvas.restore();
  }

  void _drawNoteLabels(Canvas canvas) {
    canvas.save();
    // Rotate the note labels based on Sa selection
    canvas.rotate(-saAtIndex * 30 * pi / 180);

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = isDarkMode ? Colors.white : Colors.black;

    for (int i = 0; i < notes.length; i++) {
      final angle = i * 30 - 90;
      final radAngle = angle * pi / 180;
      final labelRadius =
          noteLabelRadius +
          (noteOrientation == LabelOrientation.vertical ? 1.5 : 0.8);

      final x = labelRadius * cos(radAngle);
      final y = labelRadius * sin(radAngle);

      // Draw tick
      canvas.save();
      canvas.rotate(angle * pi / 180);
      canvas.drawLine(
        Offset(0, -innerCircleNoteRadius),
        Offset(0, -(innerCircleNoteRadius - noteTickLength)),
        tickPaint,
      );
      canvas.restore();

      // Draw note label
      canvas.save();
      canvas.translate(x, y);

      if (noteOrientation == LabelOrientation.radial) {
        canvas.rotate((angle + 90) * pi / 180);
      } else {
        canvas.rotate(saAtIndex * 30 * pi / 180);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: notes[i],
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            fontSize: 7,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawSargamLabels(Canvas canvas) {
    final labelRadius =
        sargamLabelRadius +
        (sargamOrientation == LabelOrientation.vertical ? 0.55 : 1.52);

    for (int i = 0; i < sargam.length; i++) {
      final angle = i * (360 / sargam.length) - 90;
      final radAngle = angle * pi / 180;

      final x = labelRadius * cos(radAngle);
      final y = labelRadius * sin(radAngle);

      canvas.save();
      canvas.translate(x, y);

      if (sargamOrientation == LabelOrientation.radial) {
        canvas.rotate((angle + 90) * pi / 180);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: sargam[i].key,
          style: TextStyle(
            color: (isDarkMode ? Colors.grey[200] : Colors.grey[800])
                ?.withValues(alpha: 0.9),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            fontFamily: 'ome_bhatkhande_en', // Custom font for sargam notation
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  void _drawCentsTicks(Canvas canvas) {
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(
        alpha: 0.7,
      );

    for (int i = 0; i < 60; i++) {
      final angle = i * 6 - 90;
      final isMajor = i % 5 == 0;

      canvas.save();
      canvas.rotate(angle * pi / 180);

      tickPaint.strokeWidth = isMajor ? 1 : 0.5;
      final tickEnd = isMajor
          ? -(innerCircleNoteRadius - noteTickLength)
          : -(innerCircleNoteRadius - (noteTickLength / 2).ceil());

      canvas.drawLine(
        Offset(0, -innerCircleNoteRadius),
        Offset(0, tickEnd),
        tickPaint,
      );
      canvas.restore();
    }
  }

  double _centsToRotation(int cents, String note) {
    // Get the base rotation for the note
    final baseRotation = (noteIndex - saAtIndex) * 30.0;
    // Add fine rotation from cents (-50 to +50 maps to ±15 degrees)
    final centsRotation = (cents / 50.0) * 15.0;
    return baseRotation + centsRotation;
  }

  bool _isInTune(int cents) => cents.abs() <= 6;

  void _drawNeedle(Canvas canvas) {
    final rotation = _centsToRotation(audioInfo.detune, audioInfo.note);
    final isInTune = _isInTune(audioInfo.detune);

    final needleColor = isInTune
        ? const Color(0xFF22C55E) // green-500
        : const Color(0xFFEF4444); // rose-500

    canvas.save();
    canvas.rotate(rotation * pi / 180);

    // Needle line
    final needlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = needleColor;

    canvas.drawLine(Offset.zero, Offset(0, -needleLineLength), needlePaint);

    // Needle tip circle
    canvas.drawCircle(
      Offset(0, -needleLineLength),
      2,
      Paint()..color = needleColor,
    );

    canvas.restore();
  }

  void _drawSector(Canvas canvas) {
    final radius = outerCircleSargamRadius - 2;
    const range = 15.0;

    final sectorRotation = (noteIndex - saAtIndex) * 30;

    canvas.save();
    canvas.rotate(sectorRotation * pi / 180);

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(
      radius * cos((90 + range) * pi / 180),
      -radius * sin((90 + range) * pi / 180),
    );
    path.arcTo(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      -(90 + range) * pi / 180,
      -2 * range * pi / 180,
      false,
    );
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = (isDarkMode ? Colors.white : Colors.black).withValues(
          alpha: isDarkMode ? 0.15 : 0.1,
        ),
    );

    canvas.restore();
  }

  void _drawCenterText(Canvas canvas) {
    // Note name
    final noteTextPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: audioInfo.note,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isDemo)
            TextSpan(
              text: audioInfo.scale != 0 ? '${audioInfo.scale}' : '',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    noteTextPainter.layout();
    noteTextPainter.paint(
      canvas,
      Offset(
        -noteTextPainter.width / 2,
        isDemo ? -noteTextPainter.height / 2 : -12,
      ),
    );

    // Cents display (if not demo)
    if (!isDemo) {
      final centsText =
          '${audioInfo.detune > 0 ? '+' : ''}${audioInfo.detune} cents';
      final centsTextPainter = TextPainter(
        text: TextSpan(
          text: centsText,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 5,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      centsTextPainter.layout();
      centsTextPainter.paint(canvas, Offset(-centsTextPainter.width / 2, 6));
    }
  }

  @override
  bool shouldRepaint(covariant CircularPitchPainter oldDelegate) {
    return audioInfo != oldDelegate.audioInfo ||
        saAt != oldDelegate.saAt ||
        sargamOrientation != oldDelegate.sargamOrientation ||
        noteOrientation != oldDelegate.noteOrientation ||
        isDarkMode != oldDelegate.isDarkMode ||
        isDemo != oldDelegate.isDemo;
  }
}
