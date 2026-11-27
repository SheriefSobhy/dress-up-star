import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/game_config.dart';
import '../l10n/app_strings.dart';
import '../models/fashion_show.dart';
import '../painting/shapes.dart';
import 'big_round_button.dart';
import 'challenge_widgets.dart';

// Everything here is drawn with plain source-over paints (some blend modes
// crash on Android's Impeller).

/// A sparkly runway with a spotlight: the picture of the Fashion Show.
class RunwayIcon extends StatelessWidget {
  const RunwayIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _RunwayIconPainter());
}

class _RunwayIconPainter extends CustomPainter {
  const _RunwayIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    Path poly(List<double> p) {
      final path = Path()..moveTo(p[0], p[1]);
      for (var i = 2; i < p.length; i += 2) {
        path.lineTo(p[i], p[i + 1]);
      }
      return path..close();
    }

    // Spotlight beam and lamp.
    canvas.drawPath(
      poly([44, 14, 56, 14, 78, 68, 22, 68]),
      Paint()..color = const Color(0xCCFFF3A0),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(38, 6, 62, 18, const Radius.circular(6)),
      Paint()..color = const Color(0xFF7A4AB0),
    );
    // The runway.
    final runway = poly([38, 60, 62, 60, 86, 94, 14, 94]);
    canvas.drawPath(runway, Paint()..color = const Color(0xFFFF5FA8));
    canvas.drawPath(
      runway,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    final gold = Paint()..color = const Color(0xFFFFC21E);
    canvas.drawPath(starPath(const Offset(50, 45), 17), gold);
    canvas.drawPath(starPath(const Offset(19, 30), 9), gold);
    canvas.drawPath(starPath(const Offset(83, 38), 11), gold);
  }

  @override
  bool shouldRepaint(_RunwayIconPainter old) => false;
}

/// The Show button: the runway, or the picture of the theme while she is
/// getting ready.
class ShowButton extends StatelessWidget {
  const ShowButton({
    super.key,
    required this.theme,
    required this.size,
    required this.onTap,
  });

