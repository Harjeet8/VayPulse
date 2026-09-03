import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';

/// Additive competition-grade intelligence surfaces.
///
/// These widgets never create a diagnosis. They only visualize readings,
/// events and decisions already produced by the active provider/ESP32.
class CompetitionIntelligencePanels extends StatelessWidget {
  final SensorReading current;
  final List<SensorReading> history;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;
  final bool live;
  final SensorConnectionStatus connectionStatus;

  const CompetitionIntelligencePanels({
    super.key,
    required this.current,
    required this.history,
    required this.edge,
    required this.telemetry,
    required this.live,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final recent = _recentHistory(history, current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompetitionStateHaptics(
          live: live,
          plantState: edge?.plantState ?? current.healthStatus,
          recoveryActive: edge?.recovery.active == true || current.recoveryActive,
        ),
        const SizedBox(height: 12),
        PlantStressTimelineCard(history: recent, current: current),
        const SizedBox(height: 12),
        BioelectricPulseCard(
          history: recent,
          current: current,
          bio: edge?.bioelectric,
        ),
        if (edge != null) ...[
          const SizedBox(height: 12),
          FusionEvidenceCard(edge: edge!),
          const SizedBox(height: 12),
          PlantStateJourneyCard(history: recent, edge: edge!),
        ],
        const SizedBox(height: 12),
        ReliabilityGuardCard(
          current: current,
          edge: edge,
          telemetry: telemetry,
          live: live,
          connectionStatus: connectionStatus,
        ),
      ],
    );
  }
}

class CompetitionStateHaptics extends StatefulWidget {
  final bool live;
  final String? plantState;
  final bool recoveryActive;

  const CompetitionStateHaptics({
    super.key,
    required this.live,
    required this.plantState,
    required this.recoveryActive,
  });

  @override
  State<CompetitionStateHaptics> createState() => _CompetitionStateHapticsState();
}

class _CompetitionStateHapticsState extends State<CompetitionStateHaptics> {
  String? _lastState;
  bool? _lastRecovery;

  @override
  void initState() {
    super.initState();
    _lastState = _normalized(widget.plantState);
    _lastRecovery = widget.recoveryActive;
  }

