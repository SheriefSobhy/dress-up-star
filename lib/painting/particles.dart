import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'shapes.dart';

/// What a particle looks like and how it moves.
enum ParticleKind {
  /// Little stars that pop out and slow down.
  sparkle,

  /// Soap bubbles that float up.
  bubble,

  /// Water drops that fall.
  drop,

  /// Snipped bits of hair that tumble down.
  hair,

  /// A soft colored puff (spray paint).
  mist,

  /// Wind lines (dryers).
  air,

  /// Tiny dust (nail file).
  dust,

  /// Warm steam puffs (curling iron).
  steam,
}

class _Particle {
  _Particle(
    this.kind,
    this.pos,
    this.vel,
    this.size,
    this.color,
    this.life,
    this.spin,
  );
  final ParticleKind kind;
  Offset pos;
  Offset vel;
  final double size;
  final Color color;
  final double life;
  final double spin;
  double age = 0;
}

/// A small, cheap particle effect. Positions and sizes are in the same
/// space as the art (doll space or hand space). The ticker only runs while
/// particles are alive, so an idle screen costs nothing.
class ParticleSystem extends ChangeNotifier {
  ParticleSystem(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  static const int maxParticles = 90;
  static const List<Color> sparkleColors = [
    Color(0xFFFFE066),
    Color(0xFFFF8FC7),
    Color(0xFFFFFFFF),
    Color(0xFF9AD0FF),
    Color(0xFFC9A8FF),
  ];

  late final Ticker _ticker;
  final List<_Particle> _items = [];
  final math.Random _random = math.Random();
  Duration _last = Duration.zero;

  bool get isEmpty => _items.isEmpty;

  /// Adds [count] particles of [kind] around [at].
  void emit(
    ParticleKind kind,
    Offset at, {
    int count = 1,
    Color? color,
    double size = 3,
    Offset direction = Offset.zero,
    double spread = 1,
  }) {
    for (var i = 0; i < count; i++) {
      if (_items.length >= maxParticles) _items.removeAt(0);
      final a = _random.nextDouble() * 2 * math.pi;
      final speed = _speed(kind) * (0.5 + _random.nextDouble() * 0.7);
      var vel = Offset(math.cos(a), math.sin(a)) * speed * spread;
      vel += direction;
      _items.add(
        _Particle(
          kind,
          at +
              Offset(
                (_random.nextDouble() - 0.5) * size * 2,
                (_random.nextDouble() - 0.5) * size * 2,
              ),
          vel,
          size * (0.6 + _random.nextDouble() * 0.7),
          color ?? sparkleColors[_random.nextInt(sparkleColors.length)],
          _life(kind) * (0.7 + _random.nextDouble() * 0.6),
          (_random.nextDouble() - 0.5) * 6,
        ),
      );
    }
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  /// A happy burst of stars.
  void burst(Offset at, {int count = 16, double size = 3.2}) =>
      emit(ParticleKind.sparkle, at, count: count, size: size, spread: 1.6);

  static double _speed(ParticleKind k) => switch (k) {
    ParticleKind.sparkle => 40,
    ParticleKind.bubble => 8,
    ParticleKind.drop => 10,
    ParticleKind.hair => 14,
    ParticleKind.mist => 14,
    ParticleKind.air => 6,
    ParticleKind.dust => 20,
    ParticleKind.steam => 8,
  };

  static double _life(ParticleKind k) => switch (k) {
    ParticleKind.sparkle => 0.7,
    ParticleKind.bubble => 1.4,
    ParticleKind.drop => 0.7,
    ParticleKind.hair => 1.1,
    ParticleKind.mist => 0.6,
    ParticleKind.air => 0.45,
    ParticleKind.dust => 0.6,
    ParticleKind.steam => 0.9,
  };

  static Offset _gravity(ParticleKind k) => switch (k) {
    ParticleKind.bubble => const Offset(0, -26),
    ParticleKind.drop => const Offset(0, 240),
    ParticleKind.hair => const Offset(0, 110),
    ParticleKind.dust => const Offset(0, 60),
    ParticleKind.steam => const Offset(0, -30),
    _ => Offset.zero,
  };

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    for (final p in _items) {
      p.age += dt;
      p.vel += _gravity(p.kind) * dt;
      if (p.kind == ParticleKind.sparkle || p.kind == ParticleKind.mist) {
        p.vel = p.vel * math.pow(0.04, dt).toDouble();
      }
      p.pos += p.vel * dt;
    }
    _items.removeWhere((p) => p.age >= p.life);
    if (_items.isEmpty) _ticker.stop();
    notifyListeners();
  }

  /// Draws every particle (the canvas must already be in art space).
  void paint(Canvas canvas) {
    for (final p in _items) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final fade = 1 - t * t;
      switch (p.kind) {
        case ParticleKind.sparkle:
          final r = p.size * (1 - t * 0.4);
          final path = starPath(p.pos, r, rotation: p.spin * t);
          canvas.drawPath(
            path,
            Paint()..color = p.color.withValues(alpha: fade),
          );
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.15
              ..color = darken(p.color, 0.25).withValues(alpha: fade * 0.6),
          );
        case ParticleKind.bubble:
          final r = p.size * (0.7 + t * 0.4);
          final pos = p.pos + Offset(math.sin(p.age * 6 + p.spin) * 1.5, 0);
          canvas.drawCircle(
            pos,
            r,
            Paint()
              ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 * fade),
          );
          canvas.drawCircle(
            pos,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.16
              ..color = const Color(0xFF9AD6FF).withValues(alpha: 0.9 * fade),
          );
          canvas.drawCircle(
            pos - Offset(r * 0.35, r * 0.35),
            r * 0.22,
            Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: fade),
          );
        case ParticleKind.drop:
          final r = p.size;
          final path = Path()
            ..moveTo(p.pos.dx, p.pos.dy - r * 1.6)
            ..quadraticBezierTo(
              p.pos.dx + r,
              p.pos.dy,
              p.pos.dx,
              p.pos.dy + r * 0.8,
            )
            ..quadraticBezierTo(
              p.pos.dx - r,
              p.pos.dy,
              p.pos.dx,
              p.pos.dy - r * 1.6,
            );
          canvas.drawPath(
            path,
            Paint()..color = const Color(0xFF7CC8FF).withValues(alpha: fade),
          );
          canvas.drawCircle(
            p.pos + Offset(-r * 0.25, -r * 0.1),
            r * 0.25,
            Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: fade),
          );
        case ParticleKind.hair:
          final a = p.spin * p.age;
          final d = Offset(math.cos(a), math.sin(a)) * p.size;
          canvas.drawPath(
            Path()
              ..moveTo(p.pos.dx - d.dx, p.pos.dy - d.dy)
              ..quadraticBezierTo(
                p.pos.dx + d.dy * 0.5,
                p.pos.dy - d.dx * 0.5,
                p.pos.dx + d.dx,
                p.pos.dy + d.dy,
              ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = p.size * 0.35
              ..color = p.color.withValues(alpha: fade),
          );
        case ParticleKind.mist:
          canvas.drawCircle(
            p.pos,
            p.size * (0.6 + t),
            Paint()..color = p.color.withValues(alpha: 0.45 * fade),
          );
        case ParticleKind.air:
          final dir = p.vel.distance < 0.01
              ? const Offset(1, 0)
              : p.vel / p.vel.distance;
          final normal = Offset(-dir.dy, dir.dx);
          final len = p.size * 3;
          final start = p.pos - dir * len;
          canvas.drawPath(
            Path()
              ..moveTo(start.dx, start.dy)
              ..quadraticBezierTo(
                p.pos.dx - dir.dx * len * 0.5 + normal.dx * p.size,
                p.pos.dy - dir.dy * len * 0.5 + normal.dy * p.size,
                p.pos.dx,
                p.pos.dy,
              ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = p.size * 0.35
              ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85 * fade),
          );
        case ParticleKind.dust:
          canvas.drawCircle(
            p.pos,
            p.size * 0.5,
            Paint()..color = p.color.withValues(alpha: fade),
          );
        case ParticleKind.steam:
          canvas.drawCircle(
            p.pos,
            p.size * (0.5 + t),
            Paint()
              ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * fade),
          );
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
