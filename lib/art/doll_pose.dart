import 'dart:math' as math;
import 'dart:ui';

// All positions are in doll space (the 200 x 400 drawing space of the art).

const Offset kLeftShoulder = Offset(79, 177);
const Offset kRightShoulder = Offset(121, 177);

/// Where the hands are in the art (arms hanging down).
const Offset kLeftHandRest = Offset(64.5, 252);
const Offset kRightHandRest = Offset(135.5, 252);

/// Upper arm and forearm are the same length (half of shoulder to hand).
final double kArmHalf = (kRightHandRest - kRightShoulder).distance / 2;

/// Where the doll stands (body moves pivot here).
const Offset kFeetPivot = Offset(100, 362);

/// One moment of a pose: where her hands are and how her body is turned.
/// Everything in between is worked out from this (elbows, hair swing...).
class PoseFrame {
  const PoseFrame({
    this.leftHand = kLeftHandRest,
    this.rightHand = kRightHandRest,
    this.leftPeace = 0,
    this.rightPeace = 0,
    this.tilt = 0,
    this.lift = 0,
    this.spin = 1,
    this.squash = 0,
  });

  /// Standing still with her arms down.
  static const PoseFrame rest = PoseFrame();

  final Offset leftHand;
  final Offset rightHand;

  /// 0..1: two fingers up (a peace sign) on that hand.
  final double leftPeace;
  final double rightPeace;

  /// Leaning sideways around her feet (radians, + leans right).
  final double tilt;

  /// Up in the air (doll units).
  final double lift;

  /// Horizontal scale while twirling: 1 = facing us, -1 = turned around.
  final double spin;

  /// Squished down (+) for a dip, or stretched up (-) for a hop.
  final double squash;

  PoseFrame lerp(PoseFrame o, double t) {
    double l(double a, double b) => a + (b - a) * t;
    return PoseFrame(
      leftHand: Offset.lerp(leftHand, o.leftHand, t)!,
      rightHand: Offset.lerp(rightHand, o.rightHand, t)!,
      leftPeace: l(leftPeace, o.leftPeace),
      rightPeace: l(rightPeace, o.rightPeace),
      tilt: l(tilt, o.tilt),
      lift: l(lift, o.lift),
      spin: l(spin, o.spin),
      squash: l(squash, o.squash),
    );
  }

  PoseFrame copyWith({
    Offset? leftHand,
    Offset? rightHand,
    double? leftPeace,
    double? rightPeace,
    double? tilt,
    double? lift,
    double? spin,
    double? squash,
  }) => PoseFrame(
    leftHand: leftHand ?? this.leftHand,
    rightHand: rightHand ?? this.rightHand,
    leftPeace: leftPeace ?? this.leftPeace,
    rightPeace: rightPeace ?? this.rightPeace,
    tilt: tilt ?? this.tilt,
    lift: lift ?? this.lift,
    spin: spin ?? this.spin,
    squash: squash ?? this.squash,
  );

  /// Moves [canvas] (doll space) so the whole body is posed.
  void applyBody(Canvas canvas) {
    if (tilt == 0 && lift == 0 && spin == 1 && squash == 0) return;
    canvas.translate(kFeetPivot.dx, kFeetPivot.dy - lift);
    canvas.rotate(tilt);
    canvas.scale(spin * (1 + squash * 0.6), 1 - squash);
    canvas.translate(-kFeetPivot.dx, -kFeetPivot.dy);
  }

  /// Where the doll-space point [p] ends up after [applyBody].
  Offset bodyPoint(Offset p) {
    final x = (p.dx - kFeetPivot.dx) * spin * (1 + squash * 0.6);
    final y = (p.dy - kFeetPivot.dy) * (1 - squash);
    final c = math.cos(tilt), s = math.sin(tilt);
    return Offset(
      kFeetPivot.dx + x * c - y * s,
      kFeetPivot.dy - lift + x * s + y * c,
    );
  }

  bool get isRest =>
      leftHand == kLeftHandRest &&
      rightHand == kRightHandRest &&
      leftPeace == 0 &&
      rightPeace == 0 &&
      tilt == 0 &&
      lift == 0 &&
      spin == 1 &&
      squash == 0;
}

/// Shoulder, elbow and hand of one arm reaching for a point.
class ArmBones {
  ArmBones._({
    required this.right,
    required this.shoulder,
    required this.elbow,
    required this.hand,
  });

  /// Bends the arm so the hand reaches [target] (as close as it can),
  /// with the elbow pointing away from her body.
  factory ArmBones.reach({required bool right, required Offset target}) {
    final shoulder = right ? kRightShoulder : kLeftShoulder;
    final a = kArmHalf;
    var toHand = target - shoulder;
    var d = toHand.distance;
    if (d < 4) {
      toHand = const Offset(0, 4);
      d = 4;
    }
    if (d > 2 * a) {
      toHand = toHand * (2 * a / d);
      d = 2 * a;
    }
    final base = math.atan2(toHand.dy, toHand.dx);
    // Law of cosines, with both bones the same length.
    final bend = math.acos((d / (2 * a)).clamp(-1.0, 1.0));
    Offset elbowAt(double angle) =>
        shoulder + Offset(math.cos(angle), math.sin(angle)) * a;
    final e1 = elbowAt(base + bend);
    final e2 = elbowAt(base - bend);
    final out = right ? 1.0 : -1.0;
    final elbow = (e1.dx - shoulder.dx) * out >= (e2.dx - shoulder.dx) * out
        ? e1
        : e2;
    return ArmBones._(
      right: right,
      shoulder: shoulder,
      elbow: elbow,
      hand: shoulder + toHand,
    );
  }

  final bool right;
  final Offset shoulder;
  final Offset elbow;
  final Offset hand;

