# Dress Up Star ⭐

A cute dress-up game for little kids, made with Flutter. No ads, no timers,
no reading needed and no way to lose.

**Play in the browser:** https://sheriefsobhy.github.io/dress-up-star/

## How to play

- Tap a big round button at the bottom to pick a category
  (hair, hair color, dresses, tops, skirts, shoes, accessories, background).
- Tap an item to put it on. Tap it again to take it off.
- Tap a round color button to change the item's color.
- ✨ Surprise me: a random outfit.
- 📷 Camera: saves the look to the "My Looks" gallery (top-left button).
- 🎵 Music button (top-right): turns all music and sounds on or off.
  In a browser the music starts after the first tap (browsers require this).

## Adding more items and colors

Everything you can choose lives in [`lib/data/game_config.dart`](lib/data/game_config.dart).
Copy an item line, give it a new unique `id`, and change its color or pattern.

## Running it on a computer

```
flutter pub get
flutter run -d chrome
```

## Checks

```
flutter analyze
flutter test
```

Every push to `main` builds the web version and publishes it to GitHub Pages
(see `.github/workflows/deploy-web.yml`).

## Music and sounds

All music and sound effects are made from scratch by
[`tool/generate_sounds.dart`](tool/generate_sounds.dart) (no downloaded
audio). To change them, edit that file and run:

```
dart run tool/generate_sounds.dart
```
