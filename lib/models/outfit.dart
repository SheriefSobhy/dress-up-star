import 'dart:math';

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import 'beauty.dart';
import 'doll_body.dart';

export 'beauty.dart';
export 'doll_body.dart';

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
    gameItems.where(category.shows).toList();

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
  Outfit(
    Map<Slot, WornItem> worn, {
    this.makeup = Makeup.none,
    this.salon = SalonHair.natural,
    this.nails = NailSet.none,
    this.pose = DollPose.stand,
    this.body = DollBody.classic,
    this.dollId = firstDollId,
    this.runway = false,
  }) : worn = Map.unmodifiable(worn);

  /// What the doll wears when the game starts.
  factory Outfit.starter() {
    final worn = <Slot, WornItem>{};
    for (final id in starterItemIds) {
      final item = findItem(id);
      if (item != null) worn[item.slot] = WornItem(item, item.color);
    }
    return Outfit(worn);
  }

  /// A random outfit for the "Surprise me" button, using only items that
  /// are [allowed] (by default the free ones, not Star Shop items).
  factory Outfit.random([
    Random? random,
    bool Function(GameItem item)? allowed,
  ]) {
    final ok = allowed ?? (GameItem item) => !item.isSpecial;
    final rnd = random ?? Random();
    T pick<T>(List<T> list) => list[rnd.nextInt(list.length)];
    final worn = <Slot, WornItem>{};

    void wearRandom(Slot slot, List<Color> colors, {Color? color}) {
      final options = itemsForSlot(slot).where(ok).toList();
      if (options.isEmpty) return;
      final item = pick(options);
      // Half of the time keep the item's own color, otherwise surprise!
      final c = color ?? (rnd.nextBool() ? item.color : pick<Color>(colors));
      worn[slot] = WornItem(item, c);
    }

    wearRandom(Slot.background, backgroundColors);
    wearRandom(Slot.hair, hairColors, color: pick(hairColors));
    // A dress (or costume, pajamas, sportswear), or a top with a skirt or
    // pants.
    if (rnd.nextBool()) {
      wearRandom(Slot.dress, clothesColors);
    } else {
      wearRandom(Slot.top, clothesColors);
      wearRandom(rnd.nextInt(3) == 0 ? Slot.pants : Slot.skirt, clothesColors);
    }
    wearRandom(Slot.shoes, clothesColors);
    if (rnd.nextInt(5) == 0) wearRandom(Slot.jacket, clothesColors);
    if (rnd.nextInt(4) == 0) wearRandom(Slot.socks, clothesColors);
    // A hat or something else on her head, never both.
    if (rnd.nextInt(5) == 0) {
      wearRandom(Slot.hat, clothesColors);
    } else if (rnd.nextInt(3) == 0) {
      wearRandom(Slot.head, accessoryColors);
    }
    if (rnd.nextInt(3) == 0) wearRandom(Slot.hand, accessoryColors);
    if (rnd.nextInt(3) == 0) wearRandom(Slot.eyes, glassesColors);
    if (itemsForSlot(Slot.back).any(ok) && rnd.nextInt(4) == 0) {
      wearRandom(Slot.back, accessoryColors);
    }
    for (final slot in [Slot.neck, Slot.ears, Slot.wrist]) {
      if (rnd.nextInt(5) < 2) wearRandom(slot, jewelryColors);
    }
    var salon = SalonHair.natural;
    final salonHair = findItem(salonHairId);
    if (salonHair != null && rnd.nextInt(3) == 0) {
      // A hairdo from the Hair Salon.
      worn[Slot.hair] = WornItem(salonHair, worn[Slot.hair]!.color);
      salon = SalonHair.random(rnd);
    }
    return Outfit(
      worn,
      makeup: rnd.nextInt(3) > 0 ? Makeup.random(rnd) : Makeup.none,
      salon: salon,
      nails: rnd.nextBool() ? NailSet.random(rnd) : NailSet.none,
    );
  }

  final Map<Slot, WornItem> worn;

  /// What the Makeup activity put on her face.
  final Makeup makeup;

  /// What the Hair Salon did (only shown with the salon's long hair).
  final SalonHair salon;

  /// What the Nails activity did.
  final NailSet nails;

  /// How she stands (from the Pose button).
  final DollPose pose;

  /// Her skin and face (from the character creator).
  final DollBody body;

  /// Which doll wears this. Not part of the look itself (two dolls dressed
  /// the same are equal outfits).
  final int dollId;

  /// The doll the game started with; also the owner of looks saved before
  /// there were several dolls.
  static const int firstDollId = 1;

  /// A photo taken at the Fashion Show: the gallery shows it on the runway.
  /// Not part of the look itself, like [dollId].
  final bool runway;

  /// True when her hair comes from the Hair Salon.
  bool get hasSalonHair =>
      !salon.isNatural && worn[Slot.hair]?.item.id == salonHairId;

  /// The same outfit with other clothes and/or activity results.
  Outfit copyWith({
    Map<Slot, WornItem>? worn,
    Makeup? makeup,
    SalonHair? salon,
    NailSet? nails,
    DollPose? pose,
    DollBody? body,
    int? dollId,
    bool? runway,
  }) => Outfit(
    worn ?? this.worn,
    makeup: makeup ?? this.makeup,
    salon: salon ?? this.salon,
    nails: nails ?? this.nails,
    pose: pose ?? this.pose,
    body: body ?? this.body,
    dollId: dollId ?? this.dollId,
    runway: runway ?? this.runway,
  );

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
    // A new hair style replaces the salon hairdo.
    final newHair = item.slot == Slot.hair && item.id != salonHairId;
    return copyWith(worn: next, salon: newHair ? SalonHair.natural : null);
  }

  Outfit remove(Slot slot) => copyWith(worn: Map.of(worn)..remove(slot));

  Outfit recolor(Slot slot, Color color) {
    final current = worn[slot];
    if (current == null) return this;
    return copyWith(worn: Map.of(worn)..[slot] = WornItem(current.item, color));
  }

  Map<String, dynamic> toJson() => {
    for (final entry in worn.entries)
      entry.key.name: {
        'id': entry.value.item.id,
        'color': entry.value.color.toARGB32(),
      },
    if (!makeup.isEmpty) 'makeup': makeup.toJson(),
    if (hasSalonHair) 'salon': salon.toJson(),
    if (!nails.isEmpty) 'nails': nails.toJson(),
    if (pose != DollPose.stand) 'pose': pose.name,
    if (body != DollBody.classic) 'body': body.toJson(),
    if (dollId != firstDollId) 'doll': dollId,
    if (runway) 'runway': true,
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
    final salon = worn[Slot.hair]?.item.id == salonHairId
        ? SalonHair.fromJson(json['salon'])
        : SalonHair.natural;
    return Outfit(
      worn,
      makeup: Makeup.fromJson(json['makeup']),
      salon: salon,
      nails: NailSet.fromJson(json['nails']),
      pose: DollPose.values.asNameMap()[json['pose']] ?? DollPose.stand,
      body: DollBody.fromJson(json['body']),
      dollId: json['doll'] is int ? json['doll'] as int : firstDollId,
      runway: json['runway'] == true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! Outfit || other.worn.length != worn.length) return false;
    if (other.makeup != makeup || other.salon != salon) return false;
    if (other.nails != nails || other.pose != pose) return false;
    if (other.body != body) return false;
    for (final entry in worn.entries) {
      if (other.worn[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      worn.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    makeup,
    salon,
    nails,
    pose,
    body,
  );
}
