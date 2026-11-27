import 'package:flutter/material.dart';

import '../models/unlockable.dart';
import 'game_config.dart';

/// Everything for Room Decorating.
///
/// Sizes are in "room units": a room is [roomUnits] wide. Furniture drawings
/// are in `assets/svg/room/`, made by `tool/generate_room_art.dart` (its
/// canvas for an item must match the size here).

const double roomUnits = 400;

/// Where the wall meets the floor (part of the room's height).
const double roomWallPart = 0.6;

/// Most things one room can hold (keeps old phones fast).
const int maxRoomThings = 30;

/// The size button steps through these.
const List<double> roomSizes = [0.75, 1.0, 1.25, 1.5];
const double minRoomScale = 0.6;
const double maxRoomScale = 1.7;

/// The buttons in the room's bottom bar, in order.
enum RoomCategory {
  /// The doll and her pets.
  friends(Icons.face_3_rounded, Color(0xFFFF6FA8)),

  wallpaper(Icons.wallpaper_rounded, Color(0xFFFF8FC7)),
  floor(Icons.grid_view_rounded, Color(0xFFE0A56B)),
  bed(Icons.bed_rounded, Color(0xFFB79CFF)),
  storage(Icons.shelves, Color(0xFF7CC7E8)),
  desk(Icons.desk_rounded, Color(0xFFFFB347)),
  lamp(Icons.lightbulb_rounded, Color(0xFFFFCF3F)),
  window(Icons.window_rounded, Color(0xFF7CB8FF)),
  toy(Icons.toys_rounded, Color(0xFFFF7F7F)),
  plant(Icons.local_florist_rounded, Color(0xFF6CC47A)),
  art(Icons.image_rounded, Color(0xFFD873F0)),
  petBed(Icons.pets_rounded, Color(0xFFC99A6B));

