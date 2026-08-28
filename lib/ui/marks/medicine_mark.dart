import 'package:flutter/material.dart';

/// The six medicine marks (README > Medicine Marks). Every medicine is assigned ONE mark at
/// creation; the same mark represents it on every screen (timeline, cabinet, alarm, record, email).
/// It is the primary non-textual identifier for low-literacy users, so it is stored on the medicine
/// record — never derived.
///
/// Geometry is authored in a 30×30 box and scaled to the requested size. Colour is passed in so
/// callers can use the stored markColor, or the lightened variants on the dark alarm background.
enum MarkShape {
  filledCircle, // circle r=13            — default calm
  ring, // circle r=11.5, sw 3.5  — default calm
  halfFilled, // ring + right half fill — default calm
  roundedSquare, // rect 24×24, r=7        — default slate
  triangle, // M15 3.5 L27 26 H3 Z    — default ochre
  capsule; // rect 22×10, r=5        — default mauve

  /// Stored form. Kept identical to the Kotlin `MarkShape.name` values so a database copied from
  /// the original app still reads correctly.
  String get storedName => switch (this) {
        MarkShape.filledCircle => 'FilledCircle',
        MarkShape.ring => 'Ring',
        MarkShape.halfFilled => 'HalfFilled',
        MarkShape.roundedSquare => 'RoundedSquare',
        MarkShape.triangle => 'Triangle',
        MarkShape.capsule => 'Capsule',
      };

  static MarkShape fromName(String? name) => MarkShape.values.firstWhere(
        (m) => m.storedName == name,
        orElse: () => MarkShape.filledCircle,
      );
}

class MedicineMark extends StatelessWidget {
  const MedicineMark({
    super.key,
    required this.shape,
    required this.color,
    this.size = 30,
  });

  final MarkShape shape;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _MarkPainter(shape, color)),
      );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.shape, this.color);

  final MarkShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = (size.width < size.height ? size.width : size.height) / 30; // design box is 30×30
    double p(double v) => v * k;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = p(3.5)
      ..isAntiAlias = true;
    final center = Offset(p(15), p(15));

    switch (shape) {
      case MarkShape.filledCircle:
        canvas.drawCircle(center, p(13), fill);
      case MarkShape.ring:
        canvas.drawCircle(center, p(11.5), stroke);
      case MarkShape.halfFilled:
        // Right half solid, then the full ring on top.
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(p(15), 0, size.width, size.height));
        canvas.drawCircle(center, p(11.5), fill);
        canvas.restore();
        canvas.drawCircle(center, p(11.5), stroke);
      case MarkShape.roundedSquare:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(p(3), p(3), p(24), p(24)),
            Radius.circular(p(7)),
          ),
          fill,
        );
      case MarkShape.triangle:
        final path = Path()
          ..moveTo(p(15), p(3.5))
          ..lineTo(p(27), p(26))
          ..lineTo(p(3), p(26))
          ..close();
        canvas.drawPath(path, fill);
      case MarkShape.capsule:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(p(4), p(10), p(22), p(10)),
            Radius.circular(p(5)),
          ),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.shape != shape || old.color != color;
}
