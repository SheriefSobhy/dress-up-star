import 'package:shared_preferences/shared_preferences.dart';

import 'dolls_storage.dart';
import 'looks_storage.dart';
import 'room_storage.dart';

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

  static const tutorialSeenKey = 'tutorial_seen';

  /// True once the first-time tutorial was finished or skipped.
  static Future<bool> tutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(tutorialSeenKey) ?? false;
  }

  static Future<void> setTutorialSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialSeenKey, seen);
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

  /// Unlocked Star Shop items (the same key as Rewards.unlockedKey).
  static const unlockedItemsKey = 'unlocked_items';

  /// Starts the game over: removes every star, every unlocked Star Shop
  /// item, every saved look, every doll and her room. Settings (music, sounds,
  /// language) stay,
  /// and so does today's daily star, so it is not given again right away.
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(challengeStarsKey);
    await prefs.remove(unlockedItemsKey);
    await prefs.remove(LooksStorage.storageKey);
    await prefs.remove(DollsStorage.storageKey);
    await prefs.remove(RoomStorage.storageKey);
  }
}
