// Draws the Room Decorating furniture and toys into assets/svg/room/.
//
//   dart run tool/generate_room_art.dart
//
// Sizes must match lib/data/room_config.dart. Light comes from the upper
// left (the game adds its 2.5D shading on top).
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;

// ---------------------------------------------------------------- colors

String _mix(String a, String b, double t) {
  int at(String c, int i) => int.parse(c.substring(i, i + 2), radix: 16);
  final out = [
    for (final i in [1, 3, 5])
      (at(a, i) + (at(b, i) - at(a, i)) * t)
          .round()
          .toRadixString(16)
          .padLeft(2, '0'),
  ];
  return '#${out.join().toUpperCase()}';
}

String light(String c, [double t = 0.45]) => _mix(c, '#FFFFFF', t);
String deep(String c, [double t = 0.35]) => _mix(c, '#5A2350', t);

const pink = '#FF8FC7';
const rose = '#FF5F9E';
const lilac = '#B79CFF';
const sky = '#8CCBFF';
const mint = '#8EE0B8';
const green = '#6CC47A';
const yellow = '#FFD84D';
const orange = '#FFA64D';
const red = '#FF6B6B';
const wood = '#D99A63';
const cream = '#FFF3E0';
const white = '#FFFFFF';
const gold = '#FFC93D';
const tan = '#D9A066';

// ---------------------------------------------------------------- drawing

String n(num v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

/// One drawing. Filled shapes get a soft gradient and outline by themselves.
class Art {
  Art(this.w, this.h);
  final double w, h;
  final StringBuffer _body = StringBuffer();
  final Map<String, String> _grads = {};

  String _fill(String color) {
    final id = _grads.putIfAbsent(color, () => 'g${_grads.length}');
    return 'url(#$id)';
  }

  String _style(String color, double line, double opacity) =>
      'fill="${_fill(color)}"'
      '${line > 0 ? ' stroke="${deep(color)}" stroke-width="${n(line)}" stroke-linejoin="round"' : ''}'
      '${opacity < 1 ? ' opacity="$opacity"' : ''}';

  void raw(String s) => _body.writeln(s);

  void box(
    num x,
    num y,
    num bw,
    num bh,
    String color, {
    num r = 5,
    double line = 1.8,
    double opacity = 1,
  }) => raw(
    '<rect x="${n(x)}" y="${n(y)}" width="${n(bw)}" height="${n(bh)}" '
    'rx="${n(r)}" ${_style(color, line, opacity)}/>',
  );

  void oval(
    num cx,
    num cy,
    num rx,
    num ry,
    String color, {
    double line = 1.8,
    double opacity = 1,
    num turn = 0,
  }) => raw(
    '<ellipse cx="${n(cx)}" cy="${n(cy)}" rx="${n(rx)}" ry="${n(ry)}" '
    '${_style(color, line, opacity)}'
    '${turn == 0 ? '' : ' transform="rotate(${n(turn)} ${n(cx)} ${n(cy)})"'}/>',
  );

  void dot(num cx, num cy, num r, String color, {double opacity = 1}) => raw(
    '<circle cx="${n(cx)}" cy="${n(cy)}" r="${n(r)}" fill="$color"'
    '${opacity < 1 ? ' opacity="$opacity"' : ''}/>',
  );

  void ball(num cx, num cy, num r, String color, {double line = 1.8}) =>
      oval(cx, cy, r, r, color, line: line);

  void path(String d, String color, {double line = 1.8, double opacity = 1}) =>
      raw('<path d="$d" ${_style(color, line, opacity)}/>');

  void stroke(String d, String color, num width, {double opacity = 1}) => raw(
    '<path d="$d" fill="none" stroke="$color" stroke-width="${n(width)}" '
    'stroke-linecap="round" stroke-linejoin="round"'
    '${opacity < 1 ? ' opacity="$opacity"' : ''}/>',
  );

  void star(num cx, num cy, num r, String color, {double line = 1}) {
    final d = StringBuffer();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.48;
      d.write(
        '${i == 0 ? 'M' : 'L'}${n(cx + math.cos(a) * rr)} '
        '${n(cy + math.sin(a) * rr)} ',
      );
    }
    path('${d}Z', color, line: line);
  }

  void heart(num cx, num cy, num s, String color, {double line = 1}) {
    final h = s / 2;
    path(
      'M${n(cx)} ${n(cy + h * .9)} C${n(cx - h * 1.5)} ${n(cy)} '
      '${n(cx - h * .8)} ${n(cy - h * 1.25)} ${n(cx)} ${n(cy - h * .4)} '
      'C${n(cx + h * .8)} ${n(cy - h * 1.25)} ${n(cx + h * 1.5)} ${n(cy)} '
      '${n(cx)} ${n(cy + h * .9)} Z',
      color,
      line: line,
    );
  }

  /// A cute face: eyes with a shine, cheeks and a smile.
  void face(num cx, num cy, num s) {
    for (final side in [-1, 1]) {
      oval(cx + side * s, cy, s * .24, s * .3, '#3A2A40', line: 0);
      dot(cx + side * s + s * .08, cy - s * .1, s * .09, white);
      oval(
        cx + side * s * 1.45,
        cy + s * .5,
        s * .3,
        s * .18,
        '#FF8FB8',
        line: 0,
        opacity: .7,
      );
    }
    stroke(
      'M${n(cx - s * .35)} ${n(cy + s * .45)} Q${n(cx)} ${n(cy + s * .85)} '
          '${n(cx + s * .35)} ${n(cy + s * .45)}',
      '#7A3A5A',
      math.max(1, s * .13),
    );
  }

  /// A flower seen from the front.
  void flower(num cx, num cy, num r, String color) {
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      ball(
        cx + math.cos(a) * r * .75,
        cy + math.sin(a) * r * .75,
        r * .55,
        color,
        line: 1,
      );
    }
    ball(cx, cy, r * .45, yellow, line: 1);
  }

  String build() {
    final defs = StringBuffer();
    _grads.forEach((color, id) {
      defs.write(
        '<linearGradient id="$id" x1="0" y1="0" x2="0.6" y2="1">'
        '<stop offset="0" stop-color="${light(color, .38)}"/>'
        '<stop offset="0.45" stop-color="$color"/>'
        '<stop offset="1" stop-color="${deep(color, .12)}"/></linearGradient>',
      );
    });
    return '<svg xmlns="http://www.w3.org/2000/svg" width="${n(w)}" '
        'height="${n(h)}" viewBox="0 0 ${n(w)} ${n(h)}"><defs>$defs</defs>\n'
        '$_body</svg>\n';
  }
}

