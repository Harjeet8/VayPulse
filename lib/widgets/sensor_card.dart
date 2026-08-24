import 'package:flutter/material.dart';

import 'phyto_ui.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String status;
  final Color? accent;
  final String? caption;
  final double? numericValue;
  final double? previousValue;
  final String? preferredRange;
  final int decimals;
  final bool animate;
  final bool fresh;

  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    this.accent,
    this.caption,
    this.numericValue,
    this.previousValue,
    this.preferredRange,
    this.decimals = 0,
    this.animate = true,
    this.fresh = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (accent ?? Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: accent ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (accent ?? Theme.of(context).colorScheme.primary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              accent ?? Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            if (numericValue != null)
              AnimatedMetricText(
                value: numericValue!,
                unit: unit,
                decimals: decimals,
                animate: animate,
              )
            else
              Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    TextSpan(
                      text: ' $unit',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            if (previousValue != null && numericValue != null) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    numericValue! >= previousValue!
                        ? Icons.north_east_rounded
                        : Icons.south_east_rounded,
                    size: 15,
                    color: accent ?? Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${(numericValue! - previousValue!).abs().toStringAsFixed(decimals)} $unit',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
            if (preferredRange != null) ...[
              const SizedBox(height: 5),
              Text(
                preferredRange!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
