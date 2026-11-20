/// Switches for the gentle "always moving" animations (doll breathing and
/// blinking, drifting clouds, the pulsing Play button...).
///
/// Widget tests turn them off so the screen can become still and
/// `pumpAndSettle` can finish.
class GameMotion {
  static bool idleAnimations = true;
}
