import 'package:flutter/material.dart';

import '../data/game_config.dart';
import '../models/outfit.dart';
import '../painting/doll_painter.dart';

/// A small drawing of one item, zoomed in on the doll.
class ItemThumbnail extends StatelessWidget {
  const ItemThumbnail({super.key, required this.item, required this.color});

  final GameItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final worn = <Slot, WornItem>{item.slot: WornItem(item, color)};
    final isBackground = item.slot == Slot.background;
    if (!isBackground && item.slot != Slot.hair) {
      // Show the item on a doll with simple hair so it is easy to recognise.
      final hair = itemsForSlot(Slot.hair).first;
      worn[Slot.hair] = WornItem(hair, hair.color);
    }
    return CustomPaint(
      painter: DollPainter(
        outfit: Outfit(worn),
        frame: focusRectFor(item.shape),
        showBackground: isBackground,
        showDoll: !isBackground,
      ),
    );
  }
}
