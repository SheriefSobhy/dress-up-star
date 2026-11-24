import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/art/shine.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _pixels = Size(200, 400);

Future<Uint8List> _pixelsOf(void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    _pixels.width.round(),
    _pixels.height.round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

/// How many pixels are clearly different.
int _differentPixels(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    var d = 0;
    for (var c = 0; c < 4; c++) {
      d += (a[i + c] - b[i + c]).abs();
    }
    if (d > 60) n++;
  }
  return n;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('moving parts', () {
    test(
      'standing still, the parts draw exactly like the whole doll',
      () async {
        final looks = [
          Outfit.starter(),
          Outfit.starter()
              .wear(findItem('top_sweater')!)
              .wear(findItem('skirt_long')!)
              .wear(findItem('wrist_charm')!)
              .wear(findItem('hand_wand')!),
          Outfit.starter()
              .wear(findItem('dress_princess')!)
              .wear(findItem('head_crown')!)
              .wear(findItem('eyes_sun_heart')!)
              .wear(findItem('ears_hoop')!)
              .wear(findItem('hand_balloon')!),
          for (var seed = 1; seed <= 6; seed++) Outfit.random(Random(seed)),
        ];
        for (final look in looks) {
          final recipe = await dollRecipe(look);
          final flat = await Future.wait(
            recipe.flat(Face.open).map(ArtLibrary.instance.picture),
          );
          final whole = await _pixelsOf((c) => flat.forEach(c.drawPicture));
          final posed = await posedDollPainter(look, PoseFrame.rest);
          final parts = await _pixelsOf(posed);
          expect(
            _differentPixels(whole, parts),
            lessThan(40),
            reason: outfitKey(look),
          );
        }
      },
    );

    test('hair, skirts, arms and held things are separate parts', () async {
      final look = Outfit.starter()
          .wear(findItem('top_tshirt')!)
          .wear(findItem('skirt_tutu')!)
          .wear(findItem('hand_bag')!)
          .wear(findItem('hand_wand')!);
      final doll = await dollParts(look);
      final kinds = doll.parts.map((p) => p.kind).toList();
      expect(kinds.where((k) => k == PartKind.hair), hasLength(2));
      expect(kinds, contains(PartKind.skirt));
      expect(kinds, containsAll([PartKind.leftArm, PartKind.rightArm]));
      expect(kinds.where((k) => k == PartKind.face), hasLength(1));
      // Only one thing can be held: the wand is in her left hand.
      expect(kinds, contains(PartKind.leftHeld));
      // T-shirt sleeves go with the arms.
      final arm = doll.parts.firstWhere((p) => p.kind == PartKind.rightArm);
      expect(
        arm.layers.any((l) => l.asset.contains('topTshirt_front')),
        isTrue,
      );
    });
  });

  group('arms', () {
    test('a hand reaches where it should, elbow pointing out', () {
      for (final right in [false, true]) {
        final rest = ArmBones.reach(
          right: right,
          target: right ? kRightHandRest : kLeftHandRest,
        );
        expect((rest.elbow - rest.restElbow).distance, lessThan(0.01));
        expect(rest.raised, isFalse);

        final target = right ? const Offset(124, 214) : const Offset(76, 214);
        final hips = ArmBones.reach(right: right, target: target);
        expect((hips.hand - target).distance, lessThan(0.01));
        expect((hips.elbow - hips.shoulder).distance, closeTo(kArmHalf, 0.01));
        expect((hips.hand - hips.elbow).distance, closeTo(kArmHalf, 0.01));
        // Elbow away from her body.
        final out = right ? 1 : -1;
        expect((hips.elbow.dx - 100) * out, greaterThan(40));
        expect(hips.raised, isTrue);
      }
      // Too far away: the arm stretches straight toward it.
      final far = ArmBones.reach(right: true, target: const Offset(300, 177));
      expect((far.hand - far.shoulder).distance, closeTo(2 * kArmHalf, 0.01));
    });

    test('a posed doll draws without errors', () async {
      final look = Outfit.starter()
          .wear(findItem('top_sweater')!)
          .wear(findItem('hand_balloon')!)
          .wear(findItem('wrist_bangle')!);
      const pose = PoseFrame(
        leftHand: Offset(50, 110),
        rightHand: Offset(150, 124),
        rightPeace: 1,
        tilt: 0.05,
        lift: 10,
        spin: -0.5,
        squash: 0.05,
      );
      final posed = await posedDollPainter(look, pose);
      final still = await posedDollPainter(look, PoseFrame.rest);
      final a = await _pixelsOf(posed);
      final b = await _pixelsOf(still);
      expect(_differentPixels(a, b), greaterThan(1000));
    });
  });

  group('swinging hair and skirts', () {
    test('a push makes them swing, then they settle', () {
      final sway = SwayPhysics();
      expect(sway.still, isTrue);
      sway.kick(hair: 0.5, skirt: -0.4, flare: 0.5);
      var biggest = 0.0;
      var t = 0.0;
      while (t < 6 && !(t > 0.1 && sway.still)) {
        sway.step(1 / 60, PoseFrame.rest);
        biggest = max(biggest, sway.hair.abs());
        t += 1 / 60;
      }
      expect(biggest, greaterThan(0.02));
      expect(sway.still, isTrue, reason: 'settles in time');
      expect(t, lessThan(6));
    });

    test('moving the body sideways swings the hair the other way', () {
      final sway = SwayPhysics();
      sway.step(1 / 60, PoseFrame.rest);
      sway.step(1 / 60, PoseFrame.rest);
      // She suddenly leans right.
      for (var i = 1; i <= 6; i++) {
        sway.step(1 / 60, PoseFrame(tilt: 0.02 * i));
      }
      expect(sway.hair, lessThan(0));
    });

    test('twirling and hopping make the skirt flare out', () {
      final sway = SwayPhysics();
      for (var i = 0; i <= 30; i++) {
        sway.step(1 / 60, PoseFrame(spin: cos(i / 30 * pi)));
      }
      expect(sway.flare, greaterThan(0.02));
    });
  });

  group('sparkles', () {
    test(
      'jewelry, crowns and sunglasses sparkle; plain clothes do not',
      () async {
        final look = Outfit.starter()
            .wear(findItem('dress_party')!)
            .wear(findItem('neck_heart')!)
            .wear(findItem('head_crown')!)
            .wear(findItem('eyes_sun_star')!);
        final doll = await dollParts(look);
        final shiny = [
          for (final part in doll.parts)
            for (final i in part.shiny) part.layers[i].asset.split('/').last,
        ];
        expect(
          shiny,
          unorderedEquals([
            'neckHeart.svg',
            'headCrown.svg',
            'eyesSunStar.svg',
          ]),
        );
        for (final part in doll.parts.where((p) => p.shiny.isNotEmpty)) {
          expect(part.shineRect, isNotNull);
        }
        final plain = await dollParts(
          Outfit.starter().wear(findItem('eyes_round')!),
        );
        expect(plain.parts.every((p) => p.shiny.isEmpty), isTrue);
      },
    );

    test('glitter nail polish and nail gems sparkle', () {
      final glitter = nailColors.indexWhere((c) => c.glitter);
      expect(sparklyNails(NailSet.none), isFalse);
      expect(sparklyNails(NailSet(polish: SpotGrid.filled(4, 0))), isFalse);
      expect(
        sparklyNails(NailSet(polish: SpotGrid.filled(4, glitter))),
        isTrue,
      );
      expect(
        sparklyNails(NailSet(deco: SpotGrid.filled(1, NailDeco.gem.index))),
        isTrue,
      );
    });

    test('the sparkle works with the shader and with the fallback', () async {
      final doll = await dollParts(
        Outfit.starter().wear(findItem('neck_crystal')!),
      );
      final part = doll.parts.firstWhere((p) => p.shiny.isNotEmpty);
      for (final fallback in [false, true]) {
        Shine.forceFallback = fallback;
        final shine = (await PartShine.build(part, 2))!;
        expect(shine.usesShader, !fallback);
        if (fallback) expect(shine.glints, isNotEmpty);
        await _pixelsOf((c) => shine.paint(c, 0.7));
        shine.dispose();
      }
      Shine.forceFallback = false;
    });
  });
}
