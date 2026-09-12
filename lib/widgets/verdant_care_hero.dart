import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'live_motion.dart';

/// Presentation only: score and condition are supplied by the data source.
class VerdantCareHero extends StatelessWidget {
  final String condition, problem, action, crop, source;
  final double? score;
  final bool tamil, showMeter;
  final Color accent;
  final Widget? controls;
  const VerdantCareHero(
      {super.key,
      required this.condition,
      required this.problem,
      required this.action,
      required this.crop,
      required this.source,
      required this.accent,
      this.score,
      this.tamil = false,
      this.showMeter = true,
      this.controls});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('verdant-care-hero'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor.withValues(alpha: .07),
              blurRadius: 28,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: const Color(0xFF173E32),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.spa_outlined,
                  color: Color(0xFFCADCC2), size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(crop,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(source,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          color: Color(0xFFD9E5CE), fontSize: 12))),
            ]),
            const SizedBox(height: 16),
            if (showMeter)
              LayoutBuilder(builder: (context, box) {
                final status = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tamil ? 'செடியின் நிலை' : 'PLANT CONDITION',
                          style: const TextStyle(
                              color: Color(0xFFBBD2C4),
                              fontSize: 10,
                              letterSpacing: 1)),
                      const SizedBox(height: 7),
                      Text(condition,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: Colors.white, height: 1.25)),
                    ]);
                if (box.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2) {
                  return Column(children: [
                    HealthArc(score: score, tamil: tamil),
                    const SizedBox(height: 10),
                    status
                  ]);
                }
                return Row(children: [
                  HealthArc(score: score, tamil: tamil, compact: true),
                  const SizedBox(width: 18),
                  Expanded(child: status)
                ]);
              })
            else ...[
              const Icon(Icons.spa_rounded, color: Color(0xFFCDDFAB), size: 30),
              const SizedBox(height: 10),
              Text(tamil ? 'செடியின் நிலை' : 'PLANT CONDITION',
                  style: const TextStyle(
                      color: Color(0xFFBBD2C4),
                      fontSize: 11,
                      letterSpacing: 1.5)),
              const SizedBox(height: 5),
              Text(condition,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white, height: 1.25)),
            ],
          ]),
        ),
        Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tamil ? 'என்ன பிரச்சினை?' : 'WHAT IS WRONG?',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(problem,
                  key: const Key('farmer-main-problem'),
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.28)),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: accent.withValues(
                        alpha: theme.brightness == Brightness.dark ? .16 : .09),
                    borderRadius: BorderRadius.circular(18)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          color: accent, size: 23),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                tamil
                                    ? 'இப்போது என்ன செய்ய வேண்டும்'
                                    : 'WHAT TO DO NOW',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .6)),
                            const SizedBox(height: 7),
                            Text(action,
                                key: const Key('farmer-immediate-action'),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600, height: 1.4)),
                          ])),
                    ]),
              ),
              if (controls != null) ...[const SizedBox(height: 14), controls!],
            ])),
      ]),
    );
  }
}

class HealthArc extends StatelessWidget {
  final double? score;
  final bool tamil, compact;
  const HealthArc(
      {super.key, this.score, this.tamil = false, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final value =
        score != null && score!.isFinite && score! >= 0 && score! <= 100
            ? score
            : null;
    return Semantics(
      label: value == null
          ? (tamil ? 'மதிப்பெண் இல்லை' : 'Score unavailable')
          : '${value.round()} / 100',
      child: SizedBox(
          width: compact ? 132 : 250,
          height: compact ? 108 : 163,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
                child: TweenAnimationBuilder<double>(
              tween: Tween(end: value ?? 0),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) =>
                  CustomPaint(painter: _ArcPainter(v, value != null)),
            )),
            Positioned(
                bottom: 2,
                child: Column(children: [
                  if (!compact)
                    const LiveMotion(
                        style: LiveMotionStyle.sway,
                        duration: Duration(seconds: 5),
                        child: Icon(Icons.spa_outlined,
                            size: 34, color: Color(0xFFD4E7B8))),
                  const SizedBox(height: 3),
                  Text(value == null ? '—' : '${value.round()}',
                      key: const Key('plant-health-score'),
                      style: TextStyle(
                          fontSize: compact ? 34 : 43,
                          height: 1.05,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  Text(tamil ? '100-க்கு' : 'OUT OF 100',
                      style: const TextStyle(
                          color: Color(0xFFC5D9CD),
                          fontSize: 10,
                          letterSpacing: 1.2)),
                ])),
          ])),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final bool available;
  _ArcPainter(this.value, this.available);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 25);
    final radius = math.min(size.width / 2 - 14, size.height - 35);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    p.color = const Color(0xFF406353);
    canvas.drawArc(rect, math.pi, math.pi, false, p);
    if (!available) return;
    p.shader = const SweepGradient(
            startAngle: math.pi,
            endAngle: math.pi * 2,
            colors: [Color(0xFFDFA48B), Color(0xFFE5C781), Color(0xFFA7D6A6)])
        .createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi * value / 100, false, p);
    final angle = math.pi + math.pi * value / 100;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(point, 7, Paint()..color = Colors.white);
    canvas.drawCircle(point, 3, Paint()..color = phytoGreen);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.available != available;
}
