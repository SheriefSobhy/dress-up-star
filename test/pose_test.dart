import 'dart:convert';

import 'package:dress_up_star/art/doll_pose.dart';
import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/services/game_audio.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:dress_up_star/widgets/doll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SilentGameAudio> _start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
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

DollView _doll(WidgetTester tester) =>
    tester.widget<DollView>(find.byType(DollView));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// The newest saved look.
Future<Outfit> _savedLook() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(LooksStorage.storageKey)!;
  return Outfit.fromJson(jsonDecode(saved.first) as Map<String, dynamic>);
}

void main() {
  GameMotion.idleAnimations = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('pose model', () {
    test('a pose is saved and read back with the look', () {
      for (final pose in DollPose.values) {
        final look = Outfit.starter().copyWith(pose: pose);
        final back = Outfit.fromJson(
          jsonDecode(jsonEncode(look.toJson())) as Map<String, dynamic>,
        );
        expect(back.pose, pose);
        expect(back, look);
      }
      // Standing is the default and is not written down.
      expect(Outfit.starter().toJson().containsKey('pose'), isFalse);
      // Old looks and unknown poses just stand.
      expect(Outfit.fromJson({'pose': 'backflip'}).pose, DollPose.stand);
      expect(Outfit.fromJson({}).pose, DollPose.stand);
    });

    test('changing clothes keeps the pose', () {
      final posed = Outfit.starter().copyWith(pose: DollPose.curtsy);
      expect(posed.wear(findItem('dress_tutu')!).pose, DollPose.curtsy);
      expect(posed.recolor(Slot.hair, hairColors[2]).pose, DollPose.curtsy);
      expect(posed, isNot(Outfit.starter()));
    });

    test('the Pose button order has every pose but standing', () {
      expect(poseButtonOrder.toSet(), {
        for (final p in DollPose.values)
          if (p != DollPose.stand) p,
      });
      expect(poseButtonOrder, hasLength(DollPose.values.length - 1));
    });

    test('every pose can be reached and every move ends in it', () {
      for (final pose in DollPose.values) {
        final held = heldPoseFrame(pose);
        for (final right in [false, true]) {
          final target = right ? held.rightHand : held.leftHand;
          final arm = ArmBones.reach(right: right, target: target);
          expect((arm.hand - target).distance, lessThan(0.5), reason: '$pose');
        }
        final keys = poseMove(pose, PoseFrame.rest);
        expect(keys.first.frame.isRest, isTrue);
        expect(keys.last.frame.leftHand, held.leftHand);
        expect(keys.last.frame.rightHand, held.rightHand);
        expect(poseMoveSeconds(pose), inInclusiveRange(0.4, 2.0));
        // Smooth: no big jumps between frames.
        var last = samplePoseKeys(keys, 0);
        for (var t = 0.0; t <= keys.last.time; t += 1 / 60) {
          final f = samplePoseKeys(keys, t);
          expect((f.rightHand - last.rightHand).distance, lessThan(16));
          expect((f.lift - last.lift).abs(), lessThan(6));
          last = f;
        }
      }
    });

    test('the dance is smooth, keeps the beat and loops', () {
      var last = danceFrame(0);
      for (var t = 0.0; t < 10; t += 1 / 60) {
        final f = danceFrame(t);
        expect((f.leftHand - last.leftHand).distance, lessThan(10));
        expect((f.rightHand - last.rightHand).distance, lessThan(10));
        expect(f.spin.abs(), lessThanOrEqualTo(1));
        last = f;
      }
      // 16 beats later it starts again.
      final loop = 16 * 60 / danceBpm;
      final a = danceFrame(1.1), b = danceFrame(1.1 + loop);
      expect((a.rightHand - b.rightHand).distance, lessThan(0.01));
      // It starts where she was standing.
      final move = danceMove(heldPoseFrame(DollPose.hips), PoseFrame.rest, 99);
      expect(move(0).leftHand, heldPoseFrame(DollPose.hips).leftHand);
    });
  });

  group('screen', () {
    testWidgets('each tap on Pose does the next pose', (tester) async {
      await _start(tester);
      expect(_doll(tester).outfit.pose, DollPose.stand);
      for (final pose in [...poseButtonOrder, poseButtonOrder.first]) {
        await _tap(tester, 'pose_button');
        expect(_doll(tester).outfit.pose, pose);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the pose is saved with the look and comes back', (
      tester,
    ) async {
      await _start(tester);
      await _tap(tester, 'pose_button'); // wave
      await _tap(tester, 'pose_button'); // twirl
      await _tap(tester, 'camera_button');
      expect((await _savedLook()).pose, DollPose.twirl);

      // Change pose, then wear the saved look again from the gallery.
      await _tap(tester, 'pose_button');
      expect(_doll(tester).outfit.pose, DollPose.peace);
      await _tap(tester, 'gallery_button');
      await _tap(tester, 'look_0');
      expect(_doll(tester).outfit.pose, DollPose.twirl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dance: she dances for a while, then stops by herself', (
      tester,
    ) async {
      final audio = await _start(tester);
      await tester.tap(find.byKey(const Key('dance_button')));
      await tester.pump();
      expect(_doll(tester).dancing, isTrue);
      expect(_doll(tester).happy, isTrue);
      expect(audio.played, contains(Sfx.sparkle));
      await tester.pump(danceTime ~/ 2);
      expect(_doll(tester).dancing, isTrue);
      await tester.pumpAndSettle();
      expect(_doll(tester).dancing, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dance again or Pose stops the dance', (tester) async {
      await _start(tester);
      await tester.tap(find.byKey(const Key('dance_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('dance_button')));
      await tester.pump();
      expect(_doll(tester).dancing, isFalse);

      await tester.tap(find.byKey(const Key('dance_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('pose_button')));
      await tester.pump();
      expect(_doll(tester).dancing, isFalse);
      expect(_doll(tester).outfit.pose, poseButtonOrder.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
