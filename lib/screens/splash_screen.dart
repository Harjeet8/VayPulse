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
  late final AnimationController _intro;
  late final AnimationController _ambient;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 2650), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 520),
          pageBuilder: (_, animation, __) => const ShellScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Animation<double> _phase(double begin, double end) => CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final iconOpacity = _phase(0, 0.48);
    final titleOpacity = _phase(0.32, 0.73);
    final quoteOpacity = _phase(0.58, 1);

    return Scaffold(
      backgroundColor: const Color(0xFF06130E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF06130E),
                  Color(0xFF0A251B),
                  Color(0xFF0D3325),
                ],
                stops: [0, 0.56, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            left: -120,
            top: -150,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF5FB995).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ambient,
            builder: (_, __) => CustomPaint(
              painter: _AmbientFieldPainter(
                phase: reduceMotion ? 0.42 : _ambient.value,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: iconOpacity,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.78, end: 1).animate(
                          CurvedAnimation(
                            parent: _intro,
                            curve: const Interval(
                              0,
                              0.56,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: _ambient,
                          builder: (_, child) {
                            final wave = reduceMotion
                                ? 0.5
                                : (math.sin(_ambient.value * math.pi * 2) +
                                        1) /
                                    2;
                            return Container(
                              width: 142,
                              height: 142,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(43),
                                border: Border.all(
                                  color: const Color(0xFFAFDFCC).withValues(
                                    alpha: 0.18 + wave * 0.16,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF80C8AB).withValues(
                                      alpha: 0.10 + wave * 0.08,
                                    ),
                                    blurRadius: 38 + wave * 14,
                                    spreadRadius: wave * 2,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Image.asset(
                              'assets/branding/phytosense_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: titleOpacity,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.22),
                          end: Offset.zero,
                        ).animate(titleOpacity),
                        child: const Text(
                          'PhytoSense AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: quoteOpacity,
                      child: Text(
                        context.tr('splash_quote'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    FadeTransition(
                      opacity: quoteOpacity,
                      child: AnimatedBuilder(
                        animation: _ambient,
                        builder: (_, __) => _SignalProgress(
                          phase: reduceMotion ? 0.65 : _ambient.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalProgress extends StatelessWidget {
  final double phase;

  const _SignalProgress({required this.phase});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 76,
        height: 5,
        child: Row(
          children: List.generate(3, (index) {
            final distance = ((phase * 3 - index) % 3).abs();
            final active = (1 - distance.clamp(0.0, 1.0)).toDouble();
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Colors.white.withValues(alpha: 0.16),
                    const Color(0xFFB9E7D4),
                    active,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
      );
}

class _AmbientFieldPainter extends CustomPainter {
  final double phase;

  const _AmbientFieldPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 62);
    for (var index = 0; index < 3; index++) {
      final progress = (phase + index / 3) % 1;
      final radius = 105 + progress * 150;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF8FD2B6)
              .withValues(alpha: (1 - progress) * 0.055)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientFieldPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
