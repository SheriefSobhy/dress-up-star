import 'package:flutter/material.dart';

import '../../art/beauty_art.dart';
import '../../art/doll_art.dart';
import '../../data/game_config.dart';
import '../../models/outfit.dart';
import '../../painting/activity_backdrops.dart';
import '../../painting/particles.dart';
import '../../services/game_audio.dart';
import '../../widgets/live_doll.dart';
import 'activity_shell.dart';

/// The part of doll space shown in the Makeup close-up (her face).
const Rect kMakeupFrame = Rect.fromLTRB(16, 40, 184, 176);

/// The doll for a close-up: hats and things in her hand are put away while
/// she has her makeover (they come back afterwards). Her glasses and
/// jewelry stay on, unless [glasses] is false.
Outfit closeUpOutfit(Outfit o, {bool glasses = true}) {
  final worn = Map.of(o.worn)
    ..remove(Slot.head)
    ..remove(Slot.hat)
    ..remove(Slot.hand);
  if (!glasses) worn.remove(Slot.eyes);
  return o.copyWith(worn: worn);
}

/// Makeup: lipstick, blush, eyeshadow, eyelashes, face stickers and a
/// sponge that wipes it all off again.
class MakeupScreen extends StatefulWidget {
  const MakeupScreen({super.key, required this.outfit, required this.audio});

  final Outfit outfit;
  final GameAudio audio;

  @override
  State<MakeupScreen> createState() => _MakeupScreenState();
}

