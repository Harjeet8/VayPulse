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
          appBar: AppBar(title: Text(FarmerLanguage.label(context, 'farmer_analysis'))),
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
                  _DisconnectedCard(reading: reading),
                if (reading == null)
                  const _WaitingCard()
                else ...[
                  _FarmerAnswerCard(
                    icon: Icons.eco_rounded,
                    title: FarmerLanguage.label(context, 'plant_condition'),
                    value: FarmerLanguage.firmware(
                      context,
                      edge?.plantState ?? reading.healthStatus,
                      fallback: FarmerLanguage.label(context, 'keep_monitoring'),
                    ),
                    accent: _conditionColor(context, edge?.plantState ?? reading.healthStatus),
                  ),
                  const SizedBox(height: 12),
                  _FarmerAnswerCard(
                    icon: Icons.report_problem_outlined,
                    title: FarmerLanguage.label(context, 'main_problem'),
                    value: FarmerLanguage.firmware(
                      context,
                      edge?.rootCause.primary ?? edge?.farmerSummary,
                      fallback: FarmerLanguage.label(context, 'no_problem'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FarmerAnswerCard(
                    icon: Icons.compare_arrows_rounded,
                    title: FarmerLanguage.label(context, 'what_changed'),
                    value: _whatChanged(context, edge),
                  ),
                  const SizedBox(height: 12),
                  _FarmerAnswerCard(
                    icon: Icons.task_alt_rounded,
                    title: FarmerLanguage.label(context, 'what_to_do'),
                    value: FarmerLanguage.firmware(
                      context,
                      edge?.recommendation,
                      fallback: FarmerLanguage.label(context, 'keep_monitoring'),
                    ),
                    accent: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _ConfidenceCard(
                    value: edge?.overallConfidence ?? reading.analysisConfidence,
                    degraded: edge?.degradedAnalysis == true,
                  ),
                  const SizedBox(height: 12),
                  _AdvancedDetails(reading: reading, edge: edge),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _whatChanged(BuildContext context, EdgeIntelligence? edge) {
    if (edge?.recovery.active == true || edge?.plantState?.toUpperCase() == 'RECOVERING') {
      final improved = edge?.recovery.improved;
      if (improved != null && improved.trim().isNotEmpty) {
        return FarmerLanguage.firmware(context, improved);
      }
      return FarmerLanguage.firmware(context, 'RECOVERING');
    }

    final notable = edge?.trends.where((trend) {
      final value = trend.state?.toUpperCase() ?? '';
      return value.isNotEmpty && value != 'STABLE' && value != 'NORMAL';
    }).toList();
    if (notable != null && notable.isNotEmpty) {
      final trend = notable.first;
      final channel = _friendlyChannel(trend.channel);
      final state = FarmerLanguage.firmware(context, trend.state);
      return '$channel: $state';
    }

    if (edge?.baseline.anomalyDetected == true || edge?.baseline.changePointDetected == true) {
      return FarmerLanguage.isTamil(context)
          ? 'இந்த செடியின் சமீபத்திய இயல்புடன் ஒப்பிடும்போது ஒரு குறிப்பிடத்தக்க மாற்றம் உள்ளது.'
          : 'A notable change was detected compared with this plant’s recent normal pattern.';
    }

    if (edge?.irrigation.probable == true) {
      return FarmerLanguage.isTamil(context)
          ? 'சமீபத்தில் நீர்ப்பாய்ச்சி நடந்திருக்கலாம் என்று ESP32 காட்டுகிறது.'
          : 'The ESP32 indicates that watering probably occurred recently.';
    }

    return FarmerLanguage.label(context, 'no_change');
  }
}

class _FarmerAnswerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? accent;

  const _FarmerAnswerCard({
    required this.icon,
    required this.title,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.secondary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
            const SizedBox(width: 14),
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
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                  ),
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

  const _ConfidenceCard({required this.value, required this.degraded});

  @override
  Widget build(BuildContext context) {
    final band = FarmerLanguage.confidence(context, value);
    final color = value != null && value! >= 80
        ? Theme.of(context).colorScheme.primary
        : value != null && value! >= 55
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: color, size: 30),
            const SizedBox(width: 14),
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
                    const SizedBox(height: 4),
                    Text(
                      FarmerLanguage.isTamil(context)
                          ? 'சில தகவல்கள் குறைந்த நம்பிக்கையுடன் கிடைக்கின்றன.'
                          : 'Some information is currently less reliable.',
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
          _Row('Health score', '${reading.healthScore.round()} / 100'),
          _Row('Exact confidence', '${(edge?.overallConfidence ?? reading.analysisConfidence).round()}%'),
          if (edge?.cropProfile.profile != null)
            _Row('Crop profile', edge!.cropProfile.profile!),
          if (edge?.cropProfile.growthStage != null)
            _Row('Growth stage', edge!.cropProfile.growthStage!),
          if (edge?.rootCause.secondary != null)
            _Row('Secondary cause', edge!.rootCause.secondary!),
          if (edge?.degradedReason != null)
            _Row('Reduced-confidence reason', edge!.degradedReason!),
          if (edge?.derivedEnvironment.vpdKpa != null)
            _Row('VPD', '${edge!.derivedEnvironment.vpdKpa!.toStringAsFixed(2)} kPa'),
          if (reading.plantVoltageMv != null)
            _Row('Plant amplifier output', '${reading.plantVoltageMv!.toStringAsFixed(1)} mV'),
          if (reading.bioBaselineMv != null)
            _Row('Bioelectric baseline', '${reading.bioBaselineMv!.toStringAsFixed(1)} mV'),
          if (reading.bioDeviationMv != null)
            _Row('Baseline deviation', '${reading.bioDeviationMv!.toStringAsFixed(1)} mV'),
          if (edge?.sensorFaults.isNotEmpty == true)
            _Row('Sensor issues', edge!.sensorFaults.length.toString()),
          if (edge?.tinyMl.hasData == true)
            _Row('TinyML model', edge!.tinyMl.modelLoaded ? 'Loaded' : 'Not loaded'),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DisconnectedCard extends StatelessWidget {
  final SensorReading? reading;

  const _DisconnectedCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.portable_wifi_off_rounded,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(FarmerLanguage.label(context, 'disconnected'),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  if (reading != null) ...[
                    const SizedBox(height: 4),
                    Text('${FarmerLanguage.label(context, 'last_reading')}: ${_time(reading!.timestamp)}'),
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

class _WaitingCard extends StatelessWidget {
  const _WaitingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 14),
            Expanded(child: Text('Waiting for a validated ESP32 reading…')),
          ],
        ),
      ),
    );
  }
}

Color _conditionColor(BuildContext context, String? raw) {
  final value = raw?.toUpperCase() ?? '';
  if (value.contains('CRITICAL') || value.contains('HIGH_STRESS')) {
    return Theme.of(context).colorScheme.error;
  }
  if (value.contains('STRESS') || value.contains('ATTENTION') || value.contains('WATCH')) {
    return Theme.of(context).colorScheme.tertiary;
  }
  if (value.contains('RECOVER')) return Theme.of(context).colorScheme.tertiary;
  return Theme.of(context).colorScheme.primary;
}

String _friendlyChannel(String raw) {
  final value = raw
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
      .trim();
  if (value.isEmpty) return 'Plant condition';
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _time(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
