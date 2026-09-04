import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/competition_intelligence_panels.dart';
import 'esp32_diagnostics_screen.dart';

/// Hidden technical surface for jury questions and engineering verification.
///
/// It never creates analysis of its own. Every value shown here comes from the
/// active SensorDataProvider, preserving ESP32 authority in live mode and
/// clearly labelling simulation when demo data is active.
class JudgeViewScreen extends StatelessWidget {
  const JudgeViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.sensorManager,
      builder: (context, _) {
        final sensors = scope.sensors;
        final reading = sensors.current;
        final edge = sensors.edgeIntelligence;
        final telemetry = sensors.hardwareTelemetry;
        final live = sensors.source == SensorDataSource.esp32;
        final rawAge = reading == null
            ? null
            : DateTime.now().difference(reading.timestamp);
        final age = rawAge == null
            ? null
            : rawAge.isNegative
                ? Duration.zero
                : rawAge;
        final state = _connectionState(sensors.connectionStatus, live, age);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Engineering View'),
            actions: [
              if (live)
                IconButton(
                  tooltip: 'System diagnostics',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Esp32DiagnosticsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.monitor_heart_outlined),
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              _SourceHeader(
                live: live,
                state: state,
                age: age,
                endpoint: live ? scope.sensorManager.hardwareEndpoint : null,
              ),
              const SizedBox(height: 12),
              _DecisionCard(edge: edge, analysisOrigin: reading?.analysisOrigin),
              const SizedBox(height: 12),
              _BioCard(edge: edge, bioSource: reading?.bioSource),
              const SizedBox(height: 12),
              _FusionCard(edge: edge),
              if (edge != null &&
                  (edge.sensorIntegrity.hasData ||
                      edge.plausibility.hasData ||
                      edge.runtimeHealth.hasData ||
                      edge.recovery.hasData ||
                      edge.buildState != null)) ...[
                const SizedBox(height: 12),
                _ReliabilityDiagnosticsCard(edge: edge),
              ],
              if (edge?.recentEvents.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _EventTimelineCard(events: edge!.recentEvents),
              ],
              const SizedBox(height: 12),
              _SensorEvidenceCard(
                telemetry: telemetry,
                edge: edge,
                packetAge: age,
              ),
              const SizedBox(height: 12),
              JudgeEvidenceMatrix(
                edge: edge,
                telemetry: telemetry,
                history: reading == null
                    ? const []
                    : sensors.historyFor(reading.nodeId),
                current: reading,
                live: live,
                connectionStatus: sensors.connectionStatus,
              ),
              if (live) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings_input_antenna_rounded),
                    title: const Text(
                      'Full ESP32 diagnostics',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Firmware uptime, Wi-Fi, sensor ages, errors and hardware status.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Esp32DiagnosticsScreen(),
                      ),
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

class _SourceHeader extends StatelessWidget {
  final bool live;
  final String state;
  final Duration? age;
  final String? endpoint;

  const _SourceHeader({
    required this.live,
    required this.state,
    required this.age,
    required this.endpoint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = live ? const Color(0xFF4E9DDB) : scheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.15), scheme.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  live ? 'ESP32 LIVE' : 'SIMULATION',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                state,
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            live
                ? 'Firmware-originated plant intelligence and validated sensor telemetry.'
                : 'Generated demo telemetry. No value on this screen is presented as a physical measurement.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (age != null) Text('Packet age: ${_duration(age!)}'),
              if (endpoint != null) Text('Endpoint: $endpoint'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  final EdgeIntelligence? edge;
  final String? analysisOrigin;

  const _DecisionCard({required this.edge, required this.analysisOrigin});

  @override
  Widget build(BuildContext context) {
    final e = edge;
    return _TechnicalCard(
      icon: Icons.psychology_alt_rounded,
      title: 'Decision engine',
      children: [
        _Metric('Analysis origin', analysisOrigin ?? (e?.generatedOnDevice == true ? 'esp32' : null)),
        _Metric('Firmware', e?.firmwareVersion),
        if (e?.schemaVersion != null) _Metric('Schema', 'v${e!.schemaVersion}'),
        _Metric('Plant state', e?.plantState),
        if (e?.healthScore != null)
          _Metric('Health index', '${e!.healthScore!.toStringAsFixed(1)} / 100'),
        if (e?.overallConfidence != null)
          _Metric('Analysis confidence', '${e!.overallConfidence!.round()}%'),
        _Metric('Analysis quality', e?.analysisQuality),
        _Metric('Primary root cause', e?.rootCause.primary),
        if (e?.rootCause.primaryCandidate?.confidence != null)
          _Metric(
            'Root-cause confidence',
            '${e!.rootCause.primaryCandidate!.confidence!.round()}%',
          ),
        _Metric('Recommendation', e?.recommendation),
        if (e?.derivedEnvironment.vpdKpa != null)
          _Metric('VPD', '${e!.derivedEnvironment.vpdKpa!.toStringAsFixed(2)} kPa'),
        _Metric('VPD state', e?.derivedEnvironment.vpdState ?? e?.derivedEnvironment.dryingDemandState),
        if (e?.recovery.active == true)
          _Metric('Recovery', e?.recovery.farmerResult ?? e?.recovery.improved ?? 'Active'),
        if (e?.degradedAnalysis == true)
          _Metric('Reduced confidence', e?.degradedReason ?? 'Active'),
      ],
    );
  }
}

class _BioCard extends StatelessWidget {
  final EdgeIntelligence? edge;
  final String? bioSource;

  const _BioCard({required this.edge, required this.bioSource});

  @override
  Widget build(BuildContext context) {
    final bio = edge?.bioelectric;
    final excluded = bio?.excludedByFirmware == true;
    final source = bio?.source ?? bioSource;
    final presentation = BioelectricIntelligence.isPresentationSource(source);
    return _TechnicalCard(
      icon: Icons.electric_bolt_rounded,
      title: 'Bioelectric channel',
      badge: bio == null || !bio.hasData
          ? 'NO DATA'
          : presentation
              ? 'PRESENTATION'
              : excluded
              ? 'EXCLUDED'
              : bio.learningBaseline
                  ? 'LEARNING'
                  : 'IN FUSION',
      children: [
        _Metric('Signal source', _bioSourceDescription(source)),
        _Metric('Signal state', bio?.signalQualityState),
        if (bio?.signalQuality != null)
          _Metric('Signal quality', '${bio!.signalQuality!.round()}%'),
        if (bio?.confidence != null)
          _Metric('Bio confidence', '${bio!.confidence!.round()}%'),
        _Metric('Stress state', bio?.stressState),
        if (bio?.stressScore != null)
          _Metric('Stress score', '${bio!.stressScore!.toStringAsFixed(1)} / 100'),
        if (bio?.baselineMv != null)
          _Metric('Learned baseline', '${bio!.baselineMv!.toStringAsFixed(1)} mV'),
        if (bio?.normalizedDeviation != null)
          _Metric('Baseline deviation', '${bio!.normalizedDeviation!.toStringAsFixed(1)}%'),
        _Metric('Trend', bio?.trend),
        _Metric(
          'Used by fusion',
          presentation
              ? 'No — presentation source'
              : bio?.includedInFusion == null
              ? null
              : bio!.includedInFusion!
                  ? 'Yes'
                  : 'No',
        ),
        if (presentation)
          const _Metric(
            'Integrity rule',
            'Visible for presentation only; excluded from health, diagnosis, root cause, recovery and biotic inference.',
          )
        else if (excluded)
          const _Metric(
            'Protection',
            'Bad electrode/signal quality cannot create a plant-stress alert.',
          ),
      ],
    );
  }
}

class _ReliabilityDiagnosticsCard extends StatelessWidget {
  final EdgeIntelligence edge;

  const _ReliabilityDiagnosticsCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final integrity = edge.sensorIntegrity;
    final plausibility = edge.plausibility;
    final runtime = edge.runtimeHealth;
    final recovery = edge.recovery;
    final channels = integrity.channels.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    return _TechnicalCard(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Node reliability',
      badge: integrity.normalizedState ?? runtime.normalizedState,
      children: [
        _Metric('Sensor integrity', integrity.state),
        if (integrity.faultCount != null)
          _Metric('Integrity faults', '${integrity.faultCount}'),
        if (integrity.verifyCount != null)
          _Metric('Channels to verify', '${integrity.verifyCount}'),
        _Metric('Integrity issue', integrity.primaryIssue),
        _Metric('Integrity action', integrity.primaryAction),
        for (final channel in channels)
          _Metric('${_pretty(channel.key)} channel', channel.value),
        _Metric('Sensor plausibility', plausibility.state),
        if (plausibility.issueCount != null)
          _Metric('Plausibility issues', '${plausibility.issueCount}'),
        if (plausibility.confidence != null)
          _Metric(
            'Plausibility confidence',
            '${plausibility.confidence!.round()}%',
          ),
        _Metric('Plausibility issue', plausibility.primaryIssue),
        _Metric('Plausibility recommendation', plausibility.recommendation),
        _Metric('Runtime', runtime.state),
        if (runtime.freeHeap != null)
          _Metric('Free heap', _formatBytes(runtime.freeHeap!)),
        if (runtime.minFreeHeap != null)
          _Metric('Minimum heap', _formatBytes(runtime.minFreeHeap!)),
        if (runtime.lastSensorCycleMs != null)
          _Metric(
            'Sensor-cycle latency',
            '${runtime.lastSensorCycleMs!.toStringAsFixed(0)} ms',
          ),
        if (runtime.maxSensorCycleMs != null)
          _Metric(
            'Maximum cycle latency',
            '${runtime.maxSensorCycleMs!.toStringAsFixed(0)} ms',
          ),
        if (runtime.lastLoopGapMs != null)
          _Metric(
            'Last loop gap',
            '${runtime.lastLoopGapMs!.toStringAsFixed(0)} ms',
          ),
        if (runtime.maxLoopGapMs != null)
          _Metric(
            'Maximum loop gap',
            '${runtime.maxLoopGapMs!.toStringAsFixed(0)} ms',
          ),
        if (runtime.oledI2cSkipTotal != null)
          _Metric('OLED/I²C protection count', '${runtime.oledI2cSkipTotal}'),
        _Metric('Runtime issue', runtime.issue),
        _Metric('Recovery state', recovery.state),
        if (recovery.confidence != null)
          _Metric('Recovery confidence', '${recovery.confidence!.round()}%'),
        if (recovery.progressPct != null)
          _Metric('Recovery progress', '${recovery.progressPct!.round()}%'),
        if (recovery.evidenceCount != null)
          _Metric('Recovery evidence count', '${recovery.evidenceCount}'),
        if (recovery.verificationSeconds != null)
          _Metric(
            'Recovery verification time',
            _duration(Duration(
              milliseconds: (recovery.verificationSeconds! * 1000).round(),
            )),
          ),
        _Metric(
          'Environment improved',
          _yesNo(recovery.environmentImproved),
        ),
        _Metric('Soil improved', _yesNo(recovery.soilImproved)),
        _Metric(
          'Stress evidence decreasing',
          _yesNo(recovery.stressEvidenceDecreasing),
        ),
        _Metric(
          'Bio response decreasing',
          _yesNo(recovery.bioResponseDecreasing),
        ),
        _Metric('Recovery verified', _yesNo(recovery.verified)),
        _Metric('Firmware recovery result', recovery.farmerResult),
        _Metric('Build state', edge.buildState),
      ],
    );
  }
}

class _EventTimelineCard extends StatelessWidget {
  final List<PhytoEvent> events;

  const _EventTimelineCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final visible = events.take(8).toList(growable: false);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.timeline_rounded),
        title: const Text(
          'Event timeline',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${events.length} deduplicated firmware event(s)'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            _TechnicalEventRow(event: visible[index]),
            if (index != visible.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TechnicalEventRow extends StatelessWidget {
  final PhytoEvent event;

  const _TechnicalEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final severity = event.severity?.trim().toUpperCase() ?? 'INFO';
    final warn = severity == 'WARN' || severity == 'WARNING';
    final accent = warn
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _eventTime(event),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      severity,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(event.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FusionCard extends StatelessWidget {
  final EdgeIntelligence? edge;

  const _FusionCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final e = edge;
    final confidence = e?.sensorConfidence ?? const <SensorConfidence>[];
    return _TechnicalCard(
      icon: Icons.hub_rounded,
      title: 'Fusion & confidence',
      children: [
        if (e?.activeSensorChannels.isNotEmpty == true)
          _Metric('Active channels', e!.activeSensorChannels.join(', ')),
        if (confidence.isNotEmpty)
          _Metric(
            'Sensor confidence',
            confidence
                .map((item) => item.percent == null
                    ? '${item.channel}: ${item.state ?? 'reported'}'
                    : '${item.channel}: ${item.percent!.round()}%')
                .join(' • '),
          ),
        if (e?.sensorFaults.isNotEmpty == true)
          _Metric(
            'Sensor faults',
            e!.sensorFaults
                .map((fault) => '${fault.channel}: ${fault.type ?? fault.explanation ?? 'fault'}')
                .join(' • '),
          ),
        if (e?.riskFlags.isNotEmpty == true)
          _Metric('Risk flags', e!.riskFlags.join(', ')),
        _Metric('Primary evidence', e?.rootCause.primaryCandidate?.evidenceFor),
        _Metric('Counter-evidence', e?.rootCause.primaryCandidate?.evidenceAgainst),
      ],
    );
  }
}

class _SensorEvidenceCard extends StatelessWidget {
  final HardwareTelemetry? telemetry;
  final EdgeIntelligence? edge;
  final Duration? packetAge;

  const _SensorEvidenceCard({
    required this.telemetry,
    required this.edge,
    required this.packetAge,
  });

  @override
  Widget build(BuildContext context) {
    final sensors = telemetry?.sensors.values.toList() ?? <HardwareSensorDetail>[];
    sensors.sort((a, b) => a.channel.compareTo(b.channel));
    final fallback = edge?.sensorConfidence ?? const <SensorConfidence>[];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.sensors_rounded),
        title: const Text(
          'Sensor evidence',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          sensors.isNotEmpty
              ? '${sensors.length} channels in this validated snapshot'
              : '${fallback.length} confidence channels reported',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          if (sensors.isEmpty && fallback.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No per-sensor technical evidence was reported.'),
            )
          else if (sensors.isNotEmpty)
            for (final sensor in sensors)
              _SensorRow(sensor: sensor, packetAge: packetAge)
          else
            for (final item in fallback)
              _FallbackSensorRow(item: item, packetAge: packetAge),
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final HardwareSensorDetail sensor;
  final Duration? packetAge;

  const _SensorRow({required this.sensor, required this.packetAge});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_pretty(sensor.channel),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (sensor.status != null) Text('Status: ${sensor.status}'),
                if (sensor.confidence != null)
                  Text('Confidence: ${sensor.confidence!.round()}%'),
                if (sensor.trend != null) Text('Trend: ${sensor.trend}'),
                if (packetAge != null) Text('Updated: ${_duration(packetAge!)} ago'),
              ],
            ),
            if (sensor.explanation != null) ...[
              const SizedBox(height: 4),
              Text(sensor.explanation!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const Divider(height: 18),
          ],
        ),
      );
}

class _FallbackSensorRow extends StatelessWidget {
  final SensorConfidence item;
  final Duration? packetAge;

  const _FallbackSensorRow({required this.item, required this.packetAge});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(_pretty(item.channel),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            if (item.state != null) Text('${item.state}  '),
            if (item.percent != null) Text('${item.percent!.round()}%  '),
            if (packetAge != null) Text('${_duration(packetAge!)} old'),
          ],
        ),
      );
}

class _TechnicalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final List<Widget> children;

  const _TechnicalCard({
    required this.icon,
    required this.title,
    required this.children,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...children.where((widget) {
                if (widget is _Metric) return widget.value != null && widget.value!.trim().isNotEmpty;
                return true;
              }),
            ],
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final String? value;

  const _Metric(this.label, this.value);

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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Text(value ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

String _connectionState(
  SensorConnectionStatus status,
  bool live,
  Duration? age,
) {
  if (!live) return 'SIMULATION';
  if (status != SensorConnectionStatus.ready) return 'DISCONNECTED';
  if (age != null && age.inSeconds > 6) return 'STALE';
  return 'LIVE';
}

String _duration(Duration duration) {
  if (duration.inMinutes >= 60) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
  if (duration.inSeconds >= 60) {
    return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
  }
  return '${duration.inSeconds}s';
}

String? _bioSourceDescription(String? source) {
  if (source == null || source.trim().isEmpty) return null;
  final normalized = source.trim().toUpperCase().replaceAll(' ', '_');
  if (BioelectricIntelligence.isPresentationSource(source)) {
    return 'Presentation/demo signal — not diagnostic';
  }
  if (normalized == 'REAL' || normalized == 'PHYSICAL') {
    return 'Physical measurement';
  }
  if (normalized == 'SIMULATION' || normalized == 'SIM') {
    return 'Simulation signal';
  }
  return _pretty(source);
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '$bytes B';
}

String? _yesNo(bool? value) => value == null ? null : value ? 'Yes' : 'No';

String _eventTime(PhytoEvent event) {
  final time = event.timestamp?.toLocal();
  if (time != null) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
  if (event.uptimeMs != null) {
    return 'T+${_duration(Duration(milliseconds: event.uptimeMs!))}';
  }
  return 'Time unavailable';
}

String _pretty(String value) {
  final spaced = value
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
      .trim();
  if (spaced.isEmpty) return value;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
