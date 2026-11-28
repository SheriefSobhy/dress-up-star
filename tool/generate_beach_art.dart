// Writes the SVG art for the Beach & Swim things: swimwear (with the burkini
// swim hoods), cover-ups, sun hats, swim caps, goggles, flip-flops and jelly
// sandals, and things to hold at the beach.
//
//   dart run tool/generate_beach_art.dart
//
// It uses the drawing helpers of generate_clothes_art.dart.
// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:math' as math;

import 'generate_clothes_art.dart';

const List<String> rainbow = [
  '#FF6B7A',
  '#FFA45C',
  '#FFD84D',
  '#7EDB6A',
  '#5CB8FF',
  '#B57CFF',
];

// ------------------------------------------------------------------ pieces

/// A one-piece swimsuit with short legs (it covers her whole romper).
const String onePiece =
    'M86 168 Q100 177 114 168 Q127 169 126 182 L121 222 Q126 240 125.5 261 '
    'L103 263 L100 253 L97 263 L74.5 261 Q74 240 79 222 L74 182 Q73 169 86 168 Z';

const String swimShorts =
    'M79 214 L121 214 Q125 238 125.5 262 L103 264 L100 253 L97 264 L74.5 262 '
    'Q75 238 79 214 Z';

const String rashTop =
    'M86 167 Q100 175 114 167 Q126 169 127 181 L123.5 240 Q100 246 76.5 240 '
    'L73 181 Q74 169 86 167 Z';

const String longShorts =
    'M78 230 L122 230 Q126 250 126 281 L102.5 282 L100 257 L97.5 282 L74 281 '
    'Q74 250 78 230 Z';

const String tunic =
    'M86 167 Q100 175 114 167 Q126 169 127 181 L123 218 Q132 248 138 276 '
    'Q100 290 62 276 Q68 248 77 218 L73 181 Q74 169 86 167 Z';

/// Rows of little round frills along a line from [x0] to [x1] at height [y].
String frill(
  num x0,
  num x1,
  num y, {
  String fill = light,
  double r = 5,
  double bow = 4,
}) {
  final count = ((x1 - x0) / (r * 1.5)).round();
  return [
    for (var i = 0; i <= count; i++)
      circle(
        x0 + (x1 - x0) * i / count,
        y + bow * math.sin(math.pi * i / count),
        r,
        fill,
        stroke: deep,
        width: 1.2,
      ),
  ].join();
}

/// Horizontal rainbow bands from [top], each [h] tall, bending down a bit.
String bands(num top, num h, {num bend = 5}) => [
  for (var i = 0; i < rainbow.length; i++)
    path(
      'M50 ${n(top + i * h)} Q100 ${n(top + i * h + bend * 2)} 150 ${n(top + i * h)} '
      'L150 ${n(top + (i + 1) * h + .5)} Q100 ${n(top + (i + 1) * h + bend * 2 + .5)} '
      '50 ${n(top + (i + 1) * h + .5)} Z',
      rainbow[i],
    ),
].join();

String waves(num y, String color, [double width = 2.4]) =>
    line('M58 $y q7 -7 14 0 t14 0 t14 0 t14 0 t14 0 t14 0', color, width);

String neckTrim([String color = white]) =>
    line('M86.5 169.5 Q100 178.5 113.5 169.5', color, 2.6);

// ------------------------------------------------------------------ swimwear

