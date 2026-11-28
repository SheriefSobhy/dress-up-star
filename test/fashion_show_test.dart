import 'dart:convert';
import 'dart:math';

import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/challenge.dart';
import 'package:dress_up_star/models/fashion_show.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:dress_up_star/services/rewards.dart';
import 'package:dress_up_star/widgets/art_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Outfit _wear(List<String> ids) =>
    ids.fold(Outfit.starter(), (o, id) => o.wear(findItem(id)!));

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
  await _tap(tester, 'play_button');
  return audio;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Show button, theme card, then the green Go button.
Future<void> _goOnStage(WidgetTester tester) async {
  await _tap(tester, 'show_button');
  expect(find.byKey(const Key('theme_card')), findsOneWidget);
  await _tap(tester, 'challenge_go');
  await tester.tap(find.byKey(const Key('show_go')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byKey(const Key('fashion_show')), findsOneWidget);
}

/// Watches the whole show, frame by frame.
Future<void> _watch(WidgetTester tester, {double seconds = 15}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

int _stars(WidgetTester tester) =>
    int.parse(tester.widget<Text>(find.byKey(const Key('star_total'))).data!);

void main() {
  GameMotion.idleAnimations = false;
  setUp(() {
    Rewards.now = () => DateTime(2026, 11, 24);
    SharedPreferences.setMockInitialValues({
      Rewards.dailyStarKey: '2026-11-24',
      GameSettings.scrollHintSeenKey: true,
      GameSettings.tutorialSeenKey: true,
    });
  });
  tearDown(() => GameMotion.lite.value = false);

  group('themes', () {
    test('the show has every theme; challenges keep their six', () {
      expect(ChallengeTheme.values, hasLength(10));
      expect(challengeThemes, hasLength(6));
    });

    test('extra theme items exist', () {
      for (final ids in extraThemeItems.values) {
        for (final id in ids) {
          expect(findItem(id), isNotNull, reason: id);
        }
      }
    });

    test('every theme has free matching items, a card and a picture', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final theme in ChallengeTheme.values) {
        final free = gameItems
            .where((i) => !i.isSpecial && fitsTheme(i, theme))
            .map((i) => i.slot)
            .toSet();
        expect(free.length, greaterThanOrEqualTo(3), reason: '$theme');
        expect(themeCardColors[theme], hasLength(2));
        expect(await rootBundle.loadString(themeArt(theme)), contains('<svg'));
      }
      expect(await rootBundle.loadString(runwayScene), contains('<svg'));
      for (final sound in ['runway', 'cheer']) {
        expect(
          (await rootBundle.load('assets/sounds/$sound.wav')).lengthInBytes,
          greaterThan(1000),
        );
      }
    });
  });

  group('scoring', () {
    test('cards are 2 to 5 and stars 1 to 3 for any outfit', () {
      final random = Random(3);
      for (var i = 0; i < 300; i++) {
        final score = ShowScore.of(
          Outfit.random(random),
          ChallengeTheme.values[i % ChallengeTheme.values.length],
        );
        expect(score.cards.keys.toSet(), Judge.values.toSet());
        for (final card in score.cards.values) {
          expect(card, inInclusiveRange(minCard, maxCard));
        }
        expect(score.shopStars, inInclusiveRange(1, 3));
      }
    });

    test('even an empty outfit gets friendly cards', () {
      final empty = Outfit(const {});
      final score = ShowScore.of(empty, ChallengeTheme.space);
      expect(score.cards.values.every((c) => c >= 2), isTrue);
      expect(score.shopStars, 1);
    });

    test('the theme, more things and matching colors score higher', () {
      const theme = ChallengeTheme.sports;
      final plain = ShowScore.of(Outfit.starter(), theme);
      final sporty = _wear([
        'bg_garden',
        'top_tshirt',
        'pants_shorts',
        'shoes_sneakers',
        'hat_cap',
        'wrist_friendship',
      ]);
      final good = ShowScore.of(sporty, theme);
      expect(good.cards[Judge.cat], 5);
      expect(good.cards[Judge.bunny], 5);
      expect(good.cards[Judge.cat]!, greaterThan(plain.cards[Judge.cat]!));

      var matched = sporty;
      var clashing = sporty;
      const rainbow = [
        Color(0xFFE8384F),
        Color(0xFFFF9A3C),
        Color(0xFFFFD84D),
        Color(0xFF3FBF55),
        Color(0xFF3C8CE8),
        Color(0xFF9B5DE5),
      ];
      var i = 0;
      for (final slot in sporty.worn.keys) {
        if (slot == Slot.background || slot == Slot.hair) continue;
        matched = matched.recolor(slot, rainbow.first);
        clashing = clashing.recolor(slot, rainbow[i++ % rainbow.length]);
      }
      expect(ShowScore.of(matched, theme).cards[Judge.owl], 5);
      expect(ShowScore.of(clashing, theme).cards[Judge.owl], 2);
      expect(ShowScore.of(matched, theme).shopStars, 3);
    });

    test('totals turn into 1, 2 or 3 stars', () {
      ShowScore cards(int a, int b, int c) =>
          ShowScore({Judge.cat: a, Judge.bunny: b, Judge.owl: c});
      expect(cards(2, 2, 2).shopStars, 1);
      expect(cards(3, 3, 3).shopStars, 1);
      expect(cards(4, 3, 3).shopStars, 2);
      expect(cards(4, 4, 4).shopStars, 2);
      expect(cards(5, 4, 4).shopStars, 3);
    });

    test('two different poses', () {
      for (var seed = 0; seed < 50; seed++) {
        final poses = showPoses(Random(seed));
        expect(poses.toSet(), hasLength(2));
        expect(poses, isNot(contains(DollPose.stand)));
      }
    });
  });

  test('a runway photo is remembered and is still the same look', () {
    final look = _wear(['dress_party']);
    final photo = look.copyWith(runway: true);
    final read = Outfit.fromJson(
      jsonDecode(jsonEncode(photo.toJson())) as Map<String, dynamic>,
    );
    expect(read.runway, isTrue);
    expect(read, look);
    expect(Outfit.fromJson(look.toJson()).runway, isFalse);
  });

  group('screen', () {
    testWidgets('a whole show: card, go, runway, judges, stars, photo', (
      tester,
    ) async {
      final audio = await _start(tester);
      expect(find.byKey(const Key('show_go')), findsNothing);
      await _goOnStage(tester);
      expect(audio.track, MusicTrack.show);
      expect(audio.musicPlaying, isTrue);
      expect(find.byKey(const Key('judge_cat')), findsNothing);
      await _watch(tester);

      for (final judge in Judge.values) {
        expect(find.byKey(Key('judge_${judge.name}')), findsOneWidget);
        expect(find.byKey(Key('card_${judge.name}_1')), findsOneWidget);
      }
      expect(find.byKey(const Key('show_trophy')), findsOneWidget);
      expect(find.byKey(const Key('show_star_0')), findsOneWidget);
      expect(audio.played, contains(Sfx.cheer));
      final prefs = await SharedPreferences.getInstance();
      final won = prefs.getInt(GameSettings.challengeStarsKey)!;
      expect(won, inInclusiveRange(1, 3));

      // The photo is saved once, however often it is tapped.
      await tester.tap(find.byKey(const Key('show_photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('show_photo')));
      await tester.pumpAndSettle();
      final looks = await LooksStorage().load();
      expect(looks, hasLength(1));
      expect(looks.single.runway, isTrue);

      await _tap(tester, 'show_done');
      expect(find.byKey(const Key('fashion_show')), findsNothing);
      expect(find.byKey(const Key('show_go')), findsNothing);
      expect(audio.track, MusicTrack.game);
      expect(_stars(tester), won);
      expect(
        find.descendant(
          of: find.byKey(const Key('gallery_button')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      // Wearing the photo again gives an ordinary look.
      await _tap(tester, 'gallery_button');
      await _tap(tester, 'look_0');
      await _tap(tester, 'camera_button');
      expect((await LooksStorage().load()).first.runway, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaving early wins nothing and brings the music back', (
      tester,
    ) async {
      final audio = await _start(tester);
      await _goOnStage(tester);
      await _watch(tester, seconds: 4);
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
      expect(_stars(tester), 0);
      expect(audio.track, MusicTrack.game);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mute and the parents\' switches are respected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        GameAudio.musicOnKey: false,
        GameAudio.soundsOnKey: false,
        GameSettings.scrollHintSeenKey: true,
        GameSettings.tutorialSeenKey: true,
        Rewards.dailyStarKey: '2026-11-24',
      });
      final audio = await _start(tester);
      await audio.loadSettings();
      audio.played.clear();
      await _goOnStage(tester);
      await _watch(tester);
      expect(audio.musicPlaying, isFalse);
      expect(audio.played, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lite mode on a small phone', (tester) async {
      GameMotion.lite.value = true;
      await _start(tester, size: const Size(320, 568));
      await _goOnStage(tester);
      await _watch(tester);
      expect(find.byKey(const Key('show_trophy')), findsOneWidget);
      await tester.pumpAndSettle();
      await _tap(tester, 'show_done');
      expect(tester.takeException(), isNull);
    });

    testWidgets('another card, and a challenge replaces the show', (
      tester,
    ) async {
      await _start(tester);
      ChallengeTheme shown() => ChallengeTheme.values.firstWhere(
        (t) => find.byKey(Key('theme_${t.name}')).evaluate().isNotEmpty,
      );
      await _tap(tester, 'show_button');
      final first = shown();
      await _tap(tester, 'challenge_new');
      expect(shown(), isNot(first));
      await _tap(tester, 'challenge_go');
      expect(find.byKey(const Key('show_go')), findsOneWidget);
      await _tap(tester, 'challenge_button');
      await _tap(tester, 'challenge_go');
      expect(find.byKey(const Key('show_go')), findsNothing);
      expect(find.byKey(const Key('challenge_check')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
