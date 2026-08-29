import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';

class FarmerAnalysisScreen extends StatelessWidget {
  const FarmerAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final reading = sensors.current;
        final edge = sensors.edgeIntelligence;
        return Scaffold(
          appBar: AppBar(
            title: Text(FarmerLanguage.label(context, 'analysis')),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              sensors.retry();
              await Future<void>.delayed(const Duration(milliseconds: 450));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Text(
                  FarmerLanguage.label(context, 'farmer_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                if (sensors.connectionStatus != SensorConnectionStatus.ready)
                  _ConnectionNotice(
                    reading: reading,
                    live: sensors.source == SensorDataSource.esp32,
                  ),
                if (reading == null)
                  _WaitingCard(live: sensors.source == SensorDataSource.esp32)
                else ...[
                  _AnswerCard(
                    icon: Icons.eco_rounded,
                    title: FarmerLanguage.label(context, 'plant_condition'),
                    value: FarmerLanguage.firmware(
                      context,
                      edge?.plantState ?? reading.healthStatus,
                      fallback: FarmerLanguage.label(context, 'keep_monitoring'),
                    ),
                    accent: _conditionColor(
                      context,
                      edge?.plantState ?? reading.healthStatus,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AnswerCard(
                    icon: Icons.report_problem_outlined,
                    title: FarmerLanguage.label(context, 'main_problem'),
                    value: FarmerLanguage.firmware(
                      context,
                      edge?.rootCause.primary ??
                          edge?.farmerSummary ??
                          edge?.bioelectric.farmerResult,
                      fallback: FarmerLanguage.label(context, 'no_problem'),
                    ),
                    secondary: edge?.rootCause.secondary == null
                        ? null
                        : FarmerLanguage.firmware(
                            context,
                            edge!.rootCause.secondary,
                          ),
                  ),
                  const SizedBox(height: 10),
                  _AnswerCard(
                    icon: Icons.help_outline_rounded,
                    title: FarmerLanguage.label(context, 'why_happening'),
                    value: _why(context, edge),
                  ),
                  const SizedBox(height: 10),
                  _AnswerCard(
                    icon: Icons.task_alt_rounded,
                    title: FarmerLanguage.label(context, 'what_to_do'),
                    value: FarmerLanguage.firmware(
                      context,
                      edge?.recovery.active == true
                          ? FarmerLanguage.label(context, 'recovery_action')
                          : edge?.recommendation,
                      fallback: FarmerLanguage.label(context, 'keep_monitoring'),
                    ),
                    accent: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  _AnswerCard(
                    icon: Icons.trending_up_rounded,
                    title: FarmerLanguage.label(context, 'is_improving'),
                    value: _conditionTrend(context, edge),
                  ),
                  const SizedBox(height: 10),
                  _ConfidenceCard(
                    value: edge?.overallConfidence ??
                        reading.esp32HealthConfidence ??
                        (sensors.source == SensorDataSource.simulation
                            ? reading.analysisConfidence
                            : null),
                    degraded: edge?.degradedAnalysis == true,
                    degradedReason: edge?.degradedReason,
                  ),
                  const SizedBox(height: 10),
                  _AdvancedDetails(reading: reading, edge: edge),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _why(BuildContext context, EdgeIntelligence? edge) {
    if (edge == null) return FarmerLanguage.label(context, 'why_unavailable');
    if (edge.recovery.active || edge.plantState?.toUpperCase() == 'RECOVERING') {
      return FarmerLanguage.firmware(
        context,
        edge.recovery.improved,
        fallback: FarmerLanguage.label(context, 'recovery_summary'),
      );
    }
    final explicit = edge.decisionExplanation;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return FarmerLanguage.firmware(context, explicit);
    }
    final reasons = <String>[];
    for (final raw in [
      edge.rootCause.primary,
      edge.rootCause.secondary,
      edge.bioelectric.farmerResult,
      edge.bioticStress.suspected ? edge.bioticStress.reason : null,
    ]) {
      if (raw == null || raw.trim().isEmpty) continue;
      final value = FarmerLanguage.firmware(context, raw);
      if (!reasons.contains(value)) reasons.add(value);
      if (reasons.length == 2) break;
    }
    return reasons.isEmpty
        ? FarmerLanguage.label(context, 'why_unavailable')
        : reasons.join('. ');
  }
}

class _AnswerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? secondary;
  final Color? accent;

  const _AnswerCard({
    required this.icon,
    required this.title,
    required this.value,
    this.secondary,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.secondary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                  ),
                  if (secondary != null && secondary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      '${FarmerLanguage.label(context, 'making_it_worse')}: $secondary',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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

class _ConfidenceCard extends StatelessWidget {
  final double? value;
  final bool degraded;
  final String? degradedReason;

  const _ConfidenceCard({
    required this.value,
    required this.degraded,
    required this.degradedReason,
  });

  @override
  Widget build(BuildContext context) {
    final band = FarmerLanguage.confidence(context, value);
    final color = value == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : value! >= 80
            ? Theme.of(context).colorScheme.primary
            : value! >= 55
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_outlined, color: color, size: 30),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FarmerLanguage.label(context, 'analysis_confidence'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    band,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                  ),
                  if (degraded) ...[
                    const SizedBox(height: 5),
                    Text(
                      FarmerLanguage.firmware(
                        context,
                        degradedReason,
                        fallback: FarmerLanguage.label(context, 'degraded_body'),
                      ),
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

class _AdvancedDetails extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;

  const _AdvancedDetails({required this.reading, required this.edge});

  @override
  Widget build(BuildContext context) {
    final bio = edge?.bioelectric;
    final exactConfidence = edge?.overallConfidence ?? reading.esp32HealthConfidence;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.tune_rounded),
        title: Text(
          FarmerLanguage.label(context, 'advanced_details'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _Row('Firmware', edge?.firmwareVersion ?? 'Unknown'),
          if (edge?.healthScore != null)
            _Row('Health score', '${edge!.healthScore!.round()} / 100'),
          if (exactConfidence != null)
            _Row('Exact confidence', '${exactConfidence.round()}%'),
          if (edge?.cropProfile.profile != null)
            _Row('Crop profile', edge!.cropProfile.profile!),
          if (edge?.cropProfile.growthStage != null)
            _Row('Growth stage', edge!.cropProfile.growthStage!),
          if (edge?.rootCause.secondary != null)
            _Row('Secondary cause', edge!.rootCause.secondary!),
          if (edge?.degradedReason != null)
            _Row('Reduced-confidence reason', edge!.degradedReason!),
          if (edge?.derivedEnvironment.vpdKpa != null)
            _Row(
              'VPD',
              '${edge!.derivedEnvironment.vpdKpa!.toStringAsFixed(2)} kPa',
            ),
          if (bio?.voltageMv != null)
            _Row('Plant amplifier output', '${bio!.voltageMv!.toStringAsFixed(1)} mV'),
          if (bio?.baselineMv != null)
            _Row('Bioelectric baseline', '${bio!.baselineMv!.toStringAsFixed(1)} mV'),
          if (bio?.signedChangeMv != null)
            _Row('Signed change', '${bio!.signedChangeMv!.toStringAsFixed(1)} mV'),
          if (bio?.normalizedDeviation != null)
            _Row('Normalized deviation', '${bio!.normalizedDeviation!.toStringAsFixed(1)}%'),
          if (bio?.noiseMv != null)
            _Row('Bioelectric noise', '${bio!.noiseMv!.toStringAsFixed(1)} mV'),
          if (bio?.signalQuality != null)
            _Row('Signal quality', '${bio!.signalQuality!.round()}%'),
          if (bio?.persistenceSeconds != null)
            _Row('Persistence', '${bio!.persistenceSeconds!.round()} sec'),
          if (edge?.sensorFaults.isNotEmpty == true)
            _Row('Sensor issues', edge!.sensorFaults.length.toString()),
          if (edge?.tinyMl.hasData == true)
            _Row(
              'TinyML model',
              edge!.tinyMl.modelLoaded ? 'Loaded' : 'Not loaded',
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _ConnectionNotice extends StatelessWidget {
  final SensorReading? reading;
  final bool live;

  const _ConnectionNotice({required this.reading, required this.live});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                live ? Icons.portable_wifi_off_rounded : Icons.hourglass_top_rounded,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FarmerLanguage.label(
                        context,
                        live ? 'disconnected' : 'simulation_waiting',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (reading != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${FarmerLanguage.label(context, 'last_reading')}: ${_time(reading!.timestamp)}',
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

class _WaitingCard extends StatelessWidget {
  final bool live;
  const _WaitingCard({required this.live});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  FarmerLanguage.label(
                    context,
                    live ? 'waiting_esp32' : 'simulation_waiting',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

String _conditionTrend(BuildContext context, EdgeIntelligence? edge) {
  if (edge?.recovery.active == true ||
      edge?.plantState?.toUpperCase() == 'RECOVERING') {
    return FarmerLanguage.label(context, 'recovering');
  }
  final health = edge?.trends.where(
    (item) => item.channel.toLowerCase().contains('health'),
  );
  if (health != null && health.isNotEmpty && health.first.state != null) {
    final value = health.first.state!.toUpperCase();
    if (value.contains('RISING')) {
      return FarmerLanguage.label(context, 'improving');
    }
    if (value.contains('FALLING_FAST') || value.contains('FALLING_QUICK')) {
      return FarmerLanguage.label(context, 'getting_worse_quickly');
    }
    if (value.contains('FALLING')) {
      return FarmerLanguage.label(context, 'getting_worse');
    }
  }
  final bio = edge?.bioelectric.trend?.toUpperCase();
  if (bio != null) {
    if (bio.contains('RISING_FAST') || bio.contains('RISING_QUICK')) {
      return FarmerLanguage.label(context, 'getting_worse_quickly');
    }
    if (bio.contains('RISING')) {
      return FarmerLanguage.label(context, 'getting_worse');
    }
    if (bio.contains('FALLING')) {
      return FarmerLanguage.label(context, 'improving');
    }
  }
  return FarmerLanguage.label(context, 'stable');
}

Color _conditionColor(BuildContext context, String? raw) {
  final value = raw?.toUpperCase() ?? '';
  if (value.contains('CRITICAL') || value.contains('HIGH_STRESS')) {
    return Theme.of(context).colorScheme.error;
  }
  if (value.contains('STRESS') ||
      value.contains('ATTENTION') ||
      value.contains('WATCH')) {
    return Theme.of(context).colorScheme.tertiary;
  }
  return Theme.of(context).colorScheme.primary;
}

String _time(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
