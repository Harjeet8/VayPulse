import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sequence;
  late final AnimationController _ambient;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sequence = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 4250), _openApp);
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 720),
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final eased = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(eased),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.018),
                  end: Offset.zero,
                ).animate(eased),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sequence.dispose();
    _ambient.dispose();
    super.dispose();
  }

  double _segment(double value, double begin, double end) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return ((value - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04100C),
      body: AnimatedBuilder(
        animation: Listenable.merge([_sequence, _ambient]),
        builder: (context, _) {
          final timeline = reduceMotion ? 1.0 : _sequence.value;
          final ambient = reduceMotion ? 0.35 : _ambient.value;
          final formation = _segment(timeline, 0.00, 0.48);
          final iconLock = _segment(timeline, 0.32, 0.58);
          final brand = _segment(timeline, 0.48, 0.70);
          final quote = _segment(timeline, 0.66, 0.92);
          final ready = _segment(timeline, 0.86, 1.00);

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF04100C),
                      Color(0xFF071A13),
                      Color(0xFF0A2A1E),
                    ],
                    stops: [0, 0.56, 1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                left: -140,
                top: -170,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7BD7B0).withValues(alpha: 0.13),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -170,
                bottom: -190,
                child: Container(
                  width: 410,
                  height: 410,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2E8C68).withValues(alpha: 0.11),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _SignalFieldPainter(phase: ambient),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FormingIcon(
                          formation: formation,
                          iconLock: iconLock,
                          pulse: ambient,
                        ),
                        const SizedBox(height: 29),
                        Opacity(
                          opacity: brand,
                          child: Transform.translate(
                            offset: Offset(0, (1 - brand) * 12),
                            child: Column(
                              children: [
                                Text(
                                  'PLANT INTELLIGENCE',
                                  style: TextStyle(
                                    color: const Color(0xFFB9E7D4)
                                        .withValues(alpha: 0.68),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'PhytoSense AI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 33,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _QuoteReveal(
                          text: context.tr('splash_quote'),
                          progress: quote,
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: ready,
                          child: _LaunchSignal(phase: ambient),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormingIcon extends StatelessWidget {
  final double formation;
  final double iconLock;
  final double pulse;

  const _FormingIcon({
    required this.formation,
    required this.iconLock,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final shimmer = (math.sin(pulse * math.pi * 2) + 1) / 2;
    final iconOpacity = Curves.easeOutCubic.transform(iconLock);
    final iconScale = 0.90 + iconOpacity * 0.10;

    return SizedBox(
      width: 184,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(184),
            painter: _IconFormationPainter(
              progress: formation,
              pulse: pulse,
            ),
          ),
          Opacity(
            opacity: iconOpacity,
            child: Transform.scale(
              scale: iconScale,
              child: Container(
                width: 136,
                height: 136,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  border: Border.all(
                    color: const Color(0xFFB9E7D4).withValues(
                      alpha: 0.22 + shimmer * 0.18,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF72D4AA).withValues(
                        alpha: 0.12 + shimmer * 0.08,
                      ),
                      blurRadius: 34 + shimmer * 15,
                      spreadRadius: shimmer * 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: Image.asset(
                    'assets/branding/phytosense_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteReveal extends StatelessWidget {
  final String text;
  final double progress;

  const _QuoteReveal({required this.text, required this.progress});

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 8),
        child: Column(
          children: [
            SizedBox(
              width: 330,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: eased,
                  child: SizedBox(
                    width: 330,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 15.3,
                        height: 1.48,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: 36 + 64 * eased,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFB9E7D4).withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchSignal extends StatelessWidget {
  final double phase;

  const _LaunchSignal({required this.phase});

  @override
  Widget build(BuildContext context) {
    final wave = (math.sin(phase * math.pi * 2) + 1) / 2;
    return SizedBox(
      width: 104,
      height: 18,
      child: CustomPaint(
        painter: _LaunchSignalPainter(wave: wave),
      ),
    );
  }
}

class _IconFormationPainter extends CustomPainter {
  final double progress;
  final double pulse;

  const _IconFormationPainter({
    required this.progress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress);
    final settle = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0).toDouble());
    final glow = (math.sin(pulse * math.pi * 2) + 1) / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF9DDEC2).withValues(
        alpha: (0.10 + 0.18 * glow) * (1 - eased * 0.70),
      );
    canvas.drawCircle(center, 77 - eased * 8, ringPaint);

    final scanPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC7F1DF).withValues(
        alpha: 0.34 * (1 - eased * 0.75),
      );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 70),
      pulse * math.pi * 2,
      math.pi * 0.64,
      false,
      scanPaint,
    );

    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFBDEAD7);
    const count = 18;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + 0.32;
      final startRadius = 78.0 + (i % 3) * 12.0;
      final targetRadius = 48.0 + (i.isEven ? 4.0 : -3.0);
      final start = center + Offset(math.cos(angle), math.sin(angle)) * startRadius;
      final targetAngle = angle + math.sin(i * 1.7) * 0.18;
      final target = center +
          Offset(math.cos(targetAngle), math.sin(targetAngle)) * targetRadius;
      final delay = (i % 6) * 0.035;
      final local = ((progress - delay) / (1 - delay))
          .clamp(0.0, 1.0)
          .toDouble();
      final p = Curves.easeOutCubic.transform(local);
      final pos = Offset.lerp(start, target, p)!;
      final alpha = (0.18 + 0.70 * (1 - (p - 0.7).clamp(0.0, 0.3) / 0.3))
          .clamp(0.0, 1.0)
          .toDouble();
      particlePaint.color = const Color(0xFFBDEAD7).withValues(alpha: alpha);
      canvas.drawCircle(pos, 1.7 + (i % 3) * 0.45, particlePaint);
    }

    final frameOpacity = ((eased - 0.36) / 0.64).clamp(0.0, 1.0).toDouble();
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFB9E7D4).withValues(alpha: frameOpacity * 0.72);
    final half = 52.0 * settle.clamp(0.0, 1.08).toDouble();
    final rect = Rect.fromCenter(
      center: center,
      width: half * 2,
      height: half * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      framePaint,
    );

    final signalOpacity = ((eased - 0.46) / 0.54).clamp(0.0, 1.0).toDouble();
    final signalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD2F5E6).withValues(alpha: signalOpacity * 0.70);
    final path = Path()
      ..moveTo(center.dx - 31, center.dy + 7)
      ..cubicTo(
        center.dx - 22,
        center.dy - 13,
        center.dx - 10,
        center.dy + 27,
        center.dx,
        center.dy - 8,
      )
      ..cubicTo(
        center.dx + 9,
        center.dy - 30,
        center.dx + 17,
        center.dy + 20,
        center.dx + 32,
        center.dy - 3,
      );
    canvas.drawPath(path, signalPaint);
  }

  @override
  bool shouldRepaint(covariant _IconFormationPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}

class _SignalFieldPainter extends CustomPainter {
  final double phase;

  const _SignalFieldPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF9AD8BF).withValues(alpha: 0.055);
    final dotPaint = Paint()..style = PaintingStyle.fill;

    final points = <Offset>[];
    const columns = 5;
    const rows = 8;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final index = row * columns + col;
        final wave = math.sin(phase * math.pi * 2 + index * 0.71);
        final x = size.width * (0.08 + col * 0.21) + wave * 7;
        final y = size.height * (0.08 + row * 0.12) +
            math.cos(phase * math.pi * 2 + index) * 5;
        points.add(Offset(x, y));
      }
    }

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (i + 1 < points.length && (i + 1) % columns != 0) {
        canvas.drawLine(p, points[i + 1], linePaint);
      }
      if (i + columns < points.length) {
        canvas.drawLine(p, points[i + columns], linePaint);
      }
      final pulse = (math.sin(phase * math.pi * 2 + i * 0.9) + 1) / 2;
      dotPaint.color = const Color(0xFFB9E7D4)
          .withValues(alpha: 0.035 + pulse * 0.09);
      canvas.drawCircle(p, 1.2 + pulse * 1.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalFieldPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _LaunchSignalPainter extends CustomPainter {
  final double wave;

  const _LaunchSignalPainter({required this.wave});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.13);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      base,
    );

    final signal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB9E7D4).withValues(alpha: 0.78);
    final head = 18 + wave * (size.width - 36);
    final path = Path()
      ..moveTo(math.max(0.0, head - 24).toDouble(), size.height / 2)
      ..lineTo(head - 10, size.height / 2)
      ..lineTo(head - 5, size.height / 2 - 5)
      ..lineTo(head, size.height / 2 + 5)
      ..lineTo(head + 5, size.height / 2 - 3)
      ..lineTo(head + 10, size.height / 2)
      ..lineTo(math.min(size.width, head + 24).toDouble(), size.height / 2);
    canvas.drawPath(path, signal);
  }

  @override
  bool shouldRepaint(covariant _LaunchSignalPainter oldDelegate) =>
      oldDelegate.wave != wave;
}
