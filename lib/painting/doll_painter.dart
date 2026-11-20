import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';
import 'background_painter.dart';
import 'shapes.dart';

/// The doll is drawn on a 200 x 400 "doll space". This is the part of doll
/// space that is shown when the whole doll is visible.
const Rect kDollFrame = Rect.fromLTRB(8, 8, 192, 372);

/// Scales and centers a rectangle of doll space into a widget of [size].
class FitTransform {
  FitTransform(Rect src, Size size)
    : scale = math.min(size.width / src.width, size.height / src.height),
      _src = src,
      _size = size;

  final double scale;
  final Rect _src;
  final Size _size;

  double get dx => (_size.width - _src.width * scale) / 2 - _src.left * scale;
  double get dy => (_size.height - _src.height * scale) / 2 - _src.top * scale;

  Offset apply(Offset p) => Offset(dx + p.dx * scale, dy + p.dy * scale);
}

/// The part of doll space that shows an item best (used for thumbnails and
/// as the center of the sparkle animation).
Rect focusRectFor(ItemShape shape) {
  switch (shape.slot) {
    case Slot.hair:
      return const Rect.fromLTRB(30, 14, 170, 224);
    case Slot.dress:
      return const Rect.fromLTRB(30, 136, 170, 356);
    case Slot.top:
      return const Rect.fromLTRB(42, 136, 158, 252);
    case Slot.skirt:
      return shape == ItemShape.skirtLong
          ? const Rect.fromLTRB(40, 194, 160, 334)
          : const Rect.fromLTRB(40, 190, 160, 286);
    case Slot.shoes:
      return const Rect.fromLTRB(62, 300, 138, 370);
    case Slot.head:
      return const Rect.fromLTRB(54, 14, 154, 104);
    case Slot.eyes:
      return const Rect.fromLTRB(58, 72, 142, 128);
    case Slot.hand:
      switch (shape) {
        case ItemShape.handWand:
          return const Rect.fromLTRB(20, 166, 92, 262);
        case ItemShape.handBalloon:
          return const Rect.fromLTRB(110, 76, 200, 250);
        default:
          return const Rect.fromLTRB(112, 210, 172, 284);
      }
    case Slot.background:
      return kDollFrame;
  }
}

/// Paints the background (optional) and the doll wearing [outfit].
class DollPainter extends CustomPainter {
  DollPainter({
    required this.outfit,
    this.frame = kDollFrame,
    this.showBackground = true,
    this.showDoll = true,
  });

  final Outfit outfit;

  /// Which part of doll space to show (for zoomed-in thumbnails).
  final Rect frame;
  final bool showBackground;
  final bool showDoll;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (showBackground) {
      final bg = outfit[Slot.background];
      if (bg != null) {
        paintBackground(canvas, size, bg.item.shape, bg.color);
      } else {
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = backgroundColors.first,
        );
      }
    }
    if (!showDoll) return;
    final t = FitTransform(frame, size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(t.dx, t.dy);
    canvas.scale(t.scale);
    _DollArtist(canvas, outfit).paint();
    canvas.restore();
  }

  @override
  bool shouldRepaint(DollPainter oldDelegate) =>
      oldDelegate.outfit != outfit ||
      oldDelegate.frame != frame ||
      oldDelegate.showBackground != showBackground ||
      oldDelegate.showDoll != showDoll;
}

// Body landmarks in doll space.
const _shoulderL = Offset(78, 158);
const _shoulderR = Offset(122, 158);
const _handL = Offset(60, 238);
const _handR = Offset(140, 238);
const _headCenter = Offset(100, 90);
const _headR = 40.0;
const _eyeL = Offset(85, 100);
const _eyeR = Offset(115, 100);
const _footL = Offset(85, 354);
const _footR = Offset(115, 354);

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Half the width of the body at height [y].
double _bodyHalfWidth(double y) {
  if (y <= 152) return 28;
  if (y <= 205) return _lerp(28, 20, (y - 152) / 53);
  return _lerp(20, 25, ((y - 205) / 33).clamp(0.0, 1.0));
}

/// The shape of the upper body from the shoulders down to [bottom].
Path _torsoPath(double bottom, {double neck = 156, bool straps = false}) {
  final p = Path();
  final startY = straps ? 172.0 : 160.0;
  if (straps) {
    p.moveTo(100 - _bodyHalfWidth(172), 172);
    p.lineTo(80, 151);
    p.lineTo(89, 151);
    p.quadraticBezierTo(100, neck + 8, 111, 151);
    p.lineTo(120, 151);
    p.lineTo(100 + _bodyHalfWidth(172), 172);
  } else {
    p.moveTo(72, 160);
    p.quadraticBezierTo(73, 148, 88, 148);
    p.quadraticBezierTo(100, neck, 112, 148);
    p.quadraticBezierTo(127, 148, 128, 160);
  }
  for (var y = startY + 4; y < bottom; y += 4) {
    p.lineTo(100 + _bodyHalfWidth(y), y);
  }
  p.lineTo(100 + _bodyHalfWidth(bottom), bottom);
  p.quadraticBezierTo(100, bottom + 5, 100 - _bodyHalfWidth(bottom), bottom);
  for (var y = bottom - 4; y > startY; y -= 4) {
    p.lineTo(100 - _bodyHalfWidth(y), y);
  }
  return p..close();
}

