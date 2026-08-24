import 'package:flutter/material.dart';

class InsightCard extends StatelessWidget {
  final String title;
  final String message;
  final String? action;
  final Color? accent;

  const InsightCard({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: (accent ?? Theme.of(context).colorScheme.primary)
          .withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome,
              color: accent ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(message),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      action!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
