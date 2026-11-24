import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';
import '../painting/confetti_painter.dart';
import '../services/game_audio.dart';
import '../services/rewards.dart';
import '../widgets/art_image.dart';
import '../widgets/big_round_button.dart';
import '../widgets/challenge_widgets.dart' show StarCount;
import '../widgets/reward_widgets.dart';

/// All Star Shop items, cheapest first.
List<GameItem> starShopItems() =>
    gameItems.where((i) => i.isSpecial).toList()
      ..sort((a, b) => a.price.compareTo(b.price));

/// The Star Shop: special items to unlock with stars (no real money).
/// Tapping an unlocked item closes the shop and returns it, to wear.
class StarShopScreen extends StatefulWidget {
  const StarShopScreen({
    super.key,
    required this.rewards,
    required this.audio,
    required this.outfit,
  });

  final Rewards rewards;
  final GameAudio audio;

  /// What she wears now (worn items get a check).
  final Outfit outfit;

  @override
  State<StarShopScreen> createState() => _StarShopScreenState();
}

class _StarShopScreenState extends State<StarShopScreen>
    with TickerProviderStateMixin {
  late final AnimationController _unlock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  late final AnimationController _need = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  GameItem? _unlocked;
  GameItem? _needed;
  final Map<String, int> _shakes = {};
  int _confettiSeed = 100;

  @override
  void dispose() {
    _unlock.dispose();
    _need.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _tap(GameItem item) async {
    final rewards = widget.rewards;
    if (rewards.isUnlocked(item)) {
      widget.audio.play(Sfx.itemOn);
      Navigator.of(context).pop(item);
      return;
    }
    if (await rewards.unlock(item)) {
      if (!mounted) return;
      widget.audio.play(Sfx.unlock);
      HapticFeedback.mediumImpact();
      setState(() {
        _unlocked = item;
        _confettiSeed++;
      });
      _unlock.forward(from: 0);
      _confetti.forward(from: 0);
    } else {
      widget.audio.play(Sfx.notYet);
      HapticFeedback.lightImpact();
      setState(() {
        _needed = item;
        _shakes[item.id] = (_shakes[item.id] ?? 0) + 1;
      });
      _need.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = starShopItems();
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE3F1), Color(0xFFEDE3FF)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
                    child: Row(
                      children: [
                        BigRoundButton(
                          key: const Key('shop_back'),
                          icon: Icons.arrow_back_rounded,
                          color: const Color(0xFFB79CFF),
                          semanticLabel: 'Back',
                          size: 56,
                          onTap: () {
                            widget.audio.play(Sfx.tap);
                            Navigator.of(context).pop();
                          },
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.card_giftcard_rounded,
                          color: Color(0xFFFF6FA8),
                          size: 44,
                        ),
                        const Spacer(),
                        ListenableBuilder(
                          listenable: widget.rewards,
                          builder: (context, _) => Transform.scale(
                            scale: 1.35,
                            alignment: Alignment.centerRight,
                            child: StarCount(stars: widget.rewards.stars),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final columns = box.maxWidth < 360 ? 2 : 3;
                        return ListenableBuilder(
                          listenable: widget.rewards,
                          builder: (context, _) => GridView.builder(
                            key: const Key('shop_grid'),
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.82,
                                ),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _card(items[i]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: ConfettiPainter(
                    progress: _confetti.isAnimating ? _confetti.value : 0,
                    origin: Offset(
                      MediaQuery.sizeOf(context).width / 2,
                      MediaQuery.sizeOf(context).height * 0.45,
                    ),
                    seed: _confettiSeed,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _unlock,
              builder: (context, _) => _unlocked == null
                  ? const SizedBox.shrink()
                  : UnlockCelebration(
                      item: _unlocked!,
                      progress: _unlock.isAnimating ? _unlock.value : 0,
                    ),
            ),
            AnimatedBuilder(
              animation: _need,
              builder: (context, _) => _needed == null
                  ? const SizedBox.shrink()
                  : Center(
                      child: NeedStars(
                        item: _needed!,
                        have: widget.rewards.stars,
                        progress: _need.isAnimating ? _need.value : 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(GameItem item) {
    final rewards = widget.rewards;
    final unlocked = rewards.isUnlocked(item);
    final affordable = !unlocked && rewards.canAfford(item);
    final wearing = widget.outfit.isWearing(item);
    return Shake(
      trigger: _shakes[item.id] ?? 0,
      child: Pressable(
        key: Key('shop_item_${item.id}'),
        onTap: () => _tap(item),
        builder: (pressed) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFF0F8)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: affordable
                  ? const Color(0xFFFFC23D)
                  : unlocked
                  ? const Color(0xFF8FD99A)
                  : Colors.white,
              width: affordable || unlocked ? 3.5 : 2.5,
            ),
            boxShadow: [
              if (affordable)
                const BoxShadow(color: Color(0x88FFD36B), blurRadius: 14),
              BoxShadow(
                color: const Color(0x2A7A4A8A),
                blurRadius: pressed ? 3 : 8,
                offset: Offset(0, pressed ? 1 : 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 26),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Opacity(
                      opacity: unlocked || affordable ? 1 : 0.75,
                      child: ItemThumbnail(item: item, color: item.color),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: Center(
                  child: unlocked
                      ? Icon(
                          wearing
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded,
                          key: Key('owned_${item.id}'),
                          color: const Color(0xFF4CB65A),
                          size: 24,
                        )
                      : PricePill(price: item.price),
                ),
              ),
              if (!unlocked)
                Positioned(
                  right: -4,
                  top: -4,
                  child: LockBadge(key: Key('shop_lock_${item.id}')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
