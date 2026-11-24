import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The short sound effects in the game (brush to bubble are for activities;
/// unlock and notYet are for the Star Shop).
enum Sfx {
  tap,
  itemOn,
  itemOff,
  camera,
  brush,
  sparkle,
  snip,
  water,
  blow,
  bubble,
  unlock,
  notYet,
}

/// Music and sound effects, plus the mute switch (remembered on the device).
///
/// The game uses [AudioPlayersGameAudio]; tests use [SilentGameAudio], which
/// only records what would have played.
abstract class GameAudio extends ChangeNotifier {
  static const mutedKey = 'sound_muted';

  bool _muted = false;
  bool get muted => _muted;

  /// Reads the saved mute setting and gets the sounds ready.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(mutedKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleMuted() async {
    _muted = !_muted;
    notifyListeners();
    if (_muted) {
      stopAllForMute();
    } else {
      startMusic();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(mutedKey, _muted);
  }

  /// Plays a sound effect (does nothing while muted).
  void play(Sfx sfx);

  /// Starts the background music if it isn't playing yet. Browsers only
  /// allow this after the player has touched the screen, so the app calls
  /// it on every touch; extra calls do nothing.
  void startMusic();

  /// Pauses/resumes the music when the app goes to the background and back.
  void pauseMusic();
  void resumeMusic();

  @protected
  void stopAllForMute();
}

/// Real audio using the audioplayers package (phones and browsers).
class AudioPlayersGameAudio extends GameAudio {
  static const _files = {
    Sfx.tap: 'sounds/tap.wav',
    Sfx.itemOn: 'sounds/item_on.wav',
    Sfx.itemOff: 'sounds/item_off.wav',
    Sfx.camera: 'sounds/camera.wav',
    Sfx.brush: 'sounds/brush.wav',
    Sfx.sparkle: 'sounds/sparkle.wav',
    Sfx.snip: 'sounds/snip.wav',
    Sfx.water: 'sounds/water.wav',
    Sfx.blow: 'sounds/blow.wav',
    Sfx.bubble: 'sounds/bubble.wav',
    Sfx.unlock: 'sounds/unlock.wav',
    Sfx.notYet: 'sounds/not_yet.wav',
  };
  static const _musicFile = 'sounds/music.wav';
  static const _musicVolume = 0.35;

  final AudioPlayer _music = AudioPlayer();
  final Map<Sfx, AudioPlayer> _sfx = {
    for (final s in Sfx.values) s: AudioPlayer(),
  };
  bool _musicStarted = false;
  bool _musicStarting = false;
  bool _musicPaused = false;

  @override
  Future<void> load() async {
    await super.load();
    await _safely(() async {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(_musicVolume);
      for (final entry in _sfx.entries) {
        if (!kIsWeb) await entry.value.setPlayerMode(PlayerMode.lowLatency);
        await entry.value.setReleaseMode(ReleaseMode.stop);
        await entry.value.setSource(AssetSource(_files[entry.key]!));
      }
    });
    // Phones may start music right away; browsers wait for the first touch.
    if (!kIsWeb) startMusic();
  }

  @override
  void play(Sfx sfx) {
    if (muted) return;
    final player = _sfx[sfx]!;
    _safely(() async {
      await player.stop();
      await player.play(AssetSource(_files[sfx]!));
    });
  }

  @override
  void startMusic() {
    if (muted || _musicStarting) return;
    if (_musicStarted) {
      if (_musicPaused) {
        _musicPaused = false;
        _safely(_music.resume);
      }
      return;
    }
    _musicStarting = true;
    _startMusicNow();
  }

  Future<void> _startMusicNow() async {
    try {
      await _music.play(AssetSource(_musicFile), volume: _musicVolume);
      _musicStarted = true;
      _musicPaused = false;
      // The player may have pressed mute while the music was loading.
      if (muted) pauseMusic();
    } catch (e) {
      // Usually "the browser needs a touch first": try again next touch.
      debugPrint('Music could not start yet: $e');
    } finally {
      _musicStarting = false;
    }
  }

  @override
  void pauseMusic() {
    if (_musicStarted && !_musicPaused) {
      _musicPaused = true;
      _safely(_music.pause);
    }
  }

  @override
  void resumeMusic() => startMusic();

  @override
  void stopAllForMute() {
    pauseMusic();
    for (final p in _sfx.values) {
      _safely(p.stop);
    }
  }

  /// Sound must never crash the game.
  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Sound problem: $e');
    }
  }

  @override
  void dispose() {
    _music.dispose();
    for (final p in _sfx.values) {
      p.dispose();
    }
    super.dispose();
  }
}

/// No real sound: remembers what would have played (used in tests).
class SilentGameAudio extends GameAudio {
  final List<Sfx> played = [];
  bool musicPlaying = false;

  @override
  void play(Sfx sfx) {
    if (!muted) played.add(sfx);
  }

  @override
  void startMusic() {
    if (!muted) musicPlaying = true;
  }

  @override
  void pauseMusic() => musicPlaying = false;

  @override
  void resumeMusic() => startMusic();

  @override
  void stopAllForMute() => musicPlaying = false;
}
