// Beach & Swim: the category, how swimwear is worn and drawn, challenges
// and the four Star Shop things.
import 'dart:io';

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/challenge.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:dress_up_star/screens/activities/makeup_screen.dart';
import 'package:flutter_test/flutter_test.dart';

GameItem _item(String id) => findItem(id)!;

Outfit _wear(List<String> ids) =>
    ids.fold(Outfit.starter(), (o, id) => o.wear(_item(id)));

final GameCategory _beach = gameCategories.firstWhere((c) => c.id == 'beach');

/// Every Beach & Swim thing, also the extras in other categories.
List<GameItem> get _all =>
    gameItems.where((i) => i.themes.contains(ChallengeTheme.summer)).toList();

Future<List<String>> _layers(Outfit outfit) async {
  final recipe = await dollRecipe(outfit);
  return [
    for (final l in [...recipe.under, ...recipe.over]) l.asset.split('/').last,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Beach category has the swimwear and cover-ups', () {
    final items = itemsForCategory(_beach);
    int count(String prefix) =>
        items.where((i) => i.shape.name.startsWith(prefix)).length;
    expect(count('swimDress'), 3);
    expect(count('swimRash'), 3);
    expect(count('swimBurkini'), 3);
    expect(count('swim'), 14); // 5 one-pieces and the 9 above
    expect(count('beach'), 3);
    expect(items.length, 17);
    expect(File(_beach.iconArt!).existsSync(), isTrue);
  });

  test('extras are in their usual categories', () {
    int count(String category) {
      final c = gameCategories.firstWhere((c) => c.id == category);
      return itemsForCategory(c).where(_all.contains).length;
    }

    expect(count('hats'), 6); // 4 sun hats and visors, 2 swim caps
    expect(count('glasses'), 2);
    expect(count('shoes'), 4);
    expect(count('accessories'), 7);
    expect(_all.length, 36);
    for (final item in _all) {
      expect(item.themes, contains(ChallengeTheme.beach), reason: item.id);
      expect(File(itemAsset(item.shape)).existsSync(), isTrue, reason: item.id);
    }
  });

  test('four Star Shop things, 4 to 9 stars', () {
    final shop = _all.where((i) => i.isSpecial).toList();
    expect(shop.map((i) => i.id).toSet(), {
      'shop_swim_mermaid',
      'shop_ring_flamingo',
      'shop_swim_burkini_rainbow',
      'shop_shoes_jelly_sparkle',
    });
    for (final item in shop) {
      expect(item.price, inInclusiveRange(4, 9), reason: item.id);
    }
  });

  test('swimwear is worn like a dress, cover-ups go over it', () {
    final swim = _wear(['top_tshirt', 'pants_jeans', 'swim_polka']);
    expect(swim[Slot.top], isNull);
    expect(swim[Slot.pants], isNull);
    expect(swim.wear(_item('skirt_tutu'))[Slot.dress], isNull);
    final covered = swim.wear(_item('beach_kaftan'));
    expect(covered[Slot.dress]!.item.id, 'swim_polka');
    expect(covered[Slot.jacket]!.item.id, 'beach_kaftan');
  });

  test('socks and tights are hidden under swimwear, then come back', () async {
    for (final swim in _all.where((i) => i.shape.isSwimwear)) {
      final o = _wear(['socks_rainbow_tights', swim.id]);
      expect(
        await _layers(o),
        isNot(contains('socksRainbow.svg')),
        reason: swim.id,
      );
      final parts = await dollParts(o);
      expect(
        parts.parts
            .expand((p) => p.layers)
            .any((l) => l.asset.contains('socks')),
        isFalse,
        reason: swim.id,
      );
      expect(await _layers(o.remove(Slot.dress)), contains('socksRainbow.svg'));
    }
  });

  test('burkini hoods and swim caps cover her hair', () async {
    final burkinis = _all.where((i) => i.shape.name.startsWith('swimBurkini'));
    for (final item in burkinis) {
      final names = await _layers(_wear([item.id]));
      expect(names, contains('${item.shape.name}_hood.svg'));
      expect(names, isNot(contains('hairLong.svg')));
      expect(names, isNot(contains('hairLong_back.svg')));
    }
    for (final id in ['hat_swim_cap', 'hat_swim_cap_flower']) {
      expect(await _layers(_wear([id])), isNot(contains('hairLong.svg')));
    }
    // A sun hat does not.
    expect(await _layers(_wear(['hat_straw'])), contains('hairLong.svg'));
    // The makeovers still see her hair.
    final close = closeUpOutfit(_wear(['swim_burkini_waves']));
    expect(await _layers(close), contains('hairLong.svg'));
  });

  test('a cover-up swings and keeps the sleeves under it', () async {
    final o = _wear(['swim_rash_shorts', 'beach_sundress']);
    expect(await _layers(o), contains('swimRashShorts_front.svg'));
    final parts = await dollParts(o);
    expect(
      parts.parts.any(
        (p) =>
            p.kind == PartKind.skirt &&
            p.layers.any((l) => l.asset.endsWith('beachSundress.svg')),
      ),
      isTrue,
    );
    // An ordinary jacket still covers them.
    final coat = _wear(['swim_rash_shorts', 'jacket_denim']);
    expect(await _layers(coat), isNot(contains('swimRashShorts_front.svg')));
  });

  test('arm floaties are on both arms, other things in her hand', () async {
    final floaties = await dollParts(_wear(['hand_floaties']));
    expect(floaties.parts.where((p) => p.isHeld), isEmpty);
    expect(
      floaties.parts.where(
        (p) => p.isArm && p.layers.any((l) => l.asset.contains('Floaties')),
      ),
      hasLength(2),
    );
    final ring = await dollParts(_wear(['hand_ring_duck']));
    expect(ring.parts.where((p) => p.isHeld), hasLength(1));
  });

  test('every beach look draws in every pose, body and skin', () async {
    for (final item in _all) {
      final o = _wear([
        'socks_knee',
        item.id,
      ]).copyWith(body: const DollBody(skin: 7, face: 2));
      for (final pose in DollPose.values) {
        await posedDollPainter(o, heldPoseFrame(pose));
      }
    }
  });

  test('beach things earn stars for the beach and summer cards', () {
    final look = _wear([
      'swim_frilly',
      'hat_straw',
      'shoes_jelly',
      'hand_beach_ball',
    ]);
    expect(challengeStars(look, ChallengeTheme.beach), 3);
    expect(challengeStars(look, ChallengeTheme.summer), 3);
    expect(challengeThemes, isNot(contains(ChallengeTheme.summer)));
  });

  test('beach looks save and open; older looks still open', () {
    final look = _wear([
      'shop_swim_burkini_rainbow',
      'beach_robe',
      'eyes_goggles',
      'shop_ring_flamingo',
      'shop_shoes_jelly_sparkle',
    ]);
    expect(Outfit.fromJson(look.toJson()), look);
    final old = Outfit.fromJson({
      'hair': {'id': 'hair_bun', 'color': 0xFF5B3A29},
      'dress': {'id': 'dress_party', 'color': 0xFFFF6B8B},
      'jacket': {'id': 'jacket_denim', 'color': 0xFF5F8FD9},
    });
    expect(old[Slot.dress]!.item.id, 'dress_party');
    expect(old[Slot.jacket]!.item.id, 'jacket_denim');
  });
}
