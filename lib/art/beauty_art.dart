import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import '../models/beauty.dart';
import '../painting/shapes.dart';
import 'art_library.dart';
import 'doll_art.dart' show Face;

// =============================================================================
//  Drawing the activity results. Everything here draws in doll space (or
//  hand space for nails), like the SVG art.
// =============================================================================

/// A round path covering the painted spots of [grid] for which [use] is
/// true. Spots overlap a little so the paint looks smooth.
/// A round path covering the spots [cells] of [zone].
Path cellsPath(SpotZone zone, Iterable<int> cells, {double size = 0.85}) {
  final path = Path();
  final r = zone.spacing * size;
  for (final i in cells) {
    path.addOval(Rect.fromCircle(center: zone.spots[i], radius: r));
  }
  return path;
}

Path spotsPath(
  SpotZone zone,
  SpotGrid grid, {
  bool Function(int spot, int value)? use,
  double size = 0.85,
}) {
  final path = Path();
  final r = zone.spacing * size;
  for (var i = 0; i < zone.length; i++) {
    final v = grid[i];
    if (v == null || (use != null && !use(i, v))) continue;
    path.addOval(Rect.fromCircle(center: zone.spots[i], radius: r));
  }
  return path;
}

/// The palette colors used in [grid].
Set<int> usedColors(SpotGrid grid, int length) => {
  for (var i = 0; i < length; i++) ?grid[i],
};

/// Tiny four-point sparkles scattered over [area] (for glitter).
void paintGlitter(
  Canvas canvas,
  Rect area,
  int seed, {
  double density = 0.05,
  double size = 1.1,
}) {
  final rnd = math.Random(seed);
  final count = math.max(2, (area.width * area.height * density).round());
  final white = Paint()..color = const Color(0xEEFFFFFF);
  final gold = Paint()..color = const Color(0xDDFFF2A8);
  for (var i = 0; i < count; i++) {
    final p = Offset(
      area.left + rnd.nextDouble() * area.width,
      area.top + rnd.nextDouble() * area.height,
    );
    final s = size * (0.6 + rnd.nextDouble() * 0.8);
    canvas.drawPath(
      starPath(p, s * 1.6, inner: s * 0.4, points: 4),
      i.isEven ? white : gold,
    );
  }
}

// --------------------------------------------------------------- makeup

/// Blush and eyeshadow: drawn on the skin, under the eyes and mouth.
void paintMakeupUnder(Canvas canvas, Makeup m) {
  if (!m.blush.isEmpty) {
    final r = blushZone.spacing * 1.05;
    canvas.saveLayer(
      const Rect.fromLTRB(30, 100, 170, 170),
      Paint()..color = const Color(0x99000000),
    );
    for (var i = 0; i < blushZone.length; i++) {
      final v = m.blush[i];
      if (v == null) continue;
      canvas.drawCircle(
        blushZone.spots[i],
        r,
        Paint()
          ..color = blushColors[v].color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
      );
    }
    canvas.restore();
  }

  if (!m.shadow.isEmpty) {
    for (final c in usedColors(m.shadow, shadowZone.length)) {
      final tool = eyeshadowColors[c];
      canvas.save();
      canvas.clipPath(
        spotsPath(shadowZone, m.shadow, use: (_, v) => v == c, size: 0.9),
      );
      for (final center in const [Offset(77.5, 108), Offset(122.5, 108)]) {
        final lid = Rect.fromCenter(center: center, width: 40, height: 30);
        canvas.drawOval(
          lid,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(center.dx, lid.top),
              Offset(center.dx, lid.bottom - 2),
              [
                tool.color.withValues(alpha: 0.95),
                tool.color.withValues(alpha: 0.45),
              ],
            ),
        );
        if (tool.glitter) {
          paintGlitter(canvas, lid, center.dx.round(), density: 0.09);
        }
      }
      canvas.restore();
    }
  }
}

/// Lipstick, eyelashes and stickers: drawn over the face.
void paintMakeupOver(Canvas canvas, Makeup m, Face face) {
  if (!m.lips.isEmpty) {
    for (final c in usedColors(m.lips, lipsZone.length)) {
      final color = lipstickColors[c].color;
      canvas.save();
      canvas.clipPath(
        spotsPath(lipsZone, m.lips, use: (_, v) => v == c, size: 0.95),
      );
      _paintLips(canvas, color, face);
      canvas.restore();
    }
  }
  if (m.lashLeft > 0) _paintLashes(canvas, m.lashLeft, face);
  if (m.lashRight > 0) {
    canvas.save();
    canvas.translate(200, 0);
    canvas.scale(-1, 1);
    _paintLashes(canvas, m.lashRight, face);
    canvas.restore();
  }
  for (final s in m.stickers) {
    paintSticker(canvas, s.kind, s.position, 12);
  }
}

