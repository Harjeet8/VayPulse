import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Subtle additive motion layer for the existing PhytoSense boot.
/// No text or branding is replaced; this only adds signal-flow depth.
class BootMotionPolish extends StatelessWidget {
  final double progress;
  final double phase;
  final bool dark;

  const BootMotionPolish({
    super.key,
    required this.progress,
    required this.phase,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BootMotionPainter(
          progress: progress,
          phase: phase,
          dark: dark,
        ),
      ),
    );
  }
}

class _BootMotionPainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool dark;

  const _BootMotionPainter({
    required this.progress,
    required this.phase,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 72);
    final reveal = Curves.easeOutCubic.transform(
      ((progress - 0.08) / 0.72).clamp(0.0, 1.0).toDouble(),
    );
    final settle = Curves.easeOutCubic.transform(
      ((progress - 0.42) / 0.5).clamp(0.0, 1.0).toDouble(),
    );
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final haloColor = dark ? const Color(0xFFB9E7D4) : const Color(0xFF176B4D);
    final routeColor = dark ? const Color(0xFF8BD7B5) : const Color(0xFF2B8D64);
    final packetColor =
        dark ? const Color(0xFFD7F7E9) : const Color(0xFF176B4D);
    final glowColor = dark ? const Color(0xFF8FE1BD) : const Color(0xFF31A36F);

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = haloColor.withValues(
        alpha: (0.025 + pulse * 0.05) * reveal,
      );
    for (var i = 0; i < 3; i++) {
      final radius = 92.0 + i * 19 + pulse * (2 + i);
      canvas.drawCircle(center, radius, haloPaint);
    }

    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..strokeCap = StrokeCap.round
      ..color = routeColor.withValues(alpha: 0.06 * reveal);

    final routes = <Path>[
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.34)
        ..cubicTo(
          size.width * 0.24,
          size.height * 0.27,
          size.width * 0.32,
          center.dy - 18,
          center.dx - 46,
          center.dy,
        ),
      Path()
        ..moveTo(size.width * 0.92, size.height * 0.39)
        ..cubicTo(
          size.width * 0.76,
          size.height * 0.30,
          size.width * 0.69,
          center.dy + 22,
          center.dx + 48,
          center.dy + 4,
        ),
      Path()
        ..moveTo(size.width * 0.18, size.height * 0.72)
        ..cubicTo(
          size.width * 0.34,
          size.height * 0.67,
          size.width * 0.39,
          center.dy + 82,
          center.dx - 18,
          center.dy + 50,
        ),
      Path()
        ..moveTo(size.width * 0.82, size.height * 0.69)
        ..cubicTo(
          size.width * 0.69,
          size.height * 0.63,
          size.width * 0.62,
          center.dy + 78,
          center.dx + 22,
          center.dy + 50,
        ),
    ];

    for (final route in routes) {
      canvas.drawPath(route, pathPaint);
    }

    final packetPaint = Paint()..style = PaintingStyle.fill;
    for (var routeIndex = 0; routeIndex < routes.length; routeIndex++) {
      final metrics =
          routes[routeIndex].computeMetrics().toList(growable: false);
      if (metrics.isEmpty) continue;
      final metric = metrics.first;
      final local = (phase + routeIndex * 0.19) % 1.0;
      final tangent = metric.getTangentForOffset(metric.length * local);
      if (tangent == null) continue;
      packetPaint.color = packetColor.withValues(
        alpha: (0.18 + 0.55 * settle) * reveal,
      );
      canvas.drawCircle(tangent.position, 1.7 + settle * 0.8, packetPaint);
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = glowColor.withValues(alpha: 0.055 * reveal);
      canvas.drawCircle(tangent.position, 6.5, glowPaint);
    }

    if (settle > 0) {
      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = haloColor.withValues(alpha: 0.09 * settle);
      for (var i = 0; i < 20; i++) {
        final angle = i / 20 * math.pi * 2;
        final inner = center + Offset(math.cos(angle), math.sin(angle)) * 119;
        final outer = center +
            Offset(math.cos(angle), math.sin(angle)) * (i % 5 == 0 ? 126 : 123);
        canvas.drawLine(inner, outer, tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BootMotionPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.dark != dark;
}
