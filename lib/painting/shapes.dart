import 'dart:math' as math;
import 'dart:ui';

/// Small drawing helpers shared by the painters.

Color lighten(Color c, double amount) =>
    Color.lerp(c, const Color(0xFFFFFFFF), amount)!;

Color darken(Color c, double amount) =>
    Color.lerp(c, const Color(0xFF000000), amount)!;

/// A color that shows up nicely on top of [base] (for patterns and details).
Color contrastOn(Color base) =>
    base.computeLuminance() > 0.55 ? darken(base, 0.22) : lighten(base, 0.6);

/// Outline color for a filled shape of color [c].
Color outlineOf(Color c) => darken(c, 0.28);

Path starPath(
  Offset center,
  double outer, {
  double? inner,
  int points = 5,
  double rotation = 0,
}) {
  final innerR = inner ?? outer * 0.45;
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : innerR;
    final a = rotation - math.pi / 2 + i * math.pi / points;
    final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}

/// A heart that fits roughly in a square of [size] centered on [center].
Path heartPath(Offset center, double size) {
  final s = size / 2;
  final x = center.dx;
  final y = center.dy;
  return Path()
    ..moveTo(x, y + s * 0.9)
    ..cubicTo(
      x - s * 1.4,
      y - s * 0.1,
      x - s * 0.7,
      y - s * 1.2,
      x,
      y - s * 0.45,
    )
    ..cubicTo(
      x + s * 0.7,
      y - s * 1.2,
      x + s * 1.4,
      y - s * 0.1,
      x,
      y + s * 0.9,
    )
    ..close();
}

/// A puffy cloud made of circles.
Path cloudPath(Offset c, double w) {
  final h = w * 0.32;
  return Path()
    ..addOval(
      Rect.fromCircle(
        center: c + Offset(-w * 0.28, h * 0.15),
        radius: h * 0.75,
      ),
    )
    ..addOval(Rect.fromCircle(center: c + Offset(0, -h * 0.2), radius: h))
    ..addOval(
      Rect.fromCircle(center: c + Offset(w * 0.3, h * 0.12), radius: h * 0.8),
    )
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, h * 0.45),
          width: w * 0.95,
          height: h * 0.9,
        ),
        Radius.circular(h * 0.45),
      ),
    );
}
