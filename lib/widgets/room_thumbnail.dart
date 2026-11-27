import 'package:flutter/material.dart';

import '../art/art_library.dart';
import '../art/room_art.dart';
import '../data/room_config.dart';
import 'art_image.dart';

/// A small picture of one thing for the room (the doll is not one).
class RoomThumbnail extends StatelessWidget {
  const RoomThumbnail({super.key, required this.item});

  final RoomItem item;

  @override
  Widget build(BuildContext context) {
    if (item.surface != RoomSurface.none) {
      return ArtImage(
        cacheKey: 'surface|${item.id}',
        draw: (pixels) {
          final picture = recordPicture((canvas) {
            canvas.scale(pixels.width / 120);
            final area = Offset.zero & pixels * (120 / pixels.width);
            canvas.clipRect(area);
            item.surface == RoomSurface.wallpaper
                ? paintWallpaper(canvas, item, area)
                : paintFloor(canvas, item, area);
          });
          return picture.toImage(pixels.width.round(), pixels.height.round());
        },
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: item.w / item.h,
        child: ArtImage(
          cacheKey: 'room_thumb|${item.id}',
          draw: (pixels) => rasterizeRoomItem(item, pixels),
        ),
      ),
    );
  }
}
