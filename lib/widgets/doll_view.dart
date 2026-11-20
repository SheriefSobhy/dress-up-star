import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/doll_art.dart';
import '../art/motion.dart';
import '../models/outfit.dart';

/// The animated doll: breathes and sways gently, blinks every few seconds,
/// smiles when [happy] and can wave hello.
///
/// The SVG layers are flattened into a few images whenever the outfit
/// changes, so every animation frame only moves ready-made images (fast even
/// on low-end phones).
class DollView extends StatefulWidget {
  const DollView({
    super.key,
    required this.outfit,
    this.happy = false,
    this.waving = false,
  });

  final Outfit outfit;
  final bool happy;
  final bool waving;

  @override
  State<DollView> createState() => _DollViewState();
}

class _DollImages {
  _DollImages(this.under, this.arm, this.over, this.faces);
  final ui.Image under;
  final ui.Image? arm;
  final ui.Image over;
  final Map<Face, ui.Image> faces;
}

class _DollViewState extends State<DollView>
    with SingleTickerProviderStateMixin {
  AnimationController? _idle;
  Timer? _blinkTimer;
  bool _blinking = false;
  _DollImages? _images;
  String? _wantedKey;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    if (GameMotion.idleAnimations) {
      _idle = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
      )..repeat();
      _scheduleBlink();
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2200 + _random.nextInt(3200)),
      () {
        if (!mounted) return;
        setState(() => _blinking = true);
        _blinkTimer = Timer(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() => _blinking = false);
          _scheduleBlink();
        });
      },
    );
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idle?.dispose();
    super.dispose();
  }

  void _ensureImages(Size size, double ratio) {
    if (size.isEmpty) return;
    final key =
        '${outfitKey(widget.outfit)}|${size.width.round()}x${size.height.round()}'
        '|$ratio|${widget.waving}';
    if (key == _wantedKey) return;
    _wantedKey = key;
    _build(key, size, ratio);
  }

  Future<void> _build(String key, Size size, double ratio) async {
    try {
      final fit = FitTransform(kDollFrame, size);
      final pixels = fit.applyRect(kDollFrame).size * ratio;
      final facePixels = fit.applyRect(kFaceRect).size * ratio;
      final recipe = await dollRecipe(
        widget.outfit,
        separateRightArm: widget.waving,
      );
      final faceKey =
          '${facePixels.width.round()}x${facePixels.height.round()}';
      final results = await Future.wait([
        rasterizeDoll(recipe.under, kDollFrame, pixels),
        rasterizeDoll(recipe.over, kDollFrame, pixels),
        if (widget.waving) rasterizeDoll(recipe.rightArm, kDollFrame, pixels),
        for (final face in Face.values)
          artImages.get(
            'face|${face.name}|$faceKey',
            () => rasterizeDoll([faceLayer(face)], kFaceRect, facePixels),
          ),
      ]);
      if (!mounted || key != _wantedKey) return;
      final faces = results.sublist(results.length - Face.values.length);
      setState(() {
        _images = _DollImages(
          results[0],
          widget.waving ? results[2] : null,
          results[1],
          {
            for (var i = 0; i < Face.values.length; i++)
              Face.values[i]: faces[i],
          },
        );
      });
    } catch (e) {
      debugPrint('Doll drawing failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = artPixelRatio(MediaQuery.devicePixelRatioOf(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureImages(constraints.biggest, ratio);
        return CustomPaint(
          size: Size.infinite,
          painter: _DollPainter(
            images: _images,
            idle: _idle,
            face: widget.happy
                ? Face.happy
                : (_blinking ? Face.blink : Face.open),
            waving: widget.waving,
          ),
        );
      },
    );
  }
}

class _DollPainter extends CustomPainter {
  _DollPainter({
    required this.images,
    required this.idle,
    required this.face,
    required this.waving,
  }) : super(repaint: idle);

  final _DollImages? images;
  final AnimationController? idle;
  final Face face;
  final bool waving;

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  void _draw(Canvas canvas, ui.Image image, Rect dest) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dest,
      _paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final img = images;
    if (img == null || size.isEmpty) return;
    final fit = FitTransform(kDollFrame, size);
    final dest = fit.applyRect(kDollFrame);
    final t = idle?.value ?? 0;
    final wave = 2 * math.pi * t;

    // Gentle breathing and swaying around the feet.
    final pivot = fit.apply(kFeet);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(math.sin(wave) * 0.014);
    canvas.scale(1, 1 + math.sin(wave * 3) * 0.007);
    canvas.translate(-pivot.dx, -pivot.dy);

    _draw(canvas, img.under, dest);
    final arm = img.arm;
    if (arm != null) {
      final shoulder = fit.apply(kRightShoulder);
      canvas.save();
      canvas.translate(shoulder.dx, shoulder.dy);
      canvas.rotate(-2.1 + math.sin(wave * 8) * 0.32);
      canvas.translate(-shoulder.dx, -shoulder.dy);
      _draw(canvas, arm, dest);
      canvas.restore();
    }
    final faceImage = img.faces[face];
    if (faceImage != null) _draw(canvas, faceImage, fit.applyRect(kFaceRect));
    _draw(canvas, img.over, dest);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DollPainter old) =>
      old.images != images || old.face != face || old.waving != waving;
}
