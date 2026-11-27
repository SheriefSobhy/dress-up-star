import 'package:flutter/material.dart';

import 'unlockable.dart';

/// A place on the doll where one item can be worn.
/// Items in the same slot replace each other.
enum Slot {
  background,
  hair,
  dress,
  top,
  skirt,
  shoes,
  head,
  eyes,
  hand,
  neck,
  ears,
  wrist,

  /// Worn on her back, behind her (wings).
  back,

  /// Jackets and coats, over her top or dress.
  jacket,
  pants,

  /// Socks and tights, under everything else.
  socks,

  /// Hats (they replace crowns and bows).
  hat,
}

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
  eyesWire,
  eyesCatEye,
  eyesHeartFrame,
  eyesStarFrame,
  eyesBig,
  // Sunglasses (glasses too: only one pair at a time)
  eyesSunAviator,
  eyesSunHeart,
  eyesSunStar,
  eyesSunBig,
  eyesSunSport,
  // Jewelry
  neckPearl,
  neckHeart,
  neckStar,
  neckGold,
  neckRainbow,
  neckChoker,
  neckCrystal,
  neckButterfly,
  earsStud,
  earsHoop,
  earsHeart,
  earsStar,
  earsGem,
  wristBeads,
  wristBangle,
  wristCharm,
  wristFriendship,
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
  // Star Shop specials
  dressGown,
  dressRainbow,
  dressBallerina,
  shoesSparkly,
  headUnicorn,
  eyesSunRainbow,
  neckDiamond,
  handKitten,
  handPuppy,
  backButterfly,
  bgBallroom,
  bgUnicorn,
  // Jackets and coats
  jacketDenim,
  jacketPuffer,
  jacketRain,
  jacketCardigan,
  jacketBlazer,
  jacketHoodie,
  // Pants
  pantsJeans,
  pantsLeggings,
  pantsShorts,
  pantsOveralls,
  pantsFlared,
  // Hats
  hatSun,
  hatBeanie,
  hatCap,
  hatBeret,
  hatWitch,
  hatFlower,
  // Costumes (full outfits, worn like a dress)
  costumePrincess,
  costumeMermaid,
  costumeFairy,
  costumeAstronaut,
  costumeChef,
  costumeDoctor,
  // Pajamas (worn like a dress)
  pajamaStars,
  pajamaHearts,
  pajamaBunny,
  pajamaCloud,
  // Sportswear (worn like a dress)
  sportTennis,
  sportBallet,
  sportFootball,
  sportTracksuit,
  // Socks and tights
  socksStriped,
  socksFrilly,
  socksRainbow,
  socksKnee,
  socksGlitter,
  // More dresses, tops, skirts and shoes
  dressSailor,
  dressStrawberry,
  topBlouse,
  topPolo,
  skirtPleated,
  skirtRuffle,
  shoesMaryJanes,
  shoesRoller,
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
    if (n.startsWith('neck')) return Slot.neck;
    if (n.startsWith('ears')) return Slot.ears;
    if (n.startsWith('wrist')) return Slot.wrist;
    if (n.startsWith('back')) return Slot.back;
    if (n.startsWith('jacket')) return Slot.jacket;
    if (n.startsWith('pants')) return Slot.pants;
    if (n.startsWith('socks')) return Slot.socks;
    if (n.startsWith('hat')) return Slot.hat;
    if (group.isNotEmpty) return Slot.dress;
    return Slot.background;
  }

  /// Costumes, pajamas and sportswear are worn like a dress but have their
  /// own category buttons. Everything else has no group ('').
  String get group {
    for (final g in const ['costume', 'pajama', 'sport']) {
      if (name.startsWith(g)) return g;
    }
    return '';
  }
}

/// A decoration printed on top of clothes.
enum ItemPattern { none, dots, stripes, stars, hearts }

/// One thing the doll can wear (or one background).
class GameItem with Unlockable {
  const GameItem({
    required this.id,
    required this.shape,
    required this.color,
    this.pattern = ItemPattern.none,
    this.themes = const {},
    this.price = 0,
  });

  /// Unique name, used when saving looks. Never reuse or rename an id that
  /// has been released, or saved looks will lose that item.
  @override
  final String id;
  final ItemShape shape;

  /// The color the item has when it is first put on.
  final Color color;
  final ItemPattern pattern;

  /// Challenge themes this item fits (more matching items, more stars).
  final Set<ChallengeTheme> themes;

  /// Stars needed to unlock it in the Star Shop (0: free from the start).
  @override
  final int price;

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
    this.iconArt,
    this.colorOnly = false,
    this.group = '',
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

  /// A drawn picture for the button (an SVG in assets/svg/icons/). When
  /// set, it is shown instead of the preview item and the icon.
  final String? iconArt;

  /// If true, the category shows only big color buttons that recolor the
  /// item in `slots.first` (used for "Hair color").
  final bool colorOnly;

  /// Which [ItemShapeSlot.group] of those slots is shown here.
  final String group;

  /// True when [item] belongs in this category.
  bool shows(GameItem item) =>
      slots.contains(item.slot) && item.shape.group == group;
}

/// A color button in an activity (makeup, hair dye, nail polish).
class ToolColor {
  const ToolColor(this.color, {this.glitter = false, this.rainbow = false});

  final Color color;

  /// Sparkly: tiny glitter dots are drawn on top.
  final bool glitter;

  /// Paints a rainbow (only used for hair dye).
  final bool rainbow;
}

/// How the doll stands. Saved with looks, so a photo keeps her pose.
enum DollPose { stand, wave, twirl, peace, hips, curtsy, jump }

/// The picture cards: dress her for the theme. The Challenge button uses the
/// first six (`challengeThemes`); the Fashion Show uses all of them.
enum ChallengeTheme {
  beach,
  snow,
  party,
  ball,
  garden,
  bedtime,
  sports,
  space,
  costume,
}
