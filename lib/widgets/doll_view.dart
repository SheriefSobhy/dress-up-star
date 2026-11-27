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
/// ready-made images (fast even on low-end phones). The 2.5D shading is
/// baked into those images; a soft shadow stays on the floor under her.
class DollView extends StatefulWidget {
  const DollView({
    super.key,
    required this.outfit,
    this.happy = false,
    this.waving = false,
    this.nudge = 0,
    this.dancing = false,
    this.hop = 0,
    this.turn = 0,
    this.turnSide = 1,
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

  /// How far (screen pixels, negative is up) the whole picture is raised by
  /// a hop, so her floor shadow stays on the floor.
  final double hop;

  /// Change this number to make her turn a little (a 3/4 view) and back,
  /// toward [turnSide] (-1 left, 1 right).
  final int turn;
  final int turnSide;

  /// How long one turn there and back takes.
  static const Duration turnTime = Duration(milliseconds: 1500);

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
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: DollView.turnTime,
  );
  int _turnSide = 1;
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
      );
      if (GameMotion.idleLoops) _idle!.repeat();
      GameMotion.lite.addListener(_onLite);
      _scheduleBlink();
    }
    _startHeldPose();
  }

  /// Lite mode: she stands still (no breathing) and the sparkles rest.
  void _onLite() {
    final idle = _idle;
    if (idle == null) return;
    if (GameMotion.idleLoops) {
      idle.repeat();
    } else {
      idle.stop();
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
    if (old.turn != widget.turn) {
      _turnSide = widget.turnSide;
      _turn.forward(from: 0);
      _sway.kick(hair: _turnSide * 0.45, skirt: -_turnSide * 0.35, flare: 0.3);
      _run();
    }
  }

  @override
  void dispose() {
    GameMotion.lite.removeListener(_onLite);
    _blinkTimer?.cancel();
    _idle?.dispose();
    _turn.dispose();
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
          '|${widget.outfit.makeup.key}|${widget.outfit.body.key}';
      final pictures = await Future.wait([
        for (final part in doll.parts)
          Future.wait(part.layers.map(ArtLibrary.instance.picture)),
      ]);
      final partsFuture = Future.wait([
        for (var i = 0; i < doll.parts.length; i++)
          doll.parts[i].kind == PartKind.face
              ? Future<_PartImage?>.value()
              : _partImage(doll, pictures, i, pixelsPerUnit),
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

  Future<_PartImage> _partImage(
    DollParts doll,
    List<List<ui.Picture>> pictures,
    int index,
    double pixelsPerUnit,
  ) async {
    final part = doll.parts[index];
    final pixels = part.rect.size * pixelsPerUnit;
    final picture = recordPicture((canvas) {
      final fit = FitTransform(part.rect, pixels);
      canvas.translate(fit.dx, fit.dy);
      canvas.scale(fit.scale);
      paintPartWithDepth(canvas, doll, pictures, index);
    });
    final image = await picture.toImage(
      math.max(1, pixels.width.round()),
      math.max(1, pixels.height.round()),
    );
    picture.dispose();
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
            shineTime: () => GameMotion.idleLoops
                ? _shineClock.elapsedMilliseconds / 1000
                : 0.8,
            turn: _turn,
            turnSide: _turnSide,
            hop: widget.hop,
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
    required this.turn,
    required this.turnSide,
    required this.hop,
  }) : super(repaint: Listenable.merge([idle, repaint, turn]));

  final _DollImages? images;
  final AnimationController? idle;
  final Face face;
  final PoseFrame Function() frame;
  final SwayPhysics sway;
  final double Function() shineTime;
  final Animation<double> turn;
  final int turnSide;
  final double hop;

  /// How turned she is now: she turns, holds it a moment and turns back.
  double get _turned {
    final t = turn.value;
    if (t <= 0 || t >= 1) return 0;
    final u = t < 0.3 ? t / 0.3 : (t > 0.65 ? (1 - t) / 0.35 : 1.0);
    return easeInOut(u) * turnSide;
  }

  /// How far (doll units) each part slides when turned: what is nearer to
  /// us slides toward the side she looks at, what is behind slides away.
  static List<double> _depthShifts(DollParts doll) {
    final face = doll.parts.indexWhere((p) => p.kind == PartKind.face);
    final body = doll.parts.indexWhere(
      (p) => p.layers.any((l) => l.asset.endsWith('/body.svg')),
    );
    return [
      for (var i = 0; i < doll.parts.length; i++)
        switch (doll.parts[i].kind) {
          _ when i < body => -6.0,
          PartKind.face => 7.0,
          PartKind.hair => 5.0,
          PartKind.body when i == face - 1 => 3.5,
          PartKind.body when i > face => 6.0,
          _ => 0.0,
        },
    ];
  }

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

    final pose = frame();
    final turned = _turned;
    final shifts = _depthShifts(img.doll);
    void shifted(Canvas c, int i, VoidCallback draw) {
      if (turned == 0 || shifts[i] == 0) return draw();
      c.save();
      c.translate(shifts[i] * turned, 0);
      draw();
      c.restore();
    }

    canvas.save();
    canvas.translate(fit.dx, fit.dy);
    canvas.scale(fit.scale);
    paintGroundShadow(
      canvas,
      pose: pose,
      lift: -hop / fit.scale,
      drop: -hop / fit.scale,
      turn: turned,
    );
    // Turned a little: narrower, with a slight lean into the turn.
    if (turned != 0) {
      canvas.translate(kFeet.dx, kFeet.dy);
      canvas.skew(-turned * 0.025, 0);
      canvas.scale(1 - turned.abs() * 0.13, 1);
      canvas.translate(-kFeet.dx, -kFeet.dy);
    }
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
      pose,
      drawPart: (c, i) => shifted(c, i, () => _drawPart(c, img, i)),
      drawFace: (c) {
        final faceImage = img.faces[face];
        if (faceImage == null) return;
        final at = img.doll.parts.indexWhere((p) => p.kind == PartKind.face);
        shifted(c, at, () {
          c.drawImageRect(faceImage, _src(faceImage), kFaceRect, _paint);
        });
      },
      drawShine: (c, i) {
        final shine = img.parts[i]?.shine;
        if (shine != null) shifted(c, i, () => shine.paint(c, time));
      },
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
    // The vertices have no colors, so only the picture (the shader) is drawn
    // and the blend mode makes no difference to the result. It must not be
    // BlendMode.dst: Impeller (Android) then skips binding the picture and
    // the app crashes ("bad_function_call" in Canvas::DrawVertices).
    canvas.drawVertices(
      vertices,
      BlendMode.srcOver,
      Paint()
        ..shader = pic.shader
        ..filterQuality = FilterQuality.medium,
    );
    vertices.dispose();
  }

  @override
  bool shouldRepaint(_DollPainter old) =>
      old.images != images || old.face != face || old.hop != hop;
}
