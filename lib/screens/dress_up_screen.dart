import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';
import '../painting/doll_painter.dart';
import '../painting/sparkle_painter.dart';
import '../services/looks_storage.dart';
import '../widgets/big_round_button.dart';
import '../widgets/item_thumbnail.dart';
import 'gallery_screen.dart';

/// The main game screen: the doll, the buttons and the wardrobe.
class DressUpScreen extends StatefulWidget {
  const DressUpScreen({super.key, required this.storage, this.random});

  final LooksStorage storage;
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
  Offset _sparkleAt = const Offset(100, 200);
  int _sparkleSeed = 0;
  late final Random _random = widget.random ?? Random();

  static final Animatable<double> _bounceScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.08,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.08,
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
  }

  @override
  void dispose() {
    _bounce.dispose();
    _sparkle.dispose();
    _flash.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  void _celebrate(Offset dollPoint) {
    _sparkleAt = dollPoint;
    _sparkleSeed++;
    _bounce.forward(from: 0);
    _sparkle.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _tapItem(GameItem item) {
    final wasWearing = _outfit.isWearing(item);
    setState(() {
      _outfit = _outfit.toggle(item);
      _activeSlot = item.slot;
    });
    if (!wasWearing || requiredSlots.contains(item.slot)) {
      _celebrate(focusRectFor(item.shape).center);
    } else {
      _bounce.forward(from: 0);
    }
  }

  void _tapColor(Slot slot, Color color) {
    setState(() => _outfit = _outfit.recolor(slot, color));
    final worn = _outfit[slot];
    if (worn != null) _celebrate(focusRectFor(worn.item.shape).center);
  }

  void _surprise() {
    setState(() => _outfit = Outfit.random(_random));
    _celebrate(const Offset(100, 190));
  }

  Future<void> _takePhoto() async {
    _flash.forward(from: 0);
    HapticFeedback.mediumImpact();
    final looks = await widget.storage.add(_outfit);
    if (mounted) setState(() => _savedCount = looks.length);
  }

  Future<void> _openGallery() async {
    final picked = await Navigator.of(context).push<Outfit>(
      MaterialPageRoute(builder: (_) => GalleryScreen(storage: widget.storage)),
    );
    final looks = await widget.storage.load();
    if (!mounted) return;
    setState(() {
      _savedCount = looks.length;
      if (picked != null) _outfit = picked;
    });
    if (picked != null) _celebrate(const Offset(100, 190));
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
      backgroundColor: const Color(0xFFFFF5FA),
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
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: DollPainter(outfit: _outfit, showDoll: false)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 76, bottom: 4),
                child: GestureDetector(
                  key: const Key('doll'),
                  onTap: () => _celebrate(const Offset(100, 190)),
                  child: AnimatedBuilder(
                    animation: _bounce,
                    builder: (context, child) {
                      final t = _bounce.value;
                      final scale = _bounce.isAnimating
                          ? _bounceScale.transform(t)
                          : 1.0;
                      final hop = _bounce.isAnimating
                          ? _bounceHop.transform(t)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, hop * 14),
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                      );
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: DollPainter(
                        outfit: _outfit,
                        showBackground: false,
                      ),
                    ),
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
                        onTap: _openGallery,
                      ),
                      const Spacer(),
                      BigRoundButton(
                        key: const Key('surprise_button'),
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFFFFB347),
                        semanticLabel: 'Surprise me',
                        onTap: _surprise,
                      ),
                      SizedBox(width: size.width < 360 ? 10 : 16),
                      BigRoundButton(
                        key: const Key('camera_button'),
                        icon: Icons.photo_camera_rounded,
                        color: const Color(0xFFFF6B8B),
                        semanticLabel: 'Save look',
                        onTap: _takePhoto,
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

  Widget _wardrobe() {
    final category = _category;
    final target = _colorTarget();
    final current = target == null ? null : _outfit[target];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category.colorOnly)
                _colorRow(category.colors, target!, current?.color, big: true)
              else ...[
                SizedBox(
                  height: 60,
                  child: current == null
                      ? const SizedBox.shrink()
                      : _colorRow(category.colors, target!, current.color),
                ),
                _itemRow(category),
              ],
              const SizedBox(height: 6),
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
    final d = big ? 62.0 : 46.0;
    return SizedBox(
      height: big ? 152 : 60,
      child: Center(
        child: big
            ? Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
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
    return GestureDetector(
      key: Key('color_$index'),
      onTap: () => _tapColor(slot, color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B4BA8)
                : const Color(0xFFE6DCEB),
            width: isSelected ? 4 : 2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.favorite_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: d * 0.42,
              )
            : null,
      ),
    );
  }

  Widget _itemRow(GameCategory category) {
    final items = itemsForCategory(category);
    return SizedBox(
      key: const Key('item_row'),
      height: 92,
      child: ListView.separated(
        key: ValueKey('items_${category.id}'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final worn = _outfit[item.slot];
          final selected = worn?.item.id == item.id;
          return GestureDetector(
            key: Key('item_${item.id}'),
            onTap: () => _tapItem(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 84,
              height: 84,
              margin: EdgeInsets.only(
                top: selected ? 0 : 4,
                bottom: selected ? 4 : 0,
              ),
              decoration: BoxDecoration(
                color: Color.lerp(category.buttonColor, Colors.white, 0.6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? darkenForBorder(category.buttonColor)
                      : Colors.transparent,
                  width: 4,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Padding(
                        padding: EdgeInsets.all(
                          item.slot == Slot.background ? 0 : 4,
                        ),
                        child: ItemThumbnail(
                          item: item,
                          color: selected ? worn!.color : item.color,
                        ),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: darkenForBorder(category.buttonColor),
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      key: const Key('category_bar'),
      height: 80,
      child: ListView.separated(
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
          return GestureDetector(
            key: Key('category_${category.id}'),
            onTap: () => setState(() {
              _categoryIndex = i;
              _activeSlot = null;
            }),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 74 : 64,
                height: selected ? 74 : 64,
                decoration: BoxDecoration(
                  color: category.buttonColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? darkenForBorder(category.buttonColor)
                        : Colors.white,
                    width: selected ? 4 : 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: preview != null
                      ? Padding(
                          padding: EdgeInsets.all(
                            preview.slot == Slot.background ? 0 : 6,
                          ),
                          child: ItemThumbnail(
                            item: preview,
                            color: preview.color,
                          ),
                        )
                      : Icon(
                          category.icon ?? Icons.star_rounded,
                          color: Colors.white,
                          size: 36,
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
