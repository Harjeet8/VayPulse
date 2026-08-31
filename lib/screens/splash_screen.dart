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
      duration: const Duration(milliseconds: 4100),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 4550), _openApp);
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 680),
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final eased = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.988, end: 1).animate(eased),
              child: child,
            ),
          );
        },
      ),
    );
  }

  double _segment(double value, double begin, double end) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return ((value - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sequence.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = _BootPalette.forBrightness(dark);

    return Scaffold(
      backgroundColor: palette.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_sequence, _ambient]),
        builder: (context, _) {
          final timeline = reduceMotion ? 1.0 : _sequence.value;
          final phase = reduceMotion ? 0.35 : _ambient.value;
          final field = _segment(timeline, 0.00, 0.34);
          final mark = _segment(timeline, 0.12, 0.56);
          final brand = _segment(timeline, 0.42, 0.70);
          final status = _segment(timeline, 0.60, 0.82);
          final quote = _segment(timeline, 0.70, 0.94);
          final ready = _segment(timeline, 0.88, 1.00);

          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette.backgroundGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _AmbientBrandPainter(
                    phase: phase,
                    reveal: field,
                    palette: palette,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      _HeroMark(
                        reveal: mark,
                        phase: phase,
                        palette: palette,
                      ),
                      const SizedBox(height: 30),
                      _BrandLockup(progress: brand, palette: palette),
                      const SizedBox(height: 25),
                      _SignalRail(progress: status, palette: palette),
                      const SizedBox(height: 24),
                      _QuoteReveal(
                        text: context.tr('splash_quote'),
                        progress: quote,
                        palette: palette,
                      ),
                      const Spacer(flex: 2),
                      _ReadyPulse(
                        progress: ready,
                        phase: phase,
                        palette: palette,
                      ),
                      const SizedBox(height: 34),
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

class _BootPalette {
  final bool dark;
  final Color background;
  final List<Color> backgroundGradient;
  final Color foreground;
  final Color secondary;
  final Color faint;
  final Color cardBorder;
  final Color blue;
  final Color green;
  final Color lime;
  final Color yellow;
  final Color red;

  const _BootPalette({
    required this.dark,
    required this.background,
    required this.backgroundGradient,
    required this.foreground,
    required this.secondary,
    required this.faint,
    required this.cardBorder,
    required this.blue,
    required this.green,
    required this.lime,
    required this.yellow,
    required this.red,
  });

  factory _BootPalette.forBrightness(bool dark) {
    if (dark) {
      return const _BootPalette(
        dark: true,
        background: Color(0xFF07131B),
        backgroundGradient: [
          Color(0xFF07131B),
          Color(0xFF0B1B22),
          Color(0xFF0E2820),
        ],
        foreground: Color(0xFFF7FBFF),
        secondary: Color(0xFFB9CCD5),
        faint: Color(0xFF5D747E),
        cardBorder: Color(0x2EFFFFFF),
        blue: Color(0xFF1688F2),
        green: Color(0xFF12C46C),
        lime: Color(0xFFA8E819),
        yellow: Color(0xFFFFC20A),
        red: Color(0xFFFF4538),
      );
    }
    return const _BootPalette(
      dark: false,
      background: Color(0xFFF9FBFF),
      backgroundGradient: [
        Color(0xFFFDFEFF),
        Color(0xFFF4FAFF),
        Color(0xFFF1FBF5),
      ],
      foreground: Color(0xFF172B34),
      secondary: Color(0xFF526A74),
      faint: Color(0xFF9BB0B8),
      cardBorder: Color(0x160E3A4A),
      blue: Color(0xFF1688F2),
      green: Color(0xFF08B962),
      lime: Color(0xFFA4DF15),
      yellow: Color(0xFFFFBE00),
      red: Color(0xFFFF4436),
    );
  }
}

class _HeroMark extends StatelessWidget {
  final double reveal;
  final double phase;
  final _BootPalette palette;

  const _HeroMark({
    required this.reveal,
    required this.phase,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutBack.transform(reveal.clamp(0.0, 1.0).toDouble());
    final breathe = (math.sin(phase * math.pi * 2) + 1) / 2;
    return SizedBox(
      width: 214,
      height: 214,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(214),
            painter: _BrandOrbitPainter(
              progress: reveal,
              phase: phase,
              palette: palette,
            ),
          ),
          Opacity(
            opacity: reveal.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: 0.90 + 0.10 * eased,
              child: Container(
                width: 142,
                height: 142,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(37),
                  border: Border.all(color: palette.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: palette.blue.withValues(
                        alpha: (palette.dark ? 0.13 : 0.07) + breathe * 0.03,
                      ),
                      blurRadius: 36 + breathe * 12,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: palette.green.withValues(
                        alpha: (palette.dark ? 0.14 : 0.06) + breathe * 0.04,
                      ),
                      blurRadius: 44 + breathe * 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
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

class _BrandLockup extends StatelessWidget {
  final double progress;
  final _BootPalette palette;

  const _BrandLockup({required this.progress, required this.palette});

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 11),
        child: Column(
          children: [
            Text(
              'PLANT INTELLIGENCE',
              style: TextStyle(
                color: palette.secondary.withValues(alpha: 0.82),
                fontSize: 10.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.15,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'PhytoSense AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.foreground,
                fontSize: 34,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalRail extends StatelessWidget {
  final double progress;
  final _BootPalette palette;

  const _SignalRail({required this.progress, required this.palette});

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);
    final items = [
      ('BIO', palette.blue),
      ('ROOT', palette.green),
      ('CLIMATE', palette.yellow),
      ('FUSION', palette.red),
    ];

    return Opacity(
      opacity: eased,
      child: Transform.scale(
        scale: 0.97 + eased * 0.03,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: palette.foreground.withValues(alpha: palette.dark ? 0.055 : 0.035),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: palette.foreground.withValues(alpha: palette.dark ? 0.11 : 0.07),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 13),
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    color: items[i].$2,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: items[i].$2.withValues(alpha: 0.30),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  items[i].$1,
                  style: TextStyle(
                    color: palette.secondary,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.75,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteReveal extends StatelessWidget {
  final String text;
  final double progress;
  final _BootPalette palette;

  const _QuoteReveal({
    required this.text,
    required this.progress,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 8),
        child: SizedBox(
          width: 330,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.secondary.withValues(alpha: palette.dark ? 0.91 : 0.88),
              fontSize: 14.8,
              height: 1.48,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.02,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyPulse extends StatelessWidget {
  final double progress;
  final double phase;
  final _BootPalette palette;

  const _ReadyPulse({
    required this.progress,
    required this.phase,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final wave = (math.sin(phase * math.pi * 2) + 1) / 2;
    return Opacity(
      opacity: progress,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: palette.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: palette.green.withValues(alpha: 0.25 + wave * 0.35),
                  blurRadius: 9 + wave * 5,
                  spreadRadius: wave,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'SENSING READY',
            style: TextStyle(
              color: palette.faint,
              fontSize: 9.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            height: 14,
            child: CustomPaint(
              painter: _MiniPulsePainter(
                phase: phase,
                color: palette.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandOrbitPainter extends CustomPainter {
  final double progress;
  final double phase;
  final _BootPalette palette;

  const _BrandOrbitPainter({
    required this.progress,
    required this.phase,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final p = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0).toDouble());
    final wave = (math.sin(phase * math.pi * 2) + 1) / 2;

    void arc(double radius, double start, double sweep, Color color, double width) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color.withValues(alpha: 0.18 + p * 0.62);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * p,
        false,
        paint,
      );
    }

    arc(92, math.pi * 1.02, math.pi * 0.74, palette.blue, 4.4);
    arc(82, math.pi * 1.06, math.pi * 0.60, palette.yellow, 3.6);
    arc(72, math.pi * 1.10, math.pi * 0.44, palette.red, 3.0);

    final scan = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..color = palette.green.withValues(alpha: 0.14 + wave * 0.16);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 101),
      phase * math.pi * 2,
      math.pi * 0.55,
      false,
      scan,
    );

    final tick = Paint()
      ..strokeWidth = 1
      ..color = palette.foreground.withValues(alpha: palette.dark ? 0.11 : 0.07);
    for (var i = 0; i < 28; i++) {
      final angle = (i / 28) * math.pi * 2;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * 105;
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * 102;
      canvas.drawLine(inner, outer, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _BrandOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.palette != palette;
}

class _AmbientBrandPainter extends CustomPainter {
  final double phase;
  final double reveal;
  final _BootPalette palette;

  const _AmbientBrandPainter({
    required this.phase,
    required this.reveal,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Curves.easeOutCubic.transform(reveal.clamp(0.0, 1.0).toDouble());
    final wave = (math.sin(phase * math.pi * 2) + 1) / 2;

    final glowBlue = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.blue.withValues(alpha: (palette.dark ? 0.10 : 0.075) * p),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.16, size.height * 0.18),
        radius: size.width * 0.58,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.18),
      size.width * 0.58,
      glowBlue,
    );

    final glowGreen = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.green.withValues(alpha: (palette.dark ? 0.10 : 0.065) * p),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.88, size.height * 0.78),
        radius: size.width * 0.64,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.78),
      size.width * 0.64,
      glowGreen,
    );

    final grid = Paint()
      ..strokeWidth = 0.7
      ..color = palette.foreground.withValues(alpha: (palette.dark ? 0.035 : 0.025) * p);
    const gap = 44.0;
    for (double y = 12; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (double x = 10; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    final signalY = size.height * 0.72;
    final signal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = palette.blue.withValues(alpha: (0.08 + wave * 0.07) * p);
    final path = Path()..moveTo(0, signalY);
    for (double x = 0; x <= size.width; x += 5) {
      final normalized = x / size.width;
      final pulseCenter = (phase * 0.9 + 0.08) % 1.0;
      final distance = (normalized - pulseCenter).abs();
      final envelope = math.exp(-distance * distance * 190);
      final y = signalY + math.sin(normalized * math.pi * 18) * 1.2 +
          math.sin(normalized * math.pi * 5) * envelope * 17;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, signal);
  }

  @override
  bool shouldRepaint(covariant _AmbientBrandPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.reveal != reveal ||
      oldDelegate.palette != palette;
}

class _MiniPulsePainter extends CustomPainter {
  final double phase;
  final Color color;

  const _MiniPulsePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.72);
    final y = size.height / 2;
    final path = Path()
      ..moveTo(0, y)
      ..lineTo(size.width * 0.25, y)
      ..lineTo(size.width * 0.36, y - 3)
      ..lineTo(size.width * 0.47, y + 5)
      ..lineTo(size.width * 0.58, y - 6)
      ..lineTo(size.width * 0.69, y)
      ..lineTo(size.width, y);
    canvas.drawPath(path, paint);

    final dotX = (phase * size.width).clamp(0.0, size.width).toDouble();
    canvas.drawCircle(
      Offset(dotX, y),
      1.7,
      Paint()..color = color.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniPulsePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}