final Map<String, Art> drawings = {};

void draw(String id, double w, double h, void Function(Art a) paint) {
  final art = Art(w, h);
  paint(art);
  drawings[id] = art;
}

// ----------------------------------------------------------------- pieces

void _rugs() {
  draw('rug_round', 180, 66, (a) {
    a.oval(90, 33, 88, 31, pink);
    a.oval(90, 33, 70, 24, cream, line: 1);
    a.oval(90, 33, 50, 16.5, lilac, line: 1);
    a.oval(90, 33, 28, 9, cream, line: 1);
  });
  draw('rug_heart', 150, 78, (a) {
    const heart =
        'M75 76 C30 62 2 44 4 25 C6 4 50 -3 75 20 C100 -3 144 4 146 25 '
        'C148 44 120 62 75 76 Z';
    a.path(heart, rose);
    a.raw('<g transform="translate(15 8) scale(0.8)">');
    a.path(heart, light(pink, .3), line: 1.4);
    a.raw('</g>');
  });
  draw('rug_rainbow', 200, 80, (a) {
    var i = 0;
    for (final c in [red, orange, yellow, green, sky, lilac]) {
      a.oval(100, 40, 98 - i * 14, 38 - i * 5.5, c, line: 1);
      i++;
    }
    a.oval(100, 40, 15, 5.5, white, line: 1);
    for (final p in [(20, 40), (180, 40), (100, 8), (100, 72)]) {
      a.star(p.$1, p.$2, 6, white);
    }
  });
}

