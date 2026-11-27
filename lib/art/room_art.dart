import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/room_config.dart';
import '../models/outfit.dart';
import '../models/room.dart';
import '../painting/shapes.dart';
import 'doll_art.dart';

/// Drawing a doll's bedroom: the same code draws the live room and the
/// photos of it in "My Looks".

/// Item pictures are drawn at this many logical pixels per room unit and
/// then only scaled, so dragging and pinching never redraws them.
const double roomArtScale = 1.4;

/// Finished item pictures.
final ImageCache2 roomImages = ImageCache2(90);

/// Multiplied over furniture and the doll at night.
const Color roomNightTint = Color(0xFF9C95CC);
const ColorFilter roomNightFilter = ColorFilter.mode(
  roomNightTint,
  BlendMode.modulate,
);

/// [item]'s drawing with its 2.5D shading, [pixels] big.
Future<ui.Image> rasterizeRoomItem(RoomItem item, Size pixels) async {
  final picture = await ArtLibrary.instance.picture(
    item.petArt == null
        ? ArtLayer(item.asset)
        : ArtLayer(
            item.asset,
            color: item.petColor,
            // Only the pet: without the hand that holds it.
            edit: (svg) => svg
                .split('\n')
                .where((line) => !line.contains('#FFDCC8'))
                .join('\n'),
            variant: 'room',
          ),
  );
  final source = item.petCrop ?? Rect.fromLTWH(0, 0, item.w, item.h);
  final shaded = recordPicture((canvas) {
    canvas.scale(pixels.width / source.width, pixels.height / source.height);
    canvas.translate(-source.left, -source.top);
    paintRounded(
      canvas,
      () => canvas.drawPicture(picture),
      bounds: source.inflate(6),
    );
  });
  final image = await shaded.toImage(
    math.max(1, pixels.width.round()),
    math.max(1, pixels.height.round()),
  );
  shaded.dispose();
  return image;
}

// --------------------------------------------------------------- backdrop

/// The wall (with its wallpaper) and the floor.
void paintRoomBackdrop(
  Canvas canvas,
  Size size, {
  required String wallpaper,
  required String floor,
  bool night = false,
}) {
  final unit = size.width / roomUnits;
  final height = size.height / unit;
  final wall = Rect.fromLTWH(0, 0, roomUnits, height * roomWallPart);
  final ground = Rect.fromLTRB(0, wall.bottom, roomUnits, height);
  canvas.save();
  canvas.scale(unit);

  canvas.save();
  canvas.clipRect(wall);
  paintWallpaper(canvas, findRoomItem(wallpaper)!, wall);
  // Soft light from the upper left.
  canvas.drawRect(
    wall,
    Paint()
      ..shader = ui.Gradient.linear(
        wall.topLeft,
        wall.bottomRight,
        const [Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x24582A68)],
        const [0, 0.45, 1],
      ),
  );
  canvas.restore();

  canvas.save();
  canvas.clipRect(ground);
  paintFloor(canvas, findRoomItem(floor)!, ground);
  canvas.drawRect(
    ground,
    Paint()
      ..shader = ui.Gradient.linear(
        ground.topCenter,
        Offset(ground.center.dx, ground.top + 40),
        const [Color(0x55582A68), Color(0x00582A68)],
      ),
  );
  canvas.restore();

  // The skirting board.
  final board = Rect.fromLTWH(0, wall.bottom - 9, roomUnits, 12);
  canvas.drawRect(board, Paint()..color = const Color(0xFFFFFAF4));
  canvas.drawRect(
    Rect.fromLTWH(0, board.bottom - 3, roomUnits, 3),
    Paint()..color = const Color(0xFFE5D3E0),
  );

  if (night) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, roomUnits, height),
      Paint()..color = const Color(0x80221A58),
    );
  }
  canvas.restore();
}

