import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../art/doll_art.dart';
import '../art/motion.dart';
import '../art/shine.dart';
import '../models/outfit.dart';

/// The animated doll: breathes and sways gently, blinks every few seconds,
/// smiles when [happy] and can wave hello. Her hair and skirt swing when
/// she moves, and jewelry sparkles.
///
/// The SVG layers are flattened into a few images (one per moving part)
/// whenever the outfit changes, so every animation frame only moves
/// ready-made images (fast even on low-end phones).
class DollView extends StatefulWidget {
  const DollView({
    super.key,
    required this.outfit,
    this.happy = false,
    this.waving = false,
    this.nudge = 0,
    this.dancing = false,
  });

  /// What she wears, and her pose: when the pose changes she moves into
  /// the new one.
  final Outfit outfit;
  final bool happy;
  final bool waving;

  /// Change this number to give her a little push: her hair and skirt
  /// swing and settle again (when she is tapped or hops).
  final int nudge;

  /// She dances (in time with the music) while this is true.
  final bool dancing;

  @override
  State<DollView> createState() => _DollViewState();
}

/// The picture of one part, ready to draw.
class _PartImage {
  _PartImage(this.image, this.shine)
    : shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        _identity,
        filterQuality: FilterQuality.medium,
      );

  final ui.Image image;
  final PartShine? shine;

  /// For bending hair and skirts.
  final ui.ImageShader shader;

  void dispose() {
    shader.dispose();
    shine?.dispose();
    image.dispose();
  }

  static final Float64List _identity = Float64List.fromList([
    1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  ]);
}

class _DollImages {
  _DollImages(this.doll, this.parts, this.faces);
  final DollParts doll;
  final List<_PartImage?> parts;
  final Map<Face, ui.Image> faces;

  void dispose() {
    for (final p in parts) {
      p?.dispose();
    }
  }
}

/// A move she makes: a pose for every moment, for [duration] seconds.
class _Move {
  _Move(this.sample, this.duration);
  final PoseFrame Function(double seconds) sample;
  final double duration;
  double start = 0;
}

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

class _DollViewState extends State<DollView> with TickerProviderStateMixin {
  AnimationController? _idle;
  Timer? _blinkTimer;
  bool _blinking = false;
  _DollImages? _images;
  String? _wantedKey;
  final _random = math.Random();

  Ticker? _ticker;
  final _repaint = _Repaint();
  final SwayPhysics _sway = SwayPhysics();
  final Stopwatch _shineClock = Stopwatch()..start();
  PoseFrame _frame = PoseFrame.rest;
  _Move? _move;
  Duration _lastTick = Duration.zero;

