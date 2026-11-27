import 'dart:math';

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/challenge.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Outfit _wear(List<String> ids) =>
    ids.fold(Outfit.starter(), (o, id) => o.wear(findItem(id)!));

/// The most matching items one outfit can have for [theme] (one item per
/// slot, a dress or a top and skirt or pants, a hat or a head thing).
int _bestPossible(ChallengeTheme theme) {
  int bestIn(Iterable<Slot> slots) => slots
      .where((slot) => itemsForSlot(slot).any((i) => fitsTheme(i, theme)))
      .length;
  final common = Slot.values.where(
    (s) => !const [
      Slot.dress,
      Slot.top,
      Slot.skirt,
      Slot.pants,
      Slot.hat,
    ].contains(s),
  );
  return [
    bestIn([...common, Slot.dress]),
    bestIn([...common, Slot.top, Slot.skirt]),
    bestIn([...common, Slot.top, Slot.pants]),
  ].reduce(max);
}

Future<SilentGameAudio> _start(
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
  await tester.tap(find.byKey(const Key('play_button')));
  await tester.pumpAndSettle();
  return audio;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Taps an item, scrolling the bars to find it.
Future<void> _wearOnScreen(
  WidgetTester tester,
  String category,
  String item,
) async {
  for (final (key, row) in [
    ('category_$category', 'category_bar'),
    ('item_$item', 'item_row'),
  ]) {
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
}

String _starTotal(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('star_total'))).data!;

void main() {
  GameMotion.idleAnimations = false;
  // Today's daily star was already given, so only challenge stars count.
  setUp(() {
    Rewards.now = () => DateTime(2026, 11, 24);
    SharedPreferences.setMockInitialValues({
      Rewards.dailyStarKey: '2026-11-24',
    });
  });

  group('star scoring', () {
    test('every item has at least one theme', () {
      for (final item in gameItems) {
        expect(item.themes, isNotEmpty, reason: item.id);
      }
    });

    test('every theme can get three stars and has ideas', () {
      for (final theme in ChallengeTheme.values) {
        expect(
          _bestPossible(theme),
          greaterThanOrEqualTo(matchesForThreeStars),
          reason: '$theme',
        );
        final ideas = themeIdeas(theme);
        expect(ideas, hasLength(3));
        expect(ideas.every((i) => fitsTheme(i, theme)), isTrue);
        expect(ideas.map((i) => i.slot).toSet(), hasLength(3));
        expect(themeCardColors[theme], hasLength(2));
      }
    });

    test('more matching items, more stars, never zero', () {
      const beach = ChallengeTheme.beach;
      // Nothing that fits (the sky background is for gardens).
      expect(themeMatches(Outfit.starter(), beach), 0);
      expect(challengeStars(Outfit.starter(), beach), 1);
      final one = _wear(['bg_beach']);
      expect(themeMatches(one, beach), 1);
      expect(challengeStars(one, beach), 1);
      final two = _wear(['bg_beach', 'shoes_sandals']);
      expect(challengeStars(two, beach), 2);
      final four = _wear([
        'bg_beach',
        'shoes_sandals',
        'dress_sun',
        'eyes_sun_heart',
      ]);
      expect(themeMatches(four, beach), 4);
      expect(challengeStars(four, beach), 3);
      // The same clothes are not great for snow.
      expect(challengeStars(four, ChallengeTheme.snow), 1);
      expect(
        challengeStars(
          _wear(['top_sweater', 'skirt_long', 'shoes_boots', 'bg_night']),
          ChallengeTheme.snow,
        ),
        3,
      );
    });

    test('a new card is never the same as the last one', () {
      final random = Random(5);
      var last = ChallengeTheme.party;
      final seen = <ChallengeTheme>{};
      for (var i = 0; i < 200; i++) {
        final next = pickTheme(random, last: last);
        expect(next, isNot(last));
        seen.add(next);
        last = next;
      }
      expect(seen, challengeThemes.toSet());
    });

    test('every theme has its picture', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final theme in ChallengeTheme.values) {
        final svg = await rootBundle.loadString(themeArt(theme));
        expect(svg, contains('<svg'));
      }
    });
  });

  group('saving stars', () {
    test('stars add up and are remembered', () async {
      expect(await GameSettings.challengeStars(), 0);
      expect(await GameSettings.addChallengeStars(2), 2);
      expect(await GameSettings.addChallengeStars(3), 5);
      expect(await GameSettings.challengeStars(), 5);
    });
  });

  group('screen', () {
    testWidgets('a whole challenge: card, dress up, check, stars', (
      tester,
    ) async {
      final audio = await _start(tester);
      expect(_starTotal(tester), '0');
      expect(find.byKey(const Key('challenge_check')), findsNothing);

      await _tap(tester, 'challenge_button');
      expect(find.byKey(const Key('theme_card')), findsOneWidget);
      // Which theme is it? Dress her for it.
      final theme = ChallengeTheme.values.firstWhere(
        (t) => find.byKey(Key('theme_${t.name}')).evaluate().isNotEmpty,
      );
      await _tap(tester, 'challenge_go');
      expect(find.byKey(const Key('theme_card')), findsNothing);
      expect(find.byKey(const Key('challenge_check')), findsOneWidget);

      final bg = itemsForSlot(
        Slot.background,
      ).firstWhere((i) => i.themes.contains(theme));
      final shoes = itemsForSlot(
        Slot.shoes,
      ).firstWhere((i) => i.themes.contains(theme), orElse: () => bg);
      await _wearOnScreen(tester, 'background', bg.id);
      if (shoes != bg) await _wearOnScreen(tester, 'shoes', shoes.id);

      await tester.tap(find.byKey(const Key('challenge_check')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('challenge_result')), findsOneWidget);
      expect(find.byKey(const Key('result_star_1')), findsOneWidget);
      await tester.pumpAndSettle();
      // The result closes by itself; the stars are added up.
      expect(find.byKey(const Key('challenge_result')), findsNothing);
      expect(find.byKey(const Key('challenge_check')), findsNothing);
      expect(int.parse(_starTotal(tester)), greaterThanOrEqualTo(2));
      expect(audio.played.where((s) => s == Sfx.sparkle).length, 2);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(GameSettings.challengeStarsKey),
        int.parse(_starTotal(tester)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing matching still wins a star and a celebration', (
      tester,
    ) async {
      await _start(tester);
      await _tap(tester, 'challenge_button');
      await _tap(tester, 'challenge_go');
      // Nothing changed: the starter look fits at most the garden.
      await tester.tap(find.byKey(const Key('challenge_check')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('result_star_0')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(int.parse(_starTotal(tester)), greaterThanOrEqualTo(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('another card, tap outside, and the card again', (
      tester,
    ) async {
      await _start(tester, size: const Size(320, 568));
      await _tap(tester, 'challenge_button');
      ChallengeTheme shown() => ChallengeTheme.values.firstWhere(
        (t) => find.byKey(Key('theme_${t.name}')).evaluate().isNotEmpty,
      );
      final first = shown();
      await _tap(tester, 'challenge_new');
      final second = shown();
      expect(second, isNot(first));
      // Tapping outside the card starts that challenge too.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('challenge_check')), findsOneWidget);
      // The Challenge button shows the same card again.
      await _tap(tester, 'challenge_button');
      expect(shown(), second);
      await _tap(tester, 'challenge_go');
      expect(tester.takeException(), isNull);
    });

    testWidgets('stars won earlier show on the main screen', (tester) async {
      SharedPreferences.setMockInitialValues({
        GameSettings.challengeStarsKey: 12,
        Rewards.dailyStarKey: '2026-11-24',
      });
      await _start(tester);
      expect(_starTotal(tester), '12');
    });
  });
}