  const RoomCategory(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// What is drawn on the wall or over the wooden floor.
enum RoomSurface { none, wallpaper, floor }

/// The shape of a window's glass (the sky is drawn behind it).
enum PaneShape { rect, round, arch }

/// One thing for the room.
class RoomItem with Unlockable {
  const RoomItem(
    this.id,
    this.category, {
    this.w = 0,
    this.h = 0,
    this.price = 0,
    this.surface = RoomSurface.none,
    this.colors = const [],
    this.glow,
    this.pane,
    this.paneShape = PaneShape.rect,
    this.petArt,
    this.petColor,
    this.petCrop,
  });

  @override
  final String id;
  final RoomCategory category;
  final double w;
  final double h;

  @override
  final int price;

  /// Wallpapers and floors fill the room; they are not placed.
  final RoomSurface surface;

  /// The colors of a wallpaper or floor: base, then the print.
  final List<Color> colors;

  /// Lamps: where the light is (0..1 of the item).
  final Offset? glow;

  /// Windows: the glass (item units).
  final Rect? pane;
  final PaneShape paneShape;

  /// Pets that are the kitten and puppy she can also hold: their drawing,
  /// its color and the part of it that is the pet.
  final String? petArt;
  final Color? petColor;
  final Rect? petCrop;

  bool get isDoll => id == dollRoomId;
  bool get isPet => category == RoomCategory.friends && !isDoll;

  /// Only one of her and of each pet in a room.
  bool get single => category == RoomCategory.friends;

  /// Drawn first to last: on the wall, flat on the floor, then everything
  /// that stands (those lower on the screen in front).
  int get layer {
    if (category == RoomCategory.window || category == RoomCategory.art) {
      return 0;
    }
    if (category == RoomCategory.floor) return 1;
    return 2;
  }

  String get asset => petArt ?? 'assets/svg/room/$id.svg';
}

/// The doll in her own room.
const String dollRoomId = 'doll';

const String _kitten = 'assets/svg/items/handKitten.svg';
const String _puppy = 'assets/svg/items/handPuppy.svg';
const Rect _petCrop = Rect.fromLTRB(132, 212, 182, 292);

RoomItem _wall(String id, int base, int print) => RoomItem(
  id,
  RoomCategory.wallpaper,
  surface: RoomSurface.wallpaper,
  colors: [Color(base), Color(print)],
);

RoomItem _floor(String id, int base, int print) => RoomItem(
  id,
  RoomCategory.floor,
  surface: RoomSurface.floor,
  colors: [Color(base), Color(print)],
);

/// A pet she can also hold: the same id, price and color as the Star Shop's.
RoomItem _shopPet(String id, String art) {
  final item = gameItems.firstWhere((i) => i.id == id);
  return RoomItem(
    id,
    RoomCategory.friends,
    w: 52,
    h: 83,
    price: item.price,
    petArt: art,
    petColor: item.color,
    petCrop: _petCrop,
  );
}

final List<RoomItem> roomItems = [
  // Wallpapers (8).
  _wall('wall_dots', 0xFFFFD6E8, 0xFFFFFFFF),
  _wall('wall_stars', 0xFFC9E4FF, 0xFFFFF3A0),
  _wall('wall_stripes', 0xFFD4F5E0, 0xFFB5E8C9),
  _wall('wall_hearts', 0xFFE6D8FF, 0xFFFF9CC8),
  _wall('wall_flowers', 0xFFFFF0B8, 0xFFFF9A7A),
  _wall('wall_clouds', 0xFFAFDcff, 0xFFFFFFFF),
  _wall('wall_rainbow', 0xFFFFF1F6, 0xFFFF8FA8),
  _wall('wall_diamonds', 0xFFFFDCC4, 0xFFFFC0A0),

  // Floors and rugs (6).
  _floor('floor_wood', 0xFFE5B47A, 0xFFC98F56),
  _floor('floor_checker', 0xFFFFE3EF, 0xFFFFB6D4),
  _floor('floor_carpet', 0xFFC8B6F0, 0xFFE4DAFF),
  const RoomItem('rug_round', RoomCategory.floor, w: 180, h: 66),
  const RoomItem('rug_heart', RoomCategory.floor, w: 150, h: 78),
  const RoomItem('rug_rainbow', RoomCategory.floor, w: 200, h: 80, price: 6),

  // Beds (5).
  const RoomItem('bed_pink', RoomCategory.bed, w: 180, h: 118),
  const RoomItem('bed_car', RoomCategory.bed, w: 184, h: 108),
  const RoomItem('bed_cloud', RoomCategory.bed, w: 180, h: 122),
  const RoomItem('bed_canopy', RoomCategory.bed, w: 196, h: 208, price: 12),
  const RoomItem('bed_castle', RoomCategory.bed, w: 196, h: 214, price: 11),

  // Wardrobes and shelves (4).
  const RoomItem('wardrobe', RoomCategory.storage, w: 112, h: 172),
  const RoomItem('dresser', RoomCategory.storage, w: 118, h: 102),
  const RoomItem('bookshelf', RoomCategory.storage, w: 100, h: 160),
  const RoomItem('wall_shelf', RoomCategory.storage, w: 132, h: 62),

  // Desk and chair (3).
  const RoomItem('desk', RoomCategory.desk, w: 132, h: 104),
  const RoomItem('chair', RoomCategory.desk, w: 62, h: 98),
  const RoomItem('vanity', RoomCategory.desk, w: 112, h: 152),

  // Lamps (4).
  const RoomItem(
    'lamp_floor',
    RoomCategory.lamp,
    w: 66,
    h: 170,
    glow: Offset(0.5, 0.17),
  ),
  const RoomItem(
    'lamp_table',
    RoomCategory.lamp,
    w: 56,
    h: 74,
    glow: Offset(0.5, 0.3),
  ),
  const RoomItem(
    'lamp_moon',
    RoomCategory.lamp,
    w: 68,
    h: 82,
    glow: Offset(0.5, 0.42),
  ),
  const RoomItem(
    'lamp_unicorn',
    RoomCategory.lamp,
    w: 82,
    h: 112,
    price: 7,
    glow: Offset(0.5, 0.42),
  ),

  // Windows and curtains (4).
  const RoomItem(
    'window_square',
    RoomCategory.window,
    w: 130,
    h: 124,
    pane: Rect.fromLTWH(26, 22, 78, 80),
  ),
  const RoomItem(
    'window_round',
    RoomCategory.window,
    w: 112,
    h: 112,
    pane: Rect.fromLTWH(14, 14, 84, 84),
    paneShape: PaneShape.round,
  ),
  const RoomItem(
    'window_arch',
    RoomCategory.window,
    w: 114,
    h: 150,
    pane: Rect.fromLTWH(20, 14, 74, 118),
    paneShape: PaneShape.arch,
  ),
  const RoomItem(
    'window_wide',
    RoomCategory.window,
    w: 178,
    h: 122,
    pane: Rect.fromLTWH(30, 24, 118, 76),
  ),

  // Toys (8).
  const RoomItem('teddy', RoomCategory.toy, w: 72, h: 86),
  const RoomItem('doll_house', RoomCategory.toy, w: 112, h: 130),
  const RoomItem('ball', RoomCategory.toy, w: 52, h: 52),
  const RoomItem('blocks', RoomCategory.toy, w: 82, h: 78),
  const RoomItem('unicorn_plush', RoomCategory.toy, w: 88, h: 88),
  const RoomItem('train', RoomCategory.toy, w: 124, h: 68),
  const RoomItem('teddy_giant', RoomCategory.toy, w: 136, h: 164, price: 9),
  const RoomItem('aquarium', RoomCategory.toy, w: 134, h: 124, price: 8),

  // Plants (4).
  const RoomItem('plant_flower', RoomCategory.plant, w: 56, h: 78),
  const RoomItem('plant_leafy', RoomCategory.plant, w: 82, h: 138),
  const RoomItem('plant_cactus', RoomCategory.plant, w: 52, h: 82),
  const RoomItem('plant_tulips', RoomCategory.plant, w: 62, h: 90),

  // Wall art and posters (6).
  const RoomItem('art_rainbow', RoomCategory.art, w: 82, h: 68),
  const RoomItem('art_heart', RoomCategory.art, w: 70, h: 82),
  const RoomItem('art_cat', RoomCategory.art, w: 72, h: 86),
  const RoomItem('art_rocket', RoomCategory.art, w: 70, h: 88),
  const RoomItem('art_sun', RoomCategory.art, w: 78, h: 78),
  const RoomItem('art_bunting', RoomCategory.art, w: 184, h: 52),

  // Pet beds (3).
  const RoomItem('petbed_round', RoomCategory.petBed, w: 100, h: 52),
  const RoomItem('petbed_basket', RoomCategory.petBed, w: 100, h: 68),
  const RoomItem('petbed_house', RoomCategory.petBed, w: 102, h: 102),

  // The doll and her pets.
  const RoomItem(dollRoomId, RoomCategory.friends, w: 115, h: 220),
  const RoomItem('pet_bunny', RoomCategory.friends, w: 56, h: 82),
  _shopPet('shop_pet_kitten', _kitten),
  _shopPet('shop_pet_kitten_gray', _kitten),
  _shopPet('shop_pet_puppy', _puppy),
];

final Map<String, RoomItem> _roomItemsById = {
  for (final item in roomItems) item.id: item,
};

RoomItem? findRoomItem(String id) => _roomItemsById[id];

List<RoomItem> roomItemsIn(RoomCategory category) =>
    roomItems.where((i) => i.category == category).toList();

/// The room things sold in the Star Shop, cheapest first. (The pets are
/// already there as things to hold.)
List<RoomItem> roomShopItems() =>
    roomItems.where((i) => i.isSpecial && !i.isPet).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
