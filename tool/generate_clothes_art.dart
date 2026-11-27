// Writes the SVG art for the second wardrobe: jackets, pants, hats,
// costumes, pajamas, sportswear, socks and a few more dresses, tops, skirts
// and shoes.
//
//   dart run tool/generate_clothes_art.dart
//
// The pictures are drawn on the 200 x 400 doll space with the recolor
// placeholder colors (see lib/art/art_library.dart). A garment's fabric gets
// the pattern spot and the same soft shading as the older clothes.
// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:io';
import 'dart:math' as math;

const String itemDir = 'assets/svg/items';

// Recolor placeholders.
const String base = '#FF00FF';
const String light = '#FF66FF';
const String shine = '#FFCCFF';
const String shade = '#CC00CC';
const String deep = '#990099';

const String white = '#FFFFFF';
const String cream = '#FFF7EC';
const String gold = '#FFD84D';
const String goldLine = '#C48A12';
const String pink = '#FF8FC7';
const String leaf = '#6FCF6A';
const String leafLine = '#3F9B4B';

const String defs =
    '<defs><linearGradient id="shade" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="$deep" stop-opacity="0.38"/>'
    '<stop offset="0.28" stop-color="$deep" stop-opacity="0.04"/>'
    '<stop offset="0.5" stop-color="$white" stop-opacity="0.2"/>'
    '<stop offset="0.72" stop-color="$deep" stop-opacity="0.04"/>'
    '<stop offset="1" stop-color="$deep" stop-opacity="0.38"/></linearGradient>'
    '<linearGradient id="down" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="$deep" stop-opacity="0.18"/>'
    '<stop offset="0.35" stop-color="$deep" stop-opacity="0"/>'
    '<stop offset="1" stop-color="$deep" stop-opacity="0.22"/></linearGradient>'
    '<radialGradient id="puff" cx="0.4" cy="0.35" r="0.7">'
    '<stop offset="0" stop-color="$shine"/><stop offset="0.45" stop-color="$light"/>'
    '<stop offset="1" stop-color="$shade"/></radialGradient>'
    '<linearGradient id="metal" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="$shine"/><stop offset="0.45" stop-color="$base"/>'
    '<stop offset="1" stop-color="$shade"/></linearGradient>'
    '<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="#FFF3B0"/><stop offset="0.5" stop-color="$gold"/>'
    '<stop offset="1" stop-color="#E0A81E"/></linearGradient></defs>';

void write(String name, String body) {
  File('$itemDir/$name.svg').writeAsStringSync(
    '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="400" '
    'viewBox="0 0 200 400">$defs$body</svg>\n',
  );
}

String n(num v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

const String _edge =
    'stroke="$deep" stroke-width="1.8" stroke-linejoin="round"';

/// A filled shape with the soft outline.
String shape(String d, {String fill = base, String extra = ''}) =>
    '<path d="$d" fill="$fill" $_edge$extra/>';

String path(String d, String fill, {String extra = ''}) =>
    '<path d="$d" fill="$fill"$extra/>';

String line(String d, String color, [double width = 1.4, double opacity = 1]) =>
    '<path d="$d" fill="none" stroke="$color" stroke-width="${n(width)}" '
    'stroke-linecap="round" stroke-linejoin="round" opacity="$opacity"/>';

String circle(
  num x,
  num y,
  num r,
  String fill, {
  String? stroke,
  double width = 1,
}) =>
    '<circle cx="${n(x)}" cy="${n(y)}" r="${n(r)}" fill="$fill"'
    '${stroke == null ? '' : ' stroke="$stroke" stroke-width="${n(width)}"'}/>';

String ellipse(
  num x,
  num y,
  num rx,
  num ry,
  String fill, {
  String? stroke = deep,
  String extra = '',
}) =>
    '<ellipse cx="${n(x)}" cy="${n(y)}" rx="${n(rx)}" ry="${n(ry)}" fill="$fill"'
    '${stroke == null ? '' : ' stroke="$stroke" stroke-width="1.8"'}$extra/>';

/// The fabric of a garment: color, the pattern spot, then shading over both.
/// [under] is drawn before it, [over] (kept inside the fabric) after the
/// shading and before the outline.
String fabric(List<String> ds, {String inside = '', String fill = base}) {
  final b = StringBuffer('<clipPath id="fabric">');
  for (final d in ds) {
    b.write('<path d="$d"/>');
  }
  b.write('</clipPath>');
  for (final d in ds) {
    b.write(path(d, fill));
  }
  b.write('<g id="pattern"/>');
  for (final d in ds) {
    b.write(path(d, 'url(#shade)'));
    b.write(path(d, 'url(#down)'));
  }
  if (inside.isNotEmpty) b.write('<g clip-path="url(#fabric)">$inside</g>');
  for (final d in ds) {
    b.write('<path d="$d" fill="none" $_edge/>');
  }
  return b.toString();
}

/// The same drawing again on the other side of her.
String both(String body) =>
    '$body<g transform="translate(200 0) scale(-1 1)">$body</g>';

String star(num x, num y, num r, String fill, {String? stroke}) {
  final sb = StringBuffer();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * 0.45;
    final a = -math.pi / 2 + i * math.pi / 5;
    sb.write(
      '${i == 0 ? 'M' : 'L'}${n(x + math.cos(a) * rr)} ${n(y + math.sin(a) * rr)} ',
    );
  }
  return '<path d="${sb}Z" fill="$fill"'
      '${stroke == null ? '' : ' stroke="$stroke" stroke-width="1" stroke-linejoin="round"'}/>';
}

String heart(num x, num y, num size, String fill, {String? stroke}) {
  final s = size / 2;
  return '<path d="M${n(x)} ${n(y + s * 0.9)} '
      'C${n(x - s * 1.4)} ${n(y - s * 0.1)} ${n(x - s * 0.7)} ${n(y - s * 1.2)} ${n(x)} ${n(y - s * 0.45)} '
      'C${n(x + s * 0.7)} ${n(y - s * 1.2)} ${n(x + s * 1.4)} ${n(y - s * 0.1)} ${n(x)} ${n(y + s * 0.9)} Z" '
      'fill="$fill"'
      '${stroke == null ? '' : ' stroke="$stroke" stroke-width="1"'}/>';
}

String glint(num x, num y, [num r = 3.4]) =>
    '<path d="M${n(x)} ${n(y - r)} L${n(x + r * .28)} ${n(y - r * .28)} '
    'L${n(x + r)} ${n(y)} L${n(x + r * .28)} ${n(y + r * .28)} L${n(x)} ${n(y + r)} '
    'L${n(x - r * .28)} ${n(y + r * .28)} L${n(x - r)} ${n(y)} '
    'L${n(x - r * .28)} ${n(y - r * .28)} Z" fill="$white" opacity="0.95"/>';

