import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/screens/activities/makeup_screen.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/widgets/live_doll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity_helpers.dart';

Makeup makeupOnStage(WidgetTester tester) =>
    tester.widget<LiveDoll>(find.byType(LiveDoll)).outfit.makeup;

const Rect lipsArea = Rect.fromLTRB(90, 134, 110, 145);

void main() {
  GameMotion.idleAnimations = false;
  setUp(
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
    }),
  );

  testWidgets('the activities button opens the picker, which can close', (
    tester,
  ) async {
    await openActivity(tester, null);
    expect(find.byKey(const Key('activity_makeup')), findsOneWidget);
    await tapKey(tester, 'activities_close');
    expect(find.byKey(const Key('activity_makeup')), findsNothing);
    expect(find.byKey(const Key('camera_button')), findsOneWidget);
  });

  testWidgets('lipstick paints only where the finger touches', (tester) async {
    final audio = await openActivity(tester, 'makeup');
    expect(find.byKey(const Key('activity_stage')), findsOneWidget);
    expect(makeupOnStage(tester).isEmpty, isTrue);

    // Rubbing the forehead does nothing.
    await drag(
      tester,
      kMakeupFrame,
      scribble(const Rect.fromLTRB(80, 60, 120, 80)),
    );
    expect(makeupOnStage(tester).isEmpty, isTrue);

    // A small dab paints part of the lips.
    await tapKey(tester, 'option_1');
    await drag(tester, kMakeupFrame, const [Offset(93, 137), Offset(95, 137)]);
    final dab = makeupOnStage(tester).lips;
    expect(dab.countPainted(lipsZone.regions[0]), greaterThan(0));
    expect(dab.countPainted(lipsZone.regions[0]), lessThan(lipsZone.length));
    expect(dab.mainColor(lipsZone.regions[0]), 1);
    expect(audio.played, contains(Sfx.brush));
    expect(makeupOnStage(tester).blush.isEmpty, isTrue);

    // Scribbling all over them finishes them neatly.
    await drag(tester, kMakeupFrame, scribble(lipsArea));
    expect(
      makeupOnStage(tester).lips.countPainted(lipsZone.regions[0]),
      lipsZone.length,
    );
    expect(audio.played, contains(Sfx.sparkle));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every tool works, the sponge wipes, undo all and back', (
    tester,
  ) async {
    await openActivity(tester, 'makeup');
    await drag(tester, kMakeupFrame, scribble(lipsArea));
    await tapKey(tester, 'tool_blush');
    await drag(
      tester,
      kMakeupFrame,
      scribble(const Rect.fromLTRB(52, 126, 74, 140)),
    );
    await tapKey(tester, 'tool_eyeshadow');
    await tapKey(tester, 'option_5'); // glitter
    await drag(
      tester,
      kMakeupFrame,
      scribble(const Rect.fromLTRB(60, 96, 95, 118)),
    );
    await tapKey(tester, 'tool_lashes');
    await tapKey(tester, 'option_2');
    await drag(tester, kMakeupFrame, const [
      Offset(122, 108),
      Offset(121, 110),
    ]);
    await tapKey(tester, 'tool_stickers');
    await tapKey(tester, 'option_1'); // heart
    await drag(tester, kMakeupFrame, const [
      Offset(120, 150),
      Offset(138, 126),
    ]);
    // Dropped outside the face: no sticker.
    await drag(tester, kMakeupFrame, const [Offset(120, 150), Offset(30, 60)]);

    var m = makeupOnStage(tester);
    expect(m.lips.isEmpty, isFalse);
    expect(m.blush.countPainted(blushZone.regions[0]), greaterThan(0));
    expect(m.blush.countPainted(blushZone.regions[1]), 0);
    expect(m.shadow.mainColor(shadowZone.regions[0]), 5);
    expect(m.lashLeft, 0);
    expect(m.lashRight, 3);
    expect(m.stickers.single.kind, StickerKind.heart);

    // The sponge wipes the lips only where it rubs.
    await tapKey(tester, 'tool_sponge');
    await drag(tester, kMakeupFrame, scribble(lipsArea));
    m = makeupOnStage(tester);
    expect(m.lips.isEmpty, isTrue);
    expect(m.blush.isEmpty, isFalse);

    // Undo all, then bring it back.
    await tapKey(tester, 'undo_button');
    expect(makeupOnStage(tester).isEmpty, isTrue);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    await tapKey(tester, 'undo_button');
    expect(makeupOnStage(tester), m);
    expect(find.byIcon(Icons.undo_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('done keeps the makeup on the doll, the camera saves it', (
    tester,
  ) async {
    await openActivity(tester, 'makeup');
    await drag(tester, kMakeupFrame, scribble(lipsArea));
    await tapKey(tester, 'done_button');
    expect(find.byKey(const Key('camera_button')), findsOneWidget);

    final saved = await saveAndReadLook(tester);
    expect(
      saved.makeup.lips.countPainted(lipsZone.regions[0]),
      lipsZone.length,
    );

    // Opening Makeup again shows the same makeup.
    await tapKey(tester, 'activities_button');
    await tapKey(tester, 'activity_makeup');
    expect(makeupOnStage(tester), saved.makeup);

    // The back button also keeps it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('camera_button')), findsOneWidget);
    expect((await saveAndReadLook(tester)).makeup, saved.makeup);
  });

  testWidgets('makeup fits on a small phone', (tester) async {
    await openActivity(tester, 'makeup', size: const Size(320, 568));
    for (final t in [
      'lipstick',
      'blush',
      'eyeshadow',
      'lashes',
      'stickers',
      'sponge',
    ]) {
      final rect = tester.getRect(find.byKey(Key('tool_$t')));
      expect(rect.left, greaterThanOrEqualTo(0), reason: t);
      expect(rect.right, lessThanOrEqualTo(320), reason: t);
      expect(rect.width, greaterThanOrEqualTo(44), reason: t);
      await tapKey(tester, 'tool_$t');
    }
    await drag(tester, kMakeupFrame, scribble(lipsArea));
    expect(tester.takeException(), isNull);
  });
}
