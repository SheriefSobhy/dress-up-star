import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dress_up_star/art/body_art.dart';
import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/dolls_storage.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show pumpGame, tapKey;

const _deep = DollBody(
  skin: 7,
  eyeColor: 2,
  eyeShape: 1,
  brows: 2,
  face: 1,
  freckles: true,
  blush: 2,
  lips: 1,
);

Future<Dolls> saved(WidgetTester tester) async => DollsStorage().load();

Future<void> tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Chooses [option] on the creator tab [tab].
Future<void> choose(WidgetTester tester, String tab, int option) async {
  await tap(tester, 'tab_$tab');
  await tap(tester, 'option_$option');
  // Her happy smile ends.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  GameMotion.idleAnimations = false;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('saved data', () {
    test('there are 8 skins, 6 eye colors, 4 blushes and 5 lip colors', () {
      expect(skinTones, hasLength(8));
      expect(eyeColors, hasLength(6));
      expect([eyeShapeCount, browStyleCount, faceShapeCount], [3, 3, 3]);
      expect(cheekColors, hasLength(4));
      expect(lipColors, hasLength(5));
      // Light to deep.
      final light = [for (final c in skinTones) c.computeLuminance()];
      expect(light, [...light]..sort((a, b) => b.compareTo(a)));
    });

    test('a look keeps its doll, skin and face', () {
      final look = Outfit.starter().copyWith(body: _deep, dollId: 3);
      final read = Outfit.fromJson(
        jsonDecode(jsonEncode(look.toJson())) as Map<String, dynamic>,
      );
      expect(read, look);
      expect(read.body, _deep);
      expect(read.dollId, 3);
    });

    test('a look saved before the creator opens as the first doll', () {
      final old = Outfit.fromJson({
        'hair': {'id': 'hair_long', 'color': 0xFF6B4226},
        'background': {'id': 'bg_sky', 'color': 0xFF9AD6FF},
      });
      expect(old.body, DollBody.classic);
      expect(old.dollId, Outfit.firstDollId);
      expect(old.toJson().containsKey('body'), isFalse);
    });

    test('broken body values stay classic', () {
      expect(DollBody.fromJson('x'), DollBody.classic);
      expect(
        DollBody.fromJson({'skin': 99, 'lips': -1, 'face': 'no'}),
        DollBody.classic,
      );
    });

    test('six dolls at most, never none, and ids are not reused', () {
      var dolls = Dolls.start();
      expect(dolls.remove(1).list, hasLength(1));
      for (var i = 0; i < 10; i++) {
        dolls = dolls.add(Outfit.starter());
      }
      expect(dolls.list, hasLength(maxDolls));
      dolls = dolls.remove(6);
      expect(dolls.add(Outfit.starter()).activeId, 7);
    });

    test('dressing a doll never changes her skin or the others', () {
      var dolls = Dolls.start().add(Outfit.starter().copyWith(body: _deep));
      dolls = dolls.dress(Outfit.random(Random(3)));
      expect(dolls.active.body, _deep);
      expect(dolls.active.dollId, 2);
      expect(dolls.list.first, Outfit.starter());
    });

    test('dolls are stored and read back', () async {
      final dolls = Dolls.start()
          .add(Outfit.random(Random(5)).copyWith(body: _deep))
          .select(1);
      await DollsStorage().save(dolls);
      final read = await DollsStorage().load();
      expect(read.list, dolls.list);
      expect(read.list.map((d) => d.dollId), [1, 2]);
      expect(read.activeId, 1);
      expect(read.nextId, 3);
    });

    test('broken saved dolls give the first doll', () async {
      SharedPreferences.setMockInitialValues({DollsStorage.storageKey: '{no'});
      expect((await DollsStorage().load()).list, [Outfit.starter()]);
    });

    test('reset progress goes back to one doll', () async {
      await DollsStorage().save(Dolls.start().add(Outfit.starter()));
      await GameSettings.resetProgress();
      expect((await DollsStorage().load()).list, hasLength(1));
    });
  });

  group('art', () {
    const dir = 'assets/svg/doll/';
    String drawn(ArtLayer l) {
      final raw = File(l.asset).readAsStringSync();
      return l.edit?.call(raw) ?? raw;
    }

    test('the first doll is drawn from the art as it is', () {
      for (final name in ['head', 'body', 'arm_left', 'arm_right']) {
        expect(skinLayer(name, DollBody.classic).edit, isNull);
      }
      expect(faceArtLayer('open', DollBody.classic).edit, isNull);
    });

    test('no light skin is left on any other skin tone', () {
      for (var skin = 2; skin < skinTones.length; skin++) {
        final body = DollBody(skin: skin);
        for (final name in ['head', 'body', 'arm_left', 'arm_right']) {
          final svg = drawn(skinLayer(name, body)).toUpperCase();
          expect(svg, isNot(contains('#FFDCC8')), reason: '$name $skin');
          expect(svg, isNot(contains('#DE9F84')), reason: '$name $skin');
        }
      }
    });

    test('every choice changes the art', () {
      final classic = File('${dir}face_open.svg').readAsStringSync();
      for (final body in const [
        DollBody(eyeColor: 1),
        DollBody(eyeShape: 1),
        DollBody(eyeShape: 2),
        DollBody(blush: 3),
        DollBody(lips: 4),
      ]) {
        expect(drawn(faceArtLayer('open', body)), isNot(classic));
      }
      final head = File('${dir}head.svg').readAsStringSync();
      for (final body in const [
        DollBody(face: 1),
        DollBody(face: 2),
        DollBody(freckles: true),
      ]) {
        expect(drawn(skinLayer('head', body)), isNot(head));
      }
      for (final face in ['open', 'blink', 'happy']) {
        final svg = drawn(faceArtLayer(face, const DollBody(eyeShape: 1)));
        expect('transform="translate('.allMatches(svg), hasLength(2));
      }
    });

    testWidgets('moving and still dolls use the same layers', (tester) async {
      await tester.runAsync(() async {
        final rnd = Random(9);
        for (var i = 0; i < 8; i++) {
          final outfit = Outfit.random(
            rnd,
            (_) => true,
          ).copyWith(body: DollBody.random(rnd));
          final parts = await dollParts(outfit);
          final recipe = await dollRecipe(outfit);
          expect(
            parts.parts
                .expand((p) => p.layers)
                .where((l) => !l.asset.startsWith('drawn:half'))
                .map((l) => l.key)
                .toSet(),
            containsAll(
              recipe
                  .flat(Face.open)
                  .where((l) => !l.asset.contains('_front'))
                  .map((l) => l.key)
                  .where((k) => !k.contains('face_') && !k.contains('makeup')),
            ),
          );
          final paint = await posedDollPainter(
            outfit,
            heldPoseFrame(DollPose.peace),
            depth: true,
          );
          expect(paint, isNotNull);
        }
      });
      expect(tester.takeException(), isNull);
    });
  });

  group('game', () {
    testWidgets('the creator changes the doll and she stays changed', (
      tester,
    ) async {
      await pumpGame(tester);
      await tap(tester, 'create_button');
      await choose(tester, 'skin', 6);
      await choose(tester, 'eyeColor', 3);
      await choose(tester, 'eyeShape', 2);
      await choose(tester, 'brows', 1);
      await choose(tester, 'face', 2);
      await choose(tester, 'freckles', 1);
      await choose(tester, 'blush', 1);
      await choose(tester, 'lips', 4);
      await tap(tester, 'creator_save');
      final dolls = await saved(tester);
      expect(dolls.list, hasLength(1));
      expect(
        dolls.active.body,
        const DollBody(
          skin: 6,
          eyeColor: 3,
          eyeShape: 2,
          brows: 1,
          face: 2,
          freckles: true,
          blush: 1,
          lips: 4,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('closing the creator changes nothing; Random does', (
      tester,
    ) async {
      await pumpGame(tester);
      await tap(tester, 'doll_add');
      await tap(tester, 'creator_random');
      await tester.pump(const Duration(seconds: 1));
      await tap(tester, 'creator_close');
      expect(find.byKey(const Key('doll_2')), findsNothing);

      await tap(tester, 'create_button');
      await tap(tester, 'creator_random');
      await tester.pump(const Duration(seconds: 1));
      await tap(tester, 'creator_save');
      expect((await saved(tester)).active.body, isNot(DollBody.classic));
    });

    testWidgets('each doll keeps her own clothes', (tester) async {
      await pumpGame(tester);
      await tapKey(tester, 'category_dresses');
      await tapKey(tester, 'item_dress_princess');
      await tap(tester, 'doll_add');
      await choose(tester, 'skin', 5);
      await tap(tester, 'creator_save');
      expect(find.byKey(const Key('doll_2')), findsOneWidget);
      // The new doll starts without the dress.
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      await tap(tester, 'doll_1');
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      final dolls = await saved(tester);
      expect(dolls.activeId, 1);
      expect(dolls.list[1].body.skin, 5);
      expect(dolls.list[1][Slot.dress], isNull);
      expect(dolls.list[0].body, DollBody.classic);

      // Surprise me keeps her face.
      await tap(tester, 'doll_2');
      await tap(tester, 'surprise_button');
      expect((await saved(tester)).active.body.skin, 5);
    });

    testWidgets('dolls survive restarting the app', (tester) async {
      await DollsStorage().save(
        Dolls.start().add(Outfit.starter().copyWith(body: _deep)),
      );
      await pumpGame(tester);
      expect(find.byKey(const Key('doll_1')), findsOneWidget);
      expect(find.byKey(const Key('doll_2')), findsOneWidget);
    });

    testWidgets('no more than six dolls fit on a phone', (tester) async {
      await pumpGame(tester);
      for (var i = 0; i < 5; i++) {
        await tap(tester, 'doll_add');
        await tap(tester, 'creator_save');
      }
      expect(find.byKey(const Key('doll_add')), findsNothing);
      for (var id = 1; id <= 6; id++) {
        final rect = tester.getRect(find.byKey(Key('doll_$id')));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(
          rect.right,
          lessThanOrEqualTo(
            tester.getRect(find.byKey(const Key('create_button'))).left,
          ),
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('deleting asks first and keeps the last doll', (tester) async {
      await pumpGame(tester);
      expect(find.byKey(const Key('doll_delete')), findsNothing);
      await tap(tester, 'doll_add');
      await tap(tester, 'creator_save');

      await tap(tester, 'doll_delete');
      await tap(tester, 'delete_no');
      expect(find.byKey(const Key('doll_2')), findsOneWidget);

      await tap(tester, 'doll_delete');
      await tap(tester, 'delete_yes');
      expect(find.byKey(const Key('doll_2')), findsNothing);
      expect(find.byKey(const Key('doll_delete')), findsNothing);
      expect((await saved(tester)).activeId, 1);
    });

    testWidgets('a saved look goes back on the doll who wore it', (
      tester,
    ) async {
      await pumpGame(tester);
      await tap(tester, 'doll_add');
      await choose(tester, 'skin', 4);
      await tap(tester, 'creator_save');
      await tapKey(tester, 'category_tops');
      await tapKey(tester, 'item_top_tshirt');
      await tap(tester, 'camera_button');
      expect((await LooksStorage().load()).first.dollId, 2);

      await tap(tester, 'doll_1');
      await tap(tester, 'gallery_button');
      await tap(tester, 'look_0');
      var dolls = await saved(tester);
      expect(dolls.activeId, 2);
      expect(dolls.active.body.skin, 4);
      expect(dolls.list.first[Slot.top], isNull);

      // Without her, the look goes on the doll on stage.
      await tap(tester, 'doll_delete');
      await tap(tester, 'delete_yes');
      await tap(tester, 'gallery_button');
      await tap(tester, 'look_0');
      dolls = await saved(tester);
      expect(dolls.activeId, 1);
      expect(dolls.active.body, DollBody.classic);
      expect(dolls.active[Slot.top]?.item.id, 'top_tshirt');
    });

    testWidgets('activities open on a doll with her own skin', (tester) async {
      await DollsStorage().save(Dolls.start().reshape(_deep));
      await pumpGame(tester);
      for (final name in ['makeup', 'salon', 'nails']) {
        await tap(tester, 'activities_button');
        await tap(tester, 'activity_$name');
        await tap(tester, 'done_button');
        await tester.pump(const Duration(seconds: 2));
        expect((await saved(tester)).active.body, _deep, reason: name);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the creator fits a small phone in Arabic', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('ar')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpGame(tester, size: const Size(320, 568));
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
        await choose(tester, tab, 1);
      }
      await tap(tester, 'creator_save');
      expect(tester.takeException(), isNull);
    });
  });
}
