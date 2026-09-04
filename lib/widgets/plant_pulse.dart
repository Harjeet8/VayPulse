import 'package:flutter/material.dart';

class PlantPulse extends StatelessWidget {
  final Color color;
  final double height;

  const PlantPulse({super.key, required this.color, this.height = 54});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(painter: _PlantPulsePainter(color)),
      );
}

class _PlantPulsePainter extends CustomPainter {
  final Color color;

  const _PlantPulsePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final faint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var row = 1; row < 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), faint);
    }

    final path = Path()..moveTo(0, size.height * 0.58);
    path.lineTo(size.width * 0.15, size.height * 0.58);
    path.cubicTo(
      size.width * 0.22,
      size.height * 0.58,
      size.width * 0.23,
      size.height * 0.18,
      size.width * 0.3,
      size.height * 0.2,
    );
    path.cubicTo(
      size.width * 0.36,
      size.height * 0.22,
      size.width * 0.36,
      size.height * 0.82,
      size.width * 0.44,
      size.height * 0.78,
    );
    path.cubicTo(
      size.width * 0.51,
      size.height * 0.75,
      size.width * 0.5,
      size.height * 0.42,
      size.width * 0.58,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.66,
      size.height * 0.47,
      size.width * 0.69,
      size.height * 0.58,
      size.width * 0.78,
      size.height * 0.58,
    );
    path.lineTo(size.width, size.height * 0.58);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    final leaf = Path()
      ..moveTo(size.width * 0.28, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.38,
        0,
        size.width * 0.45,
        size.height * 0.13,
      )
      ..quadraticBezierTo(
        size.width * 0.37,
        size.height * 0.3,
        size.width * 0.28,
        size.height * 0.2,
      );
    canvas.drawPath(
      leaf,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PlantPulsePainter oldDelegate) =>
      oldDelegate.color != color;
}
