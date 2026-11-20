import 'dart:math';
import 'dart:ui';

import '../data/game_config.dart';

// =============================================================================
//  Results of the activities (Makeup, Hair Salon, Nails).
//
//  Tools paint "spots": every paintable area (the lips, the hair, each nail)
//  is covered by a fixed list of small spots (a SpotZone). A finger only
//  paints the spots it touches, and the result is stored as a short string
//  with one letter per spot (a SpotGrid), so saved looks stay small.
// =============================================================================

/// Which spots of a [SpotZone] are painted, and with which palette color.
///
/// Stored as text: `.` is an empty spot, `a` is color 0, `b` color 1...
/// Trailing empty spots are left out, so every empty grid is `''`.
class SpotGrid {
  const SpotGrid._(this.cells);

  factory SpotGrid(String cells) {
    var end = cells.length;
    while (end > 0 && cells.codeUnitAt(end - 1) == _empty) {
      end--;
    }
    return end == 0 ? none : SpotGrid._(cells.substring(0, end));
  }

  /// [length] spots, all painted with [value].
  factory SpotGrid.filled(int length, int value) =>
      SpotGrid(String.fromCharCode(_a + value) * length);

  static const SpotGrid none = SpotGrid._('');
  static const int _empty = 46; // '.'
  static const int _a = 97; // 'a'
  static const int maxValue = 25;

  final String cells;

  bool get isEmpty => cells.isEmpty;

  /// The color at spot [i], or null if it is empty.
  int? operator [](int i) {
    if (i < 0 || i >= cells.length) return null;
    final c = cells.codeUnitAt(i);
    return c == _empty ? null : c - _a;
  }

  /// Paints [spots] with [value] (or empties them when [value] is null).
  SpotGrid set(Iterable<int> spots, int? value) {
    final list = spots.toList();
    if (list.isEmpty) return this;
    final length = max(cells.length, list.reduce(max) + 1);
    final codes = List<int>.generate(
      length,
      (i) => i < cells.length ? cells.codeUnitAt(i) : _empty,
    );
    final code = value == null ? _empty : _a + value;
    var changed = false;
    for (final i in list) {
      if (i < 0) continue;
      if (codes[i] != code) {
        codes[i] = code;
        changed = true;
      }
    }
    return changed ? SpotGrid(String.fromCharCodes(codes)) : this;
  }

  /// Empties every spot for which [clear] is true.
  SpotGrid clearWhere(bool Function(int spot) clear) =>
      set([for (var i = 0; i < cells.length; i++) i].where(clear), null);

  /// How many of [spots] are painted.
  int countPainted(Iterable<int> spots) =>
      spots.where((i) => this[i] != null).length;

