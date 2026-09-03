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

/// Lightweight motion used across PhytoSense AI to make live signals feel
/// active without turning the interface into a decorative animation layer.
/// Motion is automatically disabled by the OS accessibility preference or the
/// in-app Reduced Motion setting.
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
    )..repeat(reverse: true);
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
      _controller.repeat(reverse: true);
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
    final icon = Icon(
      widget.icon,
      color: widget.color,
      size: widget.size,
      semanticLabel: widget.semanticLabel,
    );
    if (reduceMotion || !widget.active) return icon;

    return AnimatedBuilder(
      animation: _controller,
      child: icon,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = switch (widget.kind) {
          LiveIconKind.bioelectric => 0.94 + (0.12 * t),
          LiveIconKind.plant => 0.97 + (0.06 * t),
          LiveIconKind.connectivity => 0.96 + (0.08 * t),
          LiveIconKind.analysis => 0.98 + (0.04 * t),
          _ => 0.985 + (0.03 * t),
        };
        final dy = switch (widget.kind) {
          LiveIconKind.environment => -1.4 * t,
          LiveIconKind.plant => -0.7 * t,
          LiveIconKind.subtle => -0.35 * t,
          _ => 0.0,
        };
        final angle = widget.kind == LiveIconKind.analysis
            ? math.sin(t * math.pi) * 0.035
            : 0.0;
        final opacity = switch (widget.kind) {
          LiveIconKind.connectivity => 0.74 + (0.26 * t),
          LiveIconKind.bioelectric => 0.82 + (0.18 * t),
          _ => 0.9 + (0.1 * t),
        };
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
    );
  }
}

Duration _durationFor(LiveIconKind kind) => switch (kind) {
      LiveIconKind.bioelectric => const Duration(milliseconds: 920),
      LiveIconKind.connectivity => const Duration(milliseconds: 1250),
      LiveIconKind.analysis => const Duration(milliseconds: 1800),
      LiveIconKind.environment => const Duration(milliseconds: 2100),
      LiveIconKind.plant => const Duration(milliseconds: 1900),
      LiveIconKind.subtle => const Duration(milliseconds: 2500),
    };

LiveIconKind liveIconKindFor(IconData icon) {
  if (icon == Icons.bolt_rounded ||
      icon == Icons.bolt_outlined ||
      icon == Icons.electric_bolt_rounded ||
      icon == Icons.electric_bolt_outlined ||
      icon == Icons.monitor_heart_rounded ||
      icon == Icons.monitor_heart_outlined) {
    return LiveIconKind.bioelectric;
  }
  if (icon == Icons.eco_rounded ||
      icon == Icons.eco_outlined ||
      icon == Icons.grass_rounded ||
      icon == Icons.grass_outlined ||
      icon == Icons.spa_rounded ||
      icon == Icons.spa_outlined) {
    return LiveIconKind.plant;
  }
  if (icon == Icons.sensors_rounded ||
      icon == Icons.sensors_outlined ||
      icon == Icons.wifi_rounded ||
      icon == Icons.wifi_outlined ||
      icon == Icons.router_rounded ||
      icon == Icons.router_outlined ||
      icon == Icons.cell_tower_rounded ||
      icon == Icons.cell_tower_outlined) {
    return LiveIconKind.connectivity;
  }
  if (icon == Icons.psychology_alt_rounded ||
      icon == Icons.psychology_alt_outlined ||
      icon == Icons.hub_rounded ||
      icon == Icons.hub_outlined ||
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
