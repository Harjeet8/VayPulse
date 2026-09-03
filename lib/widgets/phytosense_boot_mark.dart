import 'dart:math' as math;

import 'package:flutter/material.dart';

const phytoBootBlue = Color(0xFF2494F2);
const phytoBootGreen = Color(0xFF16C96B);
const phytoBootLime = Color(0xFF8EE800);
const phytoBootAmber = Color(0xFFFFC21A);
const phytoBootRed = Color(0xFFF04A38);

/// Animated presentation of the exact PhytoSense AI app icon.
///
/// The source image is never modified. Motion is layered around and over the
/// existing asset: radio traces, plant traces, ECG travel, glow and a short
/// highlight sweep. The animation collapses to the untouched icon when motion
/// is disabled.
class PhytoSenseBootMark extends StatelessWidget {
  final double progress;
  final double size;
  final bool reducedMotion;

  const PhytoSenseBootMark({
    super.key,
    required this.progress,
    this.size = 166,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = reducedMotion ? 1.0 : progress.clamp(0.0, 1.0).toDouble();
    final pulse = math.sin(p * math.pi * 2);
    final settle = Curves.easeOutBack.transform(
      (p.clamp(0.0, 0.92) / 0.92).toDouble(),
    );
    final traceOpacity = p < 0.82
        ? 1.0
        : (1.0 - ((p - 0.82) / 0.18)).clamp(0.0, 1.0).toDouble();
    final cardSize = size * 0.78;
    final sheenX = -cardSize + (cardSize * 2.15 * p);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _BootHaloPainter(progress: p),
          ),
          Transform.rotate(
            angle: reducedMotion ? 0 : pulse * 0.006,
            child: Transform.scale(
              scale: reducedMotion ? 1 : 0.90 + (0.10 * settle),
              child: Container(
                width: cardSize,
                height: cardSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardSize * 0.22),
                  boxShadow: [
                    BoxShadow(
                      color: phytoBootBlue.withValues(
                        alpha: 0.08 + 0.06 * (pulse + 1) / 2,
                      ),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: phytoBootGreen.withValues(
                        alpha: 0.09 + 0.07 * (1 - pulse) / 2,
                      ),
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardSize * 0.22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Colors.white,
                        child: Opacity(
                          opacity: reducedMotion ? 1 : 0.42 + 0.58 * Curves.easeOutCubic.transform(p),
                          child: Image.asset(
                            'assets/branding/phytosense_icon.png',
                            fit: BoxFit.cover,
                            semanticLabel: 'PhytoSense AI logo',
                          ),
                        ),
                      ),
                      if (!reducedMotion)
                        Opacity(
                          opacity: traceOpacity,
                          child: CustomPaint(
                            painter: _LogoTracePainter(progress: p),
                          ),
                        ),
                      if (!reducedMotion && p > 0.58)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Transform.translate(
                              offset: Offset(sheenX, 0),
                              child: Transform.rotate(
                                angle: -0.20,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: cardSize * 0.23,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.30),
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
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
        ],
      ),
    );
  }
}

class PhytoSenseBootBackdrop extends StatelessWidget {
  final double progress;
  final bool dark;

  const PhytoSenseBootBackdrop({
    super.key,
    required this.progress,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BootBackdropPainter(
          progress: progress,
          dark: dark,
        ),
        child: const SizedBox.expand(),
      );
}

class PhytoSenseSignalLine extends StatelessWidget {
  final double progress;
  final Color color;
  final double width;

  const PhytoSenseSignalLine({
    super.key,
    required this.progress,
    required this.color,
    this.width = 126,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 22,
        child: CustomPaint(
          painter: _SignalLinePainter(
            progress: progress,
            color: color,
          ),
        ),
      );
}

class _BootBackdropPainter extends CustomPainter {
  final double progress;
  final bool dark;

  const _BootBackdropPainter({required this.progress, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = (math.sin(progress * math.pi * 2) + 1) / 2;
    void glow(Offset center, double radius, Color color, double alpha) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55),
      );
    }

    glow(
      Offset(size.width * 0.13, size.height * 0.22),
      size.shortestSide * (0.17 + p * 0.018),
      phytoBootBlue,
      dark ? 0.085 : 0.065,
    );
    glow(
      Offset(size.width * 0.86, size.height * 0.36),
      size.shortestSide * (0.20 - p * 0.014),
      phytoBootGreen,
      dark ? 0.08 : 0.055,
    );
    glow(
      Offset(size.width * 0.25, size.height * 0.84),
      size.shortestSide * 0.12,
      phytoBootAmber,
      dark ? 0.045 : 0.035,
    );
    glow(
      Offset(size.width * 0.86, size.height * 0.82),
      size.shortestSide * 0.09,
      phytoBootRed,
      dark ? 0.030 : 0.024,
    );
  }

  @override
  bool shouldRepaint(covariant _BootBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}

class _BootHaloPainter extends CustomPainter {
  final double progress;