String flower(num x, num y, num r, String petal, String edge) {
  final b = StringBuffer();
  for (var i = 0; i < 5; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / 5;
    b.write(
      circle(
        x + math.cos(a) * r,
        y + math.sin(a) * r,
        r * 0.78,
        petal,
        stroke: edge,
      ),
    );
  }
  b.write(circle(x, y, r * 0.62, gold));
  return b.toString();
}

String cloud(num x, num y, num s, {String fill = white}) =>
    '<g fill="$fill">'
    '${circle(x - 4 * s, y + 1 * s, 3.4 * s, fill)}'
    '${circle(x, y - 1.4 * s, 4.4 * s, fill)}'
    '${circle(x + 4.4 * s, y + 0.8 * s, 3.4 * s, fill)}'
    '<rect x="${n(x - 5 * s)}" y="${n(y + 0.6 * s)}" width="${n(10 * s)}" '
    'height="${n(3.8 * s)}" rx="${n(1.8 * s)}"/></g>';

String bow(num x, num y, double s, {String fill = shine}) =>
    '<g transform="translate(${n(x)} ${n(y)}) scale($s)">'
    '${shape('M0 0 L-6 12 L-1 10 Z M0 0 L6 12 L1 10 Z', fill: fill)}'
    '${shape('M0 0 C-6 -10 -18 -8 -16 0 C-18 8 -6 10 0 0 Z M0 0 C6 -10 18 -8 16 0 C18 8 6 10 0 0 Z', fill: fill)}'
    '${shape('M-4 0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0 Z', fill: fill)}</g>';

String buttons(num x, List<num> ys, {String fill = white, num r = 2.3}) =>
    [for (final y in ys) circle(x, y, r, fill, stroke: deep)].join();

// ---------------------------------------------------------------- sleeves

/// Long sleeves (a `_front` layer: they move with her arms). [wide] puffs
/// them out; [cuff] is the color of the wrist band.
String longSleeves({
  String fill = 'url(#puff)',
  String cuff = shade,
  String extra = '',
  bool wide = false,
}) {
  final sleeve = wide
      ? 'M73 169 Q83 164 91 176 L79 240 Q68 247 55 239 L61 192 Q61 174 73 169 Z'
      : 'M72 170 Q81 164 90 175 L78 240 Q67 245 58 239 L65 188 Q65 175 72 170 Z';
  final band = wide
      ? 'M54 237 Q66 245 80 238 L78 247 Q67 252 54 246 Z'
      : 'M57 237 Q67 244 79 238 L77 247 Q67 251 56 245 Z';
  return both(
    shape(sleeve, fill: fill) +
        extra +
        shape(band, fill: cuff) +
        line('M76 184 Q72 208 68 230', white, 2.4, 0.45),
  );
}

/// Short sleeves down to about her elbow.
String shortSleeves({String fill = 'url(#puff)', String trim = white}) => both(
  shape('M70 172 Q79 165 89 174 L84 201 Q75 206 65 199 Z', fill: fill) +
      line('M66 196 Q75 202 84 198', trim, 2.4),
);

/// Round puffed sleeves.
String puffSleeves({String fill = 'url(#puff)'}) => both(
  shape(
        'M66 182 Q64 170 76 168 Q86 167 89 176 Q88 190 78 193 Q66 193 66 182 Z',
        fill: fill,
      ) +
      line('M69 190 Q78 195 87 188', white, 2) +
      line('M72 176 Q77 172 82 174', white, 1.8, 0.7),
);

// ---------------------------------------------------------------- pieces

const String bodice =
    'M86 168 Q100 178 114 168 Q126 169 127 181 L123 221 L77 221 L73 181 Q74 169 86 168 Z';

const String torso =
    'M86 168 Q100 179 114 168 Q126 169 127 181 L123 242 Q100 248 77 242 L73 181 Q74 169 86 168 Z';

/// Trousers from her waist to the ankles.
const String trousers =
    'M79 214 L121 214 Q126 234 124 254 L120.5 346 L101.5 346 L100 264 L98.5 346 L79.5 346 L76 254 Q74 234 79 214 Z';

String collar(String fill) =>
    both(shape('M86 167 L100 176 L93 186 Q85 180 83 170 Z', fill: fill));

// ---------------------------------------------------------------- jackets

