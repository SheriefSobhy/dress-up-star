import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/motion.dart';
import '../art/room_art.dart';
import '../data/room_config.dart';
import '../l10n/app_strings.dart';
import '../models/outfit.dart';
import '../models/room.dart';
import '../painting/confetti_painter.dart';
import '../painting/shapes.dart';
import '../services/game_audio.dart';
import '../services/looks_storage.dart';
import '../services/rewards.dart';
import '../services/room_storage.dart';
import '../widgets/art_image.dart';
import '../widgets/big_round_button.dart';
import '../widgets/doll_view.dart';
import '../widgets/reward_widgets.dart';
import '../widgets/room_thumbnail.dart';

Route<void> roomRoute({
  required Outfit outfit,
  required Rewards rewards,
  required LooksStorage storage,
  required GameAudio audio,
  RoomItem? place,
}) => PageRouteBuilder<void>(
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, _, _) => RoomScreen(
    outfit: outfit,
    rewards: rewards,
    storage: storage,
    audio: audio,
    place: place,
  ),
  transitionsBuilder: (_, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

/// Room Decorating: her doll's own bedroom. Pictures only: tap something in
/// the bar to put it in the room, drag it with a finger, pinch it bigger or
/// smaller, and drag it to the trash can to take it away.
class RoomScreen extends StatefulWidget {
  const RoomScreen({
    super.key,
    required this.outfit,
    required this.rewards,
    required this.storage,
    required this.audio,
    this.place,
  });

  /// The doll whose room this is, as she is dressed now.
  final Outfit outfit;
  final Rewards rewards;
  final LooksStorage storage;
  final GameAudio audio;

  /// Something to put in the room at once (picked in the Star Shop).
  final RoomItem? place;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  final RoomStorage _rooms = RoomStorage();

  /// Null until the saved room was read.
  Room? _room;

  RoomCategory _category = RoomCategory.wallpaper;

  /// The thing with the size and flip buttons (index in the room).
  int? _selected;

  /// The size of the room on screen.
  Size _size = Size.zero;

  // The finger (or two) on the room.
  final Map<int, Offset> _fingers = {};
  int? _held;
  Offset _grab = Offset.zero;
  PlacedThing? _start;
  Offset _downAt = Offset.zero;
  double _pinchStart = 0;
  bool _dragging = false;
  bool _pinched = false;
  bool _overTrash = false;

  /// The doll or pet that is reacting to a tap.
  RoomItem? _reacting;
  int _nudge = 0;

  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _unlockShow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  late final AnimationController _needShow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  RoomItem? _unlocked;
  RoomItem? _needed;
  final Map<String, int> _shakes = {};

  @override
  void initState() {
    super.initState();
    GameMotion.lite.addListener(_updateTwinkle);
    _load();
  }

  Future<void> _load() async {
    final room = await _rooms.load(widget.outfit.dollId);
    if (!mounted) return;
    setState(() => _room = room);
    _updateTwinkle();
    final place = widget.place;
    if (place != null) {
      setState(() => _category = place.category);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _put(place);
      });
    }
  }

  @override
  void dispose() {
    GameMotion.lite.removeListener(_updateTwinkle);
    _react.dispose();
    _twinkle.dispose();
    _flash.dispose();
    _confetti.dispose();
    _unlockShow.dispose();
    _needShow.dispose();
    super.dispose();
  }

  /// Stars twinkle at night (not in lite mode).
  void _updateTwinkle() {
    final on = GameMotion.idleLoops && (_room?.night ?? false);
    if (on && !_twinkle.isAnimating) {
      _twinkle.repeat();
    } else if (!on) {
      _twinkle.stop();
    }
  }

  void _change(Room room, {bool save = true}) {
    setState(() => _room = room);
    if (save) _save();
  }

  void _save() {
    final room = _room;
    if (room != null) _rooms.save(widget.outfit.dollId, room);
  }

  // --------------------------------------------------------------- the bar

  Future<void> _tapItem(RoomItem item) async {
    if (_room == null) return;
    if (!widget.rewards.isUnlocked(item)) {
      if (await widget.rewards.unlock(item)) {
        if (!mounted) return;
        widget.audio.play(Sfx.unlock);
        HapticFeedback.mediumImpact();
        setState(() => _unlocked = item);
        _unlockShow.forward(from: 0);
        _confetti.forward(from: 0);
        _put(item, quiet: true);
      } else {
        widget.audio.play(Sfx.notYet);
        HapticFeedback.lightImpact();
        setState(() {
          _needed = item;
          _shakes[item.id] = (_shakes[item.id] ?? 0) + 1;
        });
        _needShow.forward(from: 0);
      }
      return;
    }
    _put(item);
  }

  /// Puts [item] in the room (or wears the wallpaper or floor).
  void _put(RoomItem item, {bool quiet = false}) {
    final room = _room;
    if (room == null) return;
    void sound(Sfx sfx) {
      if (!quiet) widget.audio.play(sfx);
    }

    if (item.surface != RoomSurface.none) {
      sound(Sfx.itemOn);
      setState(() => _selected = null);
      _change(
        item.surface == RoomSurface.wallpaper
            ? room.copyWith(wallpaper: item.id)
            : room.copyWith(floor: item.id),
      );
      return;
    }
    // There is only one of her and of each pet: show where it is.
    if (item.single) {
      final at = room.things.indexWhere((t) => t.item.id == item.id);
      if (at >= 0) {
        sound(Sfx.tap);
        setState(() => _selected = at);
        _reactTo(item);
        return;
      }
    }
    if (room.isFull) {
      sound(Sfx.notYet);
      return;
    }
    sound(Sfx.itemOn);
    HapticFeedback.lightImpact();
    // Near the middle; each new one a bit to the side, so none hides.
    final side = (room.things.length % 5 - 2) * 0.1;
    final y = switch (item.category) {
      RoomCategory.window || RoomCategory.art => 0.4,
      RoomCategory.floor => 0.94,
      _ => 0.82 + (room.things.length % 3) * 0.05,
    };
    final placed = PlacedThing(item, 0.5 + side, y).inside(_size);
    setState(() => _selected = room.things.length);
    _change(room.add(placed));
  }

  void _toggleNight() {
    final room = _room;
    if (room == null) return;
    widget.audio.play(Sfx.sparkle);
    _change(room.copyWith(night: !room.night));
    _updateTwinkle();
  }

  Future<void> _takePhoto() async {
    final room = _room;
    if (room == null) return;
    widget.audio.play(Sfx.camera);
    HapticFeedback.mediumImpact();
    _flash.forward(from: 0);
    _confetti.forward(from: 0);
    setState(() => _selected = null);
    await widget.storage.add(widget.outfit.copyWith(room: room, runway: false));
  }

  void _nextSize() {
    final room = _room, i = _selected;
    if (room == null || i == null) return;
    widget.audio.play(Sfx.tap);
    final now = room.things[i].scale;
    final next = roomSizes.firstWhere(
      (s) => s > now + 0.05,
      orElse: () => roomSizes.first,
    );
    _change(
      room.replace(i, room.things[i].copyWith(scale: next).inside(_size)),
    );
  }

  void _flip() {
    final room = _room, i = _selected;
    if (room == null || i == null) return;
    widget.audio.play(Sfx.tap);
    _change(
      room.replace(
        i,
        room.things[i].copyWith(flipped: !room.things[i].flipped),
      ),
    );
  }

  // ------------------------------------------------------------ the fingers

  /// The trash can, bottom left of the room.
  Rect get _trash => Rect.fromLTWH(10, _size.height - 82, 72, 72);

  /// The thing in front at [at].
  int? _thingAt(Offset at) {
    final room = _room;
    if (room == null) return null;
    for (final i in room.drawOrder.reversed) {
      // Small things get a little extra room for small fingers.
      var r = room.things[i].rect(_size);
      if (r.shortestSide < 48) r = r.inflate((48 - r.shortestSide) / 2);
      if (r.contains(at)) return i;
    }
    return null;
  }

  double get _spread {
    final points = _fingers.values.toList();
    return points.length < 2 ? 0 : (points[0] - points[1]).distance;
  }

  void _down(PointerDownEvent e) {
    _fingers[e.pointer] = e.localPosition;
    if (_fingers.length == 1) {
      _downAt = e.localPosition;
      _dragging = false;
      _pinched = false;
      final i = _thingAt(e.localPosition);
      setState(() {
        _held = i;
        if (i != null) {
          final t = _room!.things[i];
          _start = t;
          _grab =
              Offset(t.x * _size.width, t.y * _size.height) - e.localPosition;
        }
      });
    } else if (_fingers.length == 2 && _held != null) {
      // A second finger: pinch it bigger or smaller.
      _pinchStart = _spread;
      _start = _room!.things[_held!];
      _pinched = true;
      setState(() => _selected = _held);
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_fingers.containsKey(e.pointer)) return;
    _fingers[e.pointer] = e.localPosition;
    final room = _room, i = _held, start = _start;
    if (room == null || i == null || start == null) return;
    if (_fingers.length >= 2) {
      if (_pinchStart <= 0) return;
      final s = (start.scale * _spread / _pinchStart).clamp(
        minRoomScale,
        maxRoomScale,
      );
      _change(
        room.replace(i, room.things[i].copyWith(scale: s).inside(_size)),
        save: false,
      );
      return;
    }
    // After a pinch the finger that stays does not move it.
    if (_pinched) return;
    if (!_dragging && (e.localPosition - _downAt).distance < 8) return;
    if (!_dragging) {
      _dragging = true;
      _selected = i;
    }
    final to = e.localPosition + _grab;
    _overTrash = _trash.inflate(12).contains(e.localPosition);
    _change(
      room.replace(
        i,
        room.things[i]
            .copyWith(x: to.dx / _size.width, y: to.dy / _size.height)
            .inside(_size),
      ),
      save: false,
    );
  }

  void _up(PointerEvent e) {
    if (_fingers.remove(e.pointer) == null || _fingers.isNotEmpty) return;
    final room = _room, i = _held;
    final cancelled = e is PointerCancelEvent;
    if (room == null) return;
    if (i == null) {
      setState(() => _selected = null);
      return;
    }
    if (_dragging && _overTrash && !cancelled) {
      widget.audio.play(Sfx.itemOff);
      HapticFeedback.mediumImpact();
      _selected = null;
      _change(room.removeAt(i));
    } else if (_dragging || _pinched) {
      _save();
    } else if (!cancelled) {
      final item = room.things[i].item;
      setState(() => _selected = i);
      if (item.category == RoomCategory.friends) {
        _reactTo(item);
      } else {
        widget.audio.play(Sfx.tap);
      }
    }
    setState(() {
      _held = null;
      _start = null;
      _dragging = false;
      _overTrash = false;
    });
  }

  /// The doll or a pet is tapped: a happy hop and hearts.
  void _reactTo(RoomItem item) {
    widget.audio.play(item.isDoll ? Sfx.cheer : Sfx.bubble);
    HapticFeedback.lightImpact();
    setState(() {
      _reacting = item;
      _nudge++;
    });
    _react.forward(from: 0);
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('room_screen'),
      backgroundColor: const Color(0xFFFFF0F7),
      body: Column(
        children: [
          Expanded(child: _stage()),
          _bar(),
        ],
      ),
    );
  }

  Widget _stage() {
    final strings = AppStrings.of(context);
    final top = MediaQuery.paddingOf(context).top + 8;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        var room = _room;
        if (room != null) {
          final aspect = _size.width / _size.height;
          // Fit everything onto this screen.
          room = _room = room.copyWith(
            aspect: aspect,
            things: [for (final t in room.things) t.inside(_size)],
          );
        }
        final selected = _selected;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (room != null) _roomView(room),
            // Camera flash.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _flash,
                builder: (context, _) => ColoredBox(
                  color: Colors.white.withValues(
                    alpha: _flash.isAnimating ? (1 - _flash.value) * .85 : 0,
                  ),
                ),
              ),
            ),
            if (_dragging)
              Positioned.fromRect(
                rect: _trash,
                child: IgnorePointer(child: _trashCan()),
              ),
            if (selected != null && !_dragging)
              Positioned(
                right: 10,
                bottom: 10,
                child: Column(
                  children: [
                    BigRoundButton(
                      key: const Key('room_size'),
                      icon: Icons.open_in_full_rounded,
                      color: const Color(0xFF5CCB6A),
                      semanticLabel: strings.changeSize,
                      size: 56,
                      onTap: _nextSize,
                    ),
                    const SizedBox(height: 10),
                    BigRoundButton(
                      key: const Key('room_flip'),
                      icon: Icons.flip_rounded,
                      color: const Color(0xFF4CC9C9),
                      semanticLabel: strings.flip,
                      size: 56,
                      onTap: _flip,
                    ),
                  ],
                ),
              ),
            Positioned(
              top: top,
              left: 12,
              child: BigRoundButton(
                key: const Key('room_back'),
                icon: Icons.arrow_back_rounded,
                color: const Color(0xFFB79CFF),
                semanticLabel: strings.back,
                size: 56,
                onTap: () {
                  widget.audio.play(Sfx.tap);
                  Navigator.of(context).pop();
                },
              ),
            ),
            Positioned(
              top: top,
              right: 12,
              child: Row(
                children: [
                  BigRoundButton(
                    key: const Key('room_night'),
                    icon: room?.night ?? false
                        ? Icons.wb_sunny_rounded
                        : Icons.nightlight_round,
                    color: room?.night ?? false
                        ? const Color(0xFFFFB347)
                        : const Color(0xFF6C5CC9),
                    semanticLabel: strings.dayNight,
                    size: 56,
                    onTap: _toggleNight,
                  ),
                  const SizedBox(width: 10),
                  BigRoundButton(
                    key: const Key('room_camera'),
                    icon: Icons.photo_camera_rounded,
                    color: const Color(0xFFFF6B8B),
                    semanticLabel: strings.saveLook,
                    size: 56,
                    onTap: _takePhoto,
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (context, _) => CustomPaint(
                  painter: ConfettiPainter(
                    progress: _confetti.isAnimating ? _confetti.value : 0,
                    origin: Offset(_size.width / 2, _size.height * 0.4),
                    seed: 31,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_unlockShow, _needShow]),
                builder: (context, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_unlocked != null && _unlockShow.isAnimating)
                      UnlockCelebration(
                        picture: RoomThumbnail(item: _unlocked!),
                        progress: _unlockShow.value,
                      ),
                    if (_needed != null && _needShow.isAnimating)
                      Center(
                        child: NeedStars(
                          picture: RoomThumbnail(item: _needed!),
                          price: _needed!.price,
                          have: widget.rewards.stars,
                          progress: _needShow.value,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trashCan() => AnimatedScale(
    key: const Key('room_trash'),
    scale: _overTrash ? 1.25 : 1,
    duration: const Duration(milliseconds: 160),
    child: GlossyCircle(
      color: _overTrash ? const Color(0xFFFF5F7F) : const Color(0xFFB8AEC4),
      size: 72,
      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 40),
    ),
  );

  /// The room itself: wall and floor, then every thing in drawing order.
  Widget _roomView(Room room) {
    final unit = _size.width / roomUnits;
    return Listener(
      key: const Key('room_area'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _BackdropPainter(
                  room.wallpaper,
                  room.floor,
                  room.night,
                ),
              ),
            ),
            for (final i in room.drawOrder) _thing(room, i),
            if (room.night)
              IgnorePointer(
                child: CustomPaint(
                  key: const Key('room_glow'),
                  painter: _GlowPainter([
                    for (final t in room.things)
                      if (t.item.glow != null)
                        (lampCenter(t, _size), 105 * unit * t.scale),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thing(Room room, int i) {
    final placed = room.things[i];
    final item = placed.item;
    final rect = placed.rect(_size);
    // Laid out at one size and only scaled, so pictures are drawn once.
    final box = Size(item.w, item.h) * (_size.width / roomUnits * roomArtScale);
    Widget art;
    if (item.isDoll) {
      art = AnimatedBuilder(
        animation: _react,
        builder: (context, _) => DollView(
          key: const Key('room_doll'),
          outfit: widget.outfit,
          happy: _reacting == item && _react.isAnimating,
          nudge: _nudge,
        ),
      );
    } else {
      art = ArtImage(
        key: ValueKey('art_${item.id}'),
        cacheKey: 'room|${item.id}',
        cache: roomImages,
        draw: (pixels) => rasterizeRoomItem(item, pixels),
      );
    }
    // Lamps stay bright at night.
    if (room.night && item.glow == null) {
      art = ColorFiltered(colorFilter: roomNightFilter, child: art);
    }
    if (item.pane != null) {
      art = Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _SkyPainter(item, room.night, _twinkle)),
          art,
        ],
      );
    }
    Widget view = FittedBox(
      fit: BoxFit.fill,
      child: SizedBox.fromSize(size: box, child: art),
    );
    if (placed.flipped) {
      view = Transform.flip(flipX: true, child: view);
    }
    return Positioned.fromRect(
      // Keeps each thing's picture (and the doll) when the order changes.
      key: ValueKey('thing_${item.id}_${_copyNumber(room, i)}'),
      rect: rect,
      child: AnimatedBuilder(
        animation: _react,
        builder: (context, child) {
          final hopping =
              _reacting == item && item.single && _react.isAnimating;
          final t = hopping ? _react.value : 0.0;
          final hop = hopping && t < 0.6
              ? math.sin(t / 0.6 * math.pi * 2).abs() * rect.height * 0.08
              : 0.0;
          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              // Always here: adding it later would rebuild the picture.
              CustomPaint(
                painter: _UnderPainter(
                  shadow: hasRoomShadow(item),
                  selected: i == _selected,
                ),
              ),
              Transform.translate(offset: Offset(0, -hop), child: child),
              if (hopping)
                Positioned(
                  left: 0,
                  right: 0,
                  top: -50,
                  height: 60,
                  child: CustomPaint(painter: _HeartsPainter(t)),
                ),
            ],
          );
        },
        child: RepaintBoundary(key: Key('thing_$i'), child: view),
      ),
    );
  }

  /// Which copy of its item the thing at [i] is.
  int _copyNumber(Room room, int i) {
    var n = 0;
    for (var k = 0; k < i; k++) {
      if (room.things[k].item.id == room.things[i].item.id) n++;
    }
    return n;
  }

  // ------------------------------------------------------------------- bar

  Widget _bar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, lighten(_category.color, 0.7)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33B06FA0),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                key: const Key('room_items'),
                height: 94,
                child: ListenableBuilder(
                  listenable: widget.rewards,
                  builder: (context, _) {
                    final items = roomItemsIn(_category);
                    return ListView.separated(
                      key: ValueKey(_category),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _itemCard(items[i]),
                    );
                  },
                ),
              ),
              SizedBox(
                key: const Key('room_categories'),
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: RoomCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) =>
                      _categoryButton(RoomCategory.values[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryButton(RoomCategory category) {
    final selected = category == _category;
    return Pressable(
      key: Key('room_cat_${category.name}'),
      onTap: () {
        widget.audio.play(Sfx.tap);
        setState(() => _category = category);
      },
      builder: (pressed) => Center(
        child: AnimatedScale(
          scale: selected ? 1.13 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: GlossyCircle(
            color: category.color,
            size: 56,
            pressed: pressed,
            rim: selected ? 4 : 3,
            rimColor: selected ? darken(category.color, 0.3) : Colors.white,
            glow: selected ? category.color : null,
            child: Icon(category.icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _itemCard(RoomItem item) {
    final room = _room;
    final used =
        room != null &&
        (room.wallpaper == item.id ||
            room.floor == item.id ||
            (item.single && room.things.any((t) => t.item.id == item.id)));
    final locked = !widget.rewards.isUnlocked(item);
    return Shake(
      trigger: _shakes[item.id] ?? 0,
      child: Pressable(
        key: Key('room_item_${item.id}'),
        onTap: () => _tapItem(item),
        builder: (pressed) => Container(
          width: 82,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, lighten(_category.color, 0.65)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: used ? darken(_category.color, 0.3) : Colors.white,
              width: used ? 3.5 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x2A7A4A8A),
                blurRadius: pressed ? 3 : 7,
                offset: Offset(0, pressed ? 1 : 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Padding(
                    padding: EdgeInsets.all(
                      item.surface == RoomSurface.none ? 6 : 0,
                    ),
                    child: item.isDoll
                        ? Center(
                            child: FittedBox(
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: LookPicture(look: widget.outfit),
                              ),
                            ),
                          )
                        : RoomThumbnail(item: item),
                  ),
                ),
              ),
              if (locked) ...[
                Positioned(
                  right: 2,
                  top: 2,
                  child: LockBadge(key: Key('room_lock_${item.id}'), size: 24),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 2,
                  child: Center(child: PricePill(price: item.price)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.wallpaper, this.floor, this.night);

  final String wallpaper;
  final String floor;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) => paintRoomBackdrop(
    canvas,
    size,
    wallpaper: wallpaper,
    floor: floor,
    night: night,
  );

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.wallpaper != wallpaper || old.floor != floor || old.night != night;
}

/// The sky behind a window's glass.
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.item, this.night, this.time) : super(repaint: time);

  final RoomItem item;
  final bool night;
  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / item.w, size.height / item.h);
    paintWindowSky(canvas, item, night: night, time: time.value * 60);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.item != item || old.night != night;
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.lamps);

  final List<(Offset, double)> lamps;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (center, radius) in lamps) {
      paintLampGlow(canvas, center, radius);
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) => true;
}

/// Under a thing: its floor shadow, and a bright ring when it is picked.
class _UnderPainter extends CustomPainter {
  _UnderPainter({required this.shadow, required this.selected});

  final bool shadow;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadow) paintRoomShadow(canvas, Offset.zero & size);
    if (!selected) return;
    final box = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(3),
      const Radius.circular(16),
    );
    canvas.drawRRect(box, Paint()..color = const Color(0x33FFFFFF));
    for (final (color, width) in const [
      (Color(0xFFFFFFFF), 5.0),
      (Color(0xFFFF5FA2), 2.0),
    ]) {
      canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_UnderPainter old) =>
      old.shadow != shadow || old.selected != selected;
}

/// Hearts floating up from a tapped doll or pet (fewer in lite mode).
class _HeartsPainter extends CustomPainter {
  _HeartsPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final count = GameMotion.lite.value ? 2 : 5;
    for (var i = 0; i < count; i++) {
      final x = size.width / 2 + (i - (count - 1) / 2) * 16;
      final y = size.height - t * (36 + (i % 3) * 8);
      canvas.drawPath(
        heartPath(Offset(x + math.sin(t * 9 + i) * 4, y), 14 + (i % 2) * 4),
        Paint()..color = const Color(0xFFFF5F9E).withValues(alpha: 1 - t * t),
      );
    }
  }

  @override
  bool shouldRepaint(_HeartsPainter old) => old.t != t;
}
