import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/room.dart';

/// Keeps every doll's bedroom on the device, by doll id.
class RoomStorage {
  static const storageKey = 'rooms';

  Future<Map<String, dynamic>> _all(SharedPreferences prefs) async {
    final raw = prefs.getString(storageKey);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw);
      return json is Map<String, dynamic> ? json : {};
    } catch (_) {
      return {};
    }
  }

  /// The bedroom of doll [dollId] (a new one if she has none yet).
  Future<Room> load(int dollId) async {
    final prefs = await SharedPreferences.getInstance();
    return Room.fromJson((await _all(prefs))['$dollId']) ?? Room.starter();
  }

  Future<void> save(int dollId, Room room) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _all(prefs);
    all['$dollId'] = room.toJson();
    await prefs.setString(storageKey, jsonEncode(all));
  }

  Future<void> remove(int dollId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _all(prefs);
    if (all.remove('$dollId') == null) return;
    await prefs.setString(storageKey, jsonEncode(all));
  }
}