void jackets() {
  // One half of an open jacket (the other half is mirrored).
  String open(num hem, {num neck = 96, num flare = 0}) =>
      'M87 167 Q73 168 72 181 L${n(75 - flare)} ${n(hem)} Q${n(85 - flare / 2)} ${n(hem + 3)} $neck ${n(hem + 1)} L$neck 194 Q89 182 87 167 Z';
  String openR(num hem, {num neck = 96, num flare = 0}) =>
      'M113 167 Q127 168 128 181 L${n(125 + flare)} ${n(hem)} Q${n(115 + flare / 2)} ${n(hem + 3)} ${n(200 - neck)} ${n(hem + 1)} L${n(200 - neck)} 194 Q111 182 113 167 Z';
  String panels(num hem, {num neck = 96, num flare = 0, String inside = ''}) =>
      fabric([
        open(hem, neck: neck, flare: flare),
        openR(hem, neck: neck, flare: flare),
      ], inside: inside);

  // Denim: stitched pockets and copper buttons.
  write(
    'jacketDenim',
    panels(244, neck: 95) +
        both(
          line('M76 197 L92 197 L92 211 Q84 215 76 211 Z', '#FFD9A0', 1.2) +
              line('M76 202 L92 202', '#FFD9A0', 1.2) +
              line('M76 233 L94 234', '#FFD9A0', 1.4) +
              line('M92 192 L92 242', '#FFD9A0', 1.1) +
              circle(84, 202, 1.8, '#E8A35C', stroke: '#9A5E28') +
              shape('M87 167 L96 182 L89 189 Q80 180 80 170 Z', fill: light),
        ),
  );
  write(
    'jacketDenim_front',
    longSleeves(extra: line('M72 190 L65 236', '#FFD9A0', 1.1)),
  );

  // Puffer: quilted rows and a zip.
  final quilt = [
    for (final y in [190, 207, 224])
      line('M70 $y Q85 ${y + 7} 100 $y Q115 ${y + 7} 130 $y', deep, 1.6, 0.65) +
          line('M74 ${y - 5} Q85 ${y - 1} 95 ${y - 5}', white, 2.4, 0.5) +
          line('M105 ${y - 5} Q115 ${y - 1} 126 ${y - 5}', white, 2.4, 0.5),
  ].join();
  const puffer =
      'M86 167 Q71 168 70 182 Q67 215 72 243 Q100 250 128 243 Q133 215 130 182 Q129 168 114 167 Q100 176 86 167 Z';
  write(
    'jacketPuffer',
    fabric([puffer], inside: quilt) +
        line('M100 176 L100 245', white, 2.6) +
        circle(100, 184, 2.6, gold, stroke: goldLine) +
        shape(
          'M85 163 Q100 172 115 163 L117 174 Q100 184 83 174 Z',
          fill: 'url(#puff)',
        ),
  );
  write(
    'jacketPuffer_front',
    longSleeves(
      wide: true,
      extra:
          line('M63 194 Q74 200 87 193', deep, 1.6, 0.65) +
          line('M60 214 Q71 220 83 213', deep, 1.6, 0.65),
    ),
  );

  // Raincoat: longer, with toggles, big pockets and a collar.
  const rain =
      'M86 167 Q73 168 72 182 L64 272 Q100 282 136 272 L128 182 Q127 168 114 167 Q100 177 86 167 Z';
  write(
    'jacketRain',
    fabric([rain]) +
        line('M100 178 L100 276', deep, 1.4, 0.6) +
        both(
          shape('M72 242 L91 242 L90 259 Q81 262 71 258 Z', fill: light) +
              line('M71 246 L92 246', deep, 1.2, 0.6) +
              shape('M86 164 L100 175 L92 190 Q80 184 80 170 Z', fill: light) +
              line('M76 190 Q73 226 70 262', white, 2.8, 0.7),
        ) +
        [
          for (final y in [200, 218, 236])
            line('M93 $y L107 $y', '#7A4A2A', 3) +
                circle(94, y, 2.4, '#B5763F', stroke: '#7A4A2A') +
                circle(106, y, 2.4, '#B5763F', stroke: '#7A4A2A'),
        ].join(),
  );
  write('jacketRain_front', longSleeves(fill: base, cuff: light));

  // Cardigan: soft V neck, ribbed hem and big buttons.
  write(
    'jacketCardigan',
    panels(247, neck: 98) +
        both(
          line('M87 168 Q89 184 98 196 L98 246', light, 4.4) +
              line('M75 240 Q86 244 97 242', shade, 7, 0.9) +
              line(
                'M78 237 L78 246 M83 238 L83 247 M88 238 L88 247 M93 238 L93 247',
                deep,
                1,
                0.5,
              ) +
              shape('M77 218 L90 218 L89 231 Q83 233 78 231 Z', fill: light) +
              heart(83.5, 224, 6, white),
        ) +
        buttons(98, [206, 220, 232], fill: gold, r: 2.6),
  );
  write('jacketCardigan_front', longSleeves());

  // Blazer: lapels, a gold button and a pocket flower.
  write(
    'jacketBlazer',
    panels(249, neck: 99) +
        both(
          shape(
                'M87 167 L99 212 L92 214 L80 192 L86 189 L79 180 Z',
                fill: light,
              ) +
              line('M77 230 L91 231', deep, 1.6, 0.8),
        ) +
        circle(99, 220, 3.2, 'url(#gold)', stroke: goldLine) +
        flower(118, 200, 3, white, '#D9A0BE'),
  );
  write('jacketBlazer_front', longSleeves(cuff: base));

  // Hoodie: hood around her neck, drawstrings and a kangaroo pocket.
  write(
    'jacketHoodie',
    fabric([
          'M86 168 Q100 178 114 168 Q127 169 128 182 L125 243 L75 243 L72 182 Q73 169 86 168 Z',
        ]) +
        shape('M80 214 L120 214 L126 236 L74 236 Z', fill: light) +
        line('M82 218 Q80 228 77 233 M118 218 Q120 228 123 233', deep, 1.4) +
        shape('M75 241 L125 241 L124 251 Q100 255 76 251 Z', fill: shade) +
        shape(
          'M82 162 Q72 170 78 180 Q88 192 100 190 Q112 192 122 180 Q128 170 118 162 Q112 178 100 178 Q88 178 82 162 Z',
          fill: 'url(#puff)',
        ) +
        line('M94 189 Q92 200 93 210 M106 189 Q108 200 107 210', white, 2.2) +
        circle(93, 211, 2.4, white, stroke: deep) +
        circle(107, 211, 2.4, white, stroke: deep),
  );
  write('jacketHoodie_front', longSleeves());
}

// ---------------------------------------------------------------- pants

void pants() {
  const stitch = '#FFD9A0';
  String belt(String fill) =>
      shape('M79 211 L121 211 L122 221 L78 221 Z', fill: fill);

  write(
    'pantsJeans',
    fabric([trousers]) +
        line('M100 221 L100 262', stitch, 1.2) +
        both(
          line('M81 224 Q86 238 97 232', stitch, 1.2) +
              line('M79.5 338 L98.5 338', stitch, 1.4) +
              line('M89 268 L88 334', light, 3.4, 0.6),
        ) +
        belt(shade) +
        circle(100, 216, 2.6, gold, stroke: goldLine) +
        heart(113, 232, 7, pink, stroke: '#C9579A'),
  );
  const leggings =
      'M80 216 L120 216 Q125 236 123 254 L117.5 347 L101.8 347 L100 264 L98.2 347 L82.5 347 L77 254 Q75 236 80 216 Z';
  write(
    'pantsLeggings',
    fabric([leggings]) +
        both(line('M86 250 Q88 296 89 338', white, 3, 0.45)) +
        shape('M80 213 L120 213 L121 220 L79 220 Z', fill: shade),
  );
  write(
    'pantsShorts',
    fabric([
          'M79 214 L121 214 Q126 240 128 276 L101.5 279 L100 260 L98.5 279 L72 276 Q74 240 79 214 Z',
        ]) +
        both(
          shape('M72 270 L98.5 273 L98.5 281 L72 278 Z', fill: light) +
              line('M81 224 Q86 236 96 232', deep, 1.3, 0.7),
        ) +
        belt(shade) +
        bow(100, 217, 0.55),
  );
  // Overalls: trousers plus a bib and straps (drawn over her top).
  write(
    'pantsOveralls',
    fabric([trousers, 'M85 186 L115 186 L117 216 L83 216 Z']) +
        both(
          shape('M85 187 L79 170 L86 168 L92 186 Z') +
              circle(87.5, 190, 3, 'url(#gold)', stroke: goldLine) +
              shape('M79.5 336 L99 336 L98.6 346 L79.7 346 Z', fill: light),
        ) +
        shape('M90 196 L110 196 L109 210 Q100 214 91 210 Z', fill: light) +
        heart(100, 203, 8, pink, stroke: '#C9579A') +
        line('M79 216 L121 216', deep, 1.6, 0.8) +
        line('M100 222 L100 262', deep, 1.2, 0.6),
  );
  write(
    'pantsFlared',
    fabric([
          'M79 214 L121 214 Q127 240 119 292 L132 350 Q118 355 102 350 L100 264 L98 350 Q82 355 68 350 L81 292 Q73 240 79 214 Z',
        ]) +
        both(
          line('M70 344 Q83 349 97 344', light, 3) +
              line('M88 268 L84 342', white, 2.6, 0.45) +
              flower(80, 336, 2.8, white, '#D9A0BE'),
        ) +
        belt(light) +
        circle(100, 216, 3, 'url(#gold)', stroke: goldLine),
  );
}

