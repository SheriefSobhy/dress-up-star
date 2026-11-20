import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/doll_art.dart';
import '../data/game_config.dart';
import '../models/outfit.dart';

/// A still picture made from the SVG art, cached so it is only drawn once.
/// It fades in when ready.
class ArtImage extends StatefulWidget {
  const ArtImage({
    super.key,
    required this.cacheKey,
    required this.draw,
    this.cache,
  });

  /// Identifies the picture (the size is added automatically).
  final String cacheKey;

  /// Where the finished picture is kept (small pictures by default).
  final ImageCache2? cache;

  /// Draws the picture at the given size in pixels.
  final Future<ui.Image> Function(Size pixels) draw;

  @override
  State<ArtImage> createState() => _ArtImageState();
}

class _ArtImageState extends State<ArtImage> {
  ui.Image? _image;
  String? _key;

  void _load(Size size, double ratio) {
    if (size.isEmpty || !size.isFinite) return;
    final pixels = size * ratio;
    final key =
        '${widget.cacheKey}|${pixels.width.round()}x${pixels.height.round()}';
    if (key == _key) return;
    _key = key;
    (widget.cache ?? artImages).get(key, () => widget.draw(pixels)).then((
      image,
    ) {
      if (mounted && key == _key) setState(() => _image = image);
    }, onError: (Object e) => debugPrint('Art failed: $e'));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = artPixelRatio(MediaQuery.devicePixelRatioOf(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        _load(constraints.biggest, ratio);
        return AnimatedOpacity(
          opacity: _image == null ? 0 : 1,
          duration: const Duration(milliseconds: 220),
          child: _image == null
              ? const SizedBox.expand()
              : RawImage(
                  image: _image,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
        );
      },
    );
  }
}

/// A small picture of one item (zoomed in on the doll, or the scene).
class ItemThumbnail extends StatelessWidget {
  const ItemThumbnail({super.key, required this.item, required this.color});

  final GameItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final worn = WornItem(item, color);
    return ArtImage(
      cacheKey: 'item|${item.id}|${color.toARGB32()}',
      draw: (pixels) async {
        if (item.slot == Slot.background) {
          return rasterizeScene(sceneLayer(worn), pixels);
        }
        final wear = <Slot, WornItem>{item.slot: worn};
        // Head things and glasses look best on a doll with hair.
        if (item.slot == Slot.head || item.slot == Slot.eyes) {
          final hair = findItem('hair_bob') ?? itemsForSlot(Slot.hair).first;
          wear[Slot.hair] = WornItem(hair, hair.color);
        }
        final recipe = await dollRecipe(Outfit(wear));
        return rasterizeDoll(
          recipe.flat(Face.open),
          focusRectFor(item.shape),
          pixels,
        );
      },
    );
  }
}

/// A saved look: the doll in front of her background.
class LookPicture extends StatelessWidget {
  const LookPicture({super.key, required this.look});

  final Outfit look;

  @override
  Widget build(BuildContext context) {
    return ArtImage(
      cacheKey: 'look|${outfitKey(look)}',
      cache: lookImages,
      draw: (pixels) {
        final bg = look[Slot.background] ?? Outfit.starter()[Slot.background]!;
        return rasterizeScene(
          sceneLayer(bg),
          pixels,
          doll: look,
          dollArea: Rect.fromLTWH(
            0,
            pixels.height * 0.05,
            pixels.width,
            pixels.height * 0.93,
          ),
        );
      },
    );
  }
}