/// A wallpaper's print over [area] (also its little picture in the bar).
void paintWallpaper(Canvas canvas, RoomItem item, Rect area) {
  final base = item.colors[0];
  final print = item.colors[1];
  final paint = Paint()..color = print;
  canvas.drawRect(area, Paint()..color = base);

  void grid(double step, void Function(Offset at, int n) draw) {
    var row = 0;
    for (var y = area.top + step / 2; y < area.bottom + step; y += step) {
      var n = row;
      for (
        var x = area.left + (row.isOdd ? step : step / 2);
        x < area.right + step;
        x += step
      ) {
        draw(Offset(x, y), n++);
      }
      row++;
    }
  }

  switch (item.id) {
    case 'wall_dots':
      grid(36, (at, _) => canvas.drawCircle(at, 6.5, paint));
    case 'wall_stars':
      grid(46, (at, n) {
        canvas.drawPath(starPath(at, n % 3 == 0 ? 11 : 8), paint);
      });
    case 'wall_stripes':
      for (var x = area.left; x < area.right; x += 40) {
        canvas.drawRect(Rect.fromLTWH(x, area.top, 20, area.height), paint);
        canvas.drawRect(
          Rect.fromLTWH(x + 28, area.top, 3, area.height),
          Paint()..color = const Color(0xFFFFFFFF),
        );
      }
    case 'wall_hearts':
      grid(44, (at, _) => canvas.drawPath(heartPath(at, 18), paint));
    case 'wall_flowers':
      grid(52, (at, _) {
        for (var i = 0; i < 5; i++) {
          final a = i * 2 * math.pi / 5 - math.pi / 2;
          canvas.drawCircle(
            at + Offset(math.cos(a), math.sin(a)) * 7,
            5.5,
            paint,
          );
        }
        canvas.drawCircle(at, 4.5, Paint()..color = const Color(0xFFFFD23D));
      });
    case 'wall_clouds':
      grid(86, (at, n) {
        canvas.drawPath(
          cloudPath(at, n.isEven ? 52 : 38),
          Paint()..color = print.withValues(alpha: 0.92),
        );
      });
    case 'wall_rainbow':
      const arcs = [
        Color(0xFFFF9A9A),
        Color(0xFFFFC27A),
        Color(0xFFFFE680),
        Color(0xFFA6E3A0),
        Color(0xFFA8D2FF),
      ];
      grid(92, (at, _) {
        for (var i = 0; i < arcs.length; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: at, radius: 28 - i * 5),
            math.pi,
            math.pi,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = arcs[i],
          );
        }
      });
    case 'wall_diamonds':
      grid(40, (at, _) {
        canvas.drawPath(
          Path()
            ..moveTo(at.dx, at.dy - 17)
            ..lineTo(at.dx + 13, at.dy)
            ..lineTo(at.dx, at.dy + 17)
            ..lineTo(at.dx - 13, at.dy)
            ..close(),
          paint,
        );
        canvas.drawCircle(at, 3, Paint()..color = const Color(0xFFFFFFFF));
      });
  }
}

/// A floor over [area] (also its little picture in the bar).
void paintFloor(Canvas canvas, RoomItem item, Rect area) {
  final base = item.colors[0];
  final print = item.colors[1];
  canvas.drawRect(area, Paint()..color = base);
  final line = Paint()
    ..color = print
    ..strokeWidth = 2.5;
  switch (item.id) {
    case 'floor_wood':
      var row = 0;
      for (var y = area.top + 6; y < area.bottom; y += 24, row++) {
        canvas.drawLine(Offset(area.left, y), Offset(area.right, y), line);
        for (var x = area.left + (row * 67) % 130; x < area.right; x += 130) {
          canvas.drawLine(Offset(x, y), Offset(x, y + 24), line);
        }
      }
    case 'floor_checker':
      // Squares seen in a little perspective.
      final middle = area.center.dx;
      var top = area.top;
      var row = 0;
      while (top < area.bottom) {
        final h = 18 + row * 5.0;
        double spread(double y) => 1 + (y - area.top) / 260;
        final paint = Paint()..color = print;
        for (var i = -8; i < 8; i++) {
          if ((i + row).isEven) continue;
          canvas.drawPath(
            Path()
              ..moveTo(middle + i * 40 * spread(top), top)
              ..lineTo(middle + (i + 1) * 40 * spread(top), top)
              ..lineTo(middle + (i + 1) * 40 * spread(top + h), top + h)
              ..lineTo(middle + i * 40 * spread(top + h), top + h)
              ..close(),
            paint,
          );
        }
        top += h;
        row++;
      }
    case 'floor_carpet':
      final rnd = math.Random(5);
      for (var i = 0; i < 420; i++) {
        canvas.drawCircle(
          Offset(
            area.left + rnd.nextDouble() * area.width,
            area.top + rnd.nextDouble() * area.height,
          ),
          1.5 + rnd.nextDouble() * 2,
          Paint()..color = print,
        );
      }
  }
}

