import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';
import 'art_library.dart';
import 'beauty_art.dart';
import 'body_art.dart';
import 'depth.dart';
import 'doll_parts.dart';
import 'doll_pose.dart';
import 'nails_art.dart';
import 'salon_art.dart';

export 'art_library.dart' show ArtLayer, ArtLibrary, recordPicture;
export 'body_art.dart' show skinTint;
export 'depth.dart';
export 'doll_parts.dart';
export 'doll_pose.dart';

// ---------------------------------------------------------------- geometry

/// The doll is drawn on a 200 x 400 "doll space". This part of it is shown
/// when the whole doll is visible.
const Rect kDollFrame = Rect.fromLTRB(4, 6, 196, 374);

/// The part of doll space covered by the face (eyes and mouth).
const Rect kFaceRect = Rect.fromLTRB(46, 82, 154, 158);

/// Backgrounds are drawn on a 480 x 800 canvas.
const Size kSceneSize = Size(480, 800);

const Offset kFeet = Offset(100, 362);

/// Scales and centers a rectangle of doll space into a widget of [size].
class FitTransform {
  FitTransform(Rect src, Size size)
    : scale = math.min(size.width / src.width, size.height / src.height),
      _src = src,
      _size = size;

  final double scale;
  final Rect _src;
  final Size _size;

  double get dx => (_size.width - _src.width * scale) / 2 - _src.left * scale;
  double get dy => (_size.height - _src.height * scale) / 2 - _src.top * scale;

  Offset apply(Offset p) => Offset(dx + p.dx * scale, dy + p.dy * scale);
  Rect applyRect(Rect r) =>
      Rect.fromPoints(apply(r.topLeft), apply(r.bottomRight));

  /// The point in the source space shown at [p] on screen.
  Offset invert(Offset p) => Offset((p.dx - dx) / scale, (p.dy - dy) / scale);
}

