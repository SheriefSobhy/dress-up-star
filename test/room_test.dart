import 'dart:convert';

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/room_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/models/room.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:dress_up_star/services/room_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SilentGameAudio> _openRoom(
  WidgetTester tester, {
  int stars = 0,
  Size size = const Size(390, 844),
  Map<String, Object> more = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    GameSettings.scrollHintSeenKey: true,
    GameSettings.tutorialSeenKey: true,
    GameSettings.challengeStarsKey: stars,
    Rewards.dailyStarKey: '2026-11-24',
    ...more,
  });
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final audio = SilentGameAudio();
  await tester.pumpWidget(
    DressUpStarApp(storage: LooksStorage(), audio: audio),
  );
  await tester.pumpAndSettle();
  await _tap(tester, 'play_button');
  await _tap(tester, 'room_button');
  expect(find.byKey(const Key('room_screen')), findsOneWidget);
  return audio;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Scrolls the room's [row] until [key] shows, then taps it.
Future<void> _pick(WidgetTester tester, String key, [String? row]) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    80,
    scrollable: find.descendant(
      of: find.byKey(Key(row ?? 'room_items')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, key);
}

Future<void> _category(WidgetTester tester, RoomCategory category) =>
    _pick(tester, 'room_cat_${category.name}', 'room_categories');

Future<Room> _saved([int doll = Outfit.firstDollId]) =>
    RoomStorage().load(doll);

PlacedThing _thing(Room room, String id) =>
    room.things.firstWhere((t) => t.item.id == id);

