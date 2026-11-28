import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';
import 'art_library.dart';
import 'beauty_art.dart';
import 'body_art.dart';
import 'doll_art.dart';
import 'nails_art.dart';
import 'salon_art.dart';

/// How a part of the doll moves.
enum PartKind {
  /// Moves with her body.
  body,

  /// Swings from the top of her head.
  hair,

  /// Swings and flares from her waist.
  skirt,

  /// Bends at the shoulder and elbow.
  leftArm,
  rightArm,

  /// Where her face goes (it has no layers of its own).
  face,

  /// Held in a hand: moves with that hand.
  leftHeld,
  rightHeld,
}

/// Some layers of the doll that move together.
class DollPart {
  DollPart(
    this.kind,
    this.layers, {
    required this.rect,
    this.bendTop = 0,
    this.shiny = const {},
    this.shineRect,
    this.sleeve,
  });

  final PartKind kind;
  final List<ArtLayer> layers;

  /// The part of doll space this part is drawn in.
  final Rect rect;

  /// Hair and skirts only bend below this height (doll space).
  final double bendTop;

  /// Which of [layers] sparkle.
  final Set<int> shiny;

  /// Where the sparkly layers are (doll space).
  final Rect? shineRect;

  /// The color of a long sleeve (the bent elbow is drawn in it).
  final Color? sleeve;

  bool get isArm => kind == PartKind.leftArm || kind == PartKind.rightArm;
  bool get isHeld => kind == PartKind.leftHeld || kind == PartKind.rightHeld;
  bool get bends => kind == PartKind.hair || kind == PartKind.skirt;
}

/// The doll split into parts that can move on their own, in drawing order.
class DollParts {
  DollParts(
    this.parts, {
    this.makeup = Makeup.none,
    this.body = DollBody.classic,
  });

  final List<DollPart> parts;
  final Makeup makeup;
  final DollBody body;

  /// The face (with its makeup) for [face].
  List<ArtLayer> face(Face face) =>
      makeupFaceLayers(makeup, face, faceLayer(face, body), body.eyeShape);
}

/// Earrings come in pairs: the sparkle area covers both ears.
Rect shineRectFor(ItemShape shape) {
  final r = focusRectFor(shape);
  if (shape.slot != Slot.ears) return r;
  return r.expandToInclude(
    Rect.fromLTRB(200 - r.right, r.top, 200 - r.left, r.bottom),
  );
}

const Rect _leftNails = Rect.fromLTRB(44, 232, 86, 274);
const Rect _rightNails = Rect.fromLTRB(114, 232, 156, 274);

/// True when the nails have glitter polish or gems.
bool sparklyNails(NailSet nails) {
  for (var i = 0; i < nails.polish.cells.length; i++) {
    final c = nails.polish[i];
    if (c != null && c < nailColors.length && nailColors[c].glitter) {
      return true;
    }
  }
  for (var i = 0; i < nails.deco.cells.length; i++) {
    if (nails.deco[i] == NailDeco.gem.index) return true;
  }
  return false;
}