// ---------------------------------------------------------------- socks

void socks() {
  String sockD(num top, {bool right = false}) {
    String x(num v) => n(right ? 200 - v : v);
    return 'M${x(83.4)} ${n(top)} L${x(98.4)} ${n(top)} L${x(98.2)} 355 '
        'Q${x(96)} 365 ${x(86)} 365 Q${x(73.5)} 365 ${x(73.8)} 358 '
        'Q${x(74.5)} 351 ${x(83.4)} 350 Z';
  }

  List<String> pair(num top) => [sockD(top), sockD(top, right: true)];
  String cuffs(num top, String fill) => both(
    shape(
      'M82.6 ${n(top - 3)} L99 ${n(top - 3)} L99 ${n(top + 4)} L82.6 ${n(top + 4)} Z',
      fill: fill,
    ),
  );
  String bands(num from, num to, num step, String color) => [
    for (var y = from; y < to; y += step)
      '<rect x="68" y="${n(y)}" width="64" height="${n(step / 2)}" fill="$color"/>',
  ].join();

  write(
    'socksStriped',
    fabric(pair(318), inside: bands(324, 366, 10, white)) + cuffs(318, light),
  );

  final frill = [
    for (var i = 0; i < 5; i++)
      circle(83 + i * 4, 336, 3.4, white, stroke: '#D9A0BE'),
  ].join();
  write(
    'socksFrilly',
    fabric(pair(336)) + both(frill + bow(91, 340, 0.42, fill: pink)),
  );

  const tights =
      'M77.5 232 L122.5 232 Q124.5 248 118 262 L116.5 300 L116.3 355 '
      'Q126 351 126.2 358 Q126.5 365 114 365 Q104 365 101.8 355 L101.6 300 '
      'L100 262 L98.4 300 L98.2 355 Q96 365 86 365 Q73.5 365 73.8 358 '
      'Q74 351 83.7 355 L83.5 300 L82 262 Q75.5 248 77.5 232 Z';
  const rainbow = [
    '#FF6B7A',
    '#FFA45C',
    '#FFE066',
    '#8EE08A',
    '#7CB8FF',
    '#B79CFF',
  ];
  write(
    'socksRainbow',
    fabric(
          [tights],
          inside: [
            for (var i = 0; i < 12; i++)
              '<rect x="68" y="${n(262 + i * 9)}" width="64" height="9" '
                  'fill="${rainbow[i % 6]}"/>',
          ].join(),
        ) +
        shape('M77 230 L123 230 L123 237 L77 237 Z', fill: light),
  );

  write(
    'socksKnee',
    fabric(pair(298)) +
        cuffs(298, white) +
        both(
          heart(91, 312, 9, white, stroke: deep) +
              line('M86 322 L87 348', white, 2.4, 0.5),
        ),
  );

  write(
    'socksGlitter',
    fabric(
          [tights],
          inside: [
            for (var i = 0; i < 90; i++)
              circle(
                72 + (i * 37) % 57,
                236 + (i * 53) % 128,
                0.7 + (i % 3) * 0.35,
                i % 4 == 0 ? shine : white,
              ),
          ].join(),
        ) +
        shape('M77 230 L123 230 L123 237 L77 237 Z', fill: 'url(#gold)') +
        both(glint(90, 292, 4) + glint(86, 334, 3)),
  );
}

// ---------------------------------------------------------------- hats

void hats() {
  // Sun hat: a wide brim, a ribbon and a flower.
  write(
    'hatSun',
    ellipse(100, 62, 80, 17, 'url(#metal)') +
        line('M32 64 Q100 88 168 64', white, 1.6, 0.6) +
        shape('M61 62 C58 12 142 12 139 62 Q100 74 61 62 Z', fill: base) +
        shape('M63 48 Q100 58 137 48 L139 61 Q100 73 61 61 Z', fill: white) +
        flower(128, 55, 6, pink, '#C9579A') +
        line('M74 34 Q82 22 96 20', white, 2.6, 0.65),
  );

  // Beanie: knitted, with a fold and a pom-pom.
  write(
    'hatBeanie',
    shape('M43 78 C36 14 164 14 157 78 Q100 56 43 78 Z', fill: 'url(#metal)') +
        line(
          'M62 60 Q64 40 82 30 M82 56 Q84 38 94 28 M118 56 Q116 38 106 28 M138 60 Q136 40 118 30 M100 54 L100 28',
          shade,
          1.6,
          0.8,
        ) +
        shape('M42 68 Q100 44 158 68 L159 84 Q100 60 41 84 Z', fill: light) +
        line(
          [
            for (var x = 50; x <= 150; x += 9)
              'M$x ${n(66 - 12 * (1 - math.pow((x - 100) / 58, 2)))} l0 12',
          ].join(' '),
          deep,
          1,
          0.45,
        ) +
        circle(100, 21, 13, 'url(#puff)', stroke: deep, width: 1.8) +
        line(
          'M93 15 l3 4 M104 13 l-1 5 M108 22 l-5 1 M96 28 l2 -5',
          white,
          1.4,
          0.7,
        ),
  );

  // Cap: a dome, a visor and a star.
  write(
    'hatCap',
    shape('M49 72 C46 18 154 18 151 72 Q100 54 49 72 Z', fill: 'url(#metal)') +
        line(
          'M100 31 L100 60 M74 38 Q68 50 68 64 M126 38 Q132 50 132 64',
          shade,
          1.4,
        ) +
        shape(
          'M56 68 Q100 50 144 68 Q150 82 130 84 Q100 70 70 84 Q50 82 56 68 Z',
          fill: shade,
        ) +
        line('M64 70 Q100 56 136 70', shine, 2) +
        circle(100, 30, 4.5, light, stroke: deep) +
        star(100, 49, 9, white, stroke: deep),
  );

  // Beret: soft and tilted.
  write(
    'hatBeret',
    shape(
          'M46 66 C20 44 50 16 94 18 C140 16 168 34 156 56 C150 66 134 62 128 60 Q90 52 54 72 Q49 72 46 66 Z',
          fill: 'url(#puff)',
        ) +
        line('M52 68 Q94 46 140 60', deep, 6) +
        line('M52 68 Q94 46 140 60', shade, 3.6) +
        line('M98 19 Q100 8 108 10', deep, 3.6) +
        line('M60 36 Q76 24 98 25', white, 2.6, 0.6) +
        heart(130, 42, 10, white, stroke: deep),
  );

  // Witch hat: a bent point, a band and a gold buckle.
  write(
    'hatWitch',
    ellipse(100, 66, 76, 14, shade) +
        shape(
          'M62 66 Q82 44 92 14 Q98 2 134 12 Q114 15 117 26 Q126 48 140 66 Q100 76 62 66 Z',
          fill: 'url(#metal)',
        ) +
        shape(
          'M68 55 Q100 64 132 54 L139 66 Q100 77 62 66 Z',
          fill: '#4A2A5E',
        ) +
        '<rect x="91" y="57" width="18" height="14" rx="3" fill="url(#gold)" stroke="$goldLine" stroke-width="1.4"/>'
            '<rect x="96" y="61" width="8" height="6" rx="1" fill="#4A2A5E"/>' +
        star(104, 34, 6, '#FFF3B0', stroke: goldLine) +
        star(88, 46, 3.5, white) +
        line('M84 44 Q90 30 95 16', white, 2.4, 0.55) +
        line('M30 68 Q60 79 100 80', white, 1.6, 0.45),
  );

  // Flower crown: leaves and blossoms in a ring.
  const spots = [
    (47.0, 82.0),
    (55.0, 66.0),
    (68.0, 54.0),
    (84.0, 47.0),
    (100.0, 44.0),
    (116.0, 47.0),
    (132.0, 54.0),
    (145.0, 66.0),
    (153.0, 82.0),
  ];
  final crown = StringBuffer(
    line('M47 82 C56 54 78 44 100 44 C122 44 144 54 153 82', leafLine, 4),
  );
  for (var i = 0; i < spots.length - 1; i++) {
    final x = (spots[i].$1 + spots[i + 1].$1) / 2;
    final y = (spots[i].$2 + spots[i + 1].$2) / 2 - 3;
    crown.write(
      '<ellipse cx="${n(x)}" cy="${n(y)}" rx="7" ry="4" fill="$leaf" '
      'stroke="$leafLine" stroke-width="1" transform="rotate(${(i - 4) * 18 - 30} ${n(x)} ${n(y)})"/>',
    );
  }
  for (var i = 0; i < spots.length; i++) {
    final (x, y) = spots[i];
    crown.write(
      i.isEven
          ? flower(x, y, i == 4 ? 7.5 : 6, light, deep)
          : flower(x, y, 4.6, white, '#D9A0BE'),
    );
  }
  write('hatFlower', crown.toString());
}

