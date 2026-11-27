import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/doll_art.dart';
import '../art/motion.dart';
import '../data/game_config.dart';
import '../l10n/app_strings.dart';
import '../models/fashion_show.dart';
import '../models/outfit.dart';
import '../painting/confetti_painter.dart';
import '../services/game_audio.dart';
import '../services/looks_storage.dart';
import '../services/rewards.dart';
import '../widgets/big_round_button.dart';
import '../widgets/challenge_widgets.dart';
import '../widgets/doll_view.dart';
import '../widgets/fashion_show_widgets.dart';

/// When each part of the show happens (seconds from the start).
abstract final class ShowTimes {
  static const double firstPose = 3.2;
  static const double secondPose = 5.0;
  static const double walkBack = 6.8;
  static const double judges = 9.4;
  static const double firstCard = 9.9;
  static const double cardGap = 0.8;
  static const double trophy = 12.6;
  static const double end = 14.4;
}

Route<void> fashionShowRoute({
  required Outfit outfit,
  required ChallengeTheme theme,
  required Rewards rewards,
  required LooksStorage storage,
  required GameAudio audio,
  math.Random? random,
}) => PageRouteBuilder<void>(
  transitionDuration: const Duration(milliseconds: 450),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, _, _) => FashionShowScreen(
    outfit: outfit,
    theme: theme,
    rewards: rewards,
    storage: storage,
    audio: audio,
    random: random,
  ),
  transitionsBuilder: (_, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

/// The runway: she walks down, strikes two poses, walks back, then the
/// judges hold up their star cards and the stars go to the Star Shop.
class FashionShowScreen extends StatefulWidget {
  const FashionShowScreen({
    super.key,
    required this.outfit,
    required this.theme,
    required this.rewards,
    required this.storage,
    required this.audio,
    this.random,
  });

  final Outfit outfit;
  final ChallengeTheme theme;
  final Rewards rewards;
  final LooksStorage storage;
  final GameAudio audio;
  final math.Random? random;

  @override
  State<FashionShowScreen> createState() => _FashionShowScreenState();
}

class _FashionShowScreenState extends State<FashionShowScreen>
    with TickerProviderStateMixin {
  late final ShowScore _score = ShowScore.of(widget.outfit, widget.theme);
  late final List<DollPose> _poses = showPoses(widget.random ?? math.Random());

  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (ShowTimes.end * 1000).round()),
    // The walk takes its time even when the phone turns animations off.
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Keeps the audience and lights moving after the show (not in lite mode).
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  DollPose _pose = DollPose.stand;
  int _nudge = 0;
  int _cards = 0;
  bool _judging = false;
  bool _won = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    widget.audio.setTrack(MusicTrack.show);
    _show
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (GameMotion.idleLoops) _idle.repeat();
      })
      ..forward();
  }

  @override
  void dispose() {
    widget.audio.setTrack(MusicTrack.game);
    _show.dispose();
    _idle.dispose();
    _confetti.dispose();
    _flash.dispose();
    super.dispose();
  }

  double get _seconds => _show.value * ShowTimes.end;

  void _onTick() {
    final t = _seconds;
    final pose = t >= ShowTimes.trophy
        ? DollPose.wave
        : t >= ShowTimes.walkBack
        ? DollPose.stand
        : t >= ShowTimes.secondPose
        ? _poses[1]
        : t >= ShowTimes.firstPose
        ? _poses[0]
        : DollPose.stand;
    // A little swing of hair and skirt with every other step.
    final walking =
        t < ShowTimes.firstPose ||
        (t >= ShowTimes.walkBack && t < ShowTimes.judges);
    final nudge = walking ? (t / 0.8).floor() : _nudge;
    final judging = t >= ShowTimes.judges;
    var cards = 0;
    while (cards < Judge.values.length &&
        t >= ShowTimes.firstCard + cards * ShowTimes.cardGap) {
      cards++;
    }
    if (pose != _pose && t < ShowTimes.walkBack) {
      widget.audio.play(_pose == DollPose.stand ? Sfx.cheer : Sfx.itemOn);
    }
    if (cards > _cards) widget.audio.play(Sfx.sparkle);
    if (!_won && t >= ShowTimes.trophy) _win();
    if (pose != _pose ||
        nudge != _nudge ||
        judging != _judging ||
        cards != _cards) {
      setState(() {
        _pose = pose;
        _nudge = nudge;
        _judging = judging;
        _cards = cards;
      });
    }
  }

  /// The trophy: the stars are saved right away.
  void _win() {
    setState(() => _won = true);
    widget.rewards.addStars(_score.shopStars);
    widget.audio.play(Sfx.unlock);
    widget.audio.play(Sfx.cheer);
    HapticFeedback.mediumImpact();
    _confetti.forward(from: 0);
  }

  Future<void> _takePhoto() async {
    if (_saved) return;
    setState(() => _saved = true);
    widget.audio.play(Sfx.camera);
    HapticFeedback.mediumImpact();
    _flash.forward(from: 0);
    await widget.storage.add(
      widget.outfit.copyWith(pose: _poses.first, runway: true),
    );
  }

  void _leave() {
    widget.audio.play(Sfx.tap);
    Navigator.of(context).pop();
  }

  /// Where her feet are (part of the screen height) and how big she is.
  (double, double) _place(double t) {
    const far = (0.51, 0.5);
    const near = (0.82, 1.0);
    const rest = (0.69, 0.72);
    (double, double) between((double, double) a, (double, double) b, double u) {
      final e = Curves.easeInOut.transform(u.clamp(0.0, 1.0));
      return (a.$1 + (b.$1 - a.$1) * e, a.$2 + (b.$2 - a.$2) * e);
    }

    if (t < ShowTimes.firstPose) {
      return between(far, near, t / ShowTimes.firstPose);
    }
    if (t < ShowTimes.walkBack) return near;
    if (t < ShowTimes.judges) {
      return between(
        near,
        rest,
        (t - ShowTimes.walkBack) / (ShowTimes.judges - ShowTimes.walkBack),
      );
    }
    return rest;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      key: const Key('fashion_show'),
      backgroundColor: const Color(0xFF35186A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth, h = constraints.maxHeight;
          final box = Size(w * 0.8, h * 0.56);
          final feet = FitTransform(kDollFrame, box).apply(kFeet).dy;
          final motion = Listenable.merge([_show, _idle, GameMotion.lite]);
          double clock() => _seconds + _idle.value * 60;
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: motion,
                  builder: (context, _) => CustomPaint(
                    painter: StagePainter(
                      time: clock(),
                      lite: GameMotion.lite.value,
                    ),
                  ),
                ),
              ),
              // The doll on the runway.
              Positioned(
                left: (w - box.width) / 2,
                top: 0,
                width: box.width,
                height: box.height,
                child: AnimatedBuilder(
                  animation: _show,
                  child: RepaintBoundary(
                    child: DollView(
                      key: const Key('show_doll'),
                      outfit: widget.outfit.copyWith(pose: _pose),
                      happy: true,
                      nudge: _nudge,
                    ),
                  ),
                  builder: (context, child) {
                    final t = _seconds;
                    final (y, scale) = _place(t);
                    final walking =
                        t < ShowTimes.firstPose ||
                        (t >= ShowTimes.walkBack && t < ShowTimes.judges);
                    final step = t * 2 * math.pi * 1.6;
                    final bob = walking ? -math.sin(step).abs() * 9 : 0.0;
                    final sway = walking ? math.sin(step) * 0.025 : 0.0;
                    return Transform.translate(
                      offset: Offset(0, h * y - feet + bob * scale),
                      child: Transform(
                        alignment: Alignment.topCenter,
                        origin: Offset(0, feet),
                        transform: Matrix4.rotationZ(sway)
                          ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: motion,
                    builder: (context, _) => CustomPaint(
                      painter: AudiencePainter(
                        time: clock(),
                        lite: GameMotion.lite.value,
                        flashing: _seconds < ShowTimes.judges || _won,
                      ),
                    ),
                  ),
                ),
              ),
              // The judges.
              if (_judging)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _judges(w, padding.bottom),
                ),
              if (_won) ...[
                Positioned(
                  top: padding.top + 56,
                  left: 0,
                  right: 0,
                  child: _trophy(h),
                ),
                Positioned(
                  left: 14,
                  top: h * 0.44,
                  child: BigRoundButton(
                    key: const Key('show_photo'),
                    icon: _saved
                        ? Icons.check_rounded
                        : Icons.photo_camera_rounded,
                    color: _saved
                        ? const Color(0xFF5CCB6A)
                        : const Color(0xFFFF6B8B),
                    semanticLabel: strings.saveLook,
                    size: 72,
                    onTap: _takePhoto,
                  ),
                ),
                Positioned(
                  right: 14,
                  top: h * 0.44,
                  child: BigRoundButton(
                    key: const Key('show_done'),
                    icon: Icons.home_rounded,
                    color: const Color(0xFF5CCB6A),
                    semanticLabel: strings.done,
                    size: 72,
                    onTap: _leave,
                  ),
                ),
              ],
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (context, _) => CustomPaint(
                    painter: ConfettiPainter(
                      progress: _confetti.isAnimating ? _confetti.value : 0,
                      origin: Offset(w / 2, h * 0.3),
                      seed: 7,
                    ),
                  ),
                ),
              ),
              // Camera flash of the photo button.
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flash,
                  builder: (context, _) => ColoredBox(
                    color: Colors.white.withValues(
                      alpha: _flash.isAnimating ? (1 - _flash.value) * 0.8 : 0,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: padding.top + 10,
                left: 12,
                child: BigRoundButton(
                  key: const Key('back_button'),
                  icon: Icons.arrow_back_rounded,
                  color: const Color(0xFFB79CFF),
                  semanticLabel: strings.back,
                  size: 56,
                  onTap: _leave,
                ),
              ),
              Positioned(
                top: padding.top + 10,
                right: 12,
                child: _themeBadge(56),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _themeBadge(double size) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.08),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: themeCardColors[widget.theme]!,
      ),
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: ThemePicture(widget.theme),
  );

  Widget _judges(double width, double bottomPadding) {
    final column = math.min(width / 3, 150.0);
    Widget icon(IconData data, Color color) =>
        Icon(data, size: 30, color: color);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) =>
          Transform.translate(offset: Offset(0, v * 220), child: child),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding + 6),
        child: AnimatedBuilder(
          animation: _show,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final judge in Judge.values)
                JudgeStand(
                  key: Key('judge_${judge.name}'),
                  judge: judge,
                  stars: _score.cards[judge]!,
                  reveal:
                      (_seconds -
                          ShowTimes.firstCard -
                          judge.index * ShowTimes.cardGap) /
                      0.45,
                  width: column,
                  criterion: switch (judge) {
                    Judge.cat => ThemePicture(widget.theme),
                    Judge.bunny => icon(
                      Icons.checkroom_rounded,
                      const Color(0xFFE8447E),
                    ),
                    Judge.owl => icon(
                      Icons.palette_rounded,
                      const Color(0xFF7A4AD0),
                    ),
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The trophy with the Star Shop stars won.
  Widget _trophy(double height) {
    final cup = math.min(120.0, height * 0.14);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _show,
        builder: (context, _) {
          final v =
              ((_seconds - ShowTimes.trophy) /
                      (ShowTimes.end - ShowTimes.trophy))
                  .clamp(0.0, 1.0);
          final pop = Curves.elasticOut.transform(v);
          return Column(
            key: const Key('show_trophy'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pop,
                child: Transform.rotate(
                  angle: math.sin(v * math.pi * 6) * 0.12 * (1 - v),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: cup,
                    color: const Color(0xFFFFD23D),
                    shadows: const [
                      Shadow(color: Color(0xFFFFF3A0), blurRadius: 24),
                      Shadow(color: Color(0x88603000), offset: Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _score.shopStars; i++)
                    BigStar(
                      key: Key('show_star_$i'),
                      size: cup * 0.55,
                      progress: ((v - i * 0.18) / 0.5).clamp(0.0, 1.0),
                      wiggle: v * math.pi * 6 + i,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
