import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import '../models/beauty.dart';
import '../models/doll_body.dart';
import '../painting/shapes.dart';
import 'art_library.dart';
import 'beauty_art.dart' show cellsPath, paintGlitter;
import 'body_art.dart';

// =============================================================================
//  Nails: the big hand of the Nails screen (hand space, 300 x 360) and the
//  tiny polished nails on the doll's hands (doll space).
// =============================================================================

const Color _skin = Color(0xFFFFDCC8);
const Color _skinLight = Color(0xFFFFEDE2);
const Color _skinShade = Color(0xFFF2BDA2);
const Color _skinLine = Color(0xFFDE9F84);

Float64List _rotation(Offset pivot, double angle) {
  final c = math.cos(angle), s = math.sin(angle);
  // Column-major 4x4: rotate around [pivot].
  return Float64List.fromList([
    c, s, 0, 0, //
    -s, c, 0, 0, //
    0, 0, 1, 0, //
    pivot.dx - c * pivot.dx + s * pivot.dy,
    pivot.dy - s * pivot.dx - c * pivot.dy, 0, 1,
  ]);
}

/// A finger as a rounded bar from its base to its tip.
Path _fingerPath(Finger f) {
  final length = (f.tip - f.base).distance + 30;
  final rect = Rect.fromLTWH(
    f.base.dx - f.width / 2,
    f.base.dy - length + 30,
    f.width,
    length,
  );
  // Built pointing up from the base, then turned to the finger's angle.
  final up = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(f.width / 2)));
  return up.transform(_rotation(f.base, f.angle));
}

Path? _handPath;

/// The whole hand outline (palm, fingers and wrist as one shape).
Path handPath() => _handPath ??= () {
  var hand = Path()
    ..addRRect(RRect.fromLTRBR(80, 178, 232, 322, const Radius.circular(58)))
    ..addRRect(RRect.fromLTRBR(104, 280, 206, 380, const Radius.circular(20)));
  for (final f in kFingers) {
    hand = Path.combine(PathOperation.union, hand, _fingerPath(f));
  }
  return hand;
}();

/// Draws the hand (without nails).
void paintHand(Canvas canvas, [DollBody body = DollBody.classic]) {
  final skinLight = skinTint(body, _skinLight);
  final skin = skinTint(body, _skin);
  final skinShade = skinTint(body, _skinShade);
  final skinLine = skinTint(body, _skinLine);
  final hand = handPath();
  canvas.drawPath(
    hand.shift(const Offset(0, 6)),
    Paint()
      ..color = const Color(0x33B0705A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  canvas.drawPath(
    hand,
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(150, 190),
        190,
        [skinLight, skin, skinShade],
        const [0, 0.55, 1],
      ),
  );
  canvas.drawPath(
    hand,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round
      ..color = skinLine,
  );
  final crease = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..color = skinLine.withValues(alpha: 0.55);
  for (final f in kFingers.take(4)) {
    // A little knuckle line in the middle of each finger.
    final mid = Offset.lerp(f.base, f.tip, 0.42)!;
    final across = Offset(-f.direction.dy, f.direction.dx) * (f.width * 0.18);
    final bend = f.direction * 2.5;
    canvas.drawPath(
      Path()
        ..moveTo(mid.dx - across.dx, mid.dy - across.dy)
        ..quadraticBezierTo(
          mid.dx + bend.dx,
          mid.dy + bend.dy,
          mid.dx + across.dx,
          mid.dy + across.dy,
        ),
      crease,
    );
  }
  // Soft shine on the back of the hand.
  canvas.drawOval(
    const Rect.fromLTWH(118, 214, 54, 26),
    Paint()
      // Fainter on deeper skin, so it stays a shine.
      ..color = const Color(0xFFFFFFFF).withValues(
        alpha: 0.33 * skin.computeLuminance() / _skin.computeLuminance(),
      ),
  );
  // A frilly pink sleeve at the wrist.
  final cuff = Path()..moveTo(92, 360);
  for (var x = 92.0; x < 218; x += 14) {
    cuff.quadraticBezierTo(x + 7, 318, x + 14, 330);
  }
  cuff
    ..lineTo(218, 372)
    ..lineTo(92, 372)
    ..close();
  canvas.drawPath(
    cuff,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 320),
        const Offset(0, 360),
        const [Color(0xFFFFD1E6), Color(0xFFFF9EC8)],
      ),
  );
  canvas.drawPath(
    cuff,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE07AAA),
  );
}