  @override
  void didUpdateWidget(covariant CompetitionStateHaptics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.live) {
      _lastState = _normalized(widget.plantState);
      _lastRecovery = widget.recoveryActive;
      return;
    }
    final next = _normalized(widget.plantState);
    final stateChanged = next.isNotEmpty && next != _lastState;
    final recoveryStarted = widget.recoveryActive && _lastRecovery != true;
    if (stateChanged || recoveryStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final urgent = next.contains('CRITICAL') || next.contains('HIGH');
        if (urgent) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      });
    }
    _lastState = next;
    _lastRecovery = widget.recoveryActive;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class PlantStressTimelineCard extends StatelessWidget {
  final List<SensorReading> history;
  final SensorReading current;

  const PlantStressTimelineCard({
    super.key,
    required this.history,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final stress = history.map((r) => r.stressScore).toList(growable: false);
    final soil = history
        .where((r) => r.soilMoistureAvailable)
        .map((r) => r.soilMoisture)
        .toList(growable: false);
    final vpd = history
        .where((r) => r.vpdKpa != null)
        .map((r) => r.vpdKpa!)
        .toList(growable: false);
    final health = history.map((r) => r.healthScore).toList(growable: false);

    return _CompetitionCard(
      icon: Icons.timeline_rounded,
      title: tamil ? 'நேரடி stress timeline' : 'Live plant stress timeline',
      subtitle: tamil
          ? 'அண்மைய validated readings — diagnosis மாற்றாமல்.'
          : 'Recent validated readings — visualization only, no extra diagnosis.',
      child: Column(
        children: [
          _SparkMetric(
            label: tamil ? 'மொத்த stress' : 'Overall stress',
            valueText: '${current.stressScore.round()}/100',
            values: stress,
            minY: 0,
            maxY: 100,
          ),
          const SizedBox(height: 11),
          _SparkMetric(
            label: tamil ? 'மண் ஈரம்' : 'Soil moisture',
            valueText: current.soilMoistureAvailable
                ? '${current.soilMoisture.toStringAsFixed(0)}%'
                : '—',
            values: soil,
            minY: 0,
            maxY: 100,
          ),
          if (vpd.isNotEmpty) ...[
            const SizedBox(height: 11),
            _SparkMetric(
              label: 'VPD',
              valueText: '${(current.vpdKpa ?? vpd.last).toStringAsFixed(2)} kPa',
              values: vpd,
            ),
          ],
          const SizedBox(height: 11),
          _SparkMetric(
            label: tamil ? 'Health index' : 'Health index',
            valueText: '${current.healthScore.round()}/100',
            values: health,
            minY: 0,
            maxY: 100,
          ),
        ],
      ),
    );
  }
}

class BioelectricPulseCard extends StatelessWidget {
  final List<SensorReading> history;
  final SensorReading current;
  final BioelectricIntelligence? bio;

  const BioelectricPulseCard({
    super.key,
    required this.history,
    required this.current,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final directVoltage = history
        .where((r) => r.plantSignalAvailable && r.plantVoltageMv != null)
        .map((r) => r.plantVoltageMv!)
        .toList(growable: false);
    final stability = history
        .where((r) => r.plantSignalAvailable)
        .map((r) => r.plantSignal)
        .toList(growable: false);
    final useVoltage = directVoltage.length >= 3;
    final values = useVoltage ? directVoltage : stability;
    final info = bio;
    final excluded = info?.excludedByFirmware == true;
    final learning = info?.learningBaseline == true && !excluded;
    final accent = excluded
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return _CompetitionCard(
      icon: Icons.electric_bolt_rounded,
      title: tamil ? 'Plant electrical pulse' : 'Plant electrical pulse',
      subtitle: excluded
          ? (tamil
              ? 'Signal quality பாதுகாப்பு active — இந்த channel fusion-ல் இல்லை.'
              : 'Signal-quality protection active — this channel is excluded from fusion.')
          : learning
              ? (tamil
                  ? 'இந்த செடியின் இயல்பான electrical baseline கற்றுக்கொள்ளப்படுகிறது.'
                  : "Learning this plant's normal electrical signature.")
              : (useVoltage
                  ? (tamil
                      ? 'AD620 plant-signal history மற்றும் firmware bio intelligence.'
                      : 'AD620 plant-signal history with firmware bio intelligence.')
                  : (tamil
                      ? 'Firmware-derived bioelectric stability history.'
                      : 'Firmware-derived bioelectric stability history.')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (values.length >= 2)
            SizedBox(
              height: 96,
              child: _MiniLineChart(values: values, accent: accent),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(tamil ? 'மேலும் samples தேவை' : 'Waiting for more samples'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: tamil ? 'Source' : 'Source',
                value: current.bioSourceLabel,
                accent: accent,
              ),
              _MetricChip(
                label: tamil ? 'Signal' : 'Signal',
                value: info?.signalQualityState ??
                    (current.plantSignalAvailable ? 'AVAILABLE' : 'UNAVAILABLE'),
                accent: accent,
              ),
              if (info?.signalQuality != null)
                _MetricChip(
                  label: tamil ? 'Quality' : 'Quality',
                  value: '${info!.signalQuality!.round()}%',
                  accent: accent,
                ),
              if (info?.baselineMv != null)
                _MetricChip(
                  label: tamil ? 'Baseline' : 'Baseline',
                  value: '${info!.baselineMv!.toStringAsFixed(1)} mV',
                  accent: accent,
                ),
              if (info?.normalizedDeviation != null)
                _MetricChip(
                  label: tamil ? 'Deviation' : 'Deviation',
                  value: '${info!.normalizedDeviation!.toStringAsFixed(1)}%',
                  accent: accent,
                ),
              if (info?.stressScore != null)
                _MetricChip(
                  label: tamil ? 'Bio stress' : 'Bio stress',
                  value: '${info!.stressScore!.toStringAsFixed(0)}/100',
                  accent: accent,
                ),
              if (info?.trend != null)
                _MetricChip(
                  label: tamil ? 'Trend' : 'Trend',
                  value: info!.trend!.replaceAll('_', ' '),
                  accent: accent,
                ),
            ],
          ),
          if (learning && info?.baselineSamples != null) ...[
            const SizedBox(height: 13),
            Text(
              info?.baselineTarget == null
                  ? '${tamil ? 'Baseline samples' : 'Baseline samples'}: ${info!.baselineSamples}'
                  : '${tamil ? 'Baseline learning' : 'Baseline learning'}: ${info!.baselineSamples}/${info.baselineTarget}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (info.baselineTarget != null && info.baselineTarget! > 0) ...[
              const SizedBox(height: 7),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                tween: Tween(
                  begin: 0,
                  end: (info.baselineSamples! / info.baselineTarget!)
                      .clamp(0.0, 1.0)
                      .toDouble(),
                ),
                builder: (context, value, _) =>
                    LinearProgressIndicator(value: value, minHeight: 7),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class FusionEvidenceCard extends StatelessWidget {
  final EdgeIntelligence edge;

  const FusionEvidenceCard({super.key, required this.edge});

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final evidence = <_EvidenceItem>[
      if (edge.stressEvidence.water != null)
        _EvidenceItem(tamil ? 'நீர் stress' : 'Water stress', edge.stressEvidence.water!),
      if (edge.stressEvidence.heat != null)
        _EvidenceItem(tamil ? 'வெப்ப stress' : 'Heat stress', edge.stressEvidence.heat!),
      if (edge.stressEvidence.rootZone != null)
        _EvidenceItem(tamil ? 'Root-zone' : 'Root-zone', edge.stressEvidence.rootZone!),
      if (edge.derivedEnvironment.airDryingDemand != null)
        _EvidenceItem(
          tamil ? 'Air drying demand' : 'Air drying demand',
          edge.derivedEnvironment.airDryingDemand!,
        ),
      if (edge.stressEvidence.diseaseEnvironment != null)
        _EvidenceItem(
          tamil ? 'Disease-conducive' : 'Disease-conducive',
          edge.stressEvidence.diseaseEnvironment!,
        ),
    ];
    final root = edge.rootCause.primaryCandidate;
    final confidence = root?.confidence ?? edge.overallConfidence;

    return _CompetitionCard(
      icon: Icons.hub_rounded,
      title: tamil ? 'ESP32 evidence fusion' : 'ESP32 evidence fusion',
      subtitle: tamil
          ? 'ஒவ்வொரு signal-ம் இறுதி முடிவை எவ்வாறு ஆதரிக்கிறது என்பதை காட்டுகிறது.'
          : 'Shows how reported evidence supports the firmware decision.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (edge.rootCause.primary != null) ...[
            Text(
              tamil ? 'Main finding' : 'Main finding',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              child: Text(
                edge.rootCause.primary!,
                key: ValueKey(edge.rootCause.primary),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            if (confidence != null) ...[
              const SizedBox(height: 5),
              Text('${tamil ? 'Confidence' : 'Confidence'}: ${_percent(confidence).round()}%'),
            ],
            const SizedBox(height: 14),
          ],
          if (evidence.isNotEmpty)
            for (var i = 0; i < evidence.length; i++) ...[
              _AnimatedEvidenceBar(item: evidence[i], index: i),
              if (i != evidence.length - 1) const SizedBox(height: 10),
            ]
          else
            Text(
              tamil
                  ? 'இந்த firmware packet-ல் quantitative evidence scores இல்லை.'
                  : 'No quantitative evidence scores were reported in this firmware packet.',
            ),
          if (root?.evidenceFor != null || root?.evidenceAgainst != null) ...[
            const SizedBox(height: 14),
            if (root?.evidenceFor != null)
              _EvidenceText(
                icon: Icons.check_circle_outline_rounded,
                label: tamil ? 'ஆதாரம்' : 'Supporting evidence',
                text: root!.evidenceFor!,
              ),
            if (root?.evidenceAgainst != null) ...[
              const SizedBox(height: 9),
              _EvidenceText(
                icon: Icons.balance_rounded,
                label: tamil ? 'எதிர் ஆதாரம்' : 'Counter-evidence',
                text: root!.evidenceAgainst!,
              ),
            ],
          ],
          if (edge.sensorConfidence.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              tamil ? 'Sensor confidence' : 'Sensor confidence',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: edge.sensorConfidence
                  .take(6)
                  .map(
                    (item) => _MetricChip(
                      label: _friendlyChannel(item.channel),
                      value: item.percent == null
                          ? (item.state ?? 'reported')
                          : '${item.percent!.round()}%',
                      accent: Theme.of(context).colorScheme.primary,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tamil
                      ? 'Flutter இந்த முடிவை மறுபடியும் diagnose செய்யாது; live mode-ல் ESP32 முடிவையே காட்டுகிறது.'
                      : 'Flutter does not re-diagnose this result; live mode displays the ESP32 decision.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlantStateJourneyCard extends StatelessWidget {
  final List<SensorReading> history;
  final EdgeIntelligence edge;

  const PlantStateJourneyCard({
    super.key,
    required this.history,
    required this.edge,
  });

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final journey = _buildJourney(history, edge);
    final visible = journey.length <= 4
        ? journey
        : journey.sublist(journey.length - 4);
    return _CompetitionCard(
      icon: Icons.route_rounded,
      title: tamil ? 'சமீபத்திய செடி மாற்றங்கள்' : 'Recent plant changes',
      subtitle: tamil
          ? 'சமீபத்திய அளவீடுகளில் செடியின் நிலை எப்படி மாறியது.'
          : 'How the plant condition changed over recent readings.',
      child: journey.isEmpty
          ? Text(tamil
              ? 'மாற்றம் இன்னும் பதிவாகவில்லை.'
              : 'No plant change has been recorded yet.')
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _JourneyNode(
                    item: visible[i],
                    latest: i == visible.length - 1,
                  ),
                  if (i != visible.length - 1)
                    const Divider(height: 12, indent: 40),
                ],
              ],
            ),
    );
  }
}

class ReliabilityGuardCard extends StatelessWidget {
  final SensorReading current;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;
  final bool live;
  final SensorConnectionStatus connectionStatus;

  const ReliabilityGuardCard({
    super.key,
    required this.current,
    required this.edge,
    required this.telemetry,
    required this.live,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final now = DateTime.now();
    final rawAge = now.difference(current.timestamp);
    final age = rawAge.isNegative ? Duration.zero : rawAge;
    final stale = live && age > const Duration(seconds: 6);
    final disconnected = live && connectionStatus != SensorConnectionStatus.ready;
    final bioExcluded = edge?.bioelectric.excludedByFirmware == true;
    final faults = edge?.sensorFaults.length ?? 0;
    final activeSensors = telemetry?.sensors.length ?? edge?.activeSensorChannels.length ?? 0;
    final rows = <_GuardRow>[
      _GuardRow(
        Icons.update_rounded,
        tamil ? 'Packet freshness' : 'Packet freshness',
        !live
            ? 'SIMULATION'
            : disconnected
                ? 'DISCONNECTED'
                : stale
                    ? 'STALE • ${age.inSeconds}s'
                    : 'LIVE • ${age.inSeconds}s',
        !stale && !disconnected,
      ),
      _GuardRow(
        Icons.verified_outlined,
        tamil ? 'Validated reading' : 'Validated reading',
        '${current.timestamp.hour.toString().padLeft(2, '0')}:${current.timestamp.minute.toString().padLeft(2, '0')}:${current.timestamp.second.toString().padLeft(2, '0')}',
        true,
      ),
      _GuardRow(
        Icons.electric_bolt_rounded,
        tamil ? 'Bioelectric protection' : 'Bioelectric protection',
        bioExcluded ? 'EXCLUDED — quality guard active' : 'QUALITY GATE ACTIVE',
        !bioExcluded,
      ),
      _GuardRow(
        Icons.sensors_rounded,
        tamil ? 'Sensor coverage' : 'Sensor coverage',
        faults > 0 ? '$activeSensors channels • $faults fault(s)' : '$activeSensors channels • no reported faults',
        faults == 0,
      ),
      _GuardRow(
        Icons.notifications_active_outlined,
        tamil ? 'Alert stability' : 'Alert stability',
        'duplicate-alert cooldown enabled',
        true,
      ),
      _GuardRow(
        Icons.swap_horiz_rounded,
        tamil ? 'Source isolation' : 'Source isolation',
        live ? 'ESP32 source only' : 'SIMULATION clearly isolated',
        true,
      ),
    ];

    return _CompetitionCard(
      icon: Icons.shield_rounded,
      title: tamil ? 'Demo reliability guards' : 'Demo reliability guards',
      subtitle: tamil
          ? 'Live demo-வில் தவறான அல்லது stale signal-ஐ live result போல காட்டாத பாதுகாப்புகள்.'
          : 'Protections that keep stale, noisy or simulated data from looking like valid live evidence.',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _GuardTile(row: rows[i]),
            if (i != rows.length - 1) const Divider(height: 14),
          ],
        ],
      ),
    );
  }
}

/// Additive panel for the hidden Engineering View.
class JudgeEvidenceMatrix extends StatelessWidget {
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;
  final List<SensorReading> history;
  final SensorReading? current;
  final bool live;
  final SensorConnectionStatus connectionStatus;

  const JudgeEvidenceMatrix({
    super.key,
    required this.edge,
    required this.telemetry,
    required this.history,
    required this.current,
    required this.live,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final e = edge;
    final reading = current;
    if (e == null && reading == null) return const SizedBox.shrink();
    final matrix = <_JudgeMetric>[
      _JudgeMetric('Decision origin', live ? 'ESP32 / firmware' : 'Simulation provider'),
      if (e?.overallConfidence != null)
        _JudgeMetric('Overall confidence', '${e!.overallConfidence!.round()}%'),
      if (e?.rootCause.primary != null)
        _JudgeMetric('Primary cause', e!.rootCause.primary!),
      if (e?.rootCause.primaryCandidate?.confidence != null)
        _JudgeMetric('Cause confidence', '${e!.rootCause.primaryCandidate!.confidence!.round()}%'),
      if (e?.bioelectric.stressScore != null)
        _JudgeMetric('Bioelectric stress', '${e!.bioelectric.stressScore!.toStringAsFixed(1)} / 100'),
      if (e?.bioelectric.normalizedDeviation != null)
        _JudgeMetric('Bio deviation', '${e!.bioelectric.normalizedDeviation!.toStringAsFixed(1)}%'),
      if (e?.derivedEnvironment.vpdKpa != null)
        _JudgeMetric('VPD', '${e!.derivedEnvironment.vpdKpa!.toStringAsFixed(2)} kPa'),
      if (e?.recovery.hasData == true)
        _JudgeMetric('Recovery', e!.recovery.state ?? (e.recovery.active ? 'ACTIVE' : 'INACTIVE')),
      _JudgeMetric('History buffer', '${history.length} validated sample(s)'),
      _JudgeMetric('Telemetry channels', '${telemetry?.sensors.length ?? e?.activeSensorChannels.length ?? 0}'),
      _JudgeMetric('Sensor faults', '${e?.sensorFaults.length ?? 0}'),
      _JudgeMetric('Source state', live ? connectionStatus.name.toUpperCase() : 'SIMULATION'),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.account_tree_outlined),
        title: const Text(
          'Evidence matrix',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text('One-screen jury proof of decision provenance and reliability.'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matrix.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 76,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
            ),
            itemBuilder: (context, index) => _JudgeMetricTile(metric: matrix[index]),
          ),
          if (e != null &&
              (e.stressEvidence.hasData || e.rootCause.primaryCandidate?.hasData == true)) ...[
            const SizedBox(height: 14),
            FusionEvidenceCard(edge: e),
          ],
        ],
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _CompetitionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SparkMetric extends StatelessWidget {
  final String label;
  final String valueText;
  final List<double> values;
  final double? minY;
  final double? maxY;

  const _SparkMetric({
    required this.label,
    required this.valueText,
    required this.values,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(valueText, style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 48,
              child: values.length < 2
                  ? Center(
                      child: Text(
                        '—',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    )
                  : _MiniLineChart(
                      values: values,
                      accent: accent,
                      minY: minY,
                      maxY: maxY,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final List<double> values;
  final Color accent;
  final double? minY;
  final double? maxY;

  const _MiniLineChart({
    required this.values,
    required this.accent,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final safeValues = values.where((v) => v.isFinite).toList(growable: false);
    if (safeValues.length < 2) return const SizedBox.shrink();
    final computedMin = safeValues.reduce(math.min);
    final computedMax = safeValues.reduce(math.max);
    final spread = math.max(0.01, computedMax - computedMin);
    final lower = minY ?? (computedMin - spread * 0.18);
    final upper = maxY ?? (computedMax + spread * 0.18);
    final spots = <FlSpot>[
      for (var i = 0; i < safeValues.length; i++) FlSpot(i.toDouble(), safeValues[i]),
    ];
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, safeValues.length - 1).toDouble(),
        minY: lower,
        maxY: upper <= lower ? lower + 1 : upper,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: accent,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.14)),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label  ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}

class _EvidenceItem {
  final String label;
  final double raw;
  const _EvidenceItem(this.label, this.raw);
}

class _AnimatedEvidenceBar extends StatelessWidget {
  final _EvidenceItem item;
  final int index;

  const _AnimatedEvidenceBar({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final value = _percent(item.raw) / 100;
    final accent = Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 520 + index * 90),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: value),
      builder: (context, animated, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('${(animated * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: animated,
              minHeight: 8,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.09),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceText extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _EvidenceText({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      );
}

class _JourneyItem {
  final DateTime? timestamp;
  final String label;
  final String type;

  const _JourneyItem({required this.timestamp, required this.label, required this.type});
}

class _JourneyNode extends StatelessWidget {
  final _JourneyItem item;
  final bool latest;

  const _JourneyNode({required this.item, required this.latest});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final upper = item.label.toUpperCase();
    final color = upper.contains('RECOVER')
        ? scheme.primary
        : upper.contains('CRITICAL') || upper.contains('STRESS')
            ? scheme.error
            : upper.contains('WATCH') || upper.contains('ATTENTION')
                ? scheme.tertiary
                : scheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: latest ? 0.18 : 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              latest ? Icons.circle : Icons.check_rounded,
              size: latest ? 10 : 17,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FarmerLanguage.firmware(
                    context,
                    item.label.replaceAll('_', ' '),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  item.timestamp == null ? item.type : _time(item.timestamp!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (latest)
            Text(
              FarmerLanguage.isTamil(context) ? 'தற்போது' : 'CURRENT',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _GuardRow {
  final IconData icon;
  final String label;
  final String value;
  final bool healthy;
  const _GuardRow(this.icon, this.label, this.value, this.healthy);
}

class _GuardTile extends StatelessWidget {
  final _GuardRow row;
  const _GuardTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = row.healthy ? scheme.primary : scheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(row.icon, size: 19, color: accent),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  row.value,
                  key: ValueKey(row.value),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          row.healthy ? Icons.check_circle_rounded : Icons.info_rounded,
          size: 18,
          color: accent,
        ),
      ],
    );
  }
}

class _JudgeMetric {
  final String label;
  final String value;
  const _JudgeMetric(this.label, this.value);
}

class _JudgeMetricTile extends StatelessWidget {
  final _JudgeMetric metric;
  const _JudgeMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              metric.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

List<SensorReading> _recentHistory(
  List<SensorReading> history,
  SensorReading current,
) {
  final sorted = [...history];
  if (sorted.every((r) => r.timestamp != current.timestamp)) sorted.add(current);
  sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final cutoff = DateTime.now().subtract(const Duration(minutes: 12));
  final recent = sorted.where((r) => !r.timestamp.isBefore(cutoff)).toList();
  final selected = recent.length >= 3 ? recent : sorted;
  if (selected.length <= 42) return selected;
  return selected.sublist(selected.length - 42);
}

List<_JourneyItem> _buildJourney(List<SensorReading> history, EdgeIntelligence edge) {
  final items = <_JourneyItem>[];
  String? last;
  for (final reading in history) {
    final state = _normalized(
      reading.recoveryActive ? 'RECOVERING' : reading.healthStatus,
    );
    if (state.isEmpty || state == last) continue;
    items.add(_JourneyItem(timestamp: reading.timestamp, label: state, type: 'STATE'));
    last = state;
  }
  for (final event in edge.recentEvents) {
    final label = event.message.trim().isNotEmpty ? event.message.trim() : event.type;
    if (label.isEmpty) continue;
    items.add(_JourneyItem(timestamp: event.timestamp, label: label, type: event.type));
  }
  if (edge.recovery.active && !items.any((i) => _normalized(i.label).contains('RECOVER'))) {
    items.add(const _JourneyItem(timestamp: null, label: 'RECOVERING', type: 'RECOVERY'));
  }
  items.sort((a, b) {
    if (a.timestamp == null && b.timestamp == null) return 0;
    if (a.timestamp == null) return 1;
    if (b.timestamp == null) return -1;
    return a.timestamp!.compareTo(b.timestamp!);
  });
  final deduped = <_JourneyItem>[];
  String? previous;
  for (final item in items) {
    final key = _normalized(item.label);
    if (key == previous) continue;
    deduped.add(item);
    previous = key;
  }
  if (deduped.length <= 7) return deduped;
  return deduped.sublist(deduped.length - 7);
}

double _percent(double raw) {
  if (!raw.isFinite) return 0;
  final normalized = raw.abs() <= 1.0 ? raw * 100 : raw;
  return normalized.clamp(0.0, 100.0).toDouble();
}

String _normalized(String? raw) =>
    (raw ?? '').trim().toUpperCase().replaceAll(' ', '_');

String _friendlyChannel(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('soil') && lower.contains('moist')) return 'Soil';
  if (lower.contains('vpd') || lower.contains('drying')) return 'VPD';
  if (lower.contains('bio') || lower.contains('plant')) return 'Bio';
  if (lower.contains('root')) return 'Root';
  if (lower.contains('humid')) return 'RH';
  if (lower.contains('temp')) return 'Temp';
  if (lower.contains('leaf')) return 'Leaf';
  if (lower.contains('light')) return 'Light';
  return raw.replaceAll('_', ' ');
}

String _time(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
