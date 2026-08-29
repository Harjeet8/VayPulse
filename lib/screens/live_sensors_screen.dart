import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import 'esp32_diagnostics_screen.dart';
import 'plant_intelligence_settings_screen.dart';

class LiveSensorsScreen extends StatelessWidget {
  const LiveSensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final reading = sensors.current;
        final edge = sensors.edgeIntelligence;
        final telemetry = sensors.hardwareTelemetry;
        return Scaffold(
          appBar: AppBar(
            title: Text(FarmerLanguage.label(context, 'live_sensors')),
            actions: [
              IconButton(
                tooltip: 'Plant Intelligence',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlantIntelligenceSettingsScreen(),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'System Diagnostics',
                icon: const Icon(Icons.monitor_heart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Esp32DiagnosticsScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              sensors.retry();
              await Future<void>.delayed(const Duration(milliseconds: 450));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                Text(
                  FarmerLanguage.label(context, 'live_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                if (sensors.connectionStatus != SensorConnectionStatus.ready)
                  _ConnectionCard(reading: reading),
                if (reading == null)
                  const _WaitingCard()
                else ...[
                  _OverallCard(reading: reading, edge: edge, telemetry: telemetry),
                  const SizedBox(height: 16),
                  _Section(
                    title: FarmerLanguage.label(context, 'air'),
                    icon: Icons.air_rounded,
                    cards: [
                      _SensorCard(
                        title: FarmerLanguage.label(context, 'air_temp'),
                        value: reading.temperatureAvailable
                            ? '${reading.temperature.toStringAsFixed(1)} °C'
                            : null,
                        detail: telemetry?.sensor('airTemperature'),
                        timestamp: reading.timestamp,
                      ),
                      _SensorCard(
                        title: FarmerLanguage.label(context, 'humidity'),
                        value: reading.humidityAvailable
                            ? '${reading.humidity.toStringAsFixed(0)} %'
                            : null,
                        detail: telemetry?.sensor('humidity'),
                        timestamp: reading.timestamp,
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'vpd'),
                        value: telemetry?.vpdKpa == null
                            ? null
                            : '${telemetry!.vpdKpa!.toStringAsFixed(2)} kPa',
                        result: _dryingDemand(context, telemetry?.vpdKpa),
                        note: FarmerLanguage.label(context, 'vpd_note'),
                      ),
                    ],
                  ),
                  _Section(
                    title: FarmerLanguage.label(context, 'light'),
                    icon: Icons.wb_sunny_outlined,
                    cards: [
                      _SensorCard(
                        title: FarmerLanguage.label(context, 'light_lux'),
                        value: reading.lightAvailable && reading.lightLux != null
                            ? '${reading.lightLux!.toStringAsFixed(0)} lux'
                            : null,
                        detail: telemetry?.sensor('light'),
                        timestamp: reading.timestamp,
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'day_phase'),
                        value: telemetry?.dayPhase ?? (reading.daytime ? 'DAY' : 'NIGHT'),
                        result: telemetry?.dayPhase ?? (reading.daytime ? 'DAY' : 'NIGHT'),
                      ),
                    ],
                  ),
                  _Section(
                    title: FarmerLanguage.label(context, 'soil_root'),
                    icon: Icons.grass_rounded,
                    cards: [
                      _SensorCard(
                        title: FarmerLanguage.label(context, 'soil_moisture'),
                        value: reading.soilMoistureAvailable
                            ? '${reading.soilMoisture.toStringAsFixed(0)} %'
                            : null,
                        detail: telemetry?.sensor('soilMoisture'),
                        timestamp: reading.timestamp,
                        extra: reading.soilCalibrated
                            ? 'Calibrated scale'
                            : 'Calibration not confirmed',
                      ),
                      _SensorCard(
                        title: FarmerLanguage.label(context, 'root_temp'),
                        value: reading.soilTemperatureAvailable &&
                                reading.soilTemperature != null
                            ? '${reading.soilTemperature!.toStringAsFixed(1)} °C'
                            : null,
                        detail: telemetry?.sensor('rootTemperature'),
                        timestamp: reading.timestamp,
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'air_root_delta'),
                        value: _airRootDelta(reading, telemetry),
                      ),
                    ],
                  ),
                  _Section(
                    title: FarmerLanguage.label(context, 'leaf'),
                    icon: Icons.eco_outlined,
                    cards: [
                      _SensorCard(
                        title: FarmerLanguage.label(context, 'leaf_wetness'),
                        value: reading.leafWetnessAvailable && reading.leafWetness != null
                            ? '${reading.leafWetness!.toStringAsFixed(0)} %'
                            : null,
                        detail: telemetry?.sensor('leafWetness'),
                        timestamp: reading.timestamp,
                        extra: reading.leafWetDurationSeconds > 0
                            ? '${FarmerLanguage.label(context, 'wet_duration')}: ${_duration(reading.leafWetDurationSeconds)}'
                            : null,
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'disease_risk'),
                        value: edge?.diseaseRiskScore != null
                            ? '${edge!.diseaseRiskScore!.round()} / 100'
                            : reading.diseaseRisk != null
                                ? '${reading.diseaseRisk!.round()} / 100'
                                : null,
                        result: edge?.diseaseRiskLevel,
                        note: FarmerLanguage.label(context, 'disease_note'),
                      ),
                    ],
                  ),
                  _Section(
                    title: FarmerLanguage.label(context, 'plant_signal'),
                    icon: Icons.electric_bolt_outlined,
                    cards: [
                      _SensorCard(
                        title: FarmerLanguage.label(context, 'bio_signal'),
                        value: reading.plantSignalAvailable && reading.plantVoltageMv != null
                            ? '${reading.plantVoltageMv!.toStringAsFixed(1)} mV'
                            : null,
                        detail: telemetry?.sensor('plantSignal'),
                        timestamp: reading.timestamp,
                        extra: _bioExtra(reading, telemetry),
                        note: FarmerLanguage.label(context, 'baseline_note'),
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'bio_baseline'),
                        value: reading.bioBaselineMv == null
                            ? null
                            : '${reading.bioBaselineMv!.toStringAsFixed(1)} mV',
                        result: reading.bioBaselineReady ? 'READY' : 'LEARNING_BASELINE',
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'bio_deviation'),
                        value: _bioDeviation(reading, telemetry),
                        result: telemetry?.sensor('plantSignal')?.result,
                      ),
                    ],
                  ),
                  _Section(
                    title: FarmerLanguage.label(context, 'intelligence'),
                    icon: Icons.psychology_alt_outlined,
                    cards: [
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'health_score'),
                        value: '${reading.healthScore.round()} / 100',
                        result: edge?.plantState ?? reading.healthStatus,
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'analysis_confidence'),
                        value: '${(edge?.overallConfidence ?? reading.analysisConfidence).round()} %',
                        result: FarmerLanguage.confidence(
                          context,
                          edge?.overallConfidence ?? reading.analysisConfidence,
                        ),
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'analysis_quality'),
                        value: telemetry?.analysisQuality,
                        result: edge?.degradedAnalysis == true
                            ? 'DEGRADED'
                            : telemetry?.analysisQuality,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverallCard extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;

  const _OverallCard({
    required this.reading,
    required this.edge,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    final crop = telemetry?.cropProfile ?? edge?.cropProfile.profile ?? 'Universal';
    final condition = FarmerLanguage.firmware(
      context,
      edge?.plantState ?? reading.healthStatus,
      fallback: 'Monitoring',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(crop,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _Summary(FarmerLanguage.label(context, 'plant_condition'), condition),
            _Summary(
              FarmerLanguage.label(context, 'main_finding'),
              FarmerLanguage.firmware(
                context,
                edge?.rootCause.primary ?? edge?.farmerSummary,
                fallback: FarmerLanguage.label(context, 'no_problem'),
              ),
            ),
            if (edge?.rootCause.secondary != null)
              _Summary(
                FarmerLanguage.label(context, 'secondary_finding'),
                FarmerLanguage.firmware(context, edge!.rootCause.secondary),
              ),
            _Summary(
              FarmerLanguage.label(context, 'analysis_confidence'),
              FarmerLanguage.confidence(
                context,
                edge?.overallConfidence ?? reading.analysisConfidence,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> cards;

  const _Section({required this.title, required this.icon, required this.cards});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            ...cards.expand((card) => [card, const SizedBox(height: 8)]),
          ],
        ),
      );
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String? value;
  final HardwareSensorDetail? detail;
  final DateTime timestamp;
  final String? extra;
  final String? note;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.timestamp,
    this.extra,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final available = value != null;
    final result = available
        ? FarmerLanguage.firmware(
            context,
            detail?.result ?? detail?.status,
            fallback: FarmerLanguage.label(context, 'no_interpretation'),
          )
        : FarmerLanguage.label(context, 'unavailable');
    final trend = detail?.trend == null
        ? FarmerLanguage.label(context, 'no_trend')
        : FarmerLanguage.firmware(context, detail!.trend);
    final confidence = detail?.confidence == null
        ? FarmerLanguage.label(context, 'no_confidence')
        : '${detail!.confidence!.round()}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(value ?? '—',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${FarmerLanguage.label(context, 'result')}: $result',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Meta('${FarmerLanguage.label(context, 'trend')}: $trend'),
                _Meta('${FarmerLanguage.label(context, 'confidence')}: $confidence'),
                _Meta('${FarmerLanguage.label(context, 'data_age')}: ${_age(timestamp)}'),
                if (detail?.ratePerHour != null)
                  _Meta('${FarmerLanguage.label(context, 'rate')}: ${_signed(detail!.ratePerHour!)} /h'),
              ],
            ),
            if (extra != null) ...[
              const SizedBox(height: 8),
              Text(extra!),
            ],
            if (detail?.explanation != null) ...[
              const SizedBox(height: 8),
              Text(FarmerLanguage.firmware(context, detail!.explanation)),
            ],
            if (detail?.contribution != null) ...[
              const SizedBox(height: 8),
              Text(
                '${FarmerLanguage.label(context, 'effect')}: ${FarmerLanguage.firmware(context, detail!.contribution)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 8),
              Text(note!, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (detail?.rawValue != null || detail?.quality != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(FarmerLanguage.label(context, 'technical')),
                children: [
                  if (detail?.rawValue != null)
                    _Technical(FarmerLanguage.label(context, 'raw'),
                        detail!.rawValue!.toStringAsFixed(0)),
                  if (detail?.quality != null)
                    _Technical('Quality / noise', detail!.quality!),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DerivedCard extends StatelessWidget {
  final String title;
  final String? value;
  final String? result;
  final String? note;

  const _DerivedCard({this.title = '', this.value, this.result, this.note});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(value ?? '—',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(
                '${FarmerLanguage.label(context, 'result')}: ${result == null ? FarmerLanguage.label(context, 'no_interpretation') : FarmerLanguage.firmware(context, result)}',
              ),
              if (note != null) ...[
                const SizedBox(height: 7),
                Text(note!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      );
}

class _Summary extends StatelessWidget {
  final String label;
  final String value;
  const _Summary(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _Meta extends StatelessWidget {
  final String text;
  const _Meta(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600),
      );
}

class _Technical extends StatelessWidget {
  final String label;
  final String value;
  const _Technical(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

class _ConnectionCard extends StatelessWidget {
  final SensorReading? reading;
  const _ConnectionCard({required this.reading});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.portable_wifi_off_rounded,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(reading == null
                  ? FarmerLanguage.label(context, 'disconnected')
                  : '${FarmerLanguage.label(context, 'disconnected')} • ${FarmerLanguage.label(context, 'last_reading')}: ${_time(reading!.timestamp)}'),
            ),
          ]),
        ),
      );
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard();
  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 14),
            Expanded(child: Text('Waiting for live ESP32 measurements…')),
          ]),
        ),
      );
}

String? _airRootDelta(SensorReading r, HardwareTelemetry? t) {
  if (t?.airRootDeltaC != null) return '${_signed(t!.airRootDeltaC!)} °C';
  if (!r.temperatureAvailable || !r.soilTemperatureAvailable || r.soilTemperature == null) {
    return null;
  }
  return '${_signed(r.temperature - r.soilTemperature!)} °C';
}

String? _bioDeviation(SensorReading r, HardwareTelemetry? t) {
  if (t?.bioelectricDeviationPercent != null) {
    return '${_signed(t!.bioelectricDeviationPercent!)} %';
  }
  if (r.bioBaselineMv == null || r.plantVoltageMv == null || r.bioBaselineMv == 0) {
    return null;
  }
  return '${_signed(((r.plantVoltageMv! - r.bioBaselineMv!) / r.bioBaselineMv!) * 100)} %';
}

String? _bioExtra(SensorReading r, HardwareTelemetry? t) {
  final parts = <String>[];
  if (r.bioBaselineMv != null) {
    parts.add('Baseline: ${r.bioBaselineMv!.toStringAsFixed(1)} mV');
  }
  final d = _bioDeviation(r, t);
  if (d != null) parts.add('Deviation: $d');
  if (r.bioNoiseMv != null) parts.add('Noise: ${r.bioNoiseMv!.toStringAsFixed(1)} mV');
  return parts.isEmpty ? null : parts.join(' • ');
}

String? _dryingDemand(BuildContext context, double? vpd) {
  if (vpd == null) return null;
  if (vpd < 0.5) return FarmerLanguage.isTamil(context) ? 'குறைந்த drying demand' : 'Low drying demand';
  if (vpd < 1.2) return FarmerLanguage.isTamil(context) ? 'வசதியான drying demand' : 'Comfortable drying demand';
  if (vpd < 1.8) return FarmerLanguage.isTamil(context) ? 'நடுத்தர drying demand' : 'Moderate drying demand';
  if (vpd < 2.5) return FarmerLanguage.isTamil(context) ? 'அதிக drying demand' : 'High drying demand';
  return FarmerLanguage.isTamil(context) ? 'மிக அதிக drying demand' : 'Very high drying demand';
}

String _age(DateTime timestamp) {
  final age = DateTime.now().difference(timestamp);
  if (age.inSeconds < 5) return 'now';
  if (age.inMinutes < 1) return '${age.inSeconds}s';
  return '${age.inMinutes}m';
}

String _duration(double seconds) {
  if (seconds < 60) return '${seconds.round()} sec';
  if (seconds < 3600) return '${(seconds / 60).round()} min';
  return '${(seconds / 3600).toStringAsFixed(1)} h';
}

String _signed(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(value.abs() >= 10 ? 1 : 2)}';

String _time(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
