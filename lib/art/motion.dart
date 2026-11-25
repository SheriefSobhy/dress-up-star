import 'package:flutter/foundation.dart';

/// Switches for the gentle "always moving" animations (doll breathing and
/// blinking, drifting clouds, the pulsing Play button...).
///
/// Widget tests turn them off so the screen can become still and
/// `pumpAndSettle` can finish.
class GameMotion {
  static bool idleAnimations = true;

  /// Lite mode: on slow phones the heavy effects are turned off (drifting
  /// clouds, the doll's breathing, moving sparkles, pulsing buttons) and
  /// there is less confetti. Turned on by `FrameWatcher` when frames drop,
  /// or by the parents.
  static final ValueNotifier<bool> lite = ValueNotifier(false);

  /// Idle loops may run now (not in tests, not in lite mode).
  static bool get idleLoops => idleAnimations && !lite.value;
}
