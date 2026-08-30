import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/data_source_card.dart';
import '../widgets/biotic_stress_card.dart';
import '../widgets/page_frame.dart';
import 'leaf_screening_screen.dart';
import 'plant_intelligence_settings_screen.dart';

class LiveNodeHomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAlerts;

  const LiveNodeHomeScreen({super.key, this.onOpenAlerts});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;
    final reading = sensors.current;
    final edge = sensors.edgeIntelligence;
    final telemetry = sensors.hardwareTelemetry;
    final live = sensors.source == SensorDataSource.esp32;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: phytoGreen),
            SizedBox(width: 9),
            Flexible(child: Text('PhytoSense AI')),
          ],
        ),
        actions: [
          if (live)
            IconButton(
              tooltip: 'Plant Intelligence',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlantIntelligenceSettingsScreen(),
                ),
              ),
              icon: const Icon(Icons.tune_rounded),
            ),
          Badge(
            isLabelVisible: scope.alerts.unreadCount > 0,
            label: Text('${scope.alerts.unreadCount}'),
            child: IconButton(
              tooltip: context.tr('alerts_title'),
              onPressed: onOpenAlerts,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          sensors.retry();
          await Future<void>.delayed(const Duration(milliseconds: 450));
        },
        child: PageFrame(
          children: [
            const DataSourceCard(),
            const SizedBox(height: 10),
            _ConnectionStrip(
              status: sensors.connectionStatus,
              timestamp: reading?.timestamp,
              onRetry: sensors.retry,
              live: live,
            ),
            const SizedBox(height: 14),
            if (edge?.firmwareCompatible == false)
              const _FirmwareCompatibilityCard()
            else if (reading == null)
              _WaitingCard(onRetry: sensors.retry, live: live)
            else ...[
              _ConditionCard(reading: reading, edge: edge, telemetry: telemetry),
              if (edge?.bioelectric.hasData == true) ...[
                const SizedBox(height: 12),
                _PlantResponseCard(bio: edge!.bioelectric),
              ],
              if (edge?.bioticStress.suspected == true) ...[
                const SizedBox(height: 12),
                BioticStressCard(
                  info: edge!.bioticStress,
                  onScan: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeafScreeningScreen(
                        sensorPrompt: true,
                      ),
                    ),
                  ),
                ),
              ],
              if (edge?.cameraInspectionRecommended == true &&
                  edge?.bioticStress.suspected != true) ...[
                const SizedBox(height: 12),
                _CameraHandoffCard(
                  edge: edge!,
                  onScan: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeafScreeningScreen(
                        sensorPrompt: true,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _WhatChangedCard(edge: edge),
              if (edge?.degradedAnalysis == true || edge?.sensorFaults.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _CoverageCard(edge: edge!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FirmwareCompatibilityCard extends StatelessWidget {
  const _FirmwareCompatibilityCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.system_update_alt_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FarmerLanguage.label(context, 'firmware_compatibility_title'),
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    FarmerLanguage.label(context, 'firmware_compatibility_body'),
                    style: TextStyle(color: colors.onErrorContainer),
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

class _ConditionCard extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;

  const _ConditionCard({
    required this.reading,
    required this.edge,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    final rawState = edge?.plantState ?? reading.healthStatus;
    final recovering = edge?.recovery.active == true || rawState.toUpperCase() == 'RECOVERING';
    final possibleBiotic = edge?.bioticStress.suspected == true;
    final title = recovering
        ? FarmerLanguage.label(context, 'recovering_title')
        : FarmerLanguage.firmware(context, rawState).toUpperCase();
    final main = possibleBiotic
        ? FarmerLanguage.label(context, 'possible_biotic_title')
        : edge?.rootCause.primary ??
            edge?.farmerSummary ??
            edge?.bioelectric.farmerResult;
    final secondary = possibleBiotic ? null : edge?.rootCause.secondary;
    final action = recovering
        ? FarmerLanguage.label(context, 'recovery_action')
        : possibleBiotic
            ? FarmerLanguage.firmware(
                context,
                edge?.bioticStress.recommendation,
                fallback:
                    FarmerLanguage.label(context, 'biotic_inspect_action'),
              )
            : edge?.recommendation ??
                FarmerLanguage.label(context, 'keep_monitoring');
    final confidence = edge?.overallConfidence ?? reading.esp32HealthConfidence ?? reading.analysisConfidence;
    final trend = _conditionTrend(context, edge);
    final severity = _severity(context, edge?.urgency, rawState, recovering);
    final summary = recovering
        ? FarmerLanguage.firmware(
            context,
            edge?.recovery.farmerResult ?? edge?.recovery.improved,
            fallback: FarmerLanguage.label(context, 'recovery_summary'),
          )
        : FarmerLanguage.firmware(
            context,
            edge?.farmerSummary ?? main,
            fallback: FarmerLanguage.label(context, 'no_problem'),
          );
    final accent = recovering
        ? Theme.of(context).colorScheme.primary
        : _stateColor(context, rawState);
    final crop = telemetry?.cropProfile ?? edge?.cropProfile.profile;
    final stage = telemetry?.growthStage ?? edge?.cropProfile.growthStage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.16), Theme.of(context).colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
          ),
          if (main != null && main.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _RankedCause(
              label: FarmerLanguage.label(context, 'main_problem'),
              value: FarmerLanguage.firmware(context, main),
            ),
          ],
          if (secondary != null && secondary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _RankedCause(
              label: FarmerLanguage.label(context, 'making_it_worse'),
              value: FarmerLanguage.firmware(context, secondary),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FarmerLanguage.label(context, 'do_this_now'),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  FarmerLanguage.firmware(context, action),
                  style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (crop != null && crop.trim().isNotEmpty)
                _Pill(
                  Icons.grass_rounded,
                  '${FarmerLanguage.label(context, 'crop_profile')}: ${FarmerLanguage.firmware(context, crop)}',
                  accent,
                ),
              if (stage != null && stage.trim().isNotEmpty)
                _Pill(
                  Icons.eco_outlined,
                  '${FarmerLanguage.label(context, 'growth_stage')}: ${FarmerLanguage.firmware(context, stage)}',
                  accent,
                ),
              _Pill(Icons.priority_high_rounded,
                  '${FarmerLanguage.label(context, 'severity')}: $severity', accent),
              _Pill(Icons.verified_outlined,
                  '${FarmerLanguage.label(context, 'confidence')}: ${FarmerLanguage.confidence(context, confidence)}', accent),
              _Pill(Icons.trending_up_rounded,
                  '${FarmerLanguage.label(context, 'trend')}: $trend', accent),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showWhy(context, edge),
              icon: const Icon(Icons.help_outline_rounded),
              label: Text(FarmerLanguage.label(context, 'why_button')),
            ),
          ),
          if (edge?.recovery.active == true && edge?.recovery.durationSeconds != null) ...[
            const SizedBox(height: 8),
            Text(
              '${FarmerLanguage.label(context, 'recovery_time')}: ${_duration(edge!.recovery.durationSeconds!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  void _showWhy(BuildContext context, EdgeIntelligence? edge) {
    final evidence = _evidence(context, edge);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FarmerLanguage.label(context, 'why_title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (evidence.isEmpty)
                Text(FarmerLanguage.label(context, 'why_unavailable'))
              else
                for (final item in evidence.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 19),
                        const SizedBox(width: 9),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantResponseCard extends StatelessWidget {
  final BioelectricIntelligence bio;
  const _PlantResponseCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    final excluded = bio.excludedByFirmware;
    final learning = !excluded && bio.learningBaseline;
    final state = excluded
        ? FarmerLanguage.label(context, 'signal_unavailable')
        : learning
            ? FarmerLanguage.label(context, 'learning_baseline')
            : _plantResponse(context, bio);
    final result = FarmerLanguage.firmware(
      context,
      excluded ? bio.interpretation : bio.farmerResult ?? bio.interpretation,
      fallback: excluded
          ? FarmerLanguage.label(context, 'bio_signal_check_electrodes')
          : learning
              ? FarmerLanguage.label(context, 'bio_learning_body')
              : FarmerLanguage.label(context, 'plant_response_no_result'),
    );
    return Card(
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
              child: Icon(Icons.electric_bolt_rounded,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(FarmerLanguage.label(context, 'plant_response'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(state,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(result),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children: [
                      if (bio.confidence != null)
                        Text('${FarmerLanguage.label(context, 'confidence')}: ${FarmerLanguage.confidence(context, bio.confidence)}'),
                      if (bio.trend != null)
                        Text('${FarmerLanguage.label(context, 'trend')}: ${FarmerLanguage.firmware(context, bio.trend)}'),
                      if (bio.persistenceSeconds != null)
                        Text('${FarmerLanguage.label(context, 'persistent_for')}: ${_duration(bio.persistenceSeconds!)}'),
                      if (bio.includedInFusion != null)
                        Text(
                          bio.includedInFusion!
                              ? FarmerLanguage.label(context, 'included_in_analysis')
                              : FarmerLanguage.label(context, 'excluded_from_analysis'),
                        ),
                    ],
                  ),
                  if (learning && bio.baselineSamples != null) ...[
                    const SizedBox(height: 9),
                    Text(
                      bio.baselineTarget == null
                          ? '${FarmerLanguage.label(context, 'baseline_samples')}: ${bio.baselineSamples}'
                          : '${FarmerLanguage.label(context, 'baseline_progress')}: ${bio.baselineSamples}/${bio.baselineTarget}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (bio.baselineTarget != null && bio.baselineTarget! > 0) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (bio.baselineSamples! / bio.baselineTarget!)
                            .clamp(0.0, 1.0),
                      ),
                    ],
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

class _CameraHandoffCard extends StatelessWidget {
  final EdgeIntelligence edge;
  final VoidCallback onScan;

  const _CameraHandoffCard({required this.edge, required this.onScan});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FarmerLanguage.label(context, 'visual_inspection_recommended'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                FarmerLanguage.firmware(
                  context,
                  edge.cameraHandoff.reason ??
                      edge.cameraHandoff.recommendation,
                  fallback: FarmerLanguage.label(
                    context,
                    'visual_inspection_body',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    FarmerLanguage.label(context, 'scan_plant_camera'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

class _WhatChangedCard extends StatelessWidget {
  final EdgeIntelligence? edge;
  const _WhatChangedCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final items = _changes(context, edge);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(FarmerLanguage.label(context, 'what_changed'),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(FarmerLanguage.label(context, 'no_change'))
            else
              for (final item in items.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right_rounded, size: 20),
                      const SizedBox(width: 5),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  final EdgeIntelligence edge;
  const _CoverageCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final issue = edge.sensorFaults.isNotEmpty
        ? edge.sensorFaults.first
        : null;
    final text = issue?.explanation ?? edge.degradedReason;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sensors_off_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(FarmerLanguage.label(context, 'sensor_attention'),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(FarmerLanguage.firmware(
                    context,
                    text,
                    fallback: FarmerLanguage.label(context, 'degraded_body'),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedCause extends StatelessWidget {
  final String label;
  final String value;
  const _RankedCause({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      );
}

class _ConnectionStrip extends StatelessWidget {
  final SensorConnectionStatus status;
  final DateTime? timestamp;
  final VoidCallback onRetry;
  final bool live;

  const _ConnectionStrip({
    required this.status,
    required this.timestamp,
    required this.onRetry,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final ready = status == SensorConnectionStatus.ready;
    return Card(
      child: ListTile(
        dense: true,
        leading: Icon(
          ready ? Icons.wifi_tethering_rounded : Icons.portable_wifi_off_rounded,
          color: ready ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
        ),
        title: Text(
          ready
              ? (live
                  ? FarmerLanguage.label(context, 'esp32_connected')
                  : FarmerLanguage.label(context, 'simulation_active'))
              : (live
                  ? FarmerLanguage.label(context, 'disconnected')
                  : FarmerLanguage.label(context, 'simulation_waiting')),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: timestamp == null
            ? null
            : Text('${FarmerLanguage.label(context, 'last_reading')}: ${_time(timestamp!)}'),
        trailing: IconButton(
          tooltip: context.tr('reconnect'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final VoidCallback onRetry;
  final bool live;
  const _WaitingCard({required this.onRetry, required this.live});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(
                FarmerLanguage.label(
                  context,
                  live ? 'waiting_esp32' : 'simulation_waiting',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('reconnect')),
              ),
            ],
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Pill(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800))),
          ],
        ),
      );
}

List<String> _changes(BuildContext context, EdgeIntelligence? edge) {
  if (edge == null) return const [];
  if (edge.recovery.active || edge.plantState?.toUpperCase() == 'RECOVERING') {
    return [
      FarmerLanguage.firmware(
        context,
        edge.recovery.improved ?? edge.recovery.farmerResult,
        fallback: FarmerLanguage.label(context, 'recovery_summary'),
      )
    ];
  }
  return edge.trends
      .where((item) {
        final state = item.state?.toUpperCase() ?? '';
        return state.isNotEmpty && state != 'STABLE' && state != 'NORMAL';
      })
      .map((item) => '${_friendlyChannel(context, item.channel)}: ${FarmerLanguage.firmware(context, item.state)}')
      .take(3)
      .toList(growable: false);
}

List<String> _evidence(BuildContext context, EdgeIntelligence? edge) {
  if (edge == null) return const [];
  final result = <String>[];
  void add(String? value) {
    if (value == null || value.trim().isEmpty) return;
    final clean = FarmerLanguage.firmware(context, value);
    if (!result.contains(clean)) result.add(clean);
  }

  add(edge.rootCause.primary);
  add(edge.rootCause.primaryCandidate?.evidenceFor);
  final counterEvidence = edge.rootCause.primaryCandidate?.evidenceAgainst;
  if (counterEvidence != null) {
    add('Counter-evidence: $counterEvidence');
  }
  add(edge.rootCause.secondary);
  add(edge.rootCause.secondaryCandidate?.evidenceFor);
  if (edge.bioelectric.corroborated == true && edge.bioelectric.corroboratedBy.isNotEmpty) {
    result.add('${FarmerLanguage.label(context, 'plant_response_supported_by')}: ${edge.bioelectric.corroboratedBy.map((e) => _friendlyChannel(context, e)).join(', ')}');
  }
  for (final trend in edge.trends.where((t) => t.state != null)) {
    result.add('${_friendlyChannel(context, trend.channel)}: ${FarmerLanguage.firmware(context, trend.state)}');
    if (result.length >= 4) break;
  }
  if (result.length < 4) add(edge.decisionExplanation);
  return result;
}

String _conditionTrend(BuildContext context, EdgeIntelligence? edge) {
  if (edge?.recovery.active == true || edge?.plantState?.toUpperCase() == 'RECOVERING') {
    return FarmerLanguage.label(context, 'recovering');
  }
  final health = edge?.trends.where((t) => t.channel.toLowerCase().contains('health')).firstOrNull;
  if (health?.state != null) return _farmerTrend(context, health!.state!);
  final bioTrend = edge?.bioelectric.trend;
  if (bioTrend != null) {
    final upper = bioTrend.toUpperCase();
    if (upper.contains('RISING_FAST') || upper.contains('RISING_QUICK')) {
      return FarmerLanguage.label(context, 'getting_worse_quickly');
    }
    if (upper.contains('RISING')) return FarmerLanguage.label(context, 'getting_worse');
    if (upper.contains('FALLING')) return FarmerLanguage.label(context, 'improving');
  }
  return FarmerLanguage.label(context, 'stable');
}

String _farmerTrend(BuildContext context, String raw) {
  final value = raw.toUpperCase();
  if (value.contains('IMPROV') || value.contains('RISING')) return FarmerLanguage.label(context, 'improving');
  if (value.contains('WORSE') || value.contains('FALLING_FAST')) return FarmerLanguage.label(context, 'getting_worse_quickly');
  if (value.contains('FALLING')) return FarmerLanguage.label(context, 'getting_worse');
  return FarmerLanguage.label(context, 'stable');
}

String _severity(BuildContext context, String? urgency, String state, bool recovering) {
  if (recovering) return FarmerLanguage.label(context, 'low');
  final value = (urgency ?? state).toUpperCase();
  if (value.contains('CRITICAL') || value.contains('HIGH') || value.contains('URGENT')) {
    return FarmerLanguage.label(context, 'high');
  }
  if (value.contains('WATCH') || value.contains('ATTENTION') || value.contains('STRESS')) {
    return FarmerLanguage.label(context, 'medium');
  }
  return FarmerLanguage.label(context, 'low');
}

String _plantResponse(BuildContext context, BioelectricIntelligence bio) {
  if (bio.available == false) return FarmerLanguage.label(context, 'signal_unavailable');
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

String _friendlyChannel(BuildContext context, String raw) {
  final value = raw.toLowerCase();
  if (value.contains('soil') && value.contains('moist')) return FarmerLanguage.label(context, 'soil_moisture');
  if (value.contains('vpd') || value.contains('drying')) return FarmerLanguage.label(context, 'air_drying');
  if (value.contains('bio') || value.contains('plant')) return FarmerLanguage.label(context, 'plant_response');
  if (value.contains('root') && value.contains('temp')) return FarmerLanguage.label(context, 'root_temp');
  if (value.contains('air') && value.contains('temp')) return FarmerLanguage.label(context, 'air_temp');
  if (value.contains('humid')) return FarmerLanguage.label(context, 'humidity');
  if (value.contains('leaf')) return FarmerLanguage.label(context, 'leaf_wetness');
  return raw.replaceAll('_', ' ');
}

Color _stateColor(BuildContext context, String raw) {
  final value = raw.toUpperCase();
  if (value.contains('CRITICAL')) return Theme.of(context).colorScheme.error;
  if (value.contains('STRESS') || value.contains('WATCH') || value.contains('ATTENTION')) {
    return Theme.of(context).colorScheme.tertiary;
  }
  return Theme.of(context).colorScheme.primary;
}

String _duration(double seconds) {
  if (seconds < 60) return '${seconds.round()} sec';
  if (seconds < 3600) return '${(seconds / 60).round()} min';
  return '${(seconds / 3600).toStringAsFixed(1)} h';
}

String _time(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
