// Renders phone-size screenshots of the game for reviewing the art.
//
//   flutter test tool/screenshots_test.dart
//
// Pictures are written to build/screenshots/ (or $SCREENSHOT_DIR).
// Run one screen size at a time (art caches are shared between tests):
//   flutter test tool/screenshots_test.dart --plain-name "390"
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String outDir =
    Platform.environment['SCREENSHOT_DIR'] ?? 'build/screenshots';
const Key rootKey = Key('screenshot_root');

Future<void> loadFonts() async {
  final fredoka = FontLoader('Fredoka')
    ..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'));
  await fredoka.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final file = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (file.existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await icons.load();
    }
  }
}

/// Lets the async art finish, then saves a picture of the whole screen.
Future<void> shot(WidgetTester tester, String name) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
  await tester.pump(const Duration(seconds: 2));
  final element = find.byKey(rootKey).evaluate().single;
  final bytes = await tester.runAsync(() async {
    final image = await captureImage(element);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  Directory(outDir).createSync(recursive: true);
  File('$outDir/$name.png').writeAsBytesSync(bytes!);
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pump(const Duration(milliseconds: 600));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Drags a finger along [points] (art space) on the activity stage.
Future<void> stroke(
  WidgetTester tester,
  Rect frame,
  List<Offset> points,
) async {
  final stage = tester.getRect(find.byKey(const Key('activity_stage')));
  final fit = FitTransform(frame, stage.size);
  Offset screen(Offset p) => stage.topLeft + fit.apply(p);
  final g = await tester.startGesture(screen(points.first));
  var last = points.first;
  for (final p in points.skip(1)) {
    for (var i = 1; i <= 4; i++) {
      await g.moveTo(screen(Offset.lerp(last, p, i / 4)!));
    }
    last = p;
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A zig-zag over a rectangle (art space), like a child scribbling.
List<Offset> scribble(Rect r, {int rows = 5}) => [
  for (var i = 0; i <= rows; i++) ...[
    Offset(r.left, r.top + r.height * i / rows),
    Offset(r.right, r.top + r.height * (i + 0.5) / rows),
  ],
];

Future<void> pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: rootKey,
      child: DressUpStarApp(storage: LooksStorage(), audio: SilentGameAudio()),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tap(tester, 'play_button');
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  GameMotion.idleAnimations = false;
  setUpAll(loadFonts);
  accessoryMain();
  setUp(
    // ignore: invalid_use_of_visible_for_testing_member
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
    }),
  );

  for (final size in const [Size(390, 844), Size(320, 640)]) {
    final tag = '${size.width.round()}';
    testWidgets('makeup screens $tag', (tester) async {
      await pumpApp(tester, size);
      await shot(tester, '${tag}_01_main');
      await tap(tester, 'activities_button');
      await shot(tester, '${tag}_02_picker');
      await tap(tester, 'activity_makeup');
      await shot(tester, '${tag}_03_makeup_empty');

      const frame = Rect.fromLTRB(16, 40, 184, 176);
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(90, 134, 110, 145)),
      );
      await tap(tester, 'tool_blush');
      await tap(tester, 'option_2');
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(52, 126, 74, 140)),
      );
      await tap(tester, 'tool_eyeshadow');
      await tap(tester, 'option_5');
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(60, 96, 95, 118)),
      );
      await tap(tester, 'option_1');
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(105, 96, 140, 118)),
      );
      await tap(tester, 'tool_lashes');
      await tap(tester, 'option_1');
      await stroke(tester, frame, const [Offset(78, 108), Offset(80, 110)]);
      await tap(tester, 'option_2');
      await stroke(tester, frame, const [Offset(122, 108), Offset(120, 110)]);
      await tap(tester, 'tool_stickers');
      await tap(tester, 'option_2');
      await stroke(tester, frame, const [Offset(120, 140), Offset(138, 124)]);
      await tap(tester, 'option_0');
      await stroke(tester, frame, const [Offset(100, 80), Offset(66, 100)]);
      await shot(tester, '${tag}_04_makeup_done');

      // The tool under the finger.
      await tap(tester, 'tool_lipstick');
      final stage = tester.getRect(find.byKey(const Key('activity_stage')));
      final fit = FitTransform(frame, stage.size);
      final g = await tester.startGesture(
        stage.topLeft + fit.apply(const Offset(96, 140)),
      );
      await g.moveTo(stage.topLeft + fit.apply(const Offset(100, 139)));
      await shot(tester, '${tag}_05_makeup_finger');
      await g.up();
      await tester.pump(const Duration(seconds: 2));

      await tap(tester, 'done_button');
      await tester.pump(const Duration(seconds: 2));
      await shot(tester, '${tag}_06_main_with_makeup');
    });

    testWidgets('salon screens $tag', (tester) async {
      await pumpApp(tester, size);
      await tap(tester, 'activities_button');
      await tap(tester, 'activity_salon');
      await shot(tester, '${tag}_10_salon_empty');

      const frame = Rect.fromLTRB(14, 24, 186, 292);
      // Wash: shampoo, then a bit of shower.
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(40, 50, 160, 90)),
      );
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(34, 110, 56, 200)),
      );
      await tap(tester, 'tool_shower');
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(40, 50, 160, 80)),
      );
      await shot(tester, '${tag}_11_salon_washing');
      // Dry everything, with the dryer still blowing.
      await tap(tester, 'tool_dryer');
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(30, 40, 170, 200), rows: 8),
      );
      final stage = tester.getRect(find.byKey(const Key('activity_stage')));
      final fit = FitTransform(frame, stage.size);
      final g = await tester.startGesture(
        stage.topLeft + fit.apply(const Offset(150, 140)),
      );
      await g.moveTo(stage.topLeft + fit.apply(const Offset(152, 150)));
      await shot(tester, '${tag}_12_salon_drying');
      await g.up();
      // Cut the left side short and the right side to the shoulders.
      await tap(tester, 'tool_scissors');
      await stroke(tester, frame, const [Offset(40, 150), Offset(46, 152)]);
      await stroke(tester, frame, const [Offset(158, 240), Offset(160, 242)]);
      await shot(tester, '${tag}_13_salon_cut');
      // Curl the right side, rainbow and pink paint.
      await tap(tester, 'tool_curler');
      await stroke(tester, frame, const [Offset(160, 160), Offset(162, 170)]);
      await tap(tester, 'tool_spray');
      await tap(tester, 'option_7');
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(128, 40, 172, 210), rows: 9),
      );
      await tap(tester, 'option_0');
      await stroke(
        tester,
        frame,
        scribble(const Rect.fromLTRB(30, 40, 70, 150), rows: 6),
      );
      await shot(tester, '${tag}_14_salon_styled');
      await tap(tester, 'done_button');
      await tester.pump(const Duration(seconds: 2));
      await shot(tester, '${tag}_15_main_with_salon');
      await tap(tester, 'activities_button');
      await shot(tester, '${tag}_16_picker');
    });

    testWidgets('nails screens $tag', (tester) async {
      await pumpApp(tester, size);
      await tap(tester, 'activities_button');
      await shot(tester, '${tag}_20_picker');
      await tap(tester, 'activity_nails');
      await shot(tester, '${tag}_21_nails_empty');

      const frame = Rect.fromLTRB(28, 46, 300, 374);
      const nails = [
        Offset(83, 140),
        Offset(123, 103),
        Offset(166, 88),
        Offset(211, 108),
        Offset(264, 211),
      ];
      // Soak two fingers.
      await stroke(tester, frame, const [Offset(80, 150), Offset(124, 112)]);
      // File three nails.
      await tap(tester, 'tool_file');
      for (final n in nails.take(3)) {
        await stroke(tester, frame, [
          n + const Offset(-8, -12),
          n + const Offset(8, -12),
          n + const Offset(-8, -12),
          n + const Offset(8, -12),
        ]);
      }
      await shot(tester, '${tag}_22_nails_soak_file');
      // Every nail its own color, one only half painted.
      await tap(tester, 'tool_polish');
      for (var i = 0; i < nails.length; i++) {
        await tap(tester, 'option_${[1, 7, 9, 5, 0][i]}');
        final n = nails[i];
        await stroke(
          tester,
          frame,
          i == 4
              ? [n + const Offset(-6, 0), n + const Offset(6, -4)]
              : scribble(Rect.fromCenter(center: n, width: 18, height: 24)),
        );
      }
      await shot(tester, '${tag}_23_nails_painted');
      // Decorations and drying.
      await tap(tester, 'tool_deco');
      await stroke(tester, frame, [const Offset(160, 250), nails[2]]);
      await tap(tester, 'option_2');
      await stroke(tester, frame, [const Offset(160, 250), nails[1]]);
      await tap(tester, 'option_3');
      await stroke(tester, frame, [const Offset(160, 250), nails[3]]);
      await tap(tester, 'tool_dryer');
      await stroke(tester, frame, [
        for (final n in nails) n + const Offset(0, 10),
      ]);
      await shot(tester, '${tag}_24_nails_done');
      await tap(tester, 'done_button');
      await tester.pump(const Duration(seconds: 2));
      await shot(tester, '${tag}_25_main_with_nails');
    });

    testWidgets('jewelry and glasses screens $tag', (tester) async {
      await pumpApp(tester, size);
      await tapInRow(tester, 'category_jewelry', 'category_bar');
      await shot(tester, '${tag}_30_jewelry');
      await tapInRow(tester, 'item_neck_heart', 'item_row');
      await tapInRow(tester, 'item_ears_star', 'item_row');
      await tapInRow(tester, 'item_wrist_charm', 'item_row');
      await shot(tester, '${tag}_31_jewelry_worn');
      await tapInRow(tester, 'category_glasses', 'category_bar');
      await tapInRow(tester, 'item_eyes_cat_eye', 'item_row');
      await tap(tester, 'activities_button');
      await tap(tester, 'activity_makeup');
      await shot(tester, '${tag}_33_makeup_glasses');
      await tap(tester, 'tool_eyeshadow');
      await shot(tester, '${tag}_34_makeup_eyeshadow');
      await tap(tester, 'done_button');
      await tester.pump(const Duration(seconds: 2));
      await tap(tester, 'activities_button');
      await tap(tester, 'activity_salon');
      await shot(tester, '${tag}_35_salon_glasses');
      await tap(tester, 'done_button');
      await tester.pump(const Duration(seconds: 2));
      await tapInRow(tester, 'item_eyes_sun_heart', 'item_row');
      await shot(tester, '${tag}_32_sunglasses');
    });
  }
}