void swimsuits() {
  write(
    'swimFrilly',
    fabric([onePiece]) +
        neckTrim() +
        frill(76, 124, 224, fill: shine, r: 4.4) +
        frill(73, 127, 235) +
        both(frill(74, 88, 172, r: 4.2, bow: -4)) +
        bow(100, 215, 0.6),
  );
  write(
    'swimPolka',
    fabric([onePiece]) +
        neckTrim() +
        line('M79 222 Q100 228 121 222', white, 5) +
        bow(100, 224, 0.75) +
        both(line('M97 262 L75 260', white, 3)),
  );
  write(
    'swimRainbow',
    fabric([onePiece], inside: bands(192, 8)) +
        neckTrim() +
        line('M80 184 Q84 180 90 179', white, 2.4, 0.6) +
        heart(100, 186, 10, white, stroke: deep),
  );
  final scales = StringBuffer();
  for (var row = 0; row < 8; row++) {
    for (var i = 0; i < 8; i++) {
      final x = 66 + i * 11 + (row.isOdd ? 5.5 : 0);
      final y = 199 + row * 8.5;
      scales.write(
        '<path d="M${n(x - 5.5)} ${n(y)} Q${n(x)} ${n(y + 10)} ${n(x + 5.5)} ${n(y)}" '
        'fill="${(row + i) % 3 == 0 ? light : 'none'}" stroke="$shine" '
        'stroke-width="1.5" stroke-linecap="round"/>',
      );
    }
  }
  // Two shells for a neckline, and sparkles.
  final shell = shape(
    'M89 195 Q76 190 79 183 Q82 177 87 180 Q90 175 94 180 Q99 180 99 187 Q97 193 89 195 Z',
    fill: shine,
  );
  write(
    'swimMermaid',
    fabric([onePiece], inside: scales.toString()) +
        neckTrim(gold) +
        both(shell + line('M89 194 L84 182 M89 194 L90 181', deep, 1, 0.6)) +
        circle(100, 188, 2.6, white, stroke: goldLine) +
        glint(81, 208, 4.4) +
        glint(117, 232, 3.8) +
        glint(106, 202, 3) +
        glint(86, 248, 3.2),
  );
  write(
    'swimSporty',
    fabric(
          [onePiece],
          inside: both(
            path('M70 176 L82 176 L90 266 L70 266 Z', white) +
                line('M85 178 L94 266', white, 3),
          ),
        ) +
        neckTrim() +
        line('M100 178 L100 200', deep, 1.4, 0.7) +
        circle(100, 201, 2.4, gold, stroke: goldLine) +
        star(110, 192, 6, white, stroke: deep),
  );
}

void swimDresses() {
  final under = shape(swimShorts, fill: shade);
  const skirt =
      'M79 216 L121 216 Q130 244 136 271 Q100 285 64 271 Q70 244 79 216 Z';
  write(
    'swimDressRuffle',
    under +
        fabric([bodice, skirt]) +
        neckTrim() +
        frill(69, 131, 256, fill: shine, bow: 7) +
        frill(66, 134, 270, bow: 10, r: 4.6) +
        line('M79 219 Q100 224 121 219', white, 4) +
        both(line('M84 232 Q80 240 76 248', deep, 1.4, 0.5)),
  );
  const skater =
      'M79 216 L121 216 Q132 242 138 266 Q129 278 119 270 Q109 282 100 272 '
      'Q91 282 81 270 Q71 278 62 266 Q68 242 79 216 Z';
  write(
    'swimDressSkater',
    under +
        fabric([bodice, skater]) +
        neckTrim() +
        line('M79 219 Q100 225 121 219', deep, 6) +
        bow(100, 220, 0.8) +
        line(
          'M90 226 L78 268 M100 228 L100 270 M110 226 L122 268',
          deep,
          1.4,
          0.45,
        ) +
        waves(256, white) +
        both(line('M86 170 L83 190', white, 3.2)),
  );
  const peplum =
      'M78 206 L122 206 Q130 224 136 238 Q100 250 64 238 Q70 224 78 206 Z';
  const lower =
      'M76 234 L124 234 Q130 252 134 268 Q100 281 66 268 Q70 252 76 234 Z';
  write(
    'swimDressPeplum',
    under +
        fabric([lower, bodice, peplum]) +
        neckTrim() +
        line('M65 238 Q100 251 135 238', white, 3) +
        line('M67 268 Q100 281 133 268', white, 3) +
        flower(100, 207, 5.4, white, deep) +
        both(circle(86, 184, 2, white)),
  );
}

