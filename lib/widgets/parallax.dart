import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../art/motion.dart';

/// The parallax of the [ParallaxLayer]s below it: tilting the phone moves
/// them at different speeds. On the web, or without a motion sensor, they
/// drift gently by themselves. Off in lite mode (and in tests).
///
/// Only ready-made layers are moved, nothing is repainted.
class ParallaxScope extends StatefulWidget {
  const ParallaxScope({super.key, required this.child});

  final Widget child;

  /// How long to wait for the sensor before drifting instead.
  static const Duration sensorWait = Duration(seconds: 1);

  @override
  State<ParallaxScope> createState() => _ParallaxScopeState();
}

/// Where the view is (-1..1 each way), and whether parallax is on at all.
class _Parallax extends ChangeNotifier {
  Offset offset = Offset.zero;
  bool on = false;

  void set(Offset value, {bool? enabled}) {
    final next = enabled ?? on;
    if (next == on && (value - offset).distance < 0.004) return;
    offset = value;
    on = next;
    notifyListeners();
  }
}

class _ParallaxScopeState extends State<ParallaxScope>
    with TickerProviderStateMixin {
  final _Parallax _view = _Parallax();
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<AccelerometerEvent>? _sensor;
  Timer? _noSensor;
  AnimationController? _drift;

  /// How the phone is usually held: follows slowly, so any way is "flat".
  Offset? _level;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _stop, onShow: _start);
    GameMotion.lite.addListener(_onLite);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  void _onLite() => GameMotion.idleLoops ? _start() : _stop();

  void _start() {
    if (!GameMotion.idleLoops || _view.on) return;
    _view.set(Offset.zero, enabled: true);
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _startDrift();
      return;
    }
    _noSensor = Timer(ParallaxScope.sensorWait, _startDrift);
    _sensor = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onTilt, onError: (Object _) => _startDrift());
  }

  void _onTilt(AccelerometerEvent e) {
    _noSensor?.cancel();
    if (_drift != null) return;
    final now = Offset(e.x, e.y);
    final level = _level = Offset.lerp(_level ?? now, now, 0.008)!;
    final tilt = Offset(
      ((now.dx - level.dx) / 2.5).clamp(-1.0, 1.0),
      ((level.dy - now.dy) / 2.5).clamp(-1.0, 1.0),
    );
    // Smoothed, so a shaky hand does not shake the picture.
    _view.set(Offset.lerp(_view.offset, tilt, 0.15)!);
  }

  void _startDrift() {
    _noSensor?.cancel();
    _sensor?.cancel();
    _sensor = null;
    if (!mounted || _drift != null) return;
    final drift = _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    drift.addListener(() {
      final a = drift.value * 2 * math.pi;
      _view.set(Offset(math.sin(a) * 0.7, math.sin(a * 2) * 0.25));
    });
    drift.repeat();
  }

  void _stop() {
    _noSensor?.cancel();
    _sensor?.cancel();
    _sensor = null;
    _drift?.dispose();
    _drift = null;
    _level = null;
    _view.set(Offset.zero, enabled: false);
  }

  @override
  void dispose() {
    GameMotion.lite.removeListener(_onLite);
    _lifecycle.dispose();
    _noSensor?.cancel();
    _sensor?.cancel();
    _drift?.dispose();
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ParallaxData(view: _view, child: widget.child);
}

class _ParallaxData extends InheritedWidget {
  const _ParallaxData({required this.view, required super.child});

  final _Parallax view;

  @override
  bool updateShouldNotify(_ParallaxData old) => old.view != view;
}

/// A layer that moves [depth] pixels at most (negative: the opposite way,
/// for what is far behind). [scale] enlarges it while parallax is on.
class ParallaxLayer extends StatelessWidget {
  const ParallaxLayer({
    super.key,
    required this.depth,
    required this.child,
    this.scale = 1,
  });

  final double depth;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final view = context
        .dependOnInheritedWidgetOfExactType<_ParallaxData>()!
        .view;
    return ListenableBuilder(
      listenable: view,
      builder: (context, child) {
        final s = view.on ? scale : 1.0;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(
              view.offset.dx * depth,
              view.offset.dy * depth * 0.6,
              0,
              1,
            )
            ..scaleByDouble(s, s, 1, 1),
          child: child,
        );
      },
      child: RepaintBoundary(child: child),
    );
  }
}

/// A few soft out-of-focus lights near the edges: the nearest layer.
class ForegroundGlows extends StatelessWidget {
  const ForegroundGlows({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size.infinite, painter: _GlowPainter());
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter();

  /// Place (fraction of the stage), radius and color.
  static const List<(double, double, double, Color)> _glows = [
    (0.02, 0.28, 26, Color(0xFFFFFFFF)),
    (0.97, 0.20, 18, Color(0xFFFFE3F3)),
    (0.10, 0.50, 11, Color(0xFFFFF3C4)),
    (0.93, 0.47, 30, Color(0xFFE9DCFF)),
    (0.28, 0.99, 34, Color(0xFFFFD9EC)),
    (0.72, 0.97, 22, Color(0xFFFFFFFF)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, r, color) in _glows) {
      final center = Offset(size.width * x, size.height * y);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.6, 1],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) => false;
}