// --------------------------------------------------- windows, lamps, floor

/// The glass of a window, in the item's own units.
Path windowPane(RoomItem item) {
  final r = item.pane!;
  return switch (item.paneShape) {
    PaneShape.rect => Path()..addRect(r),
    PaneShape.round => Path()..addOval(r),
    PaneShape.arch =>
      Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + r.width / 2)
        ..arcTo(
          Rect.fromLTWH(r.left, r.top, r.width, r.width),
          math.pi,
          math.pi,
          false,
        )
        ..lineTo(r.right, r.bottom)
        ..close(),
  };
}

/// What is outside: a sunny sky, or the moon and stars ([time] makes them
/// twinkle).
void paintWindowSky(
  Canvas canvas,
  RoomItem item, {
  required bool night,
  double time = 0,
}) {
  final r = item.pane!;
  canvas.save();
  canvas.clipPath(windowPane(item));
  canvas.drawRect(
    r,
    Paint()
      ..shader = ui.Gradient.linear(
        r.topCenter,
        r.bottomCenter,
        night
            ? const [Color(0xFF1B1550), Color(0xFF4A3A8A)]
            : const [Color(0xFF8FD0FF), Color(0xFFE4F6FF)],
      ),
  );
  Offset at(double x, double y) =>
      Offset(r.left + r.width * x, r.top + r.height * y);
  if (night) {
    const stars = [
      (0.16, 0.2, 4.5),
      (0.42, 0.12, 3.0),
      (0.3, 0.45, 3.6),
      (0.82, 0.5, 4.0),
      (0.62, 0.32, 2.6),
      (0.14, 0.7, 2.8),
      (0.7, 0.74, 3.2),
    ];
    for (var i = 0; i < stars.length; i++) {
      final (x, y, s) = stars[i];
      final glow = 0.8 + 0.2 * math.sin(time * 3 + i * 1.7);
      canvas.drawPath(
        starPath(at(x, y), s * glow),
        Paint()..color = const Color(0xFFFFF3A0),
      );
    }
    final moon = at(0.7, 0.2);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: 10)),
        Path()..addOval(
          Rect.fromCircle(center: moon + const Offset(5, -3), radius: 9),
        ),
      ),
      Paint()..color = const Color(0xFFFFF3C4),
    );
  } else {
    canvas.drawCircle(
      at(0.74, 0.22),
      10,
      Paint()..color = const Color(0xFFFFD84D),
    );
    canvas.drawPath(
      cloudPath(at(0.28, 0.44), 36),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      at(0.2, 1.12),
      r.width * 0.5,
      Paint()..color = const Color(0xFFA8DE8E),
    );
    canvas.drawCircle(
      at(0.85, 1.18),
      r.width * 0.48,
      Paint()..color = const Color(0xFF8ED07C),
    );
  }
  canvas.restore();
}

