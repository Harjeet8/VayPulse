import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2250),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 2400), _openApp);
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final bg = dark ? const Color(0xFF09131B) : const Color(0xFFF8FAFD);
    final fg = dark ? const Color(0xFFF3F6FA) : const Color(0xFF17212A);
    final muted = dark ? const Color(0xFFAAB7C4) : const Color(0xFF687582);

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final p = reduced ? 1.0 : _controller.value;
          final intro = Curves.easeOutBack.transform((p / 0.48).clamp(0.0, 1.0));
          final text = Curves.easeOutCubic.transform(((p - .30) / .40).clamp(0.0, 1.0));
          final sweep = ((p - .12) / .68).clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.16),
                    radius: 1.0,
                    colors: dark
                        ? const [Color(0xFF132333), Color(0xFF09131B)]
                        : const [Colors.white, Color(0xFFF1F5FA)],
                  ),
                ),
              ),
              CustomPaint(painter: _BootSignalPainter(p, dark)),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: .78 + .22 * intro,
                        child: Opacity(
                          opacity: intro.clamp(0.0, 1.0),
                          child: SizedBox.square(
                            dimension: 184,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size.square(184),
                                  painter: _LogoPulsePainter(p),
                                ),
                                Container(
                                  width: 142,
                                  height: 142,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2388D8)
                                            .withValues(alpha: .12),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(34),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          'assets/branding/phytosense_icon.png',
                                          fit: BoxFit.cover,
                                          semanticLabel: 'PhytoSense AI logo',
                                        ),
                                        if (!reduced)
                                          Transform.translate(
                                            offset: Offset(-190 + 380 * sweep, 0),
                                            child: Transform.rotate(
                                              angle: -.22,
                                              child: Container(
                                                width: 34,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.white.withValues(alpha: .34),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: text,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - text)),
                          child: Column(
                            children: [
                              Text(
                                'PhytoSense AI',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'See stress before it becomes visible',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _LogoPulsePainter extends CustomPainter {
  final double p;
  const _LogoPulsePainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const colors = [Color(0xFF2388D8), Color(0xFF18A765), Color(0xFFFFB21A)];
    for (var i = 0; i < colors.length; i++) {
      final q = (p + i * .24) % 1.0;
      canvas.drawCircle(
        c,
        72 + 18 * q,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = colors[i].withValues(alpha: (1 - q) * .25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPulsePainter old) => old.p != p;
}

class _BootSignalPainter extends CustomPainter {
  final double p;
  final bool dark;
  const _BootSignalPainter(this.p, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .43);
    final pulse = (math.sin(p * math.pi * 5) + 1) / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final y = c.dy + 126;
    final path = Path()..moveTo(c.dx - 90, y);
    path
      ..lineTo(c.dx - 35, y)
      ..lineTo(c.dx - 22, y - 8 * pulse)
      ..lineTo(c.dx - 10, y + 12 * pulse)
      ..lineTo(c.dx + 5, y - 18 * pulse)
      ..lineTo(c.dx + 22, y)
      ..lineTo(c.dx + 90, y);
    paint
      ..strokeWidth = 2
      ..color = const Color(0xFF2388D8).withValues(alpha: .20 + .20 * pulse);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BootSignalPainter old) => old.p != p || old.dark != dark;
}
