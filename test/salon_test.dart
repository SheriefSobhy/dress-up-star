import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/screens/activities/salon_screen.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/widgets/live_doll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity_helpers.dart';

LiveDoll doll(WidgetTester tester) =>
    tester.widget<LiveDoll>(find.byType(LiveDoll));
SalonHair salonOnStage(WidgetTester tester) => doll(tester).outfit.salon;

void main() {
  GameMotion.idleAnimations = false;
  setUp(
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
    }),
  );

  testWidgets('wash with shampoo and shower, then dry to make it shine', (
    tester,
  ) async {
    final audio = await openActivity(tester, 'salon');
    expect(doll(tester).outfit[Slot.hair]!.item.id, salonHairId);

    // Shampoo on her face does nothing; on the hair it foams.
    await drag(tester, kSalonFrame, const [Offset(100, 120), Offset(102, 124)]);
    expect(audio.played, isNot(contains(Sfx.bubble)));
    await drag(
      tester,
      kSalonFrame,
      scribble(const Rect.fromLTRB(60, 46, 140, 70)),
    );
    expect(audio.played, contains(Sfx.bubble));

    await tapKey(tester, 'tool_shower');
    await drag(
      tester,
      kSalonFrame,
      scribble(const Rect.fromLTRB(60, 46, 140, 70)),
    );
    expect(doll(tester).wetHair!.isEmpty, isFalse);
    expect(audio.played, contains(Sfx.water));
    expect(salonOnStage(tester).shine.isEmpty, isTrue);

    await tapKey(tester, 'tool_dryer');
    await drag(
      tester,
      kSalonFrame,
      scribble(const Rect.fromLTRB(50, 40, 150, 76)),
    );
    expect(doll(tester).wetHair!.isEmpty, isTrue);
    expect(salonOnStage(tester).shine.isEmpty, isFalse);
    expect(audio.played, contains(Sfx.blow));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scissors cut each side, grow back makes it long again', (
    tester,
  ) async {
    final audio = await openActivity(tester, 'salon');
    await tapKey(tester, 'tool_scissors');
    await drag(tester, kSalonFrame, const [Offset(42, 240), Offset(44, 242)]);
    expect(salonOnStage(tester).cutLeft, 1);
    expect(salonOnStage(tester).cutRight, 0);
    expect(audio.played, contains(Sfx.snip));
    await drag(tester, kSalonFrame, const [Offset(42, 150), Offset(44, 152)]);
    expect(salonOnStage(tester).cutLeft, 2);
    // Snipping where the hair is already gone does nothing.
    await drag(tester, kSalonFrame, const [Offset(42, 240), Offset(44, 242)]);
    expect(salonOnStage(tester).cutLeft, 2);

    await tapKey(tester, 'grow_button');
    expect(salonOnStage(tester).cutLeft, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('curl and straighten, spray paints only where touched', (
    tester,
  ) async {
    await openActivity(tester, 'salon');
    await tapKey(tester, 'tool_curler');
    await drag(tester, kSalonFrame, const [Offset(158, 170), Offset(160, 176)]);
    expect(salonOnStage(tester).curlRight, isTrue);
    expect(salonOnStage(tester).curlLeft, isFalse);
    await tapKey(tester, 'option_1'); // straighten
    await drag(tester, kSalonFrame, const [Offset(158, 170), Offset(160, 176)]);
    expect(salonOnStage(tester).curlRight, isFalse);

    await tapKey(tester, 'tool_spray');
    await tapKey(tester, 'option_7'); // rainbow
    await drag(tester, kSalonFrame, const [Offset(40, 150), Offset(42, 160)]);
    final dye = salonOnStage(tester).dye;
    final painted = [
      for (var i = 0; i < hairZone.length; i++)
        if (dye[i] != null) i,
    ];
    expect(painted, isNotEmpty);
    expect(painted.length, lessThan(12));
    expect(painted.every((i) => hairZone.spots[i].dx < 70), isTrue);
    expect(dye[painted.first], hairDyeColors.length - 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undo all, done keeps the hairdo, saved and shown again', (
    tester,
  ) async {
    await openActivity(tester, 'salon');
    await tapKey(tester, 'tool_scissors');
    await drag(tester, kSalonFrame, const [Offset(158, 240), Offset(160, 242)]);
    final cut = salonOnStage(tester);
    expect(cut.cutRight, 1);
    await tapKey(tester, 'undo_button');
    expect(salonOnStage(tester).isNatural, isTrue);
    await tapKey(tester, 'undo_button');
    expect(salonOnStage(tester), cut);

    await tapKey(tester, 'done_button');
    final saved = await saveAndReadLook(tester);
    expect(saved.salon, cut);
    expect(saved.hasSalonHair, isTrue);

    await tapKey(tester, 'activities_button');
    await tapKey(tester, 'activity_salon');
    expect(salonOnStage(tester), cut);
  });

  testWidgets('leaving the salon untouched keeps her own hair style', (
    tester,
  ) async {
    await openActivity(tester, null);
    await tapKey(tester, 'activities_close');
    await tapKey(tester, 'item_hair_bob');
    await tapKey(tester, 'activities_button');
    await tapKey(tester, 'activity_salon');
    expect(doll(tester).outfit[Slot.hair]!.item.id, salonHairId);
    await tapKey(tester, 'done_button');
    expect((await saveAndReadLook(tester))[Slot.hair]!.item.id, 'hair_bob');
  });

  testWidgets('the salon fits on a small phone', (tester) async {
    await openActivity(tester, 'salon', size: const Size(320, 568));
    for (final t in [
      'shampoo',
      'shower',
      'dryer',
      'scissors',
      'curler',
      'spray',
    ]) {
      final rect = tester.getRect(find.byKey(Key('tool_$t')));
      expect(rect.right, lessThanOrEqualTo(320), reason: t);
      await tapKey(tester, 'tool_$t');
    }
    for (var i = 0; i < hairDyeColors.length; i++) {
      final rect = tester.getRect(find.byKey(Key('option_$i')));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    expect(tester.takeException(), isNull);
  });
}