/// Splits [outfit] into moving parts. Drawn in order (with the face where
/// [PartKind.face] is) it looks exactly like [dollRecipe].
Future<DollParts> dollParts(Outfit outfit) async {
  final assets = await ArtLibrary.instance.manifest();

  /// A worn item's layer, and the area it sparkles in (if it does).
  (ArtLayer, Rect?)? item(Slot slot, [String suffix = '']) {
    final worn = outfit[slot];
    if (worn == null) return null;
    final path = itemAsset(worn.item.shape, suffix);
    if (suffix.isNotEmpty && !assets.contains(path)) return null;
    final shiny = suffix.isEmpty && shinyShapes.contains(worn.item.shape);
    return (
      skinnedItem(
        ArtLayer(
          path,
          color: worn.color,
          pattern: worn.item.pattern,
          slot: slot,
        ),
        outfit.body,
      ),
      shiny ? shineRectFor(worn.item.shape) : null,
    );
  }

  (ArtLayer, Rect?) plain(ArtLayer layer) => (layer, null);
  ArtLayer doll(String name) => skinLayer(name, outfit.body);

  /// One half (left or right of her middle) of a layer, for sleeves.
  (ArtLayer, Rect?)? half((ArtLayer, Rect?)? entry, {required bool right}) {
    if (entry == null) return null;
    final layer = entry.$1;
    return (
      ArtLayer.drawn('half|${right ? 'r' : 'l'}|${layer.key}', () async {
        final picture = await ArtLibrary.instance.picture(layer);
        return recordPicture((c) {
          c.clipRect(
            right
                ? const Rect.fromLTRB(100, 0, 200, 400)
                : const Rect.fromLTRB(0, 0, 100, 400),
          );
          c.drawPicture(picture);
        });
      }, slot: layer.slot),
      null,
    );
  }

  final parts = <DollPart>[];
  void add(
    PartKind kind,
    List<(ArtLayer, Rect?)?> entries, {
    Rect rect = kDollFrame,
    double bendTop = 0,
    Color? sleeve,
  }) {
    final list = entries.nonNulls.toList();
    if (list.isEmpty && kind != PartKind.face) return;
    Rect? shineRect;
    final shiny = <int>{};
    for (var i = 0; i < list.length; i++) {
      final r = list[i].$2;
      if (r == null) continue;
      shiny.add(i);
      shineRect = shineRect?.expandToInclude(r) ?? r;
    }
    parts.add(
      DollPart(
        kind,
        [for (final e in list) e.$1],
        rect: rect,
        bendTop: bendTop,
        shiny: shiny,
        shineRect: shineRect?.inflate(3),
        sleeve: sleeve,
      ),
    );
  }

  final hair = outfit[Slot.hair];
  final noHair = hairCovered(outfit);
  final salon = !noHair && hair != null && outfit.hasSalonHair
      ? salonHairLayers(outfit.salon, hair.color)
      : null;
  final hasDress = outfit[Slot.dress] != null;
  final nailsShine = sparklyNails(outfit.nails);
  List<(ArtLayer, Rect?)> nails({required bool right}) => [
    for (final l in dollNailLayers(outfit.nails, right: right))
      (l, nailsShine ? (right ? _rightNails : _leftNails) : null),
  ];
  final sleeves = sleeveSlots(outfit);
  final fronts = [for (final slot in sleeves) item(slot, '_front')];
  // The bent elbow takes the color of the outermost long sleeve.
  Color? longSleeve;
  for (final slot in sleeves) {
    final worn = outfit[slot];
    if (worn != null && longSleeveShapes.contains(worn.item.shape)) {
      longSleeve = worn.color;
    }
  }
  final swimming = outfit[Slot.dress]?.item.shape.isSwimwear ?? false;
  final floaties = outfit[Slot.hand]?.item.shape == ItemShape.handFloaties;
  final coverUp = outfit[Slot.jacket]?.item.shape.isCoverUp ?? false;
  final dress = outfit[Slot.dress];
  final stiff = dress != null && stiffShapes.contains(dress.item.shape);
  final dressKind = stiff ? PartKind.body : PartKind.skirt;
  final pants = outfit[Slot.pants]?.item.shape;
  final overalls = pants == ItemShape.pantsOveralls;
  final covered =
      dress != null && footCoveringShapes.contains(dress.item.shape);
  const hairBend = 104.0;
  const skirtBend = 206.0;
  const armsRect = 140.0;

  // Behind her body (wings first).
  add(PartKind.body, [item(Slot.back)]);
  add(dressKind, [item(Slot.dress, '_back')], bendTop: skirtBend);
  add(PartKind.hair, [
    if (salon != null)
      plain(salon.first)
    else if (!noHair)
      item(Slot.hair, '_back'),
  ], bendTop: hairBend);
  // Her body and clothes.
  add(PartKind.body, [
    plain(doll('body')),
    if (!covered && !swimming) item(Slot.socks),
    // Leggings tuck into her shoes; other pants fall over them.
    if (pants == ItemShape.pantsLeggings) item(Slot.pants),
    if (!covered) item(Slot.shoes),
    if (pants != ItemShape.pantsLeggings && !overalls) item(Slot.pants),
    if (!hasDress) item(Slot.top),
    // Overalls are worn over her top.
    if (overalls) item(Slot.pants),
  ]);
  add(
    dressKind,
    [if (hasDress) item(Slot.dress) else item(Slot.skirt)],
    rect: const Rect.fromLTRB(4, armsRect, 196, 374),
    bendTop: skirtBend,
  );
  // A cover-up swings with the skirt under it.
  add(
    coverUp ? PartKind.skirt : PartKind.body,
    [item(Slot.jacket)],
    rect: coverUp ? const Rect.fromLTRB(4, armsRect, 196, 374) : kDollFrame,
    bendTop: coverUp ? skirtBend : 0,
  );
  add(
    PartKind.leftArm,
    [
      plain(doll('arm_left')),
      ...nails(right: false),
      for (final front in fronts) half(front, right: false),
      if (floaties) half(item(Slot.hand), right: false),
      item(Slot.wrist),
    ],
    rect: const Rect.fromLTRB(4, armsRect, 100, 300),
    sleeve: longSleeve,
  );
  add(
    PartKind.rightArm,
    [
      plain(doll('arm_right')),
      ...nails(right: true),
      for (final front in fronts) half(front, right: true),
      if (floaties) half(item(Slot.hand), right: true),
    ],
    rect: const Rect.fromLTRB(100, armsRect, 196, 300),
    sleeve: longSleeve,
  );
  // Jewelry sits on top of the clothes, under her chin.
  add(PartKind.body, [
    item(Slot.neck),
    plain(doll('head')),
  ], rect: const Rect.fromLTRB(4, 0, 196, 240));
  add(PartKind.face, const []);
  add(PartKind.hair, [
    if (salon != null) plain(salon.last) else if (!noHair) item(Slot.hair),
  ], bendTop: hairBend);
  // A burkini's swim hood sits where front hair would, and never swings.
  const hoodRect = Rect.fromLTRB(20, 30, 180, 194);
  add(
    PartKind.hair,
    [item(Slot.dress, '_hood')],
    rect: hoodRect,
    bendTop: hoodRect.bottom,
  );
  // Earrings peek out in front of the hair.
  add(PartKind.body, [
    plain(browsLayer(outfit.body)),
    item(Slot.ears),
    item(Slot.head),
    item(Slot.hat),
    item(Slot.eyes),
  ], rect: const Rect.fromLTRB(4, 0, 196, 200));
  final held = outfit[Slot.hand];
  if (held != null && !floaties) {
    add(
      held.item.shape == ItemShape.handWand
          ? PartKind.leftHeld
          : PartKind.rightHeld,
      [item(Slot.hand)],
    );
  }
  return DollParts(parts, makeup: outfit.makeup, body: outfit.body);
}

