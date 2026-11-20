import 'dart:math';

import 'package:flutter/painting.dart';

import '../data/game_config.dart';

final Map<String, GameItem> _itemsById = {
  for (final item in gameItems) item.id: item,
};

/// Finds an item from the game config by its id.
GameItem? findItem(String id) => _itemsById[id];

/// All items that can be worn in [slot].
List<GameItem> itemsForSlot(Slot slot) =>
    gameItems.where((item) => item.slot == slot).toList();

/// All items shown in [category].
List<GameItem> itemsForCategory(GameCategory category) =>
    gameItems.where((item) => category.slots.contains(item.slot)).toList();

/// An item the doll is wearing, with the color it was given.
class WornItem {
  const WornItem(this.item, this.color);

  final GameItem item;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is WornItem &&
      other.item.id == item.id &&
      other.color.toARGB32() == color.toARGB32();

  @override
  int get hashCode => Object.hash(item.id, color.toARGB32());
}

/// Everything the doll is wearing right now. Outfits never change; every
/// action returns a new outfit.
class Outfit {
  Outfit(Map<Slot, WornItem> worn) : worn = Map.unmodifiable(worn);

  /// What the doll wears when the game starts.
  factory Outfit.starter() {
    final worn = <Slot, WornItem>{};
    for (final id in starterItemIds) {
      final item = findItem(id);
      if (item != null) worn[item.slot] = WornItem(item, item.color);
    }
    return Outfit(worn);
  }

  /// A random outfit for the "Surprise me" button.
  factory Outfit.random([Random? random]) {
    final rnd = random ?? Random();
    T pick<T>(List<T> list) => list[rnd.nextInt(list.length)];
    final worn = <Slot, WornItem>{};

    void wearRandom(Slot slot, List<Color> colors, {Color? color}) {
      final options = itemsForSlot(slot);
      if (options.isEmpty) return;
      final item = pick(options);
      // Half of the time keep the item's own color, otherwise surprise!
      final c = color ?? (rnd.nextBool() ? item.color : pick<Color>(colors));
      worn[slot] = WornItem(item, c);
    }

    wearRandom(Slot.background, backgroundColors);
    wearRandom(Slot.hair, hairColors, color: pick(hairColors));
    if (rnd.nextBool()) {
      wearRandom(Slot.dress, clothesColors);
    } else {
      wearRandom(Slot.top, clothesColors);
      wearRandom(Slot.skirt, clothesColors);
    }
    wearRandom(Slot.shoes, clothesColors);
    for (final slot in [Slot.head, Slot.eyes, Slot.hand]) {
      if (rnd.nextInt(3) == 0) wearRandom(slot, accessoryColors);
    }
    return Outfit(worn);
  }

  final Map<Slot, WornItem> worn;

  WornItem? operator [](Slot slot) => worn[slot];

  bool isWearing(GameItem item) => worn[item.slot]?.item.id == item.id;

  /// Puts [item] on, or takes it off if it is already on (unless its slot
  /// is required, like hair).
  Outfit toggle(GameItem item) {
    if (isWearing(item)) {
      if (requiredSlots.contains(item.slot)) return this;
      return remove(item.slot);
    }
    return wear(item);
  }

  Outfit wear(GameItem item, {Color? color}) {
    final next = Map<Slot, WornItem>.from(worn);
    for (final other in slotConflicts[item.slot] ?? const <Slot>[]) {
      next.remove(other);
    }
    final previous = worn[item.slot];
    final keepColor =
        previous != null && keepColorWhenSwitching.contains(item.slot);
    next[item.slot] = WornItem(
      item,
      color ?? (keepColor ? previous.color : item.color),
    );
    return Outfit(next);
  }

  Outfit remove(Slot slot) => Outfit(Map.of(worn)..remove(slot));

  Outfit recolor(Slot slot, Color color) {
    final current = worn[slot];
    if (current == null) return this;
    return Outfit(Map.of(worn)..[slot] = WornItem(current.item, color));
  }

  Map<String, dynamic> toJson() => {
    for (final entry in worn.entries)
      entry.key.name: {
        'id': entry.value.item.id,
        'color': entry.value.color.toARGB32(),
      },
  };

  /// Reads a saved outfit. Unknown slots or items (for example an item that
  /// was removed from the config) are skipped.
  factory Outfit.fromJson(Map<String, dynamic> json) {
    final worn = <Slot, WornItem>{};
    for (final slot in Slot.values) {
      final data = json[slot.name];
      if (data is! Map) continue;
      final item = findItem('${data['id']}');
      final color = data['color'];
      if (item == null || item.slot != slot || color is! int) continue;
      worn[slot] = WornItem(item, Color(color));
    }
    // Make sure required slots are never empty.
    final starter = Outfit.starter();
    for (final slot in requiredSlots) {
      final fallback = starter.worn[slot];
      if (!worn.containsKey(slot) && fallback != null) worn[slot] = fallback;
    }
    return Outfit(worn);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Outfit || other.worn.length != worn.length) return false;
    for (final entry in worn.entries) {
      if (other.worn[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    worn.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
