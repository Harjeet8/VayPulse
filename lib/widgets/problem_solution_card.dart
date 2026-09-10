import 'package:flutter/material.dart';

/// Farmer-first summary that separates the detected issue from the next step.
///
/// The caller supplies already-computed analysis text. This widget never
/// recalculates sensor values or changes ESP32 decisions.
class ProblemSolutionCard extends StatelessWidget {
  final String problem;
  final String solution;
  final String title;
  final String problemLabel;
  final String solutionLabel;
  final Color? accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProblemSolutionCard({
    super.key,
    required this.problem,
    required this.solution,
    this.title = 'Farmer analysis',
    this.problemLabel = 'Problem',
    this.solutionLabel = 'Solution',
    this.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final issueColor = accent ?? scheme.tertiary;
    final solutionColor = scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: issueColor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.agriculture_rounded, color: issueColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AnalysisWindow(
              icon: Icons.error_outline_rounded,
              label: problemLabel,
              text: problem,
              color: issueColor,
            ),
            const SizedBox(height: 10),
            _AnalysisWindow(
              icon: Icons.task_alt_rounded,
              label: solutionLabel,
              text: solution,
              color: solutionColor,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisWindow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;

  const _AnalysisWindow({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.065),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.65,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
