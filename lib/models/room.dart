import 'dart:math' as math;
import 'dart:ui';

import '../data/room_config.dart';

/// One thing standing (or hanging) in a room.
class PlacedThing {
  const PlacedThing(
    this.item,
    this.x,
    this.y, {
    this.scale = 1,
    this.flipped = false,
  });

  final RoomItem item;

  /// The middle of its bottom edge, as parts (0..1) of the room's width and
  /// height, so a room fits every screen.
  final double x;
  final double y;
  final double scale;
  final bool flipped;

  PlacedThing copyWith({double? x, double? y, double? scale, bool? flipped}) =>
      PlacedThing(
        item,
        x ?? this.x,
        y ?? this.y,
        scale: scale ?? this.scale,
        flipped: flipped ?? this.flipped,
      );

  /// Where it is in a room of [room] pixels.
  Rect rect(Size room) {
    final unit = room.width / roomUnits;
    final w = item.w * scale * unit;
    final h = item.h * scale * unit;
    return Rect.fromLTWH(x * room.width - w / 2, y * room.height - h, w, h);
  }

  /// The same thing moved (and made smaller if needed) so all of it is
  /// inside a room of [room] pixels.
  PlacedThing inside(Size room) {
    final unit = room.width / roomUnits;
    final fits = math.min(
      room.width / (item.w * unit),
      room.height / (item.h * unit),
    );
    final s = math.min(scale.clamp(minRoomScale, maxRoomScale), fits);
    final halfW = item.w * s * unit / 2 / room.width;
    final h = item.h * s * unit / room.height;
    return copyWith(
      scale: s,
      x: halfW >= 0.5 ? 0.5 : x.clamp(halfW, 1 - halfW),
      y: y.clamp(math.min(h, 1.0), 1.0),
    );
  }

  Map<String, dynamic> toJson() => {
    'i': item.id,
    'x': double.parse(x.toStringAsFixed(4)),
    'y': double.parse(y.toStringAsFixed(4)),
    if (scale != 1) 's': double.parse(scale.toStringAsFixed(3)),
    if (flipped) 'f': true,
  };

  static PlacedThing? fromJson(Object? json) {
    if (json is! Map) return null;
    final item = findRoomItem('${json['i']}');
    final x = json['x'], y = json['y'], s = json['s'];
    if (item == null || item.surface != RoomSurface.none) return null;
    if (x is! num || y is! num) return null;
    return PlacedThing(
      item,
      x.toDouble().clamp(0.0, 1.0),
      y.toDouble().clamp(0.0, 1.0),
      scale: s is num ? s.toDouble().clamp(minRoomScale, maxRoomScale) : 1.0,
      flipped: json['f'] == true,
    );
  }
}

/// One doll's bedroom. Rooms never change; every action returns a new one.
class Room {
  Room({
    required this.wallpaper,
    required this.floor,
    required List<PlacedThing> things,
    this.night = false,
    this.aspect = 0.62,
  }) : things = List.unmodifiable(things);

  /// A new bedroom: not empty, so there is something to move at once.
  factory Room.starter() {
    PlacedThing put(String id, double x, double y) =>
        PlacedThing(findRoomItem(id)!, x, y);
    return Room(
      wallpaper: 'wall_dots',
      floor: 'floor_wood',
      things: [
        put('window_square', 0.7, 0.4),
        put('art_heart', 0.2, 0.34),
        put('rug_round', 0.52, 0.92),
        put('bed_pink', 0.27, 0.72),
        put(dollRoomId, 0.68, 0.9),
      ],
    );
  }

  final String wallpaper;
  final String floor;
  final List<PlacedThing> things;
  final bool night;

  /// Width / height of the screen it was last decorated on (photos use it).
  final double aspect;

  bool get isFull => things.length >= maxRoomThings;

  /// [things] indexes in drawing order: the wall first, then rugs, then
  /// everything else with the lowest on screen in front.
  List<int> get drawOrder {
    final order = [for (var i = 0; i < things.length; i++) i];
    order.sort((a, b) {
      final layer = things[a].item.layer.compareTo(things[b].item.layer);
      if (layer != 0) return layer;
      final y = things[a].y.compareTo(things[b].y);
      return y != 0 ? y : a.compareTo(b);
    });
    return order;
  }

  Room copyWith({
    String? wallpaper,
    String? floor,
    List<PlacedThing>? things,
    bool? night,
    double? aspect,
  }) => Room(
    wallpaper: wallpaper ?? this.wallpaper,
    floor: floor ?? this.floor,
    things: things ?? this.things,
    night: night ?? this.night,
    aspect: aspect ?? this.aspect,
  );

  Room add(PlacedThing thing) => copyWith(things: [...things, thing]);

  Room replace(int index, PlacedThing thing) =>
      copyWith(things: [...things]..[index] = thing);

  Room removeAt(int index) => copyWith(things: [...things]..removeAt(index));

  Map<String, dynamic> toJson() => {
    'wall': wallpaper,
    'floor': floor,
    if (night) 'night': true,
    'aspect': double.parse(aspect.toStringAsFixed(4)),
    'things': [for (final t in things) t.toJson()],
  };

  /// Reads a saved room; unknown things are skipped.
  static Room? fromJson(Object? json) {
    if (json is! Map || json['things'] is! List) return null;
    String surface(Object? id, RoomSurface kind, String fallback) =>
        findRoomItem('$id')?.surface == kind ? '$id' : fallback;
    final aspect = json['aspect'];
    return Room(
      wallpaper: surface(json['wall'], RoomSurface.wallpaper, 'wall_dots'),
      floor: surface(json['floor'], RoomSurface.floor, 'floor_wood'),
      night: json['night'] == true,
      aspect: aspect is num ? aspect.toDouble().clamp(0.3, 2.0) : 0.62,
      things: [
        for (final entry in json['things'] as List)
          ?PlacedThing.fromJson(entry),
      ].take(maxRoomThings).toList(),
    );
  }
}