/// The shape of nail [f] in its own space (x across, y along the finger,
/// negative y towards the tip). Unfiled nails are a bit long and square.
Path nailShape(Finger f, {required bool filed}) {
  final w = f.nailWidth;
  final h = f.nailLength;
  final extra = filed ? 0.0 : h * 0.16;
  final rect = Rect.fromLTRB(-w / 2, -h / 2 - extra, w / 2, h / 2);
  return Path()..addRRect(
    RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.elliptical(w / 2, filed ? w * 0.55 : w * 0.25),
      topRight: Radius.elliptical(w / 2, filed ? w * 0.55 : w * 0.25),
      bottomLeft: Radius.circular(w * 0.32),
      bottomRight: Radius.circular(w * 0.32),
    ),
  );
}

/// Nail [n]'s shape in hand space.
Path nailPath(int n, {required bool filed}) {
  final f = kFingers[n];
  return nailShape(
    f,
    filed: filed,
  ).shift(f.nailCenter).transform(_rotation(f.nailCenter, f.angle));
}

/// All five nails: natural nail, polish, shine and decorations.
void paintNails(Canvas canvas, NailSet nails) {
  for (var n = 0; n < kFingers.length; n++) {
    final f = kFingers[n];
    final filed = nails.filed[n] != null;
    final shape = nailPath(n, filed: filed);
    // The natural nail.
    canvas.drawPath(
      shape,
      Paint()
        ..shader = ui.Gradient.linear(
          f.nailPoint(Offset(0, -f.nailLength / 2)),
          f.nailPoint(Offset(0, f.nailLength / 2)),
          const [Color(0xFFFFFFFF), Color(0xFFFFE4EA), Color(0xFFFFD0DA)],
          const [0, 0.25, 1],
        ),
    );
    // Polish where it was painted.
    final region = nailZone.regions[n];
    final colors = {for (final i in region) ?nails.polish[i]};
    final full = nails.polish.countPainted(region) == region.length;
    for (final c in colors) {
      final tool = nailColors[c];
      canvas.save();
      canvas.clipPath(shape);
      if (!(full && colors.length == 1)) {
        canvas.clipPath(
          cellsPath(
            nailZone,
            region.where((i) => nails.polish[i] == c),
            size: 1.05,
          ),
        );
      }
      final bounds = shape.getBounds();
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = ui.Gradient.linear(
            f.nailPoint(Offset(0, -f.nailLength / 2)),
            f.nailPoint(Offset(0, f.nailLength / 2)),
            [lighten(tool.color, 0.25), tool.color, darken(tool.color, 0.08)],
            const [0, 0.45, 1],
          ),
      );
      if (tool.glitter) {
        paintGlitter(canvas, bounds, n * 13, density: 0.06, size: 1.6);
      }
      canvas.restore();
    }
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = colors.isEmpty
            ? const Color(0xFFE9A9B4)
            : darken(nailColors[colors.first].color, 0.25),
    );
    if (!filed) {
      // A rough edge that wants filing.
      final a = f.nailPoint(Offset(-f.nailWidth * 0.3, -f.nailLength * 0.62));
      final b = f.nailPoint(Offset(f.nailWidth * 0.3, -f.nailLength * 0.62));
      canvas.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 1.2
          ..color = const Color(0x66C98A98),
      );
    }
    // Shine from the dryer.
    if (nails.shine[n] != null) {
      final s = f.nailPoint(Offset(-f.nailWidth * 0.2, -f.nailLength * 0.15));
      final e = f.nailPoint(Offset(-f.nailWidth * 0.18, f.nailLength * 0.25));
      canvas.drawLine(
        s,
        e,
        Paint()
          ..strokeWidth = f.nailWidth * 0.16
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xCCFFFFFF),
      );
      canvas.drawPath(
        starPath(
          f.nailPoint(Offset(f.nailWidth * 0.22, -f.nailLength * 0.3)),
          f.nailWidth * 0.16,
          points: 4,
          inner: f.nailWidth * 0.05,
        ),
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
    final deco = nails.deco[n];
    if (deco != null && deco < NailDeco.values.length) {
      paintNailDeco(
        canvas,
        NailDeco.values[deco],
        f.nailPoint(Offset(0, f.nailLength * 0.08)),
        f.nailWidth * 0.62,
      );
    }
  }
}

