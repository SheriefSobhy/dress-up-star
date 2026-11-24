import 'package:shared_preferences/shared_preferences.dart';

/// Small things the game remembers on the device.
class GameSettings {
  static const scrollHintSeenKey = 'scroll_hint_seen';

  /// True once the player has scrolled the category bar.
  static Future<bool> scrollHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(scrollHintSeenKey) ?? false;
  }

  static Future<void> markScrollHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(scrollHintSeenKey, true);
  }

  static const challengeStarsKey = 'challenge_stars';

  /// All the stars won in challenges.
  static Future<int> challengeStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(challengeStarsKey) ?? 0;
  }

  /// Adds [stars] and returns the new total.
  static Future<int> addChallengeStars(int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(challengeStarsKey) ?? 0) + stars;
    await prefs.setInt(challengeStarsKey, total);
    return total;
  }
}
