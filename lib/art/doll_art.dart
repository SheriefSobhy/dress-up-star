import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';
import 'art_library.dart';

export 'art_library.dart' show ArtLayer, ArtLibrary;

// ---------------------------------------------------------------- geometry

/// The doll is drawn on a 200 x 400 "doll space". This part of it is shown
/// when the whole doll is visible.
const Rect kDollFrame = Rect.fromLTRB(4, 6, 196, 374);

/// The part of doll space covered by the face (eyes and mouth).
const Rect kFaceRect = Rect.fromLTRB(46, 82, 154, 158);

/// Backgrounds are drawn on a 480 x 800 canvas.
const Size kSceneSize = Size(480, 800);

const Offset kRightShoulder = Offset(121, 177);
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
}

/// The part of doll space that shows an item best (thumbnails, sparkles).
Rect focusRectFor(ItemShape shape) {
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
    case Slot.hand:
      switch (shape) {
        case ItemShape.handWand:
          return const Rect.fromLTRB(18, 166, 94, 268);
        case ItemShape.handBalloon:
          return const Rect.fromLTRB(110, 76, 200, 262);
        default:
          return const Rect.fromLTRB(108, 222, 172, 302);
      }
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

ArtLayer faceLayer(Face face) => ArtLayer('${kDollDir}face_${face.name}.svg');

ArtLayer sceneLayer(WornItem bg) =>
    ArtLayer(itemAsset(bg.item.shape), color: bg.color, slot: Slot.background);

/// The SVG layers of a dressed doll, in drawing order, split around the
/// parts that animate (the face and, when waving, the right arm).
class DollRecipe {
  DollRecipe(this.under, this.rightArm, this.over);

  final List<ArtLayer> under;
  final List<ArtLayer> rightArm;
  final List<ArtLayer> over;

  List<ArtLayer> flat(Face face) => [
    ...under,
    ...rightArm,
    faceLayer(face),
    ...over,
  ];
}

Future<DollRecipe> dollRecipe(
  Outfit outfit, {
  bool separateRightArm = false,
}) async {
  final assets = await ArtLibrary.instance.manifest();
  List<ArtLayer> part(Slot slot, [String suffix = '']) {
    final worn = outfit[slot];
    if (worn == null) return const [];
    final path = itemAsset(worn.item.shape, suffix);
    if (suffix.isNotEmpty && !assets.contains(path)) return const [];
    return [
      ArtLayer(path, color: worn.color, pattern: worn.item.pattern, slot: slot),
    ];
  }

  ArtLayer doll(String name) => ArtLayer('$kDollDir$name.svg');
  final hasDress = outfit[Slot.dress] != null;
  final arm = [doll('arm_right')];

  final under = <ArtLayer>[
    ...part(Slot.dress, '_back'),
    ...part(Slot.hair, '_back'),
    doll('body'),
    ...part(Slot.shoes),
    if (hasDress)
      ...part(Slot.dress)
    else ...[
      ...part(Slot.top),
      ...part(Slot.skirt),
    ],
    doll('arm_left'),
    if (!separateRightArm) ...arm,
    if (hasDress)
      ...part(Slot.dress, '_front')
    else
      ...part(Slot.top, '_front'),
    doll('head'),
  ];
  final over = <ArtLayer>[
    ...part(Slot.hair),
    ...part(Slot.head),
    ...part(Slot.eyes),
    ...part(Slot.hand),
  ];
  return DollRecipe(under, separateRightArm ? arm : const [], over);
}

// ------------------------------------------------------------- rasterizing

/// Draws [layers] (doll space) so that [frame] fills [pixels], centered.
Future<ui.Image> rasterizeDoll(
  List<ArtLayer> layers,
  Rect frame,
  Size pixels,
) async {
  final pictures = await Future.wait(layers.map(ArtLibrary.instance.picture));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fit = FitTransform(frame, pixels);
  canvas.translate(fit.dx, fit.dy);
  canvas.scale(fit.scale);
  for (final p in pictures) {
    canvas.drawPicture(p);
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
    final recipe = await dollRecipe(doll);
    final pictures = await Future.wait(
      recipe.flat(Face.open).map(ArtLibrary.instance.picture),
    );
    final area = dollArea ?? Offset.zero & pixels;
    final fit = FitTransform(kDollFrame, area.size);
    canvas.translate(area.left + fit.dx, area.top + fit.dy);
    canvas.scale(fit.scale);
    for (final p in pictures) {
      canvas.drawPicture(p);
    }
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
].join(',');

/// Pixel density used for art: sharp, but capped so low-end phones stay fast.
double artPixelRatio(double deviceRatio) => deviceRatio.clamp(1.0, 2.0);
