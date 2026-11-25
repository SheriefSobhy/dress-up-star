import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/services/frame_watcher.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the game on the title screen.
Future<SilentGameAudio> pumpTitle(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final audio = SilentGameAudio();
  await tester.pumpWidget(
    DressUpStarApp(storage: LooksStorage(), audio: audio),
  );
  await tester.pumpAndSettle();
  return audio;
}

/// Holds the parents' gear for [time].
Future<void> holdGear(WidgetTester tester, Duration time) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const Key('parents_button'))),
  );
  for (
    var held = Duration.zero;
    held < time;
    held += const Duration(milliseconds: 100)
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

/// The two numbers in the question on screen.
(int, int) question(WidgetTester tester) {
  final text = tester
      .widget<Text>(find.byKey(const Key('gate_question')))
      .data!;
  final numbers = RegExp(
    r'\d+',
  ).allMatches(text).map((m) => int.parse(m[0]!)).toList();
  return (numbers[0], numbers[1]);
}

Future<void> typeAnswer(WidgetTester tester, int answer) async {
  for (final digit in '$answer'.split('')) {
    await tester.tap(find.byKey(Key('gate_key_$digit')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('gate_ok')));
  await tester.pumpAndSettle();
}

/// Hold, answer right: the parents' screen.
Future<void> openParents(WidgetTester tester) async {
  await holdGear(tester, const Duration(milliseconds: 3200));
  final (a, b) = question(tester);
  await typeAnswer(tester, a * b);
  expect(find.byKey(const Key('parents_screen')), findsOneWidget);
}

void main() {
  GameMotion.idleAnimations = false;
  setUp(
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
      GameSettings.tutorialSeenKey: true,
    }),
  );

  group('parent gate', () {
    testWidgets('a short tap does not open anything', (tester) async {
      await pumpTitle(tester);
      expect(find.byKey(const Key('parents_button')), findsOneWidget);
      await holdGear(tester, const Duration(milliseconds: 800));
      expect(find.byKey(const Key('parent_gate')), findsNothing);
      expect(find.byKey(const Key('parents_screen')), findsNothing);
      // The words for grown-ups say what to do.
      expect(find.text('Parents: hold for 3 seconds'), findsOneWidget);
    });

    testWidgets('holding 3 seconds asks a question', (tester) async {
      await pumpTitle(tester);
      await holdGear(tester, const Duration(milliseconds: 3200));
      expect(find.byKey(const Key('parent_gate')), findsOneWidget);
      final (a, b) = question(tester);
      expect(a, inInclusiveRange(3, 9));
      expect(b, inInclusiveRange(3, 9));
    });

    testWidgets('a wrong answer gives a new question', (tester) async {
      await pumpTitle(tester);
      await holdGear(tester, const Duration(milliseconds: 3200));
      final (a, b) = question(tester);
      await typeAnswer(tester, a * b + 1);
      expect(find.byKey(const Key('parent_gate')), findsOneWidget);
      expect(find.byKey(const Key('gate_wrong')), findsOneWidget);
      expect(find.byKey(const Key('parents_screen')), findsNothing);
      // The new question works.
      final (c, d) = question(tester);
      await typeAnswer(tester, c * d);
      expect(find.byKey(const Key('parents_screen')), findsOneWidget);
    });

    testWidgets('the backspace key fixes a typo', (tester) async {
      await pumpTitle(tester);
      await holdGear(tester, const Duration(milliseconds: 3200));
      final (a, b) = question(tester);
      await tester.tap(find.byKey(const Key('gate_key_7')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('gate_clear')));
      await tester.pump();
      await typeAnswer(tester, a * b);
      expect(find.byKey(const Key('parents_screen')), findsOneWidget);
    });

    testWidgets('closing the question goes back to the title', (tester) async {
      await pumpTitle(tester);
      await holdGear(tester, const Duration(milliseconds: 3200));
      await tester.tap(find.byKey(const Key('gate_cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('parent_gate')), findsNothing);
      expect(find.byKey(const Key('parents_screen')), findsNothing);
      expect(find.byKey(const Key('play_button')), findsOneWidget);
    });
  });

  group('parents screen', () {
    tearDown(() => GameMotion.lite.value = false);

    testWidgets('music and sounds switch separately', (tester) async {
      final audio = await pumpTitle(tester);
      await openParents(tester);

      await tester.tap(find.byKey(const Key('parents_music')));
      await tester.pumpAndSettle();
      expect(audio.musicOn, isFalse);
      expect(audio.soundsOn, isTrue);
      audio.startMusic();
      expect(audio.musicPlaying, isFalse);
      audio.play(Sfx.tap);
      expect(audio.played.last, Sfx.tap);

      await tester.tap(find.byKey(const Key('parents_sounds')));
      await tester.pumpAndSettle();
      expect(audio.soundsOn, isFalse);
      final before = audio.played.length;
      audio.play(Sfx.itemOn);
      expect(audio.played.length, before);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(GameAudio.musicOnKey), isFalse);
      expect(prefs.getBool(GameAudio.soundsOnKey), isFalse);
    });

    testWidgets('the switches are remembered', (tester) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        GameSettings.tutorialSeenKey: true,
        GameAudio.musicOnKey: false,
        GameAudio.soundsOnKey: true,
      });
      await pumpTitle(tester);
      await openParents(tester);
      final music = tester.widget<SwitchListTile>(
        find.byKey(const Key('parents_music')),
      );
      final sounds = tester.widget<SwitchListTile>(
        find.byKey(const Key('parents_sounds')),
      );
      expect(music.value, isFalse);
      expect(sounds.value, isTrue);
    });

    testWidgets('fewer effects turns lite mode on and off', (tester) async {
      await pumpTitle(tester);
      await openParents(tester);
      expect(GameMotion.lite.value, isFalse);
      await tester.tap(find.byKey(const Key('parents_lite')));
      await tester.pumpAndSettle();
      expect(GameMotion.lite.value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(FrameWatcher.liteModeKey), isTrue);
      await tester.tap(find.byKey(const Key('parents_lite')));
      await tester.pumpAndSettle();
      expect(GameMotion.lite.value, isFalse);
    });

    testWidgets('reset progress asks first, then clears', (tester) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        GameSettings.tutorialSeenKey: true,
        GameSettings.challengeStarsKey: 12,
        Rewards.unlockedKey: ['shop_pet_kitten:6'],
        LooksStorage.storageKey: ['{}'],
        GameAudio.musicOnKey: false,
        'language': 'en',
      });
      await pumpTitle(tester);
      await openParents(tester);
      // "Cancel" keeps everything.
      await tapTile(tester, 'parents_reset');
      expect(find.byKey(const Key('reset_dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('reset_cancel')));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(GameSettings.challengeStarsKey), 12);

      // "Reset" clears the progress but keeps the settings.
      await tester.tap(find.byKey(const Key('parents_reset')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset_confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reset_done')), findsOneWidget);
      expect(prefs.getInt(GameSettings.challengeStarsKey), isNull);
      expect(prefs.getStringList(Rewards.unlockedKey), isNull);
      expect(prefs.getStringList(LooksStorage.storageKey), isNull);
      expect(prefs.getBool(GameAudio.musicOnKey), isFalse);
      expect(prefs.getString('language'), 'en');
      expect(prefs.getBool(GameSettings.tutorialSeenKey), isTrue);
    });

    testWidgets('the privacy policy says no data is collected', (tester) async {
      await pumpTitle(tester);
      await openParents(tester);
      await tapTile(tester, 'parents_privacy');
      expect(find.byKey(const Key('privacy_screen')), findsOneWidget);
      expect(find.textContaining('does not collect'), findsOneWidget);
      // The web address is at the bottom of the policy.
      await tester.scrollUntilVisible(find.textContaining('github.io'), 200);
      expect(
        find.text('https://sheriefsobhy.github.io/dress-up-star/privacy.html'),
        findsOneWidget,
      );
    });

    testWidgets('back goes to the title screen', (tester) async {
      await pumpTitle(tester);
      await openParents(tester);
      await tester.tap(find.byKey(const Key('parents_back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('play_button')), findsOneWidget);
    });
  });
}

/// Scrolls the parents' list to [key] and taps it.
Future<void> tapTile(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(find.byKey(Key(key)), 100);
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}
