import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'art_library.dart';
import 'doll_pose.dart';
import 'doll_parts.dart';

/// The 2.5D look: soft shading added over the flat art, the same way for
/// every layer, so every item (new ones too) gets it by itself.
///
/// The light comes from the upper left. These use off-screen layers and
/// blurs, so they are meant for building pictures once (when the outfit
/// changes), never for every animation frame.

/// The part of doll space shading may draw in.
const Rect kDepthBounds = Rect.fromLTRB(-10, -10, 210, 410);

/// True for the SVG art that is shaded. Faces and what is painted on her
/// (makeup, polish) stay flat.
bool hasDepth(ArtLayer layer) =>
    layer.draw == null && !layer.asset.contains('/face_');

/// A soft band of [color] along the edges of what [draw] draws: where a copy
/// moved by [shift] no longer covers it.
void _edgeBand(
  Canvas canvas,
  Rect bounds,
  void Function() draw, {
  required Offset shift,
  required double blur,
  required Color color,
}) {
  canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.srcATop);
  canvas.drawRect(bounds, Paint()..color = color);
  canvas.saveLayer(
    bounds,
    Paint()
      ..blendMode = BlendMode.dstOut
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
        tileMode: TileMode.decal,
      ),
  );
  canvas.translate(shift.dx, shift.dy);
  draw();
  canvas.restore();
  canvas.restore();
}

/// Draws one layer (an item, her head...) rounded: a shadow side, a soft
/// rim light and a highlight, all kept inside its own shape.
void paintRounded(
  Canvas canvas,
  void Function() draw, {
  Rect bounds = kDepthBounds,
}) {
  canvas.saveLayer(bounds, Paint());
  draw();
  // The side away from the light.
  _edgeBand(
    canvas,
    bounds,
    draw,
    shift: const Offset(-4.5, -3.5),
    blur: 2.6,
    color: const Color(0x4D5A2368),
  );
  // A wide soft highlight on the lit side...
  _edgeBand(
    canvas,
    bounds,
    draw,
    shift: const Offset(6, 6),
    blur: 4,
    color: const Color(0x40FFFFFF),
  );
  // ...and a thin bright rim.
  _edgeBand(
    canvas,
    bounds,
    draw,
    shift: const Offset(1.8, 2),
    blur: 0.8,
    color: const Color(0x60FFFFFF),
  );
  canvas.restore();
}

/// The shadow that [occluder] (something in front) casts on what is already
/// in this layer.
void paintOcclusion(
  Canvas canvas,
  void Function() occluder, {
  required Offset offset,
  double blur = 3,
  double opacity = 0.28,
  Rect bounds = kDepthBounds,
}) {
  canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.srcATop);
  canvas.saveLayer(
    bounds,
    Paint()
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
        tileMode: TileMode.decal,
      ),
  );
  canvas.saveLayer(
    bounds,
    Paint()
      ..colorFilter = ColorFilter.mode(
        const Color(0xFF5A2350).withValues(alpha: opacity),
        BlendMode.srcIn,
      ),
  );
  canvas.translate(offset.dx, offset.dy);
  occluder();
  canvas.restore();
  canvas.restore();
  canvas.restore();
}

/// Draws part [index] of [doll] rounded, with the shadows the parts in
/// front of it cast: under her hair, her arms and her skirt.
///
/// [pictures] holds the drawings of every part's layers.
void paintPartWithDepth(
  Canvas canvas,
  DollParts doll,
  List<List<ui.Picture>> pictures,
  int index,
) {
  final part = doll.parts[index];
  // Nothing outside the part's own area is kept, so nothing else is shaded.
  final bounds = part.rect.intersect(kDepthBounds);
  canvas.save();
  canvas.clipRect(bounds);
  canvas.saveLayer(bounds, Paint());
  for (var i = 0; i < pictures[index].length; i++) {
    void draw() => canvas.drawPicture(pictures[index][i]);
    // Drawn hair and sleeve halves are shaded too; nail polish is not.
    part.layers[i].asset.startsWith('drawn:nails') ||
            part.layers[i].asset.startsWith('drawn:brows')
        ? draw()
        : paintRounded(canvas, draw, bounds: bounds);
  }

  final face = doll.parts.indexWhere((p) => p.kind == PartKind.face);
  // Behind her body: her body and head shade these too.
  final body = doll.parts.indexWhere(
    (p) => p.layers.any((l) => l.asset.endsWith('/body.svg')),
  );
  void occlude(
    bool Function(int i, DollPart p) test, {
    required Offset offset,
    double blur = 3,
    double opacity = 0.28,
  }) {
    final front = [
      for (var i = index + 1; i < doll.parts.length; i++)
        if (test(i, doll.parts[i])) ...pictures[i],
    ];
    if (front.isEmpty) return;
    paintOcclusion(
      canvas,
      () => front.forEach(canvas.drawPicture),
      offset: offset,
      blur: blur,
      opacity: opacity,
      bounds: bounds,
    );
  }

  // Under the front hair.
  occlude(
    (i, p) => p.kind == PartKind.hair && i > face,
    offset: const Offset(2, 5),
    opacity: 0.3,
  );
  // Under the skirt (on her legs).
  occlude(
    (i, p) => p.kind == PartKind.skirt,
    offset: const Offset(0, 6),
    blur: 3.5,
    opacity: 0.32,
  );
  // Beside her arms. Kept soft: it stays when an arm lifts.
  occlude(
    (i, p) => p.kind == PartKind.leftArm,
    offset: const Offset(3, 2),
    opacity: 0.2,
  );
  occlude(
    (i, p) => p.kind == PartKind.rightArm,
    offset: const Offset(-3, 2),
    opacity: 0.2,
  );
  if (index < body) {
    occlude(
      (i, p) => i == body || p.layers.any((l) => l.asset.endsWith('/head.svg')),
      offset: const Offset(3, 4),
      blur: 5,
      opacity: 0.34,
    );
  }
  canvas.restore();
  canvas.restore();
}

// ------------------------------------------------------------ ground shadow

final Paint _groundPaint = Paint()
  ..shader = ui.Gradient.radial(
    Offset.zero,
    1,
    const [Color(0x735A2D5A), Color(0x4D5A2D5A), Color(0x005A2D5A)],
    const [0, 0.55, 1],
  );

/// The soft shadow on the floor under her (doll space). It follows her as
/// she leans and turns, and gets smaller and paler while she is [lift] up
/// in the air. [drop] moves it back down when the whole picture is raised.
void paintGroundShadow(
  Canvas canvas, {
  required PoseFrame pose,
  double lift = 0,
  double drop = 0,
  double turn = 0,
}) {
  final up = ((pose.lift + lift) / 40).clamp(0.0, 1.0);
  final hips = pose.bodyPoint(const Offset(100, 250));
  final size = 1 - up * 0.4;
  final width =
      66 * size * (0.8 + 0.2 * pose.spin.abs()) * (1 - turn.abs() * .1);
  canvas.save();
  canvas.translate(100 + (hips.dx - 100) * 0.6 - turn * 4, 363 + drop);
  canvas.scale(width, 11 * size);
  canvas.drawCircle(Offset.zero, 1, _groundPaint);
  canvas.restore();
}
