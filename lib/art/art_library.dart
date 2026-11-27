import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/game_config.dart';

/// Turns the SVG art in `assets/svg/` into drawable pictures.
///
/// ## Recoloring
/// Item and background SVGs are drawn with five placeholder colors. They are
/// swapped for shades of the chosen color before the SVG is drawn:
///
/// | placeholder | becomes                       |
/// |-------------|-------------------------------|
/// | `#FF00FF`   | the chosen color              |
/// | `#FF66FF`   | a lighter shade (lit side)    |
/// | `#FFCCFF`   | a very light shine/highlight  |
/// | `#CC00CC`   | a darker shade (shadow side)  |
/// | `#990099`   | the soft outline color        |
///
/// ## Patterns
/// A garment SVG marks where its pattern goes with `<g id="pattern"/>` and
/// defines the fabric outline as `<clipPath id="fabric">`. The pattern is
/// drawn inside that outline (bending with the skirt's flare), and the
/// garment's own shading drawn after it shades the pattern too.
class ArtLibrary {
  ArtLibrary._();
  static final ArtLibrary instance = ArtLibrary._();

  Future<Set<String>>? _manifest;
  final Map<String, Future<String>> _text = {};
  final Map<String, Future<ui.Picture>> _pictures = {};

  /// All asset paths in the app (to find optional layers).
  Future<Set<String>> manifest() =>
      _manifest ??= AssetManifest.loadFromAssetBundle(
        rootBundle,
      ).then((m) => m.listAssets().toSet());

  Future<ui.Picture> picture(ArtLayer layer) {
    final draw = layer.draw;
    if (draw != null) {
      // Drawn by code from other (cached) pictures: cheap, so not cached.
      return draw().catchError((Object e) {
        debugPrint('Could not draw ${layer.asset}: $e');
        return _emptyPicture();
      });
    }
    return _pictures.putIfAbsent(layer.key, () async {
      try {
        final raw = await _text.putIfAbsent(
          layer.asset,
          () => rootBundle.loadString(layer.asset),
        );
        final svg = prepareSvg(
          layer.edit?.call(raw) ?? raw,
          color: layer.color,
          pattern: layer.pattern,
          slot: layer.slot,
        );
        final info = await vg.loadPicture(SvgStringLoader(svg), null);
        return info.picture;
      } catch (e) {
        debugPrint('Could not draw ${layer.asset}: $e');
        _pictures.remove(layer.key);
        return _emptyPicture();
      }
    });
  }
}

ui.Picture _emptyPicture() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder);
  return recorder.endRecording();
}

/// One SVG drawn with one color (and maybe a pattern), or a layer drawn by
/// code (makeup, salon hair, nail polish).
class ArtLayer {
  const ArtLayer(
    this.asset, {
    this.color,
    this.pattern = ItemPattern.none,
    this.slot,
    this.edit,
    this.variant = '',
  }) : draw = null;

  /// A layer drawn by [draw]. [name] must change whenever the drawing does.
  const ArtLayer.drawn(
    String name,
    Future<ui.Picture> Function() this.draw, {
    this.slot,
  }) : asset = 'drawn:$name',
       color = null,
       pattern = ItemPattern.none,
       edit = null,
       variant = '';

  final String asset;
  final Color? color;
  final ItemPattern pattern;
  final Slot? slot;
  final Future<ui.Picture> Function()? draw;

  /// Changes the SVG before it is drawn (skin and face choices). [variant]
  /// must name the change.
  final String Function(String svg)? edit;
  final String variant;

  String get key => '$asset|${color?.toARGB32()}|${pattern.name}|$variant';
}

/// Records a picture drawn by [paint].
ui.Picture recordPicture(void Function(Canvas canvas) paint) {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  return recorder.endRecording();
}

// ---------------------------------------------------------------- colors

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color _withLightness(Color c, double Function(double l) f, {double sat = 1}) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness(f(hsl.lightness).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * sat).clamp(0.0, 1.0))
      .toColor();
}

/// The five shades used to recolor art.
class Shades {
  Shades(this.base)
    : light = _withLightness(base, (l) => l + (1 - l) * 0.42),
      shine = _withLightness(base, (l) => l + (1 - l) * 0.8),
      shade = _withLightness(base, (l) => l * 0.85, sat: 1.05),
      deep = _withLightness(base, (l) => l * 0.6, sat: 0.9);

  final Color base;
  final Color light;
  final Color shine;
  final Color shade;
  final Color deep;

  /// A color that shows up nicely on the fabric (for patterns).
  Color get print => base.computeLuminance() > 0.5
      ? _withLightness(base, (l) => l * 0.7, sat: 1.1)
      : _withLightness(base, (l) => l + (1 - l) * 0.75);
}

String prepareSvg(
  String svg, {
  Color? color,
  ItemPattern pattern = ItemPattern.none,
  Slot? slot,
}) {
  var out = svg;
  if (color != null) {
    final s = Shades(color);
    final map = {
      '#FF00FF': _hex(s.base),
      '#FF66FF': _hex(s.light),
      '#FFCCFF': _hex(s.shine),
      '#CC00CC': _hex(s.shade),
      '#990099': _hex(s.deep),
    };
    out = out.replaceAllMapped(
      RegExp('#(FF00FF|FF66FF|FFCCFF|CC00CC|990099)', caseSensitive: false),
      (m) => map[m[0]!.toUpperCase()]!,
    );
  }
  final marker = RegExp(r'<g id="pattern"\s*/>');
  if (out.contains(marker)) {
    final markup = (pattern == ItemPattern.none || color == null)
        ? ''
        : patternMarkup(pattern, Shades(color).print, slot);
    out = out.replaceFirst(marker, markup);
  }
  return out;
}

