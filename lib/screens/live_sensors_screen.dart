import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/live_motion.dart';
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
        final live = sensors.source == SensorDataSource.esp32;
        return Scaffold(
          appBar: AppBar(
            title: Text(FarmerLanguage.label(context, 'live_sensors')),
            actions: [
              if (live) ...[
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
                  _ConnectionCard(reading: reading, live: live),
                if (reading == null)
                  _WaitingCard(live: live)
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
                        value: (telemetry?.vpdKpa ?? edge?.derivedEnvironment.vpdKpa) == null
                            ? null
                            : '${(telemetry?.vpdKpa ?? edge!.derivedEnvironment.vpdKpa)!.toStringAsFixed(2)} kPa',
                        result: telemetry?.sensor('vpd')?.result ?? telemetry?.sensor('airDryingDemand')?.result,
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
                      _BioelectricCard(
                        reading: reading,
                        edge: edge,
                        telemetry: telemetry,
                      ),
                    ],
                  ),
                  _Section(
                    title: FarmerLanguage.label(context, 'intelligence'),
                    icon: Icons.psychology_alt_outlined,
                    cards: [
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'health_score'),
                        value: _healthValue(reading, edge),
                        result: edge?.plantState ??
                            (edge?.hasAuthoritativeAnalysis == true
                                ? null
                                : reading.healthStatus),
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'analysis_confidence'),
                        value: _confidenceValue(reading, edge),
                        result: FarmerLanguage.confidence(
                          context,
                          _confidenceNumber(reading, edge),
                        ),
                      ),
                      _DerivedCard(
                        title: FarmerLanguage.label(context, 'analysis_quality'),
                        value: edge?.analysisQuality ?? telemetry?.analysisQuality,
                        result: edge?.degradedAnalysis == true
                            ? 'DEGRADED'
                            : edge?.analysisQuality ?? telemetry?.analysisQuality,
                        note: edge?.degradedReasons.isNotEmpty == true
                            ? edge!.degradedReasons.join(' • ')
                            : edge?.degradedReason,
                      ),
                      if (edge?.cropProfile.regionProfile != null)
                        _DerivedCard(
                          title: 'Region profile',
                          value: edge!.cropProfile.regionProfile,
                          result: edge.cropProfile.regionProfile,
                        ),
                      if (edge?.waterBalance.hasData == true)
                        _DerivedCard(
                          title: 'Water balance',
                          value: edge!.waterBalance.score == null
                              ? edge.waterBalance.state
                              : '${edge.waterBalance.score!.round()} / 100',
                          result: edge.waterBalance.state,
                          note: edge.waterBalance.explanation,
                        ),
                      if (edge?.cameraHandoff.hasData == true)
                        _DerivedCard(
                          title: 'Camera handoff',
                          value: edge!.cameraHandoff.recommended == true
                              ? 'RECOMMENDED'
                              : 'NOT RECOMMENDED',
                          result: edge.cameraHandoff.reason,
                          note: edge.cameraHandoff.recommendation,
                        ),
                      if (edge?.compoundStress.hasData == true)
                        _DerivedCard(
                          title: 'Compound stress',
                          value: edge!.compoundStress.state,
                          result: edge.compoundStress.severity == null
                              ? edge.compoundStress.state
                              : '${edge.compoundStress.severity!.round()} / 100',
                          note: 'ESP32 confidence-weighted combination of measured stress evidence.',
                        ),
                      if (edge?.prediction.hasData == true)
                        _DerivedCard(
                          title: 'Trend prediction',
                          value: edge!.prediction.message ?? edge.prediction.explanation,
                          result: edge.prediction.available == false
                              ? 'UNAVAILABLE'
                              : edge.prediction.state,
                          note: edge.prediction.available == false
                              ? 'The ESP32 did not find a stable enough trend for a reliable prediction.'
                              : null,
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

String? _healthValue(SensorReading reading, EdgeIntelligence? edge) {
  final value = edge?.hasAuthoritativeAnalysis == true
      ? edge?.healthScore
      : (edge?.healthScore ?? reading.esp32HealthScore ?? reading.healthScore);
  return value == null ? null : '${value.round()} / 100';
}

double? _confidenceNumber(SensorReading reading, EdgeIntelligence? edge) {
  if (edge?.hasAuthoritativeAnalysis == true) return edge?.overallConfidence;
  return edge?.overallConfidence ??
      reading.esp32HealthConfidence ??
      reading.analysisConfidence;
}

String? _confidenceValue(SensorReading reading, EdgeIntelligence? edge) {
  final value = _confidenceNumber(reading, edge);
  return value == null ? null : '${value.round()} %';
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
                _confidenceNumber(reading, edge),
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
                LiveMotionIcon(
                  icon: icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
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

  const _SensorCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.timestamp,
    this.extra,
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

    return LiveDataMotion(
      signature: '$title|$value|$result|$trend|$confidence',
      child: Card(
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
                if (detail?.ratePerHour == null && detail?.ratePerMinute != null)
                  _Meta('${FarmerLanguage.label(context, 'rate')}: ${_signed(detail!.ratePerMinute!)} /min'),
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
            if (detail?.rawValue != null ||
                detail?.quality != null ||
                detail?.shortSlopePerMinute != null ||
                detail?.longSlopePerMinute != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(FarmerLanguage.label(context, 'technical')),
                children: [
                  if (detail?.rawValue != null)
                    _Technical(FarmerLanguage.label(context, 'raw'),
                        detail!.rawValue!.toStringAsFixed(0)),
                  if (detail?.quality != null)
                    _Technical('Quality / noise', detail!.quality!),
                  if (detail?.shortSlopePerMinute != null)
                    _Technical(
                      'Short trend slope',
                      '${_signed(detail!.shortSlopePerMinute!)} /min',
                    ),
                  if (detail?.longSlopePerMinute != null)
                    _Technical(
                      'Long trend slope',
                      '${_signed(detail!.longSlopePerMinute!)} /min',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _BioelectricCard extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;

  const _BioelectricCard({
    required this.reading,
    required this.edge,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    final bio = edge?.bioelectric;
    final detail = telemetry?.sensor('plantSignal');
    final available = !(bio?.excludedByFirmware ?? false) &&
        (bio?.available ??
            (reading.plantSignalAvailable && reading.plantVoltageMv != null));
    final result = available
        ? FarmerLanguage.firmware(
            context,
            bio?.farmerResult ?? detail?.result,
            fallback: FarmerLanguage.label(context, 'no_interpretation'),
          )
        : FarmerLanguage.label(context, 'unavailable');
    final state = available
        ? _bioState(context, bio)
        : FarmerLanguage.label(context, 'signal_unavailable');
    final trend = bio?.trend ?? detail?.trend;
    final confidence = bio?.confidence ?? detail?.confidence;
    final persistence = bio?.persistenceSeconds;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FarmerLanguage.label(context, 'plant_electrical_response'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              state,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (available &&
                !(bio?.learningBaseline ?? false) &&
                bio?.stressScore != null) ...[
              const SizedBox(height: 4),
              Text(
                '${FarmerLanguage.label(context, 'stress_score')}: ${bio!.stressScore!.round()} / 100',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${FarmerLanguage.label(context, 'result')}: $result',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Meta(
                  '${FarmerLanguage.label(context, 'trend')}: ${trend == null ? FarmerLanguage.label(context, 'no_trend') : FarmerLanguage.firmware(context, trend)}',
                ),
                _Meta(
                  '${FarmerLanguage.label(context, 'confidence')}: ${confidence == null ? FarmerLanguage.label(context, 'no_confidence') : '${confidence.round()}%'}',
                ),
                if (persistence != null)
                  _Meta(
                    '${FarmerLanguage.label(context, 'persistent_for')}: ${_duration(persistence)}',
                  ),
                if (bio?.corroborated == true)
                  _Meta(
                    '${FarmerLanguage.label(context, 'plant_response_supported_by')}: ${bio!.corroboratedBy.isEmpty ? 'ESP32 sensor fusion' : bio.corroboratedBy.join(', ')}',
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              FarmerLanguage.label(context, 'baseline_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(FarmerLanguage.label(context, 'technical')),
              children: [
                _Technical(
                  'Voltage',
                  bio?.voltageMv != null
                      ? '${bio!.voltageMv!.toStringAsFixed(1)} mV'
                      : reading.plantVoltageMv != null
                          ? '${reading.plantVoltageMv!.toStringAsFixed(1)} mV'
                          : '—',
                ),
                _Technical(
                  'Learned baseline',
                  bio?.baselineMv != null
                      ? '${bio!.baselineMv!.toStringAsFixed(1)} mV'
                      : reading.bioBaselineMv != null
                          ? '${reading.bioBaselineMv!.toStringAsFixed(1)} mV'
                          : '—',
                ),
                _Technical(
                  'Signed change',
                  bio?.signedChangeMv == null
                      ? '—'
                      : '${_signed(bio!.signedChangeMv!)} mV',
                ),
                _Technical(
                  'Normalized deviation',
                  bio?.normalizedDeviation == null
                      ? '—'
                      : '${_signed(bio!.normalizedDeviation!)} %',
                ),
                _Technical(
                  'Noise',
                  bio?.noiseMv != null
                      ? '${bio!.noiseMv!.toStringAsFixed(1)} mV'
                      : reading.bioNoiseMv != null
                          ? '${reading.bioNoiseMv!.toStringAsFixed(1)} mV'
                          : '—',
                ),
                _Technical(
                  'Signal quality',
                  bio?.signalQuality != null
                      ? '${bio!.signalQuality!.round()}%'
                      : '${reading.bioSignalQuality.round()}%',
                ),
                if (bio?.signalQualityState != null)
                  _Technical('Signal quality state', bio!.signalQualityState!),
                if (bio?.stressLoadState != null)
                  _Technical('Stress load state', bio!.stressLoadState!),
                if (bio?.stressLoad != null)
                  _Technical('Stress load', bio!.stressLoad!.toStringAsFixed(1)),
                if (bio?.baselineReady != null)
                  _Technical(
                    'Baseline ready',
                    bio!.baselineReady! ? 'Yes' : 'No',
                  ),
                if (bio?.baselineSamples != null)
                  _Technical(
                    'Baseline samples',
                    bio!.baselineTarget == null
                        ? '${bio.baselineSamples}'
                        : '${bio.baselineSamples}/${bio.baselineTarget}',
                  ),
                if (bio?.zScore != null)
                  _Technical('Z-score', bio!.zScore!.toStringAsFixed(2)),
                if (bio?.spanMv != null)
                  _Technical('Signal span', '${bio!.spanMv!.toStringAsFixed(1)} mV'),
                if (bio?.includedInFusion != null)
                  _Technical(
                    'Included in fusion',
                    bio!.includedInFusion! ? 'Yes' : 'No',
                  ),
                if (bio?.interpretation != null)
                  _Technical('Firmware interpretation', bio!.interpretation!),
                if (bio?.baselineLearningPaused != null)
                  _Technical(
                    'Baseline learning',
                    bio!.baselineLearningPaused! ? 'Paused' : 'Active',
                  ),
                if (bio?.rawAdc != null)
                  _Technical('Raw ADC', bio!.rawAdc!.toStringAsFixed(0)),
                if (detail?.rawValue != null)
                  _Technical(
                    FarmerLanguage.label(context, 'raw'),
                    detail!.rawValue!.toStringAsFixed(0),
                  ),
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

String _bioState(BuildContext context, BioelectricIntelligence? bio) {
  if (bio == null || bio.excludedByFirmware) {
    return FarmerLanguage.label(context, 'signal_unavailable');
  }
  if (bio.learningBaseline) {
    return FarmerLanguage.label(context, 'learning_baseline');
  }
  final state = bio.stressState?.toUpperCase() ?? '';
  if (state.contains('RECOVER')) return FarmerLanguage.label(context, 'recovering');
  if (state.contains('STRONG') || (bio.stressScore != null && bio.stressScore! >= 80)) {
    return FarmerLanguage.label(context, 'strongly_stressed');
  }
  if (state.contains('STRESS') || (bio.stressScore != null && bio.stressScore! >= 55)) {
    return FarmerLanguage.label(context, 'stressed');
  }
  if (state.contains('MILD') || (bio.stressScore != null && bio.stressScore! >= 30)) {
    return FarmerLanguage.label(context, 'mild_response');
  }
  return FarmerLanguage.label(context, 'calm');
}

class _DerivedCard extends StatelessWidget {
  final String title;
  final String? value;
  final String? result;
  final String? note;

  const _DerivedCard({this.title = '', this.value, this.result, this.note});

  @override
  Widget build(BuildContext context) => LiveDataMotion(
        signature: '$title|$value|$result|$note',
        child: Card(
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
  final bool live;
  const _ConnectionCard({required this.reading, required this.live});

  @override
  Widget build(BuildContext context) {
    final label = FarmerLanguage.label(
      context,
      live ? 'disconnected' : 'simulation_waiting',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              live ? Icons.portable_wifi_off_rounded : Icons.hourglass_top_rounded,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reading == null
                    ? label
                    : '$label • ${FarmerLanguage.label(context, 'last_reading')}: ${_time(reading!.timestamp)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
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

String? _airRootDelta(SensorReading r, HardwareTelemetry? t) {
  if (t?.airRootDeltaC != null) return '${_signed(t!.airRootDeltaC!)} °C';
  if (!r.temperatureAvailable || !r.soilTemperatureAvailable || r.soilTemperature == null) {
    return null;
  }
  return '${_signed(r.temperature - r.soilTemperature!)} °C';
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
