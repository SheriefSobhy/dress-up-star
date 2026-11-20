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
    shape: ItemShape.hairLong,
    color: Color(0xFF5B3A29),
  ),
  GameItem(id: 'hair_bob', shape: ItemShape.hairBob, color: Color(0xFF5B3A29)),
  GameItem(
    id: 'hair_pigtails',
    shape: ItemShape.hairPigtails,
    color: Color(0xFF5B3A29),
  ),
  GameItem(id: 'hair_bun', shape: ItemShape.hairBun, color: Color(0xFF5B3A29)),
  GameItem(
    id: 'hair_curly',
    shape: ItemShape.hairCurly,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_braids',
    shape: ItemShape.hairBraids,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_ponytail',
    shape: ItemShape.hairPonytail,
    color: Color(0xFF5B3A29),
  ),
  GameItem(
    id: 'hair_space_buns',
    shape: ItemShape.hairSpaceBuns,
    color: Color(0xFF5B3A29),
  ),

  // Dresses
  GameItem(
    id: 'dress_princess',
    shape: ItemShape.dressPrincess,
    color: Color(0xFFFF8FC7),
    pattern: ItemPattern.stars,
  ),
  GameItem(
    id: 'dress_sun',
    shape: ItemShape.dressSun,
    color: Color(0xFFFFD84D),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'dress_tutu',
    shape: ItemShape.dressTutu,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'dress_long',
    shape: ItemShape.dressLong,
    color: Color(0xFF7CB8FF),
    pattern: ItemPattern.hearts,
  ),
  GameItem(
    id: 'dress_stripes',
    shape: ItemShape.dressSun,
    color: Color(0xFF8EE08A),
    pattern: ItemPattern.stripes,
  ),
  GameItem(
    id: 'dress_mermaid',
    shape: ItemShape.dressMermaid,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'dress_fairy',
    shape: ItemShape.dressFairy,
    color: Color(0xFF8EE08A),
  ),
  GameItem(
    id: 'dress_party',
    shape: ItemShape.dressParty,
    color: Color(0xFFFF6B8B),
    pattern: ItemPattern.dots,
  ),

  // Tops
  GameItem(
    id: 'top_tshirt',
    shape: ItemShape.topTshirt,
    color: Color(0xFFFF6B8B),
    pattern: ItemPattern.hearts,
  ),
  GameItem(id: 'top_tank', shape: ItemShape.topTank, color: Color(0xFF5CD6D6)),
  GameItem(
    id: 'top_sweater',
    shape: ItemShape.topSweater,
    color: Color(0xFFB79CFF),
    pattern: ItemPattern.stripes,
  ),
  GameItem(
    id: 'top_tshirt_stars',
    shape: ItemShape.topTshirt,
    color: Color(0xFF7CB8FF),
    pattern: ItemPattern.stars,
  ),

  // Skirts
  GameItem(
    id: 'skirt_aline',
    shape: ItemShape.skirtAline,
    color: Color(0xFF7CB8FF),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'skirt_tutu',
    shape: ItemShape.skirtTutu,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'skirt_long',
    shape: ItemShape.skirtLong,
    color: Color(0xFFD873F0),
    pattern: ItemPattern.stars,
  ),

  // Shoes
  GameItem(
    id: 'shoes_sneakers',
    shape: ItemShape.shoesSneakers,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'shoes_boots',
    shape: ItemShape.shoesBoots,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'shoes_flats',
    shape: ItemShape.shoesFlats,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'shoes_sandals',
    shape: ItemShape.shoesSandals,
    color: Color(0xFFFFD84D),
  ),

  // Accessories: crowns, bows and other head things
  GameItem(
    id: 'head_crown',
    shape: ItemShape.headCrown,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'head_tiara',
    shape: ItemShape.headTiara,
    color: Color(0xFFE6E9F0),
  ),
  GameItem(id: 'head_bow', shape: ItemShape.headBow, color: Color(0xFFFF6B8B)),
  GameItem(
    id: 'head_flower',
    shape: ItemShape.headFlower,
    color: Color(0xFFFF8FC7),
  ),

  // Glasses (in the Glasses category; the ids are older than it)
  GameItem(
    id: 'eyes_round',
    shape: ItemShape.eyesRound,
    color: Color(0xFFD873F0),
  ),
  GameItem(
    id: 'eyes_heart',
    shape: ItemShape.eyesHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'eyes_star',
    shape: ItemShape.eyesStar,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'eyes_wire',
    shape: ItemShape.eyesWire,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'eyes_cat_eye',
    shape: ItemShape.eyesCatEye,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'eyes_heart_frame',
    shape: ItemShape.eyesHeartFrame,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'eyes_star_frame',
    shape: ItemShape.eyesStarFrame,
    color: Color(0xFFB79CFF),
  ),
  GameItem(id: 'eyes_big', shape: ItemShape.eyesBig, color: Color(0xFF5CD6D6)),

  // Sunglasses
  GameItem(
    id: 'eyes_sun_aviator',
    shape: ItemShape.eyesSunAviator,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'eyes_sun_heart',
    shape: ItemShape.eyesSunHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'eyes_sun_star',
    shape: ItemShape.eyesSunStar,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'eyes_sun_big',
    shape: ItemShape.eyesSunBig,
    color: Color(0xFF3A3550),
  ),
  GameItem(
    id: 'eyes_sun_sport',
    shape: ItemShape.eyesSunSport,
    color: Color(0xFF5CD6D6),
  ),

  // Jewelry: necklaces
  GameItem(
    id: 'neck_pearl',
    shape: ItemShape.neckPearl,
    color: Color(0xFFFFFFFF),
  ),
  GameItem(
    id: 'neck_heart',
    shape: ItemShape.neckHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'neck_star',
    shape: ItemShape.neckStar,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'neck_gold',
    shape: ItemShape.neckGold,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'neck_rainbow',
    shape: ItemShape.neckRainbow,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'neck_choker',
    shape: ItemShape.neckChoker,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'neck_crystal',
    shape: ItemShape.neckCrystal,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'neck_butterfly',
    shape: ItemShape.neckButterfly,
    color: Color(0xFFD873F0),
  ),

  // Jewelry: earrings
  GameItem(
    id: 'ears_stud',
    shape: ItemShape.earsStud,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'ears_hoop',
    shape: ItemShape.earsHoop,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'ears_heart',
    shape: ItemShape.earsHeart,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'ears_star',
    shape: ItemShape.earsStar,
    color: Color(0xFFFFD84D),
  ),
  GameItem(id: 'ears_gem', shape: ItemShape.earsGem, color: Color(0xFFD873F0)),

  // Jewelry: bracelets
  GameItem(
    id: 'wrist_beads',
    shape: ItemShape.wristBeads,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'wrist_bangle',
    shape: ItemShape.wristBangle,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'wrist_charm',
    shape: ItemShape.wristCharm,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'wrist_friendship',
    shape: ItemShape.wristFriendship,
    color: Color(0xFF5CD6D6),
  ),

  // Accessories: bags) and things to hold
  GameItem(
    id: 'hand_bag',
    shape: ItemShape.handBag,
    color: Color(0xFFFF8FC7),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'hand_wand',
    shape: ItemShape.handWand,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'hand_balloon',
    shape: ItemShape.handBalloon,
    color: Color(0xFF7CB8FF),
  ),

  // Backgrounds
  GameItem(id: 'bg_sky', shape: ItemShape.bgSky, color: Color(0xFFBDE3FF)),
  GameItem(
    id: 'bg_garden',
    shape: ItemShape.bgGarden,
    color: Color(0xFFBDE3FF),
  ),
  GameItem(
    id: 'bg_castle',
    shape: ItemShape.bgCastle,
    color: Color(0xFFFFD1E8),
  ),
  GameItem(
    id: 'bg_rainbow',
    shape: ItemShape.bgRainbow,
    color: Color(0xFFE3D4FF),
  ),
  GameItem(id: 'bg_night', shape: ItemShape.bgNight, color: Color(0xFFE3D4FF)),
  GameItem(
    id: 'bg_hearts',
    shape: ItemShape.bgHearts,
    color: Color(0xFFFFD1E8),
  ),
  GameItem(id: 'bg_beach', shape: ItemShape.bgBeach, color: Color(0xFFBDE3FF)),
  GameItem(id: 'bg_candy', shape: ItemShape.bgCandy, color: Color(0xFFFFD1E8)),
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
    slots: [Slot.head, Slot.hand],
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