// --------------------------------------------------------------- patterns

class _PatternArea {
  const _PatternArea(this.rect, {this.flareFrom, this.flare = 0, this.bow = 0});
  final Rect rect;

  /// Below this height the fabric flares out (skirts), spreading the pattern.
  final double? flareFrom;
  final double flare;

  /// How much pattern rows bend down in the middle (follows the hem).
  final double bow;
}

_PatternArea _areaFor(Slot? slot) {
  switch (slot) {
    case Slot.dress:
      return const _PatternArea(
        Rect.fromLTRB(26, 160, 174, 356),
        flareFrom: 218,
        flare: 1.0,
        bow: 9,
      );
    case Slot.skirt:
      return const _PatternArea(
        Rect.fromLTRB(36, 212, 164, 344),
        flareFrom: 218,
        flare: 1.0,
        bow: 8,
      );
    case Slot.top:
      return const _PatternArea(Rect.fromLTRB(60, 160, 140, 250), bow: 2);
    case Slot.hand:
      return const _PatternArea(Rect.fromLTRB(118, 236, 166, 300));
    case Slot.jacket:
      return const _PatternArea(Rect.fromLTRB(60, 160, 140, 280), bow: 2);
    case Slot.pants:
      return const _PatternArea(Rect.fromLTRB(66, 188, 134, 354));
    case Slot.socks:
      return const _PatternArea(Rect.fromLTRB(70, 232, 130, 366));
    default:
      return const _PatternArea(Rect.fromLTRB(0, 0, 200, 400));
  }
}

String _n(double v) => v.toStringAsFixed(1);

/// SVG markup for [pattern] that follows the garment's shape.
String patternMarkup(ItemPattern pattern, Color color, Slot? slot) {
  final area = _areaFor(slot);
  final r = area.rect;
  final cx = r.center.dx;
  final hex = _hex(color);

  // How far down the flaring part we are (0 at the waist, 1 at the hem).
  double flareT(double y) {
    final from = area.flareFrom;
    if (from == null || y <= from) return 0;
    return ((y - from) / (r.bottom - from)).clamp(0.0, 1.0);
  }

  Offset place(double x, double y) {
    final t = flareT(y);
    final spread = 1 + area.flare * t;
    final px = cx + (x - cx) * spread;
    final edge = ((px - cx) / (r.width / 2)).clamp(-1.0, 1.0);
    final py = y + area.bow * (1 - edge * edge) * (0.3 + t);
    return Offset(px, py);
  }

  final b = StringBuffer(
    '<g clip-path="url(#fabric)" fill="$hex" opacity="0.88">',
  );
  switch (pattern) {
    case ItemPattern.stripes:
      for (var y = r.top + 4; y < r.bottom + 10; y += 12) {
        final a = place(r.left - 40, y);
        final m = place(cx, y);
        final c = place(r.right + 40, y);
        final h = 4.6 * (1 + 0.4 * flareT(y));
        b.write(
          '<path d="M${_n(a.dx)} ${_n(a.dy)} Q${_n(m.dx)} ${_n(m.dy * 2 - (a.dy + c.dy) / 2)} '
          '${_n(c.dx)} ${_n(c.dy)} L${_n(c.dx)} ${_n(c.dy + h)} Q${_n(m.dx)} '
          '${_n(m.dy * 2 - (a.dy + c.dy) / 2 + h)} ${_n(a.dx)} ${_n(a.dy + h)} Z"/>',
        );
      }
    case ItemPattern.none:
      break;
    default:
      var row = 0;
      final step = pattern == ItemPattern.dots ? 11.0 : 15.0;
      for (var y = r.top + 4; y < r.bottom + step; y += step, row++) {
        for (
          var x = r.left - 30 + (row.isOdd ? step / 2 : 0);
          x < r.right + 30;
          x += step
        ) {
          final p = place(x, y);
          final grow = 1 + 0.35 * flareT(y);
          switch (pattern) {
            case ItemPattern.dots:
              b.write(
                '<circle cx="${_n(p.dx)}" cy="${_n(p.dy)}" r="${_n(2.7 * grow)}"/>',
              );
            case ItemPattern.stars:
              b.write('<path d="${_starD(p, 4.8 * grow)}"/>');
            case ItemPattern.hearts:
              b.write('<path d="${_heartD(p, 8.5 * grow)}"/>');
            default:
              break;
          }
        }
      }
  }
  b.write('</g>');
  return b.toString();
}

String _starD(Offset c, double outer) {
  final inner = outer * 0.45;
  final sb = StringBuffer();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? outer : inner;
    final a = -math.pi / 2 + i * math.pi / 5;
    sb.write(
      '${i == 0 ? 'M' : 'L'}${_n(c.dx + math.cos(a) * rr)} ${_n(c.dy + math.sin(a) * rr)} ',
    );
  }
  return '${sb}Z';
}

String _heartD(Offset c, double size) {
  final s = size / 2;
  final x = c.dx, y = c.dy;
  return 'M${_n(x)} ${_n(y + s * 0.9)} '
      'C${_n(x - s * 1.4)} ${_n(y - s * 0.1)} ${_n(x - s * 0.7)} ${_n(y - s * 1.2)} ${_n(x)} ${_n(y - s * 0.45)} '
      'C${_n(x + s * 0.7)} ${_n(y - s * 1.2)} ${_n(x + s * 1.4)} ${_n(y - s * 0.1)} ${_n(x)} ${_n(y + s * 0.9)} Z';
}
