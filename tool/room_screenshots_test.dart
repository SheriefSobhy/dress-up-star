// ignore_for_file: invalid_use_of_visible_for_testing_member
// Phone-size (390 wide) screenshots of Room Decorating.
//
//   flutter test tool/room_screenshots_test.dart --plain-name "room 390"
//   flutter test tool/room_screenshots_test.dart --plain-name "catalog 390"
//
// Run them one at a time (art caches are shared between tests).
//
// Pictures are written to build/screenshots/ (or $SCREENSHOT_DIR).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/room_config.dart';
import 'package:dress_up_star/models/room.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:dress_up_star/services/room_storage.dart';
import 'package:dress_up_star/widgets/room_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screenshots_test.dart' show loadFonts, outDir, pumpApp, rootKey, tap;

/// Lets the art load and fade in, then saves the screen.
Future<void> capture(WidgetTester tester, String name) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump(const Duration(milliseconds: 25));
  }
  final element = find.byKey(rootKey).evaluate().single;
  final bytes = await tester.runAsync(() async {
    final image = await captureImage(element);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  Directory(outDir).createSync(recursive: true);
  File('$outDir/$name.png').writeAsBytesSync(bytes!);
}

/// A room full of things, to look at.
Room _full({bool night = false}) {
  PlacedThing put(String id, double x, double y, [double s = 1]) =>
      PlacedThing(findRoomItem(id)!, x, y, scale: s);
  return Room(
    wallpaper: 'wall_stars',
    floor: 'floor_checker',
    night: night,
    things: [
      put('window_arch', 0.5, 0.41),
      put('art_bunting', 0.5, 0.19),
      put('art_cat', 0.13, 0.31),
      put('rug_rainbow', 0.52, 0.93, 1.2),
      put('bed_canopy', 0.26, 0.68),
      put('wardrobe', 0.84, 0.65),
      put('lamp_unicorn', 0.62, 0.66, 0.9),
      put('doll', 0.52, 0.87),
      put('teddy_giant', 0.86, 0.83, 0.85),
      put('aquarium', 0.17, 0.86, 0.9),
      put('pet_bunny', 0.7, 0.9),
      put('shop_pet_puppy', 0.35, 0.93),
      put('petbed_house', 0.85, 0.98, 0.8),
    ],
  );
}

Future<void> _seed(Room room, {int stars = 6, List<String>? unlocked}) async {
  SharedPreferences.setMockInitialValues({
    GameSettings.scrollHintSeenKey: true,
    GameSettings.tutorialSeenKey: true,
    GameSettings.challengeStarsKey: stars,
    Rewards.dailyStarKey: '2026-11-24',
    Rewards.unlockedKey: ?unlocked,
    RoomStorage.storageKey: jsonEncode({'1': room.toJson()}),
  });
}

const List<String> _owned = [
  'bed_canopy:0',
  'rug_rainbow:0',
  'lamp_unicorn:0',
  'teddy_giant:0',
  'aquarium:0',
  'shop_pet_puppy:0',
];

void main() {
  GameMotion.idleAnimations = false;
  setUpAll(loadFonts);
  setUp(() => Rewards.now = () => DateTime(2026, 11, 24));

  testWidgets('room 390', (tester) async {
    await _seed(Room.starter(), unlocked: null);
    await pumpApp(tester, const Size(390, 844));
    await capture(tester, 'room_01_main');
    await tap(tester, 'room_button');
    await capture(tester, 'room_02_starter');
    await tap(tester, 'room_cat_bed');
    await capture(tester, 'room_03_beds');
    await tester.tap(find.byKey(const Key('room_item_bed_cloud')));
    await tester.pump(const Duration(seconds: 1));
    await capture(tester, 'room_04_selected');
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('thing_5'))),
    );
    await g.moveBy(const Offset(0, 40));
    await g.moveTo(const Offset(60, 560));
    await tester.pump(const Duration(milliseconds: 300));
    await capture(tester, 'room_05_trash');
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, 'room_cat_friends');
    await capture(tester, 'room_06_friends');
    await tap(tester, 'room_night');
    await capture(tester, 'room_07_night_starter');
  });

  testWidgets('full room 390', (tester) async {
    await _seed(_full(), unlocked: _owned);
    await pumpApp(tester, const Size(390, 844));
    await tap(tester, 'room_button');
    await capture(tester, 'room_08_full');
    await tester.tapAt(const Offset(203, 480));
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, 'room_09_doll_hearts');
    await tester.pump(const Duration(seconds: 2));
    await tap(tester, 'room_night');
    await capture(tester, 'room_10_night');
    await tap(tester, 'room_camera');
    await tester.pump(const Duration(seconds: 3));
    await tap(tester, 'room_back');
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, 'gallery_button');
    await capture(tester, 'room_11_gallery');
    await tap(tester, 'look_0');
    await capture(tester, 'room_12_photo');
  });

  testWidgets('shop 390', (tester) async {
    await _seed(Room.starter(), stars: 7);
    await pumpApp(tester, const Size(390, 844));
    await tap(tester, 'shop_button');
    await tester.drag(
      find.byKey(const Key('shop_grid')),
      const Offset(0, -2000),
    );
    await tester.pump(const Duration(seconds: 1));
    await capture(tester, 'room_13_shop');
  });

  // Every thing of every category, in the room's bottom bar.
  testWidgets('catalog 390', (tester) async {
    tester.view.physicalSize = const Size(390, 2000) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Material(
            color: const Color(0xFFF4EAF6),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in roomItems)
                    if (!item.isDoll)
                      SizedBox(
                        width: 92,
                        height: 100,
                        child: RoomThumbnail(item: item),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await capture(tester, 'room_14_catalog');
  });
}