/// A puffy skirt with a scalloped hem.
Path _tutuPath(
  double waistY,
  double hemY,
  double halfWidth, {
  int scallops = 7,
}) {
  final p = Path()
    ..moveTo(80, waistY)
    ..lineTo(120, waistY)
    ..quadraticBezierTo(
      100 + halfWidth * 0.9,
      waistY + 8,
      100 + halfWidth,
      hemY,
    );
  final step = halfWidth * 2 / scallops;
  for (var i = 0; i < scallops; i++) {
    final x1 = 100 + halfWidth - (i + 1) * step;
    p.quadraticBezierTo(x1 + step / 2, hemY + step * 0.7, x1, hemY);
  }
  p.quadraticBezierTo(100 - halfWidth * 0.9, waistY + 8, 80, waistY);
  return p..close();
}

/// Ballgown, sun dress and long dress skirts.
Path _flaredSkirt(
  double hemY,
  double hemHalf, {
  double bulge = 0,
  bool scalloped = false,
}) {
  final p = Path()
    ..moveTo(81, 204)
    ..lineTo(119, 204)
    ..quadraticBezierTo(
      120 + bulge + (hemHalf - 20) * 0.3,
      (204 + hemY) / 2,
      100 + hemHalf,
      hemY,
    );
  if (scalloped) {
    const n = 8;
    final step = hemHalf * 2 / n;
    for (var i = 0; i < n; i++) {
      final x1 = 100 + hemHalf - (i + 1) * step;
      p.quadraticBezierTo(x1 + step / 2, hemY + step * 0.55, x1, hemY);
    }
  } else {
    p.quadraticBezierTo(100, hemY + 10, 100 - hemHalf, hemY);
  }
  p.quadraticBezierTo(
    80 - bulge - (hemHalf - 20) * 0.3,
    (204 + hemY) / 2,
    81,
    204,
  );
  return p..close();
}

class _DollArtist {
  _DollArtist(this.canvas, this.outfit);

  final Canvas canvas;
  final Outfit outfit;

  // ---------------------------------------------------------------- helpers