  /// The color used most in [spots], or null if none is painted.
  int? mainColor(Iterable<int> spots) {
    final counts = <int, int>{};
    for (final i in spots) {
      final v = this[i];
      if (v != null) counts[v] = (counts[v] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// Reads a saved grid. Anything broken becomes an empty grid.
  static SpotGrid read(Object? raw, int length, {int maxColor = maxValue}) {
    if (raw is! String || raw.length > length) return none;
    for (final c in raw.codeUnits) {
      if (c != _empty && (c < _a || c > _a + maxColor)) return none;
    }
    return SpotGrid(raw);
  }

  @override
  bool operator ==(Object other) => other is SpotGrid && other.cells == cells;

  @override
  int get hashCode => cells.hashCode;

  @override
  String toString() => 'SpotGrid($cells)';
}

/// A paintable area: a fixed list of spot centers, split into regions
/// (for example the left and right cheek).
class SpotZone {
  SpotZone(this.spots, this.regionOf, this.spacing)
    : regionCount = regionOf.isEmpty ? 0 : regionOf.reduce(max) + 1;

  /// Spots on a [cols] x [rows] grid over [area]. [regionAt] says which
  /// region a spot belongs to, or null to leave that spot out.
  factory SpotZone.grid(
    Rect area,
    int cols,
    int rows,
    int? Function(Offset p) regionAt,
  ) {
    final spots = <Offset>[];
    final regions = <int>[];
    final dx = area.width / cols;
    final dy = area.height / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final p = Offset(area.left + (c + 0.5) * dx, area.top + (r + 0.5) * dy);
        final region = regionAt(p);
        if (region == null) continue;
        spots.add(p);
        regions.add(region);
      }
    }
    return SpotZone(spots, regions, max(dx, dy));
  }

  final List<Offset> spots;
  final List<int> regionOf;
  final int regionCount;

  /// Distance between neighbor spots.
  final double spacing;

  int get length => spots.length;

  late final List<List<int>> regions = [
    for (var r = 0; r < regionCount; r++)
      [
        for (var i = 0; i < spots.length; i++)
          if (regionOf[i] == r) i,
      ],
  ];

  /// The spots a round tool of [radius] touches while moving [from] -> [to].
  Set<int> touched(Offset from, Offset to, double radius) {
    final hit = <int>{};
    final distance = (to - from).distance;
    final steps = max(1, (distance / (radius * 0.5)).ceil());
    final r2 = radius * radius;
    for (var s = 0; s <= steps; s++) {
      final p = Offset.lerp(from, to, s / steps)!;
      for (var i = 0; i < spots.length; i++) {
        if ((spots[i] - p).distanceSquared <= r2) hit.add(i);
      }
    }
    return hit;
  }

  /// Fills the rest of every region that is at least [threshold] painted,
  /// so a nearly finished lipstick or nail looks neat. Returns the new grid
  /// and the regions that were just finished.
  (SpotGrid, List<int>) complete(
    SpotGrid grid,
    int value, {
    double threshold = 0.6,
  }) {
    var out = grid;
    final finished = <int>[];
    for (var r = 0; r < regionCount; r++) {
      final cells = regions[r];
      final painted = grid.countPainted(cells);
      if (painted == cells.length || painted < cells.length * threshold) {
        continue;
      }
      out = out.set(cells.where((i) => grid[i] == null), value);
      finished.add(r);
    }
    return (out, finished);
  }

  /// The middle of region [r].
  Offset regionCenter(int r) {
    final cells = regions[r];
    var sum = Offset.zero;
    for (final i in cells) {
      sum += spots[i];
    }
    return cells.isEmpty ? Offset.zero : sum / cells.length.toDouble();
  }
}

bool _inEllipse(Offset p, Offset c, double rx, double ry) {
  final x = (p.dx - c.dx) / rx;
  final y = (p.dy - c.dy) / ry;
  return x * x + y * y <= 1;
}

// ------------------------------------------------------------ face (makeup)
//
// All face positions are in "doll space" (see lib/art/doll_art.dart).

const Offset kLeftEye = Offset(78, 115);
const Offset kRightEye = Offset(122, 115);
const Offset kLeftCheek = Offset(63, 133);
const Offset kRightCheek = Offset(137, 133);
const Offset kMouth = Offset(100, 139);

/// The face where stickers can go.
const Offset kFaceCenter = Offset(100, 110);
const double kFaceRadiusX = 56;
const double kFaceRadiusY = 50;

final SpotZone lipsZone = SpotZone.grid(
  const Rect.fromLTRB(86, 130, 114, 152),
  7,
  5,
  (p) => _inEllipse(p, kMouth + const Offset(0, 1), 14, 11.5) ? 0 : null,
);

final SpotZone blushZone = SpotZone.grid(
  const Rect.fromLTRB(46, 120, 154, 146),
  18,
  4,
  (p) => _inEllipse(p, kLeftCheek, 15.5, 11)
      ? 0
      : (_inEllipse(p, kRightCheek, 15.5, 11) ? 1 : null),
);

final SpotZone shadowZone = SpotZone.grid(
  const Rect.fromLTRB(56, 92, 144, 124),
  18,
  6,
  (p) => _inEllipse(p, const Offset(77.5, 108), 19, 14)
      ? 0
      : (_inEllipse(p, const Offset(122.5, 108), 19, 14) ? 1 : null),
);

/// A sticker on the face.
enum StickerKind { star, heart, butterfly }

class FaceSticker {
  const FaceSticker(this.kind, this.position);

