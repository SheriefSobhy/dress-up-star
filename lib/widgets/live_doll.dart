import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../art/doll_art.dart';
import '../data/game_config.dart';
import '../models/outfit.dart';

/// The doll drawn straight from her vector art and zoomed in on [frame]
/// (doll space). Used by the activities, where she changes with every
/// finger move: only the changed layers are redrawn, and nothing animates
/// unless something happens. The shaded (2.5D) look of her art is made once
/// per layer and kept as a picture, so strokes stay fast.
class LiveDoll extends StatefulWidget {
  const LiveDoll({
    super.key,
    required this.outfit,
    required this.frame,
    this.face = Face.open,
    this.hairSway,
    this.bounce,
    this.wetHair,
    this.foreground,
  });

  final Outfit outfit;
  final Rect frame;
  final Face face;

  /// Blows the hair sideways (-1..1), for the hair dryer.
  final ValueListenable<double>? hairSway;

  /// A little happy hop (0..1, 0 = still).
  final ValueListenable<double>? bounce;

  /// Wet spots of the salon hair (darker while wet).
  final SpotGrid? wetHair;

  /// Draws on top of her, in doll space (soap foam, water drops).
  final void Function(Canvas canvas)? foreground;

  @override
  State<LiveDoll> createState() => _LiveDollState();
}

class _Layer {
  const _Layer(this.art, this.picture);
  final ArtLayer art;
  final ui.Picture picture;
  bool get hair => art.slot == Slot.hair;
}

/// The shaded pictures of her art layers, for one size of the widget.
class _ShadedLayers {
  final Map<String, ui.Image> _images = {};
  final Set<String> _used = {};
  Rect _area = Rect.zero;
  double _pixels = 0;

  /// Forgets the pictures if the widget changed size.
  void fit(Rect area, double pixelsPerUnit) {
    if (area == _area && pixelsPerUnit == _pixels) return;
    clear();
    _area = area;
    _pixels = pixelsPerUnit;
  }

  /// Draws [layer] shaded, with the shadow [above] casts on it.
  void draw(Canvas canvas, _Layer layer, List<_Layer> above) {
    final key = [layer.art.key, for (final a in above) a.art.key].join('+');
    _used.add(key);
    final image = _images[key] ??= _build(layer, above);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      _area,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  ui.Image _build(_Layer layer, List<_Layer> above) {
    final picture = recordPicture((canvas) {
      canvas.scale(_pixels);
      canvas.translate(-_area.left, -_area.top);
      canvas.saveLayer(_area, Paint());
      paintRounded(
        canvas,
        () => canvas.drawPicture(layer.picture),
        bounds: _area,
      );
      if (above.isNotEmpty) {
        paintOcclusion(
          canvas,
          () {
            for (final a in above) {
              canvas.drawPicture(a.picture);
            }
          },
          offset: const Offset(2, 5),
          opacity: 0.3,
          bounds: _area,
        );
      }
      canvas.restore();
    });
    final image = picture.toImageSync(
      (_area.width * _pixels).ceil().clamp(1, 4096),
      (_area.height * _pixels).ceil().clamp(1, 4096),
    );
    picture.dispose();
    return image;
  }

  /// Forgets the pictures the last frame did not use (old hairdos, skins).
  void trim() {
    _images.removeWhere((key, image) {
      if (_used.contains(key)) return false;
      image.dispose();
      return true;
    });
    _used.clear();
  }

  void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }
}

class _Pictures {
  _Pictures(this.under, this.faces, this.over);
  final List<_Layer> under;
  final Map<Face, List<_Layer>> faces;
  final List<_Layer> over;
}

