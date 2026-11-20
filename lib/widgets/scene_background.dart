import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/doll_art.dart';
import '../art/motion.dart';
import '../data/game_config.dart';
import '../models/outfit.dart';
import 'art_image.dart';

/// Gentle moving details for each scene, in scene coordinates (480 x 800).
class SceneMotion {
  const SceneMotion({
    this.clouds = 0,
    this.cloudTop = 120,
    this.cloudBottom = 330,
    this.sparkles = 0,
    this.sparkleArea = const Rect.fromLTWH(0, 80, 480, 500),
    this.waves = const [],
  });

  final int clouds;
  final double cloudTop;
  final double cloudBottom;
  final int sparkles;
  final Rect sparkleArea;
  final List<double> waves;
}

SceneMotion motionFor(ItemShape shape) {
  switch (shape) {
    case ItemShape.bgNight:
      return const SceneMotion(
        sparkles: 14,
        sparkleArea: Rect.fromLTWH(0, 40, 480, 520),
      );
    case ItemShape.bgBeach:
      return const SceneMotion(
        clouds: 2,
        cloudBottom: 300,
        sparkles: 6,
        sparkleArea: Rect.fromLTWH(0, 480, 480, 120),
        waves: [536, 584],
      );
    case ItemShape.bgHearts:
      return const SceneMotion(
        sparkles: 12,
        sparkleArea: Rect.fromLTWH(20, 140, 440, 520),
      );
    case ItemShape.bgCandy:
      return const SceneMotion(clouds: 2, sparkles: 9);
    case ItemShape.bgRainbow:
      return const SceneMotion(
        clouds: 2,
        cloudBottom: 260,
        sparkles: 8,
        sparkleArea: Rect.fromLTWH(0, 300, 480, 280),
      );
    case ItemShape.bgCastle:
      return const SceneMotion(clouds: 3, cloudBottom: 300, sparkles: 6);
    case ItemShape.bgGarden:
      return const SceneMotion(
        clouds: 2,
        cloudBottom: 300,
        sparkles: 7,
        sparkleArea: Rect.fromLTWH(0, 620, 480, 160),
      );
    default:
      return const SceneMotion(clouds: 3, sparkles: 4);
  }
}

/// The background scene with clouds drifting, sparkles twinkling and waves
/// moving. Switching scenes cross-fades.
class SceneBackground extends StatelessWidget {
  const SceneBackground({super.key, required this.scene});

  final WornItem scene;

  @override
  Widget build(BuildContext context) {
    final key = '${scene.item.id}|${scene.color.toARGB32()}';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: Stack(
        key: ValueKey(key),
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: ArtImage(
              cacheKey: 'scene|$key',
              cache: sceneImages,
              draw: (pixels) => rasterizeScene(sceneLayer(scene), pixels),
            ),
          ),
          RepaintBoundary(
            child: _SceneMotionLayer(motion: motionFor(scene.item.shape)),
          ),
        ],
      ),
    );
  }
}

class _SceneMotionLayer extends StatefulWidget {
  const _SceneMotionLayer({required this.motion});
  final SceneMotion motion;

  @override
  State<_SceneMotionLayer> createState() => _SceneMotionLayerState();
}

class _Decorations {
  _Decorations(this.cloud, this.sparkle, this.wave);
  final ui.Image cloud;
  final ui.Image sparkle;
  final ui.Image wave;
}

