# Dress Up Star ⭐

A cute dress-up game for little kids, made with Flutter. No ads, no timers,
no reading needed and no way to lose.

**Play in the browser:** https://sheriefsobhy.github.io/dress-up-star/

## How to play

- Tap the big pink Play button on the start screen.
- Tap a big round button at the bottom to pick a category
  (hair, hair color, dresses, tops, skirts, shoes, accessories, jewelry,
  glasses, background). The bar slides sideways.
- Jewelry: a necklace, earrings and a bracelet can all be worn together.
- Glasses: eye glasses and sunglasses, one pair at a time.
- Tap an item to put it on. Tap it again to take it off.
- Tap a round color button to change the item's color.
- ✨ Surprise me: a random outfit.
- 📷 Camera: saves the look to the "My Looks" gallery (top-left button).
- 🎁 Star Shop (right side): special items to unlock with stars.
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





## Star Shop and stars

- Stars come from challenges, plus one star a day the first time the game
  is opened (a little gift box pops open). No real money, no ads.
- The pink gift button (right, top of the column) shows the stars and opens
  the Star Shop: 16 special items for 3 to 15 stars - princess and ice
  gowns, rainbow dress, ballerina tutu, butterfly and fairy wings (worn on
  her back, in Accessories), unicorn headband, sparkly and gold boots,
  diamond necklace, rainbow sunglasses, a kitten, a gray kitten and a puppy
  to hold, the castle ballroom and unicorn land.
- Locked items also show in their normal category with a lock and their
  price. Enough stars: tap to unlock (light rays, confetti, a "ta-da").
  Not enough: a gentle shake and a bubble with gold stars (have) and pale
  stars (still needed).
- Saved on the device: every star earned, and every unlocked item with the
  stars paid, so stars and items are never lost. Surprise me only uses
  unlocked items.
- Shop items are the entries with `price:` in `lib/data/game_config.dart`.
  Their pictures are in `assets/svg/items/` (wings use the new `back` slot).
## Challenges

- The gold trophy button (left, above Activities) shows a picture card:
  beach, snow, party, princess ball, garden or bedtime. Three little item
  pictures on the card give ideas. Green play button: start; purple
  shuffle button: another card.
- Dress her up, then tap the green check. More items that fit the theme
  give more stars (1 to 3 - there is always at least one star, and always
  a celebration). The gold pill on the trophy shows all stars collected.
- Each item's themes are the `themes:` tags in `lib/data/game_config.dart`;
  how many matching items give 2 or 3 stars is `matchesForTwoStars` /
  `matchesForThreeStars` there. Theme pictures are in `assets/svg/themes/`.
## Poses and dancing

- The big orange Pose button (bottom-right): each tap does the next pose -
  wave, twirl, peace sign, hands on hips, curtsy, jump. The pose is saved
  with the look (camera) and shows in "My Looks".
- The purple Dance button above it: she dances in time with the music for
  10 seconds with confetti. Tap it again (or Pose) to stop.
- The pose order and dance time are at `poseButtonOrder` / `danceTime` in
  `lib/data/game_config.dart`; the poses themselves are in
  `lib/art/doll_pose.dart` (where her hands go, and how her body moves).
## Sparkles and swinging

- Jewelry, crowns, tiaras, the wand, sunglasses and glitter nails (or nail
  gems) sparkle with moving glints. Which items sparkle is the
  `shinyShapes` list in `lib/data/game_config.dart`.
- The sparkle is a fragment shader (`shaders/shine.frag`). If a phone or
  browser can't run shaders, little twinkling stars are drawn instead.
- Hair and skirts swing when she hops, moves or is tapped, then settle
  (`SwayPhysics` in `lib/art/doll_pose.dart`).
- The doll is split into moving parts (hair, skirt, arms, held things) in
  `lib/art/doll_parts.dart`; each part is turned into a picture once per
  outfit, so every frame only moves ready-made pictures.
## For parents

- The small gear (top corner of the start screen) opens the parents'
  screen. Hold it for 3 seconds (a ring fills up), then answer a
  times-table question on the number pad.
- Inside: music on/off, sound effects on/off, language (phone language,
  English or Arabic), fewer effects (lite mode), show the how-to-play
  again, the privacy policy and reset progress (stars, Star Shop items and
  saved looks; asks first).
- The game collects no data: no ads, no analytics, no accounts, no
  internet, no links out. Privacy policy (English and Arabic):
  https://sheriefsobhy.github.io/dress-up-star/privacy.html
  (`web/privacy.html`, published with the web game).

## Languages

English and Arabic (right to left). The phone's language is used unless a
parent picks one. All words are in `lib/l10n/app_strings.dart`; the game's
name stays "Dress Up Star". Fredoka has no Arabic letters, so phones show
Arabic in their own font.

## First-time tutorial

The first time the game opens, a big pointing finger shows what to do (no
reading): tap an item, slide the bottom bar, tap Pose, open the Star Shop.
Each step waits until it is done. The gray X skips it; it can be shown again
from the parents' screen (`lib/widgets/tutorial_overlay.dart`).

## Lite mode (slow phones)

`lib/services/frame_watcher.dart` watches frame times. When more than a
quarter of the frames are slow (over 24 ms) for two checks in a row, lite
mode turns on and is remembered: the clouds, the doll's breathing,
sparkles and pulsing buttons stop, and there is less confetti. Parents can
switch it with "Fewer effects".

## Adding more items and colors

Everything you can choose lives in [`lib/data/game_config.dart`](lib/data/game_config.dart).
Copy an item line, give it a new unique `id`, and change its color or pattern.

## Running it on a computer

```
flutter pub get
flutter run -d chrome
```

## Android app

Built on this computer (not on GitHub):

```
flutter build apk --release --split-per-abi  # one small APK per phone type, in build/app/outputs/flutter-apk/
flutter build appbundle --release  # build/app/outputs/bundle/release/app-release.aab (Google Play)
```

The app id is `com.sheriefsobhy.dressupstar`. Release builds are signed with
the key named in `android/key.properties`. That file and the key are kept out
of git. Without it, the release is signed with the debug key, which cannot
update the real app.

The app icon and splash picture are drawn from the doll's face by
`flutter test tool/generate_app_icon_test.dart`.

## Checks

```
flutter analyze
flutter test
```

Screenshots of the screens at phone size (written to `build/screenshots/`):

```
flutter test tool/screenshots_test.dart --plain-name "390"
```

Run one scene at a time. The parents' screens, tutorial and main screens
in each language are `--plain-name "parents 390 ar"`, `"tutorial 320 en"`,
`"tour 390 ar"` (any of 390/320 and en/ar). `--plain-name "accessory grids"` draws every
pair of glasses on every hairstyle, and all the jewelry.

Every push to `main` builds the web version and publishes it to GitHub Pages
(see `.github/workflows/deploy-web.yml`).

## Art

All the art is SVG (vector) drawings in `assets/svg/`:

- `doll/` - the girl (body, arms, head and her three faces).
- `items/` - one file per item shape, e.g. `dressPrincess.svg`. Optional
  `_back` (behind the body) and `_front` (over the arms, like sleeves) layers.
- `scenes/` - the cloud, sparkle and wave that move over the backgrounds.
- `icons/` - pictures for category buttons (jewelry, glasses).
- `tools/` - the activity tools (lipstick, scissors, nail polish...).

The jewelry and glasses art is made by
[`tool/generate_accessory_art.dart`](tool/generate_accessory_art.dart), so both
sides of a pair match exactly: edit it and run
`dart run tool/generate_accessory_art.dart`.

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
