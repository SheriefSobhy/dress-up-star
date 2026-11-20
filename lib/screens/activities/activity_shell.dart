import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../art/doll_art.dart';
import '../../art/motion.dart';
import '../../painting/particles.dart';
import '../../painting/shapes.dart';
import '../../services/game_audio.dart';
import '../../widgets/art_image.dart';
import '../../widgets/big_round_button.dart';

/// One choice for a tool: a color, or a style/shape drawn by [paint].
class ToolOption {
  const ToolOption({
    required this.color,
    this.glitter = false,
    this.rainbow = false,
    this.paint,
  });

  final Color color;
  final bool glitter;
  final bool rainbow;

  /// Draws the option on its button (and under the finger for tools that
  /// carry their option, like stickers) into a square of the given size.
  final void Function(Canvas canvas, Size size)? paint;
}

/// A tool in the tray.
class ActivityTool {
  const ActivityTool({
    required this.id,
    required this.art,
    required this.color,
    this.options = const [],
    this.tip = const Offset(0.22, 0.78),
    this.tinted = false,
    this.carriesOption = false,
    this.artColor,
  });

  final String id;

  /// SVG in assets/svg/tools/ (100 x 100).
  final String art;

  /// The tray button color.
  final Color color;
  final List<ToolOption> options;

  /// The working end of the tool in its picture (0..1). It sits right
  /// under the finger.
  final Offset tip;

  /// The tool's picture takes the chosen option's color.
  final bool tinted;

  /// The finger carries the option itself (a sticker, a gem...).
  final bool carriesOption;

  /// A fixed color for the tool picture (when it is not [tinted]).
  final Color? artColor;
}

/// What a finger move did.
class StrokeResult {
  const StrokeResult({
    this.changed = false,
    this.finished = const [],
    this.sound,
  });

  static const StrokeResult none = StrokeResult();

  /// Something was painted or changed: a small twinkle and sparkle.
  final bool changed;

  /// Where something was just finished (art space): a big sparkle burst,
  /// a "ta-da" and a smile.
  final List<Offset> finished;

  /// The sound for this move (the brush twinkle if null and something
  /// changed).
  final Sfx? sound;
}

/// Facts the stage needs to draw the girl.
class StageInfo {
  const StageInfo({
    required this.happy,
    required this.bounce,
    required this.touching,
  });

  final bool happy;
  final Animation<double> bounce;
  final bool touching;
}

typedef StrokeHandler =
    StrokeResult Function(int tool, int option, Offset from, Offset to);

/// The screen layout shared by all activities: undo-all and done buttons at
/// the top, the close-up stage in the middle (the tool follows the finger
/// there) and the tool tray at the bottom.
class ActivityShell extends StatefulWidget {
  const ActivityShell({
    super.key,
    required this.audio,
    required this.tools,
    required this.frame,
    required this.particles,
    required this.stageBuilder,
    required this.onStroke,
    required this.onDone,
    required this.onUndo,
    required this.wallColors,
    this.onLift,
    this.undoRestores = false,
    this.backdrop,
    this.topCenter,
    this.extraButtons = const [],
    this.onToolChanged,
  });

  final GameAudio audio;
  final List<ActivityTool> tools;

  /// The part of art space (doll or hand) shown on the stage.
  final Rect frame;
  final ParticleSystem particles;
  final Widget Function(BuildContext context, StageInfo info) stageBuilder;
  final StrokeHandler onStroke;

  /// The finger let go at this point (art space).
  final StrokeResult Function(int tool, int option, Offset at)? onLift;
  final VoidCallback onDone;
  final VoidCallback onUndo;

  /// When true the undo button brings back what "undo all" took away.
  final bool undoRestores;

  /// Paints the room behind the girl (stage-sized, in screen space).
  final CustomPainter? backdrop;
  final List<Color> wallColors;

  /// Something in the middle of the top bar (gets the girl's mood).
  final Widget Function(BuildContext context, StageInfo info)? topCenter;
  final List<Widget> extraButtons;
  final void Function(int tool)? onToolChanged;

  @override
  State<ActivityShell> createState() => ActivityShellState();
}

