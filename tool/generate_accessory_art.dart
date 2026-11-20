// Writes the SVG art for jewelry and glasses.
//
//   dart run tool/generate_accessory_art.dart
//
// The pictures are drawn on the 200 x 400 doll space with the recolor
// placeholder colors (see lib/art/art_library.dart), so they can be
// recolored like every other item. Geometry lives here so both sides of a
// pair of glasses or earrings are exact mirror images.
// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:io';
import 'dart:math' as math;

const String itemDir = 'assets/svg/items';
const String iconDir = 'assets/svg/icons';

// Recolor placeholders.
const String base = '#FF00FF';
const String light = '#FF66FF';
const String shine = '#FFCCFF';
const String shade = '#CC00CC';
const String deep = '#990099';

String n(double v) {
  final s = v.toStringAsFixed(2);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}

class P {
  const P(this.x, this.y);
  final double x;
  final double y;
  P operator +(P o) => P(x + o.x, y + o.y);
  P operator -(P o) => P(x - o.x, y - o.y);
  P operator *(double s) => P(x * s, y * s);
  P get mirrored => P(200 - x, y);
  String get s => '${n(x)} ${n(y)}';
}

/// A path made of absolute commands, so it can be mirrored left/right.
class PathB {
  final List<(String, List<P>)> _cmds = [];
  PathB m(P p) => this.._cmds.add(('M', [p]));
  PathB l(P p) => this.._cmds.add(('L', [p]));
  PathB q(P c, P p) => this.._cmds.add(('Q', [c, p]));
  PathB c(P c1, P c2, P p) => this.._cmds.add(('C', [c1, c2, p]));
  PathB z() => this.._cmds.add(('Z', const []));
  String get d =>
      _cmds.map((e) => '${e.$1}${e.$2.map((p) => p.s).join(' ')}').join(' ');
  String get mirroredD => _cmds
      .map((e) => '${e.$1}${e.$2.map((p) => p.mirrored.s).join(' ')}')
      .join(' ');
}

String header(String extraDefs) =>
    '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="400" '
    'viewBox="0 0 200 400"><defs>'
    '<radialGradient id="puff" cx="0.38" cy="0.32" r="0.72">'
    '<stop offset="0" stop-color="#FFFFFF"/><stop offset="0.25" stop-color="$shine"/>'
    '<stop offset="0.6" stop-color="$light"/><stop offset="1" stop-color="$shade"/></radialGradient>'
    '<linearGradient id="metal" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="$shine"/><stop offset="0.45" stop-color="$base"/>'
    '<stop offset="1" stop-color="$shade"/></linearGradient>'
    '<linearGradient id="gem" x1="0" y1="0" x2="1" y2="1">'
    '<stop offset="0" stop-color="#FFFFFF"/><stop offset="0.2" stop-color="$shine"/>'
    '<stop offset="0.55" stop-color="$base"/><stop offset="1" stop-color="$shade"/></linearGradient>'
    '<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="#FFF3B0"/><stop offset="0.5" stop-color="#FFD84D"/>'
    '<stop offset="1" stop-color="#E0A81E"/></linearGradient>'
    '$extraDefs</defs>';

const String footer = '</svg>';

/// A four-point twinkle, the "this gem shines" mark.
String glint(P c, double r, {double opacity = 0.95}) {
  final i = r * 0.28;
  return '<path d="M${c.s} m0 ${n(-r)} L${n(c.x + i)} ${n(c.y - i)} '
      'L${n(c.x + r)} ${n(c.y)} L${n(c.x + i)} ${n(c.y + i)} L${n(c.x)} ${n(c.y + r)} '
      'L${n(c.x - i)} ${n(c.y + i)} L${n(c.x - r)} ${n(c.y)} L${n(c.x - i)} ${n(c.y - i)} Z" '
      'fill="#FFFFFF" opacity="$opacity"/>';
}

String heartD(P c, double size) {
  final s = size / 2;
  final x = c.x, y = c.y;
  return 'M${n(x)} ${n(y + s * 0.9)} '
      'C${n(x - s * 1.4)} ${n(y - s * 0.1)} ${n(x - s * 0.7)} ${n(y - s * 1.2)} ${n(x)} ${n(y - s * 0.45)} '
      'C${n(x + s * 0.7)} ${n(y - s * 1.2)} ${n(x + s * 1.4)} ${n(y - s * 0.1)} ${n(x)} ${n(y + s * 0.9)} Z';
}

String starD(P c, double outer, {double ratio = 0.48, int points = 5}) {
  final sb = StringBuffer();
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : outer * ratio;
    final a = -math.pi / 2 + i * math.pi / points;
    sb.write(
      '${i == 0 ? 'M' : 'L'}${n(c.x + math.cos(a) * r)} ${n(c.y + math.sin(a) * r)} ',
    );
  }
  return '${sb}Z';
}

/// A shape with a soft outline: the outline stroke, then the fill.
String shape(
  String d, {
  String fill = 'url(#gem)',
  String stroke = deep,
  double width = 1.4,
  String extra = '',
}) =>
    '<path d="$d" fill="$fill" stroke="$stroke" stroke-width="${n(width)}" '
    'stroke-linejoin="round"$extra/>';

