import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';

class SensorHealthScreen extends StatelessWidget {
  const SensorHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final edge = sensors.edgeIntelligence;
        final telemetry = sensors.hardwareTelemetry;
        final live = sensors.source == SensorDataSource.esp32;
        return Scaffold(
          appBar: AppBar(
            title: Text(FarmerLanguage.label(context, 'sensor_health')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              _SummaryCard(edge: edge, live: live),
              const SizedBox(height: 12),
              for (final spec in _specs) ...[
                _SensorHealthTile(
                  spec: spec,
                  edge: edge,
                  telemetry: telemetry,
                ),
                const SizedBox(height: 8),
              ],
              if (edge?.degradedAnalysis == true) ...[
                const SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FarmerLanguage.label(context, 'reduced_confidence'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if (edge!.degradedReasons.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final reason in edge.degradedReasons)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text('• ${FarmerLanguage.firmware(context, reason)}'),
                            ),
                        ] else if (edge.degradedReason != null) ...[
                          const SizedBox(height: 8),
                          Text(FarmerLanguage.firmware(context, edge.degradedReason)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final EdgeIntelligence? edge;
  final bool live;
  const _SummaryCard({required this.edge, required this.live});

  @override
  Widget build(BuildContext context) {
    final needsAttention = edge?.degradedAnalysis == true ||
        edge?.sensorFaults.isNotEmpty == true ||
        edge?.bioelectric.excludedByFirmware == true ||
        edge?.sensorStatus.values.any((v) => _bad(v)) == true;
    final color = needsAttention
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(needsAttention ? Icons.build_circle_outlined : Icons.verified_rounded,
                color: color, size: 34),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    needsAttention
                        ? FarmerLanguage.label(context, 'some_sensors_attention')
                        : FarmerLanguage.label(context, 'all_sensors_good'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(live ? 'ESP32 v8.7.1 hardware status' : 'Simulation sensor status'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spec {
  final String key;
  final String title;
  final List<String> aliases;
  const _Spec(this.key, this.title, this.aliases);
}

const _specs = <_Spec>[
  _Spec('airTemperature', 'Air temperature', ['airTemperature', 'temperature', 'air']),
  _Spec('humidity', 'Humidity', ['humidity', 'relativeHumidity']),
  _Spec('light', 'Light', ['light', 'lux']),
  _Spec('soilMoisture', 'Soil moisture', ['soilMoisture', 'soil', 'water']),
  _Spec('rootTemperature', 'Root temperature', ['rootTemperature', 'soilTemperature', 'rootZone']),
  _Spec('leafWetness', 'Leaf wetness', ['leafWetness', 'leaf']),
  _Spec('plantSignal', 'Bio electrodes', ['plantSignal', 'bioelectric', 'bio']),
];

class _SensorHealthTile extends StatelessWidget {
  final _Spec spec;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;
  const _SensorHealthTile({required this.spec, required this.edge, required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final detail = telemetry?.sensor(spec.key);
    final confidence = detail?.confidence ?? _confidence(edge, spec.aliases);
    String? status = detail?.status ?? _status(edge, spec.aliases);
    if (spec.key == 'plantSignal' && edge?.bioelectric.excludedByFirmware == true) {
      status = edge?.bioelectric.signalQualityState ?? edge?.bioelectric.stressState ?? 'CHECK CONTACT';
    }
    status ??= confidence == null ? 'UNAVAILABLE' : confidence >= 80 ? 'GOOD' : confidence >= 55 ? 'MODERATE' : 'CHECK';
    final bad = _bad(status);
    final color = bad ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
    return Card(
      child: ListTile(
        leading: Icon(bad ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: color),
        title: Text(spec.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: detail?.explanation == null ? null : Text(FarmerLanguage.firmware(context, detail!.explanation)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(FarmerLanguage.firmware(context, status), style: TextStyle(fontWeight: FontWeight.w900, color: color)),
            if (confidence != null) Text('${confidence.round()}%'),
          ],
        ),
      ),
    );
  }
}

double? _confidence(EdgeIntelligence? edge, List<String> aliases) {
  if (edge == null) return null;
  for (final item in edge.sensorConfidence) {
    if (aliases.any((a) => _norm(a) == _norm(item.channel))) return item.percent;
  }
  return null;
}

String? _status(EdgeIntelligence? edge, List<String> aliases) {
  if (edge == null) return null;
  for (final entry in edge.sensorStatus.entries) {
    if (aliases.any((a) => _norm(a) == _norm(entry.key))) return entry.value;
  }
  for (final item in edge.sensorConfidence) {
    if (aliases.any((a) => _norm(a) == _norm(item.channel)) && item.state != null) return item.state;
  }
  return null;
}

bool _bad(String raw) {
  final v = raw.toUpperCase().replaceAll(' ', '_');
  return v.contains('UNAVAILABLE') || v.contains('INVALID') || v.contains('CHECK') ||
      v.contains('NOISY') || v.contains('SATURATED') || v.contains('RAIL') ||
      v.contains('FAULT') || v.contains('CALIBRATE') || v.contains('LOW');
}

String _norm(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
