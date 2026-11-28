// Renders the Beach & Swim things for reviewing the art (390 wide only).
//
//   flutter test tool/beach_screenshots_test.dart
//
// Pictures are written to build/screenshots/ (or $SCREENSHOT_DIR).
import 'dart:ui' as ui;

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clothes_screenshots_test.dart' show idsOf, look, sheet;
import 'screenshots_test.dart'
    show
        captureScreen,
        loadFonts,
        poseGrid,
        pumpApp,
        saveStrip,
        shot,
        tap,
        tapInRow;

List<String> beachIn(String category) => [
  for (final id in idsOf(category))
    if (findItem(id)!.themes.contains(ChallengeTheme.summer)) id,
];

void main() {
  GameMotion.idleAnimations = false;
  setUpAll(loadFonts);
  setUp(
    // ignore: invalid_use_of_visible_for_testing_member
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
      GameSettings.tutorialSeenKey: true,
      GameSettings.challengeStarsKey: 40,
    }),
  );

  testWidgets('beach sheets', (tester) async {
    await sheet(tester, 'beach_swimwear', [
      for (final id in idsOf('beach').where((id) => id.contains('swim')))
        look([id]),
    ], columns: 5);
    await sheet(tester, 'beach_coverups', [
      for (final cover in ['beach_sundress', 'beach_kaftan', 'beach_robe'])
        for (final under in [
          'swim_polka',
          'swim_dress_ruffle',
          'swim_burkini_waves',
          'swim_rash_leggings',
        ])
          look([under, cover]),
    ], columns: 4);
    await sheet(
      tester,
      'beach_hats',
      [
        for (final id in [...beachIn('hats'), ...beachIn('glasses')]) ...[
          look(['hair_long', id]),
          look(['hair_pigtails', id]),
        ],
      ],
      frame: const Rect.fromLTRB(10, 10, 190, 190),
      columns: 4,
      cell: 220,
    );
    await sheet(tester, 'beach_hold_shoes', [
      for (final id in beachIn('accessories')) look(['swim_sporty', id]),
      for (final id in beachIn('shoes')) look(['swim_dress_peplum', id]),
    ], columns: 6);
  });

  testWidgets('beach poses', (tester) async {
    await poseGrid(tester, 'beach_poses_a', [
      look(['swim_burkini_flower', 'hand_floaties']),
      look(['swim_rash_sport', 'hat_swim_cap', 'shop_ring_flamingo']),
      look(['swim_dress_skater', 'beach_sundress', 'hand_ring_donut']),
      look(['swim_rash_shorts', 'beach_kaftan', 'hand_bucket']),
    ]);
    final deep = look([
      'swim_frilly',
      'beach_robe',
      'hand_floaties',
    ]).copyWith(body: const DollBody(skin: 7, face: 1));
    await poseGrid(tester, 'beach_poses_b', [
      deep,
      deep.remove(Slot.jacket).wear(findItem('hand_ice_cream')!),
      look([
        'shop_swim_burkini_rainbow',
        'beach_sundress',
        'eyes_swim_mask',
        'hand_beach_ball',
      ]).copyWith(body: const DollBody(skin: 4, face: 2)),
      look(['shop_swim_mermaid', 'hat_floppy', 'hand_ring_duck']),
    ]);
  });

  testWidgets('beach screens 390', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await tapInRow(tester, 'category_beach', 'category_bar');
    await tapInRow(tester, 'item_swim_frilly', 'item_row');
    await shot(tester, '390_b_category');
    await tapInRow(tester, 'item_swim_burkini_flower', 'item_row');
    await shot(tester, '390_b_burkini');
    await tapInRow(tester, 'item_beach_kaftan', 'item_row');
    await shot(tester, '390_b_cover');
    for (final category in ['hats', 'glasses', 'shoes', 'accessories']) {
      await tapInRow(tester, 'category_$category', 'category_bar');
      await tapInRow(tester, 'item_${beachIn(category).first}', 'item_row');
      await shot(tester, '390_b_$category');
    }
    await tester.tap(find.byKey(const Key('dance_button')));
    await tester.pump();
    final frames = <ui.Image>[];
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 214));
      frames.add(await captureScreen(tester));
    }
    await saveStrip(
      tester,
      '390_b_dance',
      frames,
      const Rect.fromLTWH(40, 60, 310, 470),
    );
    await tester.pump(const Duration(seconds: 12));
    await tap(tester, 'shop_button');
    await shot(tester, '390_b_shop');
  });
}