/// A line drawn as a dark outline with a colored core (chains, frames).
String line(
  String d,
  double width, {
  String color = base,
  String outline = deep,
}) =>
    '<path d="$d" fill="none" stroke="$outline" stroke-width="${n(width + 1.6)}" '
    'stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="$d" fill="none" stroke="$color" stroke-width="${n(width)}" '
    'stroke-linecap="round" stroke-linejoin="round"/>';

/// Chibi jewelry is chunky: necklaces are drawn small around the neck and
/// then scaled up from the base of her neck.
String scaled(String body, P at, double s) =>
    '<g transform="translate(${at.s}) scale(${n(s)}) translate(${n(-at.x)} ${n(-at.y)})">$body</g>';

void write(String dir, String name, String body, {String defs = ''}) {
  if (name.startsWith('neck')) {
    body = name == 'neckChoker'
        ? scaled(body, const P(100, 164), 1.3)
        : scaled(body, const P(100, 160), 1.55);
  }
  Directory(dir).createSync(recursive: true);
  File('$dir/$name.svg').writeAsStringSync('${header(defs)}$body$footer\n');
}

// ------------------------------------------------------------- necklaces

/// The front of a necklace: a U from one side of the neck to the other.
P cubic(P a, P b, P c, P d, double t) {
  final u = 1 - t;
  return a * (u * u * u) +
      b * (3 * u * u * t) +
      c * (3 * u * t * t) +
      d * (t * t * t);
}

class Drape {
  const Drape(this.drop);
  final double drop;
  P get a => const P(88.5, 163);
  P get b => P(87.5, 163 + drop);
  P get c => P(112.5, 163 + drop);
  P get d => const P(111.5, 163);
  P at(double t) => cubic(a, b, c, d, t);
  P get bottom => at(0.5);
  String get path => 'M${a.s} C${b.s} ${c.s} ${d.s}';
}

const String goldOutline = '#B07A12';

String goldChain(Drape drape) =>
    line(drape.path, 1.3, color: 'url(#gold)', outline: goldOutline) +
    '<path d="${drape.path}" fill="none" stroke="#FFF6C8" stroke-width="0.5" '
        'stroke-dasharray="1.2 1.6" opacity="0.9"/>';

String silverChain(Drape drape) =>
    line(drape.path, 1.3, color: '#E6E9F0', outline: '#8D93A6') +
    '<path d="${drape.path}" fill="none" stroke="#FFFFFF" stroke-width="0.5" '
        'stroke-dasharray="1.2 1.6"/>';

/// A little ring that holds a pendant.
String bail(P top) =>
    '<circle cx="${n(top.x)}" cy="${n(top.y + 1.4)}" r="1.6" fill="none" '
    'stroke="$goldOutline" stroke-width="1.6"/><circle cx="${n(top.x)}" '
    'cy="${n(top.y + 1.4)}" r="1.6" fill="none" stroke="#FFE27A" stroke-width="0.8"/>';

