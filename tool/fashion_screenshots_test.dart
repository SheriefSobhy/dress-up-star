// ignore_for_file: invalid_use_of_visible_for_testing_member
// Phone-size (390 wide) screenshots of the Fashion Show.
//
//   flutter test tool/fashion_screenshots_test.dart --plain-name "show 390"
//   flutter test tool/fashion_screenshots_test.dart --plain-name "lite 390"
//
// Run them one at a time (art caches are shared between tests).
//
// Pictures are written to build/screenshots/ (or $SCREENSHOT_DIR).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screenshots_test.dart' show loadFonts, outDir, pumpApp, rootKey, tap;

/// Lets the art load without moving the show along, then saves the screen.
Future<void> capture(WidgetTester tester, String name) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump();
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

Future<void> run(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds * 10).round(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  GameMotion.idleAnimations = false;
  setUpAll(loadFonts);
  setUp(() {
    Rewards.now = () => DateTime(2026, 11, 24);
    SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
      GameSettings.tutorialSeenKey: true,
      Rewards.dailyStarKey: '2026-11-24',
    });
  });

  testWidgets('fashion show 390', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await capture(tester, 'show_01_main');
    await tap(tester, 'show_button');
    await capture(tester, 'show_02_card');
    await tap(tester, 'challenge_go');
    await capture(tester, 'show_03_go');
    await tester.tap(find.byKey(const Key('show_go')));
    await tester.pump();
    // Let her pictures load at the start of the walk.
    await capture(tester, 'show_04_start');
    await run(tester, 2.4);
    await capture(tester, 'show_05_walk');
    await run(tester, 2.0);
    await capture(tester, 'show_06_pose');
    await run(tester, 7.8);
    await capture(tester, 'show_07_judges');
    await run(tester, 3.5);
    await capture(tester, 'show_08_trophy');
    await tap(tester, 'show_photo');
    await run(tester, 1);
    await tap(tester, 'show_done');
    await run(tester, 2);
    await tap(tester, 'gallery_button');
    await run(tester, 1);
    await capture(tester, 'show_09_gallery');
  });

  testWidgets('fashion show lite 390', (tester) async {
    // The parents' lite mode switch (read when the app starts).
    (await SharedPreferences.getInstance()).setBool('lite_mode', true);
    addTearDown(() => GameMotion.lite.value = false);
    await pumpApp(tester, const Size(390, 844));
    await tap(tester, 'show_button');
    await tap(tester, 'challenge_new');
    await capture(tester, 'show_10_card_lite');
    await tap(tester, 'challenge_go');
    await tester.tap(find.byKey(const Key('show_go')));
    await tester.pump();
    await capture(tester, 'show_11_start_lite');
    await run(tester, 15);
    await capture(tester, 'show_12_trophy_lite');
  });
}
