import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/outfit.dart';
import '../widgets/art_image.dart';
import '../services/game_audio.dart';
import '../services/looks_storage.dart';
import '../widgets/big_round_button.dart';

/// "My Looks": every saved outfit. Tap one to wear it again.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.storage, required this.audio});

  final LooksStorage storage;
  final GameAudio audio;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Outfit>? _looks;

  @override
  void initState() {
    super.initState();
    widget.storage.load().then((looks) {
      if (mounted) setState(() => _looks = looks);
    });
  }

  Future<void> _delete(int index) async {
    // Ask with pictures only: a big check to delete, a big X to keep.
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_rounded,
                size: 64,
                color: Color(0xFFB79CFF),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BigRoundButton(
                    key: const Key('delete_no'),
                    icon: Icons.close_rounded,
                    color: const Color(0xFF8EE08A),
                    semanticLabel: AppStrings.of(context).keep,
                    onTap: () {
                      widget.audio.play(Sfx.tap);
                      Navigator.pop(context, false);
                    },
                  ),
                  BigRoundButton(
                    key: const Key('delete_yes'),
                    icon: Icons.check_rounded,
                    color: const Color(0xFFFF6B8B),
                    semanticLabel: AppStrings.of(context).delete,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    widget.audio.play(Sfx.itemOff);
    final looks = await widget.storage.removeAt(index);
    if (mounted) setState(() => _looks = looks);
  }

  @override
  Widget build(BuildContext context) {
    final looks = _looks;
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    BigRoundButton(
                      key: const Key('back_button'),
                      icon: Icons.arrow_back_rounded,
                      color: const Color(0xFFB79CFF),
                      semanticLabel: AppStrings.of(context).back,
                      onTap: () {
                        widget.audio.play(Sfx.tap);
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    const GlossyCircle(
                      color: Color(0xFFFF8FC7),
                      size: 58,
                      child: Icon(
                        Icons.photo_library_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              Expanded(
                child: looks == null
                    ? const SizedBox.shrink()
                    : looks.isEmpty
                    ? const Center(
                        key: Key('gallery_empty'),
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: 120,
                          color: Color(0xFFFFC2DF),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 190,
                              childAspectRatio: 0.62,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        itemCount: looks.length,
                        itemBuilder: (context, i) => _lookCard(looks[i], i),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lookCard(Outfit look, int index) {
    // Cards pop in one after another.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + 60 * (index % 8)),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(
        scale: 0.85 + 0.15 * v,
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Pressable(
              key: Key('look_$index'),
              onTap: () {
                widget.audio.play(Sfx.itemOn);
                Navigator.pop(context, look);
              },
              builder: (pressed) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x40B06FA0),
                      blurRadius: pressed ? 4 : 12,
                      offset: Offset(0, pressed ? 2 : 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: LookPicture(look: look),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: BigRoundButton(
              key: Key('delete_$index'),
              icon: Icons.close_rounded,
              color: const Color(0xFFC9B8DA),
              size: 40,
              semanticLabel: AppStrings.of(context).delete,
              onTap: () {
                widget.audio.play(Sfx.tap);
                _delete(index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