class ActivityShellState extends State<ActivityShell>
    with TickerProviderStateMixin {
  int _tool = 0;
  late final List<int> _options = List.filled(widget.tools.length, 0);

  int? _pointer;
  Offset? _lastArt;
  bool _changedThisStroke = false;
  Size _stageSize = Size.zero;

  /// The finger on the stage (screen space), or null.
  final ValueNotifier<Offset?> _finger = ValueNotifier(null);
  final Map<Sfx, DateTime> _lastSound = {};
  Offset? _lastSparkle;

  /// While this runs the girl smiles and hops.
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _bounce = _react.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 42),
    ]),
  );

  int get tool => _tool;
  int optionOf(int tool) => _options[tool];

  @override
  void initState() {
    super.initState();
    _react.addStatusListener((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _react.dispose();
    _finger.dispose();
    super.dispose();
  }

  /// The girl smiles and hops; with [at], stars burst there too.
  void celebrate({Offset? at, Sfx? sound = Sfx.sparkle}) {
    _react.forward(from: 0);
    if (at != null) widget.particles.burst(at);
    if (sound != null) _play(sound, force: true);
    HapticFeedback.lightImpact();
  }

  void _play(Sfx sfx, {bool force = false}) {
    final now = DateTime.now();
    final last = _lastSound[sfx];
    if (!force &&
        last != null &&
        now.difference(last) < const Duration(milliseconds: 190)) {
      return;
    }
    _lastSound[sfx] = now;
    widget.audio.play(sfx);
  }

  FitTransform get _fit => FitTransform(widget.frame, _stageSize);

  void _handle(StrokeResult r, Offset at) {
    // Tools like the shower and dryer make their sound even with nothing
    // left to change.
    if (!r.changed && r.sound != null) _play(r.sound!);
    if (r.changed) {
      _changedThisStroke = true;
      _play(r.sound ?? Sfx.brush);
      final last = _lastSparkle;
      if (last == null || (last - at).distance > widget.frame.width * 0.05) {
        _lastSparkle = at;
        widget.particles.emit(
          ParticleKind.sparkle,
          at,
          size: widget.frame.width * 0.016,
        );
      }
    }
    if (r.finished.isNotEmpty) {
      for (final p in r.finished) {
        widget.particles.burst(p, size: widget.frame.width * 0.022);
      }
      celebrate(sound: Sfx.sparkle);
    }
  }

  void _down(PointerDownEvent e) {
    if (_pointer != null || _stageSize.isEmpty) return;
    _pointer = e.pointer;
    _changedThisStroke = false;
    _lastSparkle = null;
    _finger.value = e.localPosition;
    final p = _fit.invert(e.localPosition);
    _lastArt = p;
    _handle(widget.onStroke(_tool, _options[_tool], p, p), p);
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    _finger.value = e.localPosition;
    final p = _fit.invert(e.localPosition);
    final from = _lastArt ?? p;
    _lastArt = p;
    _handle(widget.onStroke(_tool, _options[_tool], from, p), p);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _finger.value = null;
    final p = _fit.invert(e.localPosition);
    _lastArt = null;
    final lift = widget.onLift?.call(_tool, _options[_tool], p);
    if (lift != null) _handle(lift, p);
    if (_changedThisStroke && (lift?.finished.isEmpty ?? true)) {
      // A happy smile after every bit of work.
      _react.forward(from: 0);
    }
    _changedThisStroke = false;
  }

  void _selectTool(int i) {
    widget.audio.play(Sfx.tap);
    setState(() => _tool = i);
    widget.onToolChanged?.call(i);
  }

  void _selectOption(int i) {
    widget.audio.play(Sfx.tap);
    setState(() => _options[_tool] = i);
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDone();
      },
      child: Scaffold(
        backgroundColor: widget.wallColors.last,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.wallColors,
            ),
          ),
          child: Column(
            children: [
              _topBar(),
              Expanded(child: _stage()),
              _tray(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final width = MediaQuery.sizeOf(context).width;
    final size = width < 380 ? 56.0 : 64.0;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: SizedBox(
          height: size + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ?widget.topCenter?.call(
                context,
                StageInfo(
                  happy: _react.isAnimating,
                  bounce: _bounce,
                  touching: _pointer != null,
                ),
              ),
              Row(
                children: [
                  BigRoundButton(
                    key: const Key('undo_button'),
                    icon: widget.undoRestores
                        ? Icons.undo_rounded
                        : Icons.cleaning_services_rounded,
                    color: widget.undoRestores
                        ? const Color(0xFFFFB347)
                        : const Color(0xFFB79CFF),
                    semanticLabel: widget.undoRestores
                        ? 'Bring it back'
                        : 'Undo all',
                    size: size,
                    onTap: () {
                      widget.audio.play(
                        widget.undoRestores ? Sfx.itemOn : Sfx.itemOff,
                      );
                      widget.onUndo();
                      _react.forward(from: 0);
                    },
                  ),
                  for (final b in widget.extraButtons) ...[
                    const SizedBox(width: 10),
                    b,
                  ],
                  const Spacer(),
                  BigRoundButton(
                    key: const Key('done_button'),
                    icon: Icons.check_rounded,
                    color: const Color(0xFF5ED17A),
                    semanticLabel: 'Done',
                    size: size,
                    onTap: widget.onDone,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _stageSize = constraints.biggest;
        final fit = _fit;
        final happy = _react.isAnimating;
        return Listener(
          key: const Key('activity_stage'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.backdrop != null)
                RepaintBoundary(child: CustomPaint(painter: widget.backdrop)),
              RepaintBoundary(
                child: ValueListenableBuilder<Offset?>(
                  valueListenable: _finger,
                  builder: (context, finger, _) => widget.stageBuilder(
                    context,
                    StageInfo(
                      happy: happy,
                      bounce: _bounce,
                      touching: finger != null,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _ParticlePainter(widget.particles, fit),
                  ),
                ),
              ),
              IgnorePointer(child: _fingerTool(fit)),
            ],
          ),
        );
      },
    );
  }

  /// The tool (or the sticker) that follows the finger.
  Widget _fingerTool(FitTransform fit) {
    final tool = widget.tools[_tool];
    final option = tool.options.isEmpty ? null : tool.options[_options[_tool]];
    final size = math.min(130.0, math.max(96.0, _stageSize.shortestSide * 0.3));
    return ValueListenableBuilder<Offset?>(
      valueListenable: _finger,
      builder: (context, finger, _) {
        if (finger == null) return const SizedBox.shrink();
        if (tool.carriesOption && option?.paint != null) {
          final s = fit.scale * 16;
          return Stack(
            children: [
              Positioned(
                left: finger.dx - s / 2,
                top: finger.dy - s * 0.8,
                width: s,
                height: s,
                child: CustomPaint(painter: _OptionPainter(option!)),
              ),
            ],
          );
        }
        return Stack(
          children: [
            Positioned(
              left: finger.dx - tool.tip.dx * size,
              top: finger.dy - tool.tip.dy * size,
              width: size,
              height: size,
              child: _ToolPicture(
                tool: tool,
                color: tool.tinted ? option?.color : tool.artColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tray() {
    final tool = widget.tools[_tool];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, lighten(tool.color, 0.7)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33B06FA0),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _optionAreaHeight(MediaQuery.sizeOf(context).width),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('options_${tool.id}'),
                    child: _optionRow(tool),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _toolRow(),
            ],
          ),
        ),
      ),
    );
  }

  static const double _dot = 46;
  static const double _dotGap = 8;

  /// How many rows of option buttons fit [count] options in [width].
  static int _optionRows(int count, double width) {
    final perRow = ((width - 24 + _dotGap) / (_dot + _dotGap)).floor();
    return count <= perRow ? 1 : 2;
  }

  /// The option area is as tall as the tool with the most options needs,
  /// so the girl does not jump when switching tools.
  double _optionAreaHeight(double width) {
    final most = widget.tools.map((t) => t.options.length).fold(0, math.max);
    return _optionRows(most, width) == 1 ? 62 : 62 + _dot + _dotGap - 6;
  }

  Widget _optionRow(ActivityTool tool) {
    if (tool.options.isEmpty) return const SizedBox.expand();
    final selected = _options[_tool];
    final width = MediaQuery.sizeOf(context).width;
    final rows = _optionRows(tool.options.length, width);
    final perRow = (tool.options.length / rows).ceil();
    Widget dot(int i) {
      final o = tool.options[i];
      final isSelected = i == selected;
      return Pressable(
        key: Key('option_$i'),
        onTap: () => _selectOption(i),
        builder: (pressed) => AnimatedScale(
          scale: isSelected ? 1.14 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: GlossyCircle(
            color: o.paint != null ? Colors.white : o.color,
            size: _dot,
            pressed: pressed,
            rim: isSelected ? 4 : 3,
            rimColor: isSelected ? darken(tool.color, 0.3) : Colors.white,
            glow: isSelected ? lighten(o.color, 0.1) : null,
            child: CustomPaint(painter: _OptionPainter(o)),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) const SizedBox(height: _dotGap - 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (
                  var i = r * perRow;
                  i < math.min(tool.options.length, (r + 1) * perRow);
                  i++
                ) ...[
                  if (i > r * perRow) const SizedBox(width: _dotGap),
                  dot(i),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = widget.tools.length;
        const gap = 6.0;
        final slot = (constraints.maxWidth - 20 - gap * (n - 1)) / n;
        final size = slot.clamp(44.0, 66.0);
        return SizedBox(
          height: size * 1.16 + 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _toolButton(i, size),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _toolButton(int i, double size) {
    final tool = widget.tools[i];
    final selected = i == _tool;
    final option = tool.options.isEmpty ? null : tool.options[_options[i]];
    return Pressable(
      key: Key('tool_${tool.id}'),
      onTap: () => _selectTool(i),
      builder: (pressed) => AnimatedScale(
        scale: selected ? 1.14 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: GlossyCircle(
          color: tool.color,
          size: size,
          pressed: pressed,
          rim: selected ? 4 : 3,
          rimColor: selected ? darken(tool.color, 0.3) : Colors.white,
          glow: selected ? tool.color : null,
          child: Padding(
            padding: EdgeInsets.all(size * 0.1),
            child: _ToolPicture(
              tool: tool,
              color: tool.tinted ? option?.color : tool.artColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tool's SVG picture (tinted if needed).
class _ToolPicture extends StatelessWidget {
  const _ToolPicture({required this.tool, this.color});

  final ActivityTool tool;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final layer = ArtLayer('assets/svg/tools/${tool.art}.svg', color: color);
    return ArtImage(
      cacheKey: 'tool|${layer.key}',
      draw: (pixels) => rasterizeArt(layer, const Size(100, 100), pixels),
    );
  }
}

class _OptionPainter extends CustomPainter {
  _OptionPainter(this.option);
  final ToolOption option;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = option.paint;
    if (paint != null) {
      paint(canvas, size);
      return;
    }
    final c = size.center(Offset.zero);
    if (option.rainbow) {
      canvas.drawCircle(
        c,
        size.width / 2,
        Paint()
          ..shader = const SweepGradient(
            colors: [
              Color(0xFFFF5F6D),
              Color(0xFFFFA24C),
              Color(0xFFFFE066),
              Color(0xFF7EDB6A),
              Color(0xFF5CB8FF),
              Color(0xFFB57CFF),
              Color(0xFFFF5F6D),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: size.width / 2)),
      );
    }
    if (option.glitter) {
      final rnd = math.Random(3);
      for (var i = 0; i < 9; i++) {
        final p =
            c +
            Offset(
              (rnd.nextDouble() - 0.5) * size.width * 0.7,
              (rnd.nextDouble() - 0.5) * size.height * 0.7,
            );
        canvas.drawPath(
          starPath(
            p,
            size.width * (0.05 + rnd.nextDouble() * 0.05),
            points: 4,
            inner: size.width * 0.02,
          ),
          Paint()..color = i.isEven ? Colors.white : const Color(0xFFFFF2A8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OptionPainter old) => old.option != option;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.system, this.fit) : super(repaint: system);
  final ParticleSystem system;
  final FitTransform fit;

  @override
  void paint(Canvas canvas, Size size) {
    if (system.isEmpty) return;
    canvas.save();
    canvas.translate(fit.dx, fit.dy);
    canvas.scale(fit.scale);
    system.paint(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.system != system ||
      old.fit.scale != fit.scale ||
      old.fit.dx != fit.dx ||
      old.fit.dy != fit.dy;
}

/// Blinks the girl now and then (off in tests).
class Blinker {
  Blinker(this.onChange);
  final VoidCallback onChange;
  Timer? _timer;
  bool blinking = false;
  final math.Random _random = math.Random();

  void start() {
    if (!GameMotion.idleAnimations) return;
    _timer = Timer(Duration(milliseconds: 2400 + _random.nextInt(3000)), () {
      blinking = true;
      onChange();
      _timer = Timer(const Duration(milliseconds: 150), () {
        blinking = false;
        onChange();
        start();
      });
    });
  }

  void dispose() => _timer?.cancel();
}