void _paintLips(Canvas canvas, Color color, Face face) {
  final deep = darken(color, 0.3);
  if (face == Face.happy) {
    // Lips around the big open smile.
    final mouth = Path()
      ..moveTo(89, 133)
      ..quadraticBezierTo(100, 151, 111, 133)
      ..quadraticBezierTo(100, 136, 89, 133)
      ..close();
    canvas.drawPath(
      mouth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawPath(
      mouth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = deep.withValues(alpha: 0.6),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(96, 147.4), width: 4, height: 1.4),
      Paint()..color = const Color(0x99FFFFFF),
    );
    return;
  }
  final lips = Path()
    ..moveTo(90.5, 136)
    ..quadraticBezierTo(94.5, 132.6, 97.6, 133.8)
    ..quadraticBezierTo(100, 135, 102.4, 133.8)
    ..quadraticBezierTo(105.5, 132.6, 109.5, 136)
    ..quadraticBezierTo(100, 147.5, 90.5, 136)
    ..close();
  canvas.drawPath(
    lips,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(100, 133),
        const Offset(100, 142),
        [lighten(color, 0.12), color, darken(color, 0.08)],
        [0, 0.5, 1],
      ),
  );
  canvas.drawPath(
    lips,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = deep.withValues(alpha: 0.75),
  );
  canvas.drawPath(
    Path()
      ..moveTo(92.5, 136.3)
      ..quadraticBezierTo(100, 139.6, 107.5, 136.3),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = deep,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(100, 141.3), width: 6, height: 1.8),
    Paint()..color = const Color(0x8CFFFFFF),
  );
}

Offset _quad(Offset a, Offset b, Offset c, double t) {
  final u = 1 - t;
  return a * (u * u) + b * (2 * u * t) + c * (t * t);
}

/// The upper lid line of the left eye for each face, outer corner first.
Offset _lid(Face face, double t) {
  switch (face) {
    case Face.open:
      return t < 0.5
          ? _quad(
              const Offset(65, 110),
              const Offset(70, 98),
              const Offset(79, 99),
              t * 2,
            )
          : _quad(
              const Offset(79, 99),
              const Offset(87, 99.5),
              const Offset(91, 106),
              t * 2 - 1,
            );
    case Face.blink:
      return _quad(
        const Offset(66, 115),
        const Offset(78, 124),
        const Offset(90, 115),
        t,
      );
    case Face.happy:
      return _quad(
        const Offset(66, 119),
        const Offset(78, 103),
        const Offset(90, 119),
        t,
      );
  }
}

class _LashStyle {
  const _LashStyle(this.at, this.length, this.width, {this.liner = false});
  final List<double> at;
  final double length;
  final double width;
  final bool liner;
}

const List<_LashStyle> _lashStyles = [
  _LashStyle([0.02, 0.13, 0.25], 5.5, 1.9),
  _LashStyle([0.0, 0.1, 0.2, 0.31, 0.43, 0.56], 9, 2.1, liner: true),
  _LashStyle(
    [0.0, 0.08, 0.17, 0.27, 0.38, 0.5, 0.63, 0.76],
    7.5,
    2.3,
    liner: true,
  ),
];

/// Eyelashes of [style] (1..3) on the left eye (mirrored for the right).
void _paintLashes(Canvas canvas, int style, Face face) {
  final s = _lashStyles[(style - 1).clamp(0, _lashStyles.length - 1)];
  const ink = Color(0xFF2A1730);
  final down = face == Face.blink;
  if (s.liner) {
    final liner = Path();
    for (var i = 0; i <= 12; i++) {
      final p = _lid(face, i / 12);
      i == 0 ? liner.moveTo(p.dx, p.dy) : liner.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      liner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
  }
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s.width
    ..strokeCap = StrokeCap.round
    ..color = ink;
  for (var i = 0; i < s.at.length; i++) {
    final t = s.at[i];
    final p = _lid(face, t);
    final q = _lid(face, math.min(1, t + 0.02));
    final tangent = (q - p) / math.max(0.001, (q - p).distance);
    // Lashes point away from the eye and sweep to the outer corner.
    var normal = Offset(tangent.dy, -tangent.dx);
    if (down ? normal.dy < 0 : normal.dy > 0) normal = -normal;
    final sweep =
        (normal + const Offset(-0.9, 0) * (1 - t)) / (1 + 0.6 * (1 - t));
    final length = s.length * (1 - t * 0.45);
    final end = p + sweep * length;
    final control = p + normal * (length * 0.6);
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy),
      paint,
    );
    if (style == 3 && i.isEven) {
      canvas.drawPath(
        starPath(end, 1.9, points: 4, inner: 0.6),
        Paint()..color = const Color(0xFFFF8FC7),
      );
    }
  }
}