void _beds() {
  // A bed seen from the front-side: headboard left, mattress, blanket.
  void bed(
    Art a,
    double top,
    String frame,
    String blanket, {
    bool boards = true,
  }) {
    final h = a.h;
    for (final x in [12.0, a.w - 24]) {
      a.box(x, h - 18, 12, 17, deep(frame, .15), r: 4);
    }
    if (boards) {
      a.box(4, top, 26, h - top - 12, frame, r: 12);
      a.box(a.w - 26, h - 62, 22, 50, frame, r: 10);
    }
    a.box(14, h - 52, a.w - 28, 22, white, r: 8);
    a.box(14, h - 36, a.w - 28, 24, frame, r: 7);
    // Pillow and blanket.
    a.oval(48, h - 56, 25, 12, white, turn: -10);
    a.path(
      'M72 ${n(h - 58)} Q${n(a.w / 2 + 20)} ${n(h - 70)} ${n(a.w - 20)} '
      '${n(h - 54)} L${n(a.w - 16)} ${n(h - 28)} Q${n(a.w / 2 + 20)} '
      '${n(h - 20)} 72 ${n(h - 28)} Z',
      blanket,
    );
    a.box(70, h - 59, 13, 32, light(blanket, .6), r: 6, line: 1.2);
  }

  draw('bed_pink', 180, 118, (a) {
    bed(a, 22, pink, lilac);
    a.heart(17, 46, 18, cream);
    for (var i = 0; i < 4; i++) {
      a.heart(102 + i * 18, 76 + (i.isOdd ? 8 : 0), 10, light(rose, .5));
    }
  });
  draw('bed_car', 184, 108, (a) {
    a.path(
      'M6 92 L6 46 Q6 30 26 30 L38 30 Q48 8 70 12 L74 40 L140 46 '
      'Q180 52 178 80 L176 92 Z',
      red,
    );
    a.box(28, 44, 118, 22, white, r: 10);
    a.oval(52, 46, 20, 10, white, turn: -8);
    a.path('M70 42 Q120 34 146 50 L146 66 L70 66 Z', sky);
    a.stroke('M16 76 L164 76', white, 6);
    a.star(92, 76, 8, yellow);
    for (final x in [40.0, 142.0]) {
      a.ball(x, 91, 15, '#5A4A6A');
      a.ball(x, 91, 6, gold);
    }
    a.ball(170, 66, 5, yellow);
  });
  draw('bed_cloud', 180, 122, (a) {
    for (final p in [(22, 56, 20), (38, 38, 24), (58, 54, 18)]) {
      a.ball(p.$1, p.$2, p.$3, white);
    }
    bed(a, 60, sky, light(sky, .25), boards: false);
    for (var x = 24; x <= 156; x += 22) {
      a.ball(x, 98, 15, white, line: 1.4);
    }
    a.star(108, 74, 7, yellow);
    a.star(136, 82, 5, yellow);
    a.star(38, 36, 8, yellow);
  });
  draw('bed_canopy', 196, 208, (a) {
    // Posts, roof and curtains.
    for (final x in [8.0, 180.0]) {
      a.box(x, 44, 8, 150, gold, r: 4);
      a.ball(x + 4, 42, 6, gold);
    }
    a.path(
      'M6 44 Q20 8 98 8 Q176 8 190 44 Q175 56 160 44 Q145 58 129 45 '
      'Q114 59 98 45 Q82 59 67 45 Q51 58 36 44 Q21 56 6 44 Z',
      pink,
    );
    a.path('M86 10 L90 0 L95 7 L98 0 L101 7 L106 0 L110 10 Z', gold);
    a.path(
      'M14 50 Q50 52 56 46 Q44 100 20 118 Q34 150 14 182 Z',
      light(pink, .3),
    );
    a.path(
      'M182 50 Q146 52 140 46 Q152 100 176 118 Q162 150 182 182 Z',
      light(pink, .3),
    );
    a.oval(21, 117, 7, 5, gold);
    a.oval(175, 117, 7, 5, gold);
    // The bed itself.
    a.path(
      'M30 150 L30 112 Q40 92 60 104 Q72 82 98 82 Q124 82 136 104 '
      'Q156 92 166 112 L166 150 Z',
      lilac,
    );
    a.heart(98, 104, 18, gold);
    a.box(18, 142, 160, 24, white, r: 9);
    a.oval(56, 140, 26, 12, white, turn: -8);
    a.path('M78 138 Q130 124 178 142 L180 174 Q128 184 78 172 Z', rose);
    a.box(76, 137, 13, 36, white, r: 6, line: 1.2);
    a.box(16, 162, 164, 30, lilac, r: 9);
    for (var x = 40; x <= 156; x += 29) {
      a.heart(x, 177, 11, light(pink, .3));
    }
    for (final x in [24.0, 160.0]) {
      a.box(x, 190, 12, 16, gold, r: 4);
    }
    for (var x = 112; x <= 164; x += 24) {
      a.star(x, 154, 6, yellow);
    }
  });
  draw('bed_castle', 196, 214, (a) {
    const stone = '#C9BEEA';
    // Two towers with pointy roofs and flags.
    for (final x in [6.0, 154.0]) {
      a.box(x, 52, 36, 158, stone, r: 6);
      a.path('M${n(x - 4)} 54 L${n(x + 18)} 14 L${n(x + 40)} 54 Z', rose);
      a.stroke('M${n(x + 18)} 14 L${n(x + 18)} 3', '#7A5A8A', 2);
      a.path('M${n(x + 18)} 2 L${n(x + 32)} 7 L${n(x + 18)} 12 Z', yellow);
      a.path(
        'M${n(x + 10)} 94 L${n(x + 10)} 80 Q${n(x + 18)} 68 ${n(x + 26)} 80 '
            'L${n(x + 26)} 94 Z',
        '#8CCBFF',
      );
    }
    // Upper bunk with battlements.
    a.box(40, 80, 116, 20, white, r: 8);
    a.oval(64, 80, 20, 10, white, turn: -8);
    a.path('M82 76 Q120 66 154 80 L154 100 L82 100 Z', sky);
    for (var x = 42; x <= 138; x += 24) {
      a.box(x, 90, 14, 16, stone, r: 3);
    }
    a.box(38, 100, 120, 18, stone, r: 4);
    // Lower bunk.
    a.box(40, 160, 116, 20, white, r: 8);
    a.oval(64, 160, 20, 10, white, turn: -8);
    a.path('M82 156 Q120 146 154 160 L154 182 L82 182 Z', pink);
    a.box(38, 178, 120, 20, stone, r: 4);
    for (var x = 62; x <= 134; x += 24) {
      a.heart(x, 188, 10, rose);
    }
    // Ladder.
    for (final x in [126.0, 146.0]) {
      a.box(x, 104, 6, 108, wood, r: 3);
    }
    for (var y = 120; y <= 196; y += 19) {
      a.box(128, y, 22, 5, wood, r: 2, line: 1.2);
    }
  });
}

void _storage() {
  draw('wardrobe', 112, 172, (a) {
    a.box(12, 158, 12, 13, deep(pink, .15), r: 3);
    a.box(88, 158, 12, 13, deep(pink, .15), r: 3);
    a.box(6, 16, 100, 146, pink, r: 10);
    a.box(2, 8, 108, 18, light(pink, .25), r: 8);
    a.heart(56, 12, 20, rose);
    for (final x in [13.0, 58.0]) {
      a.box(x, 32, 41, 92, light(pink, .4), r: 8);
      a.box(x + 7, 40, 27, 76, light(pink, .15), r: 13, line: 1.2);
    }
    a.ball(49, 80, 4, gold);
    a.ball(63, 80, 4, gold);
    a.box(13, 130, 86, 26, light(pink, .4), r: 7);
    a.box(46, 140, 20, 6, gold, r: 3, line: 1.2);
  });
  draw('dresser', 118, 102, (a) {
    a.box(12, 90, 12, 11, deep(mint, .3), r: 3);
    a.box(94, 90, 12, 11, deep(mint, .3), r: 3);
    a.box(6, 14, 106, 80, mint, r: 9);
    a.box(2, 8, 114, 14, white, r: 6);
    for (var i = 0; i < 3; i++) {
      final y = 28.0 + i * 22;
      a.box(13, y, 92, 18, light(mint, .45), r: 6);
      a.ball(42, y + 9, 3.5, rose);
      a.ball(76, y + 9, 3.5, rose);
    }
  });
  draw('bookshelf', 100, 160, (a) {
    a.box(4, 4, 92, 154, wood, r: 9);
    for (var s = 0; s < 3; s++) {
      final y = 12.0 + s * 48;
      a.box(11, y, 78, 40, deep(wood, .25), r: 5, line: 1.2);
      if (s == 2) {
        a.box(16, y + 14, 30, 26, sky, r: 6);
        a.star(31, y + 27, 8, yellow);
        a.ball(68, y + 25, 15, orange);
        a.stroke('M54 ${n(y + 25)} Q68 ${n(y + 18)} 82 ${n(y + 25)}', white, 3);
        continue;
      }
      final colors = [red, yellow, sky, lilac, green, pink];
      var x = 15.0;
      for (var b = 0; b < 5; b++) {
        final bw = 8.0 + (b + s) % 3 * 2;
        final bh = 26.0 + (b * 7 + s * 5) % 12;
        a.box(x, y + 40 - bh, bw, bh, colors[(b + s * 3) % 6], r: 2, line: 1.2);
        x += bw + 1.5;
      }
      a.ball(x + 9, y + 31, 9, s == 0 ? pink : mint);
      a.face(x + 9, y + 30, 3.4);
    }
  });
  draw('wall_shelf', 132, 62, (a) {
    a.box(14, 46, 8, 14, deep(wood, .2), r: 3);
    a.box(110, 46, 8, 14, deep(wood, .2), r: 3);
    a.box(3, 40, 126, 10, wood, r: 5);
    a.box(14, 18, 12, 22, red, r: 2);
    a.box(27, 12, 11, 28, sky, r: 2);
    a.box(39, 20, 12, 20, yellow, r: 2);
    a.ball(70, 28, 12, pink);
    a.ball(62, 18, 5, pink);
    a.ball(78, 18, 5, pink);
    a.face(70, 27, 4.5);
    a.path('M96 22 L118 22 L114 40 L100 40 Z', lilac);
    a.flower(101, 13, 6, rose);
    a.flower(115, 10, 7, orange);
  });
}