class _LiveDollState extends State<LiveDoll> {
  _Pictures? _pictures;
  final _ShadedLayers _shaded = _ShadedLayers();
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LiveDoll old) {
    super.didUpdateWidget(old);
    if (old.outfit != widget.outfit || old.wetHair != widget.wetHair) _load();
  }

  @override
  void dispose() {
    _shaded.clear();
    super.dispose();
  }

  Future<void> _load() async {
    final outfit = widget.outfit;
    final token = ++_token;
    try {
      final recipe = await dollRecipe(outfit, wetHair: widget.wetHair);
      Future<List<_Layer>> pictures(List<ArtLayer> layers) async {
        final list = await Future.wait(layers.map(ArtLibrary.instance.picture));
        return [
          for (var i = 0; i < layers.length; i++) _Layer(layers[i], list[i]),
        ];
      }

      final results = await Future.wait([
        pictures(recipe.under),
        pictures(recipe.over),
        for (final face in Face.values) pictures(recipe.face(face)),
      ]);
      if (!mounted || token != _token) return;
      setState(() {
        _pictures = _Pictures(results[0], {
          for (var i = 0; i < Face.values.length; i++)
            Face.values[i]: results[2 + i],
        }, results[1]);
      });
    } catch (e) {
      debugPrint('Doll drawing failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = artPixelRatio(MediaQuery.devicePixelRatioOf(context));
    return ClipRect(
      child: CustomPaint(
        size: Size.infinite,
        painter: _LiveDollPainter(
          pictures: _pictures,
          shaded: _shaded,
          ratio: ratio,
          frame: widget.frame,
          face: widget.face,
          sway: widget.hairSway,
          bounce: widget.bounce,
          foreground: widget.foreground,
        ),
      ),
    );
  }
}

class _LiveDollPainter extends CustomPainter {
  _LiveDollPainter({
    required this.pictures,
    required this.shaded,
    required this.ratio,
    required this.frame,
    required this.face,
    this.sway,
    this.bounce,
    this.foreground,
  }) : super(repaint: Listenable.merge([sway, bounce]));

  final _Pictures? pictures;
  final _ShadedLayers shaded;
  final double ratio;
  final Rect frame;
  final Face face;
  final ValueListenable<double>? sway;
  final ValueListenable<double>? bounce;

  /// Draws on top of her, in doll space (soap foam, water drops).
  final void Function(Canvas canvas)? foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pictures;
    if (p == null || size.isEmpty) return;
    final fit = FitTransform(frame, size);
    final hop = bounce?.value ?? 0;
    final wind = sway?.value ?? 0;
    // What shows in the widget (and a little more, for hops and wind).
    shaded.fit(
      Rect.fromPoints(
        fit.invert(Offset.zero),
        fit.invert(size.bottomRight(Offset.zero)),
      ).inflate(12).intersect(kDepthBounds),
      fit.scale * ratio,
    );
    // Her front hair shades her head.
    final fringe = [
      for (final l in p.over)
        if (l.hair && hasDepth(l.art)) l,
    ];
    canvas.save();
    canvas.translate(fit.dx, fit.dy);
    canvas.scale(fit.scale);
    if (hop != 0) {
      // Squash and stretch around the chin.
      const pivot = Offset(100, 160);
      canvas.translate(pivot.dx, pivot.dy - hop * 5);
      canvas.scale(1 + hop * 0.025, 1 - hop * 0.015);
      canvas.translate(-pivot.dx, -pivot.dy);
    }
    void picture(_Layer layer) {
      if (!hasDepth(layer.art)) return canvas.drawPicture(layer.picture);
      final head = layer.art.asset.endsWith('/head.svg');
      shaded.draw(canvas, layer, head ? fringe : const []);
    }

    void draw(_Layer layer) {
      if (layer.hair && wind != 0) {
        // The hair dryer blows the ends of the hair sideways.
        canvas.save();
        canvas.translate(100, 60);
        canvas.skew(wind * 0.12, 0);
        canvas.translate(-100, -60);
        picture(layer);
        canvas.restore();
      } else {
        picture(layer);
      }
    }

    p.under.forEach(draw);
    p.faces[face]?.forEach(draw);
    p.over.forEach(draw);
    foreground?.call(canvas);
    canvas.restore();
    shaded.trim();
  }

  @override
  bool shouldRepaint(_LiveDollPainter old) =>
      old.pictures != pictures ||
      old.face != face ||
      old.frame != frame ||
      old.foreground != foreground;
}
