// Renders the second wardrobe for reviewing the art (390 wide only).
//
//   flutter test tool/clothes_screenshots_test.dart
//
// Pictures are written to build/screenshots/ (or $SCREENSHOT_DIR).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screenshots_test.dart';

Outfit look(List<String> ids) =>
    ids.fold(Outfit.starter(), (o, id) => o.wear(findItem(id)!));

/// A sheet of shaded dolls, [columns] across.
Future<void> sheet(
  WidgetTester tester,
  String name,
  List<Outfit> looks, {
  Rect frame = const Rect.fromLTRB(0, -4, 200, 376),
  int columns = 6,
  double cell = 230,
  DollPose? pose,
}) async {
  await tester.runAsync(() async {
    final h = cell * frame.height / frame.width;
    final size = Size(columns * cell, (looks.length / columns).ceil() * h);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFDDEEFF),
    );
    for (var i = 0; i < looks.length; i++) {
      final paint = await posedDollPainter(
        looks[i],
        heldPoseFrame(pose ?? DollPose.stand),
        depth: true,
      );
      final at = Offset((i % columns) * cell, (i ~/ columns) * h);
      canvas.save();
      canvas.clipRect(at & Size(cell, h));
      final fit = FitTransform(frame, Size(cell, h));
      canvas.translate(at.dx + fit.dx, at.dy + fit.dy);
      canvas.scale(fit.scale);
      paint(canvas);
      canvas.restore();
    }
    final image = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(outDir).createSync(recursive: true);
    File('$outDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

List<String> idsOf(String category) => [
  for (final i in itemsForCategory(
    gameCategories.firstWhere((c) => c.id == category),
  ))
    i.id,
];

void main() {
  GameMotion.idleAnimations = false;
  setUpAll(loadFonts);
  setUp(
    // ignore: invalid_use_of_visible_for_testing_member
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
    }),
  );

  testWidgets('wardrobe sheets', (tester) async {
    const under = ['top_tank', 'skirt_aline'];
    await sheet(tester, 'new_jackets', [
      for (final id in idsOf('jackets')) look([...under, id]),
      for (final id in idsOf('jackets')) look(['dress_princess', id]),
    ]);
    await sheet(tester, 'new_pants', [
      for (final id in idsOf('pants'))
        look(['top_tshirt', 'shoes_sneakers', id]),
      look(['pants_leggings', 'top_sweater', 'shoes_boots']),
      for (final id in idsOf('pants')) look(['top_polo', 'shoes_boots', id]),
    ]);
    await sheet(tester, 'new_socks', [
      for (final id in idsOf('socks')) look([id, 'shoes_mary_janes']),
      look([]),
      for (final id in idsOf('socks')) look([id, 'top_blouse', 'skirt_tutu']),
    ]);
    await sheet(tester, 'new_costumes', [
      for (final id in idsOf('costumes')) look([id, 'shoes_flats']),
    ]);
    await sheet(tester, 'new_pajamas_sport', [
      for (final id in [...idsOf('pajamas'), ...idsOf('sportswear')])
        look([id, 'shoes_sneakers']),
    ], columns: 4);
    await sheet(tester, 'new_more', [
      look(['dress_sailor', 'shoes_mary_janes']),
      look(['dress_strawberry', 'shoes_roller_skates']),
      look(['top_blouse', 'skirt_pleated', 'shoes_mary_janes']),
      look(['top_polo', 'skirt_ruffle', 'shoes_roller_skates']),
    ], columns: 4);
  });

  testWidgets('hats on every hair', (tester) async {
    for (final hat in idsOf('hats')) {
      await sheet(
        tester,
        'new_$hat',
        [
          for (final hair in itemsForSlot(Slot.hair)) look([hair.id, hat]),
        ],
        frame: const Rect.fromLTRB(10, -4, 190, 180),
        columns: 4,
        cell: 220,
      );
    }
  });

  testWidgets('poses', (tester) async {
    await poseGrid(tester, 'new_poses_a', [
      look(['jacket_puffer', 'dress_princess', 'hat_witch']),
      look(['jacket_raincoat', 'top_tank', 'pants_flared', 'hat_sun']),
      look(['pajama_stars', 'hat_beanie']),
      look(['shop_pajama_bunny', 'hair_pigtails']),
    ]);
    await poseGrid(tester, 'new_poses_b', [
      look(['shop_costume_mermaid']),
      look(['costume_doctor', 'hand_bag']),
      look(['shop_costume_fairy', 'shop_hat_flower_crown', 'hand_wand']),
      look(['sport_tracksuit', 'hat_cap']),
    ]);
  });

  testWidgets('screens 390', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await shot(tester, '390_c00_main');
    for (final id in [
      'jackets',
      'pants',
      'costumes',
      'pajamas',
      'sportswear',
      'socks',
      'hats',
    ]) {
      await tapInRow(tester, 'category_$id', 'category_bar');
      await tapInRow(tester, 'item_${idsOf(id).first}', 'item_row');
      await shot(tester, '390_c_$id');
    }
    // Dancing in a jacket over a swinging dress.
    await tapInRow(tester, 'item_hat_beanie', 'item_row');
    await tester.tap(find.byKey(const Key('dance_button')));
    await tester.pump();
    final frames = <ui.Image>[];
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 214));
      frames.add(await captureScreen(tester));
    }
    await saveStrip(
      tester,
      '390_c_dance',
      frames,
      const Rect.fromLTWH(40, 60, 310, 470),
    );
    await tester.pump(const Duration(seconds: 12));
  });
}
