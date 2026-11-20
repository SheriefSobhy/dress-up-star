import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';

/// Saves the "My Looks" gallery on the device with shared_preferences.
class LooksStorage {
  static const storageKey = 'my_looks';

  Future<List<Outfit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(storageKey) ?? const <String>[];
    final looks = <Outfit>[];
    for (final entry in raw) {
      try {
        final data = jsonDecode(entry);
        if (data is Map<String, dynamic>) looks.add(Outfit.fromJson(data));
      } catch (_) {
        // Skip a broken entry instead of losing the whole gallery.
      }
    }
    return looks;
  }

  /// Adds [look] at the front of the gallery and returns the new gallery.
  Future<List<Outfit>> add(Outfit look) async {
    final looks = [look, ...await load()];
    if (looks.length > maxSavedLooks) {
      looks.removeRange(maxSavedLooks, looks.length);
    }
    await _write(looks);
    return looks;
  }

  /// Removes the look at [index] and returns the new gallery.
  Future<List<Outfit>> removeAt(int index) async {
    final looks = await load();
    if (index >= 0 && index < looks.length) looks.removeAt(index);
    await _write(looks);
    return looks;
  }

  Future<void> _write(List<Outfit> looks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, [
      for (final l in looks) jsonEncode(l.toJson()),
    ]);
  }
}