  const _BootHaloPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final wave = (math.sin(progress * math.pi * 2) + 1) / 2;
    final baseRadius = size.width * 0.43;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final colors = [phytoBootBlue, phytoBootGreen, phytoBootAmber];
    for (var i = 0; i < colors.length; i++) {
      ring.color = colors[i].withValues(alpha: 0.10 - i * 0.018);
      final radius = baseRadius + (i * 6) + wave * (4 + i * 1.5);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -2.5 + i * 0.8,
        1.1,
        false,
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BootHaloPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LogoTracePainter extends CustomPainter {
  final double progress;

  const _LogoTracePainter({required this.progress});

  double _segment(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();

  void _drawPartial(Canvas canvas, Path path, Paint paint, double amount) {
    if (amount <= 0) return;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * amount), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 512;
    final sy = size.height / 512;
    canvas.save();
    canvas.scale(sx, sy);

    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.94)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

    final blueArc = Path()
      ..moveTo(105, 221)
      ..cubicTo(118, 124, 188, 91, 278, 103);
    final amberArc = Path()
      ..moveTo(150, 255)
      ..cubicTo(159, 188, 205, 159, 247, 174);
    final redArc = Path()
      ..moveTo(192, 273)
      ..cubicTo(197, 233, 218, 218, 239, 230);
    _drawPartial(canvas, blueArc, stroke(phytoBootBlue, 12), _segment(0.02, 0.22));
    _drawPartial(canvas, amberArc, stroke(phytoBootAmber, 11), _segment(0.12, 0.31));
    _drawPartial(canvas, redArc, stroke(phytoBootRed, 10), _segment(0.22, 0.38));

    final leafLarge = Path()
      ..moveTo(244, 367)
      ..cubicTo(267, 251, 321, 173, 404, 151)
      ..cubicTo(399, 250, 344, 328, 244, 367);
    final leafSmall = Path()
      ..moveTo(228, 362)
      ..cubicTo(196, 299, 150, 279, 108, 274)
      ..cubicTo(131, 330, 174, 354, 228, 362);
    _drawPartial(canvas, leafLarge, stroke(phytoBootGreen, 9), _segment(0.30, 0.60));
    _drawPartial(canvas, leafSmall, stroke(phytoBootLime, 8), _segment(0.39, 0.64));

    final pulse = Path()
      ..moveTo(242, 385)
      ..lineTo(309, 385)
      ..lineTo(327, 350)
      ..lineTo(353, 414)
      ..lineTo(370, 385)
      ..lineTo(429, 385);
    _drawPartial(canvas, pulse, stroke(phytoBootBlue, 9), _segment(0.53, 0.91));

    final dotP = _segment(0.30, 0.42);
    if (dotP > 0) {
      canvas.drawCircle(
        const Offset(219, 261),
        8 + 5 * dotP,
        Paint()
          ..color = phytoBootBlue.withValues(alpha: 0.92 * dotP)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoTracePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SignalLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _SignalLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.56)
      ..lineTo(size.width * 0.29, size.height * 0.56)
      ..lineTo(size.width * 0.36, size.height * 0.28)
      ..lineTo(size.width * 0.45, size.height * 0.78)
      ..lineTo(size.width * 0.53, size.height * 0.42)
      ..lineTo(size.width * 0.62, size.height * 0.56)
      ..lineTo(size.width, size.height * 0.56);
    final metric = path.computeMetrics().first;
    final amount = progress.clamp(0.0, 1.0).toDouble();
    final visible = metric.extractPath(0, metric.length * amount);
    canvas.drawPath(
      visible,
      Paint()
        ..color = color.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SignalLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Small in-app version of the PhytoSense AI brand mark. The exact asset stays
/// untouched while the tile breathes and receives a restrained light sweep.
class LiveBrandIcon extends StatefulWidget {
  final double size;

  const LiveBrandIcon({super.key, this.size = 28});

  @override
  State<LiveBrandIcon> createState() => _LiveBrandIconState();
}

class _LiveBrandIconState extends State<LiveBrandIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.24),
        child: Image.asset(
          'assets/branding/phytosense_icon.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final wave = (math.sin(t * math.pi * 2) + 1) / 2;
        final sweep = -widget.size + widget.size * 2.1 * t;
        return Transform.scale(
          scale: 0.985 + wave * 0.03,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.24),
              boxShadow: [
                BoxShadow(
                  color: phytoBootBlue.withValues(alpha: 0.05 + wave * 0.05),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: phytoBootGreen.withValues(alpha: 0.04 + (1 - wave) * 0.05),
                  blurRadius: 9,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size * 0.24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/branding/phytosense_icon.png',
                    fit: BoxFit.cover,
                  ),
                  Transform.translate(
                    offset: Offset(sweep, 0),
                    child: Transform.rotate(
                      angle: -0.18,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: widget.size * 0.18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0),
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
          ),
        );
      },
    );
  }
}
