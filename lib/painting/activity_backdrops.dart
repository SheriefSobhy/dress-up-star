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

/// A minty hair salon: striped wall, a big round mirror and a shelf of
/// colorful bottles.
class SalonBackdrop extends CustomPainter {
  const SalonBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()..color = const Color(0x22FFFFFF);
    final w = size.width / 9;
    for (var i = 0; i < 9; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * w, 0, w, size.height), stripe);
    }
    _bokeh(canvas, size, 9, const [
      Color(0xFFFFFFFF),
      Color(0xFFC9F2E4),
      Color(0xFFFFE3F1),
    ]);
    final r = math.min(size.width * 0.47, size.height * 0.4);
    final c = Offset(size.width / 2, size.height * 0.36);
    canvas.drawCircle(
      c + const Offset(0, 6),
      r,
      Paint()
        ..color = const Color(0x3341A08A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          c - Offset(r, r),
          c + Offset(r, r),
          const [Color(0xFFFFFFFF), Color(0xFFB8E6F0), Color(0xFF9CC8E8)],
          const [0, 0.5, 1],
        ),
    );
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..shader = ui.Gradient.linear(
          c - Offset(0, r),
          c + Offset(0, r),
          const [Color(0xFFF6FDFF), Color(0xFFDDF3F7)],
        ),
    );
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.92)),
    );
    final shine = Paint()..color = const Color(0x99FFFFFF);
    for (final x in [-0.55, -0.32]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + r * x, c.dy - r)
          ..lineTo(c.dx + r * (x + 0.14), c.dy - r)
          ..lineTo(c.dx + r * (x - 0.36), c.dy + r)
          ..lineTo(c.dx + r * (x - 0.5), c.dy + r)
          ..close(),
        shine,
      );
    }
    canvas.restore();
    // Shelves with bottles on both sides, low on the wall.
    final shelfY = size.height * 0.86;
    for (final left in [true, false]) {
      final x0 = left ? 0.0 : size.width * 0.74;
      final x1 = left ? size.width * 0.26 : size.width;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x0 - 8,
          shelfY,
          x1 + 8,
          shelfY + 9,
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      const colors = [Color(0xFFFF8FC7), Color(0xFFB79CFF), Color(0xFFFFD84D)];
      final bw = (x1 - x0) / 4.5;
      for (var i = 0; i < 3; i++) {
        final bx = x0 + bw * (0.6 + i * 1.3);
        final bh = bw * (1.5 + (i % 2) * 0.5);
        final body = RRect.fromLTRBR(
          bx,
          shelfY - bh,
          bx + bw,
          shelfY,
          Radius.circular(bw * 0.3),
        );
        canvas.drawRRect(
          body,
          Paint()..color = colors[(i + (left ? 0 : 1)) % 3],
        );
        canvas.drawRRect(
          RRect.fromLTRBR(
            bx + bw * 0.3,
            shelfY - bh - bw * 0.4,
            bx + bw * 0.7,
            shelfY - bh + 1,
            Radius.circular(bw * 0.1),
          ),
          Paint()..color = const Color(0xFFFFFFFF),
        );
        canvas.drawRRect(
          RRect.fromLTRBR(
            bx + bw * 0.18,
            shelfY - bh * 0.85,
            bx + bw * 0.34,
            shelfY - bh * 0.25,
            Radius.circular(bw * 0.08),
          ),
          Paint()..color = const Color(0x88FFFFFF),
        );
      }
    }
  }

  @override
  bool shouldRepaint(SalonBackdrop oldDelegate) => false;
}

/// A peachy nail spa: soft wall, and a fluffy striped towel to rest the
/// hand on.
class NailsBackdrop extends CustomPainter {
  const NailsBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    _bokeh(canvas, size, 13, const [
      Color(0xFFFFFFFF),
      Color(0xFFFFD6C2),
      Color(0xFFFFE3F1),
    ]);
    final towel = RRect.fromLTRBR(
      size.width * 0.04,
      size.height * 0.34,
      size.width * 0.96,
      size.height * 1.05,
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(
      towel.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0x33C0705A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(towel, Paint()..color = const Color(0xFFFFFFFF));
    canvas.save();
    canvas.clipRRect(towel);
    final stripe = Paint()..color = const Color(0xFFFFE0EC);
    for (var i = 0; i < 3; i++) {
      final y = towel.top + towel.height * (0.12 + i * 0.07);
      canvas.drawRect(
        Rect.fromLTWH(towel.left, y, towel.width, towel.height * 0.03),
        stripe,
      );
    }
    // Fluffy texture.
    final rnd = math.Random(4);
    final fluff = Paint()..color = const Color(0x14C07090);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(
          towel.left + rnd.nextDouble() * towel.width,
          towel.top + rnd.nextDouble() * towel.height,
        ),
        2 + rnd.nextDouble() * 3,
        fluff,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      towel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFD0E2),
    );
  }

  @override
  bool shouldRepaint(NailsBackdrop oldDelegate) => false;
}