/// The part of doll space that shows an item best (thumbnails, sparkles).
Rect focusRectFor(ItemShape shape) {
  // Shapes that need their own view.
  switch (shape) {
    case ItemShape.costumeMermaid:
      return const Rect.fromLTRB(36, 164, 164, 374);
    case ItemShape.costumeFairy:
      return const Rect.fromLTRB(6, 130, 194, 292);
    case ItemShape.swimFrilly:
    case ItemShape.swimPolka:
    case ItemShape.swimRainbow:
    case ItemShape.swimMermaid:
    case ItemShape.swimSporty:
      return const Rect.fromLTRB(50, 160, 150, 272);
    case ItemShape.swimDressRuffle:
    case ItemShape.swimDressSkater:
    case ItemShape.swimDressPeplum:
      return const Rect.fromLTRB(44, 162, 156, 286);
    case ItemShape.swimRashShorts:
    case ItemShape.swimRashSport:
      return const Rect.fromLTRB(46, 162, 154, 288);
    case ItemShape.swimRashLeggings:
      return const Rect.fromLTRB(46, 160, 154, 352);
    case ItemShape.swimBurkiniWaves:
    case ItemShape.swimBurkiniFlower:
    case ItemShape.swimBurkiniRainbow:
      return const Rect.fromLTRB(24, 36, 176, 352);
    case ItemShape.beachSundress:
    case ItemShape.beachKaftan:
    case ItemShape.beachRobe:
      return const Rect.fromLTRB(48, 160, 152, 308);
    case ItemShape.eyesSwimMask:
      return const Rect.fromLTRB(40, 52, 176, 146);
    case ItemShape.handFloaties:
      return const Rect.fromLTRB(52, 166, 148, 226);
    case ItemShape.handRingDuck:
    case ItemShape.handRingFlamingo:
    case ItemShape.handRingDonut:
      return const Rect.fromLTRB(112, 214, 192, 302);
    case ItemShape.handIceCream:
      return const Rect.fromLTRB(108, 196, 166, 274);
    case ItemShape.pajamaBunny:
      return const Rect.fromLTRB(24, 0, 176, 356);
    case ItemShape.pajamaStars:
    case ItemShape.pajamaCloud:
    case ItemShape.costumeAstronaut:
    case ItemShape.costumeChef:
    case ItemShape.costumeDoctor:
    case ItemShape.sportTracksuit:
      return const Rect.fromLTRB(46, 158, 154, 352);
    case ItemShape.pajamaHearts:
      return const Rect.fromLTRB(46, 160, 154, 322);
    case ItemShape.sportTennis:
    case ItemShape.sportBallet:
    case ItemShape.sportFootball:
      return const Rect.fromLTRB(44, 162, 156, 284);
    case ItemShape.jacketRain:
      return const Rect.fromLTRB(48, 158, 152, 282);
    case ItemShape.pantsShorts:
      return const Rect.fromLTRB(64, 206, 136, 284);
    case ItemShape.pantsOveralls:
      return const Rect.fromLTRB(56, 166, 144, 350);
    case ItemShape.socksRainbow:
    case ItemShape.socksGlitter:
      return const Rect.fromLTRB(58, 228, 142, 370);
    case ItemShape.shoesRoller:
      return const Rect.fromLTRB(64, 306, 136, 372);
    default:
      break;
  }
  switch (shape.slot) {
    case Slot.hair:
      return const Rect.fromLTRB(22, 6, 178, 284);
    case Slot.dress:
      return const Rect.fromLTRB(22, 150, 178, 362);
    case Slot.top:
      return const Rect.fromLTRB(50, 152, 150, 252);
    case Slot.skirt:
      return shape == ItemShape.skirtLong
          ? const Rect.fromLTRB(36, 204, 164, 346)
          : const Rect.fromLTRB(36, 204, 164, 300);
    case Slot.shoes:
      return const Rect.fromLTRB(64, 306, 136, 370);
    case Slot.head:
      return const Rect.fromLTRB(40, 4, 160, 112);
    case Slot.eyes:
      return const Rect.fromLTRB(50, 84, 150, 146);
    case Slot.neck:
      return const Rect.fromLTRB(64, 150, 136, 218);
    case Slot.ears:
      // The left ear, with a bit of her cheek.
      return const Rect.fromLTRB(22, 102, 64, 146);
    case Slot.wrist:
      return const Rect.fromLTRB(44, 220, 88, 264);
    case Slot.hand:
      switch (shape) {
        case ItemShape.handWand:
          return const Rect.fromLTRB(18, 166, 94, 268);
        case ItemShape.handKitten:
        case ItemShape.handPuppy:
          return const Rect.fromLTRB(110, 206, 186, 296);
        case ItemShape.handBalloon:
          return const Rect.fromLTRB(110, 76, 200, 262);
        default:
          return const Rect.fromLTRB(108, 222, 172, 302);
      }
    case Slot.back:
      return const Rect.fromLTRB(4, 110, 196, 300);
    case Slot.jacket:
      return const Rect.fromLTRB(50, 156, 150, 256);
    case Slot.pants:
      return const Rect.fromLTRB(56, 208, 144, 356);
    case Slot.socks:
      return const Rect.fromLTRB(64, 290, 136, 370);
    case Slot.hat:
      return const Rect.fromLTRB(16, 0, 184, 112);
    case Slot.background:
      return kDollFrame;
  }
}

// ----------------------------------------------------------------- assets

const String kDollDir = 'assets/svg/doll/';
const String kItemDir = 'assets/svg/items/';
const String kSceneDir = 'assets/svg/scenes/';

String itemAsset(ItemShape shape, [String suffix = '']) =>
    '$kItemDir${shape.name}$suffix.svg';

enum Face { open, blink, happy }

ArtLayer faceLayer(Face face, [DollBody body = DollBody.classic]) =>
    faceArtLayer(face.name, body);

ArtLayer sceneLayer(WornItem bg) =>
    ArtLayer(itemAsset(bg.item.shape), color: bg.color, slot: Slot.background);

/// True when a swim hood or swim cap hides all her hair.
bool hairCovered(Outfit outfit) => [
  outfit[Slot.dress],
  outfit[Slot.hat],
].any((w) => w != null && hairCoveringShapes.contains(w.item.shape));

/// Whose sleeves to draw, innermost first. A jacket's sleeves cover the
/// sleeves under it; a beach cover-up leaves them on underneath.
List<Slot> sleeveSlots(Outfit outfit) {
  final jacket = outfit[Slot.jacket];
  return [
    if (jacket == null || jacket.item.shape.isCoverUp)
      outfit[Slot.dress] != null ? Slot.dress : Slot.top,
    if (jacket != null) Slot.jacket,
  ];
}

/// The SVG layers of a dressed doll, in drawing order, split around the
/// parts that animate (the face and, when waving, the right arm).
class DollRecipe {
  DollRecipe(
    this.under,
    this.rightArm,
    this.over, {
    this.makeup = Makeup.none,
    this.body = DollBody.classic,
  });

