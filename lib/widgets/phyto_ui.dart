import 'package:flutter/material.dart';

import '../app/theme.dart';

class PhytoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const PhytoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      );
}

class PhytoStatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool prominent;

  const PhytoStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: prominent ? 11 : 9,
          vertical: prominent ? 7 : 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: prominent ? 17 : 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: prominent ? 12 : 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.25,
                ),
              ),
            ),
          ],
        ),
      );
}

class LivePulseDot extends StatefulWidget {
  final Color color;
  final bool animate;
  final double size;

  const LivePulseDot({
    super.key,
    required this.color,
    this.animate = true,
    this.size = 10,
  });

  @override
  State<LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.animate) controller.repeat();
  }

  @override
  void didUpdateWidget(covariant LivePulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !controller.isAnimating) controller.repeat();
    if (!widget.animate && controller.isAnimating) controller.stop();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size * 2.4,
        height: widget.size * 2.4,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final progress = widget.animate ? controller.value : 0.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * (1 + progress * 1.3),
                  height: widget.size * (1 + progress * 1.3),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: (0.28 * (1 - progress)).clamp(0, 1).toDouble(),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.34),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class AnimatedMetricText extends StatelessWidget {
  final double value;
  final String unit;
  final int decimals;
  final TextStyle? style;
  final bool animate;

  const AnimatedMetricText({
    super.key,
    required this.value,
    required this.unit,
    this.decimals = 0,
    this.style,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ??
        Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w900);
    if (!animate) {
      return Text('${value.toStringAsFixed(decimals)} $unit',
          style: resolvedStyle);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text.rich(
        TextSpan(
          text: animated.toStringAsFixed(decimals),
          children: [
            TextSpan(
              text: unit.isEmpty ? '' : ' $unit',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        style: resolvedStyle,
      ),
    );
  }
}

class PhytoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PhytoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 17),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}

class FarmerActionCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final Color? accent;

  const FarmerActionCard({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return Card(
      color: color.withValues(alpha: 0.055),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const uiHealthy = phytoGreen;
const uiAttention = phytoAmber;
const uiCritical = phytoTerracotta;