void rashGuards() {
  String sleeves() => longSleeves(extra: line('M72 190 L65 236', white, 2.2));
  write(
    'swimRashShorts',
    shape(longShorts, fill: deep) +
        both(line('M78 273 L97 274', shine, 3)) +
        fabric([rashTop]) +
        neckTrim() +
        waves(222, white, 3) +
        circle(100, 200, 9, shine, stroke: deep) +
        star(100, 200, 6.4, gold, stroke: goldLine),
  );
  write('swimRashShorts_front', sleeves());
  write(
    'swimRashSport',
    shape(longShorts, fill: shade) +
        both(
          line('M79 234 L77 280', white, 3.4) +
              line('M84 234 L83 280', white, 1.6),
        ) +
        fabric(
          [rashTop],
          inside:
              path('M60 196 L140 196 L140 210 L60 210 Z', white) +
              path('M60 214 L140 214 L140 219 L60 219 Z', white),
        ) +
        neckTrim() +
        line('M100 175 L100 193', deep, 1.6, 0.7) +
        circle(100, 194, 2.4, gold, stroke: goldLine),
  );
  write('swimRashSport_front', sleeves());
  write(
    'swimRashLeggings',
    shape(trousers, fill: shade) +
        both(
          line('M82 262 L84 342', shine, 2.4, 0.8) +
              line('M79.5 338 L98.5 338', shine, 3),
        ) +
        fabric([rashTop]) +
        neckTrim() +
        frill(79, 121, 240, fill: light, r: 3.6) +
        heart(100, 202, 18, white, stroke: deep),
  );
  write('swimRashLeggings_front', sleeves());
}

/// The swim hood of a burkini: it covers her hair, ears and neck and leaves
/// her face open.
String hood({String fill = base, String inside = '', String over = ''}) {
  const outer =
      'M100 40 C148 40 171 74 170 112 C169 140 154 158 131 168 L121 180 '
      'Q100 189 79 180 L69 168 C46 158 31 140 30 112 C29 74 52 40 100 40 Z';
  const face =
      'M100 70 C133 70 151 90 151 114 C151 140 130 157 100 157 '
      'C70 157 49 140 49 114 C49 90 67 70 100 70 Z';
  return '<clipPath id="hood"><path d="$outer $face" clip-rule="evenodd"/></clipPath>'
          '<path d="$outer $face" fill="$fill" fill-rule="evenodd"/>' +
      (inside.isEmpty ? '' : '<g clip-path="url(#hood)">$inside</g>') +
      line(outer, deep, 1.8) +
      line(face, white, 4.4) +
      line(face, deep, 1, 0.55) +
      line('M56 66 Q72 50 94 47', white, 4, 0.5) +
      line('M44 130 Q54 152 72 164', deep, 1.6, 0.35) +
      over;
}