void necklaces() {
  // Pearls: big round beads, each with its own shine.
  {
    const drape = Drape(15);
    final b = StringBuffer(
      line(drape.path, 0.7, color: '#E8DDE6', outline: '#B9A7B6'),
    );
    const count = 11;
    for (var i = 0; i < count; i++) {
      final p = drape.at(i / (count - 1));
      final r = 2.35 + 0.35 * math.sin(math.pi * i / (count - 1));
      b.write(
        '<circle cx="${n(p.x)}" cy="${n(p.y)}" r="${n(r)}" fill="url(#puff)" '
        'stroke="$deep" stroke-width="0.8"/>'
        '<circle cx="${n(p.x - r * 0.35)}" cy="${n(p.y - r * 0.4)}" r="${n(r * 0.32)}" '
        'fill="#FFFFFF" opacity="0.95"/>',
      );
    }
    b.write(glint(drape.bottom + const P(4.5, -2.5), 2.8));
    write(itemDir, 'neckPearl', b.toString());
  }

  // Heart pendant on a gold chain.
  {
    const drape = Drape(20);
    final top = drape.bottom;
    final heart = heartD(top + const P(0, 7.2), 13);
    write(
      itemDir,
      'neckHeart',
      goldChain(drape) +
          bail(top) +
          shape(heart, width: 1.5) +
          '<path d="${heartD(top + const P(-1.6, 5.6), 5)}" fill="#FFFFFF" opacity="0.55"/>' +
          glint(top + const P(4.6, 4.2), 2.6) +
          glint(top + const P(-5.5, 10.5), 1.6, opacity: 0.8),
    );
  }

  // Star pendant on a gold chain.
  {
    const drape = Drape(20);
    final top = drape.bottom;
    final c = top + const P(0, 7.4);
    write(
      itemDir,
      'neckStar',
      goldChain(drape) +
          bail(top) +
          shape(starD(c, 7.6, ratio: 0.5), width: 1.5) +
          '<path d="${starD(c + const P(-0.6, -0.4), 3.4, ratio: 0.5)}" fill="#FFFFFF" opacity="0.45"/>' +
          glint(c + const P(4.8, -4.4), 2.6),
    );
  }

  // A chunky chain of links, all in the chosen color (gold to start).
  {
    const drape = Drape(16);
    final b = StringBuffer();
    const count = 9;
    for (var i = 0; i < count; i++) {
      final t = i / (count - 1);
      final p = drape.at(t);
      final q = drape.at(math.min(1, t + 0.01));
      final angle = math.atan2(q.y - p.y, q.x - p.x) * 180 / math.pi;
      final flat = i.isOdd;
      b.write(
        '<ellipse cx="${n(p.x)}" cy="${n(p.y)}" rx="3.1" ry="${flat ? 1.2 : 1.9}" '
        'transform="rotate(${n(angle)} ${n(p.x)} ${n(p.y)})" fill="none" '
        'stroke="$deep" stroke-width="2.4"/>'
        '<ellipse cx="${n(p.x)}" cy="${n(p.y)}" rx="3.1" ry="${flat ? 1.2 : 1.9}" '
        'transform="rotate(${n(angle)} ${n(p.x)} ${n(p.y)})" fill="none" '
        'stroke="url(#metal)" stroke-width="1.3"/>',
      );
    }
    b.write(glint(drape.at(0.62) + const P(1, -2.6), 2.6));
    b.write(glint(drape.at(0.2) + const P(-1, -2.2), 1.8, opacity: 0.8));
    write(itemDir, 'neckGold', b.toString());
  }

  // Rainbow beads, with a big bead in the chosen color in the middle.
  {
    const drape = Drape(15);
    const rainbow = [
      '#FF5F6D',
      '#FFA24C',
      '#FFE066',
      '#7EDB6A',
      '#5CB8FF',
      '#B57CFF',
    ];
    final b = StringBuffer(
      line(drape.path, 0.7, color: '#FFFFFF', outline: '#C9B6C3'),
    );
    const count = 13;
    for (var i = 0; i < count; i++) {
      if (i == count ~/ 2) continue;
      final p = drape.at(i / (count - 1));
      final color =
          rainbow[(i < count ~/ 2 ? i : count - 1 - i) % rainbow.length];
      b.write(
        '<circle cx="${n(p.x)}" cy="${n(p.y)}" r="2.1" fill="$color" '
        'stroke="#7A4A6A" stroke-opacity="0.55" stroke-width="0.7"/>'
        '<circle cx="${n(p.x - 0.7)}" cy="${n(p.y - 0.8)}" r="0.7" fill="#FFFFFF" opacity="0.85"/>',
      );
    }
    final mid = drape.bottom;
    b.write(
      '<circle cx="${n(mid.x)}" cy="${n(mid.y + 0.6)}" r="3.6" fill="url(#puff)" '
      'stroke="$deep" stroke-width="1"/>',
    );
    b.write(glint(mid + const P(-1.1, -0.7), 1.6));
    write(itemDir, 'neckRainbow', b.toString());
  }

  // A ribbon choker with a flower in front.
  {
    final band = PathB()
        .m(const P(92, 162.6))
        .q(const P(100, 168), const P(108, 162.6));
    const c = P(100, 166.2);
    final b = StringBuffer(line(band.d, 4.2, color: 'url(#metal)'));
    b.write(
      '<path d="${band.d}" fill="none" stroke="$shine" stroke-width="0.8" '
      'stroke-dasharray="0.1 2.4" stroke-linecap="round" transform="translate(0 -0.9)"/>',
    );
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final p = c + P(math.cos(a), math.sin(a)) * 3.2;
      b.write(
        '<circle cx="${n(p.x)}" cy="${n(p.y)}" r="2.7" fill="$light" '
        'stroke="$deep" stroke-width="1"/>',
      );
    }
    b.write(
      '<circle cx="${n(c.x)}" cy="${n(c.y)}" r="2.1" fill="#FFE066" '
      'stroke="#D99A1E" stroke-width="0.9"/>'
      '<circle cx="${n(c.x - 0.6)}" cy="${n(c.y - 0.7)}" r="0.7" fill="#FFFFFF"/>',
    );
    b.write(glint(c + const P(5.6, -3.2), 1.9));
    write(itemDir, 'neckChoker', b.toString());
  }

  // A big crystal drop on a silver chain.
  {
    const drape = Drape(20);
    final top = drape.bottom;
    final t = top + const P(0, 2.6);
    final gem = PathB()
        .m(t)
        .l(t + const P(5.4, 5))
        .l(t + const P(0, 15))
        .l(t + const P(-5.4, 5))
        .z();
    write(
      itemDir,
      'neckCrystal',
      silverChain(drape) +
          '<circle cx="${n(top.x)}" cy="${n(top.y + 1.3)}" r="1.5" fill="none" '
              'stroke="#8D93A6" stroke-width="1.5"/>' +
          shape(gem.d, width: 1.4) +
          '<path d="M${(t + const P(-5.4, 5)).s} L${(t + const P(5.4, 5)).s} '
              'M${t.s} L${(t + const P(-1.8, 5)).s} L${(t + const P(0, 15)).s} '
              'L${(t + const P(1.8, 5)).s} Z" fill="none" stroke="#FFFFFF" '
              'stroke-width="0.7" opacity="0.75"/>' +
          '<path d="M${(t + const P(-1.8, 5)).s} L${t.s} L${(t + const P(-5.4, 5)).s} Z" '
              'fill="#FFFFFF" opacity="0.5"/>' +
          glint(t + const P(5.6, 1.2), 3) +
          glint(t + const P(-4.4, 12), 1.8, opacity: 0.85),
    );
  }

  // A butterfly on a gold chain.
  {
    const drape = Drape(19);
    final top = drape.bottom;
    final c = top + const P(0, 5.6);
    String wings(double side) {
      final up = PathB()
          .m(c)
          .c(
            c + P(side * 3, -6),
            c + P(side * 9.5, -6.5),
            c + P(side * 8.4, -1),
          )
          .c(c + P(side * 7.8, 2), c + P(side * 3, 1.6), c)
          .z();
      final down = PathB()
          .m(c)
          .c(c + P(side * 6, 1.2), c + P(side * 7.6, 6.6), c + P(side * 4, 7.2))
          .c(c + P(side * 1.6, 7.4), c + P(side * 0.6, 3), c)
          .z();
      return shape(up.d, width: 1.3) +
          shape(down.d, fill: 'url(#metal)', width: 1.3);
    }

    write(
      itemDir,
      'neckButterfly',
      goldChain(drape) +
          wings(-1) +
          wings(1) +
          '<ellipse cx="${n(c.x)}" cy="${n(c.y + 1.6)}" rx="1.2" ry="4.2" '
              'fill="#6B3A5E" stroke="#4A2340" stroke-width="0.6"/>' +
          '<path d="M${(c + const P(-0.4, -2.2)).s} q-1.5 -2.8 -3 -3.2 '
              'M${(c + const P(0.4, -2.2)).s} q1.5 -2.8 3 -3.2" fill="none" '
              'stroke="#4A2340" stroke-width="0.6" stroke-linecap="round"/>' +
          '<circle cx="${n(c.x - 5.6)}" cy="${n(c.y - 2.4)}" r="1.1" fill="#FFFFFF" opacity="0.85"/>' +
          '<circle cx="${n(c.x + 5.6)}" cy="${n(c.y - 2.4)}" r="1.1" fill="#FFFFFF" opacity="0.85"/>' +
          glint(c + const P(8.8, -6), 2.2),
    );
  }
}

