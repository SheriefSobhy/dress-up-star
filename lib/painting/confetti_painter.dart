import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../art/motion.dart';
import 'shapes.dart';

/// A happy burst of confetti, stars and hearts that pops up from [origin]
/// and floats down while [progress] goes from 0 to 1.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.progress,
    required this.origin,
    required this.seed,
  });

  final double progress;
  final Offset origin;
  final int seed;

  static const _colors = [
    Color(0xFFFF6B8B),
    Color(0xFFFF8FC7),
    Color(0xFFFFD84D),
    Color(0xFF8EE08A),
    Color(0xFF7CB8FF),
    Color(0xFFB79CFF),
    Color(0xFF5CD6D6),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rnd = math.Random(seed);
    final unit = size.shortestSide;
    final t = progress * 2.2; // seconds-ish of flight
    final fade = progress < 0.75 ? 1.0 : 1 - (progress - 0.75) / 0.25;
    final paint = Paint();
    // Lite mode (slow phones): fewer pieces.
    final pieces = GameMotion.lite.value ? 28 : 70;
    for (var i = 0; i < pieces; i++) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.25;
      final speed = unit * (0.55 + rnd.nextDouble() * 0.75);
      final drag = 1 - 0.35 * t;
      final pos =
          origin +
          Offset(
            math.cos(angle) * speed * t * drag +
                math.sin(t * 3 + i) * unit * 0.02,
            math.sin(angle) * speed * t * drag + 0.5 * unit * 0.9 * t * t,
          );
      if (pos.dy > size.height + 20) continue;
      final color = _colors[i % _colors.length];
      final s = unit * (0.012 + rnd.nextDouble() * 0.014);
      final spin = t * (2 + rnd.nextDouble() * 6) + i;
      paint.color = color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(spin);
      // Flip like a falling paper strip.
      canvas.scale(math.cos(spin * 1.7).abs() * 0.8 + 0.2, 1);
      switch (i % 5) {
        case 0:
          canvas.drawPath(starPath(Offset.zero, s * 1.4), paint);
        case 1:
          canvas.drawPath(heartPath(Offset.zero, s * 2.4), paint);
        case 2:
          canvas.drawCircle(Offset.zero, s * 0.8, paint);
        default:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: s * 1.1,
                height: s * 2.2,
              ),
              Radius.circular(s * 0.3),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) =>
      old.progress != progress || old.origin != origin || old.seed != seed;
}
