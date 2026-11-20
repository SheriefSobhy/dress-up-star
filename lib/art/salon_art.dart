import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import '../models/beauty.dart';
import '../painting/shapes.dart';
import 'art_library.dart';
import 'beauty_art.dart' show cellsPath;

// =============================================================================
//  Salon hair: the long hair art, cut, curled, dyed and shiny.
//
//  Dye keeps the hair's own shading: the hair SVG is drawn again in the dye
//  color, but only inside the sprayed spots.
// =============================================================================

const String _front = 'assets/svg/items/hairLong.svg';
const String _back = 'assets/svg/items/hairLong_back.svg';

/// The color of hair spot [i] (dye, rainbow or the natural color).
Color hairSpotColor(int i, SalonHair s, Color base, {SpotGrid? wet}) {
  final d = s.dye[i];
  var c = base;
  if (d != null && d < hairDyeColors.length) {
    final tool = hairDyeColors[d];
    c = tool.rainbow ? rainbowAt(hairZone.spots[i].dy) : tool.color;
  }
  if (wet?[i] != null) c = wetColor(c);
  return c;
}

/// Rainbow bands from the top of the head down.
Color rainbowAt(double y) {
  final band = ((y - 40) / 26).floor().clamp(0, 1000) % rainbowColors.length;
  return rainbowColors[band];
}

/// Wet hair looks darker.
Color wetColor(Color c) => Color.lerp(c, const Color(0xFF243055), 0.32)!;

/// The two salon hair layers: behind her and in front.
List<ArtLayer> salonHairLayers(SalonHair s, Color base, {SpotGrid? wet}) {
  final key = '${s.key}|${base.toARGB32()}|${wet?.cells ?? ''}';
  return [
    ArtLayer.drawn(
      'salon_back|$key',
      () => _salonPicture(s, base, back: true, wet: wet),
      slot: Slot.hair,
    ),
    ArtLayer.drawn(
      'salon_front|$key',
      () => _salonPicture(s, base, back: false, wet: wet),
      slot: Slot.hair,
    ),
  ];
}

Future<ui.Picture> _salonPicture(
  SalonHair s,
  Color base, {
  required bool back,
  SpotGrid? wet,
}) async {
  // Group the spots by their color.
  final groups = <int, List<int>>{};
  for (var i = 0; i < hairZone.length; i++) {
    final c = hairSpotColor(i, s, base, wet: wet);
    if (c.toARGB32() == base.toARGB32()) continue;
    (groups[c.toARGB32()] ??= []).add(i);
  }
  final asset = back ? _back : _front;
  final colors = [base.toARGB32(), ...groups.keys];
  final pictures = await Future.wait([
    for (final c in colors)
      ArtLibrary.instance.picture(ArtLayer(asset, color: Color(c))),
  ]);
  return recordPicture((canvas) {
    canvas.saveLayer(const Rect.fromLTRB(-20, -20, 220, 420), Paint());
    for (var g = 0; g < colors.length; g++) {
      final color = Color(colors[g]);
      canvas.save();
      if (g > 0) {
        canvas.clipPath(cellsPath(hairZone, groups[colors[g]]!, size: 0.78));
      }
      _hairPass(canvas, s, color, pictures[g], back: back);
      canvas.restore();
    }
    _hemLines(canvas, s, base, back: back);
    if (!s.shine.isEmpty) _shine(canvas, s);
    canvas.restore();
  });
}

/// The hair in one color: cut to length, with curls if curled.
void _hairPass(
  Canvas canvas,
  SalonHair s,
  Color color,
  ui.Picture picture, {
  required bool back,
}) {
  final clip = _cutClip(s, back: back);
  canvas.save();
  if (clip != null) canvas.clipPath(clip);
  canvas.drawPicture(picture);
  canvas.restore();
  for (final side in const [0, 1]) {
    if (s.curl(side)) _ringlets(canvas, s, side, color, back: back);
  }
}

double _hem(SalonHair s, int side, {required bool back}) =>
    back ? s.backHem(side) : s.frontHem(side);

/// Cuts each side at its length, with a soft wavy edge. Null when the hair
/// is long and straight (the art's own ends are used).
Path? _cutClip(SalonHair s, {required bool back}) {
  if (s.cutLeft == 0 && s.cutRight == 0 && !s.curlLeft && !s.curlRight) {
    return null;
  }
  final path = Path();
  for (final side in const [0, 1]) {
    final left = side == 0 ? -20.0 : 100.0;
    final right = side == 0 ? 100.0 : 220.0;
    final long = s.cut(side) == 0 && !s.curl(side);
    final hem = long ? 420.0 : _hem(s, side, back: back);
    path.moveTo(left, -20);
    path.lineTo(right, -20);
    path.lineTo(right, hem);
    // Little rounded tufts along the hem.
    const step = 10.0;
    for (var x = right; x > left; x -= step) {
      path.quadraticBezierTo(x - step / 2, hem + (long ? 0 : 5), x - step, hem);
    }
    path.close();
  }
  return path;
}