/// A small open eye with eyelashes of [style], filling a square of [size]
/// (for the eyelash buttons).
void paintLashPreview(Canvas canvas, Size size, int style) {
  const area = Rect.fromLTRB(52, 88, 100, 136);
  canvas.save();
  canvas.scale(size.width / area.width, size.height / area.height);
  canvas.translate(-area.left, -area.top);
  canvas.save();
  canvas.clipRect(const Rect.fromLTRB(52, 88, 100, 126));
  canvas.drawOval(
    Rect.fromCenter(center: kLeftEye, width: 23, height: 29),
    Paint()..color = const Color(0xFF5B3577),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: kLeftEye + const Offset(4.5, -7.5),
      width: 9,
      height: 11,
    ),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.restore();
  canvas.drawPath(
    Path()
      ..moveTo(65, 110)
      ..quadraticBezierTo(70, 98, 79, 99)
      ..quadraticBezierTo(87, 99.5, 91, 106),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2A1730),
  );
  _paintLashes(canvas, style, Face.open);
  canvas.restore();
}

// ------------------------------------------------------------- stickers

/// A sticker of [size] (doll units) centered on [c].
void paintSticker(Canvas canvas, StickerKind kind, Offset c, double size) {
  switch (kind) {
    case StickerKind.star:
      final star = starPath(c, size * 0.55, inner: size * 0.25);
      _shapeWithShine(canvas, star, const Color(0xFFFFD84D), c, size);
    case StickerKind.heart:
      final heart = heartPath(c + Offset(0, size * 0.04), size * 0.95);
      _shapeWithShine(canvas, heart, const Color(0xFFFF6FA5), c, size);
    case StickerKind.butterfly:
      paintButterfly(canvas, c, size);
  }
}

void _shapeWithShine(
  Canvas canvas,
  Path path,
  Color color,
  Offset c,
  double size,
) {
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.radial(
        c - Offset(size * 0.15, size * 0.2),
        size * 0.7,
        [lighten(color, 0.45), color, darken(color, 0.1)],
        [0, 0.6, 1],
      ),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size * 0.07)
      ..strokeJoin = StrokeJoin.round
      ..color = darken(color, 0.3),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: c - Offset(size * 0.14, size * 0.18),
      width: size * 0.22,
      height: size * 0.12,
    ),
    Paint()..color = const Color(0xCCFFFFFF),
  );
}

void paintButterfly(Canvas canvas, Offset c, double size) {
  const wing = Color(0xFF8FC8FF);
  const wing2 = Color(0xFFC9A8FF);
  final s = size / 12;
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.7, 0.8 * s)
    ..color = const Color(0xFF6A58B8);
  for (final side in const [-1.0, 1.0]) {
    final top = Rect.fromCenter(
      center: c + Offset(side * 3.4 * s, -1.6 * s),
      width: 6.4 * s,
      height: 6.4 * s,
    );
    final bottom = Rect.fromCenter(
      center: c + Offset(side * 2.6 * s, 2.8 * s),
      width: 4.6 * s,
      height: 4.4 * s,
    );
    canvas.drawOval(top, Paint()..color = wing);
    canvas.drawOval(top, outline);
    canvas.drawOval(bottom, Paint()..color = wing2);
    canvas.drawOval(bottom, outline);
    canvas.drawCircle(
      top.center + Offset(side * 0.6 * s, -0.4 * s),
      1.1 * s,
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, 0.4 * s),
        width: 1.7 * s,
        height: 8.5 * s,
      ),
      Radius.circular(s),
    ),
    Paint()..color = const Color(0xFF6A4A8A),
  );
}

// -------------------------------------------------------- doll layers

/// The face layers with makeup, in drawing order: makeup under the eyes and
/// mouth, the face itself, then lipstick, lashes and stickers.
List<ArtLayer> makeupFaceLayers(Makeup m, Face face, ArtLayer faceArt) {
  if (m.isEmpty) return [faceArt];
  final hasUnder = !m.blush.isEmpty || !m.shadow.isEmpty;
  return [
    if (hasUnder)
      ArtLayer.drawn(
        'makeup_under|${m.key}',
        () async => recordPicture((c) => paintMakeupUnder(c, m)),
      ),
    faceArt,
    ArtLayer.drawn(
      'makeup_over|${face.name}|${m.key}',
      () async => recordPicture((c) => paintMakeupOver(c, m, face)),
    ),
  ];
}
