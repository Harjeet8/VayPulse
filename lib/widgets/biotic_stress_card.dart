import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../services/farmer_language.dart';

/// Farmer-facing explanation of an ESP32-originated biotic-stress suspicion.
///
/// This widget never infers a biotic state. Callers must only render it when
/// [BioticStressInfo.suspected] is true.
class BioticStressCard extends StatelessWidget {
  final BioticStressInfo info;
  final VoidCallback onScan;

  const BioticStressCard({
    super.key,
    required this.info,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final evidence = <String>[
      if (info.unexplainedBioResponse == true)
        FarmerLanguage.label(context, 'biotic_evidence_bio'),
      if (info.confidence != null)
        FarmerLanguage.label(context, 'biotic_evidence_signal'),
      if (info.abioticCauseFound == false)
        FarmerLanguage.label(context, 'biotic_evidence_environment'),
    ];

    return Card(
      color: scheme.tertiaryContainer.withValues(alpha: 0.42),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.biotech_outlined, color: scheme.tertiary, size: 30),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    FarmerLanguage.label(context, 'possible_biotic_title')
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onTertiaryContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              FarmerLanguage.firmware(
                context,
                info.farmerResult ?? info.reason,
                fallback: FarmerLanguage.label(context, 'possible_biotic_body'),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              FarmerLanguage.label(context, 'biotic_why_title'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            for (final item in evidence)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 18),
                    const SizedBox(width: 7),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(FarmerLanguage.label(context, 'biotic_inspection_reason')),
            const SizedBox(height: 14),
            Text(
              FarmerLanguage.label(context, 'recommended_action'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              FarmerLanguage.firmware(
                context,
                info.recommendation,
                fallback:
                    FarmerLanguage.label(context, 'biotic_inspect_action'),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  FarmerLanguage.label(context, 'scan_plant_camera'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              FarmerLanguage.label(context, 'biotic_safety_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