/// A darker line along a fresh cut, so the ends look neat.
void _hemLines(Canvas canvas, SalonHair s, Color base, {required bool back}) {
  final deep = Shades(base).deep;
  for (final side in const [0, 1]) {
    if (s.cut(side) == 0 || s.curl(side)) continue;
    final hem = _hem(s, side, back: back);
    final left = side == 0 ? 20.0 : 100.0;
    final right = side == 0 ? 100.0 : 180.0;
    final path = Path()..moveTo(right, hem);
    const step = 10.0;
    for (var x = right; x > left; x -= step) {
      path.quadraticBezierTo(x - step / 2, hem + 5, x - step, hem);
    }
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = deep.withValues(alpha: 0.85),
    );
  }
}

/// Bouncy ringlet curls along the hem of [side].
void _ringlets(
  Canvas canvas,
  SalonHair s,
  int side,
  Color color, {
  required bool back,
}) {
  final shades = Shades(color);
  final hem = _hem(s, side, back: back);
  final xs = back ? const <double>[38, 50, 62, 74, 86] : const <double>[37, 48];
  final r = back ? 7.0 : 6.5;
  for (var i = 0; i < xs.length; i++) {
    final x = side == 0 ? xs[i] : 200 - xs[i];
    final c = Offset(x, hem - 1 + (i.isOdd ? 2.5 : 0));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c - Offset(r * 0.35, r * 0.4),
          r * 1.3,
          [shades.light, shades.base, shades.shade],
          const [0, 0.55, 1],
        ),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = shades.deep,
    );
    // The spiral of the curl.
    final spiral = Path();
    for (var k = 0; k <= 16; k++) {
      final a = k / 16 * math.pi * 2.6 + (side == 0 ? 0 : math.pi);
      final rr = r * (0.75 - k / 16 * 0.55);
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? spiral.moveTo(p.dx, p.dy) : spiral.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      spiral,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = shades.deep.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      c - Offset(r * 0.38, r * 0.42),
      r * 0.2,
      Paint()..color = shades.shine.withValues(alpha: 0.9),
    );
  }
}

/// Glossy streaks and twinkles where the hair was washed and dried.
void _shine(Canvas canvas, SalonHair s) {
  final cells = [
    for (var i = 0; i < hairZone.length; i++)
      if (s.shine[i] != null) i,
  ];
  canvas.save();
  canvas.clipPath(cellsPath(hairZone, cells, size: 0.9));
  // The shiny ring around the top of the head.
  canvas.drawPath(
    Path()..addArc(
      Rect.fromCenter(center: const Offset(100, 92), width: 112, height: 84),
      math.pi * 1.08,
      math.pi * 0.84,
    ),
    Paint()
      ..blendMode = BlendMode.srcATop
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x8CFFFFFF),
  );
  // Soft streaks down the long hair.
  final streak = Paint()
    ..blendMode = BlendMode.srcATop
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x66FFFFFF);
  for (final x in const [40.0, 160.0, 64.0, 136.0]) {
    final top = x < 50 || x > 150 ? 112.0 : 168.0;
    canvas.drawLine(
      Offset(x, top),
      Offset(x + (x < 100 ? 3 : -3), 270),
      streak,
    );
  }
  canvas.restore();
  // Twinkles.
  final star = Paint()
    ..blendMode = BlendMode.srcATop
    ..color = const Color(0xF2FFFFFF);
  for (final i in cells) {
    if (i % 4 != 0) continue;
    canvas.drawPath(
      starPath(
        hairZone.spots[i] + const Offset(2, -2),
        2.6,
        points: 4,
        inner: 0.8,
      ),
      star,
    );
  }
}

/// Soap foam on the hair (only while washing, never saved).
void paintBubbles(Canvas canvas, SpotGrid bubbles) {
  final fill = Paint()..color = const Color(0xE6FFFFFF);
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..color = const Color(0xFFA9D8FF);
  final shine = Paint()..color = const Color(0xFFFFFFFF);
  for (var i = 0; i < hairZone.length; i++) {
    if (bubbles[i] == null) continue;
    final rnd = math.Random(i);
    final p = hairZone.spots[i];
    for (var k = 0; k < 3; k++) {
      final c =
          p +
          Offset((rnd.nextDouble() - 0.5) * 10, (rnd.nextDouble() - 0.5) * 10);
      final r = 3 + rnd.nextDouble() * 3.5;
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, rim);
      canvas.drawCircle(c - Offset(r * 0.35, r * 0.35), r * 0.25, shine);
    }
  }
}

/// Little water drops on wet hair (only while washing).
void paintWetDrops(Canvas canvas, SpotGrid wet) {
  final drop = Paint()..color = const Color(0xCC8FD3FF);
  final shine = Paint()..color = const Color(0xFFFFFFFF);
  for (var i = 0; i < hairZone.length; i++) {
    if (wet[i] == null || i % 2 == 1) continue;
    final rnd = math.Random(i * 7);
    final p =
        hairZone.spots[i] +
        Offset((rnd.nextDouble() - 0.5) * 8, (rnd.nextDouble() - 0.5) * 8);
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - 3.2)
        ..quadraticBezierTo(p.dx + 2.2, p.dy + 0.4, p.dx, p.dy + 1.8)
        ..quadraticBezierTo(p.dx - 2.2, p.dy + 0.4, p.dx, p.dy - 3.2),
      drop,
    );
    canvas.drawCircle(p + const Offset(-0.6, -0.2), 0.55, shine);
  }
}