void _desks() {
  draw('desk', 132, 104, (a) {
    a.box(10, 46, 11, 56, deep(wood, .1), r: 4);
    a.box(112, 46, 11, 56, deep(wood, .1), r: 4);
    a.box(76, 46, 46, 38, wood, r: 5);
    a.box(82, 52, 34, 12, light(wood, .35), r: 4, line: 1.2);
    a.box(82, 68, 34, 12, light(wood, .35), r: 4, line: 1.2);
    a.ball(99, 58, 2.5, gold);
    a.ball(99, 74, 2.5, gold);
    a.box(2, 36, 128, 13, light(wood, .2), r: 6);
    // A book, a cup of pencils and a drawing.
    a.box(14, 28, 34, 8, sky, r: 2);
    a.box(52, 31, 30, 5, white, r: 1, line: 1);
    a.stroke('M57 33 Q63 30 68 33 T77 33', rose, 1.4);
    for (final p in [(94, red), (100, yellow), (106, green)]) {
      a.box(p.$1, 8, 4.5, 22, p.$2, r: 2, line: 1);
    }
    a.box(90, 20, 24, 17, lilac, r: 5);
    a.heart(102, 28, 9, white);
  });
  draw('chair', 62, 98, (a) {
    a.box(8, 62, 8, 34, deep(sky, .2), r: 4);
    a.box(46, 62, 8, 34, deep(sky, .2), r: 4);
    a.box(10, 4, 42, 56, sky, r: 18);
    a.box(17, 12, 28, 36, light(sky, .5), r: 13, line: 1.2);
    a.heart(31, 30, 16, pink);
    a.box(4, 56, 54, 15, pink, r: 7);
  });
  draw('vanity', 112, 152, (a) {
    a.box(10, 104, 10, 46, deep(lilac, .15), r: 4);
    a.box(92, 104, 10, 46, deep(lilac, .15), r: 4);
    a.oval(56, 50, 38, 46, gold);
    a.oval(56, 50, 30, 38, '#CDEBFF');
    a.stroke('M40 34 Q44 24 54 20', white, 5, opacity: .9);
    a.stroke('M38 48 L39 42', white, 5, opacity: .9);
    a.heart(56, 6, 16, rose);
    a.box(4, 92, 104, 16, lilac, r: 7);
    a.box(24, 106, 64, 16, light(lilac, .3), r: 6);
    a.ball(56, 114, 3.5, gold);
    a.box(16, 78, 10, 14, pink, r: 3);
    a.box(19, 72, 4, 7, gold, r: 1, line: 1);
    a.ball(34, 86, 6, mint);
    a.box(82, 74, 8, 18, red, r: 3);
    a.ball(86, 72, 4, rose);
  });
}

void _lamps() {
  void shade(Art a, double cx, double top, double bottom, String color) {
    a.path(
      'M${n(cx - 16)} ${n(top)} L${n(cx + 16)} ${n(top)} L${n(cx + 27)} '
      '${n(bottom)} L${n(cx - 27)} ${n(bottom)} Z',
      color,
    );
    a.box(cx - 29, bottom - 4, 58, 7, light(color, .55), r: 3.5, line: 1.2);
  }

  draw('lamp_floor', 66, 170, (a) {
    a.oval(33, 162, 22, 7, deep(lilac, .1));
    a.box(30, 48, 6, 114, gold, r: 3);
    shade(a, 33, 6, 50, pink);
    a.heart(33, 28, 14, white);
  });
  draw('lamp_table', 56, 74, (a) {
    a.box(25, 38, 6, 14, gold, r: 3);
    a.oval(28, 60, 16, 13, sky);
    a.oval(28, 71, 13, 3, deep(sky, .2), line: 1.2);
    shade(a, 28, 5, 40, yellow);
    a.star(28, 22, 7, white);
  });
  draw('lamp_moon', 68, 82, (a) {
    a.oval(34, 75, 22, 6, lilac);
    a.box(31, 58, 6, 16, lilac, r: 3);
    a.path(
      'M44 6 C18 6 6 22 6 36 C6 54 22 64 38 64 C50 64 60 56 63 47 '
          'C46 54 30 46 30 32 C30 20 36 10 44 6 Z',
      '#FFE680',
    );
    a.face(24, 38, 4.5);
    a.star(52, 20, 8, gold);
  });
  draw('lamp_unicorn', 82, 112, (a) {
    a.oval(41, 103, 28, 8, lilac);
    a.box(30, 84, 22, 18, pink, r: 7);
    // Ears and horn.
    a.path('M20 34 L18 12 L36 26 Z', white);
    a.path('M62 34 L64 12 L46 26 Z', white);
    a.path('M34 28 L41 1 L48 28 Z', gold);
    a.stroke('M37 20 L45 17 M38 13 L44 11', white, 1.6);
    a.oval(41, 55, 31, 33, white);
    // Mane and face.
    for (final p in [(22, 30, pink), (33, 25, yellow), (18, 42, lilac)]) {
      a.ball(p.$1, p.$2, 8, p.$3, line: 1.2);
    }
    a.oval(41, 70, 20, 13, light(pink, .55), line: 1.2);
    a.face(41, 51, 8);
    a.dot(35, 72, 1.8, '#A0507A');
    a.dot(47, 72, 1.8, '#A0507A');
    a.star(68, 80, 6, yellow);
  });
}