// -------------------------------------------------------------- earrings

/// Under the ear lobes (the right ear is the mirror image).
const P lobe = P(41, 124.5);

String both(String Function(P at, double side) draw) =>
    scaled(draw(lobe, -1), lobe, 1.75) +
    scaled(draw(lobe.mirrored, 1), lobe.mirrored, 1.75);

String stud(P at, double r) =>
    '<circle cx="${n(at.x)}" cy="${n(at.y)}" r="${n(r)}" fill="url(#gem)" '
    'stroke="$deep" stroke-width="1.1"/>'
    '<circle cx="${n(at.x - r * 0.35)}" cy="${n(at.y - r * 0.38)}" r="${n(r * 0.33)}" '
    'fill="#FFFFFF" opacity="0.9"/>';

String hook(P at, double length) => line(
  'M${at.s} L${(at + P(0, length)).s}',
  0.8,
  color: 'url(#gold)',
  outline: goldOutline,
);

void earrings() {
  write(
    itemDir,
    'earsStud',
    both((at, side) => stud(at, 3.3) + glint(at + P(side * 3.6, -3.4), 2.1)),
  );

  write(
    itemDir,
    'earsHoop',
    both(
      (at, side) =>
          '<circle cx="${n(at.x)}" cy="${n(at.y + 6.6)}" r="6.4" fill="none" '
              'stroke="$deep" stroke-width="3.2"/>'
              '<circle cx="${n(at.x)}" cy="${n(at.y + 6.6)}" r="6.4" fill="none" '
              'stroke="url(#metal)" stroke-width="1.8"/>'
              '<path d="M${(at + P(-4.4, 3)).s} Q${(at + P(-5.8, 6.6)).s} ${(at + P(-4.2, 10.2)).s}" '
              'fill="none" stroke="#FFFFFF" stroke-width="0.8" stroke-linecap="round" opacity="0.85"/>' +
          glint(at + P(side * 6.2, 11.6), 1.8),
    ),
  );

  write(
    itemDir,
    'earsHeart',
    both(
      (at, side) =>
          hook(at, 3.4) +
          shape(heartD(at + const P(0, 8.2), 9.2), width: 1.2) +
          '<path d="${heartD(at + const P(-1.2, 6.9), 3.4)}" fill="#FFFFFF" opacity="0.6"/>' +
          glint(at + P(side * 4.4, 4), 1.8),
    ),
  );

  write(
    itemDir,
    'earsStar',
    both(
      (at, side) =>
          hook(at, 3) +
          shape(starD(at + const P(0, 8.8), 5.6, ratio: 0.5), width: 1.2) +
          '<circle cx="${n(at.x - 1)}" cy="${n(at.y + 7.6)}" r="1" fill="#FFFFFF" opacity="0.8"/>' +
          glint(at + P(side * 4.8, 4.6), 1.8),
    ),
  );

  write(
    itemDir,
    'earsGem',
    both((at, side) {
      final top = at + const P(0, 6.4);
      final drop = PathB()
          .m(top)
          .c(
            top + const P(4.6, 4.6),
            top + const P(4.4, 10.6),
            top + const P(0, 11.2),
          )
          .c(top + const P(-4.4, 10.6), top + const P(-4.6, 4.6), top)
          .z();
      return stud(at, 2.1) +
          line(
            'M${(at + const P(0, 1.8)).s} L${top.s}',
            0.8,
            color: 'url(#gold)',
            outline: goldOutline,
          ) +
          shape(drop.d, width: 1.2) +
          '<path d="M${(top + const P(-1.6, 4.4)).s} q0.4 -2 1.6 -2.6" fill="none" '
              'stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round" opacity="0.85"/>' +
          glint(top + P(side * 4.6, 8.6), 2);
    }),
  );
}