  final ChallengeTheme? theme;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Semantics(
      button: true,
      label: AppStrings.of(context).fashionShow,
      child: Pressable(
        key: const Key('show_button'),
        onTap: onTap,
        builder: (pressed) => SizedBox.square(
          dimension: size,
          child: GlossyCircle(
            color: const Color(0xFF8E6BE8),
            size: size,
            pressed: pressed,
            child: Padding(
              padding: EdgeInsets.all(size * 0.1),
              child: t == null ? RunwayIcon(size: size * 0.7) : ThemePicture(t),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stage behind the doll: curtains, sweeping spotlights, light bulbs
/// and the runway. [time] is in seconds. Lite mode has fewer lights.
class StagePainter extends CustomPainter {
  StagePainter({required this.time, required this.lite});

  final double time;
  final bool lite;

  /// Where the floor begins and the runway's width, as parts of the screen.
  static const double horizon = 0.45;
  static const double farWidth = 0.3;
  static const double nearWidth = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, floor = h * horizon;
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF35186A), Color(0xFF8A3FA0)],
        ).createShader(Rect.fromLTWH(0, 0, w, floor)),
    );
    // Spotlights sweeping from the ceiling.
    const colors = [
      Color(0x33FFF3B0),
      Color(0x33B0E8FF),
      Color(0x33FFB0E0),
      Color(0x33C8FFB0),
    ];
    final beams = lite ? 2 : 4;
    for (var i = 0; i < beams; i++) {
      final x = w * (i + 0.5) / beams;
      final aim = x + math.sin(time * 1.3 + i * 1.9) * w * 0.22;
      canvas.drawPath(
        Path()
          ..moveTo(x - 8, 0)
          ..lineTo(x + 8, 0)
          ..lineTo(aim + w * 0.16, h * 0.72)
          ..lineTo(aim - w * 0.16, h * 0.72)
          ..close(),
        Paint()..color = colors[i],
      );
    }
    // Curtains on both sides.
    for (final side in [0.0, 1.0]) {
      canvas.save();
      if (side == 1) {
        canvas.translate(w, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(w * 0.19, 0)
          ..quadraticBezierTo(w * 0.15, floor * 0.5, w * 0.06, floor * 0.68)
          ..quadraticBezierTo(w * 0.14, floor * 0.82, w * 0.12, floor)
          ..lineTo(0, floor)
          ..close(),
        Paint()..color = const Color(0xFFE8447E),
      );
      final fold = Paint()
        ..color = const Color(0xFFB82A60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      for (final f in [0.05, 0.11]) {
        canvas.drawPath(
          Path()
            ..moveTo(w * f, 0)
            ..quadraticBezierTo(w * f, floor * 0.5, w * 0.03, floor * 0.68),
          fold,
        );
      }
      canvas.restore();
    }
    // Floor.
    canvas.drawRect(
      Rect.fromLTRB(0, floor, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A2A78), Color(0xFF2E1650)],
        ).createShader(Rect.fromLTRB(0, floor, w, h)),
    );
    // Runway.
    final far = w * farWidth / 2, near = w * nearWidth / 2;
    canvas.drawPath(
      Path()
        ..moveTo(w / 2 - far, floor)
        ..lineTo(w / 2 + far, floor)
        ..lineTo(w / 2 + near, h)
        ..lineTo(w / 2 - near, h)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB0D8), Color(0xFFFF5FA8)],
        ).createShader(Rect.fromLTRB(0, floor, w, h)),
    );
    // Little bulbs along the runway and over the stage, taking turns.
    void bulb(Offset at, double r, bool on) {
      if (!lite) {
        canvas.drawCircle(
          at,
          r * 2,
          Paint()..color = Color(on ? 0x55FFF3A0 : 0x18FFF3A0),
        );
      }
      canvas.drawCircle(
        at,
        r,
        Paint()..color = Color(on ? 0xFFFFF8D0 : 0xFFE0B860),
      );
    }

    final step = (time * 3).floor();
    final along = lite ? 4 : 8;
    for (var i = 0; i < along; i++) {
      final t = (i + 0.5) / along;
      final y = floor + (h - floor) * t;
      final half = far + (near - far) * t;
      for (final x in [w / 2 - half, w / 2 + half]) {
        bulb(Offset(x, y), 2.5 + 3 * t, (i + step).isEven);
      }
    }
    final top = lite ? 5 : 11;
    for (var i = 0; i < top; i++) {
      bulb(Offset(w * (i + 0.5) / top, 5), 5, (i + step).isEven);
    }
  }

  @override
  bool shouldRepaint(StagePainter old) => old.time != time || old.lite != lite;
}

/// The cartoon audience on both sides of the runway, bouncing and waving,
/// and (while [flashing]) little camera flashes. Never a full-screen flash.
class AudiencePainter extends CustomPainter {
  AudiencePainter({
    required this.time,
    required this.lite,
    required this.flashing,
  });

  final double time;
  final bool lite;
  final bool flashing;

