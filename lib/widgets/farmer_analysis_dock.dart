import 'package:flutter/material.dart';

/// Compact always-visible Problem / Solution summary for farmer-facing pages.
class FarmerAnalysisDock extends StatelessWidget {
  final String problem;
  final String solution;
  final Color accent;

  const FarmerAnalysisDock({
    super.key,
    required this.problem,
    required this.solution,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.agriculture_rounded, size: 18, color: accent),
                    const SizedBox(width: 7),
                    Text(
                      'Farmer analysis',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _DockLine(
                  label: 'Problem',
                  text: problem,
                  icon: Icons.error_outline_rounded,
                  color: accent,
                ),
                const SizedBox(height: 7),
                _DockLine(
                  label: 'Solution',
                  text: solution,
                  icon: Icons.task_alt_rounded,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockLine extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final Color color;

  const _DockLine({
    required this.label,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 62,
            child: Text(
              '$label:',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
}
