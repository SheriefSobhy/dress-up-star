import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/doll_art.dart';
import '../../art/nails_art.dart';
import '../../data/game_config.dart';
import '../../models/outfit.dart';
import '../../painting/activity_backdrops.dart';
import '../../painting/particles.dart';
import '../../services/game_audio.dart';
import '../../widgets/live_doll.dart';
import 'activity_shell.dart';
import 'makeup_screen.dart' show closeUpOutfit;

/// The part of hand space shown on the Nails screen.
const Rect kHandFrame = Rect.fromLTRB(28, 46, 300, 374);

/// Her face in the little round picture at the top.
const Rect _faceFrame = Rect.fromLTRB(36, 40, 164, 168);

/// Nails: soak, file, paint (each nail its own color), decorate and dry
/// until they shine.
class NailsScreen extends StatefulWidget {
  const NailsScreen({super.key, required this.outfit, required this.audio});

  final Outfit outfit;
  final GameAudio audio;

  @override
  State<NailsScreen> createState() => _NailsScreenState();
}

class _NailsScreenState extends State<NailsScreen>
    with TickerProviderStateMixin {
  static const int _soak = 0;
  static const int _file = 1;
  static const int _polish = 2;
  static const int _deco = 3;
  static const int _dryer = 4;

  static final List<ActivityTool> _tools = [
    const ActivityTool(
      id: 'soak',
      art: 'soak',
      color: Color(0xFF7FD8F0),
      tip: Offset(0.5, 0.5),
    ),
    const ActivityTool(id: 'file', art: 'file', color: Color(0xFFC9A8FF)),
    ActivityTool(
      id: 'polish',
      art: 'polish',
      color: const Color(0xFFFF8FB8),
      tinted: true,
      options: [
        for (final c in nailColors)
          ToolOption(color: c.color, glitter: c.glitter),
      ],
    ),
    ActivityTool(
      id: 'deco',
      art: 'gems',
      color: const Color(0xFFFFD84D),
      tip: const Offset(0.5, 0.5),
      carriesOption: true,
      options: [
        for (final d in NailDeco.values)
          ToolOption(
            color: Colors.white,
            paint: (canvas, size) => paintNailDeco(
              canvas,
              d,
              size.center(Offset.zero),
              size.width * 0.6,
            ),
          ),
      ],
    ),
    const ActivityTool(
      id: 'dryer',
      art: 'dryer',
      color: Color(0xFFB79CFF),
      artColor: Color(0xFFB47CFF),
    ),
  ];

  late NailSet _nails = widget.outfit.nails;

  /// Fingers that were dipped in the bubble bowl (only while here).
  Set<int> _soaked = {};

  /// How much each nail was rubbed with the file.
  final Map<int, double> _filing = {};

  NailSet? _undone;
  late final ParticleSystem _particles = ParticleSystem(this);
  late final Blinker _blinker = Blinker(() {
    if (mounted) setState(() {});
  });
  late final Outfit _face = closeUpOutfit(widget.outfit);

  @override
  void initState() {
    super.initState();
    _blinker.start();
  }

  @override
  void dispose() {
    _blinker.dispose();
    _particles.dispose();
    super.dispose();
  }

  void _set(NailSet n) {
    setState(() {
      _nails = n;
      _undone = null;
    });
  }

  StrokeResult _stroke(int tool, int option, Offset from, Offset to) {
    switch (tool) {
      case _soak:
        _particles.emit(ParticleKind.bubble, to, count: 1, size: 6);
        final n = nailAt(to, slack: 1.3);
        if (n == null || _soaked.contains(n)) {
          return const StrokeResult(sound: Sfx.water);
        }
        setState(() => _soaked = {..._soaked, n});
        _particles.emit(ParticleKind.bubble, to, count: 4, size: 6);
        return const StrokeResult(changed: true, sound: Sfx.water);

      case _file:
        final n = _nailTipAt(to);
        if (n == null || _nails.filed[n] != null) return StrokeResult.none;
        _filing[n] = (_filing[n] ?? 0) + (to - from).distance;
        _particles.emit(
          ParticleKind.dust,
          to,
          count: 2,
          size: 3,
          color: const Color(0xFFF6D6DE),
        );
        if (_filing[n]! < 30) return const StrokeResult(sound: Sfx.brush);
        _set(_nails.copyWith(filed: _nails.filed.set([n], 0)));
        return StrokeResult(changed: true, finished: [kFingers[n].nailCenter]);

      case _polish:
        final touched = nailZone.touched(from, to, 7);
        if (touched.isEmpty) return StrokeResult.none;
        final painted = _nails.polish.set(touched, option);
        if (painted == _nails.polish) return StrokeResult.none;
        final (done, finished) = nailZone.complete(
          painted,
          option,
          threshold: 0.5,
        );
        _set(_nails.copyWith(polish: done));
        return StrokeResult(
          changed: true,
          finished: [for (final n in finished) kFingers[n].nailCenter],
        );

      case _dryer:
        _particles.emit(
          ParticleKind.air,
          to,
          size: 6,
          direction: const Offset(-70, -50),
          spread: 0.3,
        );
        final shiny = [
          for (var n = 0; n < kFingers.length; n++)
            if ((kFingers[n].nailCenter - to).distance < 34 &&
                _nails.shine[n] == null &&
                _nails.colorOf(n) != null)
              n,
        ];
        if (shiny.isEmpty) return const StrokeResult(sound: Sfx.blow);
        _set(_nails.copyWith(shine: _nails.shine.set(shiny, 0)));
        return StrokeResult(
          changed: true,
          sound: Sfx.blow,
          finished: [for (final n in shiny) kFingers[n].nailCenter],
        );
    }
    return StrokeResult.none;
  }

  /// The nail whose tip is at [p] (where the file works).
  int? _nailTipAt(Offset p) {
    for (var n = 0; n < kFingers.length; n++) {
      final f = kFingers[n];
      final tip = f.nailPoint(Offset(0, -f.nailLength * 0.55));
      if ((tip - p).distance < f.width * 0.6) return n;
    }
    return null;
  }

  StrokeResult _lift(int tool, int option, Offset at) {
    if (tool != _deco) return StrokeResult.none;
    final n = nailAt(at, slack: 1.2);
    if (n == null || _nails.deco[n] == option) return StrokeResult.none;
    _set(_nails.copyWith(deco: _nails.deco.set([n], option)));
    return StrokeResult(changed: true, finished: [kFingers[n].nailCenter]);
  }

  void _undo() {
    final undone = _undone;
    setState(() {
      if (undone != null) {
        _nails = undone;
        _undone = null;
      } else if (!_nails.isEmpty || _soaked.isNotEmpty) {
        _undone = _nails;
        _nails = NailSet.none;
        _soaked = {};
        _filing.clear();
      }
    });
    _particles.burst(const Offset(165, 150), count: 12, size: 8);
  }

  void _done() {
    widget.audio.play(Sfx.itemOn);
    Navigator.of(context).pop(widget.outfit.copyWith(nails: _nails));
  }

  @override
  Widget build(BuildContext context) {
    return ActivityShell(
      audio: widget.audio,
      tools: _tools,
      frame: kHandFrame,
      particles: _particles,
      wallColors: const [Color(0xFFFFEADF), Color(0xFFFFD9C7)],
      backdrop: const NailsBackdrop(),
      undoRestores: _undone != null,
      onUndo: _undo,
      onDone: _done,
      onStroke: _stroke,
      onLift: _lift,
      onToolChanged: (i) {
        for (final f in kFingers) {
          _particles.emit(ParticleKind.sparkle, f.nailCenter, size: 6);
        }
      },
      topCenter: (context, info) => _FaceBubble(
        outfit: _face,
        face: info.happy
            ? Face.happy
            : (_blinker.blinking ? Face.blink : Face.open),
        bounce: info.bounce,
      ),
      stageBuilder: (context, info) => CustomPaint(
        size: Size.infinite,
        painter: _HandPainter(_nails, _soaked, info.bounce),
      ),
    );
  }
}

