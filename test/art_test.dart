import 'dart:io';
import 'dart:ui' as ui;

import 'package:dress_up_star/art/art_library.dart';
import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/painting/confetti_painter.dart';
import 'package:dress_up_star/painting/sparkle_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses an SVG the same way the game does (recolored, with a pattern).
Future<void> parse(
  String path, {
  Color? color,
  ItemPattern pattern = ItemPattern.none,
  Slot? slot,
}) async {
  final svg = prepareSvg(
    File(path).readAsStringSync(),
    color: color,
    pattern: pattern,
    slot: slot,
  );
  final info = await vg.loadPicture(SvgStringLoader(svg), null);
  info.picture.dispose();
}

void paintOnce(CustomPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  test('every item has its SVG art', () {
    for (final item in gameItems) {
      expect(File(itemAsset(item.shape)).existsSync(), isTrue, reason: item.id);
    }
    for (final name in [
      'body',
      'arm_left',
      'arm_right',
      'head',
      'face_open',
      'face_blink',
      'face_happy',
    ]) {
      expect(File('$kDollDir$name.svg').existsSync(), isTrue, reason: name);
    }
    for (final name in ['cloud', 'sparkle', 'wave']) {
      expect(File('$kSceneDir$name.svg').existsSync(), isTrue, reason: name);
    }
  });

  test('recoloring replaces every placeholder color', () {
    for (final file in Directory(kItemDir).listSync().whereType<File>()) {
      final svg = prepareSvg(
        file.readAsStringSync(),
        color: const Color(0xFF7CB8FF),
      );
      expect(
        RegExp(
          '#(FF00FF|FF66FF|FFCCFF|CC00CC|990099)',
          caseSensitive: false,
        ).hasMatch(svg),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('clothes with a pattern spot also define the fabric outline', () {
    for (final file in Directory(kItemDir).listSync().whereType<File>()) {
      final svg = file.readAsStringSync();
      if (svg.contains('<g id="pattern"/>')) {
        expect(
          svg.contains('<clipPath id="fabric">'),
          isTrue,
          reason: file.path,
        );
      }
    }
  });

  test('patterns follow the garment and use the contrast color', () {
    final markup = patternMarkup(
      ItemPattern.dots,
      const Color(0xFF123456),
      Slot.dress,
    );
    expect(markup, contains('clip-path="url(#fabric)"'));
    expect(markup, contains('#123456'));
    for (final p in ItemPattern.values.where((p) => p != ItemPattern.none)) {
      expect(
        patternMarkup(p, Colors.white, Slot.skirt).length,
        greaterThan(100),
        reason: p.name,
      );
    }
  });

  testWidgets('every SVG parses in every color and pattern', (tester) async {
    await tester.runAsync(() async {
      for (final file in Directory(
        'assets/svg',
      ).listSync(recursive: true).whereType<File>()) {
        await parse(file.path);
      }
      for (final item in gameItems) {
        final category = gameCategories.firstWhere(
          (c) => c.slots.contains(item.slot),
        );
        for (final color in category.colors) {
          for (final suffix in ['', '_back', '_front']) {
            final path = itemAsset(item.shape, suffix);
            if (!File(path).existsSync()) continue;
            for (final pattern in ItemPattern.values) {
              await parse(
                path,
                color: color,
                pattern: pattern,
                slot: item.slot,
              );
            }
          }
        }
      }
    });
  });

  test('the doll is layered in the right order', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final outfit = Outfit.starter()
        .wear(findItem('top_tshirt')!)
        .wear(findItem('skirt_tutu')!)
        .wear(findItem('head_crown')!);
    final recipe = await dollRecipe(outfit);
    final under = recipe.under.map((l) => l.asset.split('/').last).toList();
    expect(under.indexOf('body.svg'), lessThan(under.indexOf('topTshirt.svg')));
    expect(
      under.indexOf('topTshirt.svg'),
      lessThan(under.indexOf('arm_left.svg')),
    );
    expect(
      under.indexOf('arm_left.svg'),
      lessThan(under.indexOf('topTshirt_front.svg')),
    );
    expect(under.last, 'head.svg');
    expect(recipe.over.map((l) => l.asset.split('/').last), [
      'hairLong.svg',
      // Her eyebrows show over the fringe.
      'drawn:brows|0|1',
      'headCrown.svg',
    ]);

    final waving = await dollRecipe(outfit, separateRightArm: true);
    expect(waving.rightArm.single.asset, endsWith('arm_right.svg'));
    expect(waving.under.any((l) => l.asset.endsWith('arm_right.svg')), isFalse);
  });

  test('sparkles and confetti draw through the whole animation', () {
    for (var t = 0.0; t <= 1.0; t += 0.05) {
      paintOnce(
        SparklePainter(progress: t, center: const Offset(50, 50), seed: 3),
        const Size(100, 100),
      );
      paintOnce(
        ConfettiPainter(progress: t, origin: const Offset(200, 300), seed: 4),
        const Size(400, 700),
      );
    }
  });
}
