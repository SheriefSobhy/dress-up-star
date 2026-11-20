import 'package:flutter/material.dart';

import '../painting/shapes.dart';

/// A glossy candy-like circle: soft gradient, white rim, shine on top and a
/// soft colored shadow. Used by all round buttons.
class GlossyCircle extends StatelessWidget {
  const GlossyCircle({
    super.key,
    required this.color,
    required this.size,
    this.child,
    this.pressed = false,
    this.rim = 3.5,
    this.rimColor = Colors.white,
    this.glow,
  });

  final Color color;
  final double size;
  final Widget? child;
  final bool pressed;
  final double rim;
  final Color rimColor;

  /// Extra glow color (for selected buttons).
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.45),
          radius: 0.95,
          colors: [lighten(color, 0.45), color, darken(color, 0.12)],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(color: rimColor, width: rim),
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.75),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: darken(color, 0.35).withValues(alpha: pressed ? 0.18 : 0.32),
            blurRadius: pressed ? 4 : 10,
            offset: Offset(0, pressed ? 2 : 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?child,
            // Glossy shine
            IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.78),
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  heightFactor: 0.3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Makes any child squish down a little while it is pressed.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.builder});

  final VoidCallback onTap;
  final Widget Function(bool pressed) builder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: Offset(0, _down ? 0.03 : 0),
          duration: const Duration(milliseconds: 110),
          child: widget.builder(_down),
        ),
      ),
    );
  }
}

/// A big, round, glossy button with an icon (no text needed).
class BigRoundButton extends StatelessWidget {
  const BigRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 64,
    this.semanticLabel,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final String? semanticLabel;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final s = size;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onTap: onTap,
        builder: (pressed) => SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GlossyCircle(
                color: color,
                size: s,
                pressed: pressed,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: s * 0.5,
                  shadows: [
                    Shadow(
                      color: darken(color, 0.4).withValues(alpha: 0.45),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              if ((badge ?? 0) > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF8FA8), Color(0xFFFF4F7B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
