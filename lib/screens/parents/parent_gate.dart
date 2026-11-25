import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';

/// The small gear for the parents. It only opens after the button is held
/// for [holdTime] (a ring fills up while holding) and then a grown-up
/// answers a times-table question ([showParentQuestion]).
class ParentsButton extends StatefulWidget {
  const ParentsButton({
    super.key,
    required this.onUnlocked,
    this.size = 44,
    this.random,
  });

  /// Called after the hold and the right answer.
  final VoidCallback onUnlocked;
  final double size;

  /// Picks the questions (tests pass their own).
  final Random? random;

  static const holdTime = Duration(seconds: 3);

  @override
  State<ParentsButton> createState() => _ParentsButtonState();
}

class _ParentsButtonState extends State<ParentsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: ParentsButton.holdTime,
  )..addStatusListener(_onHoldStatus);
  bool _showHint = false;
  bool _asking = false;
  Timer? _hintTimer;

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hold.dispose();
    super.dispose();
  }

  void _down() {
    if (_asking) return;
    setState(() => _showHint = true);
    _hold.forward(from: 0);
  }

  void _up() {
    if (_hold.isCompleted || _asking) return;
    _hold.stop();
    _hold.animateBack(0, duration: const Duration(milliseconds: 250));
    // The words stay a moment so a grown-up can read them.
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_hold.isAnimating && _hold.value == 0) {
        setState(() => _showHint = false);
      }
    });
  }

  Future<void> _onHoldStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed || _asking) return;
    HapticFeedback.mediumImpact();
    _asking = true;
    final ok = await showParentQuestion(context, random: widget.random);
    _asking = false;
    if (!mounted) return;
    _hold.value = 0;
    setState(() => _showHint = false);
    if (ok) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final strings = AppStrings.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: _showHint ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: const Key('parents_hint'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsetsDirectional.only(end: 6),
            constraints: const BoxConstraints(maxWidth: 170),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              strings.holdForParents,
              style: const TextStyle(
                fontSize: 13,
                height: 1.2,
                color: Color(0xFF6B4A7A),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: strings.holdForParents,
          child: Listener(
            key: const Key('parents_button'),
            onPointerDown: (_) => _down(),
            onPointerUp: (_) => _up(),
            onPointerCancel: (_) => _up(),
            child: SizedBox(
              width: s,
              height: s,
              child: AnimatedBuilder(
                animation: _hold,
                builder: (context, _) => CustomPaint(
                  painter: _HoldRingPainter(_hold.value),
                  child: Center(
                    child: Container(
                      width: s - 8,
                      height: s - 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        size: s * 0.55,
                        color: const Color(0xFF9A86AE),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The ring that fills up while the gear is held.
class _HoldRingPainter extends CustomPainter {
  _HoldRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF8B5CC9),
    );
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) => old.progress != progress;
}

/// A times-table question only a grown-up can answer, typed on a small
/// number pad. Returns true for the right answer, false when closed.
Future<bool> showParentQuestion(BuildContext context, {Random? random}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ParentQuestion(random: random ?? Random()),
  );
  return ok ?? false;
}

class _ParentQuestion extends StatefulWidget {
  const _ParentQuestion({required this.random});
  final Random random;

  @override
  State<_ParentQuestion> createState() => _ParentQuestionState();
}

class _ParentQuestionState extends State<_ParentQuestion> {
  late int _a;
  late int _b;
  String _typed = '';
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  /// Two numbers from 3 to 9: easy for grown-ups, hard for little kids.
  void _newQuestion() {
    _a = 3 + widget.random.nextInt(7);
    _b = 3 + widget.random.nextInt(7);
    _typed = '';
  }

  void _digit(int d) {
    if (_typed.length >= 3) return;
    setState(() {
      _typed += '$d';
      _wrong = false;
    });
  }

  void _check() {
    if (_typed.isEmpty) return;
    if (int.tryParse(_typed) == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _wrong = true;
      _newQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    const ink = Color(0xFF4A3358);
    return Dialog(
      key: const Key('parent_gate'),
      backgroundColor: const Color(0xFFFFF7FB),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  key: const Key('gate_cancel'),
                  tooltip: strings.cancel,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              Text(
                strings.grownUpsOnly,
                style: const TextStyle(fontSize: 16, color: Color(0xFF8B6F9C)),
              ),
              const SizedBox(height: 6),
              Text(
                strings.mathQuestion(_a, _b),
                key: const Key('gate_question'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 20,
                child: _wrong
                    ? Text(
                        strings.tryAgain,
                        key: const Key('gate_wrong'),
                        style: const TextStyle(color: Color(0xFFD9466F)),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Container(
                key: const Key('gate_answer'),
                width: 140,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD9C6E8), width: 2),
                ),
                child: Text(
                  _typed,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Number pads read 1 2 3 from left to right in every language.
              Directionality(
                textDirection: TextDirection.ltr,
                child: _keypad(strings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keypad(AppStrings strings) {
    Widget key(String id, Widget child, VoidCallback onTap, {Color? color}) =>
        Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox(
            width: 68,
            height: 52,
            child: FilledButton(
              key: Key(id),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: color ?? const Color(0xFFEDE3F5),
                foregroundColor: const Color(0xFF4A3358),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onTap,
              child: child,
            ),
          ),
        );
    Widget digit(int d) => key(
      'gate_key_$d',
      Text('$d', style: const TextStyle(fontSize: 24)),
      () => _digit(d),
    );
    return Column(
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in row) digit(d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key(
              'gate_clear',
              Icon(Icons.backspace_outlined, semanticLabel: strings.clear),
              () => setState(() {
                if (_typed.isNotEmpty) {
                  _typed = _typed.substring(0, _typed.length - 1);
                }
              }),
            ),
            digit(0),
            key(
              'gate_ok',
              Icon(Icons.check_rounded, size: 28, semanticLabel: strings.ok),
              _check,
              color: const Color(0xFFB7E8BE),
            ),
          ],
        ),
      ],
    );
  }
}
