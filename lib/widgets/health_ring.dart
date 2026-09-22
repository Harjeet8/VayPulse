import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A display of the supplied score, never a new plant-health calculation.
class HealthRing extends StatelessWidget {
  final double score, size;
  final String label;
  final Color? color, textColor;
  const HealthRing(
      {super.key,
      required this.score,
      this.size = 118,
      this.label = 'Health',
      this.color,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    final valid = score.isFinite && score >= 0 && score <= 100;
    final theme = Theme.of(context);
    final tamil = Localizations.localeOf(context).languageCode == 'ta';
    final caption = label == 'Health' && tamil ? 'ஆரோக்கியம்' : label;
    return Semantics(
      label: valid
          ? '$caption ${score.round()} / 100'
          : (tamil ? 'அளவீடு இல்லை' : 'Score unavailable'),
      child: SizedBox.square(
          dimension: size,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
                child: TweenAnimationBuilder<double>(
              tween: Tween(end: valid ? score : 0),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => CustomPaint(
                key: const ValueKey('health-ring-scale'),
                painter: _SpectrumRing(
                    value,
                    valid,
                    color ?? theme.colorScheme.primary,
                    theme.colorScheme.surfaceContainerHighest),
              ),
            )),
            Padding(
                padding: EdgeInsets.all(size < 90 ? 14 : 22),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(valid ? '${score.round()}' : '—',
                        style: TextStyle(
                            fontSize: size < 90 ? 25 : 31,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: textColor ?? theme.colorScheme.onSurface)),
                    if (size >= 90) ...[
                      const SizedBox(height: 4),
                      Text(caption,
                          style: TextStyle(
                              fontSize: 10,
                              color: textColor ??
                                  theme.colorScheme.onSurfaceVariant)),
                    ],
                  ]),
                )),
          ])),
    );
  }
}

class _SpectrumRing extends CustomPainter {
  final double value;
  final bool valid;
  final Color marker, track;
  const _SpectrumRing(this.value, this.valid, this.marker, this.track);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 9;
    final stroke = size.shortestSide < 90 ? 7.0 : 10.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * .75, sweep = math.pi * 1.5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, start, sweep, false, paint);
    if (!valid) return;
    paint.strokeCap = StrokeCap.butt;
    paint.shader = const SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      transform: GradientRotation(start),
      colors: [Color(0xFFE98570), Color(0xFFF0C35D), Color(0xFF66C794)],
    ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, paint);
    Offset point(double angle) =>
        center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
        point(start), stroke / 2, Paint()..color = const Color(0xFFE98570));
    canvas.drawCircle(point(start + sweep), stroke / 2,
        Paint()..color = const Color(0xFF66C794));
    final position = point(start + sweep * value / 100);
    canvas.drawCircle(position, stroke * .7, Paint()..color = Colors.white);
    canvas.drawCircle(position, stroke * .38, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_SpectrumRing old) =>
      old.value != value ||
      old.valid != valid ||
      old.marker != marker ||
      old.track != track;
}
