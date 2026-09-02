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
  late final AnimationController _timeline;
  late final AnimationController _ambient;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4100),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 4450), _openApp);
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 620),
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final eased = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.976, end: 1).animate(eased),
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
    _timeline.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = _BootPalette.fromBrightness(dark);

    return Scaffold(
      backgroundColor: palette.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_timeline, _ambient]),
        builder: (context, _) {
          final t = reducedMotion ? 1.0 : _timeline.value;
          final phase = reducedMotion ? 0.22 : _ambient.value;

          final field = _segment(t, 0.00, 0.22);
          final scan = _segment(t, 0.03, 0.34);
          final core = _segment(t, 0.10, 0.43);
          final brand = _segment(t, 0.29, 0.57);
          final intelligence = _segment(t, 0.46, 0.70);
          final quote = _segment(t, 0.58, 0.82);
          final ready = _segment(t, 0.76, 0.96);

          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.gradient,
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _CinematicFieldPainter(
                    reveal: field,
                    scan: scan,
                    phase: phase,
                    palette: palette,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      _TopSignalStrip(progress: scan, palette: palette),
                      const Spacer(),
                      _FusionCore(
                        progress: core,
                        phase: phase,
                        palette: palette,
                      ),
                      const SizedBox(height: 22),
                      _BrandReveal(progress: brand, palette: palette),
                      const SizedBox(height: 18),
                      _IntelligenceRail(
                        progress: intelligence,
                        phase: phase,
                        palette: palette,
                      ),
                      const SizedBox(height: 18),
                      _Quote(
                        progress: quote,
                        text: context.tr('splash_quote'),
                        palette: palette,
                      ),
                      const Spacer(),
                      _ReadyFooter(
                        progress: ready,
                        phase: phase,
                        palette: palette,
                      ),
                      const SizedBox(height: 24),
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
  final Color background;
  final List<Color> gradient;
  final Color foreground;
  final Color secondary;
  final Color faint;
  final Color panel;
  final Color border;
  final Color blue;
  final Color green;
  final Color lime;
  final Color yellow;
  final Color red;
  final bool dark;

  const _BootPalette({
    required this.background,
    required this.gradient,
    required this.foreground,
    required this.secondary,
    required this.faint,
    required this.panel,
    required this.border,
    required this.blue,
    required this.green,
    required this.lime,
    required this.yellow,
    required this.red,
    required this.dark,
  });

  factory _BootPalette.fromBrightness(bool dark) {
    if (dark) {
      return const _BootPalette(
        background: Color(0xFF061017),
        gradient: [Color(0xFF061017), Color(0xFF0A1D25), Color(0xFF0C271D)],
        foreground: Color(0xFFF7FCFF),
        secondary: Color(0xFFC1D3DC),
        faint: Color(0xFF71868F),
        panel: Color(0x18FFFFFF),
        border: Color(0x30FFFFFF),
        blue: Color(0xFF2196F3),
        green: Color(0xFF16C96B),
        lime: Color(0xFF9EEA1A),
        yellow: Color(0xFFFFC107),
        red: Color(0xFFF44336),
        dark: true,
      );
    }
    return const _BootPalette(
      background: Color(0xFFFCFEFF),
      gradient: [Color(0xFFFFFFFF), Color(0xFFF1F8FF), Color(0xFFF2FBF5)],
      foreground: Color(0xFF132D36),
      secondary: Color(0xFF516A74),
      faint: Color(0xFF94A8B0),
      panel: Color(0xCFFFFFFF),
      border: Color(0x180E3A4A),
      blue: Color(0xFF1976D2),
      green: Color(0xFF0EBA61),
      lime: Color(0xFF8ED316),
      yellow: Color(0xFFF6B800),
      red: Color(0xFFE94235),
      dark: false,
    );
  }
}

class _TopSignalStrip extends StatelessWidget {
  final double progress;
  final _BootPalette palette;

  const _TopSignalStrip({required this.progress, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeOutCubic.transform(progress);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, -8 * (1 - p)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PHYTOSENSE // PLANT INTELLIGENCE',
              style: TextStyle(
                color: palette.secondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: palette.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.green.withValues(alpha: 0.38),
                        blurRadius: 9,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'CORE STARTING',
                  style: TextStyle(
                    color: palette.faint,
                    fontSize: 8.4,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FusionCore extends StatelessWidget {
  final double progress;
  final double phase;
  final _BootPalette palette;

  const _FusionCore({
    required this.progress,
    required this.phase,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0).toDouble());
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;

    return SizedBox(
      width: 254,
      height: 254,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(254),
            painter: _FusionOrbitPainter(
              progress: progress,
              phase: phase,
              palette: palette,
            ),
          ),
          Opacity(
            opacity: progress.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: 0.80 + (0.20 * p),
              child: Container(
                width: 144,
                height: 144,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.blue,
                      palette.green,
                      palette.lime,
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                  borderRadius: BorderRadius.circular(39),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.blue.withValues(alpha: 0.10 + pulse * 0.04),
                      blurRadius: 38 + pulse * 10,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: palette.green.withValues(alpha: 0.12 + pulse * 0.05),
                      blurRadius: 50 + pulse * 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _PhytoSenseMarkPainter(
                    progress: progress,
                    phase: phase,
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

class _BrandReveal extends StatelessWidget {
  final double progress;
  final _BootPalette palette;

  const _BrandReveal({required this.progress, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeOutCubic.transform(progress);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - p)),
        child: Column(
          children: [
            Text(
              'PhytoSense AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.foreground,
                fontSize: 37,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.65,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'SEE STRESS BEFORE IT BECOMES VISIBLE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.secondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntelligenceRail extends StatelessWidget {
  final double progress;
  final double phase;
  final _BootPalette palette;

  const _IntelligenceRail({
    required this.progress,
    required this.phase,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeOutCubic.transform(progress);
    final items = [
      ('BIO', palette.blue),
      ('ROOT', palette.green),
      ('CLIMATE', palette.yellow),
      ('FUSION', palette.red),
    ];

    return Opacity(
      opacity: p,
      child: Transform.scale(
        scale: 0.95 + 0.05 * p,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
            boxShadow: palette.dark
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                _SignalPillDot(
                  color: items[i].$2,
                  phase: (phase + i * 0.18) % 1.0,
                ),
                const SizedBox(width: 5),
                Text(
                  items[i].$1,
                  style: TextStyle(
                    color: palette.secondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
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

class _SignalPillDot extends StatelessWidget {
  final Color color;
  final double phase;

  const _SignalPillDot({required this.color, required this.phase});

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20 + pulse * 0.28),
            blurRadius: 5 + pulse * 4,
          ),
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  final double progress;
  final String text;
  final _BootPalette palette;

  const _Quote({
    required this.progress,
    required this.text,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeOutCubic.transform(progress);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - p)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.secondary,
              fontSize: 14.5,
              height: 1.48,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyFooter extends StatelessWidget {
  final double progress;
  final double phase;
  final _BootPalette palette;

  const _ReadyFooter({
    required this.progress,
    required this.phase,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final wave = (math.sin(phase * math.pi * 2) + 1) / 2;
    return Opacity(
      opacity: progress,
      child: Column(
        children: [
          SizedBox(
            width: 210,
            height: 24,
            child: CustomPaint(
              painter: _PulseLinePainter(
                phase: phase,
                progress: progress,
                color: palette.blue,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
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
                      blurRadius: 8 + wave * 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'PLANT INTELLIGENCE READY',
                style: TextStyle(
                  color: palette.faint,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhytoSenseMarkPainter extends CustomPainter {
  final double progress;
  final double phase;

  const _PhytoSenseMarkPainter({
    required this.progress,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;

    final leaf = Path()
      ..moveTo(size.width * 0.49, size.height * 0.82)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.68,
        size.width * 0.20,
        size.height * 0.29,
        size.width * 0.52,
        size.height * 0.15,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.25,
        size.width * 0.86,
        size.height * 0.55,
        size.width * 0.49,
        size.height * 0.82,
      )
      ..close();

    final leafPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * p)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leaf, leafPaint);

    final vein = Path()
      ..moveTo(size.width * 0.43, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.53,
        size.width * 0.67,
        size.height * 0.31,
      );
    canvas.drawPath(
      vein,
      Paint()
        ..color = const Color(0xFF0A7D58).withValues(alpha: 0.72 * p)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    final signal = Path()
      ..moveTo(size.width * 0.10, size.height * 0.57)
      ..lineTo(size.width * 0.29, size.height * 0.57)
      ..lineTo(size.width * 0.37, size.height * 0.43)
      ..lineTo(size.width * 0.46, size.height * 0.70)
      ..lineTo(size.width * 0.56, size.height * 0.37)
      ..lineTo(size.width * 0.65, size.height * 0.57)
      ..lineTo(size.width * 0.90, size.height * 0.57);
    canvas.drawPath(
      signal,
      Paint()
        ..color = Colors.white.withValues(alpha: (0.78 + pulse * 0.22) * p)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    final nodePaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.70 + pulse * 0.30) * p);
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.57),
      4 + pulse * 1.5,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PhytoSenseMarkPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.phase != phase;
}

class _FusionOrbitPainter extends CustomPainter {
  final double progress;
  final double phase;
  final _BootPalette palette;

  const _FusionOrbitPainter({
    required this.progress,
    required this.phase,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final p = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0).toDouble());
    final rotation = phase * math.pi * 2;

    void arc(double radius, double start, double sweep, Color color, double width) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color.withValues(alpha: 0.18 + 0.62 * p);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + rotation,
        sweep * p,
        false,
        paint,
      );
    }

    arc(111, -2.7, 0.98, palette.blue, 3.0);
    arc(111, -1.25, 0.78, palette.green, 3.0);
    arc(98, 0.35, 0.62, palette.yellow, 2.4);
    arc(98, 1.45, 0.50, palette.red, 2.4);
    arc(119, 2.55, 0.48, palette.lime, 2.1);

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final colors = [palette.blue, palette.green, palette.yellow, palette.red];
    for (var i = 0; i < 4; i++) {
      final angle = rotation * (i.isEven ? 1 : -1) + i * math.pi / 2;
      final radius = i.isEven ? 111.0 : 98.0;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      nodePaint.color = colors[i].withValues(alpha: 0.9 * p);
      canvas.drawCircle(point, 3.6, nodePaint);
      nodePaint.color = colors[i].withValues(alpha: 0.14 * p);
      canvas.drawCircle(point, 9.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FusionOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.phase != phase;
}

class _CinematicFieldPainter extends CustomPainter {
  final double reveal;
  final double scan;
  final double phase;
  final _BootPalette palette;

  const _CinematicFieldPainter({
    required this.reveal,
    required this.scan,
    required this.phase,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Curves.easeOutCubic.transform(reveal.clamp(0.0, 1.0).toDouble());
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = palette.foreground.withValues(alpha: (palette.dark ? 0.045 : 0.035) * p);

    const gap = 38.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final center = Offset(size.width / 2, size.height * 0.42);
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.green.withValues(alpha: (palette.dark ? 0.14 : 0.08) * p),
          palette.blue.withValues(alpha: (palette.dark ? 0.08 : 0.045) * p),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.74));
    canvas.drawCircle(center, size.width * 0.74, halo);

    final signalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = palette.blue.withValues(alpha: 0.15 * p);
    final path = Path();
    final yBase = size.height * 0.54;
    for (var i = 0; i <= 120; i++) {
      final x = size.width * i / 120;
      final envelope = math.exp(-math.pow((i - 60) / 34, 2));
      final y = yBase +
          math.sin((i / 8) + phase * math.pi * 2) * 10 * envelope +
          math.sin((i / 3.2) + phase * 4) * 2.5 * envelope;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, signalPaint);

    final scanX = size.width * scan.clamp(0.0, 1.0);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, palette.green.withValues(alpha: 0.28), Colors.transparent],
      ).createShader(Rect.fromLTWH(scanX - 28, 0, 56, size.height));
    canvas.drawRect(Rect.fromLTWH(scanX - 28, 0, 56, size.height), scanPaint);

    final particle = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 18; i++) {
      final angle = (i * 0.83) + phase * math.pi * 2;
      final radius = 70 + (i % 6) * 34.0;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle * 0.82) * radius * 0.62;
      final colors = [palette.blue, palette.green, palette.yellow, palette.red];
      particle.color = colors[i % colors.length].withValues(alpha: 0.12 * p);
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.45, particle);
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicFieldPainter oldDelegate) =>
      oldDelegate.reveal != reveal ||
      oldDelegate.scan != scan ||
      oldDelegate.phase != phase;
}

class _PulseLinePainter extends CustomPainter {
  final double phase;
  final double progress;
  final Color color;

  const _PulseLinePainter({
    required this.phase,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.72 * progress);
    final path = Path()..moveTo(0, size.height / 2);
    final points = <Offset>[
      Offset(size.width * 0.18, size.height / 2),
      Offset(size.width * 0.25, size.height * 0.32),
      Offset(size.width * 0.31, size.height * 0.72),
      Offset(size.width * 0.37, size.height * 0.10),
      Offset(size.width * 0.43, size.height * 0.88),
      Offset(size.width * 0.50, size.height / 2),
      Offset(size.width, size.height / 2),
    ];
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);

    final x = (phase * size.width).clamp(0.0, size.width);
    final dot = Paint()
      ..color = color.withValues(alpha: 0.9 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, size.height / 2), 2.6, dot);
  }

  @override
  bool shouldRepaint(covariant _PulseLinePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.progress != progress;
}