class _MakeupScreenState extends State<MakeupScreen>
    with TickerProviderStateMixin {
  static const int _lipstick = 0;
  static const int _blush = 1;
  static const int _shadow = 2;
  static const int _lashes = 3;
  static const int _stickers = 4;
  static const int _sponge = 5;

  static List<ToolOption> _colors(List<ToolColor> list) => [
    for (final c in list) ToolOption(color: c.color, glitter: c.glitter),
  ];

  static final List<ActivityTool> _tools = [
    ActivityTool(
      id: 'lipstick',
      art: 'lipstick',
      color: const Color(0xFFFF8FB8),
      tinted: true,
      options: _colors(lipstickColors),
    ),
    ActivityTool(
      id: 'blush',
      art: 'blush',
      color: const Color(0xFFFFB38A),
      tinted: true,
      options: _colors(blushColors),
    ),
    ActivityTool(
      id: 'eyeshadow',
      art: 'eyeshadow',
      color: const Color(0xFFB79CFF),
      tinted: true,
      options: _colors(eyeshadowColors),
    ),
    ActivityTool(
      id: 'lashes',
      art: 'mascara',
      color: const Color(0xFF8FB4FF),
      options: [
        for (var s = 1; s <= lashStyleCount; s++)
          ToolOption(
            color: Colors.white,
            paint: (canvas, size) => paintLashPreview(canvas, size, s),
          ),
      ],
    ),
    ActivityTool(
      id: 'stickers',
      art: 'stickers',
      color: const Color(0xFFFFD84D),
      tip: const Offset(0.5, 0.5),
      carriesOption: true,
      options: [
        for (final kind in StickerKind.values)
          ToolOption(
            color: Colors.white,
            paint: (canvas, size) => paintSticker(
              canvas,
              kind,
              size.center(Offset.zero),
              size.width * 0.62,
            ),
          ),
      ],
    ),
    const ActivityTool(
      id: 'sponge',
      art: 'sponge',
      color: Color(0xFF7FD8F0),
      tip: Offset(0.42, 0.58),
    ),
  ];

  /// Where each tool works (a little sparkle shows it when picked).
  static const List<Offset> _targets = [
    kMouth,
    kLeftCheek,
    Offset(78, 104),
    kLeftEye,
    kFaceCenter,
    kFaceCenter,
  ];

  late Makeup _makeup = widget.outfit.makeup;

  /// What "undo all" took away (the button can bring it back).
  Makeup? _undone;
  late final ParticleSystem _particles = ParticleSystem(this);
  final GlobalKey<ActivityShellState> _shell = GlobalKey();
  late final Blinker _blinker = Blinker(() {
    if (mounted) setState(() {});
  });
  late final Outfit _closeUp = closeUpOutfit(widget.outfit);

  /// Glasses come off while she paints her eyes, so nothing is in the way.
  late final Outfit _noGlasses = closeUpOutfit(widget.outfit, glasses: false);
  int _tool = 0;
  bool get _eyeTool => _tool == _shadow || _tool == _lashes;

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

  void _set(Makeup m) {
    setState(() {
      _makeup = m;
      _undone = null;
    });
  }

  StrokeResult _paintZone(
    SpotZone zone,
    SpotGrid grid,
    int color,
    Offset from,
    Offset to,
    double radius,
    Makeup Function(SpotGrid) apply,
  ) {
    final touched = zone.touched(from, to, radius);
    if (touched.isEmpty) return StrokeResult.none;
    final painted = grid.set(touched, color);
    if (painted == grid) return StrokeResult.none;
    final (done, finished) = zone.complete(painted, color, threshold: 0.55);
    _set(apply(done));
    return StrokeResult(
      changed: true,
      finished: [for (final r in finished) zone.regionCenter(r)],
    );
  }

  StrokeResult _stroke(int tool, int option, Offset from, Offset to) {
    final m = _makeup;
    switch (tool) {
      case _lipstick:
        return _paintZone(
          lipsZone,
          m.lips,
          option,
          from,
          to,
          4.5,
          (g) => m.copyWith(lips: g),
        );
      case _blush:
        return _paintZone(
          blushZone,
          m.blush,
          option,
          from,
          to,
          7,
          (g) => m.copyWith(blush: g),
        );
      case _shadow:
        return _paintZone(
          shadowZone,
          m.shadow,
          option,
          from,
          to,
          5,
          (g) => m.copyWith(shadow: g),
        );
      case _lashes:
        final eye = eyeAt(to);
        final style = option + 1;
        if (eye == null) return StrokeResult.none;
        if ((eye == 0 ? m.lashLeft : m.lashRight) == style) {
          return StrokeResult.none;
        }
        _set(
          eye == 0 ? m.copyWith(lashLeft: style) : m.copyWith(lashRight: style),
        );
        return StrokeResult(
          changed: true,
          finished: [eye == 0 ? kLeftEye : kRightEye],
        );
      case _sponge:
        return _wipe(from, to);
      default:
        return StrokeResult.none;
    }
  }

  StrokeResult _wipe(Offset from, Offset to) {
    const r = 8.0;
    final m = _makeup;
    final next = m.copyWith(
      lips: m.lips.set(lipsZone.touched(from, to, r), null),
      blush: m.blush.set(blushZone.touched(from, to, r), null),
      shadow: m.shadow.set(shadowZone.touched(from, to, r), null),
      lashLeft: eyeAt(to) == 0 ? 0 : m.lashLeft,
      lashRight: eyeAt(to) == 1 ? 0 : m.lashRight,
      stickers: [
        for (final s in m.stickers)
          if ((s.position - to).distance > r + 4) s,
      ],
    );
    if (next == m) return StrokeResult.none;
    _set(next);
    _particles.emit(ParticleKind.bubble, to, count: 2, size: 3);
    return const StrokeResult(changed: true, sound: Sfx.bubble);
  }

  StrokeResult _lift(int tool, int option, Offset at) {
    if (tool != _stickers || !onFace(at)) return StrokeResult.none;
    final p = clampToFace(at);
    _set(_makeup.addSticker(FaceSticker(StickerKind.values[option], p)));
    return StrokeResult(changed: true, finished: [p]);
  }

  void _undo() {
    final undone = _undone;
    setState(() {
      if (undone != null) {
        _makeup = undone;
        _undone = null;
      } else if (!_makeup.isEmpty) {
        _undone = _makeup;
        _makeup = Makeup.none;
      }
    });
    _particles.burst(kFaceCenter, count: 12, size: 3);
  }

  void _done() {
    widget.audio.play(Sfx.itemOn);
    Navigator.of(context).pop(widget.outfit.copyWith(makeup: _makeup));
  }

  @override
  Widget build(BuildContext context) {
    return ActivityShell(
      key: _shell,
      audio: widget.audio,
      tools: _tools,
      frame: kMakeupFrame,
      particles: _particles,
      wallColors: const [Color(0xFFFFE6F2), Color(0xFFFFD3E8)],
      backdrop: const MakeupBackdrop(),
      undoRestores: _undone != null,
      onUndo: _undo,
      onDone: _done,
      onStroke: _stroke,
      onLift: _lift,
      onToolChanged: (i) {
        setState(() => _tool = i);
        _particles.emit(ParticleKind.sparkle, _targets[i], count: 6, size: 2.4);
      },
      stageBuilder: (context, info) => LiveDoll(
        outfit: (_eyeTool ? _noGlasses : _closeUp).copyWith(makeup: _makeup),
        frame: kMakeupFrame,
        face: info.happy
            ? Face.happy
            : (_blinker.blinking && !info.touching ? Face.blink : Face.open),
        bounce: info.bounce,
      ),
    );
  }
}
