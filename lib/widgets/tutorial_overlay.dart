import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/motion.dart';
import '../l10n/app_strings.dart';
import 'big_round_button.dart';

/// The first-time tutorial, in order. Each step waits until she does it.
enum TutorialStep {
  /// Tap a piece of clothing.
  tapItem,

  /// Slide the category bar sideways.
  scrollBar,

  /// Tap the Pose button.
  pose,

  /// Open the Star Shop.
  shop,
}

/// A big animated finger that shows what to do (no reading needed), plus a
/// small button to skip it. Everything else on the screen still works:
/// touches go through to the game.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.step,
    required this.targetOf,
    required this.onSkip,
    this.skipTop = 96,
  });

  final TutorialStep step;

  /// Where on the screen (global coordinates) the step's button or bar is,
  /// or null when it is not on screen.
  final Rect? Function(TutorialStep step) targetOf;

  final VoidCallback onSkip;

  /// How far from the top the skip button sits.
  final double skipTop;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  static const _loop = Duration(milliseconds: 1800);

  /// Runs the finger's tap or swipe over and over (still in tests).
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _loop,
    value: 0.45,
  );

  @override
  void initState() {
    super.initState();
    if (GameMotion.idleAnimations) _clock.repeat();
    // The targets are known once the screen is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(TutorialOverlay old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step && GameMotion.idleAnimations) {
      _clock.forward(from: 0).whenComplete(() {
        if (mounted && GameMotion.idleAnimations) _clock.repeat();
      });
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      key: const Key('tutorial'),
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) => CustomPaint(
              key: Key('tutorial_${widget.step.name}'),
              size: Size.infinite,
              painter: _FingerPainter(
                step: widget.step,
                // Looked up while painting, when everything is laid out.
                target: () {
                  final box = context.findRenderObject() as RenderBox?;
                  final target = widget.targetOf(widget.step);
                  if (box == null || !box.hasSize || target == null) {
                    return null;
                  }
                  return target.shift(-box.localToGlobal(Offset.zero));
                },
                t: _clock.value,
                rtl: rtl,
              ),
            ),
          ),
        ),
        Positioned(
          top: widget.skipTop,
          left: 0,
          right: 0,
          child: Center(
            child: BigRoundButton(
              key: const Key('tutorial_skip'),
              icon: Icons.close_rounded,
              color: const Color(0xFFB8AEC4),
              size: 44,
              semanticLabel: strings.skip,
              onTap: widget.onSkip,
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws the pointing hand, a glowing ring on the target and, for a tap,
/// a ripple when the finger touches.
class _FingerPainter extends CustomPainter {
  _FingerPainter({
    required this.step,
    required this.target,
    required this.t,
    required this.rtl,
  });

  final TutorialStep step;
  final Rect? Function() target;

  /// 0..1 through one loop.
  final double t;
  final bool rtl;

  static const IconData _hand = Icons.touch_app_rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final target = this.target();
    if (target == null) return;
    final unit = math.min(size.width, 420.0) / 390;
    final handSize = 64.0 * unit;
    final swipe = step == TutorialStep.scrollBar;

    // Where the fingertip is, and how pressed it is (0 up, 1 touching).
    Offset tip;
    double press;
    if (swipe) {
      // Touch near the end of the bar and slide toward its start.
      final from = target.centerLeft + Offset(target.width * 0.78, 0);
      final to = target.centerLeft + Offset(target.width * 0.28, 0);
      final a = rtl ? to : from;
      final b = rtl ? from : to;
      final move = Curves.easeInOut.transform(_seg(t, 0.2, 0.7));
      tip = Offset.lerp(a, b, move)!;
      press = _seg(t, 0.08, 0.2) - _seg(t, 0.72, 0.84);
      _trail(canvas, a, tip, press);
    } else {
      // Come in from below, tap, lift.
      final come = Curves.easeOutCubic.transform(_seg(t, 0, 0.35));
      final start = target.center + Offset(handSize * 0.5, handSize * 0.9);
      tip = Offset.lerp(start, target.center, come)!;
      press = _seg(t, 0.35, 0.45) - _seg(t, 0.55, 0.68);
      _ring(canvas, target, t);
      if (t > 0.42) _ripple(canvas, target.center, _seg(t, 0.42, 0.9), unit);
    }
    final fade = 1 - _seg(t, 0.9, 1.0);
    _drawHand(canvas, tip, handSize, press, fade);
  }

  /// 0 before [a], 1 after [b], straight in between.
  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _ring(Canvas canvas, Rect r, double t) {
    final glow = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    final radius = r.shortestSide / 2 + 6 + glow * 4;
    canvas.drawCircle(
      r.center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFFFFE066).withValues(alpha: 0.55 + 0.4 * glow),
    );
    canvas.drawCircle(
      r.center,
      radius + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  void _ripple(Canvas canvas, Offset c, double p, double unit) {
    canvas.drawCircle(
      c,
      (14 + 30 * p) * unit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - p) + 1
        ..color = Colors.white.withValues(alpha: (1 - p) * 0.9),
    );
  }

  void _trail(Canvas canvas, Offset from, Offset to, double press) {
    if (press <= 0 || (to - from).distance < 4) return;
    canvas.drawLine(
      from,
      to,
      Paint()
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.55 * press),
    );
  }

  void _drawHand(
    Canvas canvas,
    Offset tip,
    double size,
    double press,
    double fade,
  ) {
    if (fade <= 0) return;
    final scale = 1 - 0.12 * press;
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.scale(scale);
    // The hand icon's fingertip is near the top middle of the picture.
    final topLeft = Offset(-size * 0.42, -size * 0.06);
    _icon(canvas, topLeft, size * 1.08, const Color(0x55000000), Offset(2, 4));
    for (final o in const [
      Offset(-2.5, 0),
      Offset(2.5, 0),
      Offset(0, -2.5),
      Offset(0, 2.5),
    ]) {
      _icon(canvas, topLeft, size, Colors.white.withValues(alpha: fade), o);
    }
    _icon(
      canvas,
      topLeft,
      size,
      const Color(0xFFFF6FA5).withValues(alpha: fade),
      Offset.zero,
    );
    canvas.restore();
  }

  void _icon(
    Canvas canvas,
    Offset topLeft,
    double size,
    Color color,
    Offset shift,
  ) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(_hand.codePoint),
        style: TextStyle(
          fontFamily: _hand.fontFamily,
          package: _hand.fontPackage,
          fontSize: size,
          height: 1,
          color: color,
        ),
      ),
    )..layout();
    painter.paint(canvas, topLeft + shift);
    painter.dispose();
  }

  @override
  bool shouldRepaint(_FingerPainter old) => true; // The target may have moved: always cheap to draw again.
}
