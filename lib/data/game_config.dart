// =============================================================================
//  DRESS UP STAR - GAME CONFIG
//
//  Everything the player can choose lives in this file.
//
//  * Add a color:  add a `Color(0xFFRRGGBB)` line to one of the color lists.
//  * Add an item:  copy a line in `gameItems`, give it a NEW unique id, and
//                  change its color and/or pattern. It appears automatically
//                  in the category that shows its slot.
//  * Patterns:     ItemPattern.none, dots, stripes, stars, hearts
//  * Shapes:       see `ItemShape` in lib/models/game_item.dart
//                  (each shape is drawn by assets/svg/items/<shapeName>.svg)
// =============================================================================

import 'package:flutter/material.dart';

import '../models/game_item.dart';

export '../models/game_item.dart';

// ---------------------------------------------------------------------------
// Doll body colors
// ---------------------------------------------------------------------------

const Color skinColor = Color(0xFFFFDDC6);
const Color skinShadeColor = Color(0xFFE9A98C);
const Color leotardColor = Color(0xFFFFF4FA);

// ---------------------------------------------------------------------------
// Color buttons
// ---------------------------------------------------------------------------

/// Colors for clothes, shoes and accessories.
const List<Color> clothesColors = [
  Color(0xFFFF8FC7), // bubblegum pink
  Color(0xFFFF6B8B), // strawberry
  Color(0xFFFFA45C), // orange
  Color(0xFFFFD84D), // sunshine yellow
  Color(0xFF8EE08A), // mint green
  Color(0xFF5CD6D6), // turquoise
  Color(0xFF7CB8FF), // sky blue
  Color(0xFFB79CFF), // lavender
  Color(0xFFD873F0), // purple
  Color(0xFFFFFFFF), // white
];

/// Hair colors.
const List<Color> hairColors = [
  Color(0xFF5B3A29), // brown
  Color(0xFF2E2230), // black
  Color(0xFFF5CF6B), // blonde
  Color(0xFFD9733F), // ginger
  Color(0xFFFF8FC7), // pink
  Color(0xFFB79CFF), // lavender
  Color(0xFF7CB8FF), // blue
  Color(0xFF8EE08A), // green
  Color(0xFFFFFFFF), // snow white
];

/// Background colors.
const List<Color> backgroundColors = [
  Color(0xFFBDE3FF), // sky
  Color(0xFFFFD1E8), // pink
  Color(0xFFE3D4FF), // lilac
  Color(0xFFC9F2D0), // mint
  Color(0xFFFFF1B8), // lemon
  Color(0xFFFFD8C2), // peach
];

/// Shiny colors for crowns and wands look nice too, so accessories get both.
const List<Color> accessoryColors = [
  Color(0xFFFFD84D), // gold
  Color(0xFFE6E9F0), // silver
  ...clothesColors,
];

/// Jewelry colors: gold and silver first, then bright gem colors.
const List<Color> jewelryColors = accessoryColors;

/// Glasses colors (sunglasses lenses are tinted with the frame color).
const List<Color> glassesColors = [
  ...accessoryColors,
  Color(0xFF3A3550), // movie-star black
];

// ---------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------

