import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/data_source_card.dart';
import '../widgets/health_ring.dart';
import '../widgets/insight_card.dart';
import '../widgets/page_frame.dart';
import '../widgets/sensor_card.dart';
import '../widgets/phyto_ui.dart';
import 'leaf_screening_screen.dart';

class LiveNodeHomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAlerts;

  const LiveNodeHomeScreen({super.key, this.onOpenAlerts});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;
    final reading = sensors.current;
    final node = sensors.nodes.isEmpty ? null : sensors.nodes.first;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [phytoGreen, phytoLeaf]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.memory_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(context.tr('live_node_dashboard'))),
          ],
        ),
        actions: [
          Badge(
            isLabelVisible: scope.alerts.unreadCount > 0,
            label: Text('${scope.alerts.unreadCount}'),
            child: IconButton(
              tooltip: context.tr('alerts_title'),
              onPressed: onOpenAlerts,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          sensors.retry();
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
        child: PageFrame(
          children: [
            const DataSourceCard(),
            const SizedBox(height: 14),
            _LiveSessionCard(
              endpoint: scope.sensorManager.hardwareEndpoint,
              status: sensors.connectionStatus,
              node: node,
              reading: reading,
              onReconnect: sensors.retry,
            ),
            const SizedBox(height: 18),
            if (reading == null)
              _WaitingCard(
                status: sensors.connectionStatus,
                errorKey: sensors.errorMessage,
                onReconnect: sensors.retry,
              )
            else ...[
              _HealthSummary(reading: reading, node: node),
              const SizedBox(height: 22),
              _SectionTitle(title: context.tr('validated_reading')),
              const SizedBox(height: 12),
              _LiveSensorGrid(reading: reading),
              const SizedBox(height: 22),
              if (!reading.isReliabilityFull ||
                  !reading.hasFullCoreReading) ...[
                _PartialHardwareCard(reading: reading),
                const SizedBox(height: 22),
              ],
              _SectionTitle(title: context.tr('ai_field_insight')),
              const SizedBox(height: 12),
              if (reading.edgeAnalysisAvailable)
                InsightCard(
                  title: _edgeText(reading.healthStatus),
                  message: reading.primaryRootCause.isEmpty
                      ? 'The ESP32 did not report a primary root cause.'
                      : _edgeText(reading.primaryRootCause),
                  action: reading.farmerAction.isEmpty
                      ? '${context.tr('recommended_action')}: Awaiting ESP32 guidance.'
                      : '${context.tr('recommended_action')}: ${reading.farmerAction}',
                  accent: reading.healthStatus.toUpperCase() == 'CRITICAL'
                      ? Theme.of(context).colorScheme.error
                      : reading.healthStatus.toUpperCase() == 'STRESS' ||
                            reading.healthStatus.toUpperCase() == 'WATCH'
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.primary,
                ),
              if (reading.edgeAnalysisAvailable) ...[
                const SizedBox(height: 12),
                _EvidenceCard(
                  evidence: reading.rankedRootCauses.isEmpty
                      ? reading.primaryRootCause
                      : reading.rankedRootCauses.map(_edgeText).join(' • '),
                  confidence:
                      reading.rootCauseConfidence ?? reading.analysisConfidence,
                  reliabilityMode: reading.reliabilityMode,
                ),
              ] else
                _PartialAnalysisCard(reading: reading),
              if (_FarmerEdgeSignals.shouldShow(reading)) ...[
                const SizedBox(height: 10),
                _FarmerEdgeSignals(reading: reading),
              ],
              if (reading.cameraRecommended) ...[
                const SizedBox(height: 14),
                _PhotoPrompt(
                  reason: reading.cameraReason.isEmpty
                      ? reading.bioticState
                      : reading.cameraReason,
                  crop: reading.crop,
                ),
              ],
              const SizedBox(height: 14),
              _CropReferenceCard(
                crop: reading.crop,
                growthStage: reading.growthStage,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  final String endpoint;
  final SensorConnectionStatus status;
  final SensorNode? node;
  final SensorReading? reading;
  final VoidCallback onReconnect;

  const _LiveSessionCard({
    required this.endpoint,
    required this.status,
    required this.node,
    required this.reading,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final freshness = _Freshness.from(reading?.timestamp);
    final color = switch (freshness) {
      _Freshness.fresh => Theme.of(context).colorScheme.primary,
      _Freshness.delayed => Theme.of(context).colorScheme.tertiary,
      _Freshness.stale => Theme.of(context).colorScheme.error,
      _Freshness.waiting => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF123528), Color(0xFF0D2119)]
              : const [Color(0xFF0C5C41), Color(0xFF197653)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF376B54)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LivePulseDot(
                      color: color,
                      size: 8,
                      animate:
                          freshness == _Freshness.fresh &&
                          !AppScope.of(context).settings.value.reducedMotion,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.tr('live_session_badge'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: context.tr('reconnect'),
                onPressed: onReconnect,
                icon: const Icon(Icons.refresh_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            node?.name ?? context.tr('live_node_name'),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('live_session_body'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SessionChip(
                icon: status == SensorConnectionStatus.ready
                    ? Icons.wifi_tethering_rounded
                    : Icons.portable_wifi_off_rounded,
                label: context.tr(switch (status) {
                  SensorConnectionStatus.ready => 'online',
                  SensorConnectionStatus.loading => 'waiting',
                  SensorConnectionStatus.offline => 'offline',
                  SensorConnectionStatus.error => 'needs_attention',
                }),
              ),
              _SessionChip(
                icon: Icons.schedule_rounded,
                label: context.tr(freshness.key),
              ),
              _SessionChip(
                icon: Icons.security_rounded,
                label: context.tr(
                  reading == null ? 'waiting_validation' : 'range_validated',
                ),
              ),
              if (node != null)
                _SessionChip(
                  icon: Icons.network_cell_rounded,
                  label: '${node!.signalPercent}%',
                ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lan_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('endpoint')}: $endpoint',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SessionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _WaitingCard extends StatelessWidget {
  final SensorConnectionStatus status;
  final String? errorKey;
  final VoidCallback onReconnect;

  const _WaitingCard({
    required this.status,
    required this.errorKey,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            status == SensorConnectionStatus.loading
                ? Icons.sync_rounded
                : Icons.portable_wifi_off_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('live_waiting_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(errorKey ?? 'live_waiting_body'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReconnect,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('reconnect')),
          ),
        ],
      ),
    ),
  );
}

class _HealthSummary extends StatelessWidget {
  final SensorReading reading;
  final SensorNode? node;

  const _HealthSummary({required this.reading, required this.node});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESP32 CROP PROFILE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${reading.crop} • ${reading.growthStage}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(context.tr('live_health_body')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Meta(
                    icon: Icons.battery_5_bar_rounded,
                    value: '${node?.batteryPercent ?? 0}%',
                  ),
                  _Meta(
                    icon: Icons.network_cell_rounded,
                    value: '${node?.signalPercent ?? 0}%',
                  ),
                  _Meta(
                    icon: Icons.schedule_rounded,
                    value: context.tr(_Freshness.from(reading.timestamp).key),
                  ),
                ],
              ),
            ],
          );
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          if (constraints.maxWidth < 430 || textScale > 1.35) {
            return Column(
              children: [
                _EdgeHealthIndicator(reading: reading),
                const SizedBox(height: 18),
                Align(alignment: Alignment.centerLeft, child: info),
              ],
            );
          }
          return Row(
            children: [
              _EdgeHealthIndicator(reading: reading),
              const SizedBox(width: 20),
              Expanded(child: info),
            ],
          );
        },
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String value;

  const _Meta({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 5),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _EdgeHealthIndicator extends StatelessWidget {
  final SensorReading reading;

  const _EdgeHealthIndicator({required this.reading});

  @override
  Widget build(BuildContext context) {
    if (reading.edgeAnalysisAvailable) {
      return HealthRing(
        score: reading.healthScore,
        label: context.tr('health_score'),
      );
    }
    return SizedBox(
      width: 126,
      child: Column(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          const Text(
            'ESP32 analysis unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PartialHardwareCard extends StatelessWidget {
  final SensorReading reading;

  const _PartialHardwareCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final connected = <String>[
      if (reading.temperatureAvailable) 'temperature',
      if (reading.humidityAvailable) 'humidity',
      if (reading.soilMoistureAvailable) 'soil moisture',
      if (reading.lightAvailable) 'light',
      if (reading.bioPlantUseAllowed) 'plant signal',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cable_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${reading.reliabilityMode} reliability',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Live ${connected.isEmpty ? 'channels are recovering' : connected.join(' + ')} received from the ESP32. '
                    'Unavailable or rejected channels are never replaced with simulated values.'
                    '${reading.recoveryStatus.isEmpty ? '' : ' ${_edgeText(reading.recoveryStatus)}.'}',
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

class _PartialAnalysisCard extends StatelessWidget {
  final SensorReading reading;

  const _PartialAnalysisCard({required this.reading});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.science_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'The ESP32 has not published a health decision yet. '
              'Status: ${_edgeText(reading.systemStatus.isEmpty ? reading.reliabilityMode : reading.systemStatus)}. '
              'The app will not calculate a replacement hardware diagnosis.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _UnavailableSensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _UnavailableSensorCard({
    required this.icon,
    required this.title,
    this.message = 'Not connected yet',
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(
            '—',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LiveSensorGrid extends StatelessWidget {
  final SensorReading reading;

  const _LiveSensorGrid({required this.reading});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1.0);
      final effectiveWidth = constraints.maxWidth / textScale;
      final columns = effectiveWidth >= 760
          ? 3
          : effectiveWidth >= 430
          ? 2
          : 1;
      const spacing = 10.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      final cards = <Widget>[
        if (reading.soilMoistureAvailable)
          SensorCard(
            icon: Icons.water_drop_outlined,
            title: context.tr('soil_moisture'),
            value: reading.soilMoisture.toStringAsFixed(0),
            numericValue: reading.soilMoisture,
            unit: '%',
            preferredRange: context.tr('preferred_soil_range'),
            animate: !AppScope.of(context).settings.value.reducedMotion,
            status: context.tr('range_validated'),
            accent: const Color(0xFF2F80C1),
          )
        else
          _UnavailableSensorCard(
            icon: Icons.water_drop_outlined,
            title: context.tr('soil_moisture'),
            message: _sensorState(reading, 'soilMoisture'),
          ),
        if (reading.temperatureAvailable)
          SensorCard(
            icon: Icons.thermostat_outlined,
            title: context.tr('temperature'),
            value: reading.temperature.toStringAsFixed(1),
            numericValue: reading.temperature,
            unit: '°C',
            decimals: 1,
            preferredRange: context.tr('preferred_temperature_range'),
            animate: !AppScope.of(context).settings.value.reducedMotion,
            status: context.tr('range_validated'),
            accent: phytoTerracotta,
          )
        else
          _UnavailableSensorCard(
            icon: Icons.thermostat_outlined,
            title: context.tr('temperature'),
            message: _sensorState(reading, 'temperature'),
          ),
        if (reading.humidityAvailable)
          SensorCard(
            icon: Icons.water_outlined,
            title: context.tr('humidity'),
            value: reading.humidity.toStringAsFixed(0),
            numericValue: reading.humidity,
            unit: '%',
            preferredRange: context.tr('preferred_humidity_range'),
            animate: !AppScope.of(context).settings.value.reducedMotion,
            status: context.tr('range_validated'),
            accent: const Color(0xFF377B99),
          )
        else
          _UnavailableSensorCard(
            icon: Icons.water_outlined,
            title: context.tr('humidity'),
            message: _sensorState(reading, 'humidity'),
          ),
        if (reading.lightAvailable)
          SensorCard(
            icon: Icons.light_mode_outlined,
            title: context.tr('light'),
            value: reading.light.toStringAsFixed(0),
            numericValue: reading.light,
            unit: '%',
            preferredRange: context.tr('preferred_light_range'),
            animate: !AppScope.of(context).settings.value.reducedMotion,
            status: context.tr('range_validated'),
            accent: phytoAmber,
          )
        else
          _UnavailableSensorCard(
            icon: Icons.light_mode_outlined,
            title: context.tr('light'),
            message: _sensorState(reading, 'light'),
          ),
        if (reading.bioPlantUseAllowed)
          SensorCard(
            icon: Icons.monitor_heart_outlined,
            title: context.tr('plant_signal'),
            value: reading.plantSignal.toStringAsFixed(0),
            numericValue: reading.plantSignal,
            unit: '%',
            preferredRange: context.tr('preferred_signal_range'),
            animate: !AppScope.of(context).settings.value.reducedMotion,
            status: context.tr('electrode_input'),
            accent: Theme.of(context).colorScheme.primary,
          )
        else
          _UnavailableSensorCard(
            icon: Icons.monitor_heart_outlined,
            title: context.tr('plant_signal'),
            message:
                reading.bioElectricalMeasurementAvailable &&
                    reading.hasBioContactTelemetry
                ? _FarmerEdgeSignals.bioContactWarning(reading)
                : _sensorState(reading, 'plantSignal'),
          ),
        if (reading.edgeAnalysisAvailable)
          SensorCard(
            icon: Icons.warning_amber_rounded,
            title: context.tr('stress'),
            value: reading.stressScore.toStringAsFixed(0),
            numericValue: reading.stressScore,
            unit: '%',
            preferredRange: context.tr('preferred_stress_range'),
            animate: !AppScope.of(context).settings.value.reducedMotion,
            status: _edgeText(reading.healthStatus),
            accent: reading.stressScore > 55
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          )
        else
          _UnavailableSensorCard(
            icon: Icons.warning_amber_rounded,
            title: context.tr('stress'),
            message: 'ESP32 analysis unavailable',
          ),
      ];
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final card in cards) SizedBox(width: width, child: card),
        ],
      );
    },
  );
}

class _EvidenceCard extends StatelessWidget {
  final String evidence;
  final double? confidence;
  final String reliabilityMode;

  const _EvidenceCard({
    required this.evidence,
    required this.confidence,
    required this.reliabilityMode,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('why_this'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (confidence != null)
                Text(context.tr('confidence', {'value': confidence!.round()})),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            evidence.isEmpty
                ? 'No ranked root cause was published by the ESP32.'
                : evidence,
          ),
          const SizedBox(height: 6),
          Text('Reliability: $reliabilityMode'),
          const SizedBox(height: 9),
          Text(
            context.tr('decision_support_note'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _FarmerEdgeSignals extends StatelessWidget {
  final SensorReading reading;

  const _FarmerEdgeSignals({required this.reading});

  static double _confidencePercent(double? value) {
    if (value == null || !value.isFinite) return 0;
    return value <= 1 ? value * 100 : value;
  }

  static bool _predictionVisible(SensorReading reading) =>
      reading.predictionAvailable &&
      _confidencePercent(reading.predictionConfidence) >= 65 &&
      (reading.predictionMessage.trim().isNotEmpty ||
          (reading.predictionMinutesToWarning != null &&
              reading.predictionTarget.trim().isNotEmpty));

  static bool _hasRecoveryState(SensorReading reading) {
    final state = reading.recoveryStatus.trim().toUpperCase();
    return reading.recoveryVerified ||
        const {
          'CONDITIONS_IMPROVING',
          'IMPROVING',
          'RECOVERING',
          'RECOVERY_VERIFIED',
          'VERIFIED',
        }.contains(state);
  }

  static String _recoveryText(BuildContext context, SensorReading reading) {
    final state = reading.recoveryStatus.trim().toUpperCase();
    if (reading.recoveryVerified ||
        state == 'RECOVERY_VERIFIED' ||
        state == 'VERIFIED') {
      return reading.recoveryFarmerResult.trim().isNotEmpty
          ? reading.recoveryFarmerResult.trim()
          : context.tr('edge_recovery_verified');
    }
    if (state.isEmpty || state == 'NONE') return '';
    if (state == 'CONDITIONS_IMPROVING' || state == 'IMPROVING') {
      return context.tr('edge_recovery_improving');
    }
    if (state == 'RECOVERING') {
      final progress = reading.recoveryProgressPct;
      return progress == null
          ? context.tr('edge_recovery_in_progress')
          : context.tr('edge_recovery_progress', {
              'value': progress.clamp(0, 100).round(),
            });
    }
    return '';
  }

  static String bioContactWarning(SensorReading reading) {
    if (!reading.hasBioContactTelemetry) return '';
    final state = reading.normalizedBioContactState;
    if (reading.bioPlantUseAllowed && state == 'PLAUSIBLE') return '';

    switch (state) {
      case 'OPEN':
        return 'Electrodes open — check plant contact';
      case 'UNSTABLE':
        return 'Electrode contact unstable';
      case 'STATIC':
      case 'SHORT_SUSPECTED':
        return 'Static/test input — excluded from plant analysis';
      case 'VERIFY':
        return 'Verifying electrode contact';
      case 'SATURATED':
        return 'Bio sensor saturated — check electrode/amplifier connection';
    }

    if (reading.bioContactPlausibleForPlantUse == false ||
        reading.bioAffectsHealth == false) {
      return 'Verify electrode contact';
    }
    return '';
  }

  static String _systemWarning(SensorReading reading) {
    final contactWarning = bioContactWarning(reading);
    if (contactWarning.isNotEmpty) return contactWarning;

    // Existing degraded/partial hardware presentation already owns the single
    // farmer-facing quality warning in these states.
    if (!reading.isReliabilityFull || !reading.hasFullCoreReading) return '';

    final integrity = reading.sensorIntegrityState.trim().toUpperCase();
    if (integrity.isNotEmpty &&
        !const {'FULL', 'CLEAR', 'GOOD', 'OK'}.contains(integrity)) {
      if (reading.sensorIntegrityPrimaryAction.trim().isNotEmpty) {
        return reading.sensorIntegrityPrimaryAction.trim();
      }
      if (reading.sensorIntegrityPrimaryIssue.trim().isNotEmpty) {
        return reading.sensorIntegrityPrimaryIssue.trim();
      }
    }

    final plausibility = reading.plausibilityState.trim().toUpperCase();
    if (plausibility.isNotEmpty &&
        !const {'CLEAR', 'GOOD', 'NORMAL', 'OK'}.contains(plausibility)) {
      if (reading.plausibilityRecommendation.trim().isNotEmpty) {
        return reading.plausibilityRecommendation.trim();
      }
      if (reading.plausibilityPrimaryIssue.trim().isNotEmpty) {
        return reading.plausibilityPrimaryIssue.trim();
      }
    }

    final runtime = reading.runtimeHealthState.trim().toUpperCase();
    if (const {'WATCH', 'DEGRADED', 'FAULT'}.contains(runtime) &&
        reading.runtimeHealthIssue.trim().isNotEmpty) {
      return reading.runtimeHealthIssue.trim();
    }
    return '';
  }

  static bool shouldShow(SensorReading reading) =>
      (!reading.plantModelReady &&
          reading.plantModelStatus.trim().toUpperCase() == 'LEARNING') ||
      _predictionVisible(reading) ||
      _hasRecoveryState(reading) ||
      _systemWarning(reading).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final predictionVisible = _predictionVisible(reading);
    final recovery = _recoveryText(context, reading);
    final warning = _systemWarning(reading);
    final learning =
        !reading.plantModelReady &&
        reading.plantModelStatus.trim().toUpperCase() == 'LEARNING';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (learning)
            _CompactEdgeLine(
              icon: Icons.auto_awesome_outlined,
              text: context.tr('edge_learning_plant'),
            ),
          if (predictionVisible)
            _CompactEdgeLine(
              icon: Icons.trending_up_rounded,
              text: reading.predictionMessage.trim().isNotEmpty
                  ? reading.predictionMessage.trim()
                  : context.tr('edge_prediction_fallback', {
                      'target': _edgeText(reading.predictionTarget),
                      'minutes': reading.predictionMinutesToWarning ?? '—',
                    }),
            ),
          if (recovery.isNotEmpty)
            _CompactEdgeLine(
              icon: reading.recoveryVerified
                  ? Icons.verified_rounded
                  : Icons.healing_rounded,
              text: recovery,
            ),
          if (warning.isNotEmpty)
            _CompactEdgeLine(
              icon: Icons.build_circle_outlined,
              text: warning,
              warning: true,
            ),
        ],
      ),
    );
  }
}

class _CompactEdgeLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warning;

  const _CompactEdgeLine({
    required this.icon,
    required this.text,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: warning ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPrompt extends StatelessWidget {
  final String reason;
  final String crop;

  const _PhotoPrompt({required this.reason, required this.crop});

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('disease_photo_prompt_title'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            reason.isEmpty
                ? 'The ESP32 recommends a leaf photo for visual screening.'
                : _edgeText(reason),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeafScreeningScreen(
                    sensorPrompt: true,
                    initialCrop: crop,
                  ),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(context.tr('disease_take_photo_action')),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CropReferenceCard extends StatelessWidget {
  final String crop;
  final String growthStage;

  const _CropReferenceCard({required this.crop, required this.growthStage});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.verified_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$crop leaf-screening context',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  'Camera screening will use the ESP32-confirmed $crop profile and $growthStage stage.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeafScreeningScreen(initialCrop: crop),
                    ),
                  ),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(context.tr('scan_leaf')),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w900),
  );
}

enum _Freshness {
  fresh('data_fresh'),
  delayed('data_delayed'),
  stale('data_stale'),
  waiting('waiting');

  final String key;
  const _Freshness(this.key);

  static _Freshness from(DateTime? timestamp) {
    if (timestamp == null) return _Freshness.waiting;
    final age = DateTime.now().difference(timestamp);
    if (age <= const Duration(seconds: 8)) return _Freshness.fresh;
    if (age <= const Duration(seconds: 20)) return _Freshness.delayed;
    return _Freshness.stale;
  }
}

String _sensorState(SensorReading reading, String key) {
  final state = reading.sensorStates[key];
  return state == null || state.isEmpty ? 'Unavailable' : _edgeText(state);
}

String _edgeText(String value) {
  final text = value.trim().replaceAll('_', ' ');
  if (text.isEmpty) return 'Awaiting ESP32 status';
  if (text != text.toUpperCase()) return text;
  return text
      .toLowerCase()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
