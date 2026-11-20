import 'dart:math';

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpGame(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DressUpStarApp(storage: LooksStorage()));
  await tester.pumpAndSettle();
  // Start on the title screen and press Play.
  await tester.tap(find.byKey(const Key('play_button')));
  await tester.pumpAndSettle();
}

/// Scrolls the category bar or item row (they only build what is on screen)
/// until [key] is visible.
Future<void> reveal(WidgetTester tester, String key) async {
  final row = key.startsWith('category_')
      ? 'category_bar'
      : key.startsWith('item_')
      ? 'item_row'
      : null;
  if (row != null) {
    await tester.scrollUntilVisible(
      find.byKey(Key(key)),
      80,
      scrollable: find.descendant(
        of: find.byKey(Key(row)),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await tester.ensureVisible(find.byKey(Key(key)));
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await reveal(tester, key);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  GameMotion.idleAnimations = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the main buttons and every category', (tester) async {
    await pumpGame(tester);
    expect(find.byKey(const Key('camera_button')), findsOneWidget);
    expect(find.byKey(const Key('surprise_button')), findsOneWidget);
    expect(find.byKey(const Key('gallery_button')), findsOneWidget);
    expect(find.byKey(const Key('doll')), findsOneWidget);
    for (final id in [
      'hair',
      'hair_color',
      'dresses',
      'tops',
      'skirts',
      'shoes',
      'accessories',
      'background',
    ]) {
      await reveal(tester, 'category_$id');
      expect(find.byKey(Key('category_$id')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap an item to wear it, tap again to take it off', (
    tester,
  ) async {
    await pumpGame(tester);
    await tapKey(tester, 'category_dresses');
    expect(
      find.byKey(const Key('color_0')),
      findsNothing,
    ); // nothing to color yet

    await tapKey(tester, 'item_dress_princess');
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(
      find.byKey(const Key('color_0')),
      findsOneWidget,
    ); // color buttons appear
    await tapKey(tester, 'color_3');

    await tapKey(tester, 'item_dress_princess');
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hair color category shows big color buttons', (tester) async {
    await pumpGame(tester);
    await tapKey(tester, 'category_hair_color');
    expect(find.byKey(const Key('color_0')), findsOneWidget);
    await tapKey(tester, 'color_4');
    expect(tester.takeException(), isNull);
  });

  testWidgets('every category and item can be tapped on a small phone', (
    tester,
  ) async {
    await pumpGame(tester, size: const Size(320, 568));
    for (final category in gameCategories.where((c) => !c.colorOnly)) {
      await tapKey(tester, 'category_${category.id}');
      for (final item in itemsForCategory(category)) {
        await tapKey(tester, 'item_${item.id}');
        expect(find.byKey(const Key('color_0')), findsOneWidget);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('surprise me changes the outfit', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.byKey(const Key('surprise_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera saves a look and the gallery can load and delete it', (
    tester,
  ) async {
    await pumpGame(tester);
    await tapKey(tester, 'category_tops');
    await tapKey(tester, 'item_top_tshirt');

    await tester.tap(find.byKey(const Key('camera_button')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(LooksStorage.storageKey), hasLength(1));
    expect(find.text('1'), findsOneWidget); // badge on the gallery button

    // Take the top off, then wear the saved look again from the gallery.
    await tapKey(tester, 'item_top_tshirt');
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    await tester.tap(find.byKey(const Key('gallery_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('look_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('look_0')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Delete it.
    await tester.tap(find.byKey(const Key('gallery_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_no')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('look_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_yes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery_empty')), findsOneWidget);
    expect(prefs.getStringList(LooksStorage.storageKey), isEmpty);

    await tester.tap(find.byKey(const Key('back_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('camera_button')), findsOneWidget);
  });

  testWidgets('saved looks survive restarting the app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() => LooksStorage().add(Outfit.random(Random(1))));
    await pumpGame(tester);
    expect(find.text('1'), findsOneWidget);
  });
}
