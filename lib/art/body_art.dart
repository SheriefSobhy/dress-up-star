import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import '../models/doll_body.dart';
import '../painting/shapes.dart';
import 'art_library.dart';

// =============================================================================
//  Draws a doll's own skin and face (see DollBody). The SVG art is drawn as
//  the first doll; other choices swap colors and shapes inside it before it
//  is drawn. The first doll's art is left exactly as it is.
// =============================================================================

const String _dir = 'assets/svg/doll/';

/// The skin color the art is drawn with.
const Color _artSkin = Color(0xFFFFDCC8);

/// Every shade of skin used in the art.
const List<String> _skinShades = [
  'FFDCC8',
  'DE9F84',
  'FFF0E6',
  'FFE0CD',
  'F6C3A8',
  'E3A388',
  'E9AE93',
  'F6C4AA',
  'FFE6D6',
  'F3BDA2',
  'F4C0A5',
  'FFE3D2',
  'F2BBA0',
  'EDB397',
  'FFEDE2',
  'DC9A80',
];

/// [artColor] (a shade of the art's skin) as it looks on [body]'s skin.
Color skinTint(DollBody body, Color artColor) {
  if (body.skin == DollBody.classic.skin) return artColor;
  final tone = skinTones[body.skin];
  double tint(double c, double t, double art) => (c * t / art).clamp(0.0, 1.0);
  return Color.from(
    alpha: artColor.a,
    red: tint(artColor.r, tone.r, _artSkin.r),
    green: tint(artColor.g, tone.g, _artSkin.g),
    blue: tint(artColor.b, tone.b, _artSkin.b),
  );
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Swaps every `#RRGGBB` in [colors] (all at once, so swaps never chain).
String _swap(String svg, Map<String, String> colors) {
  if (colors.isEmpty) return svg;
  return svg.replaceAllMapped(
    RegExp('#(${colors.keys.join('|')})', caseSensitive: false),
    (m) => colors[m[1]!.toUpperCase()]!,
  );
}

Map<String, String> _skinColors(DollBody body) => {
  if (body.skin != DollBody.classic.skin)
    for (final shade in _skinShades)
      shade: _hex(
        skinTint(body, Color(0xFF000000 | int.parse(shade, radix: 16))),
      ),
};

// ------------------------------------------------------------------ head

const String _classicHead =
    'M100 52 C134 52 158 74 158 106 C158 138 134 159 100 159 '
    'C66 159 42 138 42 106 C42 74 66 52 100 52 Z';

/// The head outline of each face shape. The top half stays the same, so all
/// hair, hats and glasses fit every face.
const List<String> _headShapes = [
  _classicHead,
  // A pointed little chin.
  'M100 52 C134 52 158 74 158 106 C158 126 126 162 100 162 '
      'C74 162 42 126 42 106 C42 74 66 52 100 52 Z',
  // Round full cheeks.
  'M100 52 C134 52 157 74 157 104 C164 146 144 159 100 159 '
      'C56 159 36 146 43 104 C43 74 66 52 100 52 Z',
];

const List<Offset> _freckles = [
  Offset(60, 127),
  Offset(66, 125),
  Offset(70, 129),
  Offset(63, 131),
  Offset(94, 124),
  Offset(106, 124),
];

String _freckleMarkup(DollBody body) {
  final color = _hex(skinTint(body, const Color(0xFFBC7352)));
  return [
    for (final f in _freckles)
      for (final x in f.dx < 90 ? [f.dx, 200 - f.dx] : [f.dx])
        '<circle cx="$x" cy="${f.dy}" r="1.35" fill="$color" opacity="0.85"/>',
  ].join();
}

/// Her head, body or arm.
ArtLayer skinLayer(String name, DollBody body) {
  final asset = '$_dir$name.svg';
  final head = name == 'head';
  final variant = [
    if (body.skin != DollBody.classic.skin) 'skin${body.skin}',
    if (head && body.face != 0) 'face${body.face}',
    if (head && body.freckles) 'freckles',
  ].join('.');
  if (variant.isEmpty) return ArtLayer(asset);
  return ArtLayer(
    asset,
    variant: variant,
    edit: (svg) {
      var out = svg;
      if (head && body.face != 0) {
        out = out.replaceFirst(_classicHead, _headShapes[body.face]);
      }
      out = _swap(out, _skinColors(body));
      if (head && body.freckles) {
        out = out.replaceFirst('</svg>', '${_freckleMarkup(body)}</svg>');
      }
      return out;
    },
  );
}

/// Items drawn with a bit of her skin (the hand around a bag's handle, her
/// foot in a flat shoe) take her skin color too.
ArtLayer skinnedItem(ArtLayer item, DollBody body) {
  if (body.skin == DollBody.classic.skin) return item;
  if (item.slot != Slot.hand && item.slot != Slot.shoes) return item;
  return ArtLayer(
    item.asset,
    color: item.color,
    pattern: item.pattern,
    slot: item.slot,
    variant: 'skin${body.skin}',
    edit: (svg) => _swap(svg, _skinColors(body)),
  );
}

// ------------------------------------------------------------------ face

class _EyeShape {
  const _EyeShape(this.sx, this.sy, this.tilt);
  final double sx;
  final double sy;

  /// Degrees the outer corner is lifted.
  final double tilt;
}

const List<_EyeShape> _eyeShapes = [
  _EyeShape(1, 1, 0),
  // Almond.
  _EyeShape(1.06, 0.76, 9),
  // Big and round.
  _EyeShape(1.16, 1.0, -3),
];

/// Reshapes whatever is drawn next on [canvas] around the left eye (mirror
/// the canvas for the right one), so eyelashes sit on every eye shape.
void applyEyeShape(Canvas canvas, int shape, Offset center) {
  if (shape == 0) return;
  final s = _eyeShapes[shape];
  canvas.translate(center.dx, center.dy);
  canvas.rotate(s.tilt * 3.14159265 / 180);
  canvas.scale(s.sx, s.sy);
  canvas.translate(-center.dx, -center.dy);
}

String _eyeTransform(int shape, double x, double tilt) {
  final s = _eyeShapes[shape];
  return 'translate($x 115) rotate($tilt) scale(${s.sx} ${s.sy}) '
      'translate(${-x} -115)';
}

/// Her eyes, nose, mouth and cheeks.
ArtLayer faceArtLayer(String face, DollBody body) {
  final asset = '${_dir}face_$face.svg';
  final variant = [
    if (body.skin != DollBody.classic.skin) 'skin${body.skin}',
    if (body.eyeColor != 0) 'eyes${body.eyeColor}',
    if (body.eyeShape != 0) 'shape${body.eyeShape}',
    if (body.blush != 0) 'blush${body.blush}',
    if (body.lips != 0) 'lips${body.lips}',
  ].join('.');
  if (variant.isEmpty) return ArtLayer(asset);
  return ArtLayer(
    asset,
    variant: variant,
    edit: (svg) {
      var out = svg;
      if (body.eyeShape != 0) {
        final tilt = _eyeShapes[body.eyeShape].tilt;
        out = out
            .replaceFirst(
              '<g id="eyeL">',
              '<g transform="${_eyeTransform(body.eyeShape, 78, tilt)}">',
            )
            .replaceFirst(
              '<g id="eyeR">',
              '<g transform="${_eyeTransform(body.eyeShape, 122, -tilt)}">',
            );
      }
      final colors = <String, String>{..._skinColors(body)};
      if (body.eyeColor != 0) {
        final eye = eyeColors[body.eyeColor];
        colors.addAll({
          '2E1B36': _hex(eye.top),
          '5B3577': _hex(eye.middle),
          'A36BC9': _hex(eye.bottom),
          '22122A': _hex(eye.pupil),
        });
      }
      if (body.lips != 0) {
        final lip = lipColors[body.lips];
        colors.addAll({
          // The small smile.
          'E45E7E': _hex(lip),
          'C24764': _hex(darken(lip, 0.18)),
          'FF9DB3': _hex(lighten(lip, 0.35)),
          // The big happy mouth.
          'C9405F': _hex(darken(lip, 0.12)),
          'A8304D': _hex(lip),
        });
      }
      final cheek = cheekColors[body.blush];
      if (body.blush != 0 && cheek != null) {
        colors['FF8FAE'] = _hex(cheek);
        colors['FF7FA3'] = _hex(cheek);
      }
      out = _swap(out, colors);
      if (cheek == null) {
        out = out.replaceAll(
          RegExp('stop-opacity="0.(75|9)"'),
          'stop-opacity="0"',
        );
      }
      return out;
    },
  );
}

// ----------------------------------------------------------------- brows

/// Her eyebrows. Drawn over her fringe (the way cartoon eyebrows show
/// through the hair), so the choice can always be seen.
void paintBrows(Canvas canvas, DollBody body) {
  final left = Path();
  double width;
  switch (body.brows) {
    case 1: // Straight and thick.
      left
        ..moveTo(68, 92)
        ..quadraticBezierTo(77, 90.5, 87, 92);
      width = 3.6;
    case 2: // High round arch.
      left
        ..moveTo(69, 95)
        ..quadraticBezierTo(75, 82, 87, 89);
      width = 2;
    default:
      left
        ..moveTo(68, 93)
        ..quadraticBezierTo(77, 88.5, 86, 92);
      width = 2.2;
  }
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = skinTint(body, const Color(0xFF9A6656)).withValues(alpha: 0.75);
  canvas.drawPath(left, paint);
  canvas.save();
  canvas.translate(200, 0);
  canvas.scale(-1, 1);
  canvas.drawPath(left, paint);
  canvas.restore();
}

ArtLayer browsLayer(DollBody body) => ArtLayer.drawn(
  'brows|${body.brows}|${body.skin}',
  () async => recordPicture((c) => paintBrows(c, body)),
);
