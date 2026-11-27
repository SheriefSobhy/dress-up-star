import 'dart:math';

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import 'challenge.dart';
import 'outfit.dart';

/// The three judges: the cat looks at the theme, the bunny counts what she
/// wears, and the owl looks at the colors.
enum Judge { cat, bunny, owl }

/// The lowest and highest card a judge holds up (never a sad result).
const int minCard = 2;
const int maxCard = 5;

/// Hair and the background are always there, so they are not "things worn".
Iterable<MapEntry<Slot, WornItem>> _dressed(Outfit outfit) => outfit
    .worn
    .entries
    .where((e) => e.key != Slot.hair && e.key != Slot.background);

int _themeCard(Outfit outfit, ChallengeTheme theme) =>
    switch (themeMatches(outfit, theme)) {
      0 => 2,
      1 => 3,
      2 => 4,
      _ => 5,
    };

int _itemsCard(Outfit outfit) =>
    _dressed(outfit).length.clamp(minCard, maxCard);

/// Which color family [color] belongs to; null for white, grey and black,
/// which go with everything.
int? colorFamily(Color color) {
  final hsl = HSLColor.fromColor(color);
  if (hsl.saturation < 0.18 || hsl.lightness > 0.93 || hsl.lightness < 0.12) {
    return null;
  }
  // Red, orange, yellow, green, teal, blue, purple, pink.
  const upTo = [15.0, 40.0, 70.0, 160.0, 195.0, 255.0, 290.0, 345.0];
  final family = upTo.indexWhere((hue) => hsl.hue < hue);
  return family < 0 ? 0 : family;
}

/// The more of her things share a color, the higher the card.
int _colorCard(Outfit outfit) {
  final families = [
    for (final e in _dressed(outfit)) colorFamily(e.value.color),
  ];
  // One thing alone can't match or clash.
  if (families.length < 2) return 3;
  final matching = families
      .where((f) => f == null || families.where((g) => g == f).length > 1)
      .length;
  return minCard + (matching / families.length * (maxCard - minCard)).round();
}

/// What each judge holds up and the Star Shop stars it earns.
class ShowScore {
  const ShowScore(this.cards);

  factory ShowScore.of(Outfit outfit, ChallengeTheme theme) => ShowScore({
    Judge.cat: _themeCard(outfit, theme),
    Judge.bunny: _itemsCard(outfit),
    Judge.owl: _colorCard(outfit),
  });

  /// 2 to 5 stars from every judge.
  final Map<Judge, int> cards;

  int get total => cards.values.fold(0, (a, b) => a + b);

  /// 1 to 3 Star Shop stars.
  int get shopStars => total >= 13 ? 3 : (total >= 10 ? 2 : 1);
}

/// Two different poses for the end of the runway.
List<DollPose> showPoses(Random random) =>
    (List.of(poseButtonOrder)..shuffle(random)).take(2).toList();
