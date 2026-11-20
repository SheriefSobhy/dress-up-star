import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'shapes.dart';

/// Stars that burst out of [center] while [progress] goes from 0 to 1.
class SparklePainter extends CustomPainter {
  SparklePainter({
    required this.progress,
    required this.center,
    required this.seed,
  });

  final double progress;
  final Offset center;
  final int seed;

  static const _colors = [
    Color(0xFFFFE066),
    Color(0xFFFF8FC7),
    Color(0xFFFFFFFF),
    Color(0xFF9AD0FF),
    Color(0xFFC9A8FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rnd = math.Random(seed);
    final reach = size.shortestSide * 0.32;
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = 1 - Curves.easeIn.transform(progress);
    for (var i = 0; i < 16; i++) {
      final angle = i * 2 * math.pi / 16 + rnd.nextDouble() * 0.4;
      final dist = reach * (0.45 + rnd.nextDouble() * 0.55) * eased;
      final p = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      final r =
          size.shortestSide *
          (0.018 + rnd.nextDouble() * 0.02) *
          (1 - progress * 0.4);
      final color = _colors[i % _colors.length];
      canvas.drawPath(
        starPath(p, r, rotation: progress * math.pi + i),
        Paint()..color = color.withValues(alpha: fade),
      );
      canvas.drawPath(
        starPath(p, r, rotation: progress * math.pi + i),
        Paint()
          ..color = darken(color, 0.2).withValues(alpha: fade * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.center != center ||
      oldDelegate.seed != seed;
}
