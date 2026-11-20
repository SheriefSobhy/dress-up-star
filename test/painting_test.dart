import 'dart:ui' as ui;

import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/painting/doll_painter.dart';
import 'package:dress_up_star/painting/sparkle_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void paintOnce(CustomPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  test('every item draws in every color on the doll and as a thumbnail', () {
    for (final item in gameItems) {
      final category = gameCategories.firstWhere(
        (c) => c.slots.contains(item.slot),
      );
      for (final color in category.colors) {
        final outfit = Outfit.starter().wear(item, color: color);
        paintOnce(DollPainter(outfit: outfit), const Size(360, 600));
        paintOnce(
          DollPainter(
            outfit: outfit,
            frame: focusRectFor(item.shape),
            showBackground: false,
          ),
          const Size(84, 84),
        );
      }
    }
  });

  test('every pattern draws on every garment shape', () {
    for (final shape in ItemShape.values) {
      for (final pattern in ItemPattern.values) {
        final item = GameItem(
          id: 'test',
          shape: shape,
          color: const Color(0xFFFF8FC7),
          pattern: pattern,
        );
        paintOnce(
          DollPainter(outfit: Outfit.starter().wear(item)),
          const Size(200, 400),
        );
      }
    }
  });

  test('painting copes with tiny and empty sizes', () {
    paintOnce(DollPainter(outfit: Outfit.starter()), Size.zero);
    paintOnce(DollPainter(outfit: Outfit.starter()), const Size(1, 1));
  });

  test('sparkles draw through the whole animation', () {
    for (var t = 0.0; t <= 1.0; t += 0.1) {
      paintOnce(
        SparklePainter(progress: t, center: const Offset(50, 50), seed: 3),
        const Size(100, 100),
      );
    }
  });
}