  static const _coats = [
    Color(0xFFFFB347),
    Color(0xFF7CB8FF),
    Color(0xFF8EE08A),
    Color(0xFFFF8FC7),
    Color(0xFFD9A066),
    Color(0xFFB79CFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w * 0.062;
    const rows = 5;
    for (var row = 0; row < rows; row++) {
      for (var side = 0; side < 2; side++) {
        final i = row * 2 + side;
        final y = h * (0.54 + row * 0.105);
        final inset = r * (row.isEven ? 0.9 : 0.45);
        final x = side == 0 ? inset : w - inset;
        final hop = math.sin(time * 7 + i * 1.7).abs() * r * 0.28;
        _fan(canvas, Offset(x, y - hop), r * (0.85 + row * 0.07), i);
      }
    }
    if (!flashing) return;
    // A new flash every so often, at a spot that depends on its number.
    final every = lite ? 1.2 : 0.3;
    final beat = (time / every).floor();
    final age = (time / every - beat) * every;
    if (age > 0.2) return;
    final random = math.Random(beat * 7 + 1);
    final x = random.nextBool()
        ? w * (0.04 + random.nextDouble() * 0.14)
        : w * (0.82 + random.nextDouble() * 0.14);
    final at = Offset(x, h * (0.48 + random.nextDouble() * 0.38));
    final glow = 1 - age / 0.2;
    canvas.drawCircle(
      at,
      r * 0.9 * glow,
      Paint()..color = Colors.white.withValues(alpha: 0.4 * glow),
    );
    canvas.drawPath(
      starPath(at, r * 0.75 * glow),
      Paint()..color = Colors.white,
    );
  }

  /// One happy animal: bear, cat or bunny ears, arms up.
  void _fan(Canvas canvas, Offset c, double r, int i) {
    final coat = Paint()..color = _coats[i % _coats.length];
    final dark = Paint()..color = const Color(0xFF3A2450);
    final wave = math.sin(time * 9 + i) * r * 0.2;
    for (final s in [-1.0, 1.0]) {
      final hand = c + Offset(s * r * 1.15 + wave, -r * 0.35);
      canvas.drawLine(
        c + Offset(s * r * 0.5, r * 0.9),
        hand,
        Paint()
          ..color = coat.color
          ..strokeWidth = r * 0.34
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(hand, r * 0.24, coat);
      switch (i % 3) {
        case 0:
          canvas.drawCircle(c + Offset(s * r * 0.7, -r * 0.72), r * 0.36, coat);
        case 1:
          canvas.drawPath(
            Path()
              ..moveTo(c.dx + s * r * 0.95, c.dy - r * 0.2)
              ..lineTo(c.dx + s * r * 0.85, c.dy - r * 1.25)
              ..lineTo(c.dx + s * r * 0.2, c.dy - r * 0.85)
              ..close(),
            coat,
          );
        default:
          canvas.drawOval(
            Rect.fromCenter(
              center: c + Offset(s * r * 0.45, -r * 1.15),
              width: r * 0.42,
              height: r * 1.2,
            ),
            coat,
          );
      }
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, r * 1.5),
        width: r * 1.9,
        height: r * 1.8,
      ),
      coat,
    );
    canvas.drawCircle(c, r, coat);
    final line = Paint()
      ..color = dark.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.11
      ..strokeCap = StrokeCap.round;
    for (final s in [-1.0, 1.0]) {
      // Closed, smiling eyes.
      canvas.drawArc(
        Rect.fromCircle(
          center: c + Offset(s * r * 0.38, -r * 0.05),
          radius: r * 0.18,
        ),
        math.pi,
        math.pi,
        false,
        line,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(0, r * 0.18), radius: r * 0.32),
      0.15,
      math.pi - 0.3,
      true,
      dark,
    );
  }

  @override
  bool shouldRepaint(AudiencePainter old) =>
      old.time != time || old.lite != lite || old.flashing != flashing;
}

/// One judge behind a little desk. Their card with [stars] pops up while
/// [reveal] goes from 0 to 1. A picture on the desk shows what they judge.
class JudgeStand extends StatelessWidget {
  const JudgeStand({
    super.key,
    required this.judge,
    required this.stars,
    required this.reveal,
    required this.criterion,
    required this.width,
  });

  final Judge judge;
  final int stars;
  final double reveal;
  final Widget criterion;
  final double width;

  @override
  Widget build(BuildContext context) {
    final pop = Curves.easeOutBack.transform(reveal.clamp(0.0, 1.0));
    final card = width * 0.86;
    final star = card * 0.29;
    Widget row(int from, int to) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = from; i < to; i++)
          CustomPaint(
            key: Key('card_${judge.name}_$i'),
            size: Size.square(star),
            painter: const _CardStarPainter(),
          ),
      ],
    );
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: card * 0.7,
            child: reveal <= 0
                ? null
                : Transform.translate(
                    offset: Offset(0, (1 - pop) * card * 0.6),
                    child: Transform.scale(
                      scale: pop,
                      child: Container(
                        width: card,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFFC23D),
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            row(0, math.min(3, stars)),
                            if (stars > 3) row(3, stars),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          CustomPaint(
            size: Size(width * 0.8, width * 0.7),
            painter: _JudgePainter(judge),
          ),
          Container(
            width: width * 0.92,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: SizedBox.square(dimension: 32, child: criterion),
          ),
        ],
      ),
    );
  }
}

