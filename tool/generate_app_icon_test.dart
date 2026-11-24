// Draws the Android app icon and splash picture from the doll's face.
//
//   flutter test tool/generate_app_icon_test.dart
//
// Writes the launcher icons (all densities, plus the adaptive icon
// foreground), the splash picture and a 512px Play Store icon into
// android/app/src/main/. Run it again after changing the doll's face.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/widgets/doll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const res = 'android/app/src/main/res';

/// Pastel colors of the icon (the background is also in colors.xml).
const iconBackground = Color(0xFFFFD6EA);
const iconBackgroundLight = Color(0xFFFFF0F7);

/// The part of doll space shown on the icon: her face and hair.
const faceSquare = Rect.fromLTRB(20, 30, 180, 190);

const densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

void main() {
  GameMotion.idleAnimations = false;

  testWidgets('generate Android icons', (tester) async {
    final face = await renderFace(tester);

    for (final entry in densities.entries) {
      final dir = '$res/mipmap-${entry.key}';
      final d = entry.value;
      // Classic icons (older phones): a round pastel badge.
      await save(
        tester,
        legacyIcon(face, 48 * d, round: false),
        '$dir/ic_launcher.png',
      );
      await save(
        tester,
        legacyIcon(face, 48 * d, round: true),
        '$dir/ic_launcher_round.png',
      );
      // Adaptive icon foreground: 108dp, face inside the 66dp safe circle.
      await save(
        tester,
        foreground(face, 108 * d),
        '$dir/ic_launcher_foreground.png',
      );
      // Splash picture for phones older than Android 12.
      await save(
        tester,
        foreground(face, 160 * d),
        '${dir.replaceFirst('mipmap', 'drawable')}/splash_doll.png',
      );
    }
    await save(
      tester,
      legacyIcon(face, 512, round: false, playStore: true),
      'android/app/src/main/ic_launcher-playstore.png',
    );
  });
}

/// Renders the happy doll big and cuts out the square around her face.
Future<ui.Image> renderFace(WidgetTester tester) async {
  const scale = 8.0;
  final hair = findItem('hair_long')!;
  final size = kDollFrame.size * scale;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        child: SizedBox.fromSize(
          size: size,
          child: DollView(
            outfit: Outfit({hair.slot: WornItem(hair, hair.color)}),
            happy: true,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final full = (await tester.runAsync(() => boundary.toImage()))!;
  final src = FitTransform(kDollFrame, size).applyRect(faceSquare);
  return (await tester.runAsync(() async {
    final side = src.width.round();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      full,
      src,
      Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    return recorder.endRecording().toImage(side, side);
  }))!;
}

typedef Painting = (int, void Function(Canvas, double));

/// Pastel background with the face and a little star.
Painting legacyIcon(
  ui.Image face,
  double px, {
  required bool round,
  bool playStore = false,
}) {
  final side = px.round();
  return (
    side,
    (canvas, s) {
      final rect = Offset.zero & Size(s, s);
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          rect.center.translate(0, -s * 0.15),
          s * 0.75,
          [iconBackgroundLight, iconBackground],
        );
      if (playStore) {
        canvas.drawRect(rect, paint); // Google Play rounds the corners.
      } else if (round) {
        canvas.drawCircle(rect.center, s * 0.46, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(s * 0.04),
            Radius.circular(s * 0.2),
          ),
          paint,
        );
      }
      final faceSize = s * (playStore ? 0.74 : 0.7);
      drawFace(canvas, face, rect.center, faceSize);
    },
  );
}

/// The adaptive icon foreground (transparent, face in the middle).
Painting foreground(ui.Image face, double px) {
  final side = px.round();
  return (
    side,
    (canvas, s) {
      // The safe zone is a 66dp circle of the 108dp icon; the face
      // (with its star) fits in it.
      drawFace(canvas, face, Offset(s / 2, s / 2), s * 0.52);
    },
  );
}

/// Draws the face as a round portrait (white ring) with a little star.
void drawFace(Canvas canvas, ui.Image face, Offset center, double size) {
  final dst = Rect.fromCenter(center: center, width: size, height: size);
  canvas.drawCircle(center, size / 2, Paint()..color = iconBackgroundLight);
  canvas.save();
  canvas.clipPath(Path()..addOval(dst));
  canvas.drawImageRect(
    face,
    Offset.zero & Size(face.width.toDouble(), face.height.toDouble()),
    dst,
    Paint()..filterQuality = FilterQuality.high,
  );
  canvas.restore();
  canvas.drawCircle(
    center,
    size / 2,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.035,
  );
  // A little gold star on the ring.
  final starCenter = center + Offset(size * 0.32, -size * 0.32);
  final starPath = star(starCenter, size * 0.13);
  canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFC93C));
  canvas.drawPath(
    starPath,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.022
      ..strokeJoin = StrokeJoin.round,
  );
}

Path star(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * 0.48;
    final a = -math.pi / 2 + i * math.pi / 5;
    final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

Future<void> save(WidgetTester tester, Painting painting, String path) async {
  final (side, draw) = painting;
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder), side.toDouble());
    final image = await recorder.endRecording().toImage(side, side);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}