const List<GameItem> gameItems = [
  // Hair styles
  GameItem(
    id: 'hair_long',
    themes: {ChallengeTheme.ball, ChallengeTheme.garden},
    shape: ItemShape.hairLong,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_bob',
    themes: {ChallengeTheme.party},
    shape: ItemShape.hairBob,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_pigtails',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.hairPigtails,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_bun',
    themes: {ChallengeTheme.ball, ChallengeTheme.bedtime},
    shape: ItemShape.hairBun,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_curly',
    themes: {ChallengeTheme.party},
    shape: ItemShape.hairCurly,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_braids',
    themes: {ChallengeTheme.snow, ChallengeTheme.garden},
    shape: ItemShape.hairBraids,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_ponytail',
    themes: {ChallengeTheme.beach, ChallengeTheme.snow},
    shape: ItemShape.hairPonytail,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_space_buns',
    themes: {ChallengeTheme.party},
    shape: ItemShape.hairSpaceBuns,
    color: Color(0xFF5B3A29),
  ),

  // Dresses
  GameItem(
    id: 'dress_princess',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.dressPrincess,
    color: Color(0xFFFF8FC7),
    pattern: ItemPattern.stars,
  ),
  GameItem(
    id: 'dress_sun',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.dressSun,
    color: Color(0xFFFFD84D),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'dress_tutu',
    themes: {ChallengeTheme.party, ChallengeTheme.ball},
    shape: ItemShape.dressTutu,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'dress_long',
    themes: {ChallengeTheme.ball, ChallengeTheme.bedtime},
    shape: ItemShape.dressLong,
    color: Color(0xFF7CB8FF),
    pattern: ItemPattern.hearts,
  ),
  GameItem(
    id: 'dress_stripes',
    themes: {ChallengeTheme.beach},
    shape: ItemShape.dressSun,
    color: Color(0xFF8EE08A),
    pattern: ItemPattern.stripes,
  ),
  GameItem(
    id: 'dress_mermaid',
    themes: {ChallengeTheme.beach, ChallengeTheme.ball},
    shape: ItemShape.dressMermaid,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'dress_fairy',
    themes: {ChallengeTheme.garden},
    shape: ItemShape.dressFairy,
    color: Color(0xFF8EE08A),
  ),
  GameItem(
    id: 'dress_party',
    themes: {ChallengeTheme.party},
    shape: ItemShape.dressParty,
    color: Color(0xFFFF6B8B),
    pattern: ItemPattern.dots,
  ),

  // Tops
  GameItem(
    id: 'top_tshirt',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.topTshirt,
    color: Color(0xFFFF6B8B),
    pattern: ItemPattern.hearts,
  ),
  GameItem(
    id: 'top_tank',
    themes: {ChallengeTheme.beach},
    shape: ItemShape.topTank,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'top_sweater',
    themes: {ChallengeTheme.snow, ChallengeTheme.bedtime},
    shape: ItemShape.topSweater,
    color: Color(0xFFB79CFF),
    pattern: ItemPattern.stripes,
  ),
  GameItem(
    id: 'top_tshirt_stars',
    themes: {ChallengeTheme.party, ChallengeTheme.bedtime},
    shape: ItemShape.topTshirt,
    color: Color(0xFF7CB8FF),
    pattern: ItemPattern.stars,
  ),

  // Skirts
  GameItem(
    id: 'skirt_aline',
    themes: {ChallengeTheme.garden},
    shape: ItemShape.skirtAline,
    color: Color(0xFF7CB8FF),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'skirt_tutu',
    themes: {ChallengeTheme.party, ChallengeTheme.ball},
    shape: ItemShape.skirtTutu,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'skirt_long',
    themes: {ChallengeTheme.snow, ChallengeTheme.ball},
    shape: ItemShape.skirtLong,
    color: Color(0xFFD873F0),
    pattern: ItemPattern.stars,
  ),

  // Shoes
  GameItem(
    id: 'shoes_sneakers',
    themes: {ChallengeTheme.garden, ChallengeTheme.party},
    shape: ItemShape.shoesSneakers,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'shoes_boots',
    themes: {ChallengeTheme.snow},
    shape: ItemShape.shoesBoots,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'shoes_flats',
    themes: {ChallengeTheme.ball, ChallengeTheme.bedtime},
    shape: ItemShape.shoesFlats,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'shoes_sandals',
    themes: {ChallengeTheme.beach},
    shape: ItemShape.shoesSandals,
    color: Color(0xFFFFD84D),
  ),

  // Accessories: crowns, bows and other head things
  GameItem(
    id: 'head_crown',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.headCrown,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'head_tiara',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.headTiara,
    color: Color(0xFFE6E9F0),
  ),
  GameItem(
    id: 'head_bow',
    themes: {ChallengeTheme.party, ChallengeTheme.bedtime},
    shape: ItemShape.headBow,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'head_flower',
    themes: {ChallengeTheme.garden, ChallengeTheme.beach},
    shape: ItemShape.headFlower,
    color: Color(0xFFFF8FC7),
  ),

  // Glasses (in the Glasses category; the ids are older than it)
  GameItem(
    id: 'eyes_round',
    themes: {ChallengeTheme.snow},
    shape: ItemShape.eyesRound,
    color: Color(0xFFD873F0),
  ),
  GameItem(
    id: 'eyes_heart',
    themes: {ChallengeTheme.party},
    shape: ItemShape.eyesHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'eyes_star',
    themes: {ChallengeTheme.party},
    shape: ItemShape.eyesStar,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'eyes_wire',
    themes: {ChallengeTheme.garden, ChallengeTheme.bedtime},
    shape: ItemShape.eyesWire,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'eyes_cat_eye',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.eyesCatEye,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'eyes_heart_frame',
    themes: {ChallengeTheme.party},
    shape: ItemShape.eyesHeartFrame,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'eyes_star_frame',
    themes: {ChallengeTheme.party, ChallengeTheme.bedtime},
    shape: ItemShape.eyesStarFrame,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'eyes_big',
    themes: {ChallengeTheme.party, ChallengeTheme.snow},
    shape: ItemShape.eyesBig,
    color: Color(0xFF5CD6D6),
  ),

  // Sunglasses
  GameItem(
    id: 'eyes_sun_aviator',
    themes: {ChallengeTheme.beach},
    shape: ItemShape.eyesSunAviator,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'eyes_sun_heart',
    themes: {ChallengeTheme.beach, ChallengeTheme.party},
    shape: ItemShape.eyesSunHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'eyes_sun_star',
    themes: {ChallengeTheme.beach, ChallengeTheme.party},
    shape: ItemShape.eyesSunStar,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'eyes_sun_big',
    themes: {ChallengeTheme.beach},
    shape: ItemShape.eyesSunBig,
    color: Color(0xFF3A3550),
  ),
  GameItem(
    id: 'eyes_sun_sport',
    themes: {ChallengeTheme.beach, ChallengeTheme.snow},
    shape: ItemShape.eyesSunSport,
    color: Color(0xFF5CD6D6),
  ),

  // Jewelry: necklaces
  GameItem(
    id: 'neck_pearl',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.neckPearl,
    color: Color(0xFFFFFFFF),
  ),
  GameItem(
    id: 'neck_heart',
    themes: {ChallengeTheme.party},
    shape: ItemShape.neckHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'neck_star',
    themes: {ChallengeTheme.bedtime, ChallengeTheme.party},
    shape: ItemShape.neckStar,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'neck_gold',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.neckGold,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'neck_rainbow',
    themes: {ChallengeTheme.party, ChallengeTheme.garden},
    shape: ItemShape.neckRainbow,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'neck_choker',
    themes: {ChallengeTheme.party},
    shape: ItemShape.neckChoker,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'neck_crystal',
    themes: {ChallengeTheme.snow, ChallengeTheme.ball},
    shape: ItemShape.neckCrystal,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'neck_butterfly',
    themes: {ChallengeTheme.garden},
    shape: ItemShape.neckButterfly,
    color: Color(0xFFD873F0),
  ),

  // Jewelry: earrings
  GameItem(
    id: 'ears_stud',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.earsStud,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'ears_hoop',
    themes: {ChallengeTheme.beach, ChallengeTheme.party},
    shape: ItemShape.earsHoop,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'ears_heart',
    themes: {ChallengeTheme.party},
    shape: ItemShape.earsHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'ears_star',
    themes: {ChallengeTheme.bedtime},
    shape: ItemShape.earsStar,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'ears_gem',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.earsGem,
    color: Color(0xFFD873F0),
  ),

  // Jewelry: bracelets
  GameItem(
    id: 'wrist_beads',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.wristBeads,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'wrist_bangle',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.wristBangle,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'wrist_charm',
    themes: {ChallengeTheme.party},
    shape: ItemShape.wristCharm,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'wrist_friendship',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.wristFriendship,
    color: Color(0xFF5CD6D6),
  ),

  // Accessories: bags) and things to hold
  GameItem(
    id: 'hand_bag',
    themes: {ChallengeTheme.party, ChallengeTheme.garden},
    shape: ItemShape.handBag,
    color: Color(0xFFFF8FC7),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'hand_wand',
    themes: {ChallengeTheme.ball, ChallengeTheme.bedtime},
    shape: ItemShape.handWand,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'hand_balloon',
    themes: {ChallengeTheme.party},
    shape: ItemShape.handBalloon,
    color: Color(0xFF7CB8FF),
  ),

  // Backgrounds
  GameItem(
    id: 'bg_sky',
    themes: {ChallengeTheme.garden},
    shape: ItemShape.bgSky,
    color: Color(0xFFBDE3FF),
  ),
  GameItem(
    id: 'bg_garden',
    themes: {ChallengeTheme.garden},
    shape: ItemShape.bgGarden,
    color: Color(0xFFBDE3FF),
  ),
  GameItem(
    id: 'bg_castle',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.bgCastle,
    color: Color(0xFFFFD1E8),
  ),
  GameItem(
    id: 'bg_rainbow',
    themes: {ChallengeTheme.party},
    shape: ItemShape.bgRainbow,
    color: Color(0xFFE3D4FF),
  ),
  GameItem(
    id: 'bg_night',
    themes: {ChallengeTheme.bedtime, ChallengeTheme.snow},
    shape: ItemShape.bgNight,
    color: Color(0xFFE3D4FF),
  ),
  GameItem(
    id: 'bg_hearts',
    themes: {ChallengeTheme.party},
    shape: ItemShape.bgHearts,
    color: Color(0xFFFFD1E8),
  ),
  GameItem(
    id: 'bg_beach',
    themes: {ChallengeTheme.beach},
    shape: ItemShape.bgBeach,
    color: Color(0xFFBDE3FF),
  ),
  GameItem(
    id: 'bg_candy',
    themes: {ChallengeTheme.party},
    shape: ItemShape.bgCandy,
    color: Color(0xFFFFD1E8),
  ),

  // -------------------------------------------------------------------------
  // Star Shop specials: locked until bought with stars (`price`, 3 to 15).
  // -------------------------------------------------------------------------
  GameItem(
    id: 'shop_gown_princess',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.dressGown,
    color: Color(0xFFFF8FC7),
    pattern: ItemPattern.stars,
    price: 10,
  ),
  GameItem(
    id: 'shop_gown_ice',
    themes: {ChallengeTheme.ball, ChallengeTheme.snow},
    shape: ItemShape.dressGown,
    color: Color(0xFF9FD8FF),
    pattern: ItemPattern.stars,
    price: 12,
  ),
  GameItem(
    id: 'shop_dress_rainbow',
    themes: {ChallengeTheme.party, ChallengeTheme.garden},
    shape: ItemShape.dressRainbow,
    color: Color(0xFFFF8FC7),
    price: 9,
  ),
  GameItem(
    id: 'shop_dress_ballerina',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.dressBallerina,
    color: Color(0xFFFFA3C8),
    price: 7,
  ),
  GameItem(
    id: 'shop_wings_butterfly',
    themes: {ChallengeTheme.garden, ChallengeTheme.party},
    shape: ItemShape.backButterfly,
    color: Color(0xFFB79CFF),
    price: 8,
  ),
  GameItem(
    id: 'shop_wings_fairy',
    themes: {ChallengeTheme.garden, ChallengeTheme.bedtime},
    shape: ItemShape.backButterfly,
    color: Color(0xFF5CD6D6),
    price: 6,
  ),
  GameItem(
    id: 'shop_unicorn_headband',
    themes: {ChallengeTheme.party, ChallengeTheme.bedtime},
    shape: ItemShape.headUnicorn,
    color: Color(0xFFD873F0),
    price: 7,
  ),
  GameItem(
    id: 'shop_boots_sparkly',
    themes: {ChallengeTheme.snow, ChallengeTheme.party},
    shape: ItemShape.shoesSparkly,
    color: Color(0xFFB79CFF),
    price: 5,
  ),
  GameItem(
    id: 'shop_boots_gold',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.shoesSparkly,
    color: Color(0xFFFFD84D),
    price: 3,
  ),
  GameItem(
    id: 'shop_necklace_diamond',
    themes: {ChallengeTheme.ball, ChallengeTheme.snow},
    shape: ItemShape.neckDiamond,
    color: Color(0xFF7CB8FF),
    price: 11,
  ),
  GameItem(
    id: 'shop_sunglasses_rainbow',
    themes: {ChallengeTheme.beach, ChallengeTheme.party},
    shape: ItemShape.eyesSunRainbow,
    color: Color(0xFFFFFFFF),
    price: 6,
  ),
  GameItem(
    id: 'shop_pet_kitten',
    themes: {ChallengeTheme.garden, ChallengeTheme.bedtime},
    shape: ItemShape.handKitten,
    color: Color(0xFFFFA45C),
    price: 10,
  ),
  GameItem(
    id: 'shop_pet_kitten_gray',
    themes: {ChallengeTheme.snow, ChallengeTheme.bedtime},
    shape: ItemShape.handKitten,
    color: Color(0xFFB8B4C8),
    price: 8,
  ),
  GameItem(
    id: 'shop_pet_puppy',
    themes: {ChallengeTheme.garden, ChallengeTheme.beach},
    shape: ItemShape.handPuppy,
    color: Color(0xFFD9A066),
    price: 10,
  ),
  GameItem(
    id: 'shop_bg_ballroom',
    themes: {ChallengeTheme.ball},
    shape: ItemShape.bgBallroom,
    color: Color(0xFFFFD1E8),
    price: 15,
  ),
  GameItem(
    id: 'shop_bg_unicorn',
    themes: {ChallengeTheme.party, ChallengeTheme.garden},
    shape: ItemShape.bgUnicorn,
    color: Color(0xFFE3D4FF),
    price: 15,
  ),
];