  final StickerKind kind;

  /// Doll space.
  final Offset position;

  @override
  bool operator ==(Object other) =>
      other is FaceSticker && other.kind == kind && other.position == position;

  @override
  int get hashCode => Object.hash(kind, position);
}

/// Is [p] on the face (where stickers stick)?
bool onFace(Offset p) => _inEllipse(p, kFaceCenter, kFaceRadiusX, kFaceRadiusY);

/// Keeps a sticker inside the drawn face area.
Offset clampToFace(Offset p) => Offset(
  p.dx.clamp(56.0, 144.0).toDouble(),
  p.dy.clamp(92.0, 150.0).toDouble(),
);

/// Which eye (0 left, 1 right) [p] is near, or null.
int? eyeAt(Offset p) {
  if (_inEllipse(p, kLeftEye + const Offset(-2, -4), 22, 18)) return 0;
  if (_inEllipse(p, kRightEye + const Offset(2, -4), 22, 18)) return 1;
  return null;
}

/// Everything the Makeup activity put on the face.
class Makeup {
  const Makeup({
    this.lips = SpotGrid.none,
    this.blush = SpotGrid.none,
    this.shadow = SpotGrid.none,
    this.lashLeft = 0,
    this.lashRight = 0,
    this.stickers = const [],
  });

  static const Makeup none = Makeup();

  /// Palette indexes: [lipstickColors], [blushColors], [eyeshadowColors].
  final SpotGrid lips;
  final SpotGrid blush;
  final SpotGrid shadow;

  /// Eyelash style per eye, 0 = none, 1..[lashStyleCount].
  final int lashLeft;
  final int lashRight;
  final List<FaceSticker> stickers;

  bool get isEmpty =>
      lips.isEmpty &&
      blush.isEmpty &&
      shadow.isEmpty &&
      lashLeft == 0 &&
      lashRight == 0 &&
      stickers.isEmpty;

  Makeup copyWith({
    SpotGrid? lips,
    SpotGrid? blush,
    SpotGrid? shadow,
    int? lashLeft,
    int? lashRight,
    List<FaceSticker>? stickers,
  }) => Makeup(
    lips: lips ?? this.lips,
    blush: blush ?? this.blush,
    shadow: shadow ?? this.shadow,
    lashLeft: lashLeft ?? this.lashLeft,
    lashRight: lashRight ?? this.lashRight,
    stickers: stickers ?? this.stickers,
  );

  /// Adds a sticker (the oldest goes if there are too many).
  Makeup addSticker(FaceSticker s) {
    final next = [...stickers, s];
    while (next.length > maxFaceStickers) {
      next.removeAt(0);
    }
    return copyWith(stickers: List.unmodifiable(next));
  }

  /// A short text that changes whenever the makeup changes (for caches).
  String get key => isEmpty
      ? ''
      : '${lips.cells}/${blush.cells}/${shadow.cells}/$lashLeft$lashRight/'
            '${stickers.map((s) => '${s.kind.index}@${s.position.dx.round()},${s.position.dy.round()}').join(';')}';

  Map<String, dynamic> toJson() => {
    if (!lips.isEmpty) 'lips': lips.cells,
    if (!blush.isEmpty) 'blush': blush.cells,
    if (!shadow.isEmpty) 'shadow': shadow.cells,
    if (lashLeft != 0 || lashRight != 0) 'lashes': [lashLeft, lashRight],
    if (stickers.isNotEmpty)
      'stickers': [
        for (final s in stickers)
          [
            s.kind.index,
            double.parse(s.position.dx.toStringAsFixed(1)),
            double.parse(s.position.dy.toStringAsFixed(1)),
          ],
      ],
  };