// ---------------------------------------------------------------- costumes

void costumes() {
  // Princess: a cape, a gown with a gold front and puffed sleeves.
  write(
    'costumePrincess_back',
    shape(
          'M80 172 Q62 240 30 336 Q48 348 64 338 L100 300 L136 338 Q152 348 170 336 Q138 240 120 172 Z',
          fill: shade,
        ) +
        line('M32 334 Q48 346 64 336 M168 334 Q152 346 136 336', gold, 3),
  );
  const gown =
      'M82 216 L118 216 C134 250 154 298 164 342 Q132 356 100 354 Q68 356 36 342 C46 298 66 250 82 216 Z';
  write(
    'costumePrincess',
    fabric([gown, bodice]) +
        shape(
          'M93 220 L107 220 Q122 290 130 352 Q100 356 70 352 Q78 290 93 220 Z',
          fill: cream,
        ) +
        line('M93 220 Q78 290 70 352 M107 220 Q122 290 130 352', gold, 3.4) +
        line('M38 340 Q68 354 100 352 Q132 354 162 340', gold, 3.4) +
        line('M86 170 Q93 168 100 178 Q107 168 114 170', gold, 3) +
        shape('M78 212 L122 212 L121 222 L79 222 Z', fill: 'url(#gold)') +
        heart(100, 217, 10, '#FF5C93', stroke: '#B8285E') +
        circle(100, 194, 4, '#6EC3FF', stroke: '#2F78B8') +
        glint(86, 270) +
        glint(118, 306) +
        glint(52, 322) +
        glint(148, 318),
  );
  write(
    'costumePrincess_front',
    puffSleeves() + both(circle(78, 180, 3, 'url(#gold)', stroke: goldLine)),
  );

  // Mermaid: a shell top and a scaly tail with a big fin.
  const tail =
      'M79 214 L121 214 Q128 250 122 288 Q119 312 118 326 Q118 340 138 346 Q152 354 150 370 Q122 372 100 358 Q78 372 50 370 Q48 354 62 346 Q82 340 82 326 Q81 312 78 288 Q72 250 79 214 Z';
  final scales = [
    for (var row = 0; row < 12; row++)
      for (var x = 68 + (row.isOdd ? 6 : 0); x < 132; x += 12)
        line('M$x ${224 + row * 9} a6 6 0 0 0 12 0', shine, 1.5, 0.85),
  ].join();
  write(
    'costumeMermaid',
    fabric([tail], inside: scales) +
        shape(
          'M82 332 Q96 340 100 358 Q104 340 118 332 Q138 346 148 368 Q122 370 100 354 Q78 370 52 368 Q62 346 82 332 Z',
          fill: light,
        ) +
        line(
          'M96 346 Q80 354 60 366 M92 340 Q78 346 66 352 M104 346 Q120 354 140 366 M108 340 Q122 346 134 352',
          deep,
          1.2,
          0.6,
        ) +
        shape(
          'M77 212 Q88 220 100 214 Q112 220 123 212 L122 224 Q111 230 100 224 Q89 230 78 224 Z',
          fill: 'url(#gold)',
        ) +
        both(
          shape(
                'M99 196 Q82 204 76 190 Q74 180 82 180 Q84 173 91 176 Q99 178 99 196 Z',
                fill: 'url(#puff)',
              ) +
              line(
                'M98 195 L81 183 M98 195 L89 178 M98 195 L77 190',
                deep,
                1.1,
                0.7,
              ),
        ) +
        line('M80 184 Q80 176 86 168 M120 184 Q120 176 114 168', shade, 2) +
        circle(100, 195, 3.4, white, stroke: '#C9B6C3') +
        glint(90, 252, 3.4) +
        glint(112, 300, 3.4),
  );

  // Fairy: leaf wings, a petal dress and a flower belt.
  String wing(String d) => shape(d, fill: shine, extra: ' fill-opacity="0.85"');
  write(
    'costumeFairy_back',
    both(
      wing('M88 184 C60 130 12 128 10 168 C8 200 54 204 88 196 Z') +
          wing('M88 200 C52 204 22 232 36 256 C52 278 80 238 90 210 Z') +
          line('M86 188 Q50 166 20 160 M84 206 Q58 224 42 248', white, 2, 0.9) +
          glint(30, 150, 4) +
          glint(46, 244, 3),
    ),
  );
  String petal(num x, num tipX, num tipY, String fill) => shape(
    'M${n(x - 11)} 216 L${n(x + 11)} 216 Q${n(tipX + 20)} ${n(tipY - 34)} ${n(tipX)} ${n(tipY)} Q${n(tipX - 20)} ${n(tipY - 34)} ${n(x - 11)} 216 Z',
    fill: fill,
  );
  write(
    'costumeFairy',
    fabric([bodice]) +
        petal(86, 56, 276, shade) +
        petal(114, 144, 276, shade) +
        petal(100, 100, 288, shade) +
        petal(90, 72, 286, 'url(#metal)') +
        petal(110, 128, 286, 'url(#metal)') +
        petal(94, 90, 270, light) +
        petal(106, 116, 266, light) +
        line(
          'M72 280 Q80 250 90 222 M128 280 Q120 250 110 222',
          white,
          1.8,
          0.6,
        ) +
        shape('M79 212 L121 212 L121 220 L79 220 Z', fill: leaf) +
        flower(86, 216, 4.4, white, '#D9A0BE') +
        flower(100, 217, 5.4, pink, '#C9579A') +
        flower(114, 216, 4.4, white, '#D9A0BE') +
        flower(100, 184, 4, light, deep) +
        glint(80, 252) +
        glint(122, 262),
  );

  // A whole suit: top and trousers.
  String suit({String inside = ''}) =>
      fabric([torso, trousers], inside: inside);

  // Astronaut: a collar ring, a control panel and badges.
  write(
    'costumeAstronaut',
    suit() +
        shape('M80 238 L120 238 L121 247 L79 247 Z', fill: '#7CB8FF') +
        both(
          shape('M79 330 L99 330 L99 340 L79 340 Z', fill: '#FF8A5C') +
              line('M81 290 Q89 295 98 290', deep, 1.4, 0.6),
        ) +
        '<rect x="87" y="194" width="26" height="22" rx="5" fill="#E6E9F0" stroke="$deep" stroke-width="1.6"/>' +
        circle(93, 201, 2.8, '#FF6B7A') +
        circle(100, 201, 2.8, gold) +
        circle(107, 201, 2.8, '#6FCF6A') +
        line('M92 209 L108 209', '#7CB8FF', 3) +
        circle(84, 186, 5.4, '#4A66C8', stroke: deep) +
        star(84, 186, 3.8, white) +
        shape(
          'M80 164 Q100 178 120 164 Q126 172 118 178 Q100 190 82 178 Q74 172 80 164 Z',
          fill: '#C9D2E4',
        ) +
        line('M86 175 Q100 183 114 175', white, 2.4),
  );
  write(
    'costumeAstronaut_front',
    longSleeves(
      wide: true,
      cuff: '#7CB8FF',
      extra: line('M62 214 Q72 220 83 214', '#FF8A5C', 4),
    ),
  );

  // Chef: a double-breasted jacket, a red scarf and an apron.
  write(
    'costumeChef',
    suit() +
        line('M100 180 L108 236', deep, 1.2, 0.6) +
        both(buttons(91, [196, 210, 224], fill: '#5A5470')) +
        shape('M80 232 L120 232 L128 296 Q100 304 72 296 Z', fill: white) +
        line('M78 228 L122 228', '#FF6B7A', 6) +
        shape('M88 254 L112 254 L110 272 Q100 276 90 272 Z', fill: cream) +
        line('M96 254 L93 242 M104 254 L108 240', '#B5763F', 3) +
        heart(100, 264, 8, '#FF6B7A') +
        shape(
          'M86 167 L100 176 L114 167 L112 178 L103 182 L107 194 L100 189 L93 194 L97 182 L88 178 Z',
          fill: '#FF6B7A',
        ),
  );
  write('costumeChef_front', longSleeves(fill: base, cuff: shine));

  // Doctor: scrubs, a long coat and a stethoscope.
  write(
    'costumeDoctor',
    shape(trousers, fill: '#7FD6D0') +
        shape(torso, fill: '#9AE6E0') +
        fabric([
          'M87 167 Q73 168 72 181 L69 288 Q82 293 95 290 L95 194 Q89 182 87 167 Z',
          'M113 167 Q127 168 128 181 L131 288 Q118 293 105 290 L105 194 Q111 182 113 167 Z',
        ]) +
        both(
          shape('M87 167 L96 196 L84 192 L79 176 Z', fill: shine) +
              shape('M74 244 L90 244 L89 262 Q82 265 75 262 Z', fill: shine),
        ) +
        line('M79 244 L79 234', '#FF6B7A', 2.6) +
        line('M84 244 L84 236', '#4A8FE0', 2.6) +
        heart(116, 206, 10, '#FF6B8B', stroke: '#B8285E') +
        line('M89 170 Q82 204 92 214 Q102 222 108 208', '#5A5470', 2.6) +
        line('M111 170 Q116 190 108 208', '#5A5470', 2.6) +
        circle(108, 214, 6, '#C9D2E4', stroke: '#5A5470', width: 1.8) +
        circle(108, 214, 2.4, white),
  );
  write('costumeDoctor_front', longSleeves(fill: base, cuff: shine));
}

