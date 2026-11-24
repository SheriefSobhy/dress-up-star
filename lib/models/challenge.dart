import 'dart:math';

import '../data/game_config.dart';
import 'outfit.dart';

/// How many things she wears fit [theme] (the background counts too).
int themeMatches(Outfit outfit, ChallengeTheme theme) =>
    outfit.worn.values.where((w) => w.item.themes.contains(theme)).length;

/// Stars for dressing her for [theme]: 1 to 3, never zero.
int challengeStars(Outfit outfit, ChallengeTheme theme) {
  final matches = themeMatches(outfit, theme);
  if (matches >= matchesForThreeStars) return 3;
  if (matches >= matchesForTwoStars) return 2;
  return 1;
}

/// A new theme card, not the same as [last].
ChallengeTheme pickTheme(Random random, {ChallengeTheme? last}) {
  final options = ChallengeTheme.values.where((t) => t != last).toList();
  return options[random.nextInt(options.length)];
}

/// A few items that fit [theme], from different places on her (shown as
/// little picture hints on the theme card).
List<GameItem> themeIdeas(ChallengeTheme theme, {int count = 3}) {
  const order = [
    Slot.dress,
    Slot.background,
    Slot.head,
    Slot.shoes,
    Slot.top,
    Slot.hand,
    Slot.eyes,
    Slot.hair,
  ];
  final ideas = <GameItem>[];
  for (final slot in order) {
    for (final item in gameItems) {
      if (item.slot == slot && item.themes.contains(theme)) {
        ideas.add(item);
        break;
      }
    }
    if (ideas.length == count) break;
  }
  return ideas;
}

/// Path to the picture of [theme].
String themeArt(ChallengeTheme theme) => 'assets/svg/themes/${theme.name}.svg';
