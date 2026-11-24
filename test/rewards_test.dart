import 'dart:convert';
import 'dart:math';

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/challenge.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/screens/star_shop_screen.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:dress_up_star/widgets/doll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _today = '2026-11-24';

GameItem _item(String id) => findItem(id)!;

/// Starts the game with [stars] earned and today's daily star already given
/// (unless [daily] is true).
Future<SilentGameAudio> _start(
  WidgetTester tester, {
  int stars = 0,
  bool daily = false,
  Map<String, Object> more = const {},
  Size size = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues({
    GameSettings.challengeStarsKey: stars,
    if (!daily) Rewards.dailyStarKey: _today,
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
  await tester.tap(find.byKey(const Key('play_button')));
  await tester.pumpAndSettle();
  return audio;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Scrolls [row] until [key] shows, then taps it.
Future<void> _tapIn(WidgetTester tester, String key, String row) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    80,
    scrollable: find.descendant(
      of: find.byKey(Key(row)),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, key);
}

String _shopStars(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const Key('shop_button')),
        matching: find.byKey(const Key('star_total')),
      ),
    )
    .data!;

Outfit _doll(WidgetTester tester) =>
    tester.widget<DollView>(find.byType(DollView)).outfit;

void main() {
  GameMotion.idleAnimations = false;
  setUp(() {
    Rewards.now = () => DateTime(2026, 11, 24, 9);
    SharedPreferences.setMockInitialValues({});
  });

  group('the shop items', () {
    test('at least 15 special items, priced 3 to 15 stars', () {
      final shop = starShopItems();
      expect(shop.length, greaterThanOrEqualTo(15));
      for (final item in shop) {
        expect(item.price, inInclusiveRange(3, 15), reason: item.id);
        expect(item.themes, isNotEmpty, reason: item.id);
      }
      // Cheapest first.
      for (var i = 1; i < shop.length; i++) {
        expect(shop[i].price, greaterThanOrEqualTo(shop[i - 1].price));
      }
      final shapes = shop.map((i) => i.shape).toSet();
      expect(
        shapes,
        containsAll([
          ItemShape.dressGown,
          ItemShape.dressRainbow,
          ItemShape.dressBallerina,
          ItemShape.headUnicorn,
          ItemShape.backButterfly,
          ItemShape.shoesSparkly,
          ItemShape.neckDiamond,
          ItemShape.eyesSunRainbow,
          ItemShape.handKitten,
          ItemShape.handPuppy,
          ItemShape.bgBallroom,
          ItemShape.bgUnicorn,
        ]),
      );
      // Everything from before stays free.
      expect(gameItems.where((i) => !i.isSpecial).length, 72);
    });

    test('every new drawing exists', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final item in starShopItems()) {
        final svg = await rootBundle.loadString(
          'assets/svg/items/${item.shape.name}.svg',
        );
        expect(svg, contains('<svg'), reason: item.id);
      }
    });

    test('wings are worn on her back and show in Accessories', () {
      final wings = _item('shop_wings_butterfly');
      expect(wings.slot, Slot.back);
      final accessories = gameCategories.firstWhere(
        (c) => c.id == 'accessories',
      );
      expect(itemsForCategory(accessories), contains(wings));
      final look = Outfit.starter().wear(wings).wear(_item('dress_fairy'));
      expect(look[Slot.back]!.item, wings);
      expect(look[Slot.dress]!.item.id, 'dress_fairy');
    });
  });

  group('unlocking and saving', () {
    test('items are locked until bought; spending is remembered', () async {
      SharedPreferences.setMockInitialValues({
        GameSettings.challengeStarsKey: 9,
      });
      final rewards = Rewards();
      await rewards.load();
      final boots = _item('shop_boots_gold'); // 3 stars
      final gown = _item('shop_gown_princess'); // 10 stars
      expect(rewards.isUnlocked(_item('dress_tutu')), isTrue); // free
      expect(rewards.isUnlocked(boots), isFalse);
      expect(rewards.stars, 9);

      expect(await rewards.unlock(gown), isFalse); // not enough
      expect(rewards.missingFor(gown), 1);
      expect(rewards.isUnlocked(gown), isFalse);
      expect(rewards.stars, 9);

      expect(await rewards.unlock(boots), isTrue);
      expect(rewards.isUnlocked(boots), isTrue);
      expect(rewards.stars, 6);
      // Unlocking again costs nothing.
      expect(await rewards.unlock(boots), isTrue);
      expect(rewards.stars, 6);

      // A fresh start (like reopening the game) remembers everything.
      final again = Rewards();
      await again.load();
      expect(again.isUnlocked(boots), isTrue);
      expect(again.isUnlocked(gown), isFalse);
      expect(again.stars, 6);
      expect(again.earned, 9);
    });

    test('new stars add to what is left after shopping', () async {
      SharedPreferences.setMockInitialValues({
        GameSettings.challengeStarsKey: 5,
      });
      final rewards = Rewards();
      await rewards.load();
      await rewards.unlock(_item('shop_boots_sparkly')); // 5 stars
      expect(rewards.stars, 0);
      expect(await rewards.addStars(3), 3);
      final again = Rewards();
      await again.load();
      expect(again.stars, 3);
      expect(again.unlockedIds, {'shop_boots_sparkly'});
    });

    test('the price paid is kept even if prices change', () async {
      SharedPreferences.setMockInitialValues({
        GameSettings.challengeStarsKey: 20,
        Rewards.unlockedKey: ['shop_pet_kitten:4', 'gone_item:2'],
      });
      final rewards = Rewards();
      await rewards.load();
      expect(rewards.isUnlocked(_item('shop_pet_kitten')), isTrue);
      expect(rewards.stars, 14);
    });
  });

  group('daily star', () {
    test('one star per day, the first time the game opens', () async {
      final rewards = Rewards();
      await rewards.load();
      expect(await rewards.claimDailyStar(), isTrue);
      expect(rewards.stars, 1);
      expect(await rewards.claimDailyStar(), isFalse); // same day
      Rewards.now = () => DateTime(2026, 11, 24, 23, 59);
      expect(await rewards.claimDailyStar(), isFalse);
      Rewards.now = () => DateTime(2026, 11, 25, 0, 1);
      expect(await rewards.claimDailyStar(), isTrue);
      expect(rewards.stars, 2);
      final again = Rewards();
      await again.load();
      expect(again.stars, 2);
    });

    testWidgets('opening the game shows the gift and adds a star', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final audio = SilentGameAudio();
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DressUpStarApp(storage: LooksStorage(), audio: audio),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('daily_gift')), findsOneWidget);
      expect(audio.played, contains(Sfx.unlock));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('daily_gift')), findsNothing);
      expect(_shopStars(tester), '1');
      // Coming back the same day: no second gift.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        DressUpStarApp(storage: LooksStorage(), audio: SilentGameAudio()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(const Key('daily_gift')), findsNothing);
      await tester.pumpAndSettle();
      expect(_shopStars(tester), '1');
    });
  });

  group('surprise me', () {
    test('only uses unlocked items', () {
      final rewards = <String>{'shop_wings_butterfly', 'shop_pet_kitten'};
      bool allowed(GameItem i) => !i.isSpecial || rewards.contains(i.id);
      var sawWings = false;
      var sawKitten = false;
      for (var seed = 0; seed < 300; seed++) {
        final look = Outfit.random(Random(seed), allowed);
        for (final worn in look.worn.values) {
          expect(allowed(worn.item), isTrue, reason: worn.item.id);
        }
        sawWings |= look[Slot.back]?.item.id == 'shop_wings_butterfly';
        sawKitten |= look[Slot.hand]?.item.id == 'shop_pet_kitten';
      }
      expect(sawWings, isTrue);
      expect(sawKitten, isTrue);
    });

    test('by default never uses Star Shop items', () {
      for (var seed = 0; seed < 300; seed++) {
        final look = Outfit.random(Random(seed));
        expect(look.worn.values.any((w) => w.item.isSpecial), isFalse);
      }
    });

    testWidgets('the button only puts on unlocked items', (tester) async {
      await _start(
        tester,
        stars: 20,
        more: {
          Rewards.unlockedKey: ['shop_wings_fairy:6'],
        },
      );
      for (var i = 0; i < 25; i++) {
        await _tap(tester, 'surprise_button');
        for (final worn in _doll(tester).worn.values) {
          expect(
            !worn.item.isSpecial || worn.item.id == 'shop_wings_fairy',
            isTrue,
            reason: worn.item.id,
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('screen', () {
    testWidgets('a locked item in its category: shake when not enough', (
      tester,
    ) async {
      final audio = await _start(tester, stars: 4);
      expect(_shopStars(tester), '4');
      await _tapIn(tester, 'category_dresses', 'category_bar');
      await tester.scrollUntilVisible(
        find.byKey(const Key('item_shop_gown_princess')),
        80,
        scrollable: find.descendant(
          of: find.byKey(const Key('item_row')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lock_shop_gown_princess')), findsOneWidget);
      await tester.tap(find.byKey(const Key('item_shop_gown_princess')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // The stars she has, and the ones still needed (10 - 4 = 6).
      expect(find.byKey(const Key('need_stars')), findsOneWidget);
      expect(find.byKey(const Key('need_have_3')), findsOneWidget);
      expect(find.byKey(const Key('need_miss_4')), findsOneWidget);
      expect(find.byKey(const Key('need_miss_9')), findsOneWidget);
      expect(audio.played.last, Sfx.notYet);
      await tester.pumpAndSettle();
      expect(_doll(tester)[Slot.dress], isNull);
      expect(_shopStars(tester), '4');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a locked item she can afford: unlock, wear it, saved', (
      tester,
    ) async {
      final audio = await _start(tester, stars: 12);
      await _tapIn(tester, 'category_shoes', 'category_bar');
      await tester.scrollUntilVisible(
        find.byKey(const Key('item_shop_boots_sparkly')),
        80,
        scrollable: find.descendant(
          of: find.byKey(const Key('item_row')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_shop_boots_sparkly')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('unlock_celebration')), findsOneWidget);
      expect(audio.played, contains(Sfx.unlock));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lock_shop_boots_sparkly')), findsNothing);
      expect(_doll(tester)[Slot.shoes]!.item.id, 'shop_boots_sparkly');
      expect(_shopStars(tester), '7');

      // The look with it saves and comes back from the gallery.
      await _tap(tester, 'camera_button');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(Rewards.unlockedKey), [
        'shop_boots_sparkly:5',
      ]);
      final saved = Outfit.fromJson(
        jsonDecode(prefs.getStringList(LooksStorage.storageKey)!.first)
            as Map<String, dynamic>,
      );
      expect(saved[Slot.shoes]!.item.id, 'shop_boots_sparkly');
      await _tapIn(tester, 'item_shop_boots_sparkly', 'item_row'); // off
      expect(_doll(tester)[Slot.shoes], isNull);
      await _tap(tester, 'gallery_button');
      await _tap(tester, 'look_0');
      expect(_doll(tester)[Slot.shoes]!.item.id, 'shop_boots_sparkly');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Star Shop: unlock, shake, then wear', (tester) async {
      await _start(tester, stars: 16, size: const Size(320, 568));
      await _tap(tester, 'shop_button');
      expect(find.byKey(const Key('shop_grid')), findsOneWidget);

      // 16 stars: the kitten (10) is fine.
      await tester.scrollUntilVisible(
        find.byKey(const Key('shop_item_shop_pet_kitten')),
        120,
        scrollable: find.descendant(
          of: find.byKey(const Key('shop_grid')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shop_item_shop_pet_kitten')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('unlock_celebration')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('owned_shop_pet_kitten')), findsOneWidget);

      // 6 left: the ballroom (15) is not.
      await tester.scrollUntilVisible(
        find.byKey(const Key('shop_item_shop_bg_ballroom')),
        120,
        scrollable: find.descendant(
          of: find.byKey(const Key('shop_grid')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shop_item_shop_bg_ballroom')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('need_stars')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('shop_lock_shop_bg_ballroom')),
        findsOneWidget,
      );

      // Tap the kitten again: back to the doll, holding it.
      await tester.scrollUntilVisible(
        find.byKey(const Key('shop_item_shop_pet_kitten')),
        -120,
        scrollable: find.descendant(
          of: find.byKey(const Key('shop_grid')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'shop_item_shop_pet_kitten');
      expect(find.byKey(const Key('shop_grid')), findsNothing);
      expect(_doll(tester)[Slot.hand]!.item.id, 'shop_pet_kitten');
      expect(_shopStars(tester), '6');
      expect(tester.takeException(), isNull);
    });

    testWidgets('challenge stars can be spent in the shop', (tester) async {
      await _start(tester, stars: 2);
      await _tap(tester, 'challenge_button');
      final theme = ChallengeTheme.values.firstWhere(
        (t) => find.byKey(Key('theme_${t.name}')).evaluate().isNotEmpty,
      );
      await _tap(tester, 'challenge_go');
      await tester.tap(find.byKey(const Key('challenge_check')));
      await tester.pumpAndSettle();
      final won = challengeStars(Outfit.starter(), theme);
      expect(_shopStars(tester), '${2 + won}');
      expect(tester.takeException(), isNull);
    });
  });
}