void _windows() {
  // The glass stays empty: the game draws the day or night sky behind.
  void curtain(
    Art a,
    double x,
    double w,
    double top,
    double bottom,
    bool left,
    String color,
  ) {
    final inner = left ? x + w : x;
    final outer = left ? x : x + w;
    final waist = top + (bottom - top) * .62;
    final pull = left ? outer + w * .3 : outer - w * .3;
    a.path(
      'M${n(outer)} ${n(top)} L${n(inner)} ${n(top)} Q${n(inner)} '
      '${n(waist - 18)} ${n(pull)} ${n(waist)} Q${n(inner)} ${n(waist + 12)} '
      '${n((inner + outer) / 2)} ${n(bottom)} L${n(outer)} ${n(bottom)} Z',
      color,
    );
    a.oval((outer + pull) / 2, waist, w * .24, 4.5, gold, line: 1.2);
  }

  draw('window_square', 130, 124, (a) {
    // A frame with a see-through middle.
    a.raw(
      '<path fill="$white" stroke="${deep(lilac)}" stroke-width="1.8" '
      'fill-rule="evenodd" d="M20 16 H110 V108 H20 Z M26 22 V102 H104 V22 Z"/>',
    );
    a.box(62.5, 22, 5, 80, white, r: 2, line: 1);
    a.box(26, 59, 78, 5, white, r: 2, line: 1);
    a.box(14, 104, 102, 11, white, r: 5);
    curtain(a, 4, 34, 12, 118, true, pink);
    curtain(a, 92, 34, 12, 118, false, pink);
    a.box(2, 6, 126, 12, rose, r: 6);
    for (var x = 18; x <= 114; x += 24) {
      a.dot(x, 12, 2.5, white);
    }
  });
  draw('window_round', 112, 112, (a) {
    a.raw(
      '<path fill="$gold" stroke="${deep(gold)}" stroke-width="2" '
      'fill-rule="evenodd" d="M56 4 a52 52 0 1 0 .1 0 Z '
      'M56 14 a42 42 0 1 1 -.1 0 Z"/>',
    );
    a.box(53.5, 14, 5, 84, gold, r: 2, line: 1);
    a.box(14, 53.5, 84, 5, gold, r: 2, line: 1);
    a.flower(20, 92, 9, pink);
    a.flower(92, 20, 7, lilac);
  });
  draw('window_arch', 114, 150, (a) {
    a.raw(
      '<path fill="$white" stroke="${deep(sky)}" stroke-width="1.8" '
      'fill-rule="evenodd" d="M13 138 V47 C13 20 32 6 57 6 C82 6 101 20 101 47 '
      'V138 Z M20 132 H94 V51 C94 28 78 14 57 14 C36 14 20 28 20 51 Z"/>',
    );
    a.box(54.5, 14, 5, 118, white, r: 2, line: 1);
    a.box(20, 76, 74, 5, white, r: 2, line: 1);
    curtain(a, 2, 30, 34, 146, true, lilac);
    curtain(a, 82, 30, 34, 146, false, lilac);
    a.box(6, 134, 102, 12, white, r: 5, opacity: .95);
    a.heart(57, 8, 14, rose);
  });
  draw('window_wide', 178, 122, (a) {
    a.raw(
      '<path fill="$white" stroke="${deep(mint)}" stroke-width="1.8" '
      'fill-rule="evenodd" d="M24 18 H154 V106 H24 Z M30 24 V100 H148 V24 Z"/>',
    );
    a.box(68, 24, 5, 76, white, r: 2, line: 1);
    a.box(108, 24, 5, 76, white, r: 2, line: 1);
    a.box(18, 102, 142, 11, white, r: 5);
    curtain(a, 4, 40, 12, 118, true, mint);
    curtain(a, 134, 40, 12, 118, false, mint);
    a.path(
      'M4 8 H174 V20 Q160 34 146 20 Q132 34 117 20 Q103 34 89 20 Q75 34 61 20 '
      'Q46 34 32 20 Q18 34 4 20 Z',
      yellow,
    );
  });
}

/// A sitting teddy bear drawn on a 72 x 86 canvas.
void _bear(Art a, String fur, String bow) {
  for (final x in [18.0, 54.0]) {
    a.ball(x, 14, 11, fur);
    a.ball(x, 14, 5.5, light(fur, .5), line: 0);
  }
  a.oval(36, 59, 21, 22, fur);
  a.oval(36, 63, 12, 14, light(fur, .5), line: 0);
  a.oval(14, 57, 8, 14, fur, turn: 28);
  a.oval(58, 57, 8, 14, fur, turn: -28);
  for (final x in [19.0, 53.0]) {
    a.oval(x, 76, 13, 9.5, fur);
    a.ball(x, 77, 5, light(fur, .5), line: 0);
  }
  a.oval(36, 29, 24, 21, fur);
  a.oval(36, 37, 11, 8, light(fur, .6), line: 1);
  a.oval(36, 33.5, 4, 3, '#4A2E3A', line: 0);
  for (final x in [26.0, 46.0]) {
    a.oval(x, 27, 2.6, 3.2, '#3A2A40', line: 0);
    a.dot(x + .8, 25.8, 1, white);
  }
  a.dot(18, 35, 3.4, '#FF8FB8', opacity: .7);
  a.dot(54, 35, 3.4, '#FF8FB8', opacity: .7);
  a.stroke('M36 36 Q33 42 31 39 M36 36 Q39 42 41 39', '#7A4A4A', 1.1);
  a.path('M36 50 L24 44 L24 57 Z', bow);
  a.path('M36 50 L48 44 L48 57 Z', bow);
  a.ball(36, 50, 4, bow);
}