// ---------------------------------------------------------------- pajamas

void pajamas() {
  const piping = white;
  String legCuffs() =>
      both(shape('M79 337 L99.4 337 L99 348 L79.4 348 Z', fill: light));

  // Starry pajamas: a buttoned top and trousers.
  write(
    'pajamaStars',
    fabric([trousers, torso]) +
        legCuffs() +
        line('M77 241 Q100 247 123 241', piping, 3) +
        line('M100 178 L100 243', piping, 2.4) +
        buttons(100, [192, 207, 222], fill: gold, r: 2.8) +
        collar(white) +
        '<rect x="107" y="198" width="13" height="12" rx="3" fill="$light" stroke="$deep" stroke-width="1.4"/>' +
        star(113.5, 204, 4.6, '#FFF3B0', stroke: goldLine),
  );
  write('pajamaStars_front', longSleeves(cuff: white));

  // Heart nightgown with a lace hem.
  const nightie =
      'M82 204 L118 204 Q132 258 142 308 Q100 322 58 308 Q68 258 82 204 Z';
  final lace = [
    for (var i = 0; i <= 12; i++)
      circle(
        60 + i * 80 / 12,
        308 + 12 * (1 - math.pow((i - 6) / 6, 2)) * 0.55,
        4.4,
        white,
        stroke: '#D9A0BE',
      ),
  ].join();
  write(
    'pajamaHearts',
    lace +
        fabric([
          nightie,
          'M86 168 Q100 180 114 168 Q126 169 127 181 L120 208 L80 208 L73 181 Q74 169 86 168 Z',
        ]) +
        line('M86 169 Q100 183 114 169', white, 4) +
        line('M80 206 Q100 212 120 206', white, 3.6) +
        bow(100, 207, 0.7, fill: white) +
        heart(100, 193, 9, white, stroke: deep),
  );
  write('pajamaHearts_front', puffSleeves());

  // Bunny onesie: a hood with long ears, a soft tummy and paws.
  write(
    'pajamaBunny_back',
    both(
          '<g transform="rotate(-16 74 56)">'
          '${ellipse(74, 34, 15, 33, 'url(#puff)')}'
          '${ellipse(74, 36, 7.5, 23, '#FFC2D8', stroke: null)}</g>',
        ) +
        ellipse(100, 108, 68, 66, base),
  );
  write(
    'pajamaBunny',
    fabric([trousers, torso]) +
        ellipse(100, 220, 18, 28, cream, stroke: shade) +
        line('M100 178 L100 196', white, 2.4) +
        both(
          ellipse(87, 356, 14, 10, base) +
              ellipse(86, 358, 8.5, 6, cream, stroke: null) +
              circle(86, 360, 2.6, '#FFC2D8') +
              circle(82, 356.4, 1.3, '#FFC2D8') +
              circle(86, 354.8, 1.3, '#FFC2D8') +
              circle(90, 356.4, 1.3, '#FFC2D8'),
        ) +
        shape(
          'M80 164 Q100 180 120 164 Q126 174 116 180 Q100 190 84 180 Q74 174 80 164 Z',
          fill: cream,
        ) +
        bow(100, 188, 0.6, fill: '#FFC2D8'),
  );
  write('pajamaBunny_front', longSleeves(cuff: cream));

  // Cloud pajamas: a sleepy cloud on the front, little clouds all over.
  final puffs = [
    cloud(82, 188, 1),
    cloud(118, 232, 1),
    cloud(116, 180, 0.8),
    cloud(86, 262, 1.1),
    cloud(112, 288, 1),
    cloud(87, 318, 1),
    cloud(114, 330, 0.8),
  ].join();
  write(
    'pajamaCloud',
    fabric([trousers, torso], inside: puffs) +
        legCuffs() +
        line('M77 241 Q100 247 123 241', piping, 3) +
        line('M86 169 Q100 182 114 169', piping, 4) +
        cloud(100, 211, 2.2) +
        line('M93 211 q3 3 6 0 M103 211 q3 3 6 0', '#5A5470', 1.4) +
        circle(92, 216, 2, '#FFC2D8') +
        circle(110, 216, 2, '#FFC2D8'),
  );
  write('pajamaCloud_front', longSleeves(cuff: white));
}

// ---------------------------------------------------------------- sports

void sports() {
  // Tennis dress: sleeveless, pleated and short.
  const tennis = 'M80 214 L120 214 L141 266 Q100 280 59 266 Z';
  write(
    'sportTennis',
    fabric([
          tennis,
          'M84 169 L90 169 Q100 184 110 169 L116 169 Q122 186 121 218 L79 218 Q78 186 84 169 Z',
        ]) +
        line(
          'M88 220 L76 272 M97 221 L93 274 M105 221 L109 274 M113 220 L126 271',
          deep,
          1.4,
          0.55,
        ) +
        line('M61 262 Q100 276 139 262', white, 3.4) +
        line('M90 170 Q100 186 110 170', white, 3) +
        collar(white) +
        shape('M79 211 L121 211 L122 219 L78 219 Z', fill: white) +
        circle(112, 197, 5.6, '#D9F24D', stroke: '#8AA81E') +
        line('M107.5 194 q5 3 3.5 8.4', white, 1.2),
  );

  // Ballet leotard with a little tulle skirt.
  write(
    'sportBallet',
    fabric([
          'M85 170 L90 170 Q100 188 110 170 L115 170 Q123 190 120 216 Q127 236 120 252 Q110 260 100 256 Q90 260 80 252 Q73 236 80 216 Q77 190 85 170 Z',
        ]) +
        shape(
          'M80 214 L120 214 Q146 220 156 238 Q148 246 142 240 Q134 250 126 243 Q117 252 109 245 Q100 253 91 245 Q83 252 74 243 Q66 250 58 240 Q52 246 44 238 Q54 220 80 214 Z',
          fill: light,
          extra: ' fill-opacity="0.88"',
        ) +
        line(
          'M88 218 L70 238 M100 219 L100 242 M112 218 L130 238',
          white,
          1.4,
          0.8,
        ) +
        shape('M79 210 L121 210 L121 218 L79 218 Z', fill: shine) +
        bow(100, 214, 0.55) +
        line('M90 171 Q100 189 110 171', white, 2.4) +
        glint(76, 232, 3) +
        glint(124, 232, 3),
  );

  // Football kit: a shirt with a star number, shorts and a belt stripe.
  write(
    'sportFootball',
    shape(
          'M79 232 L121 232 L127 276 L102 278 L100 258 L98 278 L73 276 Z',
          fill: white,
        ) +
        both(line('M79 240 L76 274', base, 4)) +
        fabric(
          [torso],
          inside:
              '<rect x="84" y="166" width="8" height="84" fill="$white" opacity="0.85"/>'
              '<rect x="108" y="166" width="8" height="84" fill="$white" opacity="0.85"/>',
        ) +
        circle(100, 208, 12, white, stroke: deep, width: 1.6) +
        star(100, 208.5, 8, base, stroke: deep) +
        line('M86 169 Q100 182 114 169', white, 4.4),
  );
  write('sportFootball_front', shortSleeves());

  // Tracksuit: a zip jacket and trousers with side stripes.
  write(
    'sportTracksuit',
    fabric([trousers, torso]) +
        both(
          line('M80 252 L83 338', white, 3) +
              line('M84.5 252 L87 338', white, 1.4) +
              shape('M79 336 L99.4 336 L99 347 L79.4 347 Z', fill: shade) +
              line('M80 214 L89 232', deep, 1.4, 0.6),
        ) +
        shape('M76 238 L124 238 L124 247 L76 247 Z', fill: shade) +
        line('M100 176 L100 244', white, 2.6) +
        circle(100, 184, 2.8, gold, stroke: goldLine) +
        shape(
          'M85 163 Q100 171 115 163 L115 174 Q100 182 85 174 Z',
          fill: shade,
        ) +
        line('M75 190 Q88 198 98 196 M102 196 Q112 198 125 190', white, 2.6),
  );
  write(
    'sportTracksuit_front',
    longSleeves(extra: line('M70 184 L63 232', white, 3)),
  );
}

// ------------------------------------------------- more of the old kinds

void moreClothes() {
  // Sailor dress.
  write(
    'dressSailor',
    fabric(['M81 216 L119 216 L148 290 Q100 304 52 290 Z', bodice]) +
        line(
          'M90 224 L78 292 M100 224 L100 298 M110 224 L122 292',
          deep,
          1.4,
          0.5,
        ) +
        line('M57 282 Q100 296 143 282', white, 3.4) +
        both(
          shape('M86 167 L100 190 L82 194 L75 176 Z', fill: white) +
              line('M80 177 L85 189 L96 187', '#3D5FB8', 1.8),
        ) +
        shape(
          'M100 188 L92 206 L99 202 L100 210 L101 202 L108 206 Z',
          fill: '#FF6B7A',
        ) +
        circle(100, 189, 4, '#FF6B7A', stroke: deep) +
        shape('M78 212 L122 212 L122 221 L78 221 Z', fill: white) +
        circle(100, 216.5, 3, 'url(#gold)', stroke: goldLine),
  );
  write('dressSailor_front', shortSleeves(trim: white));

  // Strawberry dress: little seeds and a leafy collar.
  final seeds = [
    for (var row = 0; row < 8; row++)
      for (var x = 56 + (row.isOdd ? 8 : 0); x < 148; x += 16)
        '<ellipse cx="$x" cy="${180 + row * 15}" rx="1.7" ry="2.6" fill="#FFF3B0"/>',
  ].join();
  write(
    'dressStrawberry',
    fabric([
          'M82 216 L118 216 Q152 238 146 276 Q136 300 100 296 Q64 300 54 276 Q48 238 82 216 Z',
          bodice,
        ], inside: seeds) +
        line('M66 252 Q64 274 76 286', white, 3, 0.5) +
        shape(
          'M78 214 L88 226 L94 216 L100 229 L106 216 L112 226 L122 214 L110 208 L90 208 Z',
          fill: leaf,
        ) +
        shape(
          'M84 167 L92 183 L96 174 L100 188 L104 174 L108 183 L116 167 Q100 178 84 167 Z',
          fill: leaf,
        ) +
        flower(114, 196, 3.4, white, '#D9A0BE'),
  );
  write('dressStrawberry_front', puffSleeves(fill: leaf));

  // Blouse with a round collar and a bow.
  write(
    'topBlouse',
    fabric([torso]) +
        line('M100 180 L100 244', deep, 1.2, 0.5) +
        buttons(100, [204, 218, 232], r: 2) +
        both(
          shape(
            'M87 167 Q100 172 100 179 Q92 190 84 182 Q80 174 87 167 Z',
            fill: white,
          ),
        ) +
        bow(100, 184, 0.7, fill: light) +
        line('M79 237 Q100 243 121 237', white, 2.4),
  );
  write('topBlouse_front', puffSleeves());

  // Polo shirt.
  write(
    'topPolo',
    fabric(
          [torso],
          inside:
              '<rect x="68" y="204" width="64" height="9" fill="$white" opacity="0.9"/>'
              '<rect x="68" y="216" width="64" height="4" fill="$white" opacity="0.9"/>',
        ) +
        line('M100 178 L100 200', deep, 1.4, 0.7) +
        buttons(100, [185, 195], r: 1.8) +
        collar(white) +
        heart(113, 194, 7, white, stroke: deep),
  );
  write('topPolo_front', shortSleeves());

  // Pleated skirt.
  write(
    'skirtPleated',
    fabric(['M81 216 L119 216 L146 278 Q100 290 54 278 Z']) +
        line(
          'M86 220 L64 282 M93 221 L80 285 M100 221 L100 286 M107 221 L120 285 M114 220 L136 282',
          deep,
          1.6,
          0.6,
        ) +
        line(
          'M89 222 L72 281 M103 223 L110 283 M117 222 L141 276',
          white,
          2,
          0.45,
        ) +
        shape('M79 211 L121 211 L121 221 L79 221 Z', fill: shade) +
        circle(88, 216, 2.2, gold, stroke: goldLine) +
        circle(112, 216, 2.2, gold, stroke: goldLine),
  );

  // Three ruffles.
  String ruffle(num top, num bottom, num halfTop, num halfBottom) {
    final b = StringBuffer(
      'M${n(100 - halfTop)} ${n(top)} L${n(100 + halfTop)} ${n(top)} L${n(100 + halfBottom)} ${n(bottom)} ',
    );
    final w = halfBottom * 2 / 6;
    for (var i = 0; i < 6; i++) {
      final x = 100 + halfBottom - w * i;
      b.write('Q${n(x - w / 2)} ${n(bottom + 8)} ${n(x - w)} ${n(bottom)} ');
    }
    return '${b}Z';
  }

  write(
    'skirtRuffle',
    fabric([
          ruffle(260, 290, 32, 48),
          ruffle(238, 266, 26, 40),
          ruffle(216, 244, 19, 31),
        ]) +
        line('M72 262 Q100 270 128 262 M78 240 Q100 247 122 240', white, 2.2) +
        shape('M79 211 L121 211 L121 220 L79 220 Z', fill: shine) +
        bow(112, 215, 0.5),
  );

  // Mary Janes with a strap and a button.
  write(
    'shoesMaryJanes',
    both(
      '${ellipse(86, 357, 13.5, 8, 'url(#metal)')}'
      '${ellipse(89, 353.5, 7, 3, '#FFFFFF', stroke: null)}'
      '${line('M80 352 Q90 344 98 351', deep, 5.4)}'
      '${line('M80 352 Q90 344 98 351', base, 3)}'
      '${circle(82, 351, 2.2, gold, stroke: goldLine)}'
      '${line('M76 359 Q79 354 85 353', white, 2, 0.8)}'
      '<rect x="73" y="362" width="26" height="3.6" rx="1.8" fill="$deep"/>',
    ),
  );

  // Roller skates.
  write(
    'shoesRoller',
    both(
      '${shape('M83 332 L99 332 L99 357 L76 357 Q72 348 83 345 Z', fill: 'url(#metal)')}'
      '${shape('M82 329 L100 329 L100 336 L82 336 Z', fill: white)}'
      '${line('M88 340 L97 339 M87 345 L97 344', white, 1.8)}'
      '<rect x="74" y="356" width="27" height="4.5" rx="2" fill="$shade" stroke="$deep" stroke-width="1.4"/>'
      '${circle(80, 364.5, 5, gold, stroke: goldLine, width: 1.4)}'
      '${circle(95, 364.5, 5, gold, stroke: goldLine, width: 1.4)}'
      '${circle(80, 364.5, 1.8, white)}${circle(95, 364.5, 1.8, white)}'
      '${star(90, 351, 3.4, white)}',
    ),
  );
}

void main() {
  jackets();
  pants();
  socks();
  hats();
  costumes();
  pajamas();
  sports();
  moreClothes();
  stdout.writeln('Clothes art written to $itemDir');
}