  /// Reads saved makeup; broken parts are skipped.
  factory Makeup.fromJson(Object? json) {
    if (json is! Map) return none;
    int lash(int i) {
      final l = json['lashes'];
      if (l is List && l.length == 2 && l[i] is int) {
        return (l[i] as int).clamp(0, lashStyleCount);
      }
      return 0;
    }

    final stickers = <FaceSticker>[];
    final raw = json['stickers'];
    if (raw is List) {
      for (final s in raw) {
        if (s is! List || s.length != 3) continue;
        final k = s[0], x = s[1], y = s[2];
        if (k is! int || k < 0 || k >= StickerKind.values.length) continue;
        if (x is! num || y is! num) continue;
        stickers.add(
          FaceSticker(
            StickerKind.values[k],
            clampToFace(Offset(x.toDouble(), y.toDouble())),
          ),
        );
        if (stickers.length >= maxFaceStickers) break;
      }
    }
    return Makeup(
      lips: SpotGrid.read(
        json['lips'],
        lipsZone.length,
        maxColor: lipstickColors.length - 1,
      ),
      blush: SpotGrid.read(
        json['blush'],
        blushZone.length,
        maxColor: blushColors.length - 1,
      ),
      shadow: SpotGrid.read(
        json['shadow'],
        shadowZone.length,
        maxColor: eyeshadowColors.length - 1,
      ),
      lashLeft: lash(0),
      lashRight: lash(1),
      stickers: List.unmodifiable(stickers),
    );
  }

