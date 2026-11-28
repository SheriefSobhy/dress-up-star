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

/// Every Beach & Swim thing fits the beach and summer picture cards.
const Set<ChallengeTheme> _beachThemes = {
  ChallengeTheme.beach,
  ChallengeTheme.summer,
};

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

  // Jackets and coats
  GameItem(
    id: 'jacket_denim',
    themes: {ChallengeTheme.garden, ChallengeTheme.party},
    shape: ItemShape.jacketDenim,
    color: Color(0xFF5F8FD9),
  ),
  GameItem(
    id: 'jacket_puffer',
    themes: {ChallengeTheme.snow},
    shape: ItemShape.jacketPuffer,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'jacket_raincoat',
    themes: {ChallengeTheme.garden, ChallengeTheme.snow},
    shape: ItemShape.jacketRain,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'jacket_cardigan',
    themes: {
      ChallengeTheme.bedtime,
      ChallengeTheme.snow,
      ChallengeTheme.garden,
    },
    shape: ItemShape.jacketCardigan,
    color: Color(0xFF8EE08A),
  ),
  GameItem(
    id: 'jacket_blazer',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.jacketBlazer,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'jacket_hoodie',
    themes: {ChallengeTheme.snow, ChallengeTheme.bedtime},
    shape: ItemShape.jacketHoodie,
    color: Color(0xFF5CD6D6),
  ),

  // Pants
  GameItem(
    id: 'pants_jeans',
    themes: {ChallengeTheme.garden, ChallengeTheme.party},
    shape: ItemShape.pantsJeans,
    color: Color(0xFF5F8FD9),
  ),
  GameItem(
    id: 'pants_leggings',
    themes: {ChallengeTheme.snow, ChallengeTheme.bedtime},
    shape: ItemShape.pantsLeggings,
    color: Color(0xFFD873F0),
  ),
  GameItem(
    id: 'pants_shorts',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.pantsShorts,
    color: Color(0xFFFFA45C),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'pants_overalls',
    themes: {ChallengeTheme.garden},
    shape: ItemShape.pantsOveralls,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'pants_flared',
    themes: {ChallengeTheme.party},
    shape: ItemShape.pantsFlared,
    color: Color(0xFFFF8FC7),
  ),

  // Hats
  GameItem(
    id: 'hat_sun',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.hatSun,
    color: Color(0xFFFFE08A),
  ),
  GameItem(
    id: 'hat_beanie',
    themes: {ChallengeTheme.snow, ChallengeTheme.bedtime},
    shape: ItemShape.hatBeanie,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'hat_cap',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.hatCap,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'hat_beret',
    themes: {ChallengeTheme.party, ChallengeTheme.ball},
    shape: ItemShape.hatBeret,
    color: Color(0xFFD873F0),
  ),
  GameItem(
    id: 'hat_witch',
    themes: {ChallengeTheme.party, ChallengeTheme.bedtime},
    shape: ItemShape.hatWitch,
    color: Color(0xFF8A5CC9),
  ),
  GameItem(
    id: 'shop_hat_flower_crown',
    themes: {ChallengeTheme.garden, ChallengeTheme.ball, ChallengeTheme.beach},
    shape: ItemShape.hatFlower,
    color: Color(0xFFFF8FC7),
    price: 5,
  ),

  // Costumes
  GameItem(
    id: 'costume_princess',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.costumePrincess,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'shop_costume_mermaid',
    themes: {ChallengeTheme.beach, ChallengeTheme.party},
    shape: ItemShape.costumeMermaid,
    color: Color(0xFF5CD6D6),
    price: 12,
  ),
  GameItem(
    id: 'shop_costume_fairy',
    themes: {ChallengeTheme.garden, ChallengeTheme.bedtime},
    shape: ItemShape.costumeFairy,
    color: Color(0xFFFF8FC7),
    price: 9,
  ),
  GameItem(
    id: 'shop_costume_astronaut',
    themes: {ChallengeTheme.party, ChallengeTheme.bedtime},
    shape: ItemShape.costumeAstronaut,
    color: Color(0xFFFFFFFF),
    price: 10,
  ),
  GameItem(
    id: 'costume_chef',
    themes: {ChallengeTheme.party},
    shape: ItemShape.costumeChef,
    color: Color(0xFFFFFFFF),
  ),
  GameItem(
    id: 'costume_doctor',
    themes: {ChallengeTheme.party},
    shape: ItemShape.costumeDoctor,
    color: Color(0xFFFFFFFF),
  ),

  // Pajamas
  GameItem(
    id: 'pajama_stars',
    themes: {ChallengeTheme.bedtime},
    shape: ItemShape.pajamaStars,
    color: Color(0xFF7C8CE8),
    pattern: ItemPattern.stars,
  ),
  GameItem(
    id: 'pajama_hearts',
    themes: {ChallengeTheme.bedtime},
    shape: ItemShape.pajamaHearts,
    color: Color(0xFFFF9EC8),
    pattern: ItemPattern.hearts,
  ),
  GameItem(
    id: 'shop_pajama_bunny',
    themes: {ChallengeTheme.bedtime, ChallengeTheme.snow},
    shape: ItemShape.pajamaBunny,
    color: Color(0xFFE3D4FF),
    price: 7,
  ),
  GameItem(
    id: 'pajama_cloud',
    themes: {ChallengeTheme.bedtime},
    shape: ItemShape.pajamaCloud,
    color: Color(0xFF8FCBFF),
  ),

  // Sportswear
  GameItem(
    id: 'sport_tennis',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.sportTennis,
    color: Color(0xFF8EE08A),
  ),
  GameItem(
    id: 'sport_ballet',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.sportBallet,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'sport_football',
    themes: {ChallengeTheme.garden},
    shape: ItemShape.sportFootball,
    color: Color(0xFFFF6B6B),
  ),
  GameItem(
    id: 'sport_tracksuit',
    themes: {ChallengeTheme.snow, ChallengeTheme.garden},
    shape: ItemShape.sportTracksuit,
    color: Color(0xFFB079F2),
  ),

  // Socks and tights
  GameItem(
    id: 'socks_striped',
    themes: {ChallengeTheme.party, ChallengeTheme.bedtime},
    shape: ItemShape.socksStriped,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'socks_frilly',
    themes: {ChallengeTheme.ball, ChallengeTheme.party},
    shape: ItemShape.socksFrilly,
    color: Color(0xFFFFD1E8),
  ),
  GameItem(
    id: 'socks_rainbow_tights',
    themes: {ChallengeTheme.party, ChallengeTheme.snow},
    shape: ItemShape.socksRainbow,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'socks_knee',
    themes: {ChallengeTheme.snow, ChallengeTheme.garden},
    shape: ItemShape.socksKnee,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'socks_glitter_tights',
    themes: {ChallengeTheme.ball, ChallengeTheme.party, ChallengeTheme.snow},
    shape: ItemShape.socksGlitter,
    color: Color(0xFFD873F0),
  ),

  // More dresses, tops, skirts and shoes
  GameItem(
    id: 'dress_sailor',
    themes: {ChallengeTheme.beach},
    shape: ItemShape.dressSailor,
    color: Color(0xFF5F8FD9),
  ),
  GameItem(
    id: 'dress_strawberry',
    themes: {ChallengeTheme.garden, ChallengeTheme.party},
    shape: ItemShape.dressStrawberry,
    color: Color(0xFFFF5C7A),
  ),
  GameItem(
    id: 'top_blouse',
    themes: {ChallengeTheme.ball, ChallengeTheme.garden},
    shape: ItemShape.topBlouse,
    color: Color(0xFFFFD1E8),
  ),
  GameItem(
    id: 'top_polo',
    themes: {ChallengeTheme.beach, ChallengeTheme.garden},
    shape: ItemShape.topPolo,
    color: Color(0xFF8EE08A),
  ),
  GameItem(
    id: 'skirt_pleated',
    themes: {ChallengeTheme.party, ChallengeTheme.garden},
    shape: ItemShape.skirtPleated,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'skirt_ruffle',
    themes: {ChallengeTheme.beach, ChallengeTheme.party},
    shape: ItemShape.skirtRuffle,
    color: Color(0xFFFFA45C),
  ),
  GameItem(
    id: 'shoes_mary_janes',
    themes: {ChallengeTheme.ball, ChallengeTheme.bedtime},
    shape: ItemShape.shoesMaryJanes,
    color: Color(0xFFFF6B6B),
  ),
  GameItem(
    id: 'shoes_roller_skates',
    themes: {ChallengeTheme.party, ChallengeTheme.beach},
    shape: ItemShape.shoesRoller,
    color: Color(0xFF5CD6D6),
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

  // -------------------------------------------------------------------------
  // Beach & Swim. All swimwear is modest; four are Star Shop items.
  // -------------------------------------------------------------------------
  GameItem(
    id: 'swim_frilly',
    themes: _beachThemes,
    shape: ItemShape.swimFrilly,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'swim_polka',
    themes: _beachThemes,
    shape: ItemShape.swimPolka,
    color: Color(0xFFFF6B8B),
    pattern: ItemPattern.dots,
  ),
  GameItem(
    id: 'swim_rainbow',
    themes: _beachThemes,
    shape: ItemShape.swimRainbow,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'swim_sporty',
    themes: _beachThemes,
    shape: ItemShape.swimSporty,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'swim_dress_ruffle',
    themes: _beachThemes,
    shape: ItemShape.swimDressRuffle,
    color: Color(0xFFD873F0),
  ),
  GameItem(
    id: 'swim_dress_skater',
    themes: _beachThemes,
    shape: ItemShape.swimDressSkater,
    color: Color(0xFFFFA45C),
  ),
  GameItem(
    id: 'swim_dress_peplum',
    themes: _beachThemes,
    shape: ItemShape.swimDressPeplum,
    color: Color(0xFF8EE08A),
  ),
  GameItem(
    id: 'swim_rash_shorts',
    themes: _beachThemes,
    shape: ItemShape.swimRashShorts,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'swim_rash_sport',
    themes: _beachThemes,
    shape: ItemShape.swimRashSport,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'swim_rash_leggings',
    themes: _beachThemes,
    shape: ItemShape.swimRashLeggings,
    color: Color(0xFFB79CFF),
  ),
  GameItem(
    id: 'swim_burkini_waves',
    themes: _beachThemes,
    shape: ItemShape.swimBurkiniWaves,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'swim_burkini_flower',
    themes: _beachThemes,
    shape: ItemShape.swimBurkiniFlower,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'beach_sundress',
    themes: _beachThemes,
    shape: ItemShape.beachSundress,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'beach_kaftan',
    themes: _beachThemes,
    shape: ItemShape.beachKaftan,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'beach_robe',
    themes: _beachThemes,
    shape: ItemShape.beachRobe,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'hat_straw',
    themes: _beachThemes,
    shape: ItemShape.hatStraw,
    color: Color(0xFFFFE08A),
  ),
  GameItem(
    id: 'hat_bucket',
    themes: _beachThemes,
    shape: ItemShape.hatBucket,
    color: Color(0xFF7CB8FF),
  ),
  GameItem(
    id: 'hat_floppy',
    themes: _beachThemes,
    shape: ItemShape.hatFloppy,
    color: Color(0xFFFFA45C),
  ),
  GameItem(
    id: 'hat_visor',
    themes: _beachThemes,
    shape: ItemShape.hatVisor,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'hat_swim_cap',
    themes: _beachThemes,
    shape: ItemShape.hatSwimCap,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'hat_swim_cap_flower',
    themes: _beachThemes,
    shape: ItemShape.hatSwimCapFlower,
    color: Color(0xFFD873F0),
  ),
  GameItem(
    id: 'eyes_goggles',
    themes: _beachThemes,
    shape: ItemShape.eyesGoggles,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'eyes_swim_mask',
    themes: _beachThemes,
    shape: ItemShape.eyesSwimMask,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'shoes_flip_flops',
    themes: _beachThemes,
    shape: ItemShape.shoesFlipFlops,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'shoes_flip_flower',
    themes: _beachThemes,
    shape: ItemShape.shoesFlipFlower,
    color: Color(0xFF5CD6D6),
  ),
  GameItem(
    id: 'shoes_jelly',
    themes: _beachThemes,
    shape: ItemShape.shoesJelly,
    color: Color(0xFFD873F0),
  ),
  GameItem(
    id: 'hand_floaties',
    themes: _beachThemes,
    shape: ItemShape.handFloaties,
    color: Color(0xFFFFA45C),
  ),
  GameItem(
    id: 'hand_ring_duck',
    themes: _beachThemes,
    shape: ItemShape.handRingDuck,
    color: Color(0xFFFFD84D),
  ),
  GameItem(
    id: 'hand_ring_donut',
    themes: _beachThemes,
    shape: ItemShape.handRingDonut,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'hand_beach_ball',
    themes: _beachThemes,
    shape: ItemShape.handBeachBall,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'hand_bucket',
    themes: _beachThemes,
    shape: ItemShape.handBucket,
    color: Color(0xFFFF6B8B),
  ),
  GameItem(
    id: 'hand_ice_cream',
    themes: _beachThemes,
    shape: ItemShape.handIceCream,
    color: Color(0xFFFF8FC7),
  ),
  GameItem(
    id: 'shop_swim_mermaid',
    themes: _beachThemes,
    shape: ItemShape.swimMermaid,
    color: Color(0xFF5CD6D6),
    price: 6,
  ),
  GameItem(
    id: 'shop_swim_burkini_rainbow',
    themes: _beachThemes,
    shape: ItemShape.swimBurkiniRainbow,
    color: Color(0xFFB79CFF),
    price: 9,
  ),
  GameItem(
    id: 'shop_ring_flamingo',
    themes: _beachThemes,
    shape: ItemShape.handRingFlamingo,
    color: Color(0xFFFF8FC7),
    price: 5,
  ),
  GameItem(
    id: 'shop_shoes_jelly_sparkle',
    themes: _beachThemes,
    shape: ItemShape.shoesJellySparkle,
    color: Color(0xFFFF8FC7),
    price: 4,
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
    id: 'jackets',
    slots: [Slot.jacket],
    buttonColor: Color(0xFFFFD3B6),
    colors: clothesColors,
    previewItemId: 'jacket_denim',
  ),
  GameCategory(
    id: 'skirts',
    slots: [Slot.skirt],
    buttonColor: Color(0xFFFFF0A8),
    colors: clothesColors,
    previewItemId: 'skirt_tutu',
  ),
  GameCategory(
    id: 'pants',
    slots: [Slot.pants],
    buttonColor: Color(0xFFBFD7FF),
    colors: clothesColors,
    previewItemId: 'pants_jeans',
  ),
  GameCategory(
    id: 'costumes',
    slots: [Slot.dress],
    group: 'costume',
    buttonColor: Color(0xFFF5C6EC),
    colors: clothesColors,
    previewItemId: 'costume_princess',
  ),
  GameCategory(
    id: 'pajamas',
    slots: [Slot.dress],
    group: 'pajama',
    buttonColor: Color(0xFFC9CBF5),
    colors: clothesColors,
    previewItemId: 'pajama_stars',
  ),
  GameCategory(
    id: 'sportswear',
    slots: [Slot.dress],
    group: 'sport',
    buttonColor: Color(0xFFC8F0B8),
    colors: clothesColors,
    previewItemId: 'sport_football',
  ),
  GameCategory(
    id: 'beach',
    slots: [Slot.dress, Slot.jacket],
    group: 'beach',
    buttonColor: Color(0xFFAEE9FF),
    colors: clothesColors,
    iconArt: 'assets/svg/icons/beach.svg',
  ),
  GameCategory(
    id: 'socks',
    slots: [Slot.socks],
    buttonColor: Color(0xFFFFE3EE),
    colors: clothesColors,
    previewItemId: 'socks_striped',
  ),
  GameCategory(
    id: 'shoes',
    slots: [Slot.shoes],
    buttonColor: Color(0xFFC7CEEA),
    colors: clothesColors,
    previewItemId: 'shoes_sneakers',
  ),
  GameCategory(
    id: 'hats',
    slots: [Slot.hat],
    buttonColor: Color(0xFFFFE9B0),
    colors: clothesColors,
    previewItemId: 'hat_sun',
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
  Slot.dress: [Slot.top, Slot.skirt, Slot.pants],
  Slot.top: [Slot.dress],
  Slot.skirt: [Slot.dress, Slot.pants],
  Slot.pants: [Slot.dress, Slot.skirt],
  Slot.hat: [Slot.head],
  Slot.head: [Slot.hat],
};

/// Clothes with legs (or that wrap her legs): they stand still with her
/// instead of swinging like a skirt.
const Set<ItemShape> stiffShapes = {
  ItemShape.costumeMermaid,
  ItemShape.costumeAstronaut,
  ItemShape.costumeChef,
  ItemShape.costumeDoctor,
  ItemShape.pajamaStars,
  ItemShape.pajamaBunny,
  ItemShape.pajamaCloud,
  ItemShape.sportFootball,
  ItemShape.sportTracksuit,
  ItemShape.swimFrilly,
  ItemShape.swimPolka,
  ItemShape.swimRainbow,
  ItemShape.swimMermaid,
  ItemShape.swimSporty,
  ItemShape.swimRashShorts,
  ItemShape.swimRashSport,
  ItemShape.swimRashLeggings,
  ItemShape.swimBurkiniWaves,
  ItemShape.swimBurkiniFlower,
  ItemShape.swimBurkiniRainbow,
};

/// Things that cover all her hair: burkini swim hoods and swim caps.
const Set<ItemShape> hairCoveringShapes = {
  ItemShape.swimBurkiniWaves,
  ItemShape.swimBurkiniFlower,
  ItemShape.swimBurkiniRainbow,
  ItemShape.hatSwimCap,
  ItemShape.hatSwimCapFlower,
};

/// Clothes that cover her feet, so shoes and socks are not drawn.
const Set<ItemShape> footCoveringShapes = {
  ItemShape.costumeMermaid,
  ItemShape.pajamaBunny,
};

/// Clothes whose sleeves reach the wrist (the bent elbow gets their color).
const Set<ItemShape> longSleeveShapes = {
  ItemShape.topSweater,
  ItemShape.jacketDenim,
  ItemShape.jacketPuffer,
  ItemShape.jacketRain,
  ItemShape.jacketCardigan,
  ItemShape.jacketBlazer,
  ItemShape.jacketHoodie,
  ItemShape.costumeAstronaut,
  ItemShape.costumeChef,
  ItemShape.costumeDoctor,
  ItemShape.pajamaStars,
  ItemShape.pajamaBunny,
  ItemShape.pajamaCloud,
  ItemShape.sportTracksuit,
  ItemShape.swimRashShorts,
  ItemShape.swimRashSport,
  ItemShape.swimRashLeggings,
  ItemShape.swimBurkiniWaves,
  ItemShape.swimBurkiniFlower,
  ItemShape.swimBurkiniRainbow,
  ItemShape.beachRobe,
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
  ItemShape.socksGlitter,
  ItemShape.swimMermaid,
  ItemShape.shoesJellySparkle,
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
  ChallengeTheme.sports: [Color(0xFFBFE8FF), Color(0xFFC9F5B0)],
  ChallengeTheme.space: [Color(0xFF2E2A6E), Color(0xFF7B5FC4)],
  ChallengeTheme.costume: [Color(0xFFFFD6A8), Color(0xFFD9C2FF)],
  ChallengeTheme.summer: [Color(0xFFFFF3A8), Color(0xFFA8E8FF)],
};

/// The themes of the Challenge button.
const List<ChallengeTheme> challengeThemes = [
  ChallengeTheme.beach,
  ChallengeTheme.snow,
  ChallengeTheme.party,
  ChallengeTheme.ball,
  ChallengeTheme.garden,
  ChallengeTheme.bedtime,
];

/// Items that fit the Fashion Show's own themes (besides the `themes:` of
/// each item above).
const Map<ChallengeTheme, Set<String>> extraThemeItems = {
  ChallengeTheme.sports: {
    'sport_tennis', 'sport_football', 'sport_tracksuit', 'sport_ballet',
    'shoes_sneakers', 'shoes_roller_skates', 'hat_cap', 'hair_ponytail',
    'top_tshirt', 'top_polo', 'top_tank', 'pants_shorts', 'pants_leggings',
    'socks_knee', 'socks_striped', 'eyes_sun_sport', 'wrist_friendship',
    'bg_sky', 'bg_garden', //
  },
  ChallengeTheme.space: {
    'shop_costume_astronaut', 'bg_night', 'eyes_star', 'eyes_star_frame',
    'neck_star', 'ears_star', 'top_tshirt_stars', 'pajama_stars',
    'hair_space_buns', 'shoes_boots', 'shop_boots_sparkly', 'shop_boots_gold',
    'socks_glitter_tights', 'pants_leggings', 'hand_wand', //
  },
  ChallengeTheme.costume: {
    'costume_princess', 'shop_costume_mermaid', 'shop_costume_fairy',
    'shop_costume_astronaut', 'costume_chef', 'costume_doctor', 'hat_witch',
    'shop_wings_butterfly', 'shop_wings_fairy', 'shop_unicorn_headband',
    'shop_pajama_bunny', 'dress_mermaid', 'dress_fairy', 'dress_strawberry',
    'head_crown', 'hand_wand', 'shoes_boots', 'bg_castle', 'bg_candy', //
  },
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
