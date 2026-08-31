import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';

/// Final additive calibre layer.
///
/// It never replaces the provider decision. In live mode the ESP32 remains the
/// authority; this layer visualizes, replays and explains data already present
/// in the active provider. UI-only what-if text is explicitly labelled.
class CalibreUpgradePanels extends StatelessWidget {
  final SensorReading current;
  final List<SensorReading> history;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;
  final bool live;
  final SensorConnectionStatus connectionStatus;

  const CalibreUpgradePanels({
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
    final recent = history.length <= 36
        ? history
        : history.sublist(history.length - 36);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DigitalPlantTwinCard(
          current: current,
          edge: edge,
          live: live,
        ),
        const SizedBox(height: 12),
        TrendProjectionCard(
          current: current,
          history: recent,
          edge: edge,
          live: live,
        ),
        const SizedBox(height: 12),
        SensorFusionMapCard(
          current: current,
          edge: edge,
          telemetry: telemetry,
        ),
        const SizedBox(height: 12),
        _ExpandableIntelligence(
          title: FarmerLanguage.isTamil(context)
              ? 'Reasoning lab'
              : 'Reasoning lab',
          icon: Icons.psychology_alt_outlined,
          children: [
            CounterfactualAndWhyNotCard(
              current: current,
              edge: edge,
              live: live,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ExpandableIntelligence(
          title: FarmerLanguage.isTamil(context)
              ? 'Plant baseline memory'
              : 'Plant baseline memory',
          icon: Icons.memory_rounded,
          children: [
            PlantBaselineMemoryCard(
              current: current,
              history: recent,
              edge: edge,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ExpandableIntelligence(
          title: FarmerLanguage.isTamil(context)
              ? 'Confidence architecture'
              : 'Confidence architecture',
          icon: Icons.account_tree_outlined,
          children: [
            ConfidenceDecompositionCard(
              current: current,
              edge: edge,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ExpandableIntelligence(
          title: FarmerLanguage.isTamil(context)
              ? 'Decision replay'
              : 'Decision replay',
          icon: Icons.history_toggle_off_rounded,
          children: [
            DecisionReplayCard(
              history: recent,
              current: current,
            ),
          ],
        ),
        const SizedBox(height: 12),
        CompetitionPresentationLauncher(
          live: live,
          connectionStatus: connectionStatus,
        ),
      ],
    );
  }
}

class DigitalPlantTwinCard extends StatelessWidget {
  final SensorReading current;
  final EdgeIntelligence? edge;
  final bool live;

  const DigitalPlantTwinCard({
    super.key,
    required this.current,
    required this.edge,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final stress = (100 - (edge?.healthScore ?? current.healthScore))
        .clamp(0.0, 100.0)
        .toDouble();
    final bio = edge?.bioelectric;
    final vpd = edge?.derivedEnvironment.vpdKpa ?? current.vpdKpa;
    final root = current.soilMoistureAvailable
        ? current.soilMoisture
        : null;
    final leaf = current.leafWetnessAvailable ? current.leafWetness : null;
    final state = edge?.plantState ?? current.healthStatus;
    final accent = _stateColor(context, state);

    return _PremiumCard(
      icon: Icons.spa_rounded,
      title: 'Digital Plant Twin',
      subtitle: live
          ? 'Live visual state model driven by the current ESP32 packet.'
          : 'Clearly-labelled simulation twin driven by simulated sensor evidence.',
      child: Column(
        children: [
          SizedBox(
            height: 245,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TwinFieldPainter(
                      stress: stress,
                      accent: accent,
                    ),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.38),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 54,
                    color: accent,
                  ),
                ),
                Positioned(
                  top: 6,
                  child: _TwinBadge(
                    icon: Icons.air_rounded,
                    label: 'AIR',
                    value: vpd == null ? '—' : '${vpd.toStringAsFixed(2)} kPa',
                    active: vpd != null,
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 96,
                  child: _TwinBadge(
                    icon: Icons.water_drop_outlined,
                    label: 'ROOT',
                    value: root == null ? '—' : '${root.toStringAsFixed(0)}%',
                    active: root != null,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 96,
                  child: _TwinBadge(
                    icon: Icons.electric_bolt_rounded,
                    label: 'BIO',
                    value: bio?.stressScore == null
                        ? '—'
                        : '${bio!.stressScore!.toStringAsFixed(0)}/100',
                    active: bio?.excludedByFirmware != true &&
                        bio?.stressScore != null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  child: _TwinBadge(
                    icon: Icons.grass_rounded,
                    label: 'LEAF',
                    value: leaf == null ? '—' : '${leaf.toStringAsFixed(0)}%',
                    active: leaf != null,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            child: Container(
              key: ValueKey(state),
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.replaceAll('_', ' '),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Health ${(edge?.healthScore ?? current.healthScore).toStringAsFixed(0)}/100 • Stress ${stress.toStringAsFixed(0)}/100',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrendProjectionCard extends StatelessWidget {
  final SensorReading current;
  final List<SensorReading> history;
  final EdgeIntelligence? edge;
  final bool live;

  const TrendProjectionCard({
    super.key,
    required this.current,
    required this.history,
    required this.edge,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final firmwarePrediction = live &&
        edge?.capabilities.prediction == true &&
        edge?.prediction.available == true;
    final projection = firmwarePrediction
        ? _ProviderProjection(
            title: edge?.prediction.state?.replaceAll('_', ' ') ?? 'Projection available',
            body: edge?.prediction.explanation ?? edge?.prediction.message ?? 'ESP32 projection is available.',
            confidence: edge?.prediction.confidence,
            minutes: edge?.prediction.minutesToWarning,
            source: 'ESP32 PREDICTION',
          )
        : _trendProjection(history, current, edge);
    final accent = projection.direction > 0.25
        ? Theme.of(context).colorScheme.error
        : projection.direction < -0.25
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.tertiary;

    return _PremiumCard(
      icon: Icons.auto_graph_rounded,
      title: 'What happens next?',
      subtitle: firmwarePrediction
          ? 'Firmware-provided prediction. The app does not replace it.'
          : 'Recent trend projection — direction only, not a biological prediction.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  projection.direction > 0.25
                      ? Icons.trending_up_rounded
                      : projection.direction < -0.25
                          ? Icons.trending_down_rounded
                          : Icons.trending_flat_rounded,
                  color: accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projection.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      projection.body,
                      style: const TextStyle(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill('SOURCE', projection.source, accent),
              if (projection.confidence != null)
                _MetricPill(
                  'CONFIDENCE',
                  '${projection.confidence!.toStringAsFixed(0)}%',
                  accent,
                ),
              if (projection.minutes != null)
                _MetricPill(
                  'WINDOW',
                  '~${projection.minutes!.toStringAsFixed(0)} min',
                  accent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SensorFusionMapCard extends StatelessWidget {
  final SensorReading current;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;

  const SensorFusionMapCard({
    super.key,
    required this.current,
    required this.edge,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    final confidences = <String, double?>{
      for (final item in edge?.sensorConfidence ?? const <SensorConfidence>[])
        item.channel: item.percent,
    };
    final channels = <_FusionChannel>[
      _FusionChannel('AIR', Icons.air_rounded, current.temperatureAvailable && current.humidityAvailable, _lookupConfidence(confidences, ['airTemperature', 'humidity'])),
      _FusionChannel('SOIL', Icons.water_drop_outlined, current.soilMoistureAvailable, _lookupConfidence(confidences, ['soilMoisture'])),
      _FusionChannel('ROOT', Icons.device_thermostat_rounded, current.soilTemperatureAvailable, _lookupConfidence(confidences, ['rootTemperature'])),
      _FusionChannel('LEAF', Icons.grass_rounded, current.leafWetnessAvailable, _lookupConfidence(confidences, ['leafWetness'])),
      _FusionChannel('BIO', Icons.electric_bolt_rounded, current.plantSignalAvailable && edge?.bioelectric.excludedByFirmware != true, _lookupConfidence(confidences, ['bioelectric', 'plantSignal'])),
    ];
    final finding = edge?.rootCause.primary ??
        edge?.farmerSummary ??
        current.primaryRootCause ??
        current.healthStatus;

    return _PremiumCard(
      icon: Icons.hub_outlined,
      title: 'Sensor Fusion Map',
      subtitle: 'See which evidence channels are allowed into the current decision.',
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: channels.map((item) => _FusionInputChip(item: item)).toList(),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.keyboard_double_arrow_down_rounded, size: 28),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.92, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.memory_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CONFIDENCE-WEIGHTED FUSION',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Icon(Icons.keyboard_double_arrow_down_rounded, size: 28),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CURRENT OUTPUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 5),
                Text(
                  finding,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (edge?.overallConfidence != null) ...[
                  const SizedBox(height: 6),
                  Text('Provider confidence ${edge!.overallConfidence!.toStringAsFixed(0)}%'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CounterfactualAndWhyNotCard extends StatelessWidget {
  final SensorReading current;
  final EdgeIntelligence? edge;
  final bool live;

  const CounterfactualAndWhyNotCard({
    super.key,
    required this.current,
    required this.edge,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final whatIf = edge?.prediction.whatIfExplanation ?? _fallbackWhatIf(current, edge);
    final alternatives = _whyNot(current, edge);
    final main = edge?.rootCause.primary ?? edge?.farmerSummary ?? current.primaryRootCause;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReasoningBlock(
          icon: Icons.alt_route_rounded,
          title: 'Counterfactual',
          body: whatIf,
          footnote: live
              ? 'Illustrative UI explanation only. It does not alter the ESP32 decision.'
              : 'Simulation what-if explanation. It is not physical sensor evidence.',
        ),
        const SizedBox(height: 10),
        _ReasoningBlock(
          icon: Icons.help_outline_rounded,
          title: main == null ? 'Why not another cause?' : 'Why not something else?',
          body: alternatives.isEmpty
              ? 'The provider has not supplied enough counter-evidence to reject another cause confidently.'
              : alternatives.join('\n\n'),
          footnote: '“Not dominant” means lower current support — not impossible or permanently ruled out.',
        ),
      ],
    );
  }
}

class PlantBaselineMemoryCard extends StatelessWidget {
  final SensorReading current;
  final List<SensorReading> history;
  final EdgeIntelligence? edge;

  const PlantBaselineMemoryCard({
    super.key,
    required this.current,
    required this.history,
    required this.edge,
  });

  @override
  Widget build(BuildContext context) {
    final bio = edge?.bioelectric;
    final baseline = edge?.baseline;
    final ready = bio?.baselineReady ?? baseline?.ready ?? current.bioBaselineReady;
    final samples = bio?.baselineSamples ?? current.bioBaselineSamples;
    final target = bio?.baselineTarget;
    final baselineEvent = edge?.recentEvents
        .where((event) => event.type.toUpperCase().contains('BASELINE') && event.timestamp != null)
        .firstOrNull;
    final age = baselineEvent?.timestamp == null
        ? null
        : DateTime.now().difference(baselineEvent!.timestamp!);
    final protected = bio?.baselineLearningPaused == true ||
        baseline?.status?.toUpperCase().contains('PROTECTED') == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DataTile('STATUS', ready ? 'READY' : 'LEARNING'),
            _DataTile('SAMPLES', target == null ? '$samples' : '$samples/$target'),
            _DataTile('LEARNED NORMAL', bio?.baselineMv == null ? '—' : '${bio!.baselineMv!.toStringAsFixed(1)} mV'),
            _DataTile('DEVIATION', bio?.deviationMv == null ? '—' : '${bio!.deviationMv!.toStringAsFixed(1)} mV'),
            _DataTile('SIGNAL QUALITY', bio?.signalQualityState ?? '—'),
            _DataTile('BASELINE AGE', age == null ? 'Not reported' : _duration(age)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: protected
                ? Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.65)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(protected ? Icons.shield_rounded : Icons.memory_rounded),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  protected
                      ? 'Baseline protection is active: the system is not learning the current stressed response as the new normal.'
                      : ready
                          ? 'This plant has a learned electrical reference available for comparison.'
                          : 'The electrical reference is still learning; stress interpretation should remain limited until it is ready.',
                  style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConfidenceDecompositionCard extends StatelessWidget {
  final SensorReading current;
  final EdgeIntelligence? edge;

  const ConfidenceDecompositionCard({
    super.key,
    required this.current,
    required this.edge,
  });

  @override
  Widget build(BuildContext context) {
    final valid = (edge?.sensorConfidence ?? const <SensorConfidence>[])
        .where((item) => item.valid != false && item.percent != null)
        .map((item) => item.percent!)
        .toList(growable: false);
    final reliability = valid.isEmpty
        ? current.analysisConfidence
        : valid.reduce((a, b) => a + b) / valid.length;
    final evidenceAgreement = edge?.rootCause.primaryCandidate?.confidence ??
        edge?.overallConfidence ??
        current.analysisConfidence;
    final bioQuality = edge?.bioelectric.excludedByFirmware == true
        ? 0.0
        : edge?.bioelectric.confidence ?? current.bioSignalQuality;
    final persistenceSeconds = edge?.bioelectric.persistenceSeconds ?? 0;
    final persistenceSupport = math.min(100.0, persistenceSeconds / 90 * 100).toDouble();
    final finalConfidence = edge?.overallConfidence ?? current.analysisConfidence;

    return Column(
      children: [
        _ConfidenceBar(label: 'Sensor reliability', value: reliability),
        const SizedBox(height: 9),
        _ConfidenceBar(label: 'Evidence agreement', value: evidenceAgreement),
        const SizedBox(height: 9),
        _ConfidenceBar(label: 'Bioelectric quality', value: bioQuality),
        const SizedBox(height: 9),
        _ConfidenceBar(label: 'Temporal persistence support', value: persistenceSupport),
        const SizedBox(height: 13),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Provider final confidence: ${finalConfidence.toStringAsFixed(0)}%. The bars above explain supporting factors; the app does not recompute or replace the provider confidence.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DecisionReplayCard extends StatefulWidget {
  final List<SensorReading> history;
  final SensorReading current;

  const DecisionReplayCard({
    super.key,
    required this.history,
    required this.current,
  });

  @override
  State<DecisionReplayCard> createState() => _DecisionReplayCardState();
}

class _DecisionReplayCardState extends State<DecisionReplayCard> {
  int _offset = 0;

  @override
  void didUpdateWidget(covariant DecisionReplayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final max = math.max(0, _snapshots.length - 1);
    if (_offset > max) _offset = max;
  }

  List<SensorReading> get _snapshots {
    final source = widget.history.isEmpty ? <SensorReading>[widget.current] : widget.history;
    return source.length <= 12 ? source : source.sublist(source.length - 12);
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = _snapshots;
    final index = (snapshots.length - 1 - _offset).clamp(0, snapshots.length - 1).toInt();
    final reading = snapshots[index];
    final maxOffset = math.max(0, snapshots.length - 1);
    final finding = reading.primaryRootCause ?? 'Historical root-cause text was not stored in this snapshot.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Older snapshot',
              onPressed: _offset < maxOffset ? () => setState(() => _offset++) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _time(reading.timestamp),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    _offset == 0 ? 'Latest recorded snapshot' : 'Recorded snapshot $_offset step${_offset == 1 ? '' : 's'} back',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Newer snapshot',
              onPressed: _offset > 0 ? () => setState(() => _offset--) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DataTile('STATE', reading.healthStatus),
            _DataTile('HEALTH', '${reading.healthScore.toStringAsFixed(0)}/100'),
            _DataTile('STRESS', '${reading.stressScore.toStringAsFixed(0)}/100'),
            _DataTile('CONFIDENCE', '${reading.analysisConfidence.toStringAsFixed(0)}%'),
            _DataTile('SOURCE', reading.analysisOrigin.toUpperCase()),
            if (reading.vpdKpa != null) _DataTile('VPD', '${reading.vpdKpa!.toStringAsFixed(2)} kPa'),
          ],
        ),
        const SizedBox(height: 12),
        _ReasoningBlock(
          icon: Icons.fact_check_outlined,
          title: 'Recorded finding',
          body: finding,
          footnote: 'Decision Replay shows stored values only. Missing historical firmware evidence is never invented by the app.',
        ),
      ],
    );
  }
}

class CompetitionPresentationLauncher extends StatelessWidget {
  final bool live;
  final SensorConnectionStatus connectionStatus;

  const CompetitionPresentationLauncher({
    super.key,
    required this.live,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      icon: Icons.slideshow_rounded,
      title: 'Competition presentation layer',
      subtitle: live
          ? 'Presentation-only view. It changes typography and focus — never the ESP32 data.'
          : 'Presentation-only view using clearly-labelled simulated data.',
      child: Column(
        children: [
          if (live && connectionStatus != SensorConnectionStatus.ready)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Live presentation will show the current connection state rather than pretending stale data is live.'),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CompetitionPresentationScreen()),
                  ),
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: const Text('Presentation View'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JuryStoryScreen()),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Jury Story'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompetitionPresentationScreen extends StatelessWidget {
  const CompetitionPresentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.sensorManager,
      builder: (context, _) {
        final sensors = scope.sensors;
        final reading = sensors.current;
        final edge = sensors.edgeIntelligence;
        final live = sensors.source == SensorDataSource.esp32;
        if (reading == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Presentation View')),
            body: const Center(child: Text('Waiting for a validated reading…')),
          );
        }
        final state = edge?.plantState ?? reading.healthStatus;
        final accent = _stateColor(context, state);
        final finding = edge?.rootCause.primary ?? edge?.farmerSummary ?? reading.primaryRootCause ?? state;
        final action = edge?.recommendation ?? 'Continue monitoring.';
        final packetAge = DateTime.now().difference(reading.timestamp);
        final stale = live && packetAge > const Duration(seconds: 6);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('PhytoSense AI • Presentation'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                Row(
                  children: [
                    _SourceBadge(live: live, stale: stale),
                    const Spacer(),
                    Text(
                      live ? _relativeAge(packetAge) : 'SIMULATED DATA',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  state.replaceAll('_', ' '),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 13),
                Text(
                  finding,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DO THIS NOW', style: TextStyle(color: accent, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 7),
                      Text(action, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                DigitalPlantTwinCard(current: reading, edge: edge, live: live),
                const SizedBox(height: 12),
                SensorFusionMapCard(current: reading, edge: edge, telemetry: sensors.hardwareTelemetry),
              ],
            ),
          ),
        );
      },
    );
  }
}

class JuryStoryScreen extends StatefulWidget {
  const JuryStoryScreen({super.key});

  @override
  State<JuryStoryScreen> createState() => _JuryStoryScreenState();
}

class _JuryStoryScreenState extends State<JuryStoryScreen> {
  int _stage = 0;
  Timer? _timer;

  static const _titles = ['SENSE', 'LEARN', 'FUSE', 'EXPLAIN', 'ACT', 'RECOVER'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        setState(() => _stage = (_stage + 1) % _titles.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.sensorManager,
      builder: (context, _) {
        final sensors = scope.sensors;
        final reading = sensors.current;
        final edge = sensors.edgeIntelligence;
        final live = sensors.source == SensorDataSource.esp32;
        return Scaffold(
          appBar: AppBar(title: const Text('SENSE → LEARN → FUSE → ACT')),
          body: SafeArea(
            child: reading == null
                ? const Center(child: Text('Waiting for a validated reading…'))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _SourceBadge(live: live, stale: false),
                            const Spacer(),
                            Text('${_stage + 1}/${_titles.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(value: (_stage + 1) / _titles.length, minHeight: 6),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          child: _JuryStage(
                            key: ValueKey(_stage),
                            stage: _stage,
                            title: _titles[_stage],
                            reading: reading,
                            edge: edge,
                            live: live,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _stage = (_stage - 1 + _titles.length) % _titles.length),
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Expanded(
                              child: Text(
                                'Presentation only • ${live ? 'ESP32 remains authoritative' : 'simulation clearly labelled'}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _stage = (_stage + 1) % _titles.length),
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _JuryStage extends StatelessWidget {
  final int stage;
  final String title;
  final SensorReading reading;
  final EdgeIntelligence? edge;
  final bool live;

  const _JuryStage({
    super.key,
    required this.stage,
    required this.title,
    required this.reading,
    required this.edge,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final content = switch (stage) {
      0 => (
          Icons.sensors_rounded,
          'Seven evidence channels become one validated plant snapshot.',
          'Air ${reading.temperature.toStringAsFixed(1)} °C • RH ${reading.humidity.toStringAsFixed(0)}% • Soil ${reading.soilMoisture.toStringAsFixed(0)}% • Bio ${reading.plantSignal.toStringAsFixed(0)}/100'
        ),
      1 => (
          Icons.memory_rounded,
          edge?.bioelectric.learningBaseline == true
              ? "PhytoSense is learning this plant's normal electrical signature."
              : 'The current plant signal is compared with its learned electrical reference.',
          edge?.bioelectric.baselineLearningPaused == true
              ? 'Baseline protection is active during stress.'
              : 'Signal quality ${edge?.bioelectric.signalQualityState ?? '—'}'
        ),
      2 => (
          Icons.hub_outlined,
          'Confidence-weighted fusion combines supporting and conflicting evidence.',
          '${edge?.activeSensorChannels.length ?? reading.availableChannelCount} active channels • Confidence ${(edge?.overallConfidence ?? reading.analysisConfidence).toStringAsFixed(0)}%'
        ),
      3 => (
          Icons.psychology_alt_outlined,
          edge?.rootCause.primary ?? edge?.farmerSummary ?? reading.primaryRootCause ?? 'No dominant cause reported.',
          edge?.rootCause.primaryCandidate?.evidenceFor ?? edge?.decisionExplanation ?? 'The provider explanation is shown without replacing it.'
        ),
      4 => (
          Icons.agriculture_outlined,
          edge?.recommendation ?? 'Continue monitoring.',
          'Farmer action is separated from the engineering evidence.'
        ),
      _ => (
          Icons.restore_rounded,
          edge?.recovery.active == true ? 'Recovery is being verified.' : 'PhytoSense keeps watching for recovery or a new change.',
          edge?.recovery.improved ?? edge?.recovery.remainingConcern ?? 'The loop continues: sense → learn → fuse → explain.'
        ),
    };

    return Column(
      key: ValueKey(title),
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Icon(content.$1, size: 48, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 15),
        Text(
          content.$2,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.2),
        ),
        const SizedBox(height: 13),
        Text(
          content.$3,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.4),
        ),
      ],
    );
  }
}

class _ExpandableIntelligence extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ExpandableIntelligence({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text('Tap for engineering-grade explanation'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _PremiumCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35)),
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

class _TwinBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool active;

  const _TwinBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.8)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TwinFieldPainter extends CustomPainter {
  final double stress;
  final Color accent;

  const _TwinFieldPainter({
    required this.stress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      ring.color = accent.withValues(alpha: 0.08 + i * 0.025);
      canvas.drawCircle(center, 46 + i * 22, ring);
    }
    final stressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.8);
    final sweep = math.pi * 2 * (stress / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 72),
      -math.pi / 2,
      sweep,
      false,
      stressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TwinFieldPainter oldDelegate) =>
      oldDelegate.stress != stress || oldDelegate.accent != accent;
}

class _FusionInputChip extends StatelessWidget {
  final _FusionChannel item;

  const _FusionInputChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = item.active ? activeColor : muted;
    return Container(
      width: 94,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: item.active ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(item.icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(item.label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
          Text(
            !item.active
                ? 'EXCLUDED'
                : item.confidence == null
                    ? 'ACTIVE'
                    : '${item.confidence!.toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ReasoningBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String footnote;

  const _ReasoningBlock({
    required this.icon,
    required this.title,
    required this.body,
    required this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.4, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Text(footnote, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double value;

  const _ConfidenceBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final bounded = value.clamp(0.0, 100.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
            Text('${bounded.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: bounded / 100),
          builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 7),
        ),
      ],
    );
  }
}

class _DataTile extends StatelessWidget {
  final String label;
  final String value;

  const _DataTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.7)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('$label • $value', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final bool live;
  final bool stale;

  const _SourceBadge({required this.live, required this.stale});

  @override
  Widget build(BuildContext context) {
    final color = !live
        ? Theme.of(context).colorScheme.tertiary
        : stale
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(!live ? Icons.science_outlined : stale ? Icons.schedule_rounded : Icons.wifi_tethering_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(!live ? 'SIMULATION' : stale ? 'STALE LIVE SOURCE' : 'ESP32 LIVE', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
        ],
      ),
    );
  }
}

class _FusionChannel {
  final String label;
  final IconData icon;
  final bool active;
  final double? confidence;

  const _FusionChannel(this.label, this.icon, this.active, this.confidence);
}

class _ProviderProjection {
  final String title;
  final String body;
  final double? confidence;
  final double? minutes;
  final String source;
  final double direction;

  const _ProviderProjection({
    required this.title,
    required this.body,
    required this.source,
    this.confidence,
    this.minutes,
    this.direction = 0,
  });
}

_ProviderProjection _trendProjection(
  List<SensorReading> history,
  SensorReading current,
  EdgeIntelligence? edge,
) {
  final recent = history.length <= 8
      ? history
      : history.sublist(history.length - 8);
  if (recent.length < 2) {
    return const _ProviderProjection(
      title: 'Building trend history',
      body: 'More readings are needed before a direction can be shown.',
      source: 'RECENT READINGS',
    );
  }
  final first = recent.first.stressScore;
  final last = recent.last.stressScore;
  final delta = last - first;
  if (delta > 6) {
    return _ProviderProjection(
      title: 'Stress direction is increasing',
      body: 'Recent validated stress values are moving upward. This is a direction signal, not a forecast.',
      confidence: edge?.overallConfidence ?? current.analysisConfidence,
      source: 'TREND PROJECTION',
      direction: 1,
    );
  }
  if (delta < -6) {
    return _ProviderProjection(
      title: 'Recovery direction is improving',
      body: 'Recent validated stress values are moving downward. Continue monitoring for persistence.',
      confidence: edge?.overallConfidence ?? current.analysisConfidence,
      source: 'TREND PROJECTION',
      direction: -1,
    );
  }
  return _ProviderProjection(
    title: 'Recent condition is broadly stable',
    body: 'The recent stress window does not show a strong directional change.',
    confidence: edge?.overallConfidence ?? current.analysisConfidence,
    source: 'TREND PROJECTION',
  );
}

String _fallbackWhatIf(SensorReading current, EdgeIntelligence? edge) {
  final primary = (edge?.rootCause.primary ?? '').toLowerCase();
  if (primary.contains('atmospheric') || primary.contains('drying')) {
    return current.soilMoisture >= 35
        ? 'If root-zone moisture also fell below the preferred range, water-stress evidence would become much stronger.'
        : 'If atmospheric demand fell while the root zone remained dry, root-zone water stress would stay relevant.';
  }
  if (primary.contains('water') || primary.contains('moisture')) {
    return 'If root-zone moisture returned to range but the plant response remained elevated, another cause would need more attention.';
  }
  if (primary.contains('heat')) {
    return 'If temperature fell while the plant response stayed elevated, heat would lose support and competing causes would become more important.';
  }
  return 'If one major sensor channel changes, PhytoSense should compare that new evidence with the remaining channels before changing the dominant finding.';
}

List<String> _whyNot(SensorReading current, EdgeIntelligence? edge) {
  final result = <String>[];
  final primaryCounter = edge?.rootCause.primaryCandidate?.evidenceAgainst;
  if (primaryCounter != null && primaryCounter.trim().isNotEmpty) {
    result.add('Counter-evidence: $primaryCounter');
  }
  final ranked = edge?.rootCause.ranked ?? const <RootCauseCandidate>[];
  for (final candidate in ranked.skip(1).take(2)) {
    if (candidate.name == null) continue;
    final against = candidate.evidenceAgainst;
    result.add(
      against == null || against.trim().isEmpty
          ? '${candidate.name}: lower current support (${candidate.confidence?.toStringAsFixed(0) ?? '—'}%).'
          : '${candidate.name}: $against',
    );
  }
  final main = (edge?.rootCause.primary ?? '').toLowerCase();
  if (!main.contains('water') && !main.contains('moisture') && current.soilMoistureAvailable && current.soilMoisture >= 42) {
    result.add('Water stress is not dominant right now: root-zone moisture is ${current.soilMoisture.toStringAsFixed(0)}%, so the current reading does not strongly support a dry-root cause.');
  }
  if (!main.contains('heat') && current.temperatureAvailable && current.temperature < 31) {
    result.add('Heat is not dominant right now: air temperature is ${current.temperature.toStringAsFixed(1)} °C and does not provide strong heat-stress evidence.');
  }
  if (edge?.bioelectric.excludedByFirmware == true) {
    result.add('Bioelectric stress is not used in the decision because the provider marked the plant signal unreliable or unavailable.');
  }
  if (edge?.bioticStress.suspected != true) {
    result.add('Biotic stress is not currently dominant: the provider has not reported a supported biotic-suspicion state.');
  }
  return result.toSet().take(4).toList(growable: false);
}

double? _lookupConfidence(Map<String, double?> values, List<String> names) {
  for (final name in names) {
    if (values.containsKey(name) && values[name] != null) return values[name];
  }
  return null;
}

Color _stateColor(BuildContext context, String raw) {
  final value = raw.toUpperCase();
  if (value.contains('CRITICAL')) return Theme.of(context).colorScheme.error;
  if (value.contains('STRESS') || value.contains('WATCH') || value.contains('ATTENTION')) {
    return Theme.of(context).colorScheme.tertiary;
  }
  return Theme.of(context).colorScheme.primary;
}

String _time(DateTime timestamp) {
  final h = timestamp.hour.toString().padLeft(2, '0');
  final m = timestamp.minute.toString().padLeft(2, '0');
  final s = timestamp.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _duration(Duration duration) {
  if (duration.inMinutes < 1) return '${duration.inSeconds}s';
  if (duration.inHours < 1) return '${duration.inMinutes}m';
  if (duration.inDays < 1) return '${duration.inHours}h';
  return '${duration.inDays}d';
}

String _relativeAge(Duration age) {
  if (age.inSeconds < 2) return 'Updated now';
  if (age.inSeconds < 60) return 'Updated ${age.inSeconds}s ago';
  if (age.inMinutes < 60) return 'Updated ${age.inMinutes}m ago';
  return 'Updated ${age.inHours}h ago';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