/// Her face in a round frame, smiling when something is done.
class _FaceBubble extends StatelessWidget {
  const _FaceBubble({
    required this.outfit,
    required this.face,
    required this.bounce,
  });

  final Outfit outfit;
  final Face face;
  final Animation<double> bounce;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width < 380 ? 64.0 : 76.0;
    return Container(
      key: const Key('nails_face'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFE3F1)],
        ),
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33B06FA0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: LiveDoll(
          outfit: outfit,
          frame: _faceFrame,
          face: face,
          bounce: bounce,
        ),
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  _HandPainter(this.nails, this.soaked, this.bounce) : super(repaint: bounce);

  final NailSet nails;
  final Set<int> soaked;
  final Animation<double> bounce;

  @override
  void paint(Canvas canvas, Size size) {
    final fit = FitTransform(kHandFrame, size);
    canvas.save();
    canvas.translate(fit.dx, fit.dy);
    canvas.scale(fit.scale);
    final wiggle = bounce.value;
    if (wiggle != 0) {
      // A happy little wave of the hand.
      const pivot = Offset(155, 340);
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(math.sin(wiggle * math.pi) * 0.03);
      canvas.translate(-pivot.dx, -pivot.dy);
    }
    paintHand(canvas);
    paintNails(canvas, nails);
    for (final n in soaked) {
      _foam(canvas, kFingers[n]);
    }
    canvas.restore();
  }

  void _foam(Canvas canvas, Finger f) {
    final rnd = math.Random(f.tip.dx.round());
    final fill = Paint()..color = const Color(0xCCFFFFFF);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF9AD6FF);
    for (var i = 0; i < 4; i++) {
      final along = f.direction * (-(f.width * 0.9) - rnd.nextDouble() * 12);
      final across =
          Offset(-f.direction.dy, f.direction.dx) *
          ((rnd.nextDouble() - 0.5) * f.width);
      final c = f.tip + along + across;
      final r = 3.5 + rnd.nextDouble() * 4;
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, rim);
      canvas.drawCircle(
        c - Offset(r * 0.35, r * 0.35),
        r * 0.25,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(_HandPainter old) =>
      old.nails != nails || old.soaked != soaked;
}
