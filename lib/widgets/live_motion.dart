import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum LiveMotionStyle {
  breathe,
  signal,
  sway,
  drift,
  orbit,
  spark,
}

/// Visible, context-aware motion for live icons without changing their layout.
/// Motion automatically stops when reduced motion is enabled.
class LiveMotion extends StatefulWidget {
  final Widget child;
  final LiveMotionStyle style;
  final bool animate;
  final Duration duration;

  const LiveMotion({
    super.key,
    required this.child,
    this.style = LiveMotionStyle.breathe,
    this.animate = true,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<LiveMotion> createState() => _LiveMotionState();
}

class _LiveMotionState extends State<LiveMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncController();
  }

  @override
  void didUpdateWidget(covariant LiveMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _syncController();
  }

  void _syncController() {
    if (widget.animate && !_reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate || _reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;
        var scale = 1.0;
        var angle = 0.0;
        var offset = Offset.zero;
        final opacity = 0.90 + ((math.sin(phase) + 1) / 2) * 0.10;

        switch (widget.style) {
          case LiveMotionStyle.signal:
            scale = 1 + math.sin(phase) * 0.075;
            break;
          case LiveMotionStyle.sway:
            angle = math.sin(phase) * 0.09;
            offset = Offset(0, math.cos(phase) * 1.2);
            break;
          case LiveMotionStyle.drift:
            offset = Offset(math.sin(phase) * 2.8, math.cos(phase) * 1.4);
            break;
          case LiveMotionStyle.orbit:
            angle = phase;
            scale = 1 + math.sin(phase * 2) * 0.045;
            break;
          case LiveMotionStyle.spark:
            scale =
                1 + math.pow(math.max(0, math.sin(phase)), 5).toDouble() * 0.16;
            angle = math.sin(phase * 2) * 0.035;
            break;
          case LiveMotionStyle.breathe:
            scale = 1 + (math.sin(phase) + 1) * 0.032;
            offset = Offset(0, math.sin(phase) * 1.1);
            break;
        }

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: offset,
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

class LiveMotionIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  final bool animate;
  final LiveMotionStyle? style;
  final Duration? duration;

  const LiveMotionIcon({
    super.key,
    required this.icon,
    this.color,
    this.size,
    this.animate = true,
    this.style,
    this.duration,
  });

  @override
  Widget build(BuildContext context) => LiveMotion(
        animate: animate,
        style: style ?? _styleFor(icon),
        duration: duration ??
            Duration(milliseconds: 1850 + (icon.codePoint % 7) * 170),
        child: Icon(icon, color: color, size: size),
      );

  static LiveMotionStyle _styleFor(IconData icon) {
    if (icon == Icons.wb_sunny_outlined || icon == Icons.refresh_rounded) {
      return LiveMotionStyle.orbit;
    }
    if (icon == Icons.settings_outlined || icon == Icons.settings_rounded) {
      return LiveMotionStyle.orbit;
    }
    if (icon == Icons.air_rounded || icon == Icons.cloud_outlined) {
      return LiveMotionStyle.drift;
    }
    if (icon == Icons.grass_rounded ||
        icon == Icons.eco_outlined ||
        icon == Icons.spa_outlined) {
      return LiveMotionStyle.sway;
    }
    if (icon == Icons.electric_bolt_rounded ||
        icon == Icons.electric_bolt_outlined ||
        icon == Icons.auto_awesome) {
      return LiveMotionStyle.spark;
    }
    if (icon == Icons.sensors_rounded ||
        icon == Icons.sensors_outlined ||
        icon == Icons.memory_rounded ||
        icon == Icons.monitor_heart_outlined) {
      return LiveMotionStyle.signal;
    }
    return LiveMotionStyle.breathe;
  }
}

/// Replays a short, non-looping response when live card data changes.
class LiveDataMotion extends StatefulWidget {
  final Object? signature;
  final Widget child;

  const LiveDataMotion({
    super.key,
    required this.signature,
    required this.child,
  });

  @override
  State<LiveDataMotion> createState() => _LiveDataMotionState();
}

class _LiveDataMotionState extends State<LiveDataMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant LiveDataMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signature != widget.signature) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: 0.988 + curved.value * 0.012,
        child: Opacity(
          opacity: 0.82 + curved.value * 0.18,
          child: child,
        ),
      ),
    );
  }
}

/// One-time stagger used by the existing PageFrame on each screen.
class MotionEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  const MotionEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<MotionEntrance> createState() => _MotionEntranceState();
}

class _MotionEntranceState extends State<MotionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _delay?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    if (_controller.value > 0) return;
    final delay = Duration(milliseconds: 36 * math.min(widget.index, 9));
    _delay = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 10 * (1 - curved.value)),
        child: Opacity(opacity: curved.value, child: child),
      ),
    );
  }
}
