import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/unlockable.dart';
import 'game_settings.dart';

/// Stars and the Star Shop: what she has earned, and what is unlocked.
///
/// Saved on the device so nothing is ever lost:
/// * every star ever earned (challenges and daily gifts) is one number;
/// * every unlocked item is saved with the stars that were paid for it.
///
/// The stars she can spend are the earned stars minus everything paid, so
/// the two can never get out of step. No real money is involved anywhere.
class Rewards extends ChangeNotifier {
  /// Every star ever earned (the key is older than the Star Shop).
  static const earnedKey = GameSettings.challengeStarsKey;

  /// Unlocked items, saved as "id:stars paid".
  static const unlockedKey = GameSettings.unlockedItemsKey;

  /// The last day the daily star was given ("2026-11-24").
  static const dailyStarKey = 'daily_star_day';

  /// What day it is (tests set their own clock).
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  int _earned = 0;
  final Map<String, int> _paid = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Stars she can spend now.
  int get stars => max(0, _earned - spent);

  /// Every star ever earned.
  int get earned => _earned;

  /// Stars paid for unlocked items.
  int get spent => _paid.values.fold(0, (a, b) => a + b);

  /// Ids of the items unlocked in the Star Shop.
  Set<String> get unlockedIds => Set.unmodifiable(_paid.keys);

  /// Free items are always unlocked.
  bool isUnlocked(Unlockable item) =>
      !item.isSpecial || _paid.containsKey(item.id);

  bool canAfford(Unlockable item) => stars >= item.price;

  /// How many more stars are needed for [item].
  int missingFor(Unlockable item) => max(0, item.price - stars);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _earned = prefs.getInt(earnedKey) ?? 0;
    _paid.clear();
    for (final entry in prefs.getStringList(unlockedKey) ?? const []) {
      final cut = entry.lastIndexOf(':');
      if (cut <= 0) continue;
      _paid[entry.substring(0, cut)] =
          int.tryParse(entry.substring(cut + 1)) ?? 0;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Adds stars she has won and returns how many she can spend now.
  Future<int> addStars(int count) async {
    _earned = await GameSettings.addChallengeStars(count);
    notifyListeners();
    return stars;
  }

  /// Buys [item] with stars. Returns false (and changes nothing) if there
  /// are not enough stars.
  Future<bool> unlock(Unlockable item) async {
    if (isUnlocked(item)) return true;
    if (!canAfford(item)) return false;
    _paid[item.id] = item.price;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(unlockedKey, [
      for (final e in _paid.entries) '${e.key}:${e.value}',
    ]);
    notifyListeners();
    return true;
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// The first time the game is opened each day there is a star. Returns
  /// true when it was given now.
  Future<bool> claimDailyStar() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _day(now());
    if (prefs.getString(dailyStarKey) == today) return false;
    await prefs.setString(dailyStarKey, today);
    await addStars(1);
    return true;
  }
}
