import 'package:flutter/material.dart';

import '../art/doll_art.dart';
import '../l10n/app_strings.dart';
import '../models/outfit.dart';
import '../services/dolls_storage.dart';
import 'art_image.dart';
import 'big_round_button.dart';

/// Portraits are kept apart from the item thumbnails, so dressing a doll
/// never pushes those out of memory.
final ImageCache2 _portraits = ImageCache2(24);

const Color _accent = Color(0xFF8B5CC9);

/// A doll's face in a round frame.
class DollFace extends StatelessWidget {
  const DollFace({
    super.key,
    required this.outfit,
    required this.size,
    this.selected = false,
  });

  final Outfit outfit;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFD9EC)],
        ),
        border: Border.all(
          color: selected ? _accent : Colors.white,
          width: selected ? 3.5 : 2.5,
        ),
        boxShadow: [
          if (selected)
            const BoxShadow(
              color: Color(0xCCC9A8FF),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          const BoxShadow(
            color: Color(0x40B06FA0),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: ArtImage(
          cacheKey: 'doll_face|${outfitKey(outfit)}',
          cache: _portraits,
          draw: (pixels) async {
            final recipe = await dollRecipe(outfit);
            return rasterizeDoll(
              recipe.flat(Face.open),
              const Rect.fromLTRB(34, 34, 166, 166),
              pixels,
              depth: true,
            );
          },
        ),
      ),
    );
  }
}

/// The row of dolls at the top of the main screen: tap a face to play with
/// her, + for a new one, the little x to say goodbye, and the face with a
/// pencil to change her.
class DollStrip extends StatelessWidget {
  const DollStrip({
    super.key,
    required this.dolls,
    required this.faceSize,
    required this.onShow,
    required this.onAdd,
    required this.onDelete,
    required this.onCreate,
  });

  final Dolls dolls;
  final double faceSize;
  final void Function(int id) onShow;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final s = faceSize;
    return SizedBox(
      height: s + 6,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('doll_strip'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              child: Row(
                children: [
                  for (var i = 0; i < dolls.list.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _portrait(strings, dolls.list[i], i),
                  ],
                  if (!dolls.isFull) ...[
                    const SizedBox(width: 6),
                    BigRoundButton(
                      key: const Key('doll_add'),
                      icon: Icons.add_rounded,
                      color: const Color(0xFF5CCB6A),
                      size: s,
                      semanticLabel: strings.newDoll,
                      onTap: onAdd,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _createButton(strings),
        ],
      ),
    );
  }

  Widget _portrait(AppStrings strings, Outfit doll, int index) {
    final selected = doll.dollId == dolls.activeId;
    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Semantics(
            button: true,
            selected: selected,
            label: '${strings.doll} ${index + 1}',
            child: Pressable(
              key: Key('doll_${doll.dollId}'),
              onTap: () => onShow(doll.dollId),
              builder: (pressed) =>
                  DollFace(outfit: doll, size: faceSize, selected: selected),
            ),
          ),
          if (selected && dolls.list.length > 1)
            Positioned(
              right: -2,
              bottom: -2,
              child: Semantics(
                button: true,
                label: strings.delete,
                child: Pressable(
                  key: const Key('doll_delete'),
                  onTap: onDelete,
                  builder: (pressed) => const GlossyCircle(
                    color: Color(0xFFC9B8DA),
                    size: 20,
                    rim: 1.5,
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// A doll face with a pencil.
  Widget _createButton(AppStrings strings) {
    final s = faceSize + 6;
    return Semantics(
      button: true,
      label: strings.editDoll,
      child: Pressable(
        key: const Key('create_button'),
        onTap: onCreate,
        builder: (pressed) => SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GlossyCircle(
                color: const Color(0xFFFF6FB5),
                size: s,
                pressed: pressed,
                rim: 3,
                child: Icon(
                  Icons.face_3_rounded,
                  color: Colors.white,
                  size: s * 0.64,
                ),
              ),
              Positioned(
                right: -4,
                bottom: -3,
                child: GlossyCircle(
                  color: const Color(0xFFFFB347),
                  size: s * 0.48,
                  rim: 2,
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: s * 0.3,
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
