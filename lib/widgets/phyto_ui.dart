import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'live_motion.dart';

/// Shared page introduction used across the commercial farmer experience.
/// It replaces decorative title cards with one clear hierarchy.
class PhytoPageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final IconData? icon;
  final Widget? trailing;

  const PhytoPageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = switch (icon) {
      Icons.photo_camera_outlined ||
      Icons.camera_alt_outlined ||
      Icons.camera_alt_rounded =>
        phytoTerracotta,
      Icons.timeline_rounded || Icons.history_rounded => phytoLavender,
      Icons.sensors_outlined || Icons.sensors_rounded => phytoWater,
      Icons.wb_sunny_outlined || Icons.cloud_outlined => phytoSun,
      _ => colors.primary,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: LiveMotionIcon(
              icon: icon!,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 5),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

/// A quiet, borderless content surface. Only purposeful status surfaces use
/// stronger colour so long farmer pages do not become a wall of boxes.
class PhytoSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double radius;

  const PhytoSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: dark ? 0.16 : 0.055),
            blurRadius: dark ? 18 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PhytoStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;
  final bool loading;

  const PhytoStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.accent,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return PhytoSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: color,
                    ),
                  )
                : LiveMotionIcon(icon: icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(body),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 13),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
