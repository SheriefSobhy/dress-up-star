import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import 'shapes.dart';

/// Draws a background scene filling [size].
void paintBackground(Canvas canvas, Size size, ItemShape shape, Color c) {
  final w = size.width;
  final h = size.height;
  final rect = Offset.zero & size;

  void gradient(Color top, Color bottom) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
  }

  void ground(Color color, {double top = 0.8}) {
    canvas.drawOval(
      Rect.fromLTRB(-w * 0.4, h * top, w * 1.4, h * (top + 0.6)),
      Paint()..color = color,
    );
  }

  void clouds() {
    final white = Paint()..color = const Color(0xF2FFFFFF);
    canvas.drawPath(cloudPath(Offset(w * 0.18, h * 0.14), w * 0.3), white);
    canvas.drawPath(cloudPath(Offset(w * 0.7, h * 0.27), w * 0.24), white);
  }

  switch (shape) {
    case ItemShape.bgGarden:
      gradient(c, lighten(c, 0.7));
      clouds();
      ground(const Color(0xFFB9EDB0), top: 0.7);
      ground(const Color(0xFF9BE09A), top: 0.8);
      final rnd = math.Random(3);
      const petals = [
        Color(0xFFFF8FC7),
        Color(0xFFFFD84D),
        Color(0xFFB79CFF),
        Color(0xFFFF6B8B),
        Color(0xFF7CB8FF),
      ];
      for (var i = 0; i < 14; i++) {
        final x = w * (0.04 + 0.92 * (i / 13)) + rnd.nextDouble() * w * 0.03;
        final y = h * (0.84 + rnd.nextDouble() * 0.12);
        final r = w * (0.014 + rnd.nextDouble() * 0.01);
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + r * 3),
          Paint()
            ..color = const Color(0xFF5FB760)
            ..strokeWidth = r * 0.5,
        );
        final petal = Paint()..color = petals[i % petals.length];
        for (var p = 0; p < 5; p++) {
          final a = p * 2 * math.pi / 5;
          canvas.drawCircle(
            Offset(x + math.cos(a) * r, y + math.sin(a) * r),
            r * 0.75,
            petal,
          );
        }
        canvas.drawCircle(
          Offset(x, y),
          r * 0.6,
          Paint()..color = const Color(0xFFFFF3A8),
        );
      }
    case ItemShape.bgNight:
      const navy = Color(0xFF2E2A6B);
      gradient(Color.lerp(c, navy, 0.75)!, Color.lerp(c, navy, 0.4)!);
      final rnd = math.Random(11);
      for (var i = 0; i < 40; i++) {
        final p = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.75);
        final r = w * (0.006 + rnd.nextDouble() * 0.014);
        canvas.drawPath(
          starPath(p, r, rotation: rnd.nextDouble()),
          Paint()
            ..color = Color.fromRGBO(
              255,
              250,
              220,
              0.5 + rnd.nextDouble() * 0.5,
            ),
        );
      }
      final moonC = Offset(w * 0.8, h * 0.13);
      final moonR = math.min(w, h) * 0.09;
      final moon = Path()
        ..addOval(Rect.fromCircle(center: moonC, radius: moonR));
      final cut = Path()
        ..addOval(
          Rect.fromCircle(
            center: moonC + Offset(moonR * 0.5, -moonR * 0.25),
            radius: moonR * 0.85,
          ),
        );
      canvas.drawPath(
        Path.combine(PathOperation.difference, moon, cut),
        Paint()..color = const Color(0xFFFFF3B0),
      );
      ground(Color.lerp(c, navy, 0.25)!);
    case ItemShape.bgRainbow:
      gradient(c, lighten(c, 0.7));
      const bands = [
        Color(0xFFFF9AA2),
        Color(0xFFFFC48C),
        Color(0xFFFFF09A),
        Color(0xFFB5EAAA),
        Color(0xFF9AD0FF),
        Color(0xFFC9A8FF),
      ];
      final center = Offset(w * 0.5, h * 0.66);
      final band = math.min(w, h) * 0.05;
      final outer = math.min(w * 0.48, h * 0.5);
      for (var i = 0; i < bands.length; i++) {
        final r = outer - i * band;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = bands[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = band + 0.5,
        );
      }
      final white = Paint()..color = const Color(0xFFFFFFFF);
      final mid = outer - band * 2.5;
      canvas.drawPath(cloudPath(center - Offset(mid, 0), band * 6), white);
      canvas.drawPath(cloudPath(center + Offset(mid, 0), band * 6), white);
      ground(lighten(c, 0.5));
    case ItemShape.bgCastle:
      gradient(c, lighten(c, 0.7));
      clouds();
      _castle(canvas, size, c);
      ground(const Color(0xFFC9F0C0), top: 0.82);
    case ItemShape.bgHearts:
      canvas.drawRect(rect, Paint()..color = c);
      final rnd = math.Random(5);
      for (var i = 0; i < 28; i++) {
        final p = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
        final s = math.min(w, h) * (0.05 + rnd.nextDouble() * 0.07);
        canvas.drawPath(
          heartPath(p, s),
          Paint()..color = i.isEven ? lighten(c, 0.55) : darken(c, 0.06),
        );
      }
      ground(lighten(c, 0.6), top: 0.84);
    case ItemShape.bgBeach:
      gradient(c, lighten(c, 0.7));
      final m = math.min(w, h);
      canvas.drawCircle(
        Offset(w * 0.82, h * 0.12),
        m * 0.08,
        Paint()..color = const Color(0xFFFFE066),
      );
      clouds();
      // Sea with little wave bumps on top
      final seaTop = h * 0.56;
      final sea = Path()..moveTo(0, seaTop);
      final wave = w / 8;
      for (var i = 0; i < 8; i++) {
        sea.quadraticBezierTo(
          wave * i + wave / 2,
          seaTop - m * 0.025,
          wave * (i + 1),
          seaTop,
        );
      }
      sea
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(sea, Paint()..color = const Color(0xFF7FD3F0));
      canvas.drawRect(
        Rect.fromLTRB(0, h * 0.64, w, h),
        Paint()..color = const Color(0xFF5EC4E8),
      );
      // A little sailboat
      final boat = Offset(w * 0.18, h * 0.6);
      canvas.drawPath(
        Path()
          ..moveTo(boat.dx - m * 0.06, boat.dy)
          ..lineTo(boat.dx + m * 0.06, boat.dy)
          ..lineTo(boat.dx + m * 0.04, boat.dy + m * 0.025)
          ..lineTo(boat.dx - m * 0.04, boat.dy + m * 0.025)
          ..close(),
        Paint()..color = const Color(0xFFFF8FA8),
      );
      canvas.drawPath(
        Path()
          ..moveTo(boat.dx, boat.dy - m * 0.1)
          ..lineTo(boat.dx + m * 0.05, boat.dy - m * 0.01)
          ..lineTo(boat.dx, boat.dy - m * 0.01)
          ..close(),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      ground(const Color(0xFFFFE6A8), top: 0.76);
      final rnd = math.Random(9);
      const shells = [Color(0xFFFFA45C), Color(0xFFFF8FC7), Color(0xFFB79CFF)];
      for (var i = 0; i < 6; i++) {
        final p = Offset(
          w * (0.06 + 0.88 * i / 5) + rnd.nextDouble() * w * 0.03,
          h * (0.86 + rnd.nextDouble() * 0.1),
        );
        canvas.drawPath(
          starPath(p, m * (0.02 + rnd.nextDouble() * 0.012), inner: m * 0.012),
          Paint()..color = shells[i % shells.length],
        );
      }
    case ItemShape.bgCandy:
      gradient(c, lighten(c, 0.7));
      final m = math.min(w, h);
      // Cotton-candy clouds
      canvas.drawPath(
        cloudPath(Offset(w * 0.2, h * 0.14), w * 0.3),
        Paint()..color = const Color(0xCCFFC2E2),
      );
      canvas.drawPath(
        cloudPath(Offset(w * 0.74, h * 0.24), w * 0.24),
        Paint()..color = const Color(0xCCD9C6FF),
      );
      ground(const Color(0xFFE3D0FF), top: 0.7);
      // Lollipops
      void lollipop(Offset top, double r, Color color) {
        canvas.drawLine(
          top,
          Offset(top.dx, h * 0.9),
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..strokeWidth = r * 0.22
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(top, r, Paint()..color = color);
        final swirl = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.16;
        canvas.drawCircle(top, r * 0.62, swirl);
        canvas.drawCircle(top, r * 0.26, swirl);
      }

      lollipop(Offset(w * 0.12, h * 0.52), m * 0.09, const Color(0xFFFF8FC7));
      lollipop(Offset(w * 0.88, h * 0.48), m * 0.1, const Color(0xFF7CB8FF));
      lollipop(Offset(w * 0.75, h * 0.62), m * 0.06, const Color(0xFFFFD84D));
      ground(const Color(0xFFFFC2E2), top: 0.8);
      // Sprinkles
      final rnd = math.Random(4);
      const sprinkles = [
        Color(0xFFFF6B8B),
        Color(0xFFFFD84D),
        Color(0xFF8EE08A),
        Color(0xFF7CB8FF),
        Color(0xFFFFFFFF),
      ];
      for (var i = 0; i < 30; i++) {
        final p = Offset(
          rnd.nextDouble() * w,
          h * (0.84 + rnd.nextDouble() * 0.15),
        );
        final a = rnd.nextDouble() * math.pi;
        final d = Offset(math.cos(a), math.sin(a)) * m * 0.012;
        canvas.drawLine(
          p - d,
          p + d,
          Paint()
            ..color = sprinkles[i % sprinkles.length]
            ..strokeWidth = m * 0.008
            ..strokeCap = StrokeCap.round,
        );
      }
    default: // bgSky and anything unknown
      gradient(c, lighten(c, 0.75));
      final sun = Offset(w * 0.84, h * 0.11);
      final sunR = math.min(w, h) * 0.08;
      canvas.drawCircle(
        sun,
        sunR * 1.6,
        Paint()..color = const Color(0x55FFF3A0),
      );
      canvas.drawCircle(sun, sunR, Paint()..color = const Color(0xFFFFE066));
      clouds();
      ground(const Color(0xFFD7F5CF));
  }
}