// ---------------------------------------------------------------- drawing

const Color _skin = Color(0xFFFFDCC8);
const Color _skinLine = Color(0xFFDE9F84);

/// The colors of a drawn elbow or finger on one doll.
class _Skin {
  _Skin(DollBody body)
    : fill = skinTint(body, _skin),
      line = skinTint(body, _skinLine);
  final Color fill;
  final Color line;
}

/// Draws the doll in [pose]. The art of each part is drawn by [drawPart]
/// (doll space) and the face by [drawFace]; [drawShine] adds sparkles over
/// a part. Used for the moving doll and for still pictures of looks.
void paintPosedDoll(
  Canvas canvas,
  DollParts doll,
  PoseFrame pose, {
  required void Function(Canvas canvas, int part) drawPart,
  required void Function(Canvas canvas) drawFace,
  void Function(Canvas canvas, int part)? drawShine,
}) {
  canvas.save();
  pose.applyBody(canvas);
  final left = ArmBones.reach(right: false, target: pose.leftHand);
  final right = ArmBones.reach(right: true, target: pose.rightHand);
  final parts = doll.parts;
  // Under a swim cap there is no front hair: lifted arms still pass in
  // front of her face.
  final lastHair = math.max(
    parts.lastIndexWhere((p) => p.kind == PartKind.hair),
    parts.indexWhere((p) => p.kind == PartKind.face),
  );

  void drawArm(int i) {
    final isRight = parts[i].kind == PartKind.rightArm;
    _paintArm(
      canvas,
      _Skin(doll.body),
      isRight ? right : left,
      parts[i],
      isRight ? pose.rightPeace : pose.leftPeace,
      () => drawPart(canvas, i),
      drawShine == null ? null : () => drawShine(canvas, i),
    );
  }

  // Lifted arms are drawn in front of her hair (and face).
  final later = <int>[];
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part.kind == PartKind.face) {
      drawFace(canvas);
    } else if (part.isArm) {
      final bones = part.kind == PartKind.rightArm ? right : left;
      if (bones.raised && i < lastHair) {
        later.add(i);
      } else {
        drawArm(i);
      }
    } else if (part.isHeld) {
      final bones = part.kind == PartKind.rightHeld ? right : left;
      canvas.save();
      canvas.translate(bones.handShift.dx, bones.handShift.dy);
      drawPart(canvas, i);
      drawShine?.call(canvas, i);
      canvas.restore();
    } else {
      drawPart(canvas, i);
      drawShine?.call(canvas, i);
    }
    if (i == lastHair) later.forEach(drawArm);
  }
  canvas.restore();
}