// ------------------------------------------------------------- bracelets

/// The bracelet sits on her left wrist (the arm that does not wave).
/// Inside the group, x runs across the arm and y down along it.
String onWrist(String body) =>
    '<g transform="translate(66.4 240.6) rotate(11) scale(1.3)">$body</g>';

/// The front half of the bracelet's ring.
const String wristArc = 'M-8.2 -1 Q0 4.2 8.2 -1';

double arcY(double x) {
  // Quadratic from (-8.2,-1) via (0,4.2) to (8.2,-1).
  final t = (x + 8.2) / 16.4;
  final u = 1 - t;
  return u * u * -1 + 2 * u * t * 4.2 + t * t * -1;
}

void bracelets() {
  // Round beads in the chosen color, with a white bead between.
  {
    final b = StringBuffer(
      line(wristArc, 0.6, color: '#FFFFFF', outline: '#C9B6C3'),
    );
    for (var i = 0; i < 7; i++) {
      final x = -7.4 + i * 14.8 / 6;
      final y = arcY(x);
      final white = i.isOdd;
      b.write(
        '<circle cx="${n(x)}" cy="${n(y)}" r="${white ? 1.7 : 2.2}" '
        'fill="${white ? '#FFFFFF' : 'url(#puff)'}" '
        'stroke="${white ? '#C9B6C3' : deep}" stroke-width="0.7"/>',
      );
      if (!white) {
        b.write(
          '<circle cx="${n(x - 0.7)}" cy="${n(y - 0.8)}" r="0.7" fill="#FFFFFF" opacity="0.9"/>',
        );
      }
    }
    b.write(glint(const P(4.6, -1.6), 1.8));
    write(itemDir, 'wristBeads', onWrist(b.toString()));
  }

  // A smooth shiny bangle.
  write(
    itemDir,
    'wristBangle',
    onWrist(
      line(wristArc, 2.6, color: 'url(#metal)') +
          '<path d="M-6.6 0.6 Q-2 3 2 3" fill="none" stroke="#FFFFFF" '
              'stroke-width="0.8" stroke-linecap="round" opacity="0.9"/>' +
          glint(const P(-3.6, 1.6), 2.2),
    ),
  );

  // A gold chain with little charms hanging from it.
  {
    final b = StringBuffer(
      line(wristArc, 1, color: 'url(#gold)', outline: goldOutline),
    );
    final charms = [
      (-5.0, heartD(const P(-5, 0), 4.2)),
      (0.0, starD(const P(0, 0), 2.6, ratio: 0.5)),
      (5.0, ''),
    ];
    for (final (x, d) in charms) {
      final y = arcY(x);
      final c = P(x, y + 3.4);
      b.write(
        line(
          'M${n(x)} ${n(y)} L${c.s}',
          0.5,
          color: '#FFE27A',
          outline: goldOutline,
        ),
      );
      if (d.isEmpty) {
        b.write(stud(c + const P(0, 0.6), 1.7));
      } else {
        b.write(
          '<g transform="translate(${n(c.x - x)} ${n(c.y + 1.2)})">'
          '${shape(d, width: 0.8)}</g>',
        );
      }
    }
    b.write(glint(const P(2.6, 7.4), 1.5));
    write(itemDir, 'wristCharm', onWrist(b.toString()));
  }

  // A woven friendship bracelet with a little knot.
  {
    final b = StringBuffer(line(wristArc, 3, color: base));
    b.write(
      '<path d="$wristArc" fill="none" stroke="#FFFFFF" stroke-width="3" '
      'stroke-dasharray="1.1 2.2" opacity="0.9"/>'
      '<path d="$wristArc" fill="none" stroke="#FFE066" stroke-width="3" '
      'stroke-dasharray="1.1 2.2" stroke-dashoffset="1.65" opacity="0.95"/>'
      '<path d="$wristArc" fill="none" stroke="$shade" stroke-width="0.6" '
      'transform="translate(0 1.3)" opacity="0.7"/>',
    );
    final k = P(6.2, arcY(6.2));
    b.write(
      '<circle cx="${n(k.x)}" cy="${n(k.y)}" r="1.6" fill="$light" stroke="$deep" stroke-width="0.8"/>'
      '${line('M${k.s} q0.6 3 -0.4 5', 0.7, color: light)}'
      '${line('M${k.s} q2 2.6 2.2 4.6', 0.7, color: '#FFE066', outline: '#C98A12')}',
    );
    write(itemDir, 'wristFriendship', onWrist(b.toString()));
  }
}

// --------------------------------------------------------------- glasses

/// Temples from the lens edge back toward the ears.
String temples(P lensEdge, {double width = 1.8}) {
  final d = 'M${lensEdge.s} L46 108.5 M${lensEdge.mirrored.s} L154 108.5';
  return line(d, width);
}

/// A frame drawn with both lenses. [lens] is the left lens.
String frames(
  PathB lens, {
  required double width,
  String lensFill = '#FFFFFF',
  double lensOpacity = 0.22,
}) {
  final both = '${lens.d} ${lens.mirroredD}';
  return '<path d="$both" fill="$lensFill" fill-opacity="$lensOpacity"/>'
      '<path d="$both" fill="none" stroke="$deep" stroke-width="${n(width + 2)}" stroke-linejoin="round"/>'
      '<path d="$both" fill="none" stroke="url(#metal)" stroke-width="${n(width)}" stroke-linejoin="round"/>';
}

