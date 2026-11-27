import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/outfit.dart';

/// Every doll in the game and which one is on stage. A doll is simply what
/// she wears: an [Outfit] with her own id, skin, face, clothes, makeup,
/// salon hair and nails. Like outfits, it never changes; every action
/// returns a new one.
class Dolls {
  Dolls(List<Outfit> list, this.activeId, this.nextId)
    : list = List.unmodifiable(list);

  /// The game starts with one doll.
  factory Dolls.start() =>
      Dolls([Outfit.starter()], Outfit.firstDollId, Outfit.firstDollId + 1);

  final List<Outfit> list;
  final int activeId;

  /// The next new doll's id. Ids are never used twice, so a saved look can
  /// not move to another doll.
  final int nextId;

  Outfit get active =>
      list.firstWhere((d) => d.dollId == activeId, orElse: () => list.first);

  bool get isFull => list.length >= maxDolls;

  bool has(int id) => list.any((d) => d.dollId == id);

  Dolls select(int id) => has(id) ? Dolls(list, id, nextId) : this;

  Dolls _replace(Outfit doll) => Dolls(
    [for (final d in list) d.dollId == doll.dollId ? doll : d],
    activeId,
    nextId,
  );

  /// The doll on stage puts on [look]; her skin and face stay hers.
  Dolls dress(Outfit look) =>
      _replace(look.copyWith(body: active.body, dollId: active.dollId));

  /// The doll on stage gets a new skin and face.
  Dolls reshape(DollBody body) => _replace(active.copyWith(body: body));

  /// A new doll joins and comes on stage (not when the game is full).
  Dolls add(Outfit doll) => isFull
      ? this
      : Dolls([...list, doll.copyWith(dollId: nextId)], nextId, nextId + 1);

  /// Removes a doll. The last one always stays.
  Dolls remove(int id) {
    final index = list.indexWhere((d) => d.dollId == id);
    if (index < 0 || list.length < 2) return this;
    final rest = [...list]..removeAt(index);
    return Dolls(
      rest,
      id == activeId ? rest[math.min(index, rest.length - 1)].dollId : activeId,
      nextId,
    );
  }

  Map<String, dynamic> toJson() => {
    'active': activeId,
    'next': nextId,
    'dolls': [
      for (final d in list) {...d.toJson(), 'doll': d.dollId},
    ],
  };

  /// Reads saved dolls; anything broken is skipped.
  factory Dolls.fromJson(Object? json) {
    if (json is! Map || json['dolls'] is! List) return Dolls.start();
    final list = <Outfit>[];
    for (final entry in json['dolls'] as List) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        final doll = Outfit.fromJson(entry);
        if (list.length < maxDolls &&
            !list.any((d) => d.dollId == doll.dollId)) {
          list.add(doll);
        }
      } catch (_) {
        // Keep the other dolls.
      }
    }
    if (list.isEmpty) return Dolls.start();
    final highest = list.map((d) => d.dollId).reduce(math.max);
    final next = json['next'];
    final active = json['active'];
    return Dolls(
      list,
      active is int && list.any((d) => d.dollId == active)
          ? active
          : list.first.dollId,
      next is int && next > highest ? next : highest + 1,
    );
  }
}

/// Keeps the dolls on the device with shared_preferences.
class DollsStorage {
  static const storageKey = 'dolls';

  Future<Dolls> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return Dolls.start();
    try {
      return Dolls.fromJson(jsonDecode(raw));
    } catch (_) {
      return Dolls.start();
    }
  }

  Future<void> save(Dolls dolls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(dolls.toJson()));
  }
}