void _toys() {
  draw('teddy', 72, 86, (a) => _bear(a, tan, rose));
  draw('teddy_giant', 136, 164, (a) {
    a.raw('<g transform="translate(0 28) scale(1.88 1.58)">');
    _bear(a, '#E8B07A', lilac);
    a.raw('</g>');
    a.heart(68, 126, 30, rose);
    // A little party crown, because he is special.
    a.path('M50 34 L48 6 L60 18 L68 2 L76 18 L88 6 L86 34 Z', gold);
    a.ball(68, 24, 4, pink, line: 1);
  });
  draw('doll_house', 112, 130, (a) {
    a.box(80, 16, 12, 26, red, r: 2);
    a.box(10, 48, 92, 78, '#FFE3A8', r: 5);
    a.path('M2 52 L56 6 L110 52 Q56 60 2 52 Z', rose);
    a.ball(56, 34, 9, sky);
    a.stroke('M56 26 V42 M48 34 H64', white, 2);
    for (final x in [18.0, 72.0]) {
      for (final y in [60.0, 92.0]) {
        a.box(x, y, 22, 20, sky, r: 4);
        a.stroke(
          'M${n(x + 11)} ${n(y + 2)} V${n(y + 18)} M${n(x + 2)} ${n(y + 10)} H${n(x + 20)}',
          white,
          2,
        );
      }
    }
    a.path('M45 126 V98 Q56 82 67 98 V126 Z', lilac);
    a.ball(62, 110, 2.5, gold, line: 1);
    a.box(6, 122, 100, 7, green, r: 3.5);
  });
  draw('ball', 52, 52, (a) {
    a.ball(26, 26, 24, red);
    a.path('M26 2 C8 14 8 38 26 50 C16 38 16 14 26 2 Z', white, line: 1);
    a.path('M26 2 C44 14 44 38 26 50 C36 38 36 14 26 2 Z', yellow, line: 1);
    a.path('M26 2 C20 14 20 38 26 50 C32 38 32 14 26 2 Z', sky, line: 1);
    a.ball(26, 5, 4, white, line: 1);
    a.dot(15, 15, 4, white, opacity: .8);
  });
  draw('blocks', 82, 78, (a) {
    void block(double x, double y, String c) {
      a.box(x, y, 36, 36, c, r: 7);
      a.box(x + 5, y + 5, 26, 26, light(c, .45), r: 5, line: 1);
    }

    block(3, 40, red);
    block(43, 40, sky);
    block(22, 3, yellow);
    a.star(21, 58, 10, red);
    a.heart(61, 58, 18, rose);
    a.ball(40, 21, 8, green);
  });
  draw('unicorn_plush', 88, 88, (a) {
    for (final p in [
      (14, 52, 11, pink),
      (10, 66, 9, lilac),
      (18, 40, 8, yellow),
    ]) {
      a.ball(p.$1, p.$2, p.$3, p.$4, line: 1.2);
    }
    a.oval(38, 62, 24, 18, white);
    for (final x in [24.0, 38.0, 52.0]) {
      a.box(x - 5, 70, 11, 16, white, r: 5);
      a.box(x - 5, 80, 11, 7, lilac, r: 3, line: 1);
    }
    a.path('M62 14 L74 1 L72 20 Z', gold);
    a.path('M48 22 L46 6 L60 16 Z', white);
    a.oval(60, 34, 23, 21, white);
    for (final p in [(46, 20, pink), (39, 30, yellow), (38, 43, sky)]) {
      a.ball(p.$1, p.$2, 9, p.$3, line: 1.2);
    }
    a.oval(70, 43, 13, 9, light(pink, .55), line: 1);
    a.face(63, 31, 6.5);
  });
  draw('train', 124, 68, (a) {
    // Engine with two cars.
    a.box(84, 8, 28, 34, red, r: 6);
    a.box(90, 14, 16, 14, sky, r: 4, line: 1.2);
    a.box(60, 24, 30, 24, red, r: 9);
    a.box(66, 8, 10, 18, '#5A4A6A', r: 3);
    a.ball(72, 5, 4.5, white, line: 1);
    a.box(82, 4, 32, 7, yellow, r: 3);
    a.box(58, 40, 62, 12, yellow, r: 5);
    a.box(30, 30, 24, 22, green, r: 5);
    a.box(2, 30, 24, 22, sky, r: 5);
    a.ball(14, 30, 7, pink);
    a.ball(42, 28, 8, orange);
    a.stroke('M24 46 H62', '#5A4A6A', 3);
    for (final x in [8.0, 20.0, 36.0, 48.0, 70.0, 88.0, 108.0]) {
      final r = x > 60 ? 10.0 : 7.0;
      a.ball(x, 66 - r, r, '#7A5A8A');
      a.ball(x, 66 - r, r * .4, gold, line: 0);
    }
  });
  draw('aquarium', 134, 124, (a) {
    // A little table.
    a.box(16, 92, 10, 31, deep(wood, .1), r: 4);
    a.box(108, 92, 10, 31, deep(wood, .1), r: 4);
    a.box(6, 84, 122, 14, wood, r: 6);
    a.box(10, 8, 114, 78, '#8FD6F5', r: 14);
    a.path('M13 70 Q40 60 66 72 Q95 62 121 70 L121 80 Q67 88 13 80 Z', yellow);
    a.stroke('M26 72 Q18 56 28 46 Q34 36 28 28', green, 6);
    a.stroke('M110 72 Q118 60 108 50 Q102 42 110 34', green, 6);
    a.path('M40 76 Q42 60 52 66 Q62 56 62 76 Z', pink);
    void fish(double x, double y, double s, String c, int dir) {
      a.path(
        'M${n(x - dir * s)} ${n(y)} L${n(x - dir * s * 2)} ${n(y - s * .8)} '
        'L${n(x - dir * s * 2)} ${n(y + s * .8)} Z',
        c,
        line: 1.2,
      );
      a.oval(x, y, s * 1.3, s, c, line: 1.2);
      a.dot(x + dir * s * .6, y - s * .2, s * .22, '#3A2A40');
    }

    fish(54, 34, 10, orange, 1);
    fish(88, 52, 8, rose, -1);
    fish(78, 24, 6, yellow, 1);
    for (final p in [(100, 22, 4), (104, 34, 2.6), (40, 22, 3)]) {
      a.dot(p.$1, p.$2, p.$3, white, opacity: .85);
    }
    a.stroke('M20 22 Q22 16 30 15', white, 5, opacity: .8);
    a.box(6, 4, 122, 10, lilac, r: 5);
  });
}