String bridge(String d, {double width = 2.2}) => line(d, width);

/// Little white shine curves on clear lenses.
String clearShine(P a, P b, P c) {
  final d = 'M${a.s} Q${b.s} ${c.s}';
  final m = 'M${a.mirrored.s} Q${b.mirrored.s} ${c.mirrored.s}';
  return '<path d="$d $m" fill="none" stroke="#FFFFFF" stroke-width="2.2" '
      'stroke-linecap="round" opacity="0.8"/>';
}

PathB circleLens(P c, double r) => PathB()
    .m(P(c.x - r, c.y))
    .c(
      P(c.x - r, c.y - r * 0.552),
      P(c.x - r * 0.552, c.y - r),
      P(c.x, c.y - r),
    )
    .c(
      P(c.x + r * 0.552, c.y - r),
      P(c.x + r, c.y - r * 0.552),
      P(c.x + r, c.y),
    )
    .c(
      P(c.x + r, c.y + r * 0.552),
      P(c.x + r * 0.552, c.y + r),
      P(c.x, c.y + r),
    )
    .c(
      P(c.x - r * 0.552, c.y + r),
      P(c.x - r, c.y + r * 0.552),
      P(c.x - r, c.y),
    )
    .z();

PathB roundRectLens(Rect r, double radius) {
  final k = radius * 0.448;
  return PathB()
      .m(P(r.left + radius, r.top))
      .l(P(r.right - radius, r.top))
      .c(
        P(r.right - k, r.top),
        P(r.right, r.top + k),
        P(r.right, r.top + radius),
      )
      .l(P(r.right, r.bottom - radius))
      .c(
        P(r.right, r.bottom - k),
        P(r.right - k, r.bottom),
        P(r.right - radius, r.bottom),
      )
      .l(P(r.left + radius, r.bottom))
      .c(
        P(r.left + k, r.bottom),
        P(r.left, r.bottom - k),
        P(r.left, r.bottom - radius),
      )
      .l(P(r.left, r.top + radius))
      .c(P(r.left, r.top + k), P(r.left + k, r.top), P(r.left + radius, r.top))
      .z();
}

PathB heartLens(P c, double size) {
  final s = size / 2;
  final x = c.x, y = c.y;
  return PathB()
      .m(P(x, y + s * 0.9))
      .c(
        P(x - s * 1.4, y - s * 0.1),
        P(x - s * 0.7, y - s * 1.2),
        P(x, y - s * 0.45),
      )
      .c(
        P(x + s * 0.7, y - s * 1.2),
        P(x + s * 1.4, y - s * 0.1),
        P(x, y + s * 0.9),
      )
      .z();
}

PathB starLens(P c, double outer, double ratio) {
  final p = PathB();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? outer : outer * ratio;
    final a = -math.pi / 2 + i * math.pi / 5;
    final pt = P(c.x + math.cos(a) * r, c.y + math.sin(a) * r);
    i == 0 ? p.m(pt) : p.l(pt);
  }
  return p.z();
}

class Rect {
  const Rect(this.left, this.top, this.right, this.bottom);
  final double left, top, right, bottom;
}

const P leftEye = P(78, 115);

void eyeGlasses() {
  // Thin round wire frames.
  write(
    itemDir,
    'eyesWire',
    temples(const P(62.4, 112), width: 1.2) +
        bridge('M93.4 112 Q100 106.5 106.6 112', width: 1.3) +
        frames(circleLens(leftEye, 15.4), width: 1.5) +
        clearShine(const P(68, 106), const P(70.5, 102.5), const P(75, 101.8)),
  );

  // Cat-eye: the outer corners sweep up into little wings with gems.
  {
    final lens = PathB()
        .m(const P(55, 100))
        .c(const P(66, 101.5), const P(86, 100), const P(93.5, 107))
        .c(const P(95.5, 118), const P(90, 128.5), const P(79, 129.5))
        .c(const P(68, 130), const P(61, 123), const P(60, 112))
        .q(const P(58.5, 105), const P(55, 100))
        .z();
    write(
      itemDir,
      'eyesCatEye',
      temples(const P(58.5, 106)) +
          bridge('M93.5 110 Q100 105.5 106.5 110') +
          frames(lens, width: 2.6) +
          clearShine(const P(66, 108), const P(68, 104.5), const P(73, 104)) +
          stud(const P(57.5, 102.5), 1.6) +
          stud(const P(142.5, 102.5), 1.6) +
          glint(const P(54.6, 98.4), 1.8) +
          glint(const P(145.4, 98.4), 1.8),
    );
  }

  // Heart-shaped frames with clear lenses.
  write(
    itemDir,
    'eyesHeartFrame',
    temples(const P(59.5, 110)) +
        bridge('M94 110 Q100 106 106 110') +
        frames(heartLens(const P(78, 116.5), 36), width: 2.6) +
        clearShine(const P(66, 110), const P(67.5, 105), const P(72, 104.5)),
  );

  // Star-shaped frames with clear lenses.
  write(
    itemDir,
    'eyesStarFrame',
    temples(const P(60, 109)) +
        bridge('M93.6 111.5 Q100 107 106.4 111.5') +
        frames(starLens(const P(78, 116.5), 21, 0.56), width: 2.6) +
        clearShine(const P(70, 112), const P(72, 108.5), const P(75.5, 107.5)),
  );

  // Big cute frames with a heart on each corner.
  write(
    itemDir,
    'eyesBig',
    temples(const P(56.5, 108), width: 2.4) +
        bridge('M95.5 111 Q100 107.5 104.5 111', width: 3) +
        frames(roundRectLens(const Rect(56.5, 97.5, 96, 133), 13), width: 4.2) +
        clearShine(const P(63, 112), const P(63.5, 105), const P(70, 103.5)) +
        shape(heartD(const P(58.5, 99), 6.4), fill: light, width: 1) +
        shape(heartD(const P(141.5, 99), 6.4), fill: light, width: 1),
  );
}