// ---------------------------------------------------------------------------
// Category bar (bottom of the screen), in order from left to right
// ---------------------------------------------------------------------------

const List<GameCategory> gameCategories = [
  GameCategory(
    id: 'hair',
    slots: [Slot.hair],
    buttonColor: Color(0xFFFFB3D9),
    colors: hairColors,
    previewItemId: 'hair_pigtails',
  ),
  GameCategory(
    id: 'hair_color',
    slots: [Slot.hair],
    buttonColor: Color(0xFFFFD6A5),
    colors: hairColors,
    icon: Icons.palette_rounded,
    colorOnly: true,
  ),
  GameCategory(
    id: 'dresses',
    slots: [Slot.dress],
    buttonColor: Color(0xFFE0C3FC),
    colors: clothesColors,
    previewItemId: 'dress_princess',
  ),
  GameCategory(
    id: 'tops',
    slots: [Slot.top],
    buttonColor: Color(0xFFB5EAD7),
    colors: clothesColors,
    previewItemId: 'top_tshirt',
  ),
  GameCategory(
    id: 'skirts',
    slots: [Slot.skirt],
    buttonColor: Color(0xFFFFF0A8),
    colors: clothesColors,
    previewItemId: 'skirt_tutu',
  ),
  GameCategory(
    id: 'shoes',
    slots: [Slot.shoes],
    buttonColor: Color(0xFFC7CEEA),
    colors: clothesColors,
    previewItemId: 'shoes_sneakers',
  ),
  GameCategory(
    id: 'accessories',
    slots: [Slot.head, Slot.hand, Slot.back],
    buttonColor: Color(0xFFFFDAC1),
    colors: accessoryColors,
    previewItemId: 'head_crown',
  ),
  GameCategory(
    id: 'jewelry',
    slots: [Slot.neck, Slot.ears, Slot.wrist],
    buttonColor: Color(0xFFFFC2DF),
    colors: jewelryColors,
    iconArt: 'assets/svg/icons/jewelry.svg',
  ),
  GameCategory(
    id: 'glasses',
    slots: [Slot.eyes],
    buttonColor: Color(0xFFBFE3FF),
    colors: glassesColors,
    iconArt: 'assets/svg/icons/glasses.svg',
  ),
  GameCategory(
    id: 'background',
    slots: [Slot.background],
    buttonColor: Color(0xFFA0E7E5),
    colors: backgroundColors,
    previewItemId: 'bg_rainbow',
  ),
];