void _plants() {
  void pot(Art a, double cx, double top, double w, String c) {
    a.path(
      'M${n(cx - w / 2)} ${n(top)} H${n(cx + w / 2)} L${n(cx + w * .36)} '
      '${n(a.h - 2)} H${n(cx - w * .36)} Z',
      c,
    );
    a.box(cx - w / 2 - 3, top - 4, w + 6, 10, light(c, .3), r: 5);
  }

  void leaf(
    Art a,
    double x,
    double y,
    double s,
    double turn, [
    String c = green,
  ]) {
    a.oval(x, y, s * .52, s, c, turn: turn);
    a.stroke(
      'M${n(x)} ${n(y - s * .6)} L${n(x)} ${n(y + s * .6)}',
      light(c, .35),
      1.2,
    );
  }

  draw('plant_flower', 56, 78, (a) {
    a.stroke('M28 50 V24', deep(green, .15), 4);
    leaf(a, 18, 40, 11, -55);
    leaf(a, 38, 42, 11, 55);
    a.flower(28, 20, 17, pink);
    pot(a, 28, 52, 34, orange);
    a.face(28, 64, 4);
  });
  draw('plant_leafy', 82, 138, (a) {
    a.stroke('M41 100 V40 M41 80 L20 56 M41 70 L62 46', deep(green, .2), 4);
    for (final l in [
      (41.0, 30.0, 26.0, 0.0),
      (22.0, 46.0, 22.0, -45.0),
      (60.0, 38.0, 23.0, 42.0),
      (20.0, 76.0, 19.0, -70.0),
      (62.0, 68.0, 20.0, 68.0),
      (34.0, 62.0, 17.0, -20.0),
    ]) {
      leaf(a, l.$1, l.$2, l.$3, l.$4);
    }
    pot(a, 41, 102, 46, lilac);
    a.heart(41, 120, 14, white);
  });
  draw('plant_cactus', 52, 82, (a) {
    a.box(5, 28, 13, 24, green, r: 6.5);
    a.box(35, 18, 13, 26, green, r: 6.5);
    a.box(10, 42, 16, 10, green, r: 5);
    a.box(28, 34, 14, 10, green, r: 5);
    a.box(17, 8, 19, 56, green, r: 9.5);
    a.face(26.5, 30, 4);
    a.flower(26.5, 10, 8, rose);
    pot(a, 26, 56, 32, yellow);
  });
  draw('plant_tulips', 62, 90, (a) {
    for (final t in [
      (16.0, 24.0, red),
      (31.0, 12.0, yellow),
      (46.0, 26.0, pink),
    ]) {
      final x = t.$1, y = t.$2;
      a.stroke('M31 66 Q${n(x)} 52 ${n(x)} ${n(y + 8)}', deep(green, .15), 3.5);
      a.path(
        'M${n(x - 10)} ${n(y - 8)} L${n(x - 4)} ${n(y)} L${n(x)} ${n(y - 10)} '
        'L${n(x + 4)} ${n(y)} L${n(x + 10)} ${n(y - 8)} Q${n(x + 12)} '
        '${n(y + 13)} ${n(x)} ${n(y + 13)} Q${n(x - 12)} ${n(y + 13)} '
        '${n(x - 10)} ${n(y - 8)} Z',
        t.$3,
      );
    }
    leaf(a, 20, 52, 13, -35);
    leaf(a, 43, 52, 13, 35);
    pot(a, 31, 62, 38, sky);
  });
}

