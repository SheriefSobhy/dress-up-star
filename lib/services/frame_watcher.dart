import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../art/motion.dart';

/// Watches how long each frame takes and turns on lite mode
/// ([GameMotion.lite]) when the phone can't keep up.
///
/// Lite mode is remembered. The parents can turn it on or off; after that
/// the parents' choice is kept and the watcher stops deciding.
class FrameWatcher {
  FrameWatcher({SchedulerBinding? binding})
    : _binding = binding ?? SchedulerBinding.instance;

  /// true / false once lite mode was set; missing means "automatic".
  static const liteModeKey = 'lite_mode';

  /// A frame is slow when building or drawing it takes longer than this
  /// (60 frames a second leave 16.7 ms; this allows small hiccups).
  static const slowFrame = Duration(milliseconds: 24);

  /// Frames per check, and how many of them may be slow.
  static const windowFrames = 120;
  static const slowShare = 0.25;

  /// Lite mode is only turned on after this many bad checks in a row, so
  /// one busy moment (like drawing a new outfit) does not switch it on.
  static const badWindowsNeeded = 2;

  /// The first frames after starting are always slow (warming up).
  static const warmUpFrames = 90;

  final SchedulerBinding _binding;
  bool _automatic = true;
  bool _listening = false;
  int _seen = 0;
  int _inWindow = 0;
  int _slowInWindow = 0;
  int _badWindows = 0;

  /// Reads the saved lite mode and starts watching (if still automatic).
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(liteModeKey);
    _automatic = saved == null;
    GameMotion.lite.value = saved ?? false;
    if (_automatic && !_listening) {
      _listening = true;
      _binding.addTimingsCallback(_onTimings);
    }
  }

  void stop() {
    if (_listening) _binding.removeTimingsCallback(_onTimings);
    _listening = false;
  }

  /// The parents' switch: from now on lite mode is what they chose.
  static Future<void> setLiteMode(bool on) async {
    GameMotion.lite.value = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(liteModeKey, on);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      record(t.buildDuration, t.rasterDuration);
    }
  }

  /// Counts one frame (public so tests can feed frame times).
  @visibleForTesting
  void record(Duration build, Duration raster) {
    if (!_listening || GameMotion.lite.value) return;
    if (++_seen <= warmUpFrames) return;
    _inWindow++;
    if (build > slowFrame || raster > slowFrame) _slowInWindow++;
    if (_inWindow < windowFrames) return;
    final share = _slowInWindow / _inWindow;
    if (kProfileMode) {
      debugPrint(
        'Frames: ${(share * 100).round()}% slow of the last $_inWindow '
        '(build/raster > ${slowFrame.inMilliseconds} ms)',
      );
    }
    _badWindows = share >= slowShare ? _badWindows + 1 : 0;
    _inWindow = 0;
    _slowInWindow = 0;
    if (_badWindows >= badWindowsNeeded) _turnOnLite();
  }

  Future<void> _turnOnLite() async {
    debugPrint('Frames are dropping: lite mode on.');
    GameMotion.lite.value = true;
    stop();
    final prefs = await SharedPreferences.getInstance();
    // Remembered, so the next start is smooth right away. The parents'
    // switch shows it and can turn it off.
    await prefs.setBool(liteModeKey, true);
  }
}
