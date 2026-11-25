import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parents_test.dart' show openParents, tapTile;

Future<void> pumpTitle(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DressUpStarApp(storage: LooksStorage()));
  await tester.pumpAndSettle();
}

Future<void> play(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('play_button')));
  await tester.pumpAndSettle();
}

Finder stepShown(String step) => find.byKey(Key('tutorial_$step'));

Future<bool> savedSeen() async =>
    (await SharedPreferences.getInstance()).getBool(
      GameSettings.tutorialSeenKey,
    ) ??
    false;

void main() {
  GameMotion.idleAnimations = false;
  setUp(() {
    // First launch, but today's daily star was already given (no gift).
    // ignore: invalid_use_of_visible_for_testing_member
    Rewards.now = () => DateTime(2026, 11, 25);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      Rewards.dailyStarKey: '2026-11-25',
    });
  });

  testWidgets('first launch: the finger shows the four steps in order', (
    tester,
  ) async {
    await pumpTitle(tester);
    await play(tester);
    expect(find.byKey(const Key('tutorial')), findsOneWidget);
    expect(stepShown('tapItem'), findsOneWidget);

    // 1. Tap an item.
    await tester.tap(find.byKey(const Key('item_hair_long')));
    await tester.pumpAndSettle();
    expect(stepShown('scrollBar'), findsOneWidget);

    // Tapping something else does not skip ahead.
    await tester.tap(find.byKey(const Key('surprise_button')));
    await tester.pumpAndSettle();
    expect(stepShown('scrollBar'), findsOneWidget);

    // 2. Slide the category bar.
    await tester.drag(
      find.byKey(const Key('category_bar')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    expect(stepShown('pose'), findsOneWidget);

    // 3. Tap Pose.
    await tester.tap(find.byKey(const Key('pose_button')));
    await tester.pumpAndSettle();
    expect(stepShown('shop'), findsOneWidget);
    expect(await savedSeen(), isFalse);

    // 4. Open the Star Shop: the tutorial is done for good.
    await tester.tap(find.byKey(const Key('shop_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial')), findsNothing);
    expect(await savedSeen(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the finger can be skipped', (tester) async {
    await pumpTitle(tester);
    await play(tester);
    expect(find.byKey(const Key('tutorial')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial_skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial')), findsNothing);
    expect(await savedSeen(), isTrue);
  });

  testWidgets('the game still works under the finger', (tester) async {
    await pumpTitle(tester);
    await play(tester);
    // Touches go through the tutorial to the game.
    await tester.tap(find.byKey(const Key('category_dresses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item_dress_princess')));
    await tester.pumpAndSettle();
    expect(stepShown('scrollBar'), findsOneWidget);
  });

  testWidgets('not shown once seen', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      Rewards.dailyStarKey: '2026-11-25',
      GameSettings.tutorialSeenKey: true,
    });
    await pumpTitle(tester);
    await play(tester);
    expect(find.byKey(const Key('tutorial')), findsNothing);
  });

  testWidgets('waits for the daily gift on the very first day', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await pumpTitle(tester);
    await tester.tap(find.byKey(const Key('play_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('tutorial')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial')), findsOneWidget);
  });

  testWidgets('replay from the parents screen', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      Rewards.dailyStarKey: '2026-11-25',
      GameSettings.tutorialSeenKey: true,
    });
    await pumpTitle(tester);
    await openParents(tester);
    await tapTile(tester, 'parents_replay_tutorial');
    await tester.pumpAndSettle();
    // Straight into the game with the finger.
    expect(find.byKey(const Key('doll')), findsOneWidget);
    expect(stepShown('tapItem'), findsOneWidget);
  });

  testWidgets('fits a small phone in Arabic', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      Rewards.dailyStarKey: '2026-11-25',
      'language': 'ar',
    });
    await pumpTitle(tester, size: const Size(320, 640));
    await play(tester);
    for (final step in ['tapItem', 'scrollBar', 'pose', 'shop']) {
      expect(stepShown(step), findsOneWidget);
      expect(tester.takeException(), isNull);
      switch (step) {
        case 'tapItem':
          await tester.tap(find.byKey(const Key('item_hair_long')));
        case 'scrollBar':
          // In Arabic the bar slides the other way.
          await tester.drag(
            find.byKey(const Key('category_bar')),
            const Offset(200, 0),
          );
        case 'pose':
          await tester.tap(find.byKey(const Key('pose_button')));
        case 'shop':
          await tester.tap(find.byKey(const Key('shop_button')));
      }
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('tutorial')), findsNothing);
  });
}
