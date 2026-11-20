# Dress Up Star ⭐

A cute dress-up game for little kids, made with Flutter. No ads, no timers,
no reading needed and no way to lose.

**Play in the browser:** https://sheriefsobhy.github.io/dress-up-star/

## How to play

- Tap the big pink Play button on the start screen.
- Tap a big round button at the bottom to pick a category
  (hair, hair color, dresses, tops, skirts, shoes, accessories, background).
- Tap an item to put it on. Tap it again to take it off.
- Tap a round color button to change the item's color.
- ✨ Surprise me: a random outfit.
- 📷 Camera: saves the look to the "My Looks" gallery (top-left button).
- 🎵 Music button (top-right): turns all music and sounds on or off.
  In a browser the music starts after the first tap (browsers require this).

## Activities

The big rainbow button (bottom-left of the doll) opens the activities.
Pick a tool at the bottom, then rub a finger on the girl: the tool follows
the finger and only paints where it touches. The broom button takes
everything off (tap it again to bring it back); the green check goes back
to the doll and keeps the result. Results are saved with looks and show up
in "Surprise me".

- 💄 Makeup: lipstick, blush, eyeshadow (with glitter), eyelashes, face
  stickers and a sponge that wipes makeup off.
- 💇 Hair Salon (in any order): wash with shampoo and the shower, dry with
  the hair dryer (washed hair gets shiny), cut each side with the scissors
  (long, shoulder or short), curl or straighten with the curling iron, and
  spray paint the hair (8 colors including rainbow). The magic wand button
  grows the long hair back. The salon works on the long hair; picking
  another hairstyle in the wardrobe replaces the salon hairdo.
- 💅 Nails: soak in the bubble bowl, file, paint (10 colors including
  glitter, every nail can be a different color), drop on decorations
  (gems, hearts, stars, flowers) and use the dryer to make painted nails
  shine. Her face at the top smiles along.

Activity colors live at the end of `lib/data/game_config.dart`. Tool
pictures are SVGs in `assets/svg/tools/`.

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

Screenshots of the screens at phone size (written to `build/screenshots/`):

```
flutter test tool/screenshots_test.dart --plain-name "390"
```

Every push to `main` builds the web version and publishes it to GitHub Pages
(see `.github/workflows/deploy-web.yml`).

## Art

All the art is SVG (vector) drawings in `assets/svg/`:

- `doll/` - the girl (body, arms, head and her three faces).
- `items/` - one file per item shape, e.g. `dressPrincess.svg`. Optional
  `_back` (behind the body) and `_front` (over the arms, like sleeves) layers.
- `scenes/` - the cloud, sparkle and wave that move over the backgrounds.

Items are drawn in five placeholder colors (`#FF00FF`, `#FF66FF`, `#FFCCFF`,
`#CC00CC`, `#990099`) that the game swaps for the chosen color, so every item
can be any color. Clothes mark where their pattern goes with
`<g id="pattern"/>` inside a `<clipPath id="fabric">` outline.

The title font is Fredoka (SIL Open Font License, see `assets/fonts/OFL.txt`).

## Music and sounds

All music and sound effects are made from scratch by
[`tool/generate_sounds.dart`](tool/generate_sounds.dart) (no downloaded
audio). To change them, edit that file and run:

```
dart run tool/generate_sounds.dart
```