void burkinis() {
  String set({String inside = '', String over = '', String legs = shade}) =>
      shape(trousers, fill: legs) +
      both(line('M79.5 338 L98.5 338', shine, 3)) +
      fabric([tunic], inside: inside) +
      over;
  String sleeves([String extra = '']) => longSleeves(extra: extra);

  write(
    'swimBurkiniWaves',
    set(inside: waves(250, white, 4) + waves(264, shine, 4)) +
        neckTrim() +
        line('M100 176 L100 214', deep, 1.4, 0.5),
  );
  write('swimBurkiniWaves_front', sleeves(line('M61 228 L81 231', white, 3)));
  write(
    'swimBurkiniWaves_hood',
    hood(inside: waves(55, white, 4) + waves(66, shine, 3)),
  );

  write(
    'swimBurkiniFlower',
    set(
          over: [
            for (final (x, y, r) in [
              (84, 262, 5.4),
              (112, 252, 4.4),
              (122, 268, 3.6),
              (100, 272, 3.2),
              (88, 194, 4.2),
            ])
              flower(x, y, r, white, deep),
          ].join(),
        ) +
        line('M77 218 Q100 226 123 218', deep, 4) +
        neckTrim(),
  );
  write('swimBurkiniFlower_front', sleeves(flower(68, 214, 3.4, white, deep)));
  write(
    'swimBurkiniFlower_hood',
    hood(
      over: flower(142, 70, 8, white, deep) + flower(152, 90, 5, shine, deep),
    ),
  );

  write(
    'swimBurkiniRainbow',
    set(inside: bands(240, 7.4, bend: 7)) +
        neckTrim(gold) +
        star(100, 200, 9, gold, stroke: goldLine) +
        glint(86, 188, 4) +
        glint(114, 218, 3.4),
  );
  write(
    'swimBurkiniRainbow_front',
    sleeves(
      [
        for (var i = 0; i < 4; i++)
          line(
            'M${61 - i} ${214 + i * 6} L${83 - i} ${217 + i * 6}',
            rainbow[i + 1],
            4,
          ),
      ].join(),
    ),
  );
  write(
    'swimBurkiniRainbow_hood',
    hood(inside: bands(42, 5.4, bend: -6), over: glint(60, 62, 4.4)),
  );
}

// ------------------------------------------------------------------ cover-ups

void coverUps() {
  const sundress =
      'M82 168 L88 168 Q92 188 100 190 Q108 188 112 168 L118 168 L124 196 L121 220 '
      'Q138 252 148 296 Q100 310 52 296 Q62 252 79 220 L76 196 Z';
  write(
    'beachSundress',
    fabric([sundress]) +
        line('M79 220 Q100 227 121 220', white, 4.6) +
        bow(100, 222, 0.7) +
        line(
          'M90 228 L80 298 M100 230 L100 304 M110 228 L120 298',
          deep,
          1.2,
          0.35,
        ) +
        frill(55, 145, 295, fill: white, r: 3.4, bow: 10) +
        line('M88 170 Q92 188 100 190 Q108 188 112 170', white, 2.4),
  );

  const kaftan =
      'M86 167 Q72 168 68 184 L72 206 L77 212 Q62 248 53 292 Q100 304 147 292 '
      'Q138 248 123 212 L128 206 L132 184 Q128 168 114 167 L100 196 Z';
  write(
    'beachKaftan',
    fabric([kaftan], inside: waves(274, white, 3) + waves(283, gold, 2.4)) +
        line('M85 168 L100 197 L115 168', gold, 5) +
        line('M85 168 L100 197 L115 168', white, 1.6) +
        [
          for (var i = 0; i < 3; i++)
            circle(100, 203 + i * 8, 2.6, gold, stroke: goldLine),
        ].join() +
        frill(55, 145, 293, fill: gold, r: 2.4, bow: 9),
  );
  write(
    'beachKaftan_front',
    both(
      shape(
            'M73 170 Q82 165 90 175 L84 214 Q70 222 54 213 L63 186 Q65 174 73 170 Z',
            fill: 'url(#puff)',
          ) +
          line('M56 212 Q70 219 83 212', gold, 3.4),
    ),
  );

  const robe =
      'M86 167 Q73 168 72 182 L76 222 Q63 250 58 292 Q100 303 142 292 Q137 250 124 222 L128 182 '
      'Q127 168 114 167 L100 200 Z';
  final terry = [
    for (var y = 180; y < 298; y += 9)
      for (var x = 68 + (y % 18 == 0 ? 4 : 0); x < 136; x += 9)
        circle(x, y, 1.3, shine),
  ].join();
  write(
    'beachRobe',
    fabric([robe], inside: terry) +
        both(shape('M86 167 L101 201 L94 207 Q78 188 80 170 Z', fill: white)) +
        line('M100 224 L103 296', deep, 1.4, 0.6) +
        line('M76 223 Q100 231 124 223', deep, 8) +
        line('M76 223 Q100 231 124 223', light, 5) +
        shape('M94 228 L88 252 L95 251 L99 231 Z', fill: light) +
        shape('M104 229 L112 250 L105 251 L100 232 Z', fill: light) +
        circle(100, 228, 4.6, light, stroke: deep) +
        both(shape('M72 252 L90 253 L89 270 Q80 273 72 268 Z', fill: light)),
  );
  write('beachRobe_front', longSleeves(wide: true, cuff: white));
}