void _castle(Canvas canvas, Size size, Color c) {
  final w = size.width;
  final h = size.height;
  final wall = lighten(c, 0.65);
  final roof = darken(c, 0.12);
  final line = Paint()
    ..color = darken(c, 0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, w * 0.004);
  final base = h * 0.85;

  void tower(double cx, double top, double tw) {
    final r = Rect.fromLTRB(cx - tw / 2, top, cx + tw / 2, base);
    canvas.drawRect(r, Paint()..color = wall);
    canvas.drawRect(r, line);
    final cone = Path()
      ..moveTo(cx - tw * 0.65, top)
      ..lineTo(cx, top - tw * 1.2)
      ..lineTo(cx + tw * 0.65, top)
      ..close();
    canvas.drawPath(cone, Paint()..color = roof);
    canvas.drawPath(cone, line);
    final flagTop = top - tw * 1.2;
    canvas.drawLine(Offset(cx, flagTop), Offset(cx, flagTop - tw * 0.4), line);
    canvas.drawPath(
      Path()
        ..moveTo(cx, flagTop - tw * 0.4)
        ..lineTo(cx + tw * 0.35, flagTop - tw * 0.3)
        ..lineTo(cx, flagTop - tw * 0.2)
        ..close(),
      Paint()..color = const Color(0xFFFF6B8B),
    );
    final win = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, top + tw * 0.6),
        width: tw * 0.3,
        height: tw * 0.45,
      ),
      Radius.circular(tw * 0.15),
    );
    canvas.drawRRect(win, Paint()..color = darken(c, 0.05));
  }

  // Main wall
  final body = Rect.fromLTRB(w * 0.2, h * 0.5, w * 0.8, base);
  canvas.drawRect(body, Paint()..color = wall);
  canvas.drawRect(body, line);
  tower(w * 0.12, h * 0.42, w * 0.13);
  tower(w * 0.88, h * 0.42, w * 0.13);
  tower(w * 0.3, h * 0.36, w * 0.11);
  tower(w * 0.7, h * 0.36, w * 0.11);
}
