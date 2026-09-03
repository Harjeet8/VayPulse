import 'dart:async';

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
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    _logoScale = Tween<double>(begin: 0.90, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.78, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2150), _openApp);
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
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
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final background = dark ? const Color(0xFF071813) : const Color(0xFFF5FBF8);
    final foreground = dark ? const Color(0xFFF2FFF8) : const Color(0xFF102D25);
    final secondary = dark ? const Color(0xFFAFC8BD) : const Color(0xFF587066);
    final grid = dark ? const Color(0x0EFFFFFF) : const Color(0x0B0C6A4C);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.14),
                radius: 0.82,
                colors: dark
                    ? const [Color(0xFF103A2B), Color(0xFF071813)]
                    : const [Color(0xFFE2F7ED), Color(0xFFF8FCFA)],
              ),
            ),
          ),
          CustomPaint(painter: _QuietGridPainter(grid)),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: reducedMotion
                    ? const AlwaysStoppedAnimation<double>(1)
                    : _contentOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: reducedMotion
                          ? const AlwaysStoppedAnimation<double>(1)
                          : _logoScale,
                      child: Container(
                        width: 154,
                        height: 154,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF13B96B)
                                  .withValues(alpha: dark ? 0.22 : 0.16),
                              blurRadius: 34,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            'assets/branding/phytosense_icon.png',
                            fit: BoxFit.cover,
                            semanticLabel: 'PhytoSense logo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'PhytoSense AI',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'See stress before it becomes visible',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: 112,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: reducedMotion ? 1 : null,
                          color: const Color(0xFF13B96B),
                          backgroundColor: dark
                              ? const Color(0xFF29483C)
                              : const Color(0xFFD5E9E0),
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

class _QuietGridPainter extends CustomPainter {
  final Color color;

  const _QuietGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const gap = 72.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuietGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
