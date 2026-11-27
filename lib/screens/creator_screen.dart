import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/doll_art.dart';
import '../l10n/app_strings.dart';
import '../models/outfit.dart';
import '../painting/sparkle_painter.dart';
import '../services/game_audio.dart';
import '../widgets/art_image.dart';
import '../widgets/big_round_button.dart';
import '../widgets/live_doll.dart';
import 'activities/makeup_screen.dart' show closeUpOutfit;

/// The character creator. Returns the chosen [DollBody], or null when
/// closed without saving.
Route<DollBody> creatorRoute({
  required Outfit outfit,
  required GameAudio audio,
  math.Random? random,
}) => PageRouteBuilder<DollBody>(
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, _, _) =>
      CreatorScreen(outfit: outfit, audio: audio, random: random),
  transitionsBuilder: (_, animation, _, child) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(begin: 0.88, end: 1.0).animate(
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

/// The part of doll space in the preview: her head and shoulders.
const Rect kCreatorFrame = Rect.fromLTRB(22, 28, 178, 214);

const Color _accent = Color(0xFF8B5CC9);

/// Option pictures have their own memory.
final ImageCache2 _optionImages = ImageCache2(90);

/// One thing that can be chosen.
enum _Feature {
  skin(Rect.fromLTRB(36, 44, 164, 172)),
  eyeColor(Rect.fromLTRB(60, 96, 96, 132)),
  eyeShape(Rect.fromLTRB(58, 94, 98, 134)),
  brows(Rect.fromLTRB(60, 76, 96, 112)),
  face(Rect.fromLTRB(32, 46, 168, 182)),
  freckles(Rect.fromLTRB(48, 98, 104, 154)),
  blush(Rect.fromLTRB(44, 114, 82, 152)),
  lips(Rect.fromLTRB(84, 124, 116, 156));

  const _Feature(this.crop);

  /// The part of doll space an option's picture shows.
  final Rect crop;

  int get count => switch (this) {
    skin => skinTones.length,
    eyeColor => eyeColors.length,
    eyeShape => eyeShapeCount,
    brows => browStyleCount,
    face => faceShapeCount,
    freckles => 2,
    blush => cheekColors.length,
    lips => lipColors.length,
  };

  int of(DollBody b) => switch (this) {
    skin => b.skin,
    eyeColor => b.eyeColor,
    eyeShape => b.eyeShape,
    brows => b.brows,
    face => b.face,
    freckles => b.freckles ? 1 : 0,
    blush => b.blush,
    lips => b.lips,
  };

  DollBody set(DollBody b, int v) => switch (this) {
    skin => b.copyWith(skin: v),
    eyeColor => b.copyWith(eyeColor: v),
    eyeShape => b.copyWith(eyeShape: v),
    brows => b.copyWith(brows: v),
    face => b.copyWith(face: v),
    freckles => b.copyWith(freckles: v == 1),
    blush => b.copyWith(blush: v),
    lips => b.copyWith(lips: v),
  };
}

/// Choosing a doll's skin and face with picture buttons only.
class CreatorScreen extends StatefulWidget {
  const CreatorScreen({
    super.key,
    required this.outfit,
    required this.audio,
    this.random,
  });

  /// The doll as she is now (her clothes show in the preview).
  final Outfit outfit;
  final GameAudio audio;
  final math.Random? random;

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen>
    with TickerProviderStateMixin {
  late DollBody _body = widget.outfit.body;
  _Feature _feature = _Feature.skin;
  late final math.Random _random = widget.random ?? math.Random();

  /// Nothing in front of her face while she is being made.
  late final Outfit _preview = closeUpOutfit(widget.outfit, glasses: false);

  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..addListener(() => _bounce.value = math.sin(_hop.value * math.pi));
  final ValueNotifier<double> _bounce = ValueNotifier(0);
  late final AnimationController _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// While this runs she shows her happy smile.
  Timer? _smileTimer;
  bool _smiling = false;
  int _changes = 0;

  @override
  void dispose() {
    _smileTimer?.cancel();
    _hop.dispose();
    _sparkle.dispose();
    _bounce.dispose();
    super.dispose();
  }

  /// Shows [body] with a happy reaction.
  void _change(DollBody body) {
    _smileTimer?.cancel();
    // A short smile, so the new eyes are soon open again.
    _smileTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _smiling = false);
    });
    setState(() {
      _body = body;
      _smiling = true;
      _changes++;
    });
    _hop.forward(from: 0);
    _sparkle.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _choose(int value) {
    widget.audio.play(Sfx.itemOn);
    _change(_feature.set(_body, value));
  }

  void _surprise() {
    widget.audio.play(Sfx.sparkle);
    var next = DollBody.random(_random);
    while (next == _body) {
      next = DollBody.random(_random);
    }
    _change(next);
  }

  void _save() {
    widget.audio.play(Sfx.unlock);
    Navigator.of(context).pop(_body);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final size = MediaQuery.sizeOf(context);
    final button = size.width < 380 ? 56.0 : 64.0;
    final short = size.height < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFFFEAF5),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE3F1), Color(0xFFEDE3FF), Color(0xFFE0F4FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BigRoundButton(
                      key: const Key('creator_close'),
                      icon: Icons.close_rounded,
                      color: const Color(0xFFB8AEC4),
                      size: button,
                      semanticLabel: strings.back,
                      onTap: () {
                        widget.audio.play(Sfx.tap);
                        Navigator.of(context).pop();
                      },
                    ),
                    BigRoundButton(
                      key: const Key('creator_random'),
                      icon: Icons.casino_rounded,
                      color: const Color(0xFFFFB347),
                      size: button,
                      semanticLabel: strings.randomDoll,
                      onTap: _surprise,
                    ),
                    BigRoundButton(
                      key: const Key('creator_save'),
                      icon: Icons.check_rounded,
                      color: const Color(0xFF5CCB6A),
                      size: button,
                      semanticLabel: strings.done,
                      onTap: _save,
                    ),
                  ],
                ),
              ),
              Expanded(child: _stage()),
              _panel(size.width, short),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Center(
        child: AspectRatio(
          aspectRatio: kCreatorFrame.width / kCreatorFrame.height,
          child: Container(
            key: const Key('creator_preview'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const RadialGradient(
                radius: 0.9,
                colors: [Color(0xFFFFFFFF), Color(0xFFFFD9EC)],
              ),
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40B06FA0),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LiveDoll(
                    outfit: _preview.copyWith(body: _body),
                    frame: kCreatorFrame,
                    face: _smiling ? Face.happy : Face.open,
                    bounce: _bounce,
                  ),
                  IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, box) => AnimatedBuilder(
                        animation: _sparkle,
                        builder: (context, _) => CustomPaint(
                          painter: SparklePainter(
                            progress: _sparkle.isAnimating ? _sparkle.value : 0,
                            center: box.biggest.center(Offset.zero),
                            seed: _changes,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(double width, bool short) {
    // Four choices fit side by side.
    final choice = math.min(short ? 54.0 : 70.0, (width - 24 - 30) / 4);
    final tab = math.min(short ? 46.0 : 58.0, (width - 24 - 30) / 4);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33B06FA0),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always room for two rows, so the preview does not jump.
          SizedBox(
            height: choice * 2 + 10,
            child: Center(
              child: SizedBox(
                width: choice * 4 + 31,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _feature.count; i++) _option(i, choice),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: short ? 6 : 10),
            child: Container(height: 2, color: const Color(0xFFF3E4F5)),
          ),
          SizedBox(
            width: tab * 4 + 31,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: short ? 6 : 10,
              children: [for (final f in _Feature.values) _tab(f, tab)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(int index, double size) {
    final selected = _feature.of(_body) == index;
    final body = _feature.set(_body, index);
    final crop = _feature.crop;
    return Semantics(
      button: true,
      selected: selected,
      label: '${index + 1}',
      child: Pressable(
        key: Key('option_$index'),
        onTap: () => _choose(index),
        builder: (pressed) => AnimatedScale(
          scale: selected ? 1.06 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFEAF5),
              border: Border.all(
                color: selected ? _accent : const Color(0xFFF0D9EC),
                width: selected ? 4 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? const Color(0x99C9A8FF)
                      : const Color(0x26B06FA0),
                  blurRadius: selected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: _FeaturePicture(
                key: ValueKey('${_feature.name}_$index'),
                body: body,
                crop: crop,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(_Feature feature, double size) {
    final selected = feature == _feature;
    // Icons where they say it best, otherwise a close-up of her own face.
    final (IconData?, Color) look = switch (feature) {
      _Feature.skin => (Icons.palette_rounded, const Color(0xFFFFB38A)),
      _Feature.eyeColor => (
        Icons.remove_red_eye_rounded,
        const Color(0xFF7CB8FF),
      ),
      _Feature.eyeShape => (null, const Color(0xFFC9A8FF)),
      _Feature.brows => (null, const Color(0xFFC9A8FF)),
      _Feature.face => (Icons.face_rounded, const Color(0xFF8EE08A)),
      _Feature.freckles => (Icons.grain_rounded, const Color(0xFFD9A066)),
      _Feature.blush => (Icons.favorite_rounded, const Color(0xFFFF8FAE)),
      _Feature.lips => (null, const Color(0xFFFF6FA5)),
    };
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        key: Key('tab_${feature.name}'),
        onTap: () {
          widget.audio.play(Sfx.tap);
          setState(() => _feature = feature);
        },
        builder: (pressed) => AnimatedScale(
          scale: selected ? 1.1 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: GlossyCircle(
            color: look.$2,
            size: size,
            pressed: pressed,
            rim: selected ? 4 : 3,
            rimColor: selected ? _accent : Colors.white,
            glow: selected ? look.$2 : null,
            child: look.$1 != null
                ? Icon(look.$1, color: Colors.white, size: size * 0.55)
                : Padding(
                    padding: EdgeInsets.all(size * 0.1),
                    child: ClipOval(
                      child: _FeaturePicture(
                        body: DollBody.classic,
                        crop: switch (feature) {
                          _Feature.eyeShape => const Rect.fromLTRB(
                            60,
                            75,
                            140,
                            155,
                          ),
                          _ => feature.crop,
                        },
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A close-up of a bald doll with [body], showing [crop] of doll space.
class _FeaturePicture extends StatelessWidget {
  const _FeaturePicture({super.key, required this.body, required this.crop});

  final DollBody body;
  final Rect crop;

  @override
  Widget build(BuildContext context) {
    return ArtImage(
      cacheKey: 'creator|${body.key}|${crop.left},${crop.top},${crop.width}',
      cache: _optionImages,
      draw: (pixels) async {
        final recipe = await dollRecipe(Outfit(const {}, body: body));
        return rasterizeDoll(recipe.flat(Face.open), crop, pixels, depth: true);
      },
    );
  }
}
