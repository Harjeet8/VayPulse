import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Additive engineering-style overlay for the PhytoSense boot sequence.
/// It sits behind the existing icon/brand animation and does not replace it.
class BootIntelligenceOverlay extends StatelessWidget {
  final double progress;
  final double phase;
  final bool dark;

  const BootIntelligenceOverlay({
    super.key,
    required this.progress,
    required this.phase,
    required this.dark,
  });

  double _segment(double begin, double end) {
    if (progress <= begin) return 0;
    if (progress >= end) return 1;
    return ((progress - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final scan = _segment(0.02, 0.48);
    final channels = _segment(0.18, 0.62);
    final fusion = _segment(0.48, 0.82);
    final ready = _segment(0.78, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _BootIntelligencePainter(
            scan: scan,
            fusion: fusion,
            phase: phase,
            dark: dark,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                Opacity(
                  opacity: Curves.easeOutCubic.transform(scan),
                  child: Transform.translate(
                    offset: Offset(0, (1 - scan) * -8),
                    child: _TopStatus(
                      progress: progress,
                      scan: scan,
                      fusion: fusion,
                      ready: ready,
                      dark: dark,
                    ),
                  ),
                ),
                const Spacer(),
                Opacity(
                  opacity: channels,
                  child: Transform.translate(
                    offset: Offset(0, (1 - channels) * 12),
                    child: _ChannelRail(
                      progress: channels,
                      fusion: fusion,
                      dark: dark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopStatus extends StatelessWidget {
  final double progress;
  final double scan;
  final double fusion;
  final double ready;
  final bool dark;

  const _TopStatus({
    required this.progress,
    required this.scan,
    required this.fusion,
    required this.ready,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = dark ? const Color(0xFFB9E7D4) : const Color(0xFF176B4D);
    final glow = dark ? const Color(0xFF8FE1BD) : const Color(0xFF31A36F);
    final labelColor = dark ? Colors.white : const Color(0xFF14251E);
    final label = ready > 0.45
        ? 'PLANT INTELLIGENCE READY'
        : fusion > 0.22
            ? 'FUSING BIO + ENVIRONMENT'
            : scan > 0.35
                ? 'SENSORS FORMING NETWORK'
                : 'INITIALIZING SIGNAL FIELD';
    final value = (progress * 100).clamp(0, 100).round();
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.85),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              label,
              key: ValueKey(label),
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: labelColor.withValues(alpha: dark ? 0.52 : 0.62),
                fontSize: 9.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.7,
              ),
            ),
          ),
        ),
        Text(
          '$value%',
          style: TextStyle(
            color: accent.withValues(alpha: dark ? 0.55 : 0.68),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _ChannelRail extends StatelessWidget {
  final double progress;
  final double fusion;
  final bool dark;

  const _ChannelRail({
    required this.progress,
    required this.fusion,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = dark ? const Color(0xFFB9E7D4) : const Color(0xFF176B4D);
    const channels = <(IconData, String)>[
      (Icons.electric_bolt_rounded, 'BIO'),
      (Icons.water_drop_outlined, 'SOIL'),
      (Icons.air_rounded, 'AIR'),
      (Icons.device_thermostat_rounded, 'ROOT'),
      (Icons.wb_sunny_outlined, 'LIGHT'),
    ];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < channels.length; i++) ...[
              _ChannelNode(
                icon: channels[i].$1,
                label: channels[i].$2,
                active: progress > (i * 0.12),
                fused: fusion > (i * 0.08),
                dark: dark,
              ),
              if (i != channels.length - 1)
                Container(
                  width: 18,
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  color: accent.withValues(
                    alpha: fusion > 0.2 ? 0.24 : 0.08,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 214,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              color: accent.withValues(alpha: dark ? 0.62 : 0.72),
              backgroundColor: (dark ? Colors.white : const Color(0xFF176B4D))
                  .withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool fused;
  final bool dark;

  const _ChannelNode({
    required this.icon,
    required this.label,
    required this.active,
    required this.fused,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = dark ? const Color(0xFFB9E7D4) : const Color(0xFF176B4D);
    final labelColor = dark ? Colors.white : const Color(0xFF14251E);
    final alpha = active ? (fused ? 0.78 : 0.52) : 0.14;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: active ? 0.055 : 0.02),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: accent.withValues(alpha: active ? 0.18 : 0.06),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: accent.withValues(alpha: alpha)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: labelColor.withValues(alpha: alpha * 0.82),
              fontSize: 6.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _BootIntelligencePainter extends CustomPainter {
  final double scan;
  final double fusion;
  final double phase;
  final bool dark;

  const _BootIntelligencePainter({
    required this.scan,
    required this.fusion,
    required this.phase,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 72);
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final primary = dark ? const Color(0xFFB9E7D4) : const Color(0xFF176B4D);
    final orbit = dark ? const Color(0xFF9DDEC2) : const Color(0xFF2B8D64);
    final connector = dark ? const Color(0xFF78CFA9) : const Color(0xFF31A36F);

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = orbit.withValues(alpha: 0.045 + fusion * 0.08);
    for (final radius in <double>[104, 132, 164]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 0.82,
        ),
        orbitPaint,
      );
    }

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: 0.12 + scan * 0.15);
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 264, height: 108),
      phase * math.pi * 2,
      math.pi * (0.34 + scan * 0.18),
      false,
      sweepPaint,
    );

    const nodes = 14;
    final nodePaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var i = 0; i < nodes; i++) {
      final angle = i / nodes * math.pi * 2 + phase * 0.18;
      final radiusX = 130.0 + (i % 3) * 18;
      final radiusY = 52.0 + (i % 4) * 8;
      final p = center + Offset(math.cos(angle) * radiusX, math.sin(angle) * radiusY);
      final localPulse = (math.sin(phase * math.pi * 2 + i * 0.72) + 1) / 2;
      final alpha = (0.025 + localPulse * 0.10) * (0.45 + scan * 0.55);
      nodePaint.color = primary.withValues(alpha: alpha);
      canvas.drawCircle(p, 1.4 + localPulse * 1.3, nodePaint);

      if (fusion > 0.02) {
        linePaint.color = connector.withValues(alpha: 0.018 + fusion * 0.035);
        final target = Offset.lerp(p, center, 0.18 + fusion * 0.32)!;
        canvas.drawLine(p, target, linePaint);
      }
    }

    final scanY = size.height * (0.18 + 0.64 * ((phase + scan * 0.2) % 1.0));
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        primary.withValues(alpha: 0.035 + pulse * 0.025),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, scanY - 1, size.width, 2));
    final scanLine = Paint()
      ..shader = gradient
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanLine);

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: 0.08 + fusion * 0.05);
    const inset = 17.0;
    const arm = 22.0;
    canvas.drawLine(const Offset(inset, inset), const Offset(inset + arm, inset), cornerPaint);
    canvas.drawLine(const Offset(inset, inset), const Offset(inset, inset + arm), cornerPaint);
    canvas.drawLine(Offset(size.width - inset, inset), Offset(size.width - inset - arm, inset), cornerPaint);
    canvas.drawLine(Offset(size.width - inset, inset), Offset(size.width - inset, inset + arm), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _BootIntelligencePainter oldDelegate) =>
      oldDelegate.scan != scan ||
      oldDelegate.fusion != fusion ||
      oldDelegate.phase != phase ||
      oldDelegate.dark != dark;
}
