import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/screens/activities/nails_screen.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity_helpers.dart';

/// The nails on the stage, read back through Done and the camera.
Future<NailSet> finishAndSave(WidgetTester tester) async {
  await tapKey(tester, 'done_button');
  return (await saveAndReadLook(tester)).nails;
}

Future<void> paintNail(WidgetTester tester, int n) => drag(
  tester,
  kHandFrame,
  scribble(
    Rect.fromCenter(center: kFingers[n].nailCenter, width: 16, height: 22),
  ),
);

void main() {
  GameMotion.idleAnimations = false;
  setUp(
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
    }),
  );

  testWidgets('each nail gets its own color, only where painted', (
    tester,
  ) async {
    final audio = await openActivity(tester, 'nails');
    expect(find.byKey(const Key('nails_face')), findsOneWidget);
    await tapKey(tester, 'tool_polish');
    await tapKey(tester, 'option_0');
    await paintNail(tester, 0);
    await tapKey(tester, 'option_9'); // glitter
    await paintNail(tester, 2);
    // Painting the back of the hand does nothing.
    await drag(
      tester,
      kHandFrame,
      scribble(const Rect.fromLTRB(120, 240, 190, 290)),
    );
    expect(audio.played, contains(Sfx.brush));
    expect(audio.played, contains(Sfx.sparkle));

    final nails = await finishAndSave(tester);
    expect(nails.colorOf(0), 0);
    expect(nails.colorOf(1), isNull);
    expect(nails.colorOf(2), 9);
    expect(nails.colorOf(3), isNull);
    expect(
      nails.polish.countPainted(nailZone.regions[0]),
      nailZone.regions[0].length,
    );
  });

  testWidgets('soak, file, decorate and dry until they shine', (tester) async {
    final audio = await openActivity(tester, 'nails');
    await drag(tester, kHandFrame, [
      kFingers[1].nailCenter,
      kFingers[2].nailCenter,
    ]);
    expect(audio.played, contains(Sfx.water));

    await tapKey(tester, 'tool_file');
    final f = kFingers[1];
    final tip = f.nailPoint(Offset(0, -f.nailLength * 0.55));
    await drag(tester, kHandFrame, [
      for (var i = 0; i < 6; i++) tip + Offset(i.isEven ? -8 : 8, 0),
    ]);

    await tapKey(tester, 'tool_polish');
    await paintNail(tester, 1);
    await tapKey(tester, 'tool_deco');
    await tapKey(tester, 'option_3'); // flower
    await drag(tester, kHandFrame, [const Offset(160, 260), f.nailCenter]);
    // Dropped on the back of the hand: no decoration.
    await drag(tester, kHandFrame, const [Offset(160, 260), Offset(150, 290)]);

    await tapKey(tester, 'tool_dryer');
    await drag(tester, kHandFrame, [f.nailCenter, kFingers[3].nailCenter]);
    expect(audio.played, contains(Sfx.blow));

    final nails = await finishAndSave(tester);
    expect(nails.filed[1], 0);
    expect(nails.filed[0], isNull);
    expect(nails.deco[1], NailDeco.flower.index);
    expect(nails.deco.cells.replaceAll('.', ''), 'd');
    expect(nails.shine[1], 0);
    expect(nails.shine[3], isNull); // nothing painted there to shine
  });

  testWidgets('undo all and bring it back; nails come back next time', (
    tester,
  ) async {
    await openActivity(tester, 'nails');
    await tapKey(tester, 'tool_polish');
    await paintNail(tester, 4);
    await tapKey(tester, 'undo_button');
    await tapKey(tester, 'undo_button');
    final nails = await finishAndSave(tester);
    expect(nails.colorOf(4), 0);

    await tapKey(tester, 'activities_button');
    await tapKey(tester, 'activity_nails');
    await tapKey(tester, 'undo_button');
    expect((await finishAndSave(tester)).isEmpty, isTrue);
  });

  testWidgets('nails fit on a small phone', (tester) async {
    await openActivity(tester, 'nails', size: const Size(320, 568));
    for (final t in ['soak', 'file', 'polish', 'deco', 'dryer']) {
      final rect = tester.getRect(find.byKey(Key('tool_$t')));
      expect(rect.right, lessThanOrEqualTo(320), reason: t);
      await tapKey(tester, 'tool_$t');
    }
    await tapKey(tester, 'tool_polish');
    for (var i = 0; i < nailColors.length; i++) {
      final rect = tester.getRect(find.byKey(Key('option_$i')));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    await paintNail(tester, 2);
    expect(tester.takeException(), isNull);
  });
}
