import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../painting/shapes.dart';
import 'art_image.dart';
import 'big_round_button.dart';
import 'challenge_widgets.dart' show StarCount;

const Color _gold = Color(0xFFFFC23D);
const Color _goldDark = Color(0xFFD08A10);

/// A little gold padlock on a locked item.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFF0A8), _gold, Color(0xFFE89A14)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.lock_rounded,
        color: Colors.white,
        size: size * 0.6,
        shadows: const [Shadow(color: Color(0x66A06A00), blurRadius: 2)],
      ),
    );
  }
}

/// A star and the number of stars an item costs.
class PricePill extends StatelessWidget {
  const PricePill({super.key, required this.price, this.big = false});

  final int price;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(3, 0, big ? 9 : 6, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE680), Color(0xFFFFB020)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: big ? 20 : 15),
          Text(
            '$price',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: big ? 16 : 12.5,
              height: 1.25,
              shadows: const [Shadow(color: Color(0x88A06A00), blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shakes [child] gently each time [trigger] changes ("not yet").
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = _shake.isAnimating
            ? math.sin(t * math.pi * 6) * 7 * (1 - t)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// The happy unlock: light rays, the lock flying open and the new item
/// popping out. [progress] runs from 0 to 1.
class UnlockCelebration extends StatelessWidget {
  const UnlockCelebration({
    super.key,
    required this.picture,
    required this.progress,
  });

  /// The picture of what was unlocked.
  final Widget picture;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final fade = t < 0.8 ? 1.0 : 1 - (t - 0.8) / 0.2;
    final pop = Curves.elasticOut.transform(((t - 0.12) / 0.45).clamp(0, 1));
    final lockT = (t / 0.3).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Opacity(
        opacity: fade,
        child: Center(
          key: const Key('unlock_celebration'),
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(240),
                  painter: _RaysPainter(turn: t * 0.6, grow: pop),
                ),
                Transform.scale(
                  scale: pop,
                  child: Container(
                    width: 130,
                    height: 130,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: _gold, width: 5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66FFB020), blurRadius: 24),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: picture,
                    ),
                  ),
                ),
                // The lock opens and flies away.
                Transform.translate(
                  offset: Offset(lockT * 60, -lockT * 90),
                  child: Transform.rotate(
                    angle: lockT * 0.9,
                    child: Opacity(
                      opacity: 1 - lockT,
                      child: Icon(
                        lockT > 0.25
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        color: _gold,
                        size: 64,
                        shadows: const [
                          Shadow(color: _goldDark, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.turn, required this.grow});

  final double turn;
  final double grow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * grow.clamp(0.0, 1.2);
    canvas.drawCircle(
      c,
      r * 0.75,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xCCFFF3B0), Color(0x00FFF3B0)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.75)),
    );
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = turn * 2 * math.pi + i * 2 * math.pi / rays;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.12) * r, c.dy + math.sin(a - 0.12) * r)
        ..lineTo(c.dx + math.cos(a + 0.12) * r, c.dy + math.sin(a + 0.12) * r)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (i.isEven ? const Color(0xFFFFE680) : Colors.white)
              .withValues(alpha: 0.55),
      );
    }
    final rnd = math.Random(7);
    for (var i = 0; i < 10; i++) {
      final a = rnd.nextDouble() * 2 * math.pi + turn * 3;
      final d = r * (0.55 + rnd.nextDouble() * 0.4);
      canvas.drawPath(
        starPath(
          c + Offset(math.cos(a) * d, math.sin(a) * d),
          6 + rnd.nextDouble() * 5,
        ),
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.turn != turn || old.grow != grow;
}

/// Not enough stars yet: the item with a lock, and the stars it needs -
/// gold for the stars she has, pale for the ones still to win. No words.
class NeedStars extends StatelessWidget {
  const NeedStars({
    super.key,
    required this.picture,
    required this.price,
    required this.have,
    required this.progress,
  });

  final Widget picture;
  final int price;
  final int have;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final show = Curves.easeOutBack.transform((t / 0.2).clamp(0, 1));
    final fade = t < 0.82 ? 1.0 : 1 - (t - 0.82) / 0.18;
    final perRow = price > 8 ? (price / 2).ceil() : price;
    final star = math.min(24.0, 230 / perRow);
    return IgnorePointer(
      child: Opacity(
        opacity: fade,
        child: Transform.scale(
          scale: show,
          child: Container(
            key: const Key('need_stars'),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFD36B), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x447A3A7A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: picture,
                        ),
                      ),
                      const Positioned(right: -6, top: -6, child: LockBadge()),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: perRow * star,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < price; i++)
                        Icon(
                          Icons.star_rounded,
                          key: Key(i < have ? 'need_have_$i' : 'need_miss_$i'),
                          size: star,
                          color: i < have ? _gold : const Color(0xFFE8E0EE),
                          shadows: i < have
                              ? const [Shadow(color: _goldDark, blurRadius: 1)]
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The daily gift: a box bounces in, the lid pops off and a star flies
/// out. [progress] runs from 0 to 1.
class DailyGift extends StatelessWidget {
  const DailyGift({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final drop = Curves.bounceOut.transform((t / 0.3).clamp(0, 1));
    final open = Curves.easeOut.transform(((t - 0.35) / 0.25).clamp(0, 1));
    final star = Curves.elasticOut.transform(((t - 0.4) / 0.4).clamp(0, 1));
    final fade = t < 0.82 ? 1.0 : 1 - (t - 0.82) / 0.18;
    final wiggle = t < 0.35 ? 0.0 : math.sin(t * 40) * 0.06 * (1 - open);
    return IgnorePointer(
      child: Opacity(
        opacity: fade,
        child: SizedBox(
          key: const Key('daily_gift'),
          width: 200,
          height: 230,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // The star rises out of the box.
              Positioned(
                bottom: 70 + star * 80,
                child: Transform.scale(
                  scale: 0.3 + star * 0.9,
                  child: const Icon(
                    Icons.star_rounded,
                    color: _gold,
                    size: 84,
                    shadows: [Shadow(color: _goldDark, blurRadius: 6)],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -(1 - drop) * 220),
                child: Transform.rotate(
                  angle: wiggle,
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ArtIcon('assets/svg/icons/gift_box.svg'),
                        ),
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(open * 40, -open * 70),
                            child: Transform.rotate(
                              angle: open * 0.5,
                              child: ArtIcon('assets/svg/icons/gift_lid.svg'),
                            ),
                          ),
                        ),
                      ],
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

/// The Star Shop button: a gift box and all the stars she can spend.
class StarShopButton extends StatelessWidget {
  const StarShopButton({
    super.key,
    required this.stars,
    required this.size,
    required this.onTap,
  });

  final int stars;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.of(context).starShop,
      child: Pressable(
        key: const Key('shop_button'),
        onTap: onTap,
        builder: (pressed) => SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GlossyCircle(
                color: const Color(0xFFFF7FB6),
                size: size,
                pressed: pressed,
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: size * 0.52,
                  shadows: const [
                    Shadow(
                      color: Color(0x88A0306A),
                      offset: Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              Positioned(left: -10, bottom: -8, child: StarCount(stars: stars)),
            ],
          ),
        ),
      ),
    );
  }
}