/// Shiny tinted lenses: a gradient of the frame's color, darkened, with
/// a white reflection streak across each lens.
String tintedLenses(PathB lens) {
  final both = '${lens.d} ${lens.mirroredD}';
  return '<path d="$both" fill="url(#tint)" fill-opacity="0.9"/>'
      '<path d="$both" fill="url(#dark)"/>'
      '<g clip-path="url(#lens)">'
      '<path d="M54 138 L82 88 L91 88 L63 138 Z M68 140 L95 92 L98 92 L71 140 Z" fill="#FFFFFF" opacity="0.42"/>'
      '<path d="M110 140 L138 90 L147 90 L119 140 Z M124 140 L151 92 L154 92 L127 140 Z" fill="#FFFFFF" opacity="0.32"/>'
      '<path d="$both" fill="none" stroke="#FFFFFF" stroke-width="3" opacity="0.18" '
      'transform="translate(0 2.2)"/>'
      '</g>';
}

String tintDefs(PathB lens) =>
    '<linearGradient id="tint" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="$deep"/><stop offset="0.55" stop-color="$shade"/>'
    '<stop offset="1" stop-color="$light"/></linearGradient>'
    '<linearGradient id="dark" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="#1C1030" stop-opacity="0.62"/>'
    '<stop offset="1" stop-color="#1C1030" stop-opacity="0.12"/></linearGradient>'
    '<clipPath id="lens"><path d="${lens.d} ${lens.mirroredD}"/></clipPath>';

void sunglasses() {
  void sun(
    String name,
    PathB lens, {
    required String extra,
    required double width,
    String after = '',
  }) {
    write(
      itemDir,
      name,
      extra +
          tintedLenses(lens) +
          '<path d="${lens.d} ${lens.mirroredD}" fill="none" stroke="$deep" '
              'stroke-width="${n(width + 2)}" stroke-linejoin="round"/>'
              '<path d="${lens.d} ${lens.mirroredD}" fill="none" stroke="url(#metal)" '
              'stroke-width="${n(width)}" stroke-linejoin="round"/>' +
          after,
      defs: tintDefs(lens),
    );
  }

  // Aviators: teardrop lenses, a thin frame and a double bridge.
  sun(
    'eyesSunAviator',
    PathB()
        .m(const P(58, 104.5))
        .q(const P(77, 99.5), const P(94, 104.5))
        .q(const P(96.5, 120), const P(87.5, 129))
        .q(const P(77, 137), const P(66, 130.5))
        .q(const P(56.5, 122), const P(58, 104.5))
        .z(),
    width: 1.6,
    extra:
        temples(const P(58.4, 106), width: 1.3) +
        line('M93.5 104.4 Q100 101.5 106.5 104.4', 1.4) +
        line('M94.6 110 Q100 107.4 105.4 110', 1.2),
    after: glint(const P(90.5, 106), 2.2),
  );

  // Big heart lenses.
  sun(
    'eyesSunHeart',
    heartLens(const P(78, 117), 40),
    width: 2.4,
    extra: temples(const P(57.5, 110)) + bridge('M95 110 Q100 106 105 110'),
    after: glint(const P(64, 104.5), 2.2),
  );

  // Star lenses.
  sun(
    'eyesSunStar',
    starLens(const P(78, 117), 22.5, 0.56),
    width: 2.4,
    extra:
        temples(const P(59, 109.5)) + bridge('M94.6 112 Q100 107.6 105.4 112'),
    after: glint(const P(78, 92), 2.2),
  );

  // Oversized movie-star frames.
  sun(
    'eyesSunBig',
    roundRectLens(const Rect(53.5, 95.5, 96.5, 135.5), 16),
    width: 4.4,
    extra:
        temples(const P(54, 106), width: 2.6) +
        bridge('M96.5 110 Q100 107 103.5 110', width: 3.4),
    after:
        '<path d="M59 100.5 Q62 97.6 67 97.4 M141 100.5 Q138 97.6 133 97.4" '
        'fill="none" stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round" opacity="0.8"/>',
  );

  // Sporty wrap-around shades: one big curved lens with a racing stripe.
  {
    // The left half of the shield; its mirror image makes the right half.
    final half = PathB()
        .m(const P(100, 100.5))
        .q(const P(75, 98.5), const P(51, 103))
        .q(const P(50, 118), const P(60, 127.5))
        .q(const P(73, 135), const P(86, 129))
        .q(const P(95, 124.5), const P(100, 118.5))
        .z();
    write(
      itemDir,
      'eyesSunSport',
      temples(const P(51.5, 105), width: 2.6) +
          tintedLenses(half) +
          '<path d="M51 103 Q100 94.5 149 103" fill="none" stroke="$deep" '
              'stroke-width="5.6" stroke-linecap="round"/>'
              '<path d="M51 103 Q100 94.5 149 103" fill="none" stroke="url(#metal)" '
              'stroke-width="3.6" stroke-linecap="round"/>'
              '<path d="M56 101.6 Q100 94.6 144 101.6" fill="none" stroke="#FFFFFF" '
              'stroke-width="0.9" stroke-linecap="round" opacity="0.75"/>' +
          '<path d="${half.d} ${half.mirroredD}" fill="none" stroke="$deep" '
              'stroke-width="1.4" stroke-linejoin="round" opacity="0.8"/>' +
          line('M46.5 107 L53 104.8', 2.2, color: '#FFFFFF') +
          line('M153.5 107 L147 104.8', 2.2, color: '#FFFFFF') +
          glint(const P(128, 104.5), 2.4),
      defs: tintDefs(half),
    );
  }
}

