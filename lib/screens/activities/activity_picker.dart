import 'package:flutter/material.dart';

import '../../art/doll_art.dart';
import '../../data/game_config.dart';
import '../../models/outfit.dart';
import '../../painting/shapes.dart';
import '../../services/game_audio.dart';
import '../../widgets/art_image.dart';
import '../../widgets/big_round_button.dart';
import 'makeup_screen.dart';
import 'salon_screen.dart';

/// The activities that can be opened from the main screen.
enum Activity { makeup, salon }

/// The screen for [activity]. It returns the outfit with the result.
Route<Outfit> activityRoute(
  Activity activity, {
  required Outfit outfit,
  required GameAudio audio,
}) {
  return PageRouteBuilder<Outfit>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => switch (activity) {
      Activity.makeup => MakeupScreen(outfit: outfit, audio: audio),
      Activity.salon => SalonScreen(outfit: outfit, audio: audio),
    },
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// Shows the activity picker: big picture cards, no reading needed.
Future<Activity?> showActivityPicker(
  BuildContext context, {
  required GameAudio audio,
  required Outfit outfit,
}) {
  return showGeneralDialog<Activity>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x667A3A7A),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => _Picker(audio: audio, outfit: outfit),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

class _Picker extends StatelessWidget {
  const _Picker({required this.audio, required this.outfit});

  final GameAudio audio;
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 32).clamp(240.0, 380.0);
    final cardHeight = ((size.height - 200) / Activity.values.length).clamp(
      110.0,
      160.0,
    );
    return SafeArea(
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF4FA), Color(0xFFF1E6FF)],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x557A3A7A),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 52),
                    const Spacer(),
                    const GlossyCircle(
                      color: Color(0xFFFF7EB6),
                      size: 52,
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const Spacer(),
                    BigRoundButton(
                      key: const Key('activities_close'),
                      icon: Icons.close_rounded,
                      color: const Color(0xFFC9B8DA),
                      size: 52,
                      semanticLabel: 'Close',
                      onTap: () {
                        audio.play(Sfx.tap);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < Activity.values.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _card(context, Activity.values[i], cardHeight, i),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Activity a, double height, int index) {
    final (colors, tools) = switch (a) {
      Activity.makeup => (
        const [Color(0xFFFFB8D9), Color(0xFFFF8FC7)],
        const ['lipstick', 'blush'],
      ),
      Activity.salon => (
        const [Color(0xFFA8EBD8), Color(0xFF5CCB9E)],
        const ['scissors', 'dryer'],
      ),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 110),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(
        scale: 0.8 + 0.2 * v,
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Pressable(
        key: Key('activity_${a.name}'),
        onTap: () {
          audio.play(Sfx.itemOn);
          Navigator.pop(context, a);
        },
        builder: (pressed) => Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: darken(colors.last, 0.3).withValues(alpha: 0.35),
                blurRadius: pressed ? 4 : 12,
                offset: Offset(0, pressed ? 2 : 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardSparkles(lighten(colors.first, 0.6)),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _Portrait(activity: a, outfit: outfit),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          for (var t = 0; t < tools.length; t++)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment(
                                  t == 0 ? -0.35 : 0.55,
                                  t == 0 ? -0.25 : 0.35,
                                ),
                                child: FractionallySizedBox(
                                  heightFactor: 0.72,
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: _ToolArt(tools[t]),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The girl after the activity, in a round white frame.
class _Portrait extends StatelessWidget {
  const _Portrait({required this.activity, required this.outfit});

  final Activity activity;
  final Outfit outfit;

  static Outfit sample(Activity a, Outfit base) {
    final o = closeUpOutfit(base);
    switch (a) {
      case Activity.makeup:
        return o.copyWith(
          makeup: Makeup(
            lips: SpotGrid.filled(lipsZone.length, 0),
            blush: SpotGrid.filled(blushZone.length, 0),
            shadow: SpotGrid.filled(shadowZone.length, 0),
            lashLeft: 2,
            lashRight: 2,
            stickers: const [FaceSticker(StickerKind.star, Offset(138, 124))],
          ),
        );
      case Activity.salon:
        final long = findItem(salonHairId);
        return (long == null ? o : o.wear(long)).copyWith(
          salon: SalonHair(
            cutLeft: 1,
            cutRight: 1,
            curlLeft: true,
            curlRight: true,
            dye: SpotGrid.filled(hairZone.length, 0),
            shine: SpotGrid.filled(hairZone.length, 0),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = sample(activity, outfit);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFE3F1)],
            ),
          ),
          child: ArtImage(
            cacheKey: 'portrait|${activity.name}|${outfitKey(look)}',
            draw: (pixels) async {
              final recipe = await dollRecipe(look);
              return rasterizeDoll(
                recipe.flat(Face.happy),
                activity == Activity.makeup
                    ? kMakeupFrame.deflate(4)
                    : const Rect.fromLTRB(14, 26, 186, 226),
                pixels,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToolArt extends StatelessWidget {
  const _ToolArt(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final layer = ArtLayer(
      'assets/svg/tools/$name.svg',
      color: switch (name) {
        'lipstick' => lipstickColors.first.color,
        'dryer' => const Color(0xFFFF7EB6),
        _ => null,
      },
    );
    return ArtImage(
      cacheKey: 'tool|${layer.key}',
      draw: (pixels) => rasterizeArt(layer, const Size(100, 100), pixels),
    );
  }
}

class _CardSparkles extends CustomPainter {
  _CardSparkles(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spots = [
      Offset(0.45, 0.18),
      Offset(0.9, 0.2),
      Offset(0.62, 0.82),
      Offset(0.96, 0.7),
      Offset(0.5, 0.55),
    ];
    for (var i = 0; i < spots.length; i++) {
      final p = Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      canvas.drawPath(
        starPath(
          p,
          size.height * (0.05 + 0.02 * (i % 2)),
          points: 4,
          inner: size.height * 0.018,
        ),
        Paint()..color = color.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_CardSparkles old) => old.color != color;
}
