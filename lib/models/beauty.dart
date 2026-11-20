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
