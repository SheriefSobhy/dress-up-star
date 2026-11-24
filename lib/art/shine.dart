import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../painting/shapes.dart';
import 'doll_parts.dart';

/// Moving sparkles on jewelry, crowns, sunglasses and glitter nails.
///
/// Uses the fragment shader `shaders/shine.frag`. Where shaders are not
/// supported it falls back to a few twinkling stars drawn by code.
class Shine {
  static Future<ui.FragmentProgram?>? _program;

  /// Draw the fallback stars even when shaders work (for tests).
  @visibleForTesting
  static bool forceFallback = false;

  /// The shader program, or null when shaders are not supported.
  static Future<ui.FragmentProgram?> program() {
    if (forceFallback) return Future.value(null);
    return _program ??= () async {
      try {
        return await ui.FragmentProgram.fromAsset('shaders/shine.frag');
      } catch (e) {
        debugPrint('Sparkle shader not available, using stars: $e');
        return null;
      }
    }();
  }
}

/// The sparkle of one part of the doll.
class PartShine {
  PartShine._(this.mask, this.rect, this.shader, this.glints);

  /// The sparkly pixels of the part (doll space [rect]).
  final ui.Image mask;
  final Rect rect;
  final ui.FragmentShader? shader;

  /// Fallback: points (doll space) where stars twinkle.
  final List<Offset> glints;

  bool get usesShader => shader != null;

  /// Builds the sparkle for [part], with a mask of [pixelsPerUnit].
  static Future<PartShine?> build(DollPart part, double pixelsPerUnit) async {
    final rect = part.shineRect;
    if (rect == null || part.shiny.isEmpty) return null;
    final mask = await rasterizeShineMask(part, rect.size * pixelsPerUnit);
    final program = await Shine.program();
    if (program != null) {
      return PartShine._(mask, rect, program.fragmentShader(), const []);
    }
    return PartShine._(mask, rect, null, await _glintsOf(mask, rect));
  }

  void paint(Canvas canvas, double time) {
    final s = shader;
    if (s != null) {
      s
        ..setFloat(0, rect.left)
        ..setFloat(1, rect.top)
        ..setFloat(2, rect.width)
        ..setFloat(3, rect.height)
        ..setFloat(4, time)
        ..setImageSampler(0, mask);
      canvas.drawRect(rect, Paint()..shader = s);
      return;
    }
    _paintStars(canvas, time);
  }

  static final Paint _starPaint = Paint();

  void _paintStars(Canvas canvas, double time) {
    for (var i = 0; i < glints.length; i++) {
      final phase = (time * 0.55 + i * 0.381) % 1.0;
      final a = math.pow(math.sin(phase * math.pi), 3).toDouble();
      if (a < 0.05) continue;
      _starPaint.color = const Color(0xFFFFFBEA).withValues(alpha: a * 0.95);
      canvas.drawPath(
        starPath(glints[i], 1 + 3 * a, rotation: phase * 1.5),
        _starPaint,
      );
    }
  }

  void dispose() {
    shader?.dispose();
    mask.dispose();
  }
}

/// A few well-spread points on the sparkly pixels.
Future<List<Offset>> _glintsOf(ui.Image mask, Rect rect) async {
  final data = await mask.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return const [];
  final bytes = data.buffer.asUint8List();
  final w = mask.width, h = mask.height;
  final step = math.max(2, math.min(w, h) ~/ 10);
  final spots = <Offset>[];
  for (var y = step ~/ 2; y < h; y += step) {
    for (var x = step ~/ 2; x < w; x += step) {
      if (bytes[(y * w + x) * 4 + 3] > 180) {
        spots.add(
          Offset(
            rect.left + x / w * rect.width,
            rect.top + y / h * rect.height,
          ),
        );
      }
    }
  }
  spots.shuffle(math.Random(spots.length));
  return spots.take(8).toList();
}