  Offset get restHand => right ? kRightHandRest : kLeftHandRest;

  /// Direction of the arm in the art (hanging down).
  double get restAngle {
    final d = restHand - shoulder;
    return math.atan2(d.dy, d.dx);
  }

  Offset get restElbow =>
      shoulder + Offset(math.cos(restAngle), math.sin(restAngle)) * kArmHalf;

  double get upperAngle {
    final d = elbow - shoulder;
    return math.atan2(d.dy, d.dx);
  }

  double get lowerAngle {
    final d = hand - elbow;
    return math.atan2(d.dy, d.dx);
  }

  /// How far the hand moved from where it is in the art.
  Offset get handShift => hand - restHand;

  /// True when the arm is lifted away from her side (then it is drawn in
  /// front of her hair instead of behind it).
  bool get raised => (hand - restHand).distance > 14;
}

/// A smooth start and stop between key poses.
double easeInOut(double t) => t * t * (3 - 2 * t);

/// One key pose at [time] seconds.
class PoseKey {
  const PoseKey(this.time, this.frame);
  final double time;
  final PoseFrame frame;
}

/// The pose at [t] seconds, moving smoothly from key to key.
PoseFrame samplePoseKeys(List<PoseKey> keys, double t) {
  if (t <= keys.first.time) return keys.first.frame;
  for (var i = 1; i < keys.length; i++) {
    final b = keys[i];
    if (t <= b.time) {
      final a = keys[i - 1];
      final span = b.time - a.time;
      final u = span <= 0 ? 1.0 : (t - a.time) / span;
      return a.frame.lerp(b.frame, easeInOut(u));
    }
  }
  return keys.last.frame;
}

/// Waving hello, looped (the title screen). [t] in seconds.
PoseFrame wavingFrame(double t) {
  final swing = math.sin(t * 2 * math.pi * 1.4);
  return PoseFrame(
    rightHand: Offset(153 + swing * 9, 120 - swing.abs() * 3),
    tilt: -0.012 + swing * 0.008,
  );
}

/// A wobbly spring: pushed by a force, swings and settles back to 0.
class _Spring {
  _Spring(this.freq, this.damping);
  final double freq;
  final double damping;
  double x = 0;
  double v = 0;

  void step(double dt, double force) {
    final w = 2 * math.pi * freq;
    // Small steps keep the spring steady even when a frame is late.
    var t = dt;
    while (t > 0) {
      final h = math.min(t, 1 / 120);
      final a = -w * w * x - 2 * damping * w * v + force;
      v += a * h;
      x += v * h;
      t -= h;
    }
  }

  /// The force that holds the spring at [target].
  double hold(double target) => math.pow(2 * math.pi * freq, 2) * target;

  bool get still => x.abs() < 0.0015 && v.abs() < 0.01;

  void reset() => x = v = 0;
}

/// Hair and skirts swinging after she moves: three little springs that
/// lag behind her body and then settle.
class SwayPhysics {
  final _Spring _hair = _Spring(1.4, 0.17);
  final _Spring _skirt = _Spring(1.9, 0.2);
  final _Spring _flare = _Spring(2.4, 0.25);

  Offset? _lastHead;
  Offset? _headV;
  double _lastSpin = 1;

  static const double maxHair = 0.16;
  static const double maxSkirt = 0.11;
  static const double maxFlare = 0.12;

  /// Sideways swing of the hair (a skew, about radians).
  double get hair => _hair.x.clamp(-maxHair, maxHair);

  /// Sideways swing of skirts and dresses.
  double get skirt => _skirt.x.clamp(-maxSkirt, maxSkirt);

  /// How much the skirt flares out (0 = normal).
  double get flare => _flare.x.clamp(-maxFlare * 0.4, maxFlare);

  /// A little push, e.g. when she is tapped or hops.
  void kick({double hair = 0, double skirt = 0, double flare = 0}) {
    _hair.v += hair;
    _skirt.v += skirt;
    _flare.v += flare;
  }

  /// Advances the springs by [dt] seconds while the body is in [frame].
  void step(double dt, PoseFrame frame) {
    if (dt <= 0) return;
    // The top of her head: the hair follows it.
    final head = frame.bodyPoint(const Offset(100, 60));
    var ax = 0.0;
    var vy = 0.0;
    final last = _lastHead;
    if (last != null) {
      final v = (head - last) / dt;
      final lastV = _headV ?? v;
      ax = ((v.dx - lastV.dx) / dt).clamp(-5000.0, 5000.0);
      vy = v.dy.clamp(-600.0, 600.0);
      _headV = v;
    }
    _lastHead = head;
    final spinRate = ((frame.spin - _lastSpin) / dt).clamp(-20.0, 20.0);
    _lastSpin = frame.spin;

    // The springs lag behind: when the body speeds up to the right, the
    // hair swings to the left.
    _hair.step(dt, -ax * 0.011 - spinRate * 0.5);
    _skirt.step(dt, -ax * 0.008 + spinRate * 0.35);
    // Moving up and down or twirling makes the skirt flare out.
    final flareTarget = (vy.abs() * 0.00028 + spinRate.abs() * 0.025).clamp(
      0.0,
      maxFlare,
    );
    _flare.step(dt, _flare.hold(flareTarget));
  }

  /// True when everything has settled.
  bool get still => _hair.still && _skirt.still && _flare.still;

  /// Stops all swinging at once.
  void reset() {
    _hair.reset();
    _skirt.reset();
    _flare.reset();
    forgetSpeed();
  }

  /// Forgets the body's speed (after a pause) but keeps swinging.
  void forgetSpeed() {
    _lastHead = null;
    _headV = null;
    _lastSpin = 1;
  }
}