// ---------------------------------------------------------------------------
// Rules
// ---------------------------------------------------------------------------

/// What the doll wears when the game starts.
const List<String> starterItemIds = ['hair_long', 'bg_sky'];

/// These slots always have something in them (tapping again keeps it on).
const Set<Slot> requiredSlots = {Slot.hair, Slot.background};

/// Putting on an item in the key slot takes off the items in the value slots.
const Map<Slot, List<Slot>> slotConflicts = {
  Slot.dress: [Slot.top, Slot.skirt],
  Slot.top: [Slot.dress],
  Slot.skirt: [Slot.dress],
};

/// When switching to another item in these slots, keep the chosen color
/// (so a new hair style keeps the hair color).
const Set<Slot> keepColorWhenSwitching = {Slot.hair};

/// How many looks the "My Looks" gallery keeps (newest first).
const int maxSavedLooks = 100;

/// Things that sparkle with moving glints when she wears them. Glitter nail
/// polish and nail gems sparkle too.
const Set<ItemShape> shinyShapes = {
  ItemShape.headCrown,
  ItemShape.headTiara,
  ItemShape.handWand,
  ItemShape.eyesSunAviator,
  ItemShape.eyesSunHeart,
  ItemShape.eyesSunStar,
  ItemShape.eyesSunBig,
  ItemShape.eyesSunSport,
  ItemShape.neckPearl,
  ItemShape.neckHeart,
  ItemShape.neckStar,
  ItemShape.neckGold,
  ItemShape.neckRainbow,
  ItemShape.neckChoker,
  ItemShape.neckCrystal,
  ItemShape.neckButterfly,
  ItemShape.earsStud,
  ItemShape.earsHoop,
  ItemShape.earsHeart,
  ItemShape.earsStar,
  ItemShape.earsGem,
  ItemShape.wristBeads,
  ItemShape.wristBangle,
  ItemShape.wristCharm,
  ItemShape.wristFriendship,
  ItemShape.headUnicorn,
  ItemShape.eyesSunRainbow,
  ItemShape.neckDiamond,
  ItemShape.shoesSparkly,
};