/// The soft light of a lit lamp around [center].
void paintLampGlow(Canvas canvas, Offset center, double radius) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..blendMode = BlendMode.screen
      ..shader = ui.Gradient.radial(
        center,
        radius,
        const [Color(0xF2FFE6A0), Color(0x80FFC870), Color(0x00FFC870)],
        const [0, 0.4, 1],
      ),
  );
}

/// Where [placed]'s light is, in a room of [room] pixels.
Offset lampCenter(PlacedThing placed, Size room) {
  final r = placed.rect(room);
  final glow = placed.item.glow!;
  final x = placed.flipped ? 1 - glow.dx : glow.dx;
  return Offset(r.left + r.width * x, r.top + r.height * glow.dy);
}

/// True for things that stand on the floor and cast a soft shadow.
bool hasRoomShadow(RoomItem item) =>
    item.layer == 2 && !item.isDoll && item.id != 'wall_shelf';

/// The soft shadow under a standing thing shown at [rect].
void paintRoomShadow(Canvas canvas, Rect rect) {
  final center = Offset(rect.center.dx, rect.bottom - rect.height * 0.02);
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(rect.width * 0.52, math.max(3, rect.width * 0.09));
  canvas.drawCircle(
    Offset.zero,
    1,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        1,
        const [Color(0x665A2D5A), Color(0x335A2D5A), Color(0x005A2D5A)],
        const [0, 0.6, 1],
      ),
  );
  canvas.restore();
}

// ------------------------------------------------------------------ photo

/// A still picture of [room] with its doll as she is dressed in [doll].
Future<ui.Image> rasterizeRoom(Room room, Outfit doll, Size pixels) async {
  final unit = pixels.width / roomUnits;
  final images = <int, ui.Image>{};
  await Future.wait([
    for (var i = 0; i < room.things.length; i++)
      if (!room.things[i].item.isDoll)
        () async {
          final item = room.things[i].item;
          final size = Size(item.w, item.h) * (unit * room.things[i].scale);
          images[i] = await roomImages.get(
            'photo|${item.id}|${size.width.round()}',
            () => rasterizeRoomItem(item, size),
          );
        }(),
  ]);
  final pose = heldPoseFrame(doll.pose);
  final paintDoll = await posedDollPainter(doll, pose, depth: true);
  final picture = recordPicture((canvas) {
    paintRoomBackdrop(
      canvas,
      pixels,
      wallpaper: room.wallpaper,
      floor: room.floor,
      night: room.night,
    );
    final tint = room.night ? roomNightFilter : null;
    for (final i in room.drawOrder) {
      final placed = room.things[i];
      final item = placed.item;
      final r = placed.rect(pixels);
      if (hasRoomShadow(item)) paintRoomShadow(canvas, r);
      canvas.save();
      if (placed.flipped) {
        canvas.translate(r.center.dx * 2, 0);
        canvas.scale(-1, 1);
      }
      if (item.isDoll) {
        canvas.saveLayer(r.inflate(r.width * 0.2), Paint()..colorFilter = tint);
        final fit = FitTransform(kDollFrame, r.size);
        canvas.translate(r.left + fit.dx, r.top + fit.dy);
        canvas.scale(fit.scale);
        paintGroundShadow(canvas, pose: pose);
        paintDoll(canvas);
        canvas.restore();
      } else {
        if (item.pane != null) {
          canvas.save();
          canvas.translate(r.left, r.top);
          canvas.scale(r.width / item.w);
          paintWindowSky(canvas, item, night: room.night);
          canvas.restore();
        }
        final image = images[i]!;
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          r,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..colorFilter = item.glow == null ? tint : null,
        );
      }
      canvas.restore();
    }
    if (room.night) {
      for (final placed in room.things) {
        if (placed.item.glow == null) continue;
        paintLampGlow(
          canvas,
          lampCenter(placed, pixels),
          105 * unit * placed.scale,
        );
      }
    }
  });
  final image = await picture.toImage(
    math.max(1, pixels.width.round()),
    math.max(1, pixels.height.round()),
  );
  picture.dispose();
  return image;
}
