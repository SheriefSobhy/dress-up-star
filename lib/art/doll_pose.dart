import 'dart:math' as math;
import 'dart:ui';

import '../models/game_item.dart' show DollPose;

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

  /// [spin], but never thinner than a sliver of her (a flat drawing seen
  /// edge-on would vanish mid-twirl).
  double get _turn =>
      spin.isNegative ? math.min(spin, -0.2) : math.max(spin, 0.2);

  /// Moves [canvas] (doll space) so the whole body is posed.
  void applyBody(Canvas canvas) {
    if (tilt == 0 && lift == 0 && spin == 1 && squash == 0) return;
    canvas.translate(kFeetPivot.dx, kFeetPivot.dy - lift);
    canvas.rotate(tilt);
    canvas.scale(_turn * (1 + squash * 0.6), 1 - squash);
    canvas.translate(-kFeetPivot.dx, -kFeetPivot.dy);
  }

  /// Where the doll-space point [p] ends up after [applyBody].
  Offset bodyPoint(Offset p) {
    final x = (p.dx - kFeetPivot.dx) * _turn * (1 + squash * 0.6);
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

// ------------------------------------------------------------------ poses

const PoseFrame _waveHeld = PoseFrame(
  rightHand: Offset(153, 118),
  tilt: -0.015,
);
const PoseFrame _armsOut = PoseFrame(
  leftHand: Offset(26, 196),
  rightHand: Offset(174, 196),
);
const PoseFrame _twirlHeld = PoseFrame(
  leftHand: Offset(30, 206),
  rightHand: Offset(170, 206),
);
const PoseFrame _peaceHeld = PoseFrame(
  leftHand: Offset(76, 214),
  rightHand: Offset(150, 124),
  rightPeace: 1,
  tilt: 0.025,
);
const PoseFrame _hipsHeld = PoseFrame(
  leftHand: Offset(76, 214),
  rightHand: Offset(124, 214),
);
const PoseFrame _skirtHold = PoseFrame(
  leftHand: Offset(42, 238),
  rightHand: Offset(158, 238),
);
const PoseFrame _cheer = PoseFrame(
  leftHand: Offset(50, 112),
  rightHand: Offset(150, 112),
);

/// How she stands after doing [pose].
PoseFrame heldPoseFrame(DollPose pose) => switch (pose) {
  DollPose.stand => PoseFrame.rest,
  DollPose.wave => _waveHeld,
  DollPose.twirl => _twirlHeld,
  DollPose.peace => _peaceHeld,
  DollPose.hips => _hipsHeld,
  DollPose.curtsy => _skirtHold.copyWith(tilt: 0.02),
  DollPose.jump => _cheer,
};

/// The move into [pose], starting from [from]. It ends in
/// [heldPoseFrame].
List<PoseKey> poseMove(DollPose pose, PoseFrame from) {
  final held = heldPoseFrame(pose);
  PoseKey k(double t, PoseFrame f) => PoseKey(t, f);
  final keys = switch (pose) {
    DollPose.stand => [k(0.5, held)],
    DollPose.wave => [
      for (var i = 0; i < 5; i++)
        k(
          0.35 + i * 0.25,
          held.copyWith(
            rightHand: i.isEven
                ? const Offset(160, 114)
                : const Offset(144, 121),
            tilt: i.isEven ? -0.025 : -0.005,
          ),
        ),
      k(1.6, held),
    ],
    DollPose.twirl => [
      k(0.25, _armsOut.copyWith(squash: 0.04)),
      k(0.6, _armsOut.copyWith(spin: -1, lift: 10, squash: -0.03)),
      k(0.95, _armsOut.copyWith(spin: 1, lift: 0)),
      k(1.3, held),
    ],
    DollPose.peace => [
      k(0.3, from.lerp(held, 0.5).copyWith(lift: 7, squash: -0.03)),
      k(0.6, held.copyWith(squash: 0.04)),
      k(1.0, held),
    ],
    DollPose.hips => [
      k(0.35, held.copyWith(squash: 0.045)),
      k(0.6, held.copyWith(lift: 5, squash: -0.025)),
      k(0.9, held),
    ],
    DollPose.curtsy => [
      k(0.35, _skirtHold),
      k(0.8, _skirtHold.copyWith(squash: 0.075, lift: -1)),
      k(1.2, _skirtHold),
      k(1.6, held),
    ],
    DollPose.jump => [
      k(0.2, from.copyWith(squash: 0.07)),
      k(0.45, _cheer.copyWith(lift: 36, squash: -0.05)),
      k(0.7, _cheer.copyWith(squash: 0.06)),
      k(0.9, _cheer.copyWith(squash: -0.02)),
      k(1.1, held),
    ],
  };
  return [PoseKey(0, from), ...keys];
}

/// Seconds the move into a pose takes.
double poseMoveSeconds(DollPose pose) =>
    poseMove(pose, PoseFrame.rest).last.time;

// ------------------------------------------------------------------ dance

/// The music's speed (beats per minute), so she dances in time.
const double danceBpm = 140;
const double _beat = 60 / danceBpm;

/// 16 beats of dancing, one key pose every half beat; it repeats.
final List<PoseKey> _danceKeys = () {
  final up = [
    // Sway side to side, waving one arm up then the other.
    PoseFrame(rightHand: const Offset(162, 104), tilt: 0.07),
    PoseFrame(leftHand: const Offset(38, 104), tilt: -0.07),
    PoseFrame(rightHand: const Offset(162, 104), tilt: 0.07),
    PoseFrame(leftHand: const Offset(38, 104), tilt: -0.07),
    // Hands on hips, bounce bounce.
    _hipsHeld.copyWith(squash: 0.05),
    _hipsHeld.copyWith(lift: 6, squash: -0.03),
    // Twirl!
    _armsOut.copyWith(spin: -1, lift: 6),
    _armsOut,
    // Point up to the sky, one side then the other.
    _hipsHeld.copyWith(rightHand: const Offset(172, 96), tilt: 0.06),
    _hipsHeld.copyWith(leftHand: const Offset(28, 96), tilt: -0.06),
    _hipsHeld.copyWith(rightHand: const Offset(172, 96), tilt: 0.06),
    _hipsHeld.copyWith(leftHand: const Offset(28, 96), tilt: -0.06),
    // Jump and cheer.
    _cheer.copyWith(squash: 0.06),
    _cheer.copyWith(lift: 30, squash: -0.04),
    // Clap clap.
    const PoseFrame(leftHand: Offset(94, 200), rightHand: Offset(106, 200)),
    const PoseFrame(leftHand: Offset(70, 204), rightHand: Offset(130, 204)),
  ];
  return [
    for (var i = 0; i <= up.length; i++) PoseKey(i * _beat, up[i % up.length]),
  ];
}();

/// Dancing, [t] seconds in. She bounces on every beat.
PoseFrame danceFrame(double t) {
  final loop = _danceKeys.last.time;
  final frame = samplePoseKeys(_danceKeys, t % loop);
  final bounce = math.sin(math.pi * (t / _beat)).abs();
  return frame.copyWith(lift: frame.lift + bounce * 3);
}

/// A dance of [seconds], starting from [from] and ending in [held].
PoseFrame Function(double t) danceMove(
  PoseFrame from,
  PoseFrame held,
  double seconds,
) {
  const blend = 0.35;
  return (t) {
    if (t < blend) return from.lerp(danceFrame(t), easeInOut(t / blend));
    final end = seconds - t;
    if (end < blend * 1.5) {
      return held.lerp(
        danceFrame(t),
        easeInOut((end / (blend * 1.5)).clamp(0, 1)),
      );
    }
    return danceFrame(t);
  };
}