// ---------------------------------------------------------------------------
// Poses and dancing
// ---------------------------------------------------------------------------

/// Each tap on the Pose button does the next pose in this list.
const List<DollPose> poseButtonOrder = [
  DollPose.wave,
  DollPose.twirl,
  DollPose.peace,
  DollPose.hips,
  DollPose.curtsy,
  DollPose.jump,
];

/// How long she dances after the Dance button.
const Duration danceTime = Duration(seconds: 10);

// ---------------------------------------------------------------------------
// Dress-up challenges (the Challenge button)
//
// Every item lists the themes it fits (`themes:` above). Wearing more items
// that fit the theme gives more stars. There is always at least one star.
// ---------------------------------------------------------------------------

/// Matching items needed for two stars, and for three stars.
const int matchesForTwoStars = 2;
const int matchesForThreeStars = 4;

/// The card color of each theme (top and bottom of the card).
const Map<ChallengeTheme, List<Color>> themeCardColors = {
  ChallengeTheme.beach: [Color(0xFF9FE3FF), Color(0xFFFFE7A8)],
  ChallengeTheme.snow: [Color(0xFFD6ECFF), Color(0xFFFFFFFF)],
  ChallengeTheme.party: [Color(0xFFFFC2E2), Color(0xFFFFF0A8)],
  ChallengeTheme.ball: [Color(0xFFE3D4FF), Color(0xFFFFD1E8)],
  ChallengeTheme.garden: [Color(0xFFBDF2C4), Color(0xFFFFF6C9)],
  ChallengeTheme.bedtime: [Color(0xFF6C63C9), Color(0xFFB6A6FF)],
};

