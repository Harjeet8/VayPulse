import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_scope.dart';

enum LiveIconKind {
  subtle,
  bioelectric,
  plant,
  environment,
  connectivity,
  analysis,
}

/// PhytoSense AI live icon motion.
///
/// Major sensing icons use clearly visible signal motion, while secondary
/// icons only breathe gently. Motion respects both OS and in-app Reduced
/// Motion settings.
class LiveIcon extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final LiveIconKind kind;
  final bool active;
  final String? semanticLabel;

  const LiveIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 24,
    this.kind = LiveIconKind.subtle,
    this.active = true,
    this.semanticLabel,
  });

  @override
  State<LiveIcon> createState() => _LiveIconState();
}

class _LiveIconState extends State<LiveIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.kind),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant LiveIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _controller.duration = _durationFor(widget.kind);
    }
    if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    } else if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations == true ||
            (AppScope.maybeOf(context)?.settings.value.reducedMotion ?? false);
    final color = widget.color ?? IconTheme.of(context).color ??
        Theme.of(context).colorScheme.primary;
    final icon = Icon(
      widget.icon,
      color: color,
      size: widget.size,
      semanticLabel: widget.semanticLabel,
    );
    if (reduceMotion || !widget.active) return icon;

    final major = widget.kind != LiveIconKind.subtle;
    final box = major ? widget.size * 1.42 : widget.size * 1.10;
    return SizedBox.square(
      dimension: box,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final raw = _controller.value;
          final wave = (math.sin(raw * math.pi * 2) + 1) / 2;
          final scale = switch (widget.kind) {
            LiveIconKind.bioelectric => 0.91 + 0.18 * wave,
            LiveIconKind.plant => 0.96 + 0.08 * wave,
            LiveIconKind.connectivity => 0.96 + 0.07 * wave,
            LiveIconKind.analysis => 0.97 + 0.05 * wave,
            LiveIconKind.environment => 0.97 + 0.06 * wave,
            LiveIconKind.subtle => 0.985 + 0.03 * wave,
          };
          final angle = switch (widget.kind) {
            LiveIconKind.plant => math.sin(raw * math.pi * 2) * 0.075,
            LiveIconKind.analysis => math.sin(raw * math.pi * 2) * 0.035,
            _ => 0.0,
          };
          final dy = switch (widget.kind) {
            LiveIconKind.environment => -1.6 * wave,
            LiveIconKind.plant => -0.9 * wave,
            LiveIconKind.subtle => -0.4 * wave,
            _ => 0.0,
          };

          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (major)
                CustomPaint(
                  painter: _SignalPainter(
                    progress: raw,
                    kind: widget.kind,
                    color: color,
                  ),
                ),
              Center(
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: scale,
                      child: icon,
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

class _SignalPainter extends CustomPainter {
  final double progress;
  final LiveIconKind kind;
  final Color color;

  const _SignalPainter({
    required this.progress,
    required this.kind,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = math.min(size.width, size.height) / 2;
    final wave = (math.sin(progress * math.pi * 2) + 1) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case LiveIconKind.connectivity:
        for (var i = 0; i < 2; i++) {
          final p = (progress + i * 0.42) % 1.0;
          paint
            ..strokeWidth = 1.5
            ..color = color.withValues(alpha: (1 - p) * 0.42);
          canvas.drawCircle(c, base * (0.42 + p * 0.50), paint);
        }
        break;
      case LiveIconKind.bioelectric:
        paint
          ..strokeWidth = 2.2
          ..color = color.withValues(alpha: 0.20 + wave * 0.34);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: base * (0.68 + wave * 0.08)),
          -math.pi * 0.85,
          math.pi * 1.50,
          false,
          paint,
        );
        final sparkAngle = progress * math.pi * 2 - math.pi / 2;
        final spark = c + Offset(math.cos(sparkAngle), math.sin(sparkAngle)) * base * 0.78;
        canvas.drawCircle(
          spark,
          1.8 + wave,
          Paint()..color = color.withValues(alpha: 0.92),
        );
        break;
      case LiveIconKind.analysis:
        paint
          ..strokeWidth = 1.25
          ..color = color.withValues(alpha: 0.26);
        canvas.drawCircle(c, base * 0.74, paint);
        for (var i = 0; i < 2; i++) {
          final a = progress * math.pi * 2 + i * math.pi;
          final dot = c + Offset(math.cos(a), math.sin(a)) * base * 0.74;
          canvas.drawCircle(
            dot,
            2.0,
            Paint()..color = color.withValues(alpha: 0.85),
          );
        }
        break;
      case LiveIconKind.environment:
        final p = progress;
        paint
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: (1 - p) * 0.32);
        canvas.drawCircle(c, base * (0.52 + p * 0.34), paint);
        break;
      case LiveIconKind.plant:
        paint
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: 0.14 + wave * 0.18);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: base * 0.76),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          paint,
        );
        break;
      case LiveIconKind.subtle:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SignalPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.kind != kind ||
      oldDelegate.color != color;
}

Duration _durationFor(LiveIconKind kind) => switch (kind) {
      LiveIconKind.bioelectric => const Duration(milliseconds: 1050),
      LiveIconKind.connectivity => const Duration(milliseconds: 1450),
      LiveIconKind.analysis => const Duration(milliseconds: 2100),
      LiveIconKind.environment => const Duration(milliseconds: 2300),
      LiveIconKind.plant => const Duration(milliseconds: 2200),
      LiveIconKind.subtle => const Duration(milliseconds: 2800),
    };

LiveIconKind liveIconKindFor(IconData icon) {
  if (icon == Icons.bolt_rounded ||
      icon == Icons.bolt_outlined ||
      icon == Icons.electric_bolt_rounded ||
      icon == Icons.electric_bolt_outlined ||
      icon == Icons.monitor_heart_rounded ||
      icon == Icons.monitor_heart_outlined ||
      icon == Icons.favorite_rounded) {
    return LiveIconKind.bioelectric;
  }
  if (icon == Icons.eco_rounded ||
      icon == Icons.eco_outlined ||
      icon == Icons.grass_rounded ||
      icon == Icons.grass_outlined ||
      icon == Icons.spa_rounded ||
      icon == Icons.spa_outlined ||
      icon == Icons.agriculture_rounded) {
    return LiveIconKind.plant;
  }
  if (icon == Icons.sensors_rounded ||
      icon == Icons.sensors_outlined ||
      icon == Icons.wifi_rounded ||
      icon == Icons.wifi_outlined ||
      icon == Icons.router_rounded ||
      icon == Icons.router_outlined ||
      icon == Icons.cell_tower_rounded ||
      icon == Icons.cell_tower_outlined ||
      icon == Icons.hub_rounded) {
    return LiveIconKind.connectivity;
  }
  if (icon == Icons.psychology_alt_rounded ||
      icon == Icons.psychology_alt_outlined ||
      icon == Icons.auto_graph_rounded ||
      icon == Icons.auto_graph_outlined) {
    return LiveIconKind.analysis;
  }
  if (icon == Icons.water_drop_rounded ||
      icon == Icons.water_drop_outlined ||
      icon == Icons.thermostat_rounded ||
      icon == Icons.thermostat_outlined ||
      icon == Icons.light_mode_rounded ||
      icon == Icons.light_mode_outlined ||
      icon == Icons.air_rounded ||
      icon == Icons.air_outlined ||
      icon == Icons.wb_sunny_rounded ||
      icon == Icons.wb_sunny_outlined) {
    return LiveIconKind.environment;
  }
  return LiveIconKind.subtle;
}