// ----------------------------------------------------------------- icons

void icons() {
  // A necklace with a heart pendant.
  File('$iconDir/jewelry.svg')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">'
      '<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">'
      '<stop offset="0" stop-color="#FFF3B0"/><stop offset="0.5" stop-color="#FFD84D"/>'
      '<stop offset="1" stop-color="#E0A81E"/></linearGradient>'
      '<linearGradient id="h" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0" stop-color="#FFFFFF"/><stop offset="0.25" stop-color="#FFC2DF"/>'
      '<stop offset="0.6" stop-color="#FF5C9A"/><stop offset="1" stop-color="#D62F6E"/></linearGradient></defs>'
      '<path d="M18 16 C14 52 34 64 50 64 C66 64 86 52 82 16" fill="none" stroke="#B07A12" '
      'stroke-width="7" stroke-linecap="round"/>'
      '<path d="M18 16 C14 52 34 64 50 64 C66 64 86 52 82 16" fill="none" stroke="url(#g)" '
      'stroke-width="4" stroke-linecap="round"/>'
      '<path d="M18 16 C14 52 34 64 50 64 C66 64 86 52 82 16" fill="none" stroke="#FFF8D6" '
      'stroke-width="1.4" stroke-dasharray="2 4" stroke-linecap="round"/>'
      '<circle cx="50" cy="66" r="4" fill="none" stroke="#B07A12" stroke-width="3.4"/>'
      '<path d="${heartD(const P(50, 80), 30)}" fill="url(#h)" stroke="#A3245A" stroke-width="3" stroke-linejoin="round"/>'
      '<path d="${heartD(const P(45, 75), 10)}" fill="#FFFFFF" opacity="0.55"/>'
      '${glint(const P(64, 70), 6)}${glint(const P(30, 44), 4, opacity: 0.9)}'
      '</svg>\n',
    );

  // Sunglasses with shiny pink lenses.
  File('$iconDir/glasses.svg').writeAsStringSync(
    '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">'
    '<defs><linearGradient id="t" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="#3A1E4E"/><stop offset="0.6" stop-color="#8A3A8E"/>'
    '<stop offset="1" stop-color="#E27BC4"/></linearGradient>'
    '<clipPath id="c"><rect x="8" y="34" width="36" height="32" rx="13"/>'
    '<rect x="56" y="34" width="36" height="32" rx="13"/></clipPath></defs>'
    '<path d="M44 44 Q50 38 56 44" fill="none" stroke="#A3245A" stroke-width="7" stroke-linecap="round"/>'
    '<path d="M44 44 Q50 38 56 44" fill="none" stroke="#FF8FC7" stroke-width="4" stroke-linecap="round"/>'
    '<g fill="url(#t)"><rect x="8" y="34" width="36" height="32" rx="13"/>'
    '<rect x="56" y="34" width="36" height="32" rx="13"/></g>'
    '<g clip-path="url(#c)" fill="#FFFFFF"><path d="M8 70 L30 30 L38 30 L16 70 Z M60 70 L82 30 L90 30 L68 70 Z" opacity="0.5"/>'
    '<path d="M20 72 L42 32 L45 32 L23 72 Z M72 72 L94 32 L97 32 L75 72 Z" opacity="0.35"/></g>'
    '<g fill="none" stroke="#A3245A" stroke-width="7"><rect x="8" y="34" width="36" height="32" rx="13"/>'
    '<rect x="56" y="34" width="36" height="32" rx="13"/></g>'
    '<g fill="none" stroke="#FF8FC7" stroke-width="4"><rect x="8" y="34" width="36" height="32" rx="13"/>'
    '<rect x="56" y="34" width="36" height="32" rx="13"/></g>'
    '<path d="M14 38 Q17 35.5 22 35.5 M62 38 Q65 35.5 70 35.5" fill="none" stroke="#FFFFFF" '
    'stroke-width="2" stroke-linecap="round" opacity="0.9"/>'
    '${glint(const P(84, 30), 6)}${glint(const P(14, 74), 4, opacity: 0.85)}'
    '</svg>\n',
  );
}

void main() {
  necklaces();
  earrings();
  bracelets();
  eyeGlasses();
  sunglasses();
  icons();
  stdout.writeln('Wrote jewelry, glasses and icon art.');
}
