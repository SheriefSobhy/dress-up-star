// Renders the character creator and the dolls for reviewing (390 wide only).
//
//   flutter test tool/creator_screenshots_test.dart
//
// Pictures are written to build/screenshots/ (or $SCREENSHOT_DIR).
import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/dolls_storage.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clothes_screenshots_test.dart' show sheet, look;
import 'screenshots_test.dart';

/// Six different dolls in different clothes.
Dolls family() {
  var dolls = Dolls.start();
  const bodies = [
    DollBody(skin: 7, eyeColor: 1, eyeShape: 2, brows: 2, blush: 2, lips: 3),
    DollBody(skin: 4, eyeColor: 3, eyeShape: 1, face: 1, freckles: true),
    DollBody(skin: 0, eyeColor: 2, face: 2, blush: 1, lips: 2, brows: 1),
    DollBody(skin: 5, eyeColor: 4, eyeShape: 2, face: 2, lips: 1),
    DollBody(skin: 2, eyeColor: 5, eyeShape: 1, face: 1, blush: 3, lips: 4),
  ];
  const clothes = [
    ['hair_bun', 'dress_princess'],
    ['hair_bob', 'top_tshirt', 'skirt_tutu'],
    ['hair_pigtails', 'dress_sun'],
    ['hair_curly', 'top_tshirt'],
    ['hair_braids'],
  ];
  for (var i = 0; i < bodies.length; i++) {
    dolls = dolls.add(look(clothes[i]).copyWith(body: bodies[i]));
  }
  return dolls;
}

Future<void> start(WidgetTester tester, Dolls dolls) async {
  await DollsStorage().save(dolls);
  await pumpApp(tester, const Size(390, 844));
}

void main() {
  GameMotion.idleAnimations = false;
  setUpAll(loadFonts);
  setUp(
    // ignore: invalid_use_of_visible_for_testing_member
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
      GameSettings.tutorialSeenKey: true,
    }),
  );

  testWidgets('main screen and creator', (tester) async {
    await start(tester, family().select(1));
    await tester.pump(const Duration(seconds: 3));
    await shot(tester, 'c01_main_six');
    await tap(tester, 'doll_2');
    await shot(tester, 'c02_main_deep');
    await tap(tester, 'doll_delete');
    await shot(tester, 'c03_delete');
    await tap(tester, 'delete_no');
    await tap(tester, 'create_button');
    for (final tab in [
      'skin',
      'eyeColor',
      'eyeShape',
      'brows',
      'face',
      'freckles',
      'blush',
      'lips',
    ]) {
      await tap(tester, 'tab_$tab');
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, 'c04_creator_$tab');
    }
  });

  testWidgets('one doll', (tester) async {
    await start(tester, Dolls.start());
    await tester.pump(const Duration(seconds: 3));
    await shot(tester, 'c00_main_one');
    await tap(tester, 'create_button');
    await shot(tester, 'c00_creator_classic');
  });

  testWidgets('activities on a deep skin', (tester) async {
    await start(tester, family().select(2));
    await tap(tester, 'activities_button');
    await shot(tester, 'c05_picker');
    await tap(tester, 'activity_makeup');
    await tap(tester, 'tool_lashes');
    await tap(tester, 'option_1');
    const frame = Rect.fromLTRB(16, 40, 184, 176);
    await stroke(tester, frame, const [Offset(78, 108), Offset(80, 110)]);
    await stroke(tester, frame, const [Offset(122, 108), Offset(120, 110)]);
    await tap(tester, 'tool_lipstick');
    await stroke(
      tester,
      frame,
      scribble(const Rect.fromLTRB(90, 134, 110, 145)),
    );
    await shot(tester, 'c06_makeup');
    await tap(tester, 'done_button');
    await tester.pump(const Duration(seconds: 2));
    await tap(tester, 'activities_button');
    await tap(tester, 'activity_nails');
    await shot(tester, 'c07_nails');
  });

  testWidgets('doll sheets', (tester) async {
    final skins = [
      for (var s = 0; s < skinTones.length; s++) DollBody(skin: s),
    ];
    final clothes = [
      'dress_princess',
      'top_tshirt',
      'dress_sun',
      'shoes_flats',
    ];
    await sheet(
      tester,
      's01_skins',
      [
        for (var i = 0; i < skins.length; i++)
          look([clothes[i % 3], 'shoes_flats']).copyWith(body: skins[i]),
      ],
      columns: 4,
      cell: 300,
    );
    final hand = itemsForSlot(Slot.hand);
    for (final pose in [DollPose.peace, DollPose.wave]) {
      await sheet(
        tester,
        's02_${pose.name}',
        [
          for (var i = 0; i < 8; i++)
            look([
              'shoes_flats',
            ]).wear(hand[i % hand.length]).copyWith(body: skins[i]),
        ],
        columns: 4,
        cell: 300,
        pose: pose,
      );
    }
    // Faces close up: every face and eye shape, light and deep.
    await sheet(
      tester,
      's03_faces',
      [
        for (final skin in [1, 4, 7])
          for (var i = 0; i < 3; i++)
            look(const []).copyWith(
              body: DollBody(
                skin: skin,
                face: i,
                eyeShape: i,
                brows: i,
                eyeColor: i + 1,
                freckles: i == 2,
              ),
              makeup: const Makeup(lashLeft: 2, lashRight: 2),
            ),
      ],
      columns: 3,
      cell: 340,
      frame: const Rect.fromLTRB(30, 30, 170, 170),
    );
  });
}
