import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Progress ring — the home progress summary (46px) and the record donut (74–86px). Track is a
/// faint calm; the arc animates over ~400ms (README > Animation). Rounded caps, starts at 12
/// o'clock.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.fraction,
    this.diameter = 46,
    this.strokeWidth = 6,
    this.color,
    this.trackColor,
    this.center,
  });

  final double fraction;
  final double diameter;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final arc = color ?? context.colors.calm;
    final track = trackColor ?? context.colors.calm.withValues(alpha: 0.22);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(value, arc, track, strokeWidth),
          child: center == null ? null : Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.arc, this.track, this.strokeWidth);

  final double fraction;
  final Color arc;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base..color = track);
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, base..color = arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.arc != arc || old.track != track;
}
