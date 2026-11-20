import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'shapes.dart';

/// Soft round lights in the background, like a dreamy photo.
void _bokeh(Canvas canvas, Size size, int seed, List<Color> colors) {
  final rnd = math.Random(seed);
  for (var i = 0; i < 14; i++) {
    final c = Offset(
      rnd.nextDouble() * size.width,
      rnd.nextDouble() * size.height,
    );
    final r = size.shortestSide * (0.03 + rnd.nextDouble() * 0.07);
    canvas.drawCircle(
      c,
      r,
      Paint()..color = colors[i % colors.length].withValues(alpha: 0.28),
    );
  }
}

/// A vanity mirror with glowing bulbs behind the girl's face.
class MakeupBackdrop extends CustomPainter {
  const MakeupBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    _bokeh(canvas, size, 5, const [
      Color(0xFFFFFFFF),
      Color(0xFFFFC2DF),
      Color(0xFFE3D4FF),
    ]);
    final w = math.min(size.width * 0.92, size.height * 0.78);
    final mirror = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: w,
      height: math.min(size.height * 0.9, w * 1.12),
    );
    final frame = RRect.fromRectAndRadius(mirror, Radius.circular(w * 0.46));
    canvas.drawRRect(
      frame.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0x33B06FA0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = ui.Gradient.linear(
          mirror.topLeft,
          mirror.bottomRight,
          const [Color(0xFFFFE2A0), Color(0xFFFFB6D5), Color(0xFFE7B0FF)],
          const [0, 0.5, 1],
        ),
    );
    final glass = frame.deflate(w * 0.05);
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = ui.Gradient.linear(
          glass.outerRect.topCenter,
          glass.outerRect.bottomCenter,
          const [Color(0xFFF4FBFF), Color(0xFFDDEFFF), Color(0xFFF3E6FF)],
          const [0, 0.5, 1],
        ),
    );
    canvas.save();
    canvas.clipRRect(glass);
    final shine = Paint()..color = const Color(0x88FFFFFF);
    for (final x in [0.18, 0.3]) {
      canvas.drawPath(
        Path()
          ..moveTo(mirror.left + mirror.width * x, mirror.top)
          ..lineTo(mirror.left + mirror.width * (x + 0.08), mirror.top)
          ..lineTo(mirror.left + mirror.width * (x - 0.2), mirror.bottom)
          ..lineTo(mirror.left + mirror.width * (x - 0.28), mirror.bottom)
          ..close(),
        shine,
      );
    }
    canvas.restore();
    // Bulbs around the mirror.
    const bulbs = 14;
    final r = w * 0.035;
    for (var i = 0; i < bulbs; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / bulbs;
      final p = Offset(
        mirror.center.dx + math.cos(a) * (mirror.width / 2 - w * 0.025),
        mirror.center.dy + math.sin(a) * (mirror.height / 2 - w * 0.025),
      );
      canvas.drawCircle(
        p,
        r * 2.2,
        Paint()
          ..color = const Color(0x55FFF2A8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            p - Offset(r * 0.3, r * 0.3),
            r * 1.2,
            const [Color(0xFFFFFFFF), Color(0xFFFFF1A6), Color(0xFFFFD24D)],
            const [0, 0.5, 1],
          ),
      );
    }
    // The vanity table.
    final table = Rect.fromLTWH(
      0,
      size.height * 0.9,
      size.width,
      size.height * 0.1,
    );
    canvas.drawRect(
      table,
      Paint()
        ..shader = ui.Gradient.linear(
          table.topCenter,
          table.bottomCenter,
          const [Color(0xFFFFD1E6), Color(0xFFF7A9CB)],
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, table.top, size.width, 3),
      Paint()..color = lighten(const Color(0xFFFFD1E6), 0.6),
    );
  }

  @override
  bool shouldRepaint(MakeupBackdrop oldDelegate) => false;
}