Future<void> _drag(WidgetTester tester, int thing, Offset to) async {
  final from = tester.getCenter(find.byKey(Key('thing_$thing')));
  final g = await tester.startGesture(from);
  await g.moveBy(const Offset(0, 20));
  await g.moveTo(to);
  await tester.pump();
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  GameMotion.idleAnimations = false;
  setUp(() {
    Rewards.now = () => DateTime(2026, 11, 24, 9);
    SharedPreferences.setMockInitialValues({});
  });

  group('room things', () {
    test('as many in each category as asked', () {
      int count(RoomCategory c) => roomItemsIn(c).length;
      expect(count(RoomCategory.wallpaper), 8);
      expect(count(RoomCategory.floor), 6);
      expect(count(RoomCategory.bed), 5);
      expect(count(RoomCategory.storage), 4);
      expect(count(RoomCategory.desk), 3);
      expect(count(RoomCategory.lamp), 4);
      expect(count(RoomCategory.window), 4);
      expect(count(RoomCategory.toy), 8);
      expect(count(RoomCategory.plant), 4);
      expect(count(RoomCategory.art), 6);
      expect(count(RoomCategory.petBed), 3);
      expect(roomItems.map((i) => i.id).toSet().length, roomItems.length);
    });

    test('six Star Shop things, 5 to 12 stars', () {
      final shop = roomShopItems();
      expect(shop.map((i) => i.id).toSet(), {
        'bed_canopy',
        'bed_castle',
        'rug_rainbow',
        'lamp_unicorn',
        'teddy_giant',
        'aquarium',
      });
      for (final item in shop) {
        expect(item.price, inInclusiveRange(5, 12), reason: item.id);
      }
    });

    test('every drawing exists and matches its size', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final item in roomItems) {
        if (item.surface != RoomSurface.none || item.isDoll) continue;
        final svg = await rootBundle.loadString(item.asset);
        if (item.petArt != null) continue;
        expect(
          svg,
          contains('viewBox="0 0 ${item.w.round()} ${item.h.round()}"'),
          reason: item.id,
        );
      }
    });
  });

  group('room model', () {
    PlacedThing put(String id, double x, double y, {double scale = 1}) =>
        PlacedThing(findRoomItem(id)!, x, y, scale: scale);

    test('lower things are in front; wall and rugs stay behind', () {
      final room = Room(
        wallpaper: 'wall_dots',
        floor: 'floor_wood',
        things: [
          put('teddy', 0.5, 0.9),
          put('bed_pink', 0.5, 0.7),
          put('rug_round', 0.5, 0.99),
          put('art_cat', 0.5, 0.95),
        ],
      );
      expect(room.drawOrder, [3, 2, 1, 0]);
    });

    test('things are kept inside the room', () {
      const size = Size(390, 600);
      for (final thing in [
        put('bed_castle', -1, -1, scale: 5),
        put('art_bunting', 2, 2, scale: 1.7),
        put('ball', 0, 0.01),
      ]) {
        final r = thing.inside(size).rect(size);
        expect(r.left, greaterThanOrEqualTo(-0.01), reason: thing.item.id);
        expect(r.top, greaterThanOrEqualTo(-0.01), reason: thing.item.id);
        expect(r.right, lessThanOrEqualTo(390.01), reason: thing.item.id);
        expect(r.bottom, lessThanOrEqualTo(600.01), reason: thing.item.id);
      }
    });

    test('saved and read back; unknown things are skipped', () {
      final room = Room(
        wallpaper: 'wall_stars',
        floor: 'floor_carpet',
        night: true,
        things: [put('teddy', 0.25, 0.75, scale: 1.5).copyWith(flipped: true)],
      );
      final json = jsonDecode(jsonEncode(room.toJson())) as Map;
      (json['things'] as List).add({'i': 'gone', 'x': 0.5, 'y': 0.5});
      final read = Room.fromJson(json)!;
      expect(read.toJson(), room.toJson());
    });

    test('every doll has her own room, and reset removes them', () async {
      final storage = RoomStorage();
      await storage.save(1, Room.starter().copyWith(night: true));
      await storage.save(2, Room.starter().copyWith(wallpaper: 'wall_hearts'));
      expect((await storage.load(1)).night, isTrue);
      expect((await storage.load(2)).wallpaper, 'wall_hearts');
      await storage.remove(1);
      expect((await storage.load(1)).night, isFalse);
      await GameSettings.resetProgress();
      expect((await storage.load(2)).wallpaper, 'wall_dots');
    });

    test('a room photo is saved with the look', () async {
      final storage = LooksStorage();
      await storage.add(Outfit.starter().copyWith(room: Room.starter()));
      await storage.add(Outfit.starter());
      final looks = await storage.load();
      expect(looks.first.room, isNull);
      expect(looks.last.room!.toJson(), Room.starter().toJson());
    });

    test('room things are bought with stars', () async {
      SharedPreferences.setMockInitialValues({
        GameSettings.challengeStarsKey: 7,
      });
      final rewards = Rewards();
      await rewards.load();
      expect(await rewards.unlock(findRoomItem('bed_canopy')!), isFalse);
      expect(await rewards.unlock(findRoomItem('rug_rainbow')!), isTrue);
      expect(rewards.stars, 1);
    });
  });

  group('room screen', () {
    testWidgets('wallpaper, floor, adding, day and night are saved', (
      tester,
    ) async {
      await _openRoom(tester);
      await _pick(tester, 'room_item_wall_stripes');
      await _category(tester, RoomCategory.floor);
      await _pick(tester, 'room_item_floor_carpet');
      await _category(tester, RoomCategory.toy);
      await _pick(tester, 'room_item_teddy');
      expect(find.byKey(const Key('room_glow')), findsNothing);
      await _tap(tester, 'room_night');
      expect(find.byKey(const Key('room_glow')), findsOneWidget);
      var room = await _saved();
      expect(room.wallpaper, 'wall_stripes');
      expect(room.floor, 'floor_carpet');
      expect(room.night, isTrue);
      expect(room.things.where((t) => t.item.id == 'teddy'), hasLength(1));
      // Still there when she comes back.
      await _tap(tester, 'room_back');
      await _tap(tester, 'room_button');
      expect(find.byKey(const Key('room_glow')), findsOneWidget);
      room = await _saved();
      expect(room.wallpaper, 'wall_stripes');
      expect(tester.takeException(), isNull);
    });

    testWidgets('drag, size, flip, pinch and the trash can', (tester) async {
      final audio = await _openRoom(tester);
      final area = tester.getRect(find.byKey(const Key('room_area')));
      // Thing 3 is the starter bed: far past the corner stays inside.
      await _drag(tester, 3, area.topRight + const Offset(100, -100));
      var bed = _thing(await _saved(), 'bed_pink');
      final r = bed.rect(area.size);
      expect(r.right, closeTo(area.width, 0.5));
      expect(r.top, closeTo(0, 0.5));

      await _tap(tester, 'room_size');
      expect(_thing(await _saved(), 'bed_pink').scale, 1.25);
      await _tap(tester, 'room_flip');
      expect(_thing(await _saved(), 'bed_pink').flipped, isTrue);

      final center = tester.getCenter(find.byKey(const Key('thing_3')));
      final one = await tester.startGesture(center - const Offset(20, 0));
      final two = await tester.startGesture(center + const Offset(20, 0));
      await two.moveTo(center + const Offset(4, 0));
      await tester.pump();
      await two.up();
      await one.up();
      await tester.pumpAndSettle();
      bed = _thing(await _saved(), 'bed_pink');
      expect(bed.scale, lessThan(1.25));

      final count = (await _saved()).things.length;
      await _drag(tester, 3, area.bottomLeft + const Offset(46, -46));
      final room = await _saved();
      expect(room.things.length, count - 1);
      expect(room.things.any((t) => t.item.id == 'bed_pink'), isFalse);
      expect(audio.played, contains(Sfx.itemOff));
      expect(tester.takeException(), isNull);
    });

    testWidgets('one doll and one of each pet; tapping them reacts', (
      tester,
    ) async {
      final audio = await _openRoom(tester);
      await _category(tester, RoomCategory.friends);
      await _pick(tester, 'room_item_pet_bunny');
      await _pick(tester, 'room_item_pet_bunny');
      await _pick(tester, 'room_item_doll');
      final room = await _saved();
      expect(room.things.where((t) => t.item.id == 'pet_bunny'), hasLength(1));
      expect(room.things.where((t) => t.item.isDoll), hasLength(1));
      audio.played.clear();
      await tester.tap(find.byKey(const Key('thing_4'))); // the doll
      await tester.pumpAndSettle();
      expect(audio.played, [Sfx.cheer]);
      await tester.tap(find.byKey(const Key('thing_5'))); // the bunny
      await tester.pumpAndSettle();
      expect(audio.played, [Sfx.cheer, Sfx.bubble]);
    });

    testWidgets('locked things: not enough stars, then unlock', (tester) async {
      await _openRoom(tester, stars: 7);
      await _category(tester, RoomCategory.bed);
      await tester.scrollUntilVisible(
        find.byKey(const Key('room_item_bed_canopy')),
        80,
        scrollable: find.descendant(
          of: find.byKey(const Key('room_items')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('room_item_bed_canopy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('need_stars')), findsOneWidget);
      await tester.pumpAndSettle();
      await _category(tester, RoomCategory.lamp);
      await _pick(tester, 'room_item_lamp_unicorn'); // 7 stars
      expect(find.byKey(const Key('room_lock_lamp_unicorn')), findsNothing);
      expect(
        (await _saved()).things.any((t) => t.item.id == 'lamp_unicorn'),
        isTrue,
      );
      final rewards = Rewards();
      await rewards.load();
      expect(rewards.stars, 0);
    });

    testWidgets('the camera saves the room to My Looks', (tester) async {
      await _openRoom(tester);
      await _tap(tester, 'room_camera');
      final looks = await LooksStorage().load();
      expect(looks.single.room, isNotNull);
      await _tap(tester, 'room_back');
      await _tap(tester, 'gallery_button');
      await _tap(tester, 'look_0');
      expect(find.byKey(const Key('room_photo_big')), findsOneWidget);
      await tester.tapAt(const Offset(195, 422));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('room_photo_big')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a room thing picked in the Star Shop goes in the room', (
      tester,
    ) async {
      await _openRoom(
        tester,
        more: {
          Rewards.unlockedKey: ['aquarium:8'],
        },
        stars: 8,
      );
      await _tap(tester, 'room_back');
      await _tap(tester, 'shop_button');
      await tester.scrollUntilVisible(
        find.byKey(const Key('shop_item_aquarium')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('shop_grid')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'shop_item_aquarium');
      expect(find.byKey(const Key('room_screen')), findsOneWidget);
      expect(
        (await _saved()).things.any((t) => t.item.id == 'aquarium'),
        isTrue,
      );
    });

    testWidgets('fits a small phone, in lite mode too', (tester) async {
      GameMotion.lite.value = true;
      addTearDown(() => GameMotion.lite.value = false);
      await _openRoom(tester, size: const Size(320, 640));
      await _tap(tester, 'room_night');
      await _category(tester, RoomCategory.petBed);
      await _pick(tester, 'room_item_petbed_house');
      expect(tester.takeException(), isNull);
    });
  });
}