class _SceneMotionLayerState extends State<_SceneMotionLayer>
    with SingleTickerProviderStateMixin {
  /// One loop of all motion. Every movement repeats a whole number of times
  /// per loop, so the loop is seamless.
  static const loop = Duration(seconds: 120);
  AnimationController? _clock;
  _Decorations? _decorations;
  String? _sizeKey;

  @override
  void initState() {
    super.initState();
    if (GameMotion.idleAnimations) {
      _clock = AnimationController(vsync: this, duration: loop)..repeat();
    }
  }

  @override
  void dispose() {
    _clock?.dispose();
    super.dispose();
  }

  void _load(Size size, double ratio) {
    if (size.isEmpty) return;
    final scale = sceneCover(size).scale * ratio;
    final key = scale.toStringAsFixed(2);
    if (key == _sizeKey) return;
    _sizeKey = key;
    Future<ui.Image> art(String name, Size source) => artImages.get(
      'deco|$name|$key',
      () =>
          rasterizeArt(ArtLayer('$kSceneDir$name.svg'), source, source * scale),
    );
    Future.wait([
      art('cloud', const Size(120, 60)),
      art('sparkle', const Size(40, 40)),
      art('wave', const Size(480, 30)),
    ]).then((images) {
      if (mounted && key == _sizeKey) {
        setState(
          () => _decorations = _Decorations(images[0], images[1], images[2]),
        );
      }
    }, onError: (Object e) => debugPrint('Decorations failed: $e'));
  }

  @override
  Widget build(BuildContext context) {
    if (_clock == null) return const SizedBox.expand();
    final ratio = artPixelRatio(MediaQuery.devicePixelRatioOf(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        _load(constraints.biggest, ratio);
        return CustomPaint(
          size: Size.infinite,
          painter: _MotionPainter(widget.motion, _decorations, _clock!),
        );
      },
    );
  }
}

class _MotionPainter extends CustomPainter {
  _MotionPainter(this.motion, this.decorations, this.clock)
    : super(repaint: clock);

  final SceneMotion motion;
  final _Decorations? decorations;
  final AnimationController clock;

  static final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  void _image(Canvas canvas, ui.Image img, Rect dest, double opacity) {
    _paint.color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      dest,
      _paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final d = decorations;
    if (d == null) return;
    final t = clock.value; // 0..1 over the whole loop
    final cover = sceneCover(size);
    final s = cover.scale;
    final rnd = math.Random(42);

    // Clouds drift slowly to the right and come back from the left.
    for (var i = 0; i < motion.clouds; i++) {
      final laps = 1 + i % 2; // whole laps per loop keeps it seamless
      final y =
          motion.cloudTop +
          (motion.cloudBottom - motion.cloudTop) *
              (i / math.max(1, motion.clouds - 1));
      final w = 100.0 + rnd.nextDouble() * 70;
      final start = rnd.nextDouble();
      final x = ((start + t * laps) % 1.0) * (480 + w + 40) - w - 20;
      final p = cover.apply(Offset(x, y));
      _image(
        canvas,
        d.cloud,
        Rect.fromLTWH(p.dx, p.dy, w * s, w * 0.5 * s),
        0.92,
      );
    }

    // Waves gently slide back and forth.
    for (var i = 0; i < motion.waves.length; i++) {
      final shift = math.sin(2 * math.pi * (t * 40 + i * 0.3)) * 24;
      final p = cover.apply(Offset(-30 + shift, motion.waves[i]));
      _image(
        canvas,
        d.wave,
        Rect.fromLTWH(p.dx, p.dy, 540 * s, 30 * s),
        0.8 - i * 0.2,
      );
    }

    // Sparkles twinkle (grow, shine and fade) at fixed spots.
    final area = motion.sparkleArea;
    for (var i = 0; i < motion.sparkles; i++) {
      final pos = Offset(
        area.left + rnd.nextDouble() * area.width,
        area.top + rnd.nextDouble() * area.height,
      );
      final speed = 30 + rnd.nextInt(20); // twinkles per loop
      final phase = rnd.nextDouble();
      final v = math.sin(2 * math.pi * (t * speed + phase));
      final glow = math.max(0.0, v);
      if (glow <= 0.02) continue;
      final r = (9 + rnd.nextDouble() * 9) * (0.5 + glow * 0.6) * s;
      final c = cover.apply(pos);
      _image(canvas, d.sparkle, Rect.fromCircle(center: c, radius: r), glow);
    }
  }

  @override
  bool shouldRepaint(_MotionPainter old) =>
      old.decorations != decorations || old.motion != motion;
}
