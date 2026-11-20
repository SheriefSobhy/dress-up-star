import 'dart:convert';

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts the game, presses Play, opens the Activities picker and the
/// activity [name] (if given).
Future<SilentGameAudio> openActivity(
  WidgetTester tester,
  String? name, {
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
  await tester.tap(find.byKey(const Key('activities_button')));
  await tester.pumpAndSettle();
  if (name != null) {
    await tester.tap(find.byKey(Key('activity_$name')));
    await tester.pumpAndSettle();
  }
  return audio;
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Drags a finger along [points] (art space shown in [frame]) on the stage.
Future<void> drag(WidgetTester tester, Rect frame, List<Offset> points) async {
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
  await tester.pumpAndSettle();
}

/// A zig-zag over [r] (art space), like a child scribbling.
List<Offset> scribble(Rect r, {int rows = 5}) => [
  for (var i = 0; i <= rows; i++) ...[
    Offset(r.left, r.top + r.height * i / rows),
    Offset(r.right, r.top + r.height * (i + 0.5) / rows),
  ],
];

/// Saves the current look with the camera and reads it back.
Future<Outfit> saveAndReadLook(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('camera_button')));
  await tester.pumpAndSettle();
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(LooksStorage.storageKey)!;
  return Outfit.fromJson(jsonDecode(saved.first) as Map<String, dynamic>);
}
