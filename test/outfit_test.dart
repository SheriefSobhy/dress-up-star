import 'dart:io';
import 'dart:math';

import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('game config', () {
    test('item ids are unique', () {
      final ids = gameItems.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every category has items or is color-only, and previews exist', () {
      for (final c in gameCategories) {
        expect(c.colors, isNotEmpty, reason: c.id);
        if (!c.colorOnly) expect(itemsForCategory(c), isNotEmpty, reason: c.id);
        if (c.previewItemId != null) {
          expect(findItem(c.previewItemId!), isNotNull, reason: c.id);
        }
        if (c.iconArt != null) {
          expect(File(c.iconArt!).existsSync(), isTrue, reason: c.id);
        }
        expect(
          c.previewItemId != null || c.icon != null || c.iconArt != null,
          isTrue,
          reason: c.id,
        );
      }
    });

    test('starter items exist and every required slot has items', () {
      for (final id in starterItemIds) {
        expect(findItem(id), isNotNull);
      }
      for (final slot in requiredSlots) {
        expect(itemsForSlot(slot), isNotEmpty);
        expect(Outfit.starter()[slot], isNotNull);
      }
    });
  });

  group('outfit', () {
    final dress = findItem('dress_princess')!;
    final top = findItem('top_tshirt')!;
    final skirt = findItem('skirt_tutu')!;
    final hairBob = findItem('hair_bob')!;

    test('tap to wear, tap again to remove', () {
      final on = Outfit.starter().toggle(top);
      expect(on.isWearing(top), isTrue);
      expect(on[Slot.top]!.color, top.color);
      final off = on.toggle(top);
      expect(off.isWearing(top), isFalse);
      expect(off[Slot.top], isNull);
    });

    test('hair cannot be removed', () {
      final start = Outfit.starter();
      final hair = start[Slot.hair]!.item;
      expect(start.toggle(hair).isWearing(hair), isTrue);
    });

    test('a dress takes off top and skirt, and the other way round', () {
      final separates = Outfit.starter().wear(top).wear(skirt);
      final withDress = separates.wear(dress);
      expect(withDress[Slot.top], isNull);
      expect(withDress[Slot.skirt], isNull);
      expect(withDress.isWearing(dress), isTrue);
      expect(withDress.wear(top)[Slot.dress], isNull);
    });

    test('changing hair style keeps the hair color', () {
      const pink = Color(0xFFFF8FC7);
      final o = Outfit.starter().recolor(Slot.hair, pink).wear(hairBob);
      expect(o.isWearing(hairBob), isTrue);
      expect(o[Slot.hair]!.color.toARGB32(), pink.toARGB32());
    });

    test('recolor changes only the given slot', () {
      const blue = Color(0xFF7CB8FF);
      final o = Outfit.starter().wear(top).recolor(Slot.top, blue);
      expect(o[Slot.top]!.color.toARGB32(), blue.toARGB32());
      expect(Outfit.starter().recolor(Slot.top, blue)[Slot.top], isNull);
    });

    test('json round trip', () {
      final o = Outfit.starter()
          .wear(top)
          .wear(skirt)
          .recolor(Slot.skirt, const Color(0xFF8EE08A));
      expect(Outfit.fromJson(o.toJson()), o);
    });

    test('broken json falls back to required items', () {
      final o = Outfit.fromJson({
        'top': {'id': 'no_such_item', 'color': 1},
        'skirt': {'id': 'top_tshirt', 'color': 1}, // wrong slot
        'shoes': 'nonsense',
      });
      expect(o[Slot.top], isNull);
      expect(o[Slot.skirt], isNull);
      expect(o[Slot.hair], isNotNull);
      expect(o[Slot.background], isNotNull);
    });

    test('random outfits are always valid', () {
      final rnd = Random(42);
      for (var i = 0; i < 200; i++) {
        final o = Outfit.random(rnd);
        expect(o[Slot.hair], isNotNull);
        expect(o[Slot.background], isNotNull);
        expect(o[Slot.shoes], isNotNull);
        final hasDress = o[Slot.dress] != null;
        final hasSeparates = o[Slot.top] != null || o[Slot.skirt] != null;
        expect(hasDress != hasSeparates, isTrue);
        for (final entry in o.worn.entries) {
          expect(entry.value.item.slot, entry.key);
        }
      }
    });
  });
}