// ------------------------------------------------------------------ hats

void beachHats() {
  const brim = 'url(#metal)';
  // A straw hat with a ribbon.
  write(
    'hatStraw',
    ellipse(100, 62, 78, 17, brim) +
        line('M30 62 Q100 86 170 62 M38 58 Q100 78 162 58', deep, 1.2, 0.45) +
        shape('M63 62 C60 16 140 16 137 62 Q100 74 63 62 Z') +
        [
          for (final y in [30, 40])
            line('M70 $y Q100 ${y + 8} 130 $y', deep, 1.2, 0.45),
        ].join() +
        shape('M63 48 Q100 59 137 48 L137 61 Q100 73 63 61 Z', fill: white) +
        bow(130, 56, 0.85, fill: pink) +
        line('M76 32 Q84 23 98 21', white, 2.6, 0.65),
  );
  write(
    'hatBucket',
    shape('M62 64 L68 34 Q100 18 132 34 L138 64 Z') +
        line('M66 52 Q100 62 134 52', white, 4) +
        shape(
          'M62 60 Q100 74 138 60 L160 82 Q130 92 124 80 Q100 72 76 80 Q70 92 40 82 Z',
          fill: shade,
        ) +
        line('M52 80 Q74 68 100 68 Q126 68 148 80', shine, 1.6, 0.8) +
        flower(122, 50, 6, white, deep) +
        line('M78 34 Q90 27 104 27', white, 2.6, 0.6),
  );
  // A big floppy sun hat with a wavy brim.
  write(
    'hatFloppy',
    shape(
          'M18 70 Q24 44 58 52 Q100 62 142 52 Q176 44 182 70 Q168 90 140 78 '
          'Q120 68 100 74 Q80 68 60 78 Q32 90 18 70 Z',
          fill: brim,
        ) +
        shape('M60 60 C56 12 144 12 140 60 Q100 72 60 60 Z') +
        shape('M61 46 Q100 58 139 46 L140 58 Q100 71 60 58 Z', fill: shine) +
        flower(68, 52, 8, white, deep) +
        flower(80, 59, 5.4, pink, deep) +
        line('M78 30 Q88 21 102 20', white, 2.8, 0.65),
  );
  // A visor: open on top, so her hair shows.
  write(
    'hatVisor',
    shape('M49 74 Q100 44 151 74 L149 85 Q100 59 51 85 Z') +
        shape(
          'M58 74 Q100 54 142 74 Q158 96 128 94 Q100 82 72 94 Q42 96 58 74 Z',
          fill: shade,
        ) +
        line('M64 78 Q100 62 136 78', shine, 2.4, 0.9) +
        circle(100, 62, 6.4, white, stroke: deep) +
        star(100, 62, 4.6, gold, stroke: goldLine),
  );

  const cap =
      'M39 112 C33 68 62 41 100 41 C138 41 167 68 161 112 Q155 120 149 111 '
      'C146 90 128 74 100 74 C72 74 54 90 51 111 Q45 120 39 112 Z';
  const capEdge = 'M51 111 C54 90 72 74 100 74 C128 74 146 90 149 111';
  write(
    'hatSwimCap',
    fabric([cap]) +
        line('M100 43 L100 72', white, 6) +
        line('M82 45 Q76 58 76 76 M118 45 Q124 58 124 76', shine, 3) +
        line(capEdge, deep, 3) +
        line('M54 68 Q66 50 88 47', white, 3, 0.7),
  );
  write(
    'hatSwimCapFlower',
    fabric([cap]) +
        line(capEdge, white, 3.6) +
        line('M54 68 Q66 50 88 47', white, 3, 0.7) +
        flower(136, 62, 10, white, deep) +
        flower(148, 86, 6.4, shine, deep) +
        flower(116, 52, 5.6, pink, deep) +
        [
          for (final (x, y) in [(66, 70), (86, 58), (102, 62), (58, 90)])
            circle(x, y, 3, shine),
        ].join(),
  );
}

