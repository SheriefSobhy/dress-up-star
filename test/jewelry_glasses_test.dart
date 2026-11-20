import 'dart:convert';
import 'dart:math';

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/screens/activities/makeup_screen.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity_helpers.dart' show saveAndReadLook;
import 'widget_test.dart' show pumpGame, tapKey;

GameCategory category(String id) =>
    gameCategories.firstWhere((c) => c.id == id);

List<String> idsIn(String categoryId) =>
    itemsForCategory(category(categoryId)).map((i) => i.id).toList();

/// A look saved by the game before Jewelry and Glasses existed.
const Map<String, dynamic> oldLook = {
  'background': {'id': 'bg_garden', 'color': 0xFFBDE3FF},
  'hair': {'id': 'hair_bob', 'color': 0xFFF5CF6B},
  'dress': {'id': 'dress_party', 'color': 0xFFFF6B8B},
  'head': {'id': 'head_bow', 'color': 0xFFFF8FC7},
  'eyes': {'id': 'eyes_heart', 'color': 0xFF7CB8FF},
  'hand': {'id': 'hand_wand', 'color': 0xFFFFD84D},
};

void main() {
  GameMotion.idleAnimations = false;

  group('config', () {
    test('jewelry has necklaces, earrings and bracelets', () {
      final ids = idsIn('jewelry');
      int count(String prefix) => ids.where((i) => i.startsWith(prefix)).length;
      expect(count('neck_'), greaterThanOrEqualTo(8));
      expect(count('ears_'), greaterThanOrEqualTo(5));
      expect(count('wrist_'), greaterThanOrEqualTo(4));
    });

    test('glasses moved out of accessories, with new frames and shades', () {
      final glasses = idsIn('glasses');
      expect(glasses, containsAll(['eyes_round', 'eyes_heart', 'eyes_star']));
      expect(
        glasses.where((i) => !i.startsWith('eyes_sun_')).length - 3,
        greaterThanOrEqualTo(5),
      );
      expect(
        glasses.where((i) => i.startsWith('eyes_sun_')).length,
        greaterThanOrEqualTo(5),
      );
      expect(idsIn('accessories').where((i) => i.startsWith('eyes_')), isEmpty);
      expect(idsIn('accessories'), containsAll(['head_crown', 'hand_bag']));
    });

    test('every item is in exactly one category', () {
      for (final item in gameItems) {
        final homes = gameCategories.where(
          (c) => !c.colorOnly && c.slots.contains(item.slot),
        );
        expect(homes.length, 1, reason: item.id);
      }
    });
  });

  group('wearing', () {
    final pearl = findItem('neck_pearl')!;
    final heart = findItem('neck_heart')!;
    final hoops = findItem('ears_hoop')!;
    final bangle = findItem('wrist_bangle')!;

    test('a necklace, earrings and a bracelet can all be worn at once', () {
      var o = Outfit.starter().wear(pearl).wear(hoops).wear(bangle);
      expect(o.isWearing(pearl) && o.isWearing(hoops), isTrue);
      expect(o.isWearing(bangle), isTrue);
      // A second necklace replaces the first one only.
      o = o.wear(heart);
      expect(o.isWearing(pearl), isFalse);
      expect(o.isWearing(heart) && o.isWearing(hoops), isTrue);
      expect(o.isWearing(bangle), isTrue);
      // Jewelry stays on when the dress changes.
      o = o.wear(findItem('dress_princess')!).wear(findItem('top_tank')!);
      expect(o.isWearing(heart) && o.isWearing(bangle), isTrue);
    });

    test('only one pair of glasses; tap again to take them off', () {
      final round = findItem('eyes_round')!;
      final shades = findItem('eyes_sun_aviator')!;
      var o = Outfit.starter().toggle(round).toggle(shades);
      expect(o.isWearing(round), isFalse);
      expect(o.isWearing(shades), isTrue);
      o = o.toggle(shades);
      expect(o[Slot.eyes], isNull);
    });

    test('new items save and load with their colors', () {
      final o = Outfit.starter()
          .wear(pearl, color: const Color(0xFFB79CFF))
          .wear(hoops)
          .wear(bangle)
          .wear(findItem('eyes_sun_star')!, color: const Color(0xFF3A3550));
      final back = Outfit.fromJson(
        jsonDecode(jsonEncode(o.toJson())) as Map<String, dynamic>,
      );
      expect(back, o);
      expect(back[Slot.neck]!.color, const Color(0xFFB79CFF));
    });

    test('old saved looks still open, glasses and all', () {
      final o = Outfit.fromJson(
        jsonDecode(jsonEncode(oldLook)) as Map<String, dynamic>,
      );
      expect(o[Slot.eyes]!.item.id, 'eyes_heart');
      expect(o[Slot.eyes]!.color, const Color(0xFF7CB8FF));
      expect(o[Slot.head]!.item.id, 'head_bow');
      expect(o[Slot.hand]!.item.id, 'hand_wand');
      expect(o[Slot.neck], isNull);
      expect(o.toJson(), oldLook);
    });

    test('surprise me uses jewelry and every kind of glasses', () {
      final rnd = Random(7);
      final seen = <String>{};
      for (var i = 0; i < 400; i++) {
        final o = Outfit.random(rnd);
        for (final slot in [Slot.neck, Slot.ears, Slot.wrist, Slot.eyes]) {
          final worn = o[slot];
          if (worn != null) seen.add(worn.item.id);
        }
      }
      expect(seen, containsAll(idsIn('jewelry')));
      expect(seen, containsAll(idsIn('glasses')));
    });
  });

  group('drawing', () {
    test('jewelry and glasses are layered on the doll', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final outfit = Outfit.starter()
          .wear(findItem('top_sweater')!)
          .wear(findItem('neck_crystal')!)
          .wear(findItem('ears_gem')!)
          .wear(findItem('wrist_charm')!)
          .wear(findItem('eyes_sun_heart')!)
          .wear(findItem('head_tiara')!);
      final recipe = await dollRecipe(outfit);
      final under = recipe.under.map((l) => l.asset.split('/').last).toList();
      // Over the clothes (and sleeves), under her chin.
      expect(
        under.indexOf('topSweater_front.svg'),
        lessThan(under.indexOf('neckCrystal.svg')),
      );
      expect(
        under.indexOf('arm_left.svg'),
        lessThan(under.indexOf('wristCharm.svg')),
      );
      expect(under.last, 'head.svg');
      expect(recipe.over.map((l) => l.asset.split('/').last), [
        'hairLong.svg',
        'earsGem.svg',
        'headTiara.svg',
        'eyesSunHeart.svg',
      ]);
    });

    test('glasses stay on for close-ups but can be lifted off', () {
      final o = Outfit.starter()
          .wear(findItem('eyes_cat_eye')!)
          .wear(findItem('ears_star')!)
          .wear(findItem('head_crown')!);
      final close = closeUpOutfit(o);
      expect(close[Slot.eyes]!.item.id, 'eyes_cat_eye');
      expect(close[Slot.ears]!.item.id, 'ears_star');
      expect(close[Slot.head], isNull);
      expect(closeUpOutfit(o, glasses: false)[Slot.eyes], isNull);
    });
  });

  group('screen', () {
    setUp(
      () => SharedPreferences.setMockInitialValues({
        GameSettings.scrollHintSeenKey: true,
      }),
    );

    testWidgets('wear a necklace, earrings and a bracelet together', (
      tester,
    ) async {
      await pumpGame(tester);
      await tapKey(tester, 'category_jewelry');
      await tapKey(tester, 'item_neck_star');
      await tapKey(tester, 'item_ears_hoop');
      await tapKey(tester, 'item_wrist_friendship');
      // The color buttons recolor the last one picked.
      await tapKey(tester, 'color_1'); // silver
      final look = await saveAndReadLook(tester);
      expect(look[Slot.neck]!.item.id, 'neck_star');
      expect(look[Slot.ears]!.item.id, 'ears_hoop');
      expect(look[Slot.wrist]!.item.id, 'wrist_friendship');
      expect(look[Slot.wrist]!.color, jewelryColors[1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('one pair of glasses at a time, tap again to take off', (
      tester,
    ) async {
      await pumpGame(tester, size: const Size(320, 568));
      await tapKey(tester, 'category_glasses');
      await tapKey(tester, 'item_eyes_round');
      await tapKey(tester, 'item_eyes_sun_sport');
      expect(
        (await saveAndReadLook(tester))[Slot.eyes]!.item.id,
        'eyes_sun_sport',
      );
      await tapKey(tester, 'item_eyes_sun_sport');
      expect((await saveAndReadLook(tester))[Slot.eyes], isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an old saved look opens from the gallery', (tester) async {
      SharedPreferences.setMockInitialValues({
        GameSettings.scrollHintSeenKey: true,
        LooksStorage.storageKey: [jsonEncode(oldLook)],
      });
      await pumpGame(tester);
      await tapKey(tester, 'gallery_button');
      await tapKey(tester, 'look_0');
      final look = await saveAndReadLook(tester);
      expect(look[Slot.eyes]!.item.id, 'eyes_heart');
      expect(look[Slot.dress]!.item.id, 'dress_party');
      // Her glasses show up as picked in the Glasses category.
      await tapKey(tester, 'category_glasses');
      expect(
        find.descendant(
          of: find.byKey(const Key('item_eyes_heart')),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
    });
  });
}
