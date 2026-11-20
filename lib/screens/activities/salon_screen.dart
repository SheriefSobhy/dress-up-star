import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/doll_art.dart';
import '../../art/salon_art.dart';
import '../../data/game_config.dart';
import '../../models/outfit.dart';
import '../../painting/activity_backdrops.dart';
import '../../painting/particles.dart';
import '../../services/game_audio.dart';
import '../../widgets/big_round_button.dart';
import '../../widgets/live_doll.dart';
import 'activity_shell.dart';
import 'makeup_screen.dart' show closeUpOutfit;

/// The part of doll space shown in the salon (her head and long hair).
const Rect kSalonFrame = Rect.fromLTRB(14, 24, 186, 292);

/// The Hair Salon: wash, dry, cut, curl or straighten and color the hair,
/// in any order. "Grow back" makes the hair long again.
class SalonScreen extends StatefulWidget {
  const SalonScreen({super.key, required this.outfit, required this.audio});

  final Outfit outfit;
  final GameAudio audio;

  @override
  State<SalonScreen> createState() => _SalonScreenState();
}

class _SalonScreenState extends State<SalonScreen>
    with TickerProviderStateMixin {
  static const int _shampoo = 0;
  static const int _shower = 1;
  static const int _dryer = 2;
  static const int _scissors = 3;
  static const int _curler = 4;
  static const int _spray = 5;

  static final List<ActivityTool> _tools = [
    const ActivityTool(id: 'shampoo', art: 'shampoo', color: Color(0xFFC9A8FF)),
    const ActivityTool(
      id: 'shower',
      art: 'shower',
      color: Color(0xFF7FD8F0),
      tip: Offset(0.33, 0.67),
    ),
    const ActivityTool(
      id: 'dryer',
      art: 'dryer',
      color: Color(0xFFFF9EC8),
      artColor: Color(0xFFFF7EB6),
    ),
    const ActivityTool(
      id: 'scissors',
      art: 'scissors',
      color: Color(0xFFFFC27A),
    ),
    ActivityTool(
      id: 'curler',
      art: 'curler',
      color: const Color(0xFFB79CFF),
      options: [
        ToolOption(color: Colors.white, paint: (c, s) => _curlIcon(c, s)),
        ToolOption(color: Colors.white, paint: (c, s) => _straightIcon(c, s)),
      ],
    ),
    ActivityTool(
      id: 'spray',
      art: 'spray',
      color: const Color(0xFF8EE08A),
      tinted: true,
      options: [
        for (final c in hairDyeColors)
          ToolOption(color: c.color, rainbow: c.rainbow),
      ],
    ),
  ];

  /// Where each tool works (a little sparkle shows it when picked).
  static const List<Offset> _targets = [
    Offset(100, 60),
    Offset(100, 60),
    Offset(150, 150),
    Offset(48, 230),
    Offset(150, 190),
    Offset(60, 120),
  ];

  late final Outfit _start = _salonOutfit(widget.outfit);
  late SalonHair _salon = _start.salon;
  SpotGrid _bubbles = SpotGrid.none;
  SpotGrid _wet = SpotGrid.none;

  /// What "undo all" took away (the button can bring it back).
  (SalonHair, SpotGrid, SpotGrid)? _undone;

  late final ParticleSystem _particles = ParticleSystem(this);
  final GlobalKey<ActivityShellState> _shell = GlobalKey();
  late final Blinker _blinker = Blinker(() {
    if (mounted) setState(() {});
  });

  /// The hair dryer's wind: strength (0..1) and the sway it causes.
  late final AnimationController _wind = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  final ValueNotifier<double> _sway = ValueNotifier(0);
  double _windSide = 1;
  double _windPhase = 0;

  /// The salon works on the long hair (in her own hair color).
  static Outfit _salonOutfit(Outfit o) {
    final long = findItem(salonHairId);
    if (long == null || o[Slot.hair]?.item.id == salonHairId) return o;
    return o.wear(long).copyWith(salon: SalonHair.natural);
  }

  Color get _hairColor => _start[Slot.hair]!.color;

  @override
  void initState() {
    super.initState();
    _blinker.start();
    _wind.addListener(_updateSway);
  }

  @override
  void dispose() {
    _blinker.dispose();
    _wind.dispose();
    _sway.dispose();
    _particles.dispose();
    super.dispose();
  }

  void _updateSway() {
    _sway.value = _wind.value * _windSide * (0.7 + 0.3 * math.sin(_windPhase));
  }

  void _set({SalonHair? salon, SpotGrid? bubbles, SpotGrid? wet}) {
    setState(() {
      _salon = salon ?? _salon;
      _bubbles = bubbles ?? _bubbles;
      _wet = wet ?? _wet;
      _undone = null;
    });
  }

  /// Hair spots the tool touches (only where hair can be seen).
  List<int> _hairSpots(Offset from, Offset to, double radius) => [
    for (final i in hairZone.touched(from, to, radius))
      if (_salon.hairAt(hairZone.spots[i])) i,
  ];

  StrokeResult _stroke(int tool, int option, Offset from, Offset to) {
    switch (tool) {
      case _shampoo:
        final spots = _hairSpots(from, to, 12);
        final next = _bubbles.set(spots, 0);
        if (next == _bubbles) return StrokeResult.none;
        _set(bubbles: next);
        _particles.emit(ParticleKind.bubble, to, count: 2, size: 4);
        return const StrokeResult(changed: true, sound: Sfx.bubble);

      case _shower:
        _particles.emit(
          ParticleKind.drop,
          to,
          count: 3,
          size: 2.4,
          direction: const Offset(-25, 40),
        );
        final spots = _hairSpots(from, to, 14);
        final bubbles = _bubbles.set(spots, null);
        final wet = _wet.set(spots, 0);
        if (bubbles == _bubbles && wet == _wet) {
          return const StrokeResult(sound: Sfx.water);
        }
        _set(bubbles: bubbles, wet: wet);
        return const StrokeResult(changed: true, sound: Sfx.water);

      case _dryer:
        _blow(from, to);
        final spots = _hairSpots(from, to, 16);
        final drying = spots.where((i) => _wet[i] != null).toList();
        final bubbles = _bubbles.set(spots, null);
        if (drying.isEmpty && bubbles == _bubbles) {
          return const StrokeResult(sound: Sfx.blow);
        }
        _set(
          bubbles: bubbles,
          wet: _wet.set(drying, null),
          salon: _salon.copyWith(shine: _salon.shine.set(drying, 0)),
        );
        final dry = drying.isNotEmpty && _wet.isEmpty;
        return StrokeResult(
          changed: true,
          sound: Sfx.blow,
          finished: dry ? [to] : const [],
        );

      case _scissors:
        return _cut(to);

      case _curler:
        final side = hairSide(to);
        final curly = option == 0;
        if (!_salon.hairAt(to) || _salon.curl(side) == curly) {
          return StrokeResult.none;
        }
        _set(salon: _salon.withCurl(side, curly));
        _particles.emit(ParticleKind.steam, to, count: 5, size: 4);
        return StrokeResult(changed: true, finished: [to]);

      case _spray:
        final tool = hairDyeColors[option];
        _particles.emit(
          ParticleKind.mist,
          to,
          count: 2,
          size: 4,
          color: tool.rainbow ? rainbowAt(to.dy) : tool.color,
        );
        final spots = _hairSpots(from, to, 9);
        final dye = _salon.dye.set(spots, option);
        if (dye == _salon.dye) return StrokeResult.none;
        _set(salon: _salon.copyWith(dye: dye));
        return const StrokeResult(changed: true);
    }
    return StrokeResult.none;
  }

  void _blow(Offset from, Offset to) {
    _windSide = to.dx < 100 ? 1 : -1;
    _windPhase += 0.6;
    _wind.value = 1;
    _updateSway();
    _particles.emit(
      ParticleKind.air,
      to,
      size: 3.5,
      direction: Offset(-60 * _windSide, 18),
      spread: 0.3,
    );
  }

  /// Snip! The side the scissors touch gets shorter.
  StrokeResult _cut(Offset at) {
    if (!_salon.hairAt(at) || at.dy < 120) return StrokeResult.none;
    final side = hairSide(at);
    final length = at.dy > 190 ? 1 : 2;
    if (length <= _salon.cut(side)) return StrokeResult.none;
    var next = _salon.withCut(side, length);
    // Paint and shine on the cut-off hair go with it.
    final hem = next.backHem(side);
    bool gone(int i) {
      final p = hairZone.spots[i];
      return hairSide(p) == side && p.dy > hem + 4;
    }

    next = next.copyWith(
      dye: next.dye.clearWhere(gone),
      shine: next.shine.clearWhere(gone),
    );
    _set(
      salon: next,
      bubbles: _bubbles.clearWhere(gone),
      wet: _wet.clearWhere(gone),
    );
    _particles.emit(
      ParticleKind.hair,
      at,
      count: 7,
      size: 6,
      color: _hairColor,
    );
    return const StrokeResult(changed: true, sound: Sfx.snip);
  }

  void _lift(int tool) {
    if (tool == _dryer) {
      _wind.animateTo(0, curve: Curves.easeOut);
    }
  }

  void _growBack() {
    if (_salon.cutLeft == 0 && _salon.cutRight == 0) {
      widget.audio.play(Sfx.tap);
      return;
    }
    _set(salon: _salon.copyWith(cutLeft: 0, cutRight: 0));
    for (final x in const [40.0, 160.0]) {
      _particles.burst(Offset(x, 240), count: 10, size: 4);
    }
    _shell.currentState?.celebrate(at: const Offset(100, 250));
  }

  void _undo() {
    final undone = _undone;
    setState(() {
      if (undone != null) {
        _salon = undone.$1;
        _bubbles = undone.$2;
        _wet = undone.$3;
        _undone = null;
      } else if (!_salon.isNatural || !_bubbles.isEmpty || !_wet.isEmpty) {
        _undone = (_salon, _bubbles, _wet);
        _salon = SalonHair.natural;
        _bubbles = SpotGrid.none;
        _wet = SpotGrid.none;
      }
    });
    _particles.burst(const Offset(100, 120), count: 12, size: 4);
  }

  void _done() {
    widget.audio.play(Sfx.itemOn);
    final untouched = _salon.isNatural && widget.outfit.salon.isNatural;
    Navigator.of(context).pop(
      untouched
          ? widget.outfit
          : _salonOutfit(widget.outfit).copyWith(salon: _salon),
    );
  }

  void _paintForeground(Canvas canvas) {
    if (!_wet.isEmpty) paintWetDrops(canvas, _wet);
    if (!_bubbles.isEmpty) paintBubbles(canvas, _bubbles);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ActivityShell(
      key: _shell,
      audio: widget.audio,
      tools: _tools,
      frame: kSalonFrame,
      particles: _particles,
      wallColors: const [Color(0xFFDDF7EF), Color(0xFFC4EEE2)],
      backdrop: const SalonBackdrop(),
      undoRestores: _undone != null,
      onUndo: _undo,
      onDone: _done,
      onStroke: _stroke,
      onLift: (tool, option, at) {
        _lift(tool);
        return StrokeResult.none;
      },
      onToolChanged: (i) =>
          _particles.emit(ParticleKind.sparkle, _targets[i], count: 6, size: 4),
      extraButtons: [
        BigRoundButton(
          key: const Key('grow_button'),
          icon: Icons.auto_fix_high_rounded,
          color: const Color(0xFF5CCB9E),
          semanticLabel: 'Grow back',
          size: width < 380 ? 56 : 64,
          onTap: _growBack,
        ),
      ],
      stageBuilder: (context, info) => LiveDoll(
        outfit: closeUpOutfit(_start).copyWith(salon: _salon),
        frame: kSalonFrame,
        face: info.happy
            ? Face.happy
            : (_blinker.blinking && !info.touching ? Face.blink : Face.open),
        bounce: info.bounce,
        hairSway: _sway,
        wetHair: _wet,
        foreground: _paintForeground,
      ),
    );
  }
}

void _curlIcon(Canvas canvas, Size size) {
  final c = size.center(Offset.zero);
  final path = Path();
  for (var k = 0; k <= 30; k++) {
    final a = k / 30 * math.pi * 3.2;
    final r = size.width * (0.05 + k / 30 * 0.28);
    final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
    k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8A5CD6),
  );
}

void _straightIcon(Canvas canvas, Size size) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.09
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF8A5CD6);
  for (final x in const [0.32, 0.5, 0.68]) {
    canvas.drawLine(
      Offset(size.width * x, size.height * 0.24),
      Offset(size.width * x, size.height * 0.76),
      paint,
    );
  }
}