// ---------------------------------------------------------------------------
// Activities (Makeup, Hair Salon, Nails)
//
// The order of these lists is saved with looks: add new colors at the END.
// ---------------------------------------------------------------------------

const List<ToolColor> lipstickColors = [
  ToolColor(Color(0xFFFF5C9A)), // pink
  ToolColor(Color(0xFFE8384F)), // cherry red
  ToolColor(Color(0xFFFF8A65)), // coral
  ToolColor(Color(0xFFB0397A)), // berry
  ToolColor(Color(0xFF9B5DE5)), // purple
  ToolColor(Color(0xFFFFA3B8)), // soft rose
];

const List<ToolColor> blushColors = [
  ToolColor(Color(0xFFFF7FA8)), // pink
  ToolColor(Color(0xFFFF9F6E)), // peach
  ToolColor(Color(0xFFFF4F7E)), // raspberry
  ToolColor(Color(0xFFC08CFF)), // lilac
];

const List<ToolColor> eyeshadowColors = [
  ToolColor(Color(0xFFB98CFF)), // lavender
  ToolColor(Color(0xFF6FBDFF)), // sky blue
  ToolColor(Color(0xFF6EDCA8)), // mint
  ToolColor(Color(0xFFFFC94D)), // gold
  ToolColor(Color(0xFFFF8FC7)), // pink
  ToolColor(Color(0xFFF2B8FF), glitter: true), // glitter
];

