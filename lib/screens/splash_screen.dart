import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shell_screen.dart';

/// Complete PhytoSense startup sequence. Initialization and motion run
/// together, preventing a flash between unrelated loading screens.
class SplashScreen extends StatefulWidget {
  final Future<void>? initialization;

  const SplashScreen({super.key, this.initialization});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sequence;
  late final AnimationController _ambient;
  Timer? _reducedMotionHold;
  bool _started = false;
  bool _reducedMotion = false;
  bool _initializationDone = false;
  bool _sequenceDone = false;
  bool _navigating = false;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _sequence = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _sequenceDone = true;
          _openWhenReady();
        }
      });
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    unawaited(_waitForInitialization());
  }

  Future<void> _waitForInitialization() async {
    try {
      await (widget.initialization ?? Future<void>.value());
      if (!mounted) return;
      _initializationDone = true;
      _openWhenReady();
    } catch (error) {
      if (!mounted) return;
      _ambient.stop();
      setState(() => _startupError = error);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      // Reduced motion still presents the complete branded boot instead of
      // skipping directly from Android's launch window to Home.
      _sequence.value = 0.999;
      _reducedMotionHold = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _sequenceDone = true;
        _openWhenReady();
      });
    } else {
      _ambient.repeat();
      _sequence.forward();
    }
  }

  void _openWhenReady() {
    if (!_initializationDone || !_sequenceDone || _navigating || !mounted) {
      return;
    }
    _navigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder<void>(
          transitionDuration: _reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 520),
          pageBuilder: (_, __, ___) => const ShellScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.992, end: 1).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    });
  }

  double _segment(double progress, double begin, double end) {
    if (progress <= begin) return 0;
    if (progress >= end) return 1;
    return ((progress - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
  }

  @override
  void dispose() {
    _reducedMotionHold?.cancel();
    _sequence.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) return const _StartupErrorView();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF04120E) : const Color(0xFFF3F8F5);
    final systemStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: background,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemStyle,
      child: Scaffold(
        backgroundColor: background,
        body: AnimatedBuilder(
          animation: Listenable.merge([_sequence, _ambient]),
          builder: (context, _) {
            final progress = _reducedMotion ? 1.0 : _sequence.value;
            final phase = _reducedMotion ? 0.18 : _ambient.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF102A20),
                          Color(0xFF04120E),
                        ]
                      : const [
                          Color(0xFFEEF8F2),
                          Color(0xFFF3F8F5),
                        ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 76, 24, 126),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 196,
                              width: double.infinity,
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                Positioned.fill(
                                    child: IgnorePointer(
                                        child: _LivingBootIcons(
                                  progress: progress,
                                  phase: phase,
                                  dark: isDark,
                                  reducedMotion: _reducedMotion,
                                ))),
                                _AnimatedLogo(
                                    progress: progress,
                                    phase: phase,
                                    reducedMotion: _reducedMotion,
                                    dark: isDark),
                              ]),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                                width: 112,
                                height: 54,
                                child: CustomPaint(
                                    painter: _GrowingSproutPainter(
                                  progress: _reducedMotion
                                      ? 1
                                      : _segment(progress, .15, .8),
                                  color: isDark
                                      ? const Color(0xFFBFD995)
                                      : const Color(0xFF4C765F),
                                ))),
                            const SizedBox(height: 16),
                            _BootCopy(
                              progress: progress,
                              segment: _segment,
                              dark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LivingBootIcons extends StatelessWidget {
  final double progress;
  final double phase;
  final bool dark;
  final bool reducedMotion;

  const _LivingBootIcons({
    required this.progress,
    required this.phase,
    required this.dark,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    final reveal = Curves.easeOutCubic.transform(
      ((progress - 0.12) / 0.62).clamp(0.0, 1.0).toDouble(),
    );
    final color = dark ? const Color(0xFF9EE9C8) : const Color(0xFF1D684D);
    final icons = <(IconData, Alignment, double)>[
      (Icons.water_drop_outlined, const Alignment(-0.98, -0.70), 0.0),
      (Icons.wb_sunny_outlined, const Alignment(0.98, -0.70), 0.21),
      (Icons.air_rounded, const Alignment(-0.98, 0.70), 0.42),
      (Icons.sensors_rounded, const Alignment(0.98, 0.70), 0.63),
    ];
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 330,
          height: 390,
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final item in icons)
                Align(
                  alignment: item.$2,
                  child: Opacity(
                    opacity: reveal * 0.72,
                    child: Transform.translate(
                      offset: reducedMotion
                          ? Offset.zero
                          : Offset(
                              math.sin((phase + item.$3) * math.pi * 2) * 3,
                              math.cos((phase + item.$3) * math.pi * 2) * 5,
                            ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: dark ? 0.08 : 0.07),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(item.$1, color: color, size: 22),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  final double progress;
  final double phase;
  final bool reducedMotion;
  final bool dark;

  const _AnimatedLogo({
    required this.progress,
    required this.phase,
    required this.reducedMotion,
    required this.dark,
  });

  double _segment(double begin, double end) {
    if (progress <= begin) return 0;
    if (progress >= end) return 1;
    return ((progress - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final accent = dark ? const Color(0xFF9EE9C8) : const Color(0xFF176B4D);
    final glow = dark ? const Color(0xFF4BE39B) : const Color(0xFF31A36F);
    final reveal = Curves.easeOutBack.transform(_segment(0.05, 0.40));
    final lock = Curves.easeOutCubic.transform(_segment(0.67, 0.92));
    final breathe = reducedMotion ? 0.0 : math.sin(phase * math.pi * 2);
    final scale = (0.58 + reveal * 0.42) * (1 + breathe * 0.014);
    final angle = (1 - reveal) * -0.12 + breathe * 0.008;
    final lift = (1 - reveal) * 54 + breathe * 2.1;
    final sheen = Curves.easeInOutCubic.transform(_segment(0.22, 0.74));
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;

    return Semantics(
      image: true,
      label: 'PhytoSense AI logo',
      child: SizedBox(
        width: 196,
        height: 196,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170 + pulse * 3,
              height: 170 + pulse * 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.075 + lock * 0.025),
              ),
            ),
            Transform.translate(
              offset: Offset(0, lift),
              child: Transform.rotate(
                angle: angle,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(42),
                      boxShadow: [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.10 + lock * 0.06),
                          blurRadius: 28 + lock * 8,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.24 : 0.13,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 13),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      key: const Key('boot-logo-clip'),
                      borderRadius: BorderRadius.circular(42),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/branding/phytosense_icon.png',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true,
                          ),
                          if (!reducedMotion)
                            Transform.translate(
                              offset: Offset(-176 + sheen * 310, 0),
                              child: Transform.rotate(
                                angle: -0.28,
                                child: Container(
                                  width: 34,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.34),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootCopy extends StatelessWidget {
  final double progress;
  final double Function(double, double, double) segment;
  final bool dark;

  const _BootCopy({
    required this.progress,
    required this.segment,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? const Color(0xFFF4FFF9) : const Color(0xFF14251E);
    final secondary = dark ? Colors.white : const Color(0xFF4C6256);
    final accent = dark ? const Color(0xFF9EE9C8) : const Color(0xFF176B4D);
    final brand = Curves.easeOutCubic.transform(segment(progress, 0.27, 0.55));
    final quote = Curves.easeOutCubic.transform(segment(progress, 0.42, 0.72));
    final ready = Curves.easeOutCubic.transform(segment(progress, 0.76, 0.98));
    return Column(
      children: [
        Transform.translate(
          offset: Offset(0, (1 - brand) * 12),
          child: Opacity(
            opacity: brand,
            child: Text(
              'PhytoSense AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.05,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Transform.translate(
          offset: Offset(0, (1 - quote) * 9),
          child: Opacity(
            opacity: quote,
            child: Text(
              'For the Betterment of Farmers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondary.withValues(alpha: dark ? 0.68 : 0.78),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.08,
              ),
            ),
          ),
        ),
        const SizedBox(height: 17),
        Opacity(
          opacity: ready,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: accent.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              'PLANT CARE, MADE CLEAR',
              style: TextStyle(
                color: dark ? const Color(0xFFBFEFDB) : const Color(0xFF176B4D),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Card(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 46),
                      SizedBox(height: 14),
                      Text(
                        'PhytoSense AI could not start',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Close and reopen the app. Your locally saved records remain safe.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _GrowingSproutPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _GrowingSproutPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final stem = Path()
      ..moveTo(x, size.height - 5)
      ..cubicTo(x - 3, 36, x + 4, 23, x, 9);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final length = stem.computeMetrics().first;
    canvas.drawPath(length.extractPath(0, length.length * progress), paint);
    final grow = ((progress - .32) / .68).clamp(0.0, 1.0).toDouble();
    if (grow <= 0) {
      return;
    }
    paint.style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(x, 27);
    canvas.scale(grow);
    canvas.drawPath(
        Path()
          ..moveTo(0, 5)
          ..cubicTo(-21, 4, -24, -5, -25, -15)
          ..cubicTo(-10, -16, -1, -7, 0, 5)
          ..close(),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(1, -5)
          ..cubicTo(1, -19, 12, -22, 23, -22)
          ..cubicTo(22, -9, 13, -5, 1, -5)
          ..close(),
        paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GrowingSproutPainter old) =>
      old.progress != progress || old.color != color;
}
