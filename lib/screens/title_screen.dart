import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/motion.dart';
import '../data/game_config.dart';
import '../l10n/app_strings.dart';
import '../models/outfit.dart';
import '../services/app_settings.dart';
import '../services/game_audio.dart';
import '../services/game_settings.dart';
import '../services/looks_storage.dart';
import '../widgets/big_round_button.dart';
import '../widgets/doll_view.dart';
import '../widgets/scene_background.dart';
import 'dress_up_screen.dart';
import 'parents/parent_gate.dart';
import 'parents/parents_screen.dart';

/// The start screen: the game name, the doll waving hello and a big Play
/// button.
class TitleScreen extends StatefulWidget {
  const TitleScreen({
    super.key,
    required this.storage,
    required this.audio,
    required this.settings,
  });

  final LooksStorage storage;
  final GameAudio audio;
  final AppSettings settings;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  static final Outfit _titleOutfit = () {
    var o = Outfit.starter();
    for (final id in [
      'hair_pigtails',
      'dress_sun',
      'head_crown',
      'shoes_flats',
      'bg_castle',
    ]) {
      final item = findItem(id);
      if (item != null) o = o.wear(item);
    }
    final dress = o[Slot.dress];
    if (dress != null) o = o.recolor(Slot.dress, const Color(0xFFFF8FC7));
    return o;
  }();

  @override
  void initState() {
    super.initState();
    if (GameMotion.idleAnimations) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      );
      if (GameMotion.idleLoops) _pulse!.repeat(reverse: true);
      GameMotion.lite.addListener(_onLite);
    }
  }

  /// Lite mode: the Play button stops pulsing.
  void _onLite() {
    final pulse = _pulse;
    if (pulse == null) return;
    if (GameMotion.idleLoops) {
      pulse.repeat(reverse: true);
    } else {
      pulse.animateTo(0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    GameMotion.lite.removeListener(_onLite);
    _pulse?.dispose();
    super.dispose();
  }

  /// The parents' gear: after the hold and the question, the settings.
  Future<void> _openParents() async {
    final result = await Navigator.of(context).push<ParentsResult>(
      MaterialPageRoute(
        builder: (_) =>
            ParentsScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
    if (!mounted || result != ParentsResult.replayTutorial) return;
    // Straight into the game, where the pointing finger starts again.
    await GameSettings.setTutorialSeen(false);
    if (mounted) _play();
  }

  void _play() {
    widget.audio.play(Sfx.itemOn);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) =>
            DressUpScreen(storage: widget.storage, audio: widget.audio),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 1.08, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SceneBackground(scene: _titleOutfit[Slot.background]!),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 18),
                const _Logo(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: DollView(outfit: _titleOutfit, waving: true),
                  ),
                ),
                _playButton(),
                const SizedBox(height: 28),
              ],
            ),
          ),
          // The parents' gear, small and out of the way.
          PositionedDirectional(
            top: 0,
            end: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ParentsButton(size: 40, onUnlocked: _openParents),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playButton() {
    final button = BigRoundButton(
      key: const Key('play_button'),
      icon: Icons.play_arrow_rounded,
      color: const Color(0xFFFF6FA5),
      size: 112,
      semanticLabel: AppStrings.of(context).play,
      onTap: _play,
    );
    final pulse = _pulse;
    if (pulse == null) return button;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.07 * Curves.easeInOut.transform(pulse.value),
        child: child,
      ),
      child: button,
    );
  }
}

/// "Dress Up Star" in big bubbly letters with a white outline.
class _Logo extends StatelessWidget {
  const _Logo();

  Widget _outlined(String text, double size, List<Color> colors) {
    final style = TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      height: 1.0,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
      letterSpacing: 1,
    );
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.2
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: const [
              Shadow(
                color: Color(0x557A3A7A),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(rect),
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final big = math.min(64.0, width * 0.15);
    return Semantics(
      label: 'Dress Up Star',
      child: Column(
        children: [
          _outlined('Dress Up', big, const [
            Color(0xFFFF8FC7),
            Color(0xFFE0457E),
          ]),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD84D),
                size: 40,
                shadows: [Shadow(color: Color(0xFFFFFFFF), blurRadius: 6)],
              ),
              _outlined('Star', big * 1.15, const [
                Color(0xFFC9A8FF),
                Color(0xFF7C4DDB),
              ]),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD84D),
                size: 40,
                shadows: [Shadow(color: Color(0xFFFFFFFF), blurRadius: 6)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
