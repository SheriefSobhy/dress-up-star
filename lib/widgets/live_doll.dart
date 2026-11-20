import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../art/doll_art.dart';
import '../data/game_config.dart';
import '../models/outfit.dart';

/// The doll drawn straight from her vector art and zoomed in on [frame]
/// (doll space). Used by the activities, where she changes with every
/// finger move: only the changed layers are redrawn, and nothing animates
/// unless something happens.
class LiveDoll extends StatefulWidget {
  const LiveDoll({
    super.key,
    required this.outfit,
    required this.frame,
    this.face = Face.open,
    this.hairSway,
    this.bounce,
  });

  final Outfit outfit;
  final Rect frame;
  final Face face;

  /// Blows the hair sideways (-1..1), for the hair dryer.
  final ValueListenable<double>? hairSway;

  /// A little happy hop (0..1, 0 = still).
  final ValueListenable<double>? bounce;

  @override
  State<LiveDoll> createState() => _LiveDollState();
}

class _Layer {
  const _Layer(this.picture, this.hair);
  final ui.Picture picture;
  final bool hair;
}

class _Pictures {
  _Pictures(this.under, this.faces, this.over);
  final List<_Layer> under;
  final Map<Face, List<_Layer>> faces;
  final List<_Layer> over;
}

class _LiveDollState extends State<LiveDoll> {
  _Pictures? _pictures;
  Outfit? _wanted;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LiveDoll old) {
    super.didUpdateWidget(old);
    if (old.outfit != widget.outfit) _load();
  }

  Future<void> _load() async {
    final outfit = widget.outfit;
    _wanted = outfit;
    try {
      final recipe = await dollRecipe(outfit);
      Future<List<_Layer>> pictures(List<ArtLayer> layers) async {
        final list = await Future.wait(layers.map(ArtLibrary.instance.picture));
        return [
          for (var i = 0; i < layers.length; i++)
            _Layer(list[i], layers[i].slot == Slot.hair),
        ];
      }

      final results = await Future.wait([
        pictures(recipe.under),
        pictures(recipe.over),
        for (final face in Face.values) pictures(recipe.face(face)),
      ]);
      if (!mounted || _wanted != outfit) return;
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
    return ClipRect(
      child: CustomPaint(
        size: Size.infinite,
        painter: _LiveDollPainter(
          pictures: _pictures,
          frame: widget.frame,
          face: widget.face,
          sway: widget.hairSway,
          bounce: widget.bounce,
        ),
      ),
    );
  }
}

class _LiveDollPainter extends CustomPainter {
  _LiveDollPainter({
    required this.pictures,
    required this.frame,
    required this.face,
    this.sway,
    this.bounce,
  }) : super(repaint: Listenable.merge([sway, bounce]));

  final _Pictures? pictures;
  final Rect frame;
  final Face face;
  final ValueListenable<double>? sway;
  final ValueListenable<double>? bounce;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pictures;
    if (p == null || size.isEmpty) return;
    final fit = FitTransform(frame, size);
    final hop = bounce?.value ?? 0;
    final wind = sway?.value ?? 0;
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
    void draw(_Layer layer) {
      if (layer.hair && wind != 0) {
        // The hair dryer blows the ends of the hair sideways.
        canvas.save();
        canvas.translate(100, 60);
        canvas.skew(wind * 0.12, 0);
        canvas.translate(-100, -60);
        canvas.drawPicture(layer.picture);
        canvas.restore();
      } else {
        canvas.drawPicture(layer.picture);
      }
    }

    p.under.forEach(draw);
    p.faces[face]?.forEach(draw);
    p.over.forEach(draw);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiveDollPainter old) =>
      old.pictures != pictures || old.face != face || old.frame != frame;
}
