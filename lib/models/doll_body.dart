import 'dart:math';
import 'dart:ui';

// =============================================================================
//  What the character creator chooses: a doll's skin and face. Her hair,
//  clothes and activity results are part of her outfit.
// =============================================================================

/// How many dolls can live in the game at once.
const int maxDolls = 6;

/// Skin tones, light to deep. The second one is the first doll's.
const List<Color> skinTones = [
  Color(0xFFFFE9DC),
  Color(0xFFFFDCC8),
  Color(0xFFF7CBA4),
  Color(0xFFEAB188),
  Color(0xFFD29568),
  Color(0xFFB4774E),
  Color(0xFF93603F),
  Color(0xFF754A33),
];

/// The colors of one pair of eyes, from the top of the iris down.
class EyeColor {
  const EyeColor(this.top, this.middle, this.bottom, this.pupil);
  final Color top;
  final Color middle;
  final Color bottom;
  final Color pupil;
}

const List<EyeColor> eyeColors = [
  // Violet (the first doll's).
  EyeColor(
    Color(0xFF2E1B36),
    Color(0xFF5B3577),
    Color(0xFFA36BC9),
    Color(0xFF22122A),
  ),
  // Brown.
  EyeColor(
    Color(0xFF2A150C),
    Color(0xFF6E3B1E),
    Color(0xFFBE7C45),
    Color(0xFF1C0D07),
  ),
  // Blue.
  EyeColor(
    Color(0xFF0F2650),
    Color(0xFF1F62B8),
    Color(0xFF6FCBF5),
    Color(0xFF0B1834),
  ),
  // Green.
  EyeColor(
    Color(0xFF0D3320),
    Color(0xFF1F7A4B),
    Color(0xFF86D685),
    Color(0xFF082214),
  ),
  // Honey.
  EyeColor(
    Color(0xFF4A2B05),
    Color(0xFFB4730C),
    Color(0xFFFFC945),
    Color(0xFF2C1903),
  ),
  // Gray.
  EyeColor(
    Color(0xFF222B38),
    Color(0xFF5A6E86),
    Color(0xFFB4CADD),
    Color(0xFF141B26),
  ),
];

/// Cheek blush colors; null is no blush.
const List<Color?> cheekColors = [
  Color(0xFFFF8FAE),
  Color(0xFFFF9466),
  Color(0xFFD93D72),
  null,
];

/// Lip colors (the first is the first doll's).
const List<Color> lipColors = [
  Color(0xFFE45E7E),
  Color(0xFFD7263D),
  Color(0xFFF5704A),
  Color(0xFFA9438F),
  Color(0xFFB5675A),
];

const int eyeShapeCount = 3;
const int browStyleCount = 3;
const int faceShapeCount = 3;

/// One doll's skin and face.
class DollBody {
  const DollBody({
    this.skin = 1,
    this.eyeColor = 0,
    this.eyeShape = 0,
    this.brows = 0,
    this.face = 0,
    this.freckles = false,
    this.blush = 0,
    this.lips = 0,
  });

  /// How the very first doll looks (also every look saved before there was
  /// a character creator).
  static const DollBody classic = DollBody();

  /// Indexes into [skinTones], [eyeColors], [cheekColors] and [lipColors].
  final int skin;
  final int eyeColor;
  final int eyeShape;
  final int brows;
  final int face;
  final bool freckles;
  final int blush;
  final int lips;

  factory DollBody.random(Random rnd) => DollBody(
    skin: rnd.nextInt(skinTones.length),
    eyeColor: rnd.nextInt(eyeColors.length),
    eyeShape: rnd.nextInt(eyeShapeCount),
    brows: rnd.nextInt(browStyleCount),
    face: rnd.nextInt(faceShapeCount),
    freckles: rnd.nextInt(4) == 0,
    blush: rnd.nextInt(cheekColors.length),
    lips: rnd.nextInt(lipColors.length),
  );

  DollBody copyWith({
    int? skin,
    int? eyeColor,
    int? eyeShape,
    int? brows,
    int? face,
    bool? freckles,
    int? blush,
    int? lips,
  }) => DollBody(
    skin: skin ?? this.skin,
    eyeColor: eyeColor ?? this.eyeColor,
    eyeShape: eyeShape ?? this.eyeShape,
    brows: brows ?? this.brows,
    face: face ?? this.face,
    freckles: freckles ?? this.freckles,
    blush: blush ?? this.blush,
    lips: lips ?? this.lips,
  );

  /// A short text that changes whenever she does (for caches).
  String get key =>
      '$skin.$eyeColor.$eyeShape.$brows.$face.${freckles ? 1 : 0}.$blush.$lips';

  Map<String, dynamic> toJson() => {
    'skin': skin,
    'eyeColor': eyeColor,
    'eyeShape': eyeShape,
    'brows': brows,
    'face': face,
    'freckles': freckles,
    'blush': blush,
    'lips': lips,
  };

  /// Reads a saved body; anything missing or broken stays classic.
  factory DollBody.fromJson(Object? json) {
    if (json is! Map) return classic;
    int read(String name, int count, int fallback) {
      final v = json[name];
      return v is int && v >= 0 && v < count ? v : fallback;
    }

    return DollBody(
      skin: read('skin', skinTones.length, classic.skin),
      eyeColor: read('eyeColor', eyeColors.length, 0),
      eyeShape: read('eyeShape', eyeShapeCount, 0),
      brows: read('brows', browStyleCount, 0),
      face: read('face', faceShapeCount, 0),
      freckles: json['freckles'] == true,
      blush: read('blush', cheekColors.length, 0),
      lips: read('lips', lipColors.length, 0),
    );
  }

  @override
  bool operator ==(Object other) => other is DollBody && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'DollBody($key)';
}