class _CardStarPainter extends CustomPainter {
  const _CardStarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = starPath(size.center(Offset.zero), size.width * 0.5);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFC21E));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD08A10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CardStarPainter old) => false;
}

/// The cat, bunny and owl judges, drawn in a 100 x 88 space.
class _JudgePainter extends CustomPainter {
  const _JudgePainter(this.judge);

  final Judge judge;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 88);
    final coat = Paint()
      ..color = switch (judge) {
        Judge.cat => const Color(0xFFFFB05C),
        Judge.bunny => const Color(0xFFF4EDF8),
        Judge.owl => const Color(0xFFA9784F),
      };
    final inner = Paint()..color = const Color(0xFFFF9FC0);
    final dark = Paint()..color = const Color(0xFF3A2450);
    Path triangle(
      double ax,
      double ay,
      double bx,
      double by,
      double cx,
      double cy,
    ) => Path()
      ..moveTo(ax, ay)
      ..lineTo(bx, by)
      ..lineTo(cx, cy)
      ..close();
    void oval(double x, double y, double w, double h, Paint p) =>
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          p,
        );

    for (final s in [-1.0, 1.0]) {
      final x = 50 + s * 24;
      switch (judge) {
        case Judge.cat:
          canvas.drawPath(
            triangle(50 + s * 36, 44, 50 + s * 34, 8, 50 + s * 8, 24),
            coat,
          );
          canvas.drawPath(
            triangle(50 + s * 30, 34, 50 + s * 29, 17, 50 + s * 16, 25),
            inner,
          );
        case Judge.bunny:
          oval(50 + s * 16, 18, 17, 38, coat);
          oval(50 + s * 16, 19, 8, 27, inner);
        case Judge.owl:
          canvas.drawPath(
            triangle(x + s * 12, 36, x + s * 14, 10, x - s * 14, 24),
            coat,
          );
      }
    }
    oval(50, 54, 74, 66, coat);
    if (judge == Judge.owl) {
      oval(50, 74, 44, 26, Paint()..color = const Color(0xFFE8C99B));
      for (final x in [34.0, 66.0]) {
        canvas.drawCircle(Offset(x, 47), 15, Paint()..color = Colors.white);
      }
    }
    final eyeY = judge == Judge.owl ? 47.0 : 50.0;
    for (final x in [34.0, 66.0]) {
      canvas.drawCircle(Offset(x, eyeY), judge == Judge.owl ? 7.5 : 6, dark);
      canvas.drawCircle(
        Offset(x + 2, eyeY - 2),
        2.2,
        Paint()..color = Colors.white,
      );
    }
    final line = Paint()
      ..color = dark.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (judge == Judge.owl) {
      canvas.drawPath(
        triangle(43, 58, 57, 58, 50, 70),
        Paint()..color = const Color(0xFFFFB020),
      );
    } else {
      for (final x in [26.0, 74.0]) {
        oval(x, 62, 11, 7, Paint()..color = const Color(0x77FF6BA0));
      }
      canvas.drawPath(triangle(46, 59, 54, 59, 50, 64), inner);
      for (final x in [45.0, 55.0]) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, 66), radius: 5),
          0.2,
          math.pi - 0.4,
          false,
          line,
        );
      }
    }
    if (judge == Judge.cat) {
      for (final s in [-1.0, 1.0]) {
        for (final dy in [-3.0, 4.0]) {
          canvas.drawLine(
            Offset(50 + s * 20, 64 + dy * 0.4),
            Offset(50 + s * 40, 64 + dy),
            line..strokeWidth = 1.4,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_JudgePainter old) => old.judge != judge;
}
