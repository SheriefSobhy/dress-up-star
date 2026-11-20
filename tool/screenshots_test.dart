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
import 'package:dress_up_star/main.dart';
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
  }
}