  void fill(Path p, Color c, {bool outline = true, double width = 1.6}) {
    canvas.drawPath(p, Paint()..color = c);
    if (outline) {
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..color = outlineOf(c),
      );
    }
  }

  void circle(Offset c, double r, Color color, {bool outline = true}) => fill(
    Path()..addOval(Rect.fromCircle(center: c, radius: r)),
    color,
    outline: outline,
  );

  void oval(Offset c, double w, double h, Color color, {bool outline = true}) =>
      fill(
        Path()..addOval(Rect.fromCenter(center: c, width: w, height: h)),
        color,
        outline: outline,
      );

  void thickLine(
    Offset a,
    Offset b,
    double width,
    Color c, {
    bool outline = true,
  }) {
    if (outline) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = outlineOf(c)
          ..strokeWidth = width + 3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = c
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void stroke(Path p, Color c, double width) => canvas.drawPath(
    p,
    Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  /// Draws [pattern] inside [clip] and re-draws the outline on top.
  void pattern(Path clip, ItemPattern pattern, Color base) {
    if (pattern == ItemPattern.none) return;
    final b = clip.getBounds();
    final paint = Paint()..color = contrastOn(base).withValues(alpha: 0.85);
    canvas.save();
    canvas.clipPath(clip);
    switch (pattern) {
      case ItemPattern.dots:
        var row = 0;
        for (var y = b.top + 5; y < b.bottom + 6; y += 11, row++) {
          for (
            var x = b.left + (row.isOdd ? 5.5 : 0);
            x < b.right + 6;
            x += 11
          ) {
            canvas.drawCircle(Offset(x, y), 2.6, paint);
          }
        }
      case ItemPattern.stripes:
        for (var y = b.top + 4; y < b.bottom; y += 11) {
          canvas.drawRect(
            Rect.fromLTWH(b.left - 2, y, b.width + 4, 4.5),
            paint,
          );
        }
      case ItemPattern.stars:
        var row = 0;
        for (var y = b.top + 8; y < b.bottom + 8; y += 16, row++) {
          for (var x = b.left + (row.isOdd ? 8 : 0); x < b.right + 8; x += 16) {
            canvas.drawPath(starPath(Offset(x, y), 4.2), paint);
          }
        }
      case ItemPattern.hearts:
        var row = 0;
        for (var y = b.top + 7; y < b.bottom + 8; y += 15, row++) {
          for (
            var x = b.left + (row.isOdd ? 7.5 : 0);
            x < b.right + 8;
            x += 15
          ) {
            canvas.drawPath(heartPath(Offset(x, y), 7.5), paint);
          }
        }
      case ItemPattern.none:
        break;
    }
    canvas.restore();
    stroke(clip, outlineOf(base), 1.6);
  }

  void garment(Path p, Color c, ItemPattern pat) {
    fill(p, c);
    pattern(p, pat, c);
  }

  // ------------------------------------------------------------------ doll

  void paint() {
    // Soft shadow on the floor.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 362), width: 96, height: 14),
      Paint()..color = const Color(0x22000000),
    );

    final hair = outfit[Slot.hair];
    final dressWorn = outfit[Slot.dress];
    if (dressWorn != null) dressBack(dressWorn);
    if (hair != null) hairBack(hair);

    // Legs and feet
    final legs = Path()
      ..addRRect(RRect.fromLTRBR(83, 228, 97, 352, const Radius.circular(7)))
      ..addRRect(RRect.fromLTRBR(103, 228, 117, 352, const Radius.circular(7)));
    fill(legs, skinColor);
    oval(_footL, 22, 11, skinColor);
    oval(_footR, 22, 11, skinColor);
    final shoes = outfit[Slot.shoes];
    if (shoes != null) this.shoes(shoes);

    // Body: skin, then a simple leotard so the doll is never "undressed".
    fill(_torsoPath(236), skinColor);
    final leo = _torsoPath(230, straps: true)
      ..addRRect(RRect.fromLTRBR(80, 222, 120, 246, const Radius.circular(9)));
    fill(Path.combine(PathOperation.union, leo, Path()), leotardColor);

    final dress = outfit[Slot.dress];
    final top = outfit[Slot.top];
    final skirt = outfit[Slot.skirt];
    if (dress != null) {
      dressBody(dress);
    } else {
      if (top != null) topBody(top);
      if (skirt != null) skirtBody(skirt);
    }

    // Arms in front of the clothes, then sleeves on top of the arms.
    thickLine(_shoulderL, _handL, 13, skinColor);
    thickLine(_shoulderR, _handR, 13, skinColor);
    circle(_handL, 7.5, skinColor);
    circle(_handR, 7.5, skinColor);
    if (dress != null) {
      dressSleeves(dress);
    } else if (top != null) {
      topSleeves(top);
    }

    if (hair != null) hairMiddle(hair);
    head();
    if (hair != null) hairFront(hair);

    final headItem = outfit[Slot.head];
    if (headItem != null) headAccessory(headItem);
    final eyes = outfit[Slot.eyes];
    if (eyes != null) glasses(eyes);
    final hand = outfit[Slot.hand];
    if (hand != null) handItem(hand);
  }

  void head() {
    fill(
      Path()..addRRect(
        RRect.fromLTRBR(93, 120, 107, 154, const Radius.circular(5)),
      ),
      skinColor,
    );
    circle(const Offset(60, 98), 7, skinColor);
    circle(const Offset(140, 98), 7, skinColor);
    circle(_headCenter, _headR, skinColor);

    // Eyes
    const eyeColor = Color(0xFF3B2A4A);
    for (final e in [_eyeL, _eyeR]) {
      oval(e, 11, 14, eyeColor, outline: false);
      canvas.drawCircle(
        e + const Offset(2, -3),
        3,
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawCircle(
        e + const Offset(-2, 3),
        1.3,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
    // Eyelashes
    final lash = Paint()
      ..color = eyeColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      _eyeL + const Offset(-5, -5),
      _eyeL + const Offset(-8.5, -8),
      lash,
    );
    canvas.drawLine(
      _eyeR + const Offset(5, -5),
      _eyeR + const Offset(8.5, -8),
      lash,
    );

    // Cheeks
    final blush = Paint()..color = const Color(0x66FF8FA8);
    canvas.drawCircle(const Offset(75, 112), 6.5, blush);
    canvas.drawCircle(const Offset(125, 112), 6.5, blush);

    // Nose and smile
    stroke(
      Path()
        ..moveTo(98, 107)
        ..quadraticBezierTo(100, 109, 102, 107),
      skinShadeColor,
      1.6,
    );
    final smile = Path()
      ..moveTo(91, 114)
      ..quadraticBezierTo(100, 124, 109, 114)
      ..quadraticBezierTo(100, 118, 91, 114)
      ..close();
    fill(smile, const Color(0xFFE0607E), width: 1.2);
  }

  // ------------------------------------------------------------------ hair

  Path _hairCap() => Path()
    ..moveTo(56, 112)
    ..cubicTo(48, 60, 74, 42, 100, 42)
    ..cubicTo(126, 42, 152, 60, 144, 112)
    ..quadraticBezierTo(140, 86, 130, 74)
    ..quadraticBezierTo(122, 90, 112, 75)
    ..quadraticBezierTo(104, 90, 94, 75)
    ..quadraticBezierTo(84, 90, 72, 74)
    ..quadraticBezierTo(60, 86, 56, 112)
    ..close();

  void hairBack(WornItem w) {
    final c = w.color;
    switch (w.item.shape) {
      case ItemShape.hairLong:
        final p = Path()
          ..moveTo(100, 42)
          ..cubicTo(50, 42, 44, 100, 47, 205);
        const n = 5;
        const step = 106 / n;
        for (var i = 0; i < n; i++) {
          final x1 = 47 + (i + 1) * step;
          p.quadraticBezierTo(x1 - step / 2, 216, x1, 205);
        }
        p.cubicTo(156, 100, 150, 42, 100, 42);
        fill(p..close(), c);
      case ItemShape.hairBob:
        fill(
          Path()
            ..moveTo(100, 42)
            ..cubicTo(48, 42, 40, 100, 50, 142)
            ..quadraticBezierTo(100, 156, 150, 142)
            ..cubicTo(160, 100, 152, 42, 100, 42)
            ..close(),
          c,
        );
      case ItemShape.hairPigtails:
        circle(const Offset(100, 88), 46, c);
        for (final side in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(100 + side * 46, 104);
          canvas.rotate(side * 0.45);
          oval(const Offset(0, 28), 30, 62, c);
          canvas.restore();
        }
      case ItemShape.hairBun:
        circle(const Offset(100, 88), 46, c);
        circle(const Offset(100, 34), 19, c);
      case ItemShape.hairCurly:
        final p = Path()
          ..addOval(
            Rect.fromCircle(center: const Offset(100, 100), radius: 50),
          );
        for (var i = 0; i < 14; i++) {
          final a = i * 2 * math.pi / 14;
          p.addOval(
            Rect.fromCircle(
              center: Offset(100 + 50 * math.cos(a), 104 + 54 * math.sin(a)),
              radius: 19,
            ),
          );
        }
        fill(Path.combine(PathOperation.union, p, Path()), c);
      case ItemShape.hairBraids:
        circle(const Offset(100, 88), 46, c);
      case ItemShape.hairPonytail:
        // A swishy ponytail from the top-right of the head.
        fill(
          Path()
            ..moveTo(128, 46)
            ..cubicTo(176, 34, 188, 112, 164, 176)
            ..quadraticBezierTo(162, 150, 152, 136)
            ..quadraticBezierTo(166, 100, 140, 62)
            ..close(),
          c,
        );
        circle(const Offset(100, 88), 46, c);
      case ItemShape.hairSpaceBuns:
        circle(const Offset(66, 46), 18, c);
        circle(const Offset(134, 46), 18, c);
        circle(const Offset(100, 88), 46, c);
      default:
        break;
    }
  }

  /// Hair that hangs in front of the shoulders.
  void hairMiddle(WornItem w) {
    if (w.item.shape != ItemShape.hairBraids) return;
    final c = w.color;
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 7; i++) {
        oval(Offset(100 + side * (39 + i * 0.8), 124 + i * 13.5), 19, 17, c);
      }
      final tie = Offset(100 + side * 44.6, 214);
      oval(tie, 14, 6, const Color(0xFFFF8FC7));
      fill(
        Path()
          ..moveTo(tie.dx - 6, tie.dy + 2)
          ..quadraticBezierTo(tie.dx, tie.dy + 20, tie.dx + 6, tie.dy + 2)
          ..close(),
        c,
      );
    }
  }

  void hairFront(WornItem w) {
    final c = w.color;
    fill(_hairCap(), c);
    // A shiny highlight
    stroke(
      Path()
        ..moveTo(76, 56)
        ..quadraticBezierTo(86, 49, 98, 48),
      lighten(c, 0.45).withValues(alpha: 0.8),
      3,
    );
    const tieColor = Color(0xFFFF8FC7);
    switch (w.item.shape) {
      case ItemShape.hairPigtails:
        circle(const Offset(56, 102), 6, tieColor);
        circle(const Offset(144, 102), 6, tieColor);
      case ItemShape.hairBun:
        oval(const Offset(100, 50), 22, 7, tieColor);
      case ItemShape.hairPonytail:
        circle(const Offset(134, 52), 6.5, tieColor);
      case ItemShape.hairSpaceBuns:
        // Little curls in each bun and a tie under them
        stroke(
          Path()
            ..addArc(
              Rect.fromCircle(center: const Offset(66, 44), radius: 8),
              0.5,
              4,
            )
            ..addArc(
              Rect.fromCircle(center: const Offset(134, 44), radius: 8),
              -1.4,
              4,
            ),
          outlineOf(c),
          1.6,
        );
        circle(const Offset(74, 60), 5, tieColor);
        circle(const Offset(126, 60), 5, tieColor);
      case ItemShape.hairCurly:
        for (final p in const [
          Offset(66, 72),
          Offset(80, 58),
          Offset(100, 52),
          Offset(120, 58),
          Offset(134, 72),
        ]) {
          circle(p, 13, c);
        }
      default:
        break;
    }
  }

  // ----------------------------------------------------------------- shoes

  void shoes(WornItem w) {
    final c = w.color;
    for (final foot in [_footL, _footR]) {
      final out = foot.dx < 100 ? -1.0 : 1.0; // toes point outward
      switch (w.item.shape) {
        case ItemShape.shoesBoots:
          final legX = foot.dx < 100 ? 90.0 : 110.0;
          fill(
            Path()..addRRect(
              RRect.fromLTRBR(
                legX - 9.5,
                312,
                legX + 9.5,
                352,
                const Radius.circular(5),
              ),
            ),
            c,
          );
          oval(foot + Offset(out * 1.5, -1), 27, 14, c);
          fill(
            Path()..addRRect(
              RRect.fromLTRBR(
                legX - 10.5,
                310,
                legX + 10.5,
                319,
                const Radius.circular(4),
              ),
            ),
            lighten(c, 0.4),
          );
        case ItemShape.shoesFlats:
          oval(foot + const Offset(0, 1), 25, 12, c);
          oval(foot + Offset(-out * 3, -1.5), 13, 5, skinColor, outline: false);
          circle(foot + Offset(out * 8, -2), 2.6, contrastOn(c));
        case ItemShape.shoesSandals:
          oval(foot + const Offset(0, 4), 26, 7, darken(c, 0.08));
          final strap = Paint()
            ..color = c
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            foot + Offset(out * 9, -1),
            foot + Offset(out * 1, 2),
            strap,
          );
          canvas.drawLine(
            foot + Offset(out * 2, -4),
            foot + Offset(-out * 6, 1),
            strap,
          );
          final legX = foot.dx < 100 ? 90.0 : 110.0;
          canvas.drawLine(Offset(legX - 7, 343), Offset(legX + 7, 343), strap);
          circle(foot + Offset(out * 3, -3), 2.4, contrastOn(c));
        default: // sneakers
          oval(foot + const Offset(0, -1), 27, 15, c);
          fill(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: foot + const Offset(0, 6),
                  width: 28,
                  height: 5,
                ),
                const Radius.circular(2.5),
              ),
            ),
            const Color(0xFFFFFFFF),
            width: 1.2,
          );
          final lace = Paint()
            ..color = const Color(0xFFFFFFFF)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(foot + Offset(-3, -5), foot + Offset(3, -5), lace);
          canvas.drawLine(
            foot + Offset(-3, -1.5),
            foot + Offset(3, -1.5),
            lace,
          );
      }
    }
  }

  // ----------------------------------------------------------------- tops

  void topBody(WornItem w) {
    final c = w.color;
    final pat = w.item.pattern;
    switch (w.item.shape) {
      case ItemShape.topTank:
        final body = _torsoPath(216, neck: 164, straps: true);
        garment(body, c, pat);
        // Little bow at the neckline
        final bow = Offset(100, 163);
        fill(
          starPath(bow, 4.5, inner: 2.5, points: 4),
          contrastOn(c),
          width: 1,
        );
      case ItemShape.topSweater:
        final body = _torsoPath(222, neck: 152);
        garment(body, c, pat);
        final band = Path()
          ..addRRect(
            RRect.fromLTRBR(78, 214, 122, 226, const Radius.circular(4)),
          );
        fill(band, darken(c, 0.1));
      default: // t-shirt
        garment(_torsoPath(218), c, pat);
    }
  }

  void topSleeves(WornItem w) {
    final c = w.color;
    switch (w.item.shape) {
      case ItemShape.topSweater:
        for (final arm in [(_shoulderL, _handL), (_shoulderR, _handR)]) {
          final end = Offset.lerp(arm.$1, arm.$2, 0.82)!;
          thickLine(arm.$1, end, 17, c);
          thickLine(
            Offset.lerp(arm.$1, arm.$2, 0.78)!,
            end,
            17,
            darken(c, 0.1),
            outline: false,
          );
        }
      case ItemShape.topTshirt:
        for (final arm in [(_shoulderL, _handL), (_shoulderR, _handR)]) {
          thickLine(arm.$1, Offset.lerp(arm.$1, arm.$2, 0.3)!, 19, c);
        }
      default:
        break;
    }
  }

  // ---------------------------------------------------------------- skirts

  void skirtBody(WornItem w) {
    final c = w.color;
    final pat = w.item.pattern;
    switch (w.item.shape) {
      case ItemShape.skirtTutu:
        fill(_tutuPath(203, 248, 50), lighten(c, 0.35));
        garment(_tutuPath(203, 240, 43, scallops: 6), c, pat);
      case ItemShape.skirtLong:
        garment(
          Path()
            ..moveTo(81, 203)
            ..lineTo(119, 203)
            ..quadraticBezierTo(127, 262, 136, 324)
            ..quadraticBezierTo(100, 332, 64, 324)
            ..quadraticBezierTo(73, 262, 81, 203)
            ..close(),
          c,
          pat,
        );
      default: // A-line
        garment(
          Path()
            ..moveTo(81, 203)
            ..lineTo(119, 203)
            ..lineTo(142, 266)
            ..quadraticBezierTo(100, 276, 58, 266)
            ..close(),
          c,
          pat,
        );
    }
    fill(
      Path()..addRRect(
        RRect.fromLTRBR(79, 199, 121, 209, const Radius.circular(4)),
      ),
      darken(c, 0.1),
    );
  }

  // ---------------------------------------------------------------- dresses

  void dressBody(WornItem w) {
    final c = w.color;
    final pat = w.item.pattern;
    switch (w.item.shape) {
      case ItemShape.dressPrincess:
        garment(_flaredSkirt(336, 64, bulge: 8, scalloped: true), c, pat);
        garment(_torsoPath(212), c, pat);
        fill(
          Path()..addRRect(
            RRect.fromLTRBR(78, 203, 122, 213, const Radius.circular(5)),
          ),
          lighten(c, 0.55),
        );
        fill(heartPath(const Offset(100, 208), 10), darken(c, 0.12), width: 1);
      case ItemShape.dressSun:
        garment(_flaredSkirt(282, 48), c, pat);
        garment(_torsoPath(212, neck: 160, straps: true), c, pat);
        _waistBow(lighten(c, 0.55));
      case ItemShape.dressTutu:
        fill(_tutuPath(204, 252, 54), lighten(c, 0.35));
        garment(_tutuPath(204, 243, 46, scallops: 6), c, pat);
        garment(_torsoPath(212), c, pat);
        fill(
          starPath(const Offset(100, 176), 8),
          const Color(0xFFFFE066),
          width: 1.2,
        );
      case ItemShape.dressLong:
        garment(_flaredSkirt(340, 46, bulge: 2), c, pat);
        garment(_torsoPath(212, neck: 170, straps: true), c, pat);
        fill(
          Path()..addRRect(
            RRect.fromLTRBR(79, 202, 121, 210, const Radius.circular(4)),
          ),
          darken(c, 0.1),
        );
      case ItemShape.dressMermaid:
        // Snug down to the knees, then a wavy tail-fin hem.
        final skirt = Path()
          ..moveTo(81, 204)
          ..lineTo(119, 204)
          ..quadraticBezierTo(126, 262, 113, 300)
          ..quadraticBezierTo(128, 318, 142, 340);
        const n = 6;
        const step = 80 / n;
        for (var i = 0; i < n; i++) {
          final x1 = 140 - (i + 1) * step;
          skirt.quadraticBezierTo(x1 + step / 2, 352, x1, 340);
        }
        skirt
          ..quadraticBezierTo(72, 318, 87, 300)
          ..quadraticBezierTo(74, 262, 81, 204)
          ..close();
        garment(skirt, c, pat);
        // Fin lines and a scale pattern
        final fin = outlineOf(c).withValues(alpha: 0.6);
        for (var x = 76.0; x <= 124; x += 12) {
          stroke(
            Path()
              ..moveTo(100 + (x - 100) * 0.4, 304)
              ..lineTo(x, 340),
            fin,
            1.2,
          );
        }
        canvas.save();
        canvas.clipPath(skirt);
        final scale = contrastOn(c).withValues(alpha: 0.7);
        var row = 0;
        for (var y = 214.0; y < 298; y += 9, row++) {
          for (var x = 78.0 + (row.isOdd ? 5 : 0); x < 124; x += 10) {
            stroke(
              Path()..addArc(
                Rect.fromCircle(center: Offset(x, y), radius: 5),
                0,
                3.14,
              ),
              scale,
              1.2,
            );
          }
        }
        canvas.restore();
        garment(_torsoPath(212, neck: 164, straps: true), c, pat);
        fill(
          Path()..addRRect(
            RRect.fromLTRBR(79, 202, 121, 210, const Radius.circular(4)),
          ),
          lighten(c, 0.5),
        );
        circle(const Offset(100, 206), 3.5, const Color(0xFFFFFFFF));
      case ItemShape.dressFairy:
        // Pointy petal skirt in two layers
        Path petals(double hem, double half, int n) {
          final p = Path()
            ..moveTo(81, 204)
            ..lineTo(119, 204)
            ..lineTo(100 + half * 0.8, hem - 12);
          final step = half * 2 / n;
          for (var i = 0; i < n; i++) {
            final x0 = 100 + half - i * step;
            p
              ..lineTo(x0 - step / 2, hem)
              ..lineTo(x0 - step, hem - 12);
          }
          return p
            ..lineTo(81, 204)
            ..close();
        }

        fill(petals(268, 46, 5), lighten(c, 0.4));
        garment(petals(258, 40, 4), c, pat);
        garment(_torsoPath(212, neck: 162, straps: true), c, pat);
        fill(
          Path()..addRRect(
            RRect.fromLTRBR(79, 202, 121, 210, const Radius.circular(4)),
          ),
          darken(c, 0.12),
        );
        fill(
          starPath(const Offset(100, 206), 6),
          const Color(0xFFFFE066),
          width: 1,
        );
      case ItemShape.dressParty:
        // Puffy "bubble" skirt with a big bow
        final skirt = Path()
          ..moveTo(81, 204)
          ..lineTo(119, 204)
          ..cubicTo(152, 214, 152, 258, 124, 264)
          ..quadraticBezierTo(100, 272, 76, 264)
          ..cubicTo(48, 258, 48, 214, 81, 204)
          ..close();
        garment(skirt, c, pat);
        stroke(
          Path()
            ..moveTo(70, 254)
            ..quadraticBezierTo(100, 266, 130, 254),
          outlineOf(c).withValues(alpha: 0.5),
          1.4,
        );
        garment(_torsoPath(212), c, pat);
        _waistBow(lighten(c, 0.6), size: 1.5);
      default:
        break;
    }
  }

  /// Parts of a dress that are behind the body (fairy wings).
  void dressBack(WornItem w) {
    if (w.item.shape != ItemShape.dressFairy) return;
    final wing = lighten(w.color, 0.55).withValues(alpha: 0.85);
    for (final side in [-1.0, 1.0]) {
      for (final (center, width, height, angle) in [
        (const Offset(42, 168), 54.0, 74.0, -0.6),
        (const Offset(56, 222), 36.0, 50.0, 0.5),
      ]) {
        canvas.save();
        canvas.translate(100 + side * (100 - center.dx), center.dy);
        canvas.rotate(side * -angle);
        final p = Path()
          ..addOval(
            Rect.fromCenter(center: Offset.zero, width: width, height: height),
          );
        canvas.drawPath(p, Paint()..color = wing);
        stroke(p, outlineOf(w.color).withValues(alpha: 0.6), 1.4);
        canvas.drawCircle(
          Offset(0, -height * 0.15),
          width * 0.12,
          Paint()..color = const Color(0x88FFFFFF),
        );
        canvas.restore();
      }
    }
  }

  void _waistBow(Color c, {double size = 1}) {
    const k = Offset(100, 208);
    final a = 11 * size;
    final b = 7 * size;
    fill(
      Path()
        ..moveTo(k.dx, k.dy)
        ..lineTo(k.dx - a, k.dy - b)
        ..lineTo(k.dx - a, k.dy + b)
        ..close()
        ..moveTo(k.dx, k.dy)
        ..lineTo(k.dx + a, k.dy - b)
        ..lineTo(k.dx + a, k.dy + b)
        ..close(),
      c,
      width: 1.2,
    );
    circle(k, 3.5 * size, c);
  }

  void dressSleeves(WornItem w) {
    final shape = w.item.shape;
    if (shape == ItemShape.dressPrincess) {
      final c = lighten(w.color, 0.15);
      circle(_shoulderL + const Offset(-1, 2), 13, c);
      circle(_shoulderR + const Offset(1, 2), 13, c);
    } else if (shape == ItemShape.dressParty) {
      circle(_shoulderL + const Offset(0, 1), 10, w.color);
      circle(_shoulderR + const Offset(0, 1), 10, w.color);
    }
  }

  // ----------------------------------------------------------- accessories

  void headAccessory(WornItem w) {
    final c = w.color;
    switch (w.item.shape) {
      case ItemShape.headCrown:
        final crown = Path()
          ..moveTo(74, 58)
          ..lineTo(71, 28)
          ..lineTo(86, 42)
          ..lineTo(100, 20)
          ..lineTo(114, 42)
          ..lineTo(129, 28)
          ..lineTo(126, 58)
          ..quadraticBezierTo(100, 52, 74, 58)
          ..close();
        fill(crown, c);
        circle(const Offset(71, 28), 3.5, c);
        circle(const Offset(100, 20), 3.8, c);
        circle(const Offset(129, 28), 3.5, c);
        circle(const Offset(100, 47), 4.5, const Color(0xFFFF6B8B));
        circle(const Offset(85, 50), 3, const Color(0xFF7CB8FF));
        circle(const Offset(115, 50), 3, const Color(0xFF7CB8FF));
      case ItemShape.headTiara:
        stroke(
          Path()..addArc(
            Rect.fromCircle(center: const Offset(100, 92), radius: 46),
            math.pi * 1.18,
            math.pi * 0.64,
          ),
          outlineOf(c),
          6,
        );
        stroke(
          Path()..addArc(
            Rect.fromCircle(center: const Offset(100, 92), radius: 46),
            math.pi * 1.18,
            math.pi * 0.64,
          ),
          c,
          4,
        );
        fill(starPath(const Offset(100, 38), 11), c);
        fill(starPath(const Offset(80, 44), 6.5), c);
        fill(starPath(const Offset(120, 44), 6.5), c);
        circle(const Offset(100, 39), 3.2, const Color(0xFFFF8FC7));
      case ItemShape.headBow:
        canvas.save();
        canvas.translate(130, 54);
        canvas.rotate(0.4);
        fill(
          Path()
            ..moveTo(-4, 4)
            ..lineTo(-9, 18)
            ..lineTo(-2, 15)
            ..close()
            ..moveTo(4, 4)
            ..lineTo(9, 18)
            ..lineTo(2, 15)
            ..close(),
          c,
          width: 1.2,
        );
        oval(const Offset(-11, 0), 22, 17, c);
        oval(const Offset(11, 0), 22, 17, c);
        circle(Offset.zero, 5.5, darken(c, 0.08));
        canvas.restore();
      case ItemShape.headFlower:
        const center = Offset(132, 58);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          circle(center + Offset(math.cos(a) * 8.5, math.sin(a) * 8.5), 7.5, c);
        }
        circle(center, 5.5, const Color(0xFFFFE066));
      default:
        break;
    }
  }

  void glasses(WornItem w) {
    final c = w.color;
    final frame = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Bridge and arms
    canvas.drawPath(
      Path()
        ..moveTo(96, 98)
        ..quadraticBezierTo(100, 94, 104, 98),
      frame,
    );
    canvas.drawLine(const Offset(72, 97), const Offset(62, 93), frame);
    canvas.drawLine(const Offset(128, 97), const Offset(138, 93), frame);
    for (final e in [_eyeL, _eyeR]) {
      switch (w.item.shape) {
        case ItemShape.eyesHeart:
          fill(heartPath(e + const Offset(0, 1), 28), c.withValues(alpha: 0.8));
          canvas.drawCircle(
            e + const Offset(-5, -4),
            2.5,
            Paint()..color = const Color(0xAAFFFFFF),
          );
        case ItemShape.eyesStar:
          fill(starPath(e, 16, inner: 8.5), c.withValues(alpha: 0.8));
          canvas.drawCircle(
            e + const Offset(-4, -3),
            2.2,
            Paint()..color = const Color(0xAAFFFFFF),
          );
        default: // round glasses
          canvas.drawCircle(e, 12, Paint()..color = const Color(0x40FFFFFF));
          canvas.drawCircle(e, 12, frame);
      }
    }
  }

  void handItem(WornItem w) {
    final c = w.color;
    final pat = w.item.pattern;
    switch (w.item.shape) {
      case ItemShape.handWand:
        thickLine(
          _handL + const Offset(1, 8),
          const Offset(46, 194),
          3.5,
          const Color(0xFFFFFFFF),
        );
        fill(starPath(const Offset(45, 186), 15), c);
        canvas.drawCircle(
          const Offset(41, 182),
          3,
          Paint()..color = const Color(0xAAFFFFFF),
        );
        circle(_handL, 7.5, skinColor);
      case ItemShape.handBalloon:
        stroke(
          Path()
            ..moveTo(_handR.dx, _handR.dy)
            ..cubicTo(150, 210, 160, 180, 170, 140),
          const Color(0xFF9A8FA8),
          1.4,
        );
        fill(
          Path()
            ..moveTo(170, 136)
            ..lineTo(166, 142)
            ..lineTo(174, 142)
            ..close(),
          c,
          width: 1.2,
        );
        oval(const Offset(170, 110), 44, 54, c);
        oval(
          const Offset(160, 98),
          9,
          14,
          const Color(0x99FFFFFF),
          outline: false,
        );
        circle(_handR, 7.5, skinColor);
      default: // handbag
        stroke(
          Path()
            ..moveTo(131, 250)
            ..quadraticBezierTo(141, 222, 151, 250),
          outlineOf(c),
          3.5,
        );
        final bag = Path()
          ..addRRect(
            RRect.fromLTRBR(125, 246, 157, 274, const Radius.circular(7)),
          );
        garment(bag, c, pat);
        fill(
          Path()
            ..moveTo(125, 253)
            ..lineTo(157, 253)
            ..lineTo(141, 262)
            ..close(),
          darken(c, 0.08),
          width: 1.2,
        );
        circle(const Offset(141, 261), 2.5, const Color(0xFFFFE066));
        circle(_handR, 7.5, skinColor);
    }
  }
}