  /// A random pretty makeup look for "Surprise me".
  factory Makeup.random(Random rnd) {
    SpotGrid full(SpotZone zone, int colors) =>
        SpotGrid.filled(zone.length, rnd.nextInt(colors));
    final lash = rnd.nextBool() ? 1 + rnd.nextInt(lashStyleCount) : 0;
    const spots = [
      Offset(64, 128),
      Offset(137, 126),
      Offset(140, 101),
      Offset(60, 104),
    ];
    final stickers = <FaceSticker>[
      if (rnd.nextInt(3) == 0)
        FaceSticker(
          StickerKind.values[rnd.nextInt(StickerKind.values.length)],
          spots[rnd.nextInt(spots.length)],
        ),
    ];
    return Makeup(
      lips: rnd.nextInt(4) > 0
          ? full(lipsZone, lipstickColors.length)
          : SpotGrid.none,
      blush: rnd.nextBool()
          ? full(blushZone, blushColors.length)
          : SpotGrid.none,
      shadow: rnd.nextBool()
          ? full(shadowZone, eyeshadowColors.length)
          : SpotGrid.none,
      lashLeft: lash,
      lashRight: lash,
      stickers: stickers,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Makeup &&
      other.lips == lips &&
      other.blush == blush &&
      other.shadow == shadow &&
      other.lashLeft == lashLeft &&
      other.lashRight == lashRight &&
      _listEquals(other.stickers, stickers);

  @override
  int get hashCode => Object.hash(
    lips,
    blush,
    shadow,
    lashLeft,
    lashRight,
    Object.hashAll(stickers),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ------------------------------------------------------------ hair salon
//
// The salon works on the long hair (see `salonHairId`). Each side (0 = her
// right, on the left of the screen; 1 = the other side) can be cut and
// curled on its own.

/// How many lengths the hair can have: long, shoulder, short.
const int hairLengthCount = 3;

/// Where the hair ends for each length: the locks in front of the
/// shoulders, and the hair behind her.
const List<double> kFrontHems = [208, 174, 142];
const List<double> kBackHems = [280, 214, 162];

/// Curls bounce up a little.
const double kCurlLift = 10;

/// Half the width of the long hair (behind her) at height [y].
double _hairHalfWidth(double y) {
  if (y < 36) return 0;
  if (y < 106) {
    final t = (106 - y) / 72;
    return 68 * sqrt(max(0, 1 - t * t));
  }
  return 68 - max(0, y - 160) * 0.08;
}

bool _inBackHair(Offset p) =>
    (p.dx - 100).abs() <= _hairHalfWidth(p.dy) && p.dy <= kBackHems[0];

/// Spots covering the whole long hair.
final SpotZone hairZone = SpotZone.grid(
  const Rect.fromLTRB(26, 30, 174, 286),
  12,
  20,
  (p) => _inBackHair(p) ? 0 : null,
);

/// The side of the hair at [p].
int hairSide(Offset p) => p.dx < 100 ? 0 : 1;

/// The Hair Salon result.
class SalonHair {
  const SalonHair({
    this.cutLeft = 0,
    this.cutRight = 0,
    this.curlLeft = false,
    this.curlRight = false,
    this.dye = SpotGrid.none,
    this.shine = SpotGrid.none,
  });

  static const SalonHair natural = SalonHair();

  /// Length per side: 0 long ... [hairLengthCount] - 1 short.
  final int cutLeft;
  final int cutRight;
  final bool curlLeft;
  final bool curlRight;

  /// Spray paint on [hairZone] (indexes into [hairDyeColors]).
  final SpotGrid dye;

  /// Shiny spots after washing and drying ([hairZone], value 0).
  final SpotGrid shine;

  bool get isNatural => this == natural;

  int cut(int side) => side == 0 ? cutLeft : cutRight;
  bool curl(int side) => side == 0 ? curlLeft : curlRight;

  /// Where the hair behind her ends on [side].
  double backHem(int side) =>
      kBackHems[cut(side)] - (curl(side) ? kCurlLift : 0);

  /// Where the lock in front of her shoulder ends on [side].
  double frontHem(int side) =>
      kFrontHems[cut(side)] - (curl(side) ? kCurlLift : 0);

  /// Is there hair to see at [p] (not her face or body)?
  bool hairAt(Offset p) {
    final side = hairSide(p);
    final drape =
        p.dy >= 96 &&
        p.dy <= frontHem(side) &&
        (side == 0 ? p.dx >= 30 && p.dx <= 57 : p.dx >= 143 && p.dx <= 170);
    if (drape) return true;
    if (!_inBackHair(p) || p.dy > backHem(side)) return false;
    final face = p.dy > 88 && _inEllipse(p, const Offset(100, 108), 56, 51);
    final body =
        (p.dx > 74 && p.dx < 126 && p.dy > 164) ||
        (p.dx > 91 && p.dx < 109 && p.dy > 148);
    return !face && !body;
  }

  SalonHair copyWith({
    int? cutLeft,
    int? cutRight,
    bool? curlLeft,
    bool? curlRight,
    SpotGrid? dye,
    SpotGrid? shine,
  }) => SalonHair(
    cutLeft: cutLeft ?? this.cutLeft,
    cutRight: cutRight ?? this.cutRight,
    curlLeft: curlLeft ?? this.curlLeft,
    curlRight: curlRight ?? this.curlRight,
    dye: dye ?? this.dye,
    shine: shine ?? this.shine,
  );

  SalonHair withCut(int side, int length) =>
      side == 0 ? copyWith(cutLeft: length) : copyWith(cutRight: length);

  SalonHair withCurl(int side, bool curly) =>
      side == 0 ? copyWith(curlLeft: curly) : copyWith(curlRight: curly);

  String get key => isNatural
      ? ''
      : '$cutLeft$cutRight${curlLeft ? 1 : 0}${curlRight ? 1 : 0}/'
            '${dye.cells}/${shine.cells}';

  Map<String, dynamic> toJson() => {
    if (cutLeft != 0 || cutRight != 0) 'cut': [cutLeft, cutRight],
    if (curlLeft || curlRight) 'curl': [curlLeft, curlRight],
    if (!dye.isEmpty) 'dye': dye.cells,
    if (!shine.isEmpty) 'shine': shine.cells,
  };

  factory SalonHair.fromJson(Object? json) {
    if (json is! Map) return natural;
    int cut(int i) {
      final c = json['cut'];
      if (c is List && c.length == 2 && c[i] is int) {
        return (c[i] as int).clamp(0, hairLengthCount - 1);
      }
      return 0;
    }

    bool curl(int i) {
      final c = json['curl'];
      return c is List && c.length == 2 && c[i] == true;
    }

    return SalonHair(
      cutLeft: cut(0),
      cutRight: cut(1),
      curlLeft: curl(0),
      curlRight: curl(1),
      dye: SpotGrid.read(
        json['dye'],
        hairZone.length,
        maxColor: hairDyeColors.length - 1,
      ),
      shine: SpotGrid.read(json['shine'], hairZone.length, maxColor: 0),
    );
  }

  /// A random salon hairdo for "Surprise me".
  factory SalonHair.random(Random rnd) {
    final cut = rnd.nextInt(hairLengthCount);
    final odd = rnd.nextInt(5) == 0;
    final curly = rnd.nextBool();
    var dye = SpotGrid.none;
    switch (rnd.nextInt(6)) {
      case 0 || 1:
        dye = SpotGrid.filled(
          hairZone.length,
          rnd.nextInt(hairDyeColors.length),
        );
      case 2:
        // Two colored streaks.
        final color = rnd.nextInt(hairDyeColors.length);
        dye = dye.set([
          for (var i = 0; i < hairZone.length; i++)
            if ((hairZone.spots[i].dx - 52).abs() < 9 ||
                (hairZone.spots[i].dx - 148).abs() < 9)
              i,
        ], color);
    }
    return SalonHair(
      cutLeft: cut,
      cutRight: odd ? rnd.nextInt(hairLengthCount) : cut,
      curlLeft: curly,
      curlRight: curly,
      dye: dye,
      shine: rnd.nextBool()
          ? SpotGrid.filled(hairZone.length, 0)
          : SpotGrid.none,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SalonHair &&
      other.cutLeft == cutLeft &&
      other.cutRight == cutRight &&
      other.curlLeft == curlLeft &&
      other.curlRight == curlRight &&
      other.dye == dye &&
      other.shine == shine;

  @override
  int get hashCode =>
      Object.hash(cutLeft, cutRight, curlLeft, curlRight, dye, shine);
}

// ------------------------------------------------------------------ nails
//
// The Nails close-up shows one big hand in its own "hand space"
// (300 x 360, wrist at the bottom, back of the hand towards us).

/// One finger: from its base to its round tip.
class Finger {
  const Finger(this.base, this.tip, this.width);

  final Offset base;
  final Offset tip;
  final double width;

  Offset get direction {
    final d = tip - base;
    return d / d.distance;
  }

  /// Turns the finger's own "up" (0, -1) into [direction].
  double get angle => atan2(direction.dx, -direction.dy);

  /// Nail size: [nailWidth] across, [nailLength] along the finger.
  double get nailWidth => width * 0.66;
  double get nailLength => width * 0.84;

  /// The middle of the nail.
  Offset get nailCenter => tip - direction * (width * 0.56 + 1);

  /// Turns a point on the nail (x across, y along, negative towards the
  /// tip) into hand space.
  Offset nailPoint(Offset local) {
    final a = angle;
    final c = cos(a), s = sin(a);
    return nailCenter +
        Offset(local.dx * c - local.dy * s, local.dx * s + local.dy * c);
  }
}

/// Pinky, ring, middle, index finger and thumb.
const List<Finger> kFingers = [
  Finger(Offset(98, 222), Offset(80, 128), 31),
  Finger(Offset(130, 206), Offset(121, 90), 34),
  Finger(Offset(165, 202), Offset(166, 74), 35),
  Finger(Offset(200, 208), Offset(213, 94), 34),
  Finger(Offset(222, 270), Offset(276, 196), 37),
];

/// The hand as shown on the Nails screen.
const Rect kHandSpace = Rect.fromLTRB(0, 0, 300, 360);

/// Spots on every nail (region = which nail).
final SpotZone nailZone = () {
  final spots = <Offset>[];
  final regions = <int>[];
  for (var n = 0; n < kFingers.length; n++) {
    final f = kFingers[n];
    const cols = 3, rows = 4;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        spots.add(
          f.nailPoint(
            Offset(
              (c - 1) * f.nailWidth / cols,
              (r + 0.5) / rows * f.nailLength - f.nailLength / 2,
            ),
          ),
        );
        regions.add(n);
      }
    }
  }
  return SpotZone(spots, regions, kFingers[0].nailWidth / 3);
}();

/// The nail under [p], or null.
int? nailAt(Offset p, {double slack = 1}) {
  int? best;
  var bestDistance = double.infinity;
  for (var i = 0; i < kFingers.length; i++) {
    final f = kFingers[i];
    final d = (p - f.nailCenter).distance;
    if (d < f.width * 0.75 * slack && d < bestDistance) {
      best = i;
      bestDistance = d;
    }
  }
  return best;
}

/// Decorations for nails.
enum NailDeco { gem, heart, star, flower }

/// The Nails result: polish spots, and per nail a decoration, shine and
/// whether it was filed.
class NailSet {
  const NailSet({
    this.polish = SpotGrid.none,
    this.deco = SpotGrid.none,
    this.shine = SpotGrid.none,
    this.filed = SpotGrid.none,
  });

  static const NailSet none = NailSet();

  /// [nailZone] spots, indexes into [nailColors].
  final SpotGrid polish;

  /// One spot per nail: a [NailDeco] index.
  final SpotGrid deco;

  /// One spot per nail: 0 when the dryer made it shine.
  final SpotGrid shine;

  /// One spot per nail: 0 when it was filed.
  final SpotGrid filed;

  bool get isEmpty => this == none;

  /// The main polish color of nail [n], or null.
  int? colorOf(int n) => polish.mainColor(nailZone.regions[n]);

  NailSet copyWith({
    SpotGrid? polish,
    SpotGrid? deco,
    SpotGrid? shine,
    SpotGrid? filed,
  }) => NailSet(
    polish: polish ?? this.polish,
    deco: deco ?? this.deco,
    shine: shine ?? this.shine,
    filed: filed ?? this.filed,
  );

  String get key => isEmpty
      ? ''
      : '${polish.cells}/${deco.cells}/${shine.cells}/${filed.cells}';

  Map<String, dynamic> toJson() => {
    if (!polish.isEmpty) 'polish': polish.cells,
    if (!deco.isEmpty) 'deco': deco.cells,
    if (!shine.isEmpty) 'shine': shine.cells,
    if (!filed.isEmpty) 'filed': filed.cells,
  };

  factory NailSet.fromJson(Object? json) {
    if (json is! Map) return none;
    final n = kFingers.length;
    return NailSet(
      polish: SpotGrid.read(
        json['polish'],
        nailZone.length,
        maxColor: nailColors.length - 1,
      ),
      deco: SpotGrid.read(
        json['deco'],
        n,
        maxColor: NailDeco.values.length - 1,
      ),
      shine: SpotGrid.read(json['shine'], n, maxColor: 0),
      filed: SpotGrid.read(json['filed'], n, maxColor: 0),
    );
  }

  /// Random pretty nails for "Surprise me".
  factory NailSet.random(Random rnd) {
    final n = kFingers.length;
    final same = rnd.nextBool();
    final first = rnd.nextInt(nailColors.length);
    var polish = SpotGrid.none;
    for (var i = 0; i < n; i++) {
      polish = polish.set(
        nailZone.regions[i],
        same ? first : rnd.nextInt(nailColors.length),
      );
    }
    var deco = SpotGrid.none;
    if (rnd.nextBool()) {
      final kind = rnd.nextInt(NailDeco.values.length);
      deco = deco.set([2], kind);
      if (rnd.nextBool()) deco = deco.set([4], kind);
    }
    return NailSet(
      polish: polish,
      deco: deco,
      shine: rnd.nextBool() ? SpotGrid.filled(n, 0) : SpotGrid.none,
      filed: SpotGrid.filled(n, 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NailSet &&
      other.polish == polish &&
      other.deco == deco &&
      other.shine == shine &&
      other.filed == filed;

  @override
  int get hashCode => Object.hash(polish, deco, shine, filed);
}