  final List<ArtLayer> under;
  final List<ArtLayer> rightArm;
  final List<ArtLayer> over;
  final Makeup makeup;
  final DollBody body;

  /// The face (with its makeup) for [face].
  List<ArtLayer> face(Face face) =>
      makeupFaceLayers(makeup, face, faceLayer(face, body), body.eyeShape);

  List<ArtLayer> flat(Face face) => [
    ...under,
    ...rightArm,
    ...this.face(face),
    ...over,
  ];
}

Future<DollRecipe> dollRecipe(
  Outfit outfit, {
  bool separateRightArm = false,
  SpotGrid? wetHair,
}) async {
  final assets = await ArtLibrary.instance.manifest();
  List<ArtLayer> part(Slot slot, [String suffix = '']) {
    final worn = outfit[slot];
    if (worn == null) return const [];
    final path = itemAsset(worn.item.shape, suffix);
    if (suffix.isNotEmpty && !assets.contains(path)) return const [];
    return [
      skinnedItem(
        ArtLayer(
          path,
          color: worn.color,
          pattern: worn.item.pattern,
          slot: slot,
        ),
        outfit.body,
      ),
    ];
  }

  ArtLayer doll(String name) => skinLayer(name, outfit.body);
  // Salon hair replaces the plain long hair (also while it is wet).
  final hair = outfit[Slot.hair];
  final wet = wetHair != null && !wetHair.isEmpty;
  final noHair = hairCovered(outfit);
  final salon =
      !noHair &&
          hair != null &&
          (outfit.hasSalonHair || (wet && hair.item.id == salonHairId))
      ? salonHairLayers(outfit.salon, hair.color, wet: wetHair)
      : null;
  final hasDress = outfit[Slot.dress] != null;
  final arm = [doll('arm_right'), ...dollNailLayers(outfit.nails, right: true)];
  final pants = outfit[Slot.pants]?.item.shape;
  final covered = footCoveringShapes.contains(outfit[Slot.dress]?.item.shape);
  final swimming = outfit[Slot.dress]?.item.shape.isSwimwear ?? false;
  final floaties = outfit[Slot.hand]?.item.shape == ItemShape.handFloaties;

  final under = <ArtLayer>[
    // Wings behind everything.
    ...part(Slot.back),
    ...part(Slot.dress, '_back'),
    if (salon != null)
      salon.first
    else if (!noHair)
      ...part(Slot.hair, '_back'),
    doll('body'),
    if (!covered && !swimming) ...part(Slot.socks),
    // Leggings tuck into her shoes; other pants fall over them.
    if (pants == ItemShape.pantsLeggings) ...part(Slot.pants),
    if (!covered) ...part(Slot.shoes),
    if (pants != ItemShape.pantsLeggings && pants != ItemShape.pantsOveralls)
      ...part(Slot.pants),
    if (hasDress)
      ...part(Slot.dress)
    else ...[
      ...part(Slot.top),
      // Overalls are worn over her top.
      if (pants == ItemShape.pantsOveralls) ...part(Slot.pants),
      ...part(Slot.skirt),
    ],
    ...part(Slot.jacket),
    doll('arm_left'),
    ...dollNailLayers(outfit.nails, right: false),
    if (!separateRightArm) ...arm,
    for (final slot in sleeveSlots(outfit)) ...part(slot, '_front'),
    // Arm floaties go over her sleeves.
    if (floaties) ...part(Slot.hand),
    // Jewelry sits on top of the clothes, under her chin.
    ...part(Slot.wrist),
    ...part(Slot.neck),
    doll('head'),
  ];
  final over = <ArtLayer>[
    if (salon != null) salon.last else if (!noHair) ...part(Slot.hair),
    // A burkini's swim hood.
    ...part(Slot.dress, '_hood'),
    browsLayer(outfit.body),
    // Earrings peek out in front of the hair.
    ...part(Slot.ears),
    ...part(Slot.head),
    ...part(Slot.hat),
    ...part(Slot.eyes),
    if (!floaties) ...part(Slot.hand),
  ];
  return DollRecipe(
    under,
    separateRightArm ? arm : const [],
    over,
    makeup: outfit.makeup,
    body: outfit.body,
  );
}

// ------------------------------------------------------------- rasterizing

