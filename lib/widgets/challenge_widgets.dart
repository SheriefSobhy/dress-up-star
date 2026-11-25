import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../data/game_config.dart';
import '../models/challenge.dart';
import '../painting/shapes.dart';
import '../services/game_audio.dart';
import 'art_image.dart';
import 'big_round_button.dart';

/// The picture of a challenge theme (beach, snow, party...).
class ThemePicture extends StatelessWidget {
  const ThemePicture(this.theme, {super.key});

  final ChallengeTheme theme;

  @override
  Widget build(BuildContext context) => ArtIcon(themeArt(theme));
}

BoxDecoration _themeCard(ChallengeTheme theme, double radius) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: themeCardColors[theme]!,
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white, width: 5),
  boxShadow: const [
    BoxShadow(color: Color(0x557A3A7A), blurRadius: 24, offset: Offset(0, 8)),
  ],
);

/// What the child picked on the theme card.
enum ThemeCardChoice { go, another }

/// Shows the big theme card: a picture (no words), a few item pictures as
/// ideas, a big green "go" button and a "another card" button. Tapping
/// outside also starts the challenge.
Future<ThemeCardChoice?> showThemeCard(
  BuildContext context, {
  required ChallengeTheme theme,
  required GameAudio audio,
}) {
  return showGeneralDialog<ThemeCardChoice>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x667A3A7A),
    transitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (context, _, _) => _ThemeCard(theme: theme, audio: audio),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: RotationTransition(
          turns: Tween(begin: -0.03, end: 0.0).animate(animation),
          child: child,
        ),
      ),
    ),
  );
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme, required this.audio});

  final ChallengeTheme theme;
  final GameAudio audio;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = math.min(screen.width - 40, 340.0);
    final picture = math.min(width - 60, screen.height * 0.3);
    final ideas = themeIdeas(theme);
    void pick(ThemeCardChoice choice) {
      audio.play(choice == ThemeCardChoice.go ? Sfx.itemOn : Sfx.tap);
      Navigator.of(context).pop(choice);
    }

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          key: const Key('theme_card'),
          width: width,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: _themeCard(theme, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: picture,
                height: picture,
                child: ThemePicture(theme, key: Key('theme_${theme.name}')),
              ),
              const SizedBox(height: 10),
              // Picture hints: things that fit the theme.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final item in ideas)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: ItemThumbnail(item: item, color: item.color),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BigRoundButton(
                    key: const Key('challenge_new'),
                    icon: Icons.shuffle_rounded,
                    color: const Color(0xFFB79CFF),
                    semanticLabel: AppStrings.of(context).anotherCard,
                    size: 56,
                    onTap: () => pick(ThemeCardChoice.another),
                  ),
                  const SizedBox(width: 24),
                  BigRoundButton(
                    key: const Key('challenge_go'),
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF5CCB6A),
                    semanticLabel: AppStrings.of(context).start,
                    size: 76,
                    onTap: () => pick(ThemeCardChoice.go),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The happy result: the theme picture and 1 to 3 big stars popping in.
/// Closes by itself (or with a tap).
Future<void> showChallengeResult(
  BuildContext context, {
  required ChallengeTheme theme,
  required int stars,
  required GameAudio audio,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x557A3A7A),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, _, _) =>
        _Result(theme: theme, stars: stars, audio: audio),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.7, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

class _Result extends StatefulWidget {
  const _Result({
    required this.theme,
    required this.stars,
    required this.audio,
  });

  final ChallengeTheme theme;
  final int stars;
  final GameAudio audio;

  @override
  State<_Result> createState() => _ResultState();
}

class _ResultState extends State<_Result> with SingleTickerProviderStateMixin {
  static const _starStart = 0.12;
  static const _starGap = 0.16;

  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  int _sounds = 0;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _show
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _close();
      })
      ..forward();
  }

  /// A sparkle sound as each star pops in.
  void _onTick() {
    if (_sounds < widget.stars &&
        _show.value >= _starStart + _sounds * _starGap) {
      _sounds++;
      widget.audio.play(Sfx.sparkle);
    }
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width - 40, 340.0);
    final star = math.min(92.0, (width - 40) / 3);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: Center(
        child: Container(
          key: const Key('challenge_result'),
          width: width,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
          decoration: _themeCard(widget.theme, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width * 0.42,
                height: width * 0.42,
                child: ThemePicture(widget.theme),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _show,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.stars; i++)
                      _BigStar(
                        key: Key('result_star_$i'),
                        size: star,
                        progress:
                            ((_show.value - _starStart - i * _starGap) / 0.2)
                                .clamp(0.0, 1.0),
                        wiggle: _show.value * 2 * math.pi * 3 + i,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A big shiny gold star that pops in ([progress] 0..1) and wiggles.
class _BigStar extends StatelessWidget {
  const _BigStar({
    super.key,
    required this.size,
    required this.progress,
    required this.wiggle,
  });

  final double size;
  final double progress;
  final double wiggle;

  @override
  Widget build(BuildContext context) {
    final pop = Curves.elasticOut.transform(progress);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Transform.rotate(
        angle: math.sin(wiggle) * 0.08 * progress,
        child: Transform.scale(
          scale: pop,
          child: CustomPaint(
            size: Size.square(size),
            painter: const _StarPainter(),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.48;
    final path = starPath(c, r);
    canvas.drawPath(
      path.shift(Offset(0, r * 0.06)),
      Paint()..color = const Color(0x44A06A00),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFF6B0), Color(0xFFFFD84D), Color(0xFFF2A81E)],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD08A10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      starPath(c + Offset(-r * 0.12, -r * 0.14), r * 0.28),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// The Challenge button: a gold trophy, or the picture of the theme while
/// a challenge is on.
class ChallengeButton extends StatelessWidget {
  const ChallengeButton({
    super.key,
    required this.theme,
    required this.size,
    required this.onTap,
  });

  final ChallengeTheme? theme;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Semantics(
      button: true,
      label: AppStrings.of(context).challenge,
      child: Pressable(
        key: const Key('challenge_button'),
        onTap: onTap,
        builder: (pressed) => SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (t == null)
                GlossyCircle(
                  color: const Color(0xFFFFC23D),
                  size: size,
                  pressed: pressed,
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: size * 0.55,
                    shadows: const [
                      Shadow(
                        color: Color(0x88B06A00),
                        offset: Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(size * 0.08),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: themeCardColors[t]!,
                    ),
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x557A3A7A),
                        blurRadius: pressed ? 4 : 10,
                        offset: Offset(0, pressed ? 2 : 5),
                      ),
                    ],
                  ),
                  child: ThemePicture(t),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gold pill with a star and a number: all the stars collected.
class StarCount extends StatelessWidget {
  const StarCount({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        child: child,
      ),
      child: Container(
        key: ValueKey(stars),
        padding: const EdgeInsets.fromLTRB(4, 1, 8, 1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE680), Color(0xFFFFB020)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: 20),
            Text(
              '$stars',
              key: const Key('star_total'),
              style: const TextStyle(
                fontFamily: 'Fredoka',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                shadows: [Shadow(color: Color(0x66A06A00), blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
