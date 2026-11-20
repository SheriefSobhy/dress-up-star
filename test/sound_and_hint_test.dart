import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SilentGameAudio> pumpGame(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final audio = SilentGameAudio();
  await tester.pumpWidget(
    DressUpStarApp(storage: LooksStorage(), audio: audio),
  );
  await tester.pumpAndSettle();
  return audio;
}

Finder get hint => find.byKey(const Key('scroll_hint'));

void main() {
  group('sounds', () {
    setUp(
      () => SharedPreferences.setMockInitialValues({
        GameSettings.scrollHintSeenKey: true,
      }),
    );

    testWidgets('each action plays its sound', (tester) async {
      final audio = await pumpGame(tester);
      await tester.tap(find.byKey(const Key('category_hair')));
      await tester.pumpAndSettle();
      expect(audio.played.last, Sfx.tap);

      await tester.tap(find.byKey(const Key('category_dresses')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_dress_princess')));
      await tester.pumpAndSettle();
      expect(audio.played.last, Sfx.itemOn);

      await tester.tap(find.byKey(const Key('color_2')));
      await tester.pumpAndSettle();
      expect(audio.played.last, Sfx.tap);

      await tester.tap(find.byKey(const Key('item_dress_princess')));
      await tester.pumpAndSettle();
      expect(audio.played.last, Sfx.itemOff);

      await tester.tap(find.byKey(const Key('camera_button')));
      await tester.pumpAndSettle();
      expect(audio.played.last, Sfx.camera);

      await tester.tap(find.byKey(const Key('surprise_button')));
      await tester.pumpAndSettle();
      expect(audio.played.last, Sfx.itemOn);
    });

    testWidgets('music starts on the first touch', (tester) async {
      final audio = await pumpGame(tester);
      expect(audio.musicPlaying, isFalse);
      await tester.tap(find.byKey(const Key('doll')));
      await tester.pumpAndSettle();
      expect(audio.musicPlaying, isTrue);
    });

    testWidgets('mute button silences everything and is remembered', (
      tester,
    ) async {
      final audio = await pumpGame(tester);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('mute_button')));
      await tester.pumpAndSettle();
      expect(audio.muted, isTrue);
      expect(audio.musicPlaying, isFalse);
      expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(GameAudio.mutedKey), isTrue);

      final before = audio.played.length;
      await tester.tap(find.byKey(const Key('camera_button')));
      await tester.pumpAndSettle();
      expect(audio.played.length, before);

      // A new start of the game remembers the setting.
      final again = SilentGameAudio();
      await again.load();
      expect(again.muted, isTrue);

      await tester.tap(find.byKey(const Key('mute_button')));
      await tester.pumpAndSettle();
      expect(audio.muted, isFalse);
      expect(audio.musicPlaying, isTrue);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets('top buttons fit on a small phone', (tester) async {
      await pumpGame(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      for (final k in [
        'gallery_button',
        'surprise_button',
        'camera_button',
        'mute_button',
      ]) {
        final rect = tester.getRect(find.byKey(Key(k)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: k);
        expect(rect.right, lessThanOrEqualTo(320), reason: k);
      }
      // The mute button is the top-right one.
      expect(
        tester.getRect(find.byKey(const Key('mute_button'))).left,
        greaterThan(
          tester.getRect(find.byKey(const Key('camera_button'))).left,
        ),
      );
    });
  });

  group('scroll hint', () {
    testWidgets('shows the first time and goes away after scrolling', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpGame(tester);
      expect(hint, findsOneWidget);

      await tester.drag(
        find.byKey(const Key('category_bar')),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(hint, findsNothing);
      expect(await GameSettings.scrollHintSeen(), isTrue);
    });

    testWidgets('does not show again once seen', (tester) async {
      SharedPreferences.setMockInitialValues({
        GameSettings.scrollHintSeenKey: true,
      });
      await pumpGame(tester);
      expect(hint, findsNothing);
    });

    testWidgets('does not show when everything fits (wide screen)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpGame(tester, size: const Size(1200, 900));
      expect(hint, findsNothing);
    });

    testWidgets('does not block tapping the category under it', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpGame(tester);
      expect(hint, findsOneWidget);
      final under = tester.getCenter(hint);
      await tester.tapAt(under);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  test('new items are in the game', () {
    for (final id in [
      'dress_mermaid',
      'dress_fairy',
      'dress_party',
      'hair_ponytail',
      'hair_space_buns',
      'bg_beach',
      'bg_candy',
    ]) {
      expect(findItem(id), isNotNull, reason: id);
    }
    expect(itemsForSlot(Slot.dress).length, greaterThanOrEqualTo(8));
    expect(itemsForSlot(Slot.hair).length, greaterThanOrEqualTo(8));
    expect(itemsForSlot(Slot.background).length, greaterThanOrEqualTo(8));
  });
}
