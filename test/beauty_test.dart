import 'dart:math';
import 'dart:ui' as ui;

import 'package:dress_up_star/art/beauty_art.dart';
import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('spot grid', () {
    test('empty grids are all the same, trailing spots are dropped', () {
      expect(SpotGrid('....'), SpotGrid.none);
      expect(SpotGrid('a.b..').cells, 'a.b');
      expect(SpotGrid.none.isEmpty, isTrue);
    });

    test('set paints and clears spots', () {
      final g = SpotGrid.none.set([2, 4], 1);
      expect(g[2], 1);
      expect(g[4], 1);
      expect(g[0], isNull);
      expect(g[99], isNull);
      expect(g.set([2, 4], 1), same(g));
      expect(g.set([2, 4], null), SpotGrid.none);
      expect(g.countPainted([0, 1, 2, 3, 4]), 2);
      expect(g.set([1], 3).mainColor([1, 2, 4]), 1);
    });

    test('broken saved grids are ignored', () {
      expect(SpotGrid.read('ab', 5), SpotGrid('ab'));
      expect(SpotGrid.read('abcdef', 5), SpotGrid.none); // too long
      expect(SpotGrid.read('a!', 5), SpotGrid.none); // bad letter
      expect(SpotGrid.read('az', 5, maxColor: 3), SpotGrid.none);
      expect(SpotGrid.read(42, 5), SpotGrid.none);
    });
  });

  group('zones', () {
    test('a tool only paints the spots it touches', () {
      final hit = lipsZone.touched(kMouth, kMouth, 4.5);
      expect(hit, isNotEmpty);
      expect(hit.length, lessThan(lipsZone.length));
      // The forehead is far from the lips.
      expect(
        lipsZone.touched(const Offset(100, 70), const Offset(100, 70), 4.5),
        isEmpty,
      );
      // Blush on the left cheek does not reach the right cheek.
      final left = blushZone.touched(kLeftCheek, kLeftCheek, 7);
      expect(left.every((i) => blushZone.regionOf[i] == 0), isTrue);
    });

    test('a fast swipe still paints the whole way', () {
      final hit = shadowZone.touched(
        const Offset(62, 106),
        const Offset(138, 106),
        5,
      );
      expect(hit.any((i) => shadowZone.regionOf[i] == 0), isTrue);
      expect(hit.any((i) => shadowZone.regionOf[i] == 1), isTrue);
    });

    test('a nearly painted region is finished neatly', () {
      final cells = blushZone.regions[0];
      final most = cells.take((cells.length * 0.7).ceil());
      final (done, finished) = blushZone.complete(
        SpotGrid.none.set(most, 2),
        2,
      );
      expect(finished, [0]);
      expect(done.countPainted(cells), cells.length);
      expect(done.countPainted(blushZone.regions[1]), 0);

      final (same, none) = blushZone.complete(
        SpotGrid.none.set(cells.take(2), 2),
        2,
      );
      expect(none, isEmpty);
      expect(same.countPainted(cells), 2);
    });
  });

  group('makeup', () {
    final full = Makeup(
      lips: SpotGrid.filled(lipsZone.length, 1),
      blush: SpotGrid.filled(blushZone.length, 0),
      shadow: SpotGrid.filled(shadowZone.length, 5),
      lashLeft: 2,
      lashRight: 3,
      stickers: const [FaceSticker(StickerKind.heart, Offset(70, 128))],
    );

    test('json round trip and empty makeup is not saved', () {
      expect(Makeup.fromJson(full.toJson()), full);
      expect(Makeup.none.toJson(), isEmpty);
      final o = Outfit.starter().copyWith(makeup: full);
      expect(Outfit.fromJson(o.toJson()), o);
      expect(Outfit.starter().toJson().containsKey('makeup'), isFalse);
    });

    test('broken makeup json is skipped', () {
      final m = Makeup.fromJson({
        'lips': 'zzz',
        'lashes': [9, 'x'],
        'stickers': [
          [7, 1, 1],
          'nonsense',
          [0, 500, -40],
        ],
      });
      expect(m.lips, SpotGrid.none);
      expect(m.lashLeft, lashStyleCount);
      expect(m.lashRight, 0);
      expect(m.stickers.single.kind, StickerKind.star);
      expect(
        m.stickers.single.position,
        const Offset(144, 92),
      ); // kept on the face
      expect(Makeup.fromJson('nope'), Makeup.none);
    });

    test('only a few stickers are kept', () {
      var m = Makeup.none;
      for (var i = 0; i < maxFaceStickers + 3; i++) {
        m = m.addSticker(FaceSticker(StickerKind.star, Offset(60.0 + i, 120)));
      }
      expect(m.stickers.length, maxFaceStickers);
      expect(m.stickers.last.position.dx, 60.0 + maxFaceStickers + 2);
    });

    test('changing clothes keeps the makeup', () {
      final o = Outfit.starter()
          .copyWith(makeup: full)
          .wear(findItem('dress_princess')!)
          .recolor(Slot.hair, const Color(0xFFFF8FC7))
          .remove(Slot.dress);
      expect(o.makeup, full);
      expect(o, isNot(Outfit.starter()));
    });

    test('surprise me sometimes puts on makeup', () {
      final rnd = Random(3);
      final looks = [for (var i = 0; i < 60; i++) Outfit.random(rnd)];
      expect(looks.where((o) => !o.makeup.isEmpty), isNotEmpty);
      expect(looks.where((o) => o.makeup.isEmpty), isNotEmpty);
      for (final o in looks) {
        expect(Outfit.fromJson(o.toJson()), o);
      }
    });

    test('makeup is part of the doll picture and its cache key', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final o = Outfit.starter().copyWith(makeup: full);
      expect(outfitKey(o), isNot(outfitKey(Outfit.starter())));
      final recipe = await dollRecipe(o);
      final face = recipe.face(Face.open).map((l) => l.asset).toList();
      expect(face.first, startsWith('drawn:makeup_under'));
      expect(face[1], endsWith('face_open.svg'));
      expect(face.last, startsWith('drawn:makeup_over'));
      expect(
        (await dollRecipe(Outfit.starter())).face(Face.open),
        hasLength(1),
      );
    });

    test('makeup draws for every face without errors', () {
      for (final face in Face.values) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        paintMakeupUnder(canvas, full);
        paintMakeupOver(canvas, full, face);
        recorder.endRecording().dispose();
      }
    });
  });
}