void _art() {
  void frame(Art a, String frameColor, String paper) {
    a.box(2, 2, a.w - 4, a.h - 4, frameColor, r: 9);
    a.box(9, 9, a.w - 18, a.h - 18, paper, r: 4, line: 1.2);
  }

  draw('art_rainbow', 82, 68, (a) {
    frame(a, wood, '#DDF1FF');
    var r = 28.0;
    for (final c in [red, orange, yellow, green, lilac]) {
      a.stroke('M${n(41 - r)} 52 A${n(r)} ${n(r)} 0 0 1 ${n(41 + r)} 52', c, 5);
      r -= 5;
    }
    a.ball(17, 52, 6, white, line: 1);
    a.ball(65, 52, 6, white, line: 1);
  });
  draw('art_heart', 70, 82, (a) {
    frame(a, gold, cream);
    a.heart(35, 42, 42, rose, line: 1.6);
    a.face(35, 37, 6);
    a.star(18, 18, 5, yellow);
    a.star(53, 66, 5, lilac);
  });
  draw('art_cat', 72, 86, (a) {
    frame(a, lilac, '#FFE3F1');
    a.path('M18 40 L20 18 L34 30 Z', orange);
    a.path('M54 40 L52 18 L38 30 Z', orange);
    a.oval(36, 46, 22, 19, orange);
    a.oval(36, 54, 10, 7, white, line: 0);
    a.face(36, 43, 7);
    a.stroke(
      'M12 48 L22 49 M12 55 L22 53 M60 48 L50 49 M60 55 L50 53',
      '#7A4A5A',
      1,
    );
    a.heart(36, 70, 11, rose);
  });
  draw('art_rocket', 70, 88, (a) {
    frame(a, sky, '#3E3478');
    for (final p in [(17, 20), (54, 30), (18, 62), (52, 70), (48, 15)]) {
      a.star(p.$1, p.$2, 3.5, yellow, line: 0);
    }
    a.path('M28 66 Q35 82 42 66 Z', orange);
    a.path('M28 50 L18 66 L28 64 Z', red);
    a.path('M42 50 L52 66 L42 64 Z', red);
    a.path('M35 16 Q50 32 43 66 H27 Q20 32 35 16 Z', white);
    a.ball(35, 40, 7, sky);
  });
  draw('art_sun', 78, 78, (a) {
    for (var i = 0; i < 10; i++) {
      final t = i * math.pi / 5;
      a.ball(39 + math.cos(t) * 28, 39 + math.sin(t) * 28, 9, orange);
    }
    a.ball(39, 39, 27, yellow);
    a.face(39, 36, 9);
  });
  draw('art_bunting', 184, 52, (a) {
    a.stroke('M3 6 Q92 30 181 6', '#8B5CC9', 2.5);
    final colors = [pink, yellow, sky, mint, lilac, orange, pink];
    for (var i = 0; i < 7; i++) {
      final t = (i + 0.5) / 7;
      final x = 3 + 178 * t;
      final y = 6 + 48 * t * (1 - t);
      a.path(
        'M${n(x - 11)} ${n(y)} L${n(x + 11)} ${n(y)} L${n(x)} ${n(y + 30)} Z',
        colors[i],
      );
      a.heart(x, y + 10, 8, white, line: 0);
    }
  });
}

void _petBeds() {
  draw('petbed_round', 100, 52, (a) {
    a.oval(50, 31, 48, 20, pink);
    a.oval(50, 26, 36, 13, light(lilac, .35));
    for (final x in [20.0, 40.0, 60.0, 80.0]) {
      a.heart(x, 43, 8, white, line: 0);
    }
  });
  draw('petbed_basket', 100, 68, (a) {
    a.oval(50, 28, 46, 20, deep(wood, .15));
    a.oval(50, 31, 38, 14, sky);
    a.path('M4 30 Q50 56 96 30 Q94 64 78 66 H22 Q6 64 4 30 Z', wood);
    for (var x = 16; x <= 84; x += 17) {
      a.stroke('M$x 45 Q${x + 3} 55 $x 63', deep(wood, .2), 2.2);
    }
    a.stroke('M9 50 Q50 66 91 50', deep(wood, .2), 2.2);
    a.path('M50 44 L40 39 V51 Z', rose);
    a.path('M50 44 L60 39 V51 Z', rose);
    a.ball(50, 45, 3.5, rose);
  });
  draw('petbed_house', 102, 102, (a) {
    a.box(14, 42, 74, 58, yellow, r: 8);
    a.path('M3 48 L51 4 L99 48 Q95 56 87 52 L51 20 L15 52 Q7 56 3 48 Z', red);
    a.path('M20 44 L51 16 L82 44 Z', yellow, line: 0);
    a.path('M31 99 V70 Q51 42 71 70 V99 Z', '#7A4A6A');
    a.oval(51, 94, 17, 6, pink, line: 1);
    // A bone sign.
    for (final p in [(41, 35), (41, 41), (61, 35), (61, 41)]) {
      a.ball(p.$1, p.$2, 4, white, line: 1);
    }
    a.box(41, 34.5, 20, 7, white, r: 2, line: 0);
  });
}

void _pets() {
  draw('pet_bunny', 56, 82, (a) {
    for (final p in [(19.0, -8.0), (37.0, 8.0)]) {
      a.oval(p.$1, 17, 7, 17, white, turn: p.$2);
      a.oval(p.$1, 18, 3.4, 12, light(pink, .3), turn: p.$2, line: 0);
    }
    a.ball(46, 66, 7, white);
    a.oval(28, 62, 17, 17, white);
    a.oval(28, 65, 9, 11, light(pink, .75), line: 0);
    a.oval(18, 76, 9, 5.5, white);
    a.oval(38, 76, 9, 5.5, white);
    a.oval(28, 38, 20, 17, white);
    a.face(28, 36, 6);
    a.path('M26 41 H30 L28 43.5 Z', rose, line: 0);
    a.path('M28 54 L19 49 V60 Z', sky);
    a.path('M28 54 L37 49 V60 Z', sky);
    a.ball(28, 54, 3.2, sky);
  });
}

void main() {
  _rugs();
  _beds();
  _storage();
  _desks();
  _lamps();
  _windows();
  _toys();
  _plants();
  _art();
  _petBeds();
  _pets();
  final dir = Directory('assets/svg/room')..createSync(recursive: true);
  drawings.forEach((id, art) {
    File('${dir.path}/$id.svg').writeAsStringSync(art.build());
  });
  print('Wrote ${drawings.length} drawings to ${dir.path}');
}
