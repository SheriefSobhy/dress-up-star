import 'package:flutter/material.dart';

/// A place on the doll where one item can be worn.
/// Items in the same slot replace each other.
enum Slot { background, hair, dress, top, skirt, shoes, head, eyes, hand }

/// How an item is drawn. Every shape belongs to exactly one [Slot].
///
/// To add a new item you usually only need a new entry in
/// `lib/data/game_config.dart` that re-uses one of these shapes with a new
/// color and/or pattern. A brand-new shape also needs its art:
/// `assets/svg/items/<shapeName>.svg` (plus optional `_back` / `_front`
/// layers). See `lib/art/art_library.dart` for the recolor colors.
enum ItemShape {
  // Hair
  hairLong,
  hairBob,
  hairPigtails,
  hairBun,
  hairCurly,
  hairBraids,
  hairPonytail,
  hairSpaceBuns,
  // Dresses
  dressPrincess,
  dressSun,
  dressTutu,
  dressLong,
  dressMermaid,
  dressFairy,
  dressParty,
  // Tops
  topTshirt,
  topTank,
  topSweater,
  // Skirts
  skirtAline,
  skirtTutu,
  skirtLong,
  // Shoes
  shoesSneakers,
  shoesBoots,
  shoesFlats,
  shoesSandals,
  // Head accessories
  headCrown,
  headTiara,
  headBow,
  headFlower,
  // Glasses
  eyesRound,
  eyesHeart,
  eyesStar,
  // Things to hold
  handBag,
  handWand,
  handBalloon,
  // Backgrounds
  bgSky,
  bgGarden,
  bgNight,
  bgRainbow,
  bgCastle,
  bgHearts,
  bgBeach,
  bgCandy,
}

extension ItemShapeSlot on ItemShape {
  Slot get slot {
    final n = name;
    if (n.startsWith('hair')) return Slot.hair;
    if (n.startsWith('dress')) return Slot.dress;
    if (n.startsWith('top')) return Slot.top;
    if (n.startsWith('skirt')) return Slot.skirt;
    if (n.startsWith('shoes')) return Slot.shoes;
    if (n.startsWith('head')) return Slot.head;
    if (n.startsWith('eyes')) return Slot.eyes;
    if (n.startsWith('hand')) return Slot.hand;
    return Slot.background;
  }
}

/// A decoration printed on top of clothes.
enum ItemPattern { none, dots, stripes, stars, hearts }

/// One thing the doll can wear (or one background).
class GameItem {
  const GameItem({
    required this.id,
    required this.shape,
    required this.color,
    this.pattern = ItemPattern.none,
  });

  /// Unique name, used when saving looks. Never reuse or rename an id that
  /// has been released, or saved looks will lose that item.
  final String id;
  final ItemShape shape;

  /// The color the item has when it is first put on.
  final Color color;
  final ItemPattern pattern;

  Slot get slot => shape.slot;
}

/// A button in the bottom category bar.
class GameCategory {
  const GameCategory({
    required this.id,
    required this.slots,
    required this.buttonColor,
    required this.colors,
    this.previewItemId,
    this.icon,
    this.colorOnly = false,
  });

  final String id;

  /// Items whose slot is in this list are shown in this category.
  final List<Slot> slots;
  final Color buttonColor;

  /// The round color buttons offered for items of this category.
  final List<Color> colors;

  /// The category button shows a small drawing of this item...
  final String? previewItemId;

  /// ...or this icon, if there is no preview item.
  final IconData? icon;

  /// If true, the category shows only big color buttons that recolor the
  /// item in `slots.first` (used for "Hair color").
  final bool colorOnly;
}
