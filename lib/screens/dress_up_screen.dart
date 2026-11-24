import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/doll_art.dart';
import '../art/motion.dart';
import '../data/game_config.dart';
import '../models/challenge.dart';
import '../models/outfit.dart';
import '../painting/confetti_painter.dart';
import '../painting/shapes.dart';
import '../painting/sparkle_painter.dart';
import '../services/game_audio.dart';
import '../services/game_settings.dart';
import '../services/looks_storage.dart';
import '../services/rewards.dart';
import '../widgets/art_image.dart';
import '../widgets/big_round_button.dart';
import '../widgets/challenge_widgets.dart';
import '../widgets/doll_view.dart';
import '../widgets/reward_widgets.dart';
import '../widgets/scene_background.dart';
import 'activities/activity_picker.dart';
import 'gallery_screen.dart';
import 'star_shop_screen.dart';

/// The main game screen: the doll, the buttons and the wardrobe.
class DressUpScreen extends StatefulWidget {
  const DressUpScreen({
    super.key,
    required this.storage,
    required this.audio,
    this.random,
  });

  final LooksStorage storage;
  final GameAudio audio;
  final Random? random;

  @override
  State<DressUpScreen> createState() => _DressUpScreenState();
}

class _DressUpScreenState extends State<DressUpScreen>
    with TickerProviderStateMixin {
  Outfit _outfit = Outfit.starter();
  int _categoryIndex = 0;

  /// The slot the color buttons change (the last thing tapped).
  Slot? _activeSlot;
  int _savedCount = 0;

  /// Goes up each time the doll gets a little push (hair and skirt swing).
  int _nudge = 0;

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// While this runs the doll shows her big happy smile.
  late final AnimationController _happy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  int _confettiSeed = 0;

  /// Runs while she dances (confetti pops every couple of seconds).
  late final AnimationController _dance =
      AnimationController(vsync: this, duration: danceTime)
        ..addListener(_onDanceTick)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _stopDance();
        });
  bool _dancing = false;
  int _danceBursts = 0;

  /// The theme card she is being dressed for (null: no challenge).
  ChallengeTheme? _challenge;
  ChallengeTheme? _lastTheme;

  /// Stars and Star Shop items (saved on the device).
  final Rewards _rewards = Rewards();

  /// The unlock celebration, the "not enough stars yet" bubble and the
  /// daily gift (pictures on top of the stage).
  late final AnimationController _unlockShow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  late final AnimationController _needShow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  late final AnimationController _giftShow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  GameItem? _unlockedItem;
  GameItem? _neededItem;

  /// Goes up each time a locked item is tapped without enough stars.
  final Map<String, int> _shakes = {};

  /// Gently pushes the "scroll me" arrow sideways (a few times, then rests).
  late final AnimationController _hintBounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  final ScrollController _categoryScroll = ScrollController();
  bool _showScrollHint = false;
  late final AppLifecycleListener _lifecycle;

  Offset _sparkleAt = const Offset(100, 200);
  int _sparkleSeed = 0;
  late final Random _random = widget.random ?? Random();

  static final Animatable<double> _bounceScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.06,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.06,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]);
  static final Animatable<double> _bounceHop = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: -1,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: -1,
        end: 0,
      ).chain(CurveTween(curve: Curves.bounceOut)),
      weight: 65,
    ),
  ]);

  GameCategory get _category => gameCategories[_categoryIndex];

  @override
  void initState() {
    super.initState();
    widget.storage.load().then((looks) {
      if (mounted) setState(() => _savedCount = looks.length);
    });
    _loadRewards();
    widget.audio.load();
    // Pause the music while the app is in the background.
    _lifecycle = AppLifecycleListener(
      onHide: widget.audio.pauseMusic,
      onShow: widget.audio.resumeMusic,
    );
    _categoryScroll.addListener(_onCategoryScroll);
    _maybeShowScrollHint();
  }

  /// Loads the stars, then gives the daily star (with the gift animation)
  /// the first time the game is opened today.
  Future<void> _loadRewards() async {
    await _rewards.load();
    if (!mounted) return;
    setState(() {});
    if (await _rewards.claimDailyStar() && mounted) {
      widget.audio.play(Sfx.unlock);
      _giftShow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rewards.dispose();
    _unlockShow.dispose();
    _needShow.dispose();
    _giftShow.dispose();
    _lifecycle.dispose();
    _categoryScroll.dispose();
    _hintBounce.dispose();
    _bounce.dispose();
    _sparkle.dispose();
    _flash.dispose();
    _happy.dispose();
    _confetti.dispose();
    _dance.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ scroll hint

  /// The first time the game opens, an arrow shows that the category bar
  /// scrolls sideways. It goes away (for good) once the bar is scrolled.
  Future<void> _maybeShowScrollHint() async {
    if (await GameSettings.scrollHintSeen()) return;
    if (!mounted) return;
    // Wait for the bar to be laid out, then only show the arrow if there is
    // actually something to scroll to.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_categoryScroll.hasClients) return;
      if (_categoryScroll.position.maxScrollExtent <= 0) return;
      setState(() => _showScrollHint = true);
      _hintBounce.repeat(reverse: true, count: 10);
    });
  }

  void _onCategoryScroll() {
    if (_showScrollHint && _categoryScroll.offset > 12) {
      _hintBounce.stop();
      setState(() => _showScrollHint = false);
      GameSettings.markScrollHintSeen();
    }
  }

  // ---------------------------------------------------------------- actions

  void _celebrate(Offset dollPoint) {
    _sparkleAt = dollPoint;
    _sparkleSeed++;
    _bounce.forward(from: 0);
    _nudge++;
    _sparkle.forward(from: 0);
    _happy.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _burstConfetti() {
    _confettiSeed++;
    _confetti.forward(from: 0);
  }

  void _tapItem(GameItem item) {
    if (!_rewards.isUnlocked(item)) {
      _tapLocked(item);
      return;
    }
    final wasWearing = _outfit.isWearing(item);
    setState(() {
      _outfit = _outfit.toggle(item);
      _activeSlot = item.slot;
    });
    if (!wasWearing || requiredSlots.contains(item.slot)) {
      widget.audio.play(Sfx.itemOn);
      _celebrate(focusRectFor(item.shape).center);
    } else {
      widget.audio.play(Sfx.itemOff);
      _bounce.forward(from: 0);
      setState(() => _nudge++);
    }
  }

  /// A locked Star Shop item: unlock it if she has the stars (and put it
  /// on), otherwise a gentle shake and the stars still needed.
  Future<void> _tapLocked(GameItem item) async {
    if (await _rewards.unlock(item)) {
      if (!mounted) return;
      _showUnlocked(item);
      setState(() {
        _outfit = _outfit.wear(item);
        _activeSlot = item.slot;
      });
      _celebrate(focusRectFor(item.shape).center);
    } else {
      widget.audio.play(Sfx.notYet);
      HapticFeedback.lightImpact();
      setState(() {
        _neededItem = item;
        _shakes[item.id] = (_shakes[item.id] ?? 0) + 1;
      });
      _needShow.forward(from: 0);
    }
  }

  void _showUnlocked(GameItem item) {
    widget.audio.play(Sfx.unlock);
    HapticFeedback.mediumImpact();
    setState(() => _unlockedItem = item);
    _unlockShow.forward(from: 0);
    _burstConfetti();
  }

  Future<void> _openShop() async {
    widget.audio.play(Sfx.tap);
    final picked = await Navigator.of(context).push<GameItem>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => StarShopScreen(
          rewards: _rewards,
          audio: widget.audio,
          outfit: _outfit,
        ),
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
            alignment: Alignment.topRight,
            child: child,
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
    if (picked == null) return;
    // Put on what she picked, and show its category.
    final index = gameCategories.indexWhere(
      (c) => !c.colorOnly && c.slots.contains(picked.slot),
    );
    setState(() {
      _outfit = _outfit.wear(picked);
      _activeSlot = picked.slot;
      if (index >= 0) _categoryIndex = index;
    });
    _celebrate(focusRectFor(picked.shape).center);
  }

  void _tapColor(Slot slot, Color color) {
    widget.audio.play(Sfx.tap);
    setState(() => _outfit = _outfit.recolor(slot, color));
    final worn = _outfit[slot];
    if (worn != null) _celebrate(focusRectFor(worn.item.shape).center);
  }

  void _tapCategory(int index) {
    widget.audio.play(Sfx.tap);
    setState(() {
      _categoryIndex = index;
      _activeSlot = null;
    });
  }

  /// Each tap: the next pose (it is saved with the look).
  void _nextPose() {
    widget.audio.play(Sfx.itemOn);
    _stopDance();
    final next =
        poseButtonOrder[(poseButtonOrder.indexOf(_outfit.pose) + 1) %
            poseButtonOrder.length];
    setState(() => _outfit = _outfit.copyWith(pose: next));
    _happy.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _toggleDance() {
    if (_dancing) {
      widget.audio.play(Sfx.tap);
      _stopDance();
      return;
    }
    widget.audio.play(Sfx.sparkle);
    // She dances to the music (if the sound is on).
    widget.audio.startMusic();
    _danceBursts = 0;
    setState(() => _dancing = true);
    _dance.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _onDanceTick() {
    final seconds = _dance.value * danceTime.inMilliseconds / 1000;
    if (seconds >= _danceBursts * 2.4) {
      _danceBursts++;
      _burstConfetti();
    }
  }

  void _stopDance() {
    if (!_dancing) return;
    _dance.stop();
    setState(() => _dancing = false);
    _happy.forward(from: 0);
  }

  /// Shows a theme card (or the current one again).
  Future<void> _openChallenge() async {
    widget.audio.play(Sfx.tap);
    var theme = _challenge ?? pickTheme(_random, last: _lastTheme);
    while (true) {
      final choice = await showThemeCard(
        context,
        theme: theme,
        audio: widget.audio,
      );
      if (!mounted) return;
      if (choice != ThemeCardChoice.another) break;
      theme = pickTheme(_random, last: theme);
    }
    setState(() {
      _challenge = theme;
      _lastTheme = theme;
    });
  }

  /// The check button: stars for the outfit, and a happy celebration.
  Future<void> _checkChallenge() async {
    final theme = _challenge;
    if (theme == null) return;
    final stars = challengeStars(_outfit, theme);
    widget.audio.play(Sfx.itemOn);
    setState(() => _challenge = null);
    _celebrate(const Offset(100, 190));
    _burstConfetti();
    HapticFeedback.mediumImpact();
    await _rewards.addStars(stars);
    if (!mounted) return;
    await showChallengeResult(
      context,
      theme: theme,
      stars: stars,
      audio: widget.audio,
    );
    if (!mounted) return;
    setState(() {});
    _happy.forward(from: 0);
  }

  void _surprise() {
    widget.audio.play(Sfx.itemOn);
    setState(() => _outfit = Outfit.random(_random, _rewards.isUnlocked));
    _celebrate(const Offset(100, 190));
    _burstConfetti();
  }

  Future<void> _takePhoto() async {
    widget.audio.play(Sfx.camera);
    _flash.forward(from: 0);
    _burstConfetti();
    _happy.forward(from: 0);
    HapticFeedback.mediumImpact();
    final looks = await widget.storage.add(_outfit);
    if (mounted) setState(() => _savedCount = looks.length);
  }

  Future<void> _openGallery() async {
    widget.audio.play(Sfx.tap);
    final picked = await Navigator.of(context).push<Outfit>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) =>
            GalleryScreen(storage: widget.storage, audio: widget.audio),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.88, end: 1.0).animate(curved),
              alignment: Alignment.topLeft,
              child: child,
            ),
          );
        },
      ),
    );
    final looks = await widget.storage.load();
    if (!mounted) return;
    setState(() {
      _savedCount = looks.length;
      if (picked != null) _outfit = picked;
    });
    if (picked != null) _celebrate(const Offset(100, 190));
  }

  /// Activities: pick one, play, and come back with the result on the doll.
  Future<void> _openActivities() async {
    widget.audio.play(Sfx.tap);
    final activity = await showActivityPicker(
      context,
      audio: widget.audio,
      outfit: _outfit,
    );
    if (activity == null || !mounted) return;
    final result = await Navigator.of(
      context,
    ).push(activityRoute(activity, outfit: _outfit, audio: widget.audio));
    if (result == null || !mounted) return;
    setState(() => _outfit = result);
    _celebrate(const Offset(100, 130));
    _burstConfetti();
  }

  /// Which slot the color buttons should change in the current category.
  Slot? _colorTarget() {
    final category = _category;
    if (category.colorOnly) return category.slots.first;
    final active = _activeSlot;
    if (active != null &&
        category.slots.contains(active) &&
        _outfit[active] != null) {
      return active;
    }
    for (final slot in category.slots) {
      if (_outfit[slot] != null) return slot;
    }
    return null;
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F7),
      body: Column(
        children: [
          Expanded(child: _stage()),
          _wardrobe(),
        ],
      ),
    );
  }

  Widget _stage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final buttonSize = size.width < 380 ? 56.0 : 64.0;
        final gap = size.width < 360 ? 8.0 : 12.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            SceneBackground(
              scene:
                  _outfit[Slot.background] ??
                  Outfit.starter()[Slot.background]!,
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 76, bottom: 4),
                child: GestureDetector(
                  key: const Key('doll'),
                  onTap: () {
                    widget.audio.play(Sfx.tap);
                    _celebrate(const Offset(100, 190));
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_bounce, _happy, _dance]),
                    builder: (context, _) {
                      final t = _bounce.value;
                      final scale = _bounce.isAnimating
                          ? _bounceScale.transform(t)
                          : 1.0;
                      final hop = _bounce.isAnimating
                          ? _bounceHop.transform(t)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, hop * 16),
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.bottomCenter,
                          child: RepaintBoundary(
                            child: DollView(
                              outfit: _outfit,
                              happy: _happy.isAnimating || _dancing,
                              dancing: _dancing,
                              nudge: _nudge,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Sparkles
            IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 76, bottom: 4),
                  child: LayoutBuilder(
                    builder: (context, inner) {
                      final fit = FitTransform(kDollFrame, inner.biggest);
                      return AnimatedBuilder(
                        animation: _sparkle,
                        builder: (context, _) => CustomPaint(
                          size: Size.infinite,
                          painter: SparklePainter(
                            progress: _sparkle.isAnimating ? _sparkle.value : 0,
                            center: fit.apply(_sparkleAt),
                            seed: _sparkleSeed,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Confetti for the camera and "Surprise me"
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: ConfettiPainter(
                    progress: _confetti.isAnimating ? _confetti.value : 0,
                    origin: Offset(size.width / 2, size.height * 0.42),
                    seed: _confettiSeed,
                  ),
                ),
              ),
            ),
            // Star Shop pictures: unlocking, stars still needed, daily gift.
            AnimatedBuilder(
              animation: Listenable.merge([_unlockShow, _needShow, _giftShow]),
              builder: (context, _) => Stack(
                fit: StackFit.expand,
                children: [
                  if (_unlockedItem != null && _unlockShow.isAnimating)
                    UnlockCelebration(
                      item: _unlockedItem!,
                      progress: _unlockShow.value,
                    ),
                  if (_neededItem != null && _needShow.isAnimating)
                    Align(
                      alignment: const Alignment(0, 0.35),
                      child: NeedStars(
                        item: _neededItem!,
                        have: _rewards.stars,
                        progress: _needShow.value,
                      ),
                    ),
                  if (_giftShow.isAnimating)
                    Align(
                      alignment: const Alignment(0, 0.72),
                      child: SizedBox(
                        height: min(230.0, size.height * 0.42),
                        child: FittedBox(
                          child: DailyGift(progress: _giftShow.value),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Camera flash
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _flash,
                builder: (context, _) {
                  final v = _flash.isAnimating ? 1 - _flash.value : 0.0;
                  return ColoredBox(
                    color: Colors.white.withValues(alpha: v * 0.85),
                  );
                },
              ),
            ),
            // Challenge (and its check button) and Activities
            Positioned(
              left: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: child,
                    ),
                    child: _challenge == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsets.only(bottom: gap),
                            child: BigRoundButton(
                              key: const Key('challenge_check'),
                              icon: Icons.check_rounded,
                              color: const Color(0xFF5CCB6A),
                              semanticLabel: 'Done',
                              size: buttonSize,
                              onTap: _checkChallenge,
                            ),
                          ),
                  ),
                  ChallengeButton(
                    theme: _challenge,
                    size: buttonSize,
                    onTap: _openChallenge,
                  ),
                  SizedBox(height: gap + 4),
                  ActivitiesButton(
                    size: size.width < 380 ? 68 : 78,
                    onTap: _openActivities,
                  ),
                ],
              ),
            ),
            // Star Shop, Dance and Pose
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListenableBuilder(
                    listenable: _rewards,
                    builder: (context, _) => StarShopButton(
                      stars: _rewards.stars,
                      size: buttonSize,
                      onTap: _openShop,
                    ),
                  ),
                  SizedBox(height: gap + 4),
                  BigRoundButton(
                    key: const Key('dance_button'),
                    icon: Icons.celebration_rounded,
                    color: _dancing
                        ? const Color(0xFFFF5FA2)
                        : const Color(0xFFB079F2),
                    semanticLabel: 'Dance',
                    size: buttonSize,
                    onTap: _toggleDance,
                  ),
                  SizedBox(height: gap),
                  RingButton(
                    buttonKey: const Key('pose_button'),
                    label: 'Pose',
                    icon: Icons.emoji_people_rounded,
                    color: const Color(0xFFFFA63D),
                    ringColors: const [
                      Color(0xFFFFE066),
                      Color(0xFFFF8FC7),
                      Color(0xFFFFB347),
                      Color(0xFFFFF3B0),
                      Color(0xFFFFE066),
                    ],
                    size: size.width < 380 ? 68 : 78,
                    pulse: false,
                    onTap: _nextPose,
                  ),
                ],
              ),
            ),
            // Top buttons
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      BigRoundButton(
                        key: const Key('gallery_button'),
                        icon: Icons.photo_library_rounded,
                        color: const Color(0xFFB79CFF),
                        semanticLabel: 'My looks',
                        badge: _savedCount,
                        size: buttonSize,
                        onTap: _openGallery,
                      ),
                      const Spacer(),
                      BigRoundButton(
                        key: const Key('surprise_button'),
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFFFFB347),
                        semanticLabel: 'Surprise me',
                        size: buttonSize,
                        onTap: _surprise,
                      ),
                      SizedBox(width: gap),
                      BigRoundButton(
                        key: const Key('camera_button'),
                        icon: Icons.photo_camera_rounded,
                        color: const Color(0xFFFF6B8B),
                        semanticLabel: 'Save look',
                        size: buttonSize,
                        onTap: _takePhoto,
                      ),
                      SizedBox(width: gap),
                      // Mute / unmute all sounds (top-right).
                      ListenableBuilder(
                        listenable: widget.audio,
                        builder: (context, _) {
                          final muted = widget.audio.muted;
                          return BigRoundButton(
                            key: const Key('mute_button'),
                            icon: muted
                                ? Icons.music_off_rounded
                                : Icons.music_note_rounded,
                            color: muted
                                ? const Color(0xFFB8AEC4)
                                : const Color(0xFF4CC9C9),
                            semanticLabel: muted ? 'Sound off' : 'Sound on',
                            size: buttonSize,
                            onTap: widget.audio.toggleMuted,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Slides and fades the new row in when the category changes.
  Widget _switcher(Widget child) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 260),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    layoutBuilder: (current, previous) =>
        Stack(alignment: Alignment.center, children: [...previous, ?current]),
    child: child,
  );

  Widget _wardrobe() {
    final category = _category;
    final target = _colorTarget();
    final current = target == null ? null : _outfit[target];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, lighten(category.buttonColor, 0.75)],
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
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: lighten(category.buttonColor, 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 4),
              if (category.colorOnly)
                _switcher(
                  KeyedSubtree(
                    key: ValueKey('colors_${category.id}'),
                    child: _colorRow(
                      category.colors,
                      target!,
                      current?.color,
                      big: true,
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 60,
                  child: _switcher(
                    current == null
                        ? SizedBox.shrink(key: ValueKey('none_${category.id}'))
                        : KeyedSubtree(
                            key: ValueKey(
                              'colors_${category.id}_${target!.name}',
                            ),
                            child: _colorRow(
                              category.colors,
                              target,
                              current.color,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  key: const Key('item_row'),
                  height: 100,
                  child: _switcher(
                    KeyedSubtree(
                      key: ValueKey('items_${category.id}'),
                      child: _itemRow(category),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              _categoryBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorRow(
    List<Color> colors,
    Slot slot,
    Color? selected, {
    bool big = false,
  }) {
    final d = big ? 60.0 : 44.0;
    return SizedBox(
      height: big ? 156 : 60,
      child: Center(
        child: big
            ? Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < colors.length; i++)
                    _colorDot(colors[i], slot, selected, d, i),
                ],
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: colors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) =>
                    Center(child: _colorDot(colors[i], slot, selected, d, i)),
              ),
      ),
    );
  }

  Widget _colorDot(
    Color color,
    Slot slot,
    Color? selected,
    double d,
    int index,
  ) {
    final isSelected = selected?.toARGB32() == color.toARGB32();
    return Pressable(
      key: Key('color_$index'),
      onTap: () => _tapColor(slot, color),
      builder: (pressed) => AnimatedScale(
        scale: isSelected ? 1.12 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: GlossyCircle(
          color: color,
          size: d,
          pressed: pressed,
          rim: isSelected ? 4 : 3,
          rimColor: isSelected ? const Color(0xFF8B5CC9) : Colors.white,
          glow: isSelected ? lighten(color, 0.1) : null,
          child: isSelected
              ? Icon(
                  Icons.favorite_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: d * 0.42,
                  shadows: const [
                    Shadow(color: Color(0x55000000), blurRadius: 3),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _itemRow(GameCategory category) {
    final items = itemsForCategory(category);
    final accent = darkenForBorder(category.buttonColor);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final item = items[i];
        final worn = _outfit[item.slot];
        final selected = worn?.item.id == item.id;
        final locked = !_rewards.isUnlocked(item);
        final affordable = locked && _rewards.canAfford(item);
        return Shake(
          trigger: _shakes[item.id] ?? 0,
          child: Pressable(
            key: Key('item_${item.id}'),
            onTap: () => _tapItem(item),
            builder: (pressed) => AnimatedScale(
              scale: selected ? 1.06 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      lighten(category.buttonColor, selected ? 0.35 : 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? accent : Colors.white,
                    width: selected ? 3.5 : 2.5,
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: category.buttonColor.withValues(alpha: 0.95),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    BoxShadow(
                      color: const Color(0x2A7A4A8A),
                      blurRadius: pressed ? 3 : 7,
                      offset: Offset(0, pressed ? 1 : 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: EdgeInsets.all(
                            item.slot == Slot.background ? 0 : 3,
                          ),
                          child: Opacity(
                            opacity: locked && !affordable ? 0.6 : 1,
                            child: ItemThumbnail(
                              item: item,
                              color: selected ? worn!.color : item.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (locked) ...[
                      Positioned(
                        right: 2,
                        top: 2,
                        child: LockBadge(key: Key('lock_${item.id}'), size: 24),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 2,
                        child: Center(child: PricePill(price: item.price)),
                      ),
                    ],
                    if (selected)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: accent,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 84,
      child: Stack(
        children: [
          Positioned.fill(child: _categoryList()),
          if (_showScrollHint)
            Positioned(right: 6, top: 0, bottom: 0, child: _scrollHint()),
        ],
      ),
    );
  }

  /// A small bouncing arrow saying "this bar slides sideways".
  Widget _scrollHint() {
    return IgnorePointer(
      key: const Key('scroll_hint'),
      child: Center(
        child: AnimatedBuilder(
          animation: _hintBounce,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              8 * Curves.easeInOut.transform(_hintBounce.value) - 8,
              0,
            ),
            child: child,
          ),
          child: const GlossyCircle(
            color: Color(0xFFFF8FC7),
            size: 46,
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryList() {
    return SizedBox(
      key: const Key('category_bar'),
      height: 84,
      child: ListView.separated(
        controller: _categoryScroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: gameCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final category = gameCategories[i];
          final selected = i == _categoryIndex;
          final preview = category.previewItemId == null
              ? null
              : findItem(category.previewItemId!);
          return Pressable(
            key: Key('category_${category.id}'),
            onTap: () => _tapCategory(i),
            builder: (pressed) => Center(
              child: AnimatedScale(
                scale: selected ? 1.13 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: GlossyCircle(
                  color: category.buttonColor,
                  size: 64,
                  pressed: pressed,
                  rim: selected ? 4 : 3,
                  rimColor: selected
                      ? darkenForBorder(category.buttonColor)
                      : Colors.white,
                  glow: selected ? category.buttonColor : null,
                  child: category.iconArt != null
                      ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: ArtIcon(category.iconArt!),
                        )
                      : preview != null
                      ? Padding(
                          padding: EdgeInsets.all(
                            preview.slot == Slot.background ? 0 : 5,
                          ),
                          child: ItemThumbnail(
                            item: preview,
                            color: preview.color,
                          ),
                        )
                      : Icon(
                          category.icon ?? Icons.star_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Color darkenForBorder(Color c) => Color.lerp(c, Colors.black, 0.3)!;

/// The big glossy Activities button, with a rainbow ring and a gentle
/// pulse so it is easy to notice.
class ActivitiesButton extends StatelessWidget {
  const ActivitiesButton({super.key, required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RingButton(
    buttonKey: const Key('activities_button'),
    label: 'Activities',
    glow: const Color(0x66D873F0),
    icon: Icons.face_retouching_natural_rounded,
    color: const Color(0xFFFF6FB5),
    ringColors: const [
      Color(0xFFFF8FC7),
      Color(0xFFFFD84D),
      Color(0xFF8EE08A),
      Color(0xFF7CB8FF),
      Color(0xFFC9A8FF),
      Color(0xFFFF8FC7),
    ],
    size: size,
    onTap: onTap,
  );
}

/// A big glossy round button inside a colorful ring (Activities, Pose).
class RingButton extends StatefulWidget {
  const RingButton({
    super.key,
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.color,
    required this.ringColors,
    required this.size,
    required this.onTap,
    this.pulse = true,
    this.glow,
  });

  /// The key of the part that is tapped (used by tests).
  final Key buttonKey;
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> ringColors;
  final double size;
  final VoidCallback onTap;

  /// Gently grows and shrinks, so it is easy to notice.
  final bool pulse;

  /// The soft light around the ring (a see-through [color] if not set).
  final Color? glow;

  @override
  State<RingButton> createState() => _RingButtonState();
}

class _RingButtonState extends State<RingButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (GameMotion.idleAnimations && widget.pulse) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1300),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final button = Semantics(
      button: true,
      label: widget.label,
      child: Pressable(
        key: widget.buttonKey,
        onTap: widget.onTap,
        builder: (pressed) => Container(
          width: s,
          height: s,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: widget.ringColors),
            boxShadow: [
              BoxShadow(
                color: widget.glow ?? widget.color.withValues(alpha: 0.4),
                blurRadius: pressed ? 6 : 16,
                spreadRadius: pressed ? 0 : 2,
              ),
            ],
          ),
          child: GlossyCircle(
            color: widget.color,
            size: s - 8,
            pressed: pressed,
            rim: 3,
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: s * 0.52,
              shadows: [
                Shadow(
                  color: darken(widget.color, 0.4).withValues(alpha: 0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final pulse = _pulse;
    if (pulse == null) return button;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.06 * Curves.easeInOut.transform(pulse.value),
        child: child,
      ),
      child: button,
    );
  }
}