void _paintArm(
  Canvas canvas,
  _Skin skin,
  ArmBones b,
  DollPart part,
  double peace,
  VoidCallback draw,
  VoidCallback? shine,
) {
  if (b.hand == b.restHand && peace <= 0) {
    draw();
    shine?.call();
    return;
  }
  final rest = b.restAngle;
  final a = kArmHalf;
  final s = b.shoulder;

  // A round elbow under the two halves of the arm.
  final bone = Path()
    ..moveTo(s.dx, s.dy)
    ..lineTo(b.elbow.dx, b.elbow.dy)
    ..lineTo(b.hand.dx, b.hand.dy);
  Paint stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawPath(bone, stroke(skin.line, 15));
  canvas.drawPath(bone, stroke(skin.fill, 12));
  final sleeve = part.sleeve;
  if (sleeve != null) {
    final cuff = Offset.fromDirection(b.lowerAngle, a * 0.62) + b.elbow;
    final cloth = Path()
      ..moveTo(s.dx, s.dy)
      ..lineTo(b.elbow.dx, b.elbow.dy)
      ..lineTo(cuff.dx, cuff.dy);
    final shades = Shades(sleeve);
    canvas.drawPath(cloth, stroke(shades.deep, 21));
    canvas.drawPath(cloth, stroke(shades.light, 18));
  }

  void clipAlongArm(double from, double to) {
    canvas.translate(s.dx, s.dy);
    canvas.rotate(rest);
    canvas.clipRect(Rect.fromLTRB(from, -60, to, 60));
    canvas.rotate(-rest);
    canvas.translate(-s.dx, -s.dy);
  }

  // Upper arm: turns around the shoulder.
  canvas.save();
  canvas.translate(s.dx, s.dy);
  canvas.rotate(b.upperAngle - rest);
  canvas.translate(-s.dx, -s.dy);
  clipAlongArm(-90, a);
  draw();
  canvas.restore();

  // Forearm and hand: moved to the elbow and turned.
  final restElbow = b.restElbow;
  canvas.save();
  canvas.translate(b.elbow.dx, b.elbow.dy);
  canvas.rotate(b.lowerAngle - rest);
  canvas.translate(-restElbow.dx, -restElbow.dy);
  if (peace > 0) _paintPeaceFingers(canvas, skin, b, peace);
  canvas.save();
  clipAlongArm(a, 200);
  draw();
  canvas.restore();
  shine?.call();
  canvas.restore();
}

/// Two fingers up, drawn where the hand is in the art (before the hand, so
/// the hand covers where they start).
void _paintPeaceFingers(Canvas canvas, _Skin skin, ArmBones b, double peace) {
  final u = Offset.fromDirection(b.restAngle);
  final n = Offset(-u.dy, u.dx);
  final c = b.restHand;
  final outline = Paint()
    ..color = skin.line
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  final fill = Paint()
    ..color = skin.fill
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.4
    ..strokeCap = StrokeCap.round;
  for (final side in const [-1.0, 1.0]) {
    final from = c + u * 3 + n * (side * 2);
    final to = c + u * (3 + 14 * peace) + n * (side * (2 + 5 * peace));
    canvas.drawLine(from, to, outline);
    canvas.drawLine(from, to, fill);
  }
}

/// A still picture of a posed doll (for saved looks), drawn into [canvas]
/// in doll space.
Future<void Function(Canvas canvas)> posedDollPainter(
  Outfit outfit,
  PoseFrame pose, {
  Face face = Face.open,
  bool depth = false,
}) async {
  final doll = await dollParts(outfit);
  final pictures = await Future.wait([
    for (final part in doll.parts)
      Future.wait(part.layers.map(ArtLibrary.instance.picture)),
  ]);
  final facePictures = await Future.wait(
    doll.face(face).map(ArtLibrary.instance.picture),
  );
  return (canvas) => paintPosedDoll(
    canvas,
    doll,
    pose,
    drawPart: (c, i) => depth
        ? paintPartWithDepth(c, doll, pictures, i)
        : pictures[i].forEach(c.drawPicture),
    drawFace: (c) => facePictures.forEach(c.drawPicture),
  );
}

/// A picture of only the sparkly pixels of [part] (what covers them later
/// in the part is cut away), for the sparkle effect.
Future<ui.Image> rasterizeShineMask(DollPart part, Size pixels) async {
  final pictures = await Future.wait(
    part.layers.map(ArtLibrary.instance.picture),
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fit = FitTransform(part.shineRect!, pixels);
  canvas.translate(fit.dx, fit.dy);
  canvas.scale(fit.scale);
  var started = false;
  for (var i = 0; i < pictures.length; i++) {
    if (part.shiny.contains(i)) {
      canvas.drawPicture(pictures[i]);
      started = true;
    } else if (started) {
      canvas.saveLayer(null, Paint()..blendMode = BlendMode.dstOut);
      canvas.drawPicture(pictures[i]);
      canvas.restore();
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    pixels.width.round().clamp(1, 4096),
    pixels.height.round().clamp(1, 4096),
  );
  picture.dispose();
  return image;
}