  /// Seconds of movement so far.
  double _time = 0;

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
    _startHeldPose();
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
  void didUpdateWidget(DollView old) {
    super.didUpdateWidget(old);
    if (old.dancing != widget.dancing) {
      widget.dancing ? _startDance() : _moveToHeldPose();
    } else if (old.waving != widget.waving) {
      _startHeldPose();
    } else if (old.outfit.pose != widget.outfit.pose && !widget.dancing) {
      _moveToHeldPose();
    }
    if (old.nudge != widget.nudge) _kick();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idle?.dispose();
    _ticker?.dispose();
    _repaint.dispose();
    _images?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- motion

  /// Her pose when she is not doing anything.
  PoseFrame get _heldFrame =>
      widget.waving ? wavingFrame(0.18) : heldPoseFrame(widget.outfit.pose);

  void _startHeldPose() {
    if (widget.dancing) {
      _startDance();
    } else if (widget.waving && GameMotion.idleAnimations) {
      _play(_Move(wavingFrame, double.infinity));
    } else {
      _move = null;
      _frame = _heldFrame;
      _repaint.ping();
    }
  }

  /// Moves from wherever she is now into her held pose.
  void _moveToHeldPose() {
    if (widget.waving) return _startHeldPose();
    final keys = poseMove(widget.outfit.pose, _frame);
    _play(_Move((t) => samplePoseKeys(keys, t), keys.last.time));
  }

  void _startDance() {
    final from = _frame;
    _play(_Move(danceMove(from, from, double.infinity), double.infinity));
  }

  void _play(_Move move) {
    move.start = _time;
    _move = move;
    _run();
  }

  void _run() {
    final ticker = _ticker ??= createTicker(_tick);
    if (ticker.isActive) return;
    _lastTick = Duration.zero;
    ticker.start();
  }

  void _kick() {
    final side = _random.nextBool() ? 1.0 : -1.0;
    _sway.kick(hair: side * 0.5, skirt: -side * 0.4, flare: 0.55);
    _run();
  }

  void _tick(Duration elapsed) {
    final dt = math.max(0.0, (elapsed - _lastTick).inMicroseconds / 1e6);
    _lastTick = elapsed;
    _time += dt;
    final move = _move;
    if (move != null) {
      final t = _time - move.start;
      if (t >= move.duration) {
        _move = null;
        _frame = _heldFrame;
      } else {
        _frame = move.sample(t);
      }
    }
    // A late frame should not throw the hair around.
    _sway.step(math.min(dt, 0.1), _frame);
    if (_move == null && _sway.still) {
      _ticker?.stop();
      _sway.reset();
    }
    _repaint.ping();
  }

  // -------------------------------------------------------------- pictures

  void _ensureImages(Size size, double ratio) {
    if (size.isEmpty) return;
    final key =
        '${outfitKey(widget.outfit)}|${size.width.round()}x${size.height.round()}'
        '|$ratio';
    if (key == _wantedKey) return;
    _wantedKey = key;
    _build(key, size, ratio);
  }

  Future<void> _build(String key, Size size, double ratio) async {
    try {
      final fit = FitTransform(kDollFrame, size);
      final pixelsPerUnit = fit.scale * ratio;
      final facePixels = fit.applyRect(kFaceRect).size * ratio;
      final doll = await dollParts(widget.outfit);
      final faceKey =
          '${facePixels.width.round()}x${facePixels.height.round()}'
          '|${widget.outfit.makeup.key}';
      final partsFuture = Future.wait([
        for (final part in doll.parts)
          part.kind == PartKind.face
              ? Future<_PartImage?>.value()
              : _partImage(part, pixelsPerUnit),
      ]);
      final faces = await Future.wait([
        for (final face in Face.values)
          artImages.get(
            'face|${face.name}|$faceKey',
            () => rasterizeDoll(doll.face(face), kFaceRect, facePixels),
          ),
      ]);
      final parts = await partsFuture;
      final images = _DollImages(doll, parts, {
        for (var i = 0; i < Face.values.length; i++) Face.values[i]: faces[i],
      });
      if (!mounted || key != _wantedKey) {
        images.dispose();
        return;
      }
      final old = _images;
      setState(() => _images = images);
      if (old != null) {
        // The last frame may still show the old pictures.
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    } catch (e) {
      debugPrint('Doll drawing failed: $e');
    }
  }

  Future<_PartImage> _partImage(DollPart part, double pixelsPerUnit) async {
    final image = await rasterizeDoll(
      part.layers,
      part.rect,
      part.rect.size * pixelsPerUnit,
    );
    final shine = await PartShine.build(part, pixelsPerUnit * 0.8);
    return _PartImage(image, shine);
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
            repaint: _repaint,
            face: widget.happy
                ? Face.happy
                : (_blinking ? Face.blink : Face.open),
            frame: () => _frame,
            sway: _sway,
            shineTime: () => GameMotion.idleAnimations
                ? _shineClock.elapsedMilliseconds / 1000
                : 0.8,
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
    required Listenable repaint,
    required this.face,
    required this.frame,
    required this.sway,
    required this.shineTime,
  }) : super(repaint: Listenable.merge([idle, repaint]));

  final _DollImages? images;
  final AnimationController? idle;
  final Face face;
  final PoseFrame Function() frame;
  final SwayPhysics sway;
  final double Function() shineTime;

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  static Rect _src(ui.Image image) =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final img = images;
    if (img == null || size.isEmpty) return;
    final fit = FitTransform(kDollFrame, size);
    final t = idle?.value ?? 0;
    final wave = 2 * math.pi * t;
    final time = shineTime();

    canvas.save();
    canvas.translate(fit.dx, fit.dy);
    canvas.scale(fit.scale);
    // Gentle breathing and swaying around the feet.
    if (t != 0) {
      canvas.translate(kFeet.dx, kFeet.dy);
      canvas.rotate(math.sin(wave) * 0.014);
      canvas.scale(1, 1 + math.sin(wave * 3) * 0.007);
      canvas.translate(-kFeet.dx, -kFeet.dy);
    }
    paintPosedDoll(
      canvas,
      img.doll,
      frame(),
      drawPart: (c, i) => _drawPart(c, img, i),
      drawFace: (c) {
        final faceImage = img.faces[face];
        if (faceImage != null) {
          c.drawImageRect(faceImage, _src(faceImage), kFaceRect, _paint);
        }
      },
      drawShine: (c, i) => img.parts[i]?.shine?.paint(c, time),
    );
    canvas.restore();
  }

  void _drawPart(Canvas canvas, _DollImages img, int i) {
    final pic = img.parts[i];
    if (pic == null) return;
    final part = img.doll.parts[i];
    if (part.bends) {
      final hair = part.kind == PartKind.hair;
      final swing = hair ? sway.hair : sway.skirt;
      final flare = hair ? sway.flare * 0.4 : sway.flare;
      if (swing.abs() > 1e-4 || flare.abs() > 1e-4) {
        _drawBent(canvas, pic, part, swing, flare);
        return;
      }
    }
    canvas.drawImageRect(pic.image, _src(pic.image), part.rect, _paint);
  }

  /// Draws hair or a skirt bent sideways ([swing]) and flared out
  /// ([flare]): nothing moves above [DollPart.bendTop], the ends most.
  void _drawBent(
    Canvas canvas,
    _PartImage pic,
    DollPart part,
    double swing,
    double flare,
  ) {
    const rows = 10;
    final r = part.rect;
    final top = part.bendTop.clamp(r.top, r.bottom);
    final length = r.bottom - top;
    final sx = pic.image.width / r.width;
    final sy = pic.image.height / r.height;
    final positions = Float32List((rows + 2) * 4);
    final uvs = Float32List((rows + 2) * 4);
    var k = 0;
    void row(double y, double u) {
      final shift = swing * length * math.pow(u, 1.6);
      final spread = flare * math.pow(u, 1.2);
      for (final x in [r.left, r.right]) {
        positions[k] = x + shift + (x - 100) * spread;
        positions[k + 1] = y;
        uvs[k] = (x - r.left) * sx;
        uvs[k + 1] = (y - r.top) * sy;
        k += 2;
      }
    }

    row(r.top, 0);
    for (var j = 0; j <= rows; j++) {
      row(top + length * j / rows, j / rows);
    }
    final vertices = ui.Vertices.raw(
      VertexMode.triangleStrip,
      positions,
      textureCoordinates: uvs,
    );
    canvas.drawVertices(
      vertices,
      BlendMode.dst,
      Paint()
        ..shader = pic.shader
        ..filterQuality = FilterQuality.medium,
    );
    vertices.dispose();
  }

  @override
  bool shouldRepaint(_DollPainter old) =>
      old.images != images || old.face != face;
}