/// A nail decoration of [size] centered on [c].
void paintNailDeco(Canvas canvas, NailDeco deco, Offset c, double size) {
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.8, size * 0.07)
    ..strokeJoin = StrokeJoin.round;
  switch (deco) {
    case NailDeco.gem:
      final s = size / 2;
      final gem = Path()
        ..moveTo(c.dx - s, c.dy - s * 0.25)
        ..lineTo(c.dx - s * 0.5, c.dy - s * 0.75)
        ..lineTo(c.dx + s * 0.5, c.dy - s * 0.75)
        ..lineTo(c.dx + s, c.dy - s * 0.25)
        ..lineTo(c.dx, c.dy + s)
        ..close();
      canvas.drawPath(
        gem,
        Paint()
          ..shader = ui.Gradient.linear(
            c - Offset(s, s),
            c + Offset(s, s),
            const [Color(0xFFE8FCFF), Color(0xFF7FDDF0), Color(0xFF3FAEDB)],
            const [0, 0.5, 1],
          ),
      );
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - s, c.dy - s * 0.25)
          ..lineTo(c.dx + s, c.dy - s * 0.25)
          ..moveTo(c.dx - s * 0.3, c.dy - s * 0.25)
          ..lineTo(c.dx, c.dy + s)
          ..lineTo(c.dx + s * 0.3, c.dy - s * 0.25),
        outline
          ..strokeWidth = math.max(0.6, size * 0.04)
          ..color = const Color(0xAAFFFFFF),
      );
      canvas.drawPath(
        gem,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, size * 0.07)
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF2C8DB8),
      );
    case NailDeco.heart:
      final heart = heartPath(c, size);
      canvas.drawPath(heart, Paint()..color = const Color(0xFFFF4F8B));
      canvas.drawPath(heart, outline..color = const Color(0xFFC2306A));
      canvas.drawCircle(
        c - Offset(size * 0.18, size * 0.12),
        size * 0.1,
        Paint()..color = const Color(0xCCFFFFFF),
      );
    case NailDeco.star:
      final star = starPath(c, size * 0.55, inner: size * 0.25);
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFD84D));
      canvas.drawPath(star, outline..color = const Color(0xFFC98A12));
    case NailDeco.flower:
      final petal = Paint()..color = const Color(0xFFFFF4FA);
      final line = outline..color = const Color(0xFFE88BB5);
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 5;
        final p = c + Offset(math.cos(a), math.sin(a)) * (size * 0.27);
        canvas.drawCircle(p, size * 0.21, petal);
        canvas.drawCircle(p, size * 0.21, line);
      }
      canvas.drawCircle(
        c,
        size * 0.15,
        Paint()..color = const Color(0xFFFFD84D),
      );
  }
}

// ----------------------------------------------------- the doll's hands

/// Tiny polished nails on the doll's two fists (doll space).
void paintDollNails(Canvas canvas, NailSet nails, {required bool right}) {
  canvas.save();
  if (right) {
    canvas.translate(200, 0);
    canvas.scale(-1, 1);
  }
  const hand = Offset(64.5, 252);
  const spots = [
    Offset(-5.4, 3.6), // pinky
    Offset(-3.1, 5.7),
    Offset(-0.2, 6.5),
    Offset(2.8, 5.8),
  ];
  for (var n = 0; n < kFingers.length; n++) {
    final c = nails.colorOf(n);
    if (c == null) continue;
    final color = nailColors[c].color;
    final p = n < spots.length ? hand + spots[n] : const Offset(71.5, 246.2);
    final rect = Rect.fromCenter(center: p, width: 2.8, height: 2.3);
    canvas.drawOval(rect, Paint()..color = color);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = darken(color, 0.35),
    );
    if (nails.shine[n] != null || nailColors[c].glitter) {
      canvas.drawCircle(
        p - const Offset(0.5, 0.4),
        0.45,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
  }
  canvas.restore();
}

/// The doll layer with nails for one hand (empty list when unpainted).
List<ArtLayer> dollNailLayers(NailSet nails, {required bool right}) {
  if (nails.polish.isEmpty) return const [];
  return [
    ArtLayer.drawn(
      'nails|${right ? 'r' : 'l'}|${nails.key}',
      () async => recordPicture((c) => paintDollNails(c, nails, right: right)),
    ),
  ];
}
