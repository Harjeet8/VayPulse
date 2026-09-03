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
  late final Animation<double> _logoTurn;
  late final Animation<double> _logoLift;
  late final Animation<double> _contentOpacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 28,
      ),
    ]).animate(_controller);
    _logoTurn = Tween<double>(begin: -0.055, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoLift = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.86, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1650), _openApp);
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
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
    final background =
        dark ? const Color(0xFF071611) : const Color(0xFFF7FBF8);
    final foreground =
        dark ? const Color(0xFFF1FBF5) : const Color(0xFF102D25);
    final secondary =
        dark ? const Color(0xFFAFC8BD) : const Color(0xFF587066);

    return Scaffold(
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 0.88,
            colors: dark
                ? const [Color(0xFF123126), Color(0xFF071611)]
                : const [Color(0xFFE7F6EE), Color(0xFFF9FCFA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: reducedMotion
                  ? const AlwaysStoppedAnimation<double>(1)
                  : _contentOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 124,
                    height: 124,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF10251B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: dark
                            ? const Color(0xFF2B4B3D)
                            : const Color(0xFFDDEBE3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.22 : 0.07,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedBuilder(
                        animation: _controller,
                        child: Image.asset(
                          'assets/branding/phytosense_icon.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'PhytoSense AI logo',
                        ),
                        builder: (context, child) {
                          if (reducedMotion) return child!;
                          return Transform.translate(
                            offset: Offset(0, _logoLift.value),
                            child: Transform.rotate(
                              angle: _logoTurn.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'PhytoSense AI',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'See stress before it becomes visible',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 112,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: reducedMotion ? 1 : _controller.value,
                          color: theme.colorScheme.primary,
                          backgroundColor: dark
                              ? const Color(0xFF29483C)
                              : const Color(0xFFD7E8DF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