/// Scrolls [row] until [key] shows, then taps it.
Future<void> tapInRow(WidgetTester tester, String key, String row) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    80,
    scrollable: find.descendant(
      of: find.byKey(Key(row)),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pump(const Duration(milliseconds: 400));
  await tap(tester, key);
}

/// Draws one doll picture per entry of [looks] in a grid and saves it.
Future<void> grid(
  WidgetTester tester,
  String name,
  List<Outfit> looks,
  Rect frame, {
  int columns = 5,
  double cell = 180,
}) async {
  await tester.runAsync(() async {
    final rows = (looks.length / columns).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(columns * cell, rows * cell * frame.height / frame.width);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFF0F7),
    );
    final h = cell * frame.height / frame.width;
    for (var i = 0; i < looks.length; i++) {
      final recipe = await dollRecipe(looks[i]);
      final image = await rasterizeDoll(
        recipe.flat(Face.open),
        frame,
        Size(cell, h),
      );
      canvas.drawImage(
        image,
        Offset((i % columns) * cell, (i ~/ columns) * h),
        Paint(),
      );
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

void accessoryMain() {
  testWidgets('accessory grids', (tester) async {
    final hairs = itemsForSlot(Slot.hair);
    final glasses = itemsForSlot(Slot.eyes);
    for (final g in glasses) {
      await grid(
        tester,
        'grid_glasses_${g.id}',
        [for (final h in hairs) Outfit.starter().wear(h).wear(g)],
        const Rect.fromLTRB(20, 30, 180, 170),
        columns: 4,
      );
    }
    await grid(tester, 'grid_glasses_all', [
      for (final g in glasses)
        Outfit.starter().wear(findItem('hair_bob')!).wear(g),
    ], const Rect.fromLTRB(30, 60, 170, 160));
    final jewelry = [
      ...itemsForSlot(Slot.neck),
      ...itemsForSlot(Slot.ears),
      ...itemsForSlot(Slot.wrist),
    ];
    await grid(tester, 'grid_jewelry_close', [
      for (final j in jewelry)
        Outfit.starter().wear(findItem('hair_bun')!).wear(j),
    ], const Rect.fromLTRB(20, 90, 180, 270));
    await grid(
      tester,
      'grid_jewelry_hair',
      [
        for (final h in hairs)
          Outfit.starter()
              .wear(h)
              .wear(findItem('dress_party')!)
              .wear(findItem('neck_heart')!)
              .wear(findItem('ears_gem')!)
              .wear(findItem('wrist_bangle')!),
      ],
      const Rect.fromLTRB(10, 40, 190, 280),
      columns: 4,
    );
  });
}