/// Eyelash styles (0 means no extra lashes).
const int lashStyleCount = 3;

const List<ToolColor> hairDyeColors = [
  ToolColor(Color(0xFFFF6FB5)), // pink
  ToolColor(Color(0xFFB47CFF)), // purple
  ToolColor(Color(0xFF58A8FF)), // blue
  ToolColor(Color(0xFF3FD5C8)), // teal
  ToolColor(Color(0xFF7EDB6A)), // green
  ToolColor(Color(0xFFFFD84D)), // yellow
  ToolColor(Color(0xFFFF9A3C)), // orange
  ToolColor(Color(0xFFFF6FB5), rainbow: true), // rainbow
];

/// The bands of the rainbow hair dye, top to bottom.
const List<Color> rainbowColors = [
  Color(0xFFFF5F6D), // red
  Color(0xFFFFA24C), // orange
  Color(0xFFFFE066), // yellow
  Color(0xFF7EDB6A), // green
  Color(0xFF5CB8FF), // blue
  Color(0xFFB57CFF), // purple
];

const List<ToolColor> nailColors = [
  ToolColor(Color(0xFFF2405C)), // red
  ToolColor(Color(0xFFFF7EB6)), // pink
  ToolColor(Color(0xFFFF8A5C)), // coral
  ToolColor(Color(0xFFFFD84D)), // yellow
  ToolColor(Color(0xFF6EE0A8)), // mint
  ToolColor(Color(0xFF3CCFD6)), // turquoise
  ToolColor(Color(0xFF6AA8FF)), // blue
  ToolColor(Color(0xFFA57CFF)), // purple
  ToolColor(Color(0xFFFFFFFF)), // white
  ToolColor(Color(0xFFF6B8FF), glitter: true), // glitter
];

/// The hair style the Hair Salon works on (other styles replace salon hair).
const String salonHairId = 'hair_long';

/// The most stickers the face can have (the oldest goes when adding more).
const int maxFaceStickers = 8;
