// The second wardrobe: new categories, their rules and old saved looks.
import 'dart:io';

import 'package:dress_up_star/art/doll_art.dart';
import 'package:dress_up_star/data/game_config.dart';
import 'package:dress_up_star/models/outfit.dart';
import 'package:flutter_test/flutter_test.dart';

GameItem _item(String id) => findItem(id)!;

Outfit _wear(List<String> ids) =>
    ids.fold(Outfit.starter(), (o, id) => o.wear(_item(id)));

List<GameItem> _in(String id) =>
    itemsForCategory(gameCategories.firstWhere((c) => c.id == id));

void main() {
  test('each new category has its items', () {
    const counts = {
      'jackets': 6,
      'pants': 5,
      // With the Beach extras.
      'hats': 12,
      'costumes': 6,
      'pajamas': 4,
      'sportswear': 4,
      'socks': 5,
      // The older kinds, two more each (without the Star Shop ones).
      'dresses': 10,
      'tops': 6,
      'skirts': 5,
      'shoes': 9,
    };
    for (final e in counts.entries) {
      final items = _in(e.key).where(
        (i) =>
            !i.isSpecial ||
            const ['hats', 'costumes', 'pajamas'].contains(e.key),
      );
      expect(items.length, e.value, reason: e.key);
    }
    for (final item in gameItems) {
      expect(item.themes, isNotEmpty, reason: item.id);
      expect(File(itemAsset(item.shape)).existsSync(), isTrue, reason: item.id);
    }
  });

  test('five new Star Shop items, 5 to 12 stars', () {
    final shop = [
      for (final c in ['hats', 'costumes', 'pajamas'])
        ..._in(c).where((i) => i.isSpecial),
    ];
    expect(shop.length, 5);
    for (final item in shop) {
      expect(item.price, inInclusiveRange(5, 12), reason: item.id);
    }
  });

  test('pants replace skirts and dresses, but keep her top', () {
    final jeans = _wear(['top_tshirt', 'skirt_tutu', 'pants_jeans']);
    expect(jeans[Slot.skirt], isNull);
    expect(jeans[Slot.top], isNotNull);
    expect(jeans.wear(_item('skirt_aline'))[Slot.pants], isNull);
    expect(jeans.wear(_item('costume_chef'))[Slot.pants], isNull);
    expect(_wear(['dress_sun', 'pants_shorts'])[Slot.dress], isNull);
  });

  test('hats and crowns take turns; jackets go over anything', () {
    final hat = _wear(['head_crown', 'hat_beanie']);
    expect(hat[Slot.head], isNull);
    expect(hat.wear(_item('head_tiara'))[Slot.hat], isNull);
    final coat = _wear(['dress_sun', 'jacket_puffer', 'socks_knee']);
    expect(coat[Slot.dress], isNotNull);
    expect(coat[Slot.jacket], isNotNull);
    expect(coat.wear(_item('top_polo'))[Slot.jacket], isNotNull);
  });

  test('layers: socks, shoes, pants, top, jacket', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Future<List<String>> under(List<String> ids) async => (await dollRecipe(
      _wear(ids),
    )).under.map((l) => l.asset.split('/').last).toList();

    final names = await under([
      'socks_striped',
      'shoes_sneakers',
      'pants_jeans',
      'top_sweater',
      'jacket_denim',
    ]);
    final order = [
      'body.svg',
      'socksStriped.svg',
      'shoesSneakers.svg',
      'pantsJeans.svg',
      'topSweater.svg',
      'jacketDenim.svg',
      'arm_left.svg',
      'jacketDenim_front.svg',
    ].map(names.indexOf).toList();
    expect(order, [...order]..sort());
    expect(order.first, isNonNegative);
    // The jacket sleeves cover the sweater sleeves.
    expect(names, isNot(contains('topSweater_front.svg')));

    // Leggings tuck into shoes; the mermaid tail hides feet.
    final tucked = await under(['pants_leggings', 'shoes_boots']);
    expect(
      tucked.indexOf('pantsLeggings.svg'),
      lessThan(tucked.indexOf('shoesBoots.svg')),
    );
    final mermaid = await under([
      'shoes_boots',
      'socks_knee',
      'shop_costume_mermaid',
    ]);
    expect(mermaid, isNot(contains('shoesBoots.svg')));
    expect(mermaid, isNot(contains('socksKnee.svg')));
  });

  test('trousers stand still, skirts and nighties swing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Future<bool> swings(String id) async =>
        (await dollParts(_wear([id]))).parts.any(
          (p) =>
              p.kind == PartKind.skirt &&
              p.layers.any((l) => l.slot == Slot.dress),
        );
    expect(await swings('pajama_hearts'), isTrue);
    expect(await swings('sport_tennis'), isTrue);
    expect(await swings('pajama_stars'), isFalse);
    expect(await swings('costume_doctor'), isFalse);
  });

  test('new things are saved with a look, and old looks still open', () {
    final look = _wear([
      'top_blouse',
      'pants_flared',
      'jacket_blazer',
      'socks_frilly',
      'hat_beret',
    ]);
    expect(Outfit.fromJson(look.toJson()), look);

    // A look saved before these clothes existed.
    final old = Outfit.fromJson({
      'hair': {'id': 'hair_bun', 'color': 0xFF5B3A29},
      'background': {'id': 'bg_sky', 'color': 0xFFBDE3FF},
      'dress': {'id': 'dress_party', 'color': 0xFFFF6B8B},
      'head': {'id': 'head_crown', 'color': 0xFFFFD84D},
    });
    expect(old[Slot.dress]!.item.id, 'dress_party');
    expect(old[Slot.head]!.item.id, 'head_crown');
    expect(old.worn.length, 4);
  });
}