// ------------------------------------------------------------------ goggles

void goggles() {
  const strap = 'M59 113 L44 108 M141 113 L156 108';
  // Cut the middle out, so her eyes stay bright behind the glass.
  String ring(num x) =>
      '<path d="M${x - 21} 115 a21 17 0 1 0 42 0 a21 17 0 1 0 -42 0 Z '
          'M${x - 15} 115 a15 11.5 0 1 0 30 0 a15 11.5 0 1 0 -30 0 Z" '
          'fill="$base" fill-rule="evenodd" stroke="$deep" stroke-width="1.6"/>'
          '<ellipse cx="$x" cy="115" rx="15" ry="11.5" fill="$shine" fill-opacity="0.24"/>' +
      line('M${x - 10} 111 Q${x - 6} 106 $x 106', white, 2.6, 0.9);
  write(
    'eyesGoggles',
    line(strap, deep, 5.4) +
        line(strap, light, 3) +
        line('M98 113 Q100 108 102 113', deep, 5) +
        ring(78) +
        ring(122),
  );
  const mask =
      'M52 104 Q54 94 78 95 L122 95 Q146 94 148 104 L147 124 Q144 135 124 135 '
      'Q108 135 105 127 Q100 120 95 127 Q92 135 76 135 Q56 135 53 124 Z';
  const glass =
      'M59 106 Q61 101 78 101 L122 101 Q139 101 141 106 L140 121 Q138 128 124 128 '
      'Q112 128 109 122 Q100 111 91 122 Q88 128 76 128 Q62 128 60 121 Z';
  write(
    'eyesSwimMask',
    line(strap, deep, 7) +
        line(strap, base, 4.4) +
        '<path d="$mask $glass" fill="$base" fill-rule="evenodd" stroke="$deep" '
            'stroke-width="1.6" stroke-linejoin="round"/>' +
        '<path d="$glass" fill="$shine" fill-opacity="0.24"/>' +
        line(
          'M66 112 L74 104 M72 116 L80 107 M126 112 L134 104',
          white,
          2.4,
          0.85,
        ) +
        // The snorkel.
        line('M156 130 Q168 126 167 104 L167 62', deep, 8) +
        line('M156 130 Q168 126 167 104 L167 62', light, 5) +
        circle(167, 60, 4.6, gold, stroke: goldLine) +
        ellipse(154, 131, 6, 4.4, shade),
  );
}

// ------------------------------------------------------------------ shoes

void beachShoes() {
  String sole({String fill = shade}) =>
      ellipse(86, 362.5, 13.5, 4.8, fill) +
      line('M76 362 Q86 366 96 362', shine, 1.4, 0.8);
  const thong = 'M77 357 Q82 353 86 362 Q90 353 95 357';
  String straps() => line(thong, deep, 4.6) + line(thong, base, 2.8);

  write(
    'shoesFlipFlops',
    both(sole() + straps() + circle(86, 361, 1.8, white)),
  );
  write(
    'shoesFlipFlower',
    both(sole(fill: light) + straps() + flower(86, 356, 3.8, white, deep)),
  );

  // Jelly sandals: see-through, with a cage of straps.
  String jelly() =>
      sole() +
      '<path d="M74 361 Q74 350 86 349 Q98 350 98 361 Q86 367 74 361 Z" '
          'fill="$light" fill-opacity="0.55" stroke="$deep" stroke-width="1.6"/>' +
      line('M79 352 L83 365 M86 350 L86 365 M93 352 L89 365', base, 2.2) +
      line('M75 358 Q86 353 97 358', base, 2.2) +
      line('M76 348 Q86 344 96 348', deep, 4) +
      line('M76 348 Q86 344 96 348', base, 2.4) +
      line('M78 354 Q81 351 84 351', white, 1.8, 0.9);
  write('shoesJelly', both(jelly()));
  write(
    'shoesJellySparkle',
    both(
      jelly() +
          star(86, 355, 4.6, gold, stroke: goldLine) +
          glint(76, 351, 4.4) +
          glint(96, 363, 3.4) +
          circle(91, 357, 1, white) +
          circle(80, 362, 1, white),
    ),
  );
}