/// Draws [layers] (doll space) so that [frame] fills [pixels], centered.
/// With [depth], every layer gets its 2.5D shading.
Future<ui.Image> rasterizeDoll(
  List<ArtLayer> layers,
  Rect frame,
  Size pixels, {
  bool depth = false,
}) async {
  final pictures = await Future.wait(layers.map(ArtLibrary.instance.picture));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fit = FitTransform(frame, pixels);
  canvas.translate(fit.dx, fit.dy);
  canvas.scale(fit.scale);
  for (var i = 0; i < pictures.length; i++) {
    void draw() => canvas.drawPicture(pictures[i]);
    depth && hasDepth(layers[i])
        ? paintRounded(canvas, draw, bounds: frame.inflate(8))
        : draw();
  }
  return _finish(recorder, pixels);
}

/// The transform that makes the 480x800 scene cover [size], keeping the
/// ground (bottom) in view.
Matrix4Like sceneCover(Size size) {
  final s = math.max(
    size.width / kSceneSize.width,
    size.height / kSceneSize.height,
  );
  return Matrix4Like(
    s,
    (size.width - kSceneSize.width * s) / 2,
    size.height - kSceneSize.height * s,
  );
}

/// A uniform scale plus offset.
class Matrix4Like {
  const Matrix4Like(this.scale, this.dx, this.dy);
  final double scale;
  final double dx;
  final double dy;
  Offset apply(Offset p) => Offset(dx + p.dx * scale, dy + p.dy * scale);
}

Future<ui.Image> rasterizeScene(
  ArtLayer scene,
  Size pixels, {
  Outfit? doll,
  Rect? dollArea,
}) async {
  final picture = await ArtLibrary.instance.picture(scene);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final cover = sceneCover(pixels);
  canvas.save();
  canvas.translate(cover.dx, cover.dy);
  canvas.scale(cover.scale);
  canvas.drawPicture(picture);
  canvas.restore();
  if (doll != null) {
    // In the pose she was saved in.
    final pose = heldPoseFrame(doll.pose);
    final paintDoll = await posedDollPainter(doll, pose, depth: true);
    final area = dollArea ?? Offset.zero & pixels;
    final fit = FitTransform(kDollFrame, area.size);
    canvas.translate(area.left + fit.dx, area.top + fit.dy);
    canvas.scale(fit.scale);
    paintGroundShadow(canvas, pose: pose);
    paintDoll(canvas);
  }
  return _finish(recorder, pixels);
}

/// Draws one SVG whose own size is [source] stretched to [pixels].
Future<ui.Image> rasterizeArt(ArtLayer layer, Size source, Size pixels) async {
  final picture = await ArtLibrary.instance.picture(layer);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixels.width / source.width, pixels.height / source.height);
  canvas.drawPicture(picture);
  return _finish(recorder, pixels);
}

Future<ui.Image> _finish(ui.PictureRecorder recorder, Size pixels) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    math.max(1, pixels.width.round()),
    math.max(1, pixels.height.round()),
  );
  picture.dispose();
  return image;
}

/// A small least-recently-used cache of finished images (thumbnails etc.).
class ImageCache2 {
  ImageCache2(this.capacity);
  final int capacity;
  final LinkedHashMap<String, Future<ui.Image>> _map = LinkedHashMap();

  Future<ui.Image> get(String key, Future<ui.Image> Function() build) {
    final existing = _map.remove(key);
    if (existing != null) {
      _map[key] = existing;
      return existing;
    }
    final created = build();
    _map[key] = created;
    created.then((_) {}, onError: (Object _) => _map.remove(key));
    while (_map.length > capacity) {
      _map.remove(_map.keys.first);
    }
    return created;
  }
}

/// Small pictures: item thumbnails, faces, cloud and sparkle images.
final ImageCache2 artImages = ImageCache2(160);

/// Full-screen scenes are big, so only a few are kept.
final ImageCache2 sceneImages = ImageCache2(3);

/// Saved-look pictures for the gallery.
final ImageCache2 lookImages = ImageCache2(30);

String outfitKey(Outfit o) => [
  for (final e in o.worn.entries)
    '${e.key.name}:${e.value.item.id}:${e.value.color.toARGB32()}',
  if (!o.makeup.isEmpty) 'makeup:${o.makeup.key}',
  if (o.hasSalonHair) 'salon:${o.salon.key}',
  if (!o.nails.isEmpty) 'nails:${o.nails.key}',
  if (o.body != DollBody.classic) 'body:${o.body.key}',
].join(',');

/// Pixel density used for art: sharp, but capped so low-end phones stay fast.
double artPixelRatio(double deviceRatio) => deviceRatio.clamp(1.0, 2.0);