// ------------------------------------------------------------------ to hold

/// Her hand, over what she holds.
const String _hand =
    '<circle cx="135.5" cy="252" r="8.2" fill="#FFDCC8" stroke="#DE9F84" stroke-width="1.6"/>'
    '<ellipse cx="130" cy="249" rx="3" ry="4.2" fill="#FFDCC8" stroke="#DE9F84" '
    'stroke-width="1.2" transform="rotate(25 130 249)"/>';

/// A swim ring hanging from her hand.
String ring({String fill = base, String inside = ''}) {
  const d =
      'M120 276 a26 24 0 1 0 52 0 a26 24 0 1 0 -52 0 Z '
      'M135 276 a11 10 0 1 0 22 0 a11 10 0 1 0 -22 0 Z';
  return '<clipPath id="ring"><path d="$d" clip-rule="evenodd"/></clipPath>'
          '<path d="$d" fill="$fill" fill-rule="evenodd" stroke="$deep" stroke-width="1.8"/>'
          '<g clip-path="url(#ring)">$inside</g>' +
      line('M126 270 Q130 258 142 256', white, 4, 0.7) +
      line('M164 288 Q156 296 146 297', deep, 3, 0.3);
}

void holdables() {
  // Arm floaties: one round float on each upper arm.
  write(
    'handFloaties',
    both(
      '<g transform="rotate(11 75 197)">'
              '${ellipse(75, 197, 13, 10.5, base)}'
              '</g>' +
          line('M63 196 Q74 202 87 195', shine, 3) +
          line('M67 191 Q71 188 77 188', white, 2.4, 0.85) +
          circle(66, 201, 1.8, white, stroke: deep),
    ),
  );

  write(
    'handRingDuck',
    ring() +
        shape('M118 290 Q106 288 110 278 Q114 286 124 283 Z') +
        circle(168, 255, 11.5, base, stroke: deep, width: 1.8) +
        shape('M176 255 Q188 254 186 260 Q181 264 175 261 Z', fill: '#FFA02E') +
        circle(171, 252, 2.2, '#3A2A40') +
        circle(171.8, 251.2, 0.8, white) +
        circle(166, 259, 2.4, '#FF9EB8') +
        _hand,
  );
  const neck = 'M164 272 Q184 262 174 246 Q164 232 172 226';
  write(
    'handRingFlamingo',
    ring() +
        line(neck, deep, 11) +
        line(neck, base, 7.6) +
        circle(174, 225, 9, base, stroke: deep, width: 1.8) +
        shape('M180 222 Q191 223 188 236 Q184 232 179 231 Z', fill: white) +
        path('M188 229 Q188 234 188 236 Q185 233 183 232 Z', '#3A2A40') +
        circle(175, 223, 1.9, '#3A2A40') +
        circle(175.7, 222.3, 0.7, white) +
        line(
          'M126 286 Q134 295 146 292 M130 281 Q136 287 144 286',
          shine,
          2.6,
        ) +
        glint(160, 262, 4.6) +
        _hand,
  );
  final sprinkles = [
    for (var i = 0; i < 14; i++)
      () {
        final a = i * 2 * math.pi / 14;
        final r = i.isEven ? 19.5 : 15.5;
        final x = 146 + math.cos(a) * r, y = 276 + math.sin(a) * r * 0.92;
        return line(
          'M${n(x - 2)} ${n(y - 1)} L${n(x + 2)} ${n(y + 1)}',
          rainbow[i % rainbow.length],
          2.6,
        );
      }(),
  ].join();
  write(
    'handRingDonut',
    ring(
          fill: '#F2C078',
          inside:
              '<path d="M118 252 L176 252 L176 276 Q170 290 164 280 Q158 296 150 286 '
              'Q142 298 136 284 Q128 292 126 280 Q118 286 118 272 Z '
              'M135 276 a11 10 0 1 0 22 0 a11 10 0 1 0 -22 0 Z" fill="$base" '
              'fill-rule="evenodd" stroke="$deep" stroke-width="1.2"/>',
        ) +
        sprinkles +
        _hand,
  );

  const ball = 'M122 272 a22 22 0 1 0 44 0 a22 22 0 1 0 -44 0 Z';
  write(
    'handBeachBall',
    '<clipPath id="ball"><path d="$ball"/></clipPath>'
            '${path(ball, white)}'
            '<g clip-path="url(#ball)">'
            '${path('M144 252 Q120 262 119 292 L130 298 Q130 268 144 252 Z', base)}'
            '${path('M144 252 Q140 272 144 296 L156 294 Q160 268 144 252 Z', '#FFD84D')}'
            '${path('M144 252 Q166 262 164 292 L172 280 L170 258 Z', '#5CB8FF')}'
            '</g>' +
        line(ball, deep, 1.8) +
        circle(144, 255, 4.4, white, stroke: deep) +
        line('M127 266 Q130 257 139 253', white, 3.4, 0.8) +
        _hand,
  );

  write(
    'handBucket',
    // The spade.
    line('M153 275 L166 241', '#E0A81E', 4.4) +
        shape('M159 238 L172 243 L170 247 L158 242 Z', fill: '#FFD84D') +
        shape(
          'M145 270 L159 270 L158 281 Q152 289 146 281 Z',
          fill: '#5CB8FF',
        ) +
        line('M122 271 Q136 232 153 271', deep, 4) +
        line('M122 271 Q136 232 153 271', white, 2) +
        shape('M121 270 L155 270 L150 298 Q138 303 126 298 Z') +
        ellipse(138, 270, 17.5, 4.6, shine) +
        path(
          'M124 270 Q131 264 138 268 Q146 264 152 270 Q138 274 124 270 Z',
          '#F2C078',
        ) +
        star(138, 285, 7.4, shine, stroke: deep) +
        line('M126 276 L129 293', white, 2.4, 0.7) +
        _hand,
  );

  write(
    'handIceCream',
    shape(
          'M126 238 L146 238 L137.5 270 Q136 273 134.5 270 Z',
          fill: '#F2C078',
        ) +
        line(
          'M128 244 L141 257 M134 240 L143 249 M144 244 L131 257 M138 240 L129 249',
          '#C48A3A',
          1.2,
        ) +
        circle(136, 233, 11.5, base, stroke: deep, width: 1.8) +
        circle(136, 219, 9.4, shine, stroke: deep, width: 1.8) +
        circle(137, 208, 4, '#FF4F6D', stroke: '#B02A48') +
        line('M137 205 Q139 200 143 199', '#3F9B4B', 1.4) +
        line('M128 230 Q130 225 135 224', white, 2.4, 0.8) +
        line(
          'M132 215 L134 217 M141 218 L140 221 M139 231 L142 233',
          '#5CB8FF',
          2,
        ) +
        _hand,
  );
}

void main() {
  swimsuits();
  swimDresses();
  rashGuards();
  burkinis();
  coverUps();
  beachHats();
  goggles();
  beachShoes();
  holdables();
}
