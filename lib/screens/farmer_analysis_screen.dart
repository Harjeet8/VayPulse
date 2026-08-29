import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/firmware_text_adapter.dart';
import '../services/sensor_data_provider.dart';

class FarmerAnalysisScreen extends StatelessWidget {
  const FarmerAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;

    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final reading = sensors.current;
        final edge = sensors.edgeIntelligence;
        return Scaffold(
          appBar: AppBar(
            title: Text(FirmwareTextAdapter.label(context, 'title')),
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
                  FirmwareTextAdapter.label(context, 'subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                if (sensors.connectionStatus != SensorConnectionStatus.ready)
                  _DisconnectedCard(reading: reading),
                if (reading == null) ...[
                  const SizedBox(height: 12),
                  const _WaitingForReadingCard(),
                ] else ...[
                  _OverallCard(reading: reading, edge: edge),
                  const SizedBox(height: 12),
                  _ActionCard(edge: edge),
                  const SizedBox(height: 12),
                  _WhatIsHappeningCard(edge: edge),
                  const SizedBox(height: 12),
                  _PredictionCard(edge: edge),
                  const SizedBox(height: 12),
                  _WhyCard(edge: edge),
                  if (edge?.recovery.hasData == true ||
                      edge?.plantState?.toUpperCase() == 'RECOVERING') ...[
                    const SizedBox(height: 12),
                    _RecoveryCard(edge: edge!),
                  ],
                  const SizedBox(height: 12),
                  _SensorSummaryCard(reading: reading, edge: edge),
                  const SizedBox(height: 12),
                  _ConfidenceCard(reading: reading, edge: edge),
                  if (edge?.diseaseRiskScore != null ||
                      reading.diseaseRisk != null) ...[
                    const SizedBox(height: 12),
                    _DiseaseRiskCard(reading: reading, edge: edge),
                  ],
                  const SizedBox(height: 12),
                  _AvoidCard(edge: edge),
                  const SizedBox(height: 12),
                  _WatchNextCard(edge: edge),
                  if (edge?.recentEvents.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _EventsCard(edge: edge!),
                  ],
                  const SizedBox(height: 12),
                  _TechnicalDetails(reading: reading, edge: edge),
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

  const _OverallCard({required this.reading, required this.edge});

  @override
  Widget build(BuildContext context) {
    final state = FirmwareTextAdapter.text(
      context,
      edge?.plantState ?? reading.healthStatus,
      fallback: 'Monitoring',
    );
    final confidence = edge?.overallConfidence ?? reading.analysisConfidence;
    final score = edge?.healthScore ?? reading.healthScore;
    final isRecovering = edge?.plantState?.toUpperCase() == 'RECOVERING' ||
        edge?.recovery.active == true;
    final color = isRecovering
        ? Theme.of(context).colorScheme.tertiary
        : score < 45
            ? Theme.of(context).colorScheme.error
            : score < 70
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.primary;

    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'overall'),
      icon: Icons.eco_rounded,
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.round().toString(),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 7, left: 4),
                child: Text(
                  '/ 100',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const Spacer(),
              _Pill(label: state, color: color),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 12),
          Text(
            FirmwareTextAdapter.text(
              context,
              edge?.farmerSummary,
              fallback: _summaryFallback(context, state, confidence),
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.verified_user_outlined,
                text: '${confidence.round()}% confidence',
              ),
              _InfoChip(
                icon: edge?.hasAuthoritativeAnalysis == true
                    ? Icons.memory_rounded
                    : Icons.mobile_friendly_rounded,
                text: FirmwareTextAdapter.label(
                  context,
                  edge?.hasAuthoritativeAnalysis == true
                      ? 'edge_source'
                      : 'fallback_source',
                ),
              ),
              if (edge?.urgency != null)
                _InfoChip(
                  icon: Icons.flag_outlined,
                  text: FirmwareTextAdapter.text(context, edge!.urgency),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _summaryFallback(
    BuildContext context,
    String state,
    double confidence,
  ) {
    if (confidence < 50) {
      return FirmwareTextAdapter.label(context, 'low_confidence_warning');
    }
    return '$state. ${FirmwareTextAdapter.label(context, 'monitor')}';
  }
}

class _ActionCard extends StatelessWidget {
  final EdgeIntelligence? edge;

  const _ActionCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final action = FirmwareTextAdapter.text(
      context,
      edge?.recommendation,
      fallback: FirmwareTextAdapter.label(context, 'no_action_from_node'),
    );
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'do_now'),
      icon: Icons.task_alt_rounded,
      accent: Theme.of(context).colorScheme.primary,
      child: Text(
        action,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
      ),
    );
  }
}

class _WhatIsHappeningCard extends StatelessWidget {
  final EdgeIntelligence? edge;

  const _WhatIsHappeningCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final cause = edge?.rootCause;
    final rows = <Widget>[];
    if (cause?.primary != null) {
      rows.add(_CauseRow(
        label: FirmwareTextAdapter.label(context, 'primary'),
        value: FirmwareTextAdapter.text(context, cause!.primary),
        strong: true,
      ));
    }
    if (cause?.secondary != null) {
      rows.add(_CauseRow(
        label: FirmwareTextAdapter.label(context, 'secondary'),
        value: FirmwareTextAdapter.text(context, cause!.secondary),
      ));
    }
    if (cause?.additionalContributor != null) {
      rows.add(_CauseRow(
        label: FirmwareTextAdapter.label(context, 'contributor'),
        value: FirmwareTextAdapter.text(context, cause!.additionalContributor),
      ));
    }

    final evidence = edge?.stressEvidence;
    final evidenceWidgets = <Widget>[];
    void addEvidence(String label, double? value) {
      if (value == null) return;
      evidenceWidgets.add(_EvidenceBar(label: label, value: value));
    }

    addEvidence('Water stress evidence', evidence?.water);
    addEvidence('Heat stress evidence', evidence?.heat);
    addEvidence('Root-zone stress evidence', evidence?.rootZone);
    addEvidence('Sensor reliability issue', evidence?.sensorFault);

    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'happening'),
      icon: Icons.manage_search_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isEmpty)
            Text(FirmwareTextAdapter.label(context, 'no_major_stress'))
          else
            ..._separate(rows),
          if (evidenceWidgets.isNotEmpty) ...[
            const SizedBox(height: 14),
            ..._separate(evidenceWidgets),
          ],
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final EdgeIntelligence? edge;

  const _PredictionCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final prediction = edge?.prediction;
    final hasPrediction = prediction?.hasData == true;
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'next'),
      icon: Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasPrediction
                ? FirmwareTextAdapter.text(
                    context,
                    prediction?.explanation ?? prediction?.state,
                  )
                : FirmwareTextAdapter.label(context, 'no_prediction'),
          ),
          if (prediction?.minutesToWaterStressWarning != null) ...[
            const SizedBox(height: 10),
            Text(
              'Estimated warning window: ${_durationText(prediction!.minutesToWaterStressWarning!)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          if (prediction?.confidence != null) ...[
            const SizedBox(height: 6),
            Text('Prediction confidence: ${prediction!.confidence!.round()}%'),
          ],
          if (prediction?.whatIfExplanation != null) ...[
            const SizedBox(height: 10),
            Text(FirmwareTextAdapter.text(
                context, prediction!.whatIfExplanation)),
          ],
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  final EdgeIntelligence? edge;

  const _WhyCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final explanation = FirmwareTextAdapter.text(
      context,
      edge?.decisionExplanation,
      fallback: FirmwareTextAdapter.label(context, 'monitor'),
    );
    final derived = edge?.derivedEnvironment;
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'why'),
      icon: Icons.psychology_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(explanation),
          if (derived?.airDryingDemand != null) ...[
            const SizedBox(height: 10),
            Text(
              '${FirmwareTextAdapter.label(context, 'air_drying')}: ${derived!.airDryingDemand!.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          if (edge?.baseline.anomalyDetected == true ||
              edge?.baseline.changePointDetected == true) ...[
            const SizedBox(height: 8),
            const Text('This value changed unusually compared with the plant’s recent pattern.'),
          ],
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final EdgeIntelligence edge;

  const _RecoveryCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final recovery = edge.recovery;
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'recovery'),
      icon: Icons.autorenew_rounded,
      accent: Theme.of(context).colorScheme.tertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FirmwareTextAdapter.text(
              context,
              recovery.quality ?? edge.plantState,
              fallback: 'Recovery is being monitored.',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (recovery.improved != null) ...[
            const SizedBox(height: 8),
            Text('Improved: ${FirmwareTextAdapter.text(context, recovery.improved)}'),
          ],
          if (recovery.remainingConcern != null) ...[
            const SizedBox(height: 6),
            Text('Still watching: ${FirmwareTextAdapter.text(context, recovery.remainingConcern)}'),
          ],
          if (edge.irrigation.hasData) ...[
            const SizedBox(height: 10),
            Text(
              edge.irrigation.probable
                  ? '${FirmwareTextAdapter.label(context, 'irrigation_detected')}${edge.irrigation.response == null ? '' : ': ${FirmwareTextAdapter.text(context, edge.irrigation.response)}'}'
                  : FirmwareTextAdapter.text(context, edge.irrigation.response),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorSummaryCard extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;

  const _SensorSummaryCard({required this.reading, required this.edge});

  @override
  Widget build(BuildContext context) {
    final confidences = edge?.sensorConfidence ?? const <SensorConfidence>[];
    final faults = edge?.sensorFaults ?? const <SensorFaultInfo>[];
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'sensor_summary'),
      icon: Icons.sensors_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${reading.availableChannelCount} sensor channels currently usable'),
          if (confidences.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...confidences.take(7).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Expanded(child: Text(_friendlyChannel(item.channel))),
                        Text(
                          item.percent == null
                              ? FirmwareTextAdapter.text(context, item.state, fallback: '—')
                              : '${item.percent!.round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (faults.isNotEmpty) ...[
            const Divider(height: 22),
            ...faults.take(4).map(
                  (fault) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 19,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_friendlyChannel(fault.channel)}: ${FirmwareTextAdapter.text(context, fault.explanation ?? fault.type, fallback: 'Check this sensor.')}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;

  const _ConfidenceCard({required this.reading, required this.edge});

  @override
  Widget build(BuildContext context) {
    final value = edge?.overallConfidence ?? reading.analysisConfidence;
    final description = value >= 80
        ? 'High confidence — major available sensors are agreeing.'
        : value >= 55
            ? 'Medium confidence — use the result with the sensor notes below.'
            : FirmwareTextAdapter.label(context, 'low_confidence_warning');
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'confidence'),
      icon: Icons.verified_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${value.round()}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              _Pill(
                label: edge?.degradedAnalysis == true
                    ? FirmwareTextAdapter.label(context, 'degraded_analysis')
                    : FirmwareTextAdapter.label(context, 'full_analysis'),
                color: edge?.degradedAnalysis == true
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
          if (edge?.degradedReason != null) ...[
            const SizedBox(height: 8),
            Text(FirmwareTextAdapter.text(context, edge!.degradedReason)),
          ],
        ],
      ),
    );
  }
}

class _DiseaseRiskCard extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;

  const _DiseaseRiskCard({required this.reading, required this.edge});

  @override
  Widget build(BuildContext context) {
    final score = edge?.diseaseRiskScore ?? reading.diseaseRisk;
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'environmental_risk'),
      icon: Icons.spa_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edge?.diseaseRiskLevel != null
                ? FirmwareTextAdapter.text(context, edge!.diseaseRiskLevel)
                : score == null
                    ? 'Monitoring'
                    : '${score.round()} / 100',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(FirmwareTextAdapter.label(context, 'environmental_note')),
        ],
      ),
    );
  }
}

class _AvoidCard extends StatelessWidget {
  final EdgeIntelligence? edge;

  const _AvoidCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final lowConfidence = (edge?.overallConfidence ?? 100) < 55 ||
        edge?.sensorFaults.isNotEmpty == true;
    final text = lowConfidence
        ? FirmwareTextAdapter.label(context, 'low_confidence_warning')
        : 'Avoid treating one unusual reading as a confirmed disease or changing several conditions at once.';
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'avoid'),
      icon: Icons.block_outlined,
      child: Text(text),
    );
  }
}

class _WatchNextCard extends StatelessWidget {
  final EdgeIntelligence? edge;

  const _WatchNextCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    final trends = edge?.trends ?? const <SensorTrend>[];
    final notable = trends.where((trend) {
      final state = trend.state?.toLowerCase() ?? '';
      return state.contains('fall') ||
          state.contains('ris') ||
          state.contains('dry') ||
          state.contains('wet') ||
          state.contains('unstable');
    }).take(3).toList();

    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'watch'),
      icon: Icons.visibility_outlined,
      child: notable.isEmpty
          ? Text(FirmwareTextAdapter.label(context, 'monitor'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: notable
                  .map((trend) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text(
                          '• ${_friendlyChannel(trend.channel)}: ${FirmwareTextAdapter.text(context, trend.state)}',
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

class _EventsCard extends StatelessWidget {
  final EdgeIntelligence edge;

  const _EventsCard({required this.edge});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: FirmwareTextAdapter.label(context, 'events'),
      icon: Icons.history_rounded,
      child: Column(
        children: edge.recentEvents
            .take(6)
            .map(
              (event) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.circle, size: 10),
                title: Text(FirmwareTextAdapter.text(context, event.message)),
                subtitle: event.timestamp == null
                    ? null
                    : Text(_timeText(event.timestamp!)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TechnicalDetails extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;

  const _TechnicalDetails({required this.reading, required this.edge});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.tune_rounded),
        title: Text(
          FirmwareTextAdapter.label(context, 'technical'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _TechnicalRow('Firmware', edge?.firmwareVersion ?? 'Unknown'),
          _TechnicalRow(
            'Health source',
            edge?.hasAuthoritativeAnalysis == true
                ? 'ESP32 edge intelligence'
                : 'Compatibility fallback',
          ),
          if (edge?.cropProfile.profile != null)
            _TechnicalRow(
              FirmwareTextAdapter.label(context, 'profile'),
              edge!.cropProfile.profile!,
            ),
          if (edge?.cropProfile.growthStage != null)
            _TechnicalRow(
              FirmwareTextAdapter.label(context, 'stage'),
              edge!.cropProfile.growthStage!,
            ),
          if (edge?.derivedEnvironment.vpdKpa != null)
            _TechnicalRow(
              FirmwareTextAdapter.label(context, 'vpd'),
              '${edge!.derivedEnvironment.vpdKpa!.toStringAsFixed(2)} kPa',
            ),
          if (reading.plantVoltageMv != null)
            _TechnicalRow(
              'AD620 amplifier output',
              '${reading.plantVoltageMv!.toStringAsFixed(1)} mV',
            ),
          if (reading.bioBaselineMv != null)
            _TechnicalRow(
              'Bioelectric baseline',
              '${reading.bioBaselineMv!.toStringAsFixed(1)} mV',
            ),
          if (reading.bioDeviationMv != null)
            _TechnicalRow(
              'Baseline deviation',
              '${reading.bioDeviationMv!.toStringAsFixed(1)} mV',
            ),
          if (edge?.activeSensorChannels.isNotEmpty == true)
            _TechnicalRow(
              FirmwareTextAdapter.label(context, 'active_channels'),
              edge!.activeSensorChannels.join(', '),
            ),
          if (edge?.tinyMl.hasData == true) ...[
            _TechnicalRow(
              FirmwareTextAdapter.label(context, 'tinyml'),
              edge!.tinyMl.modelLoaded
                  ? FirmwareTextAdapter.label(context, 'model_loaded')
                  : FirmwareTextAdapter.label(context, 'model_not_loaded'),
            ),
            if (!edge!.tinyMl.modelLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  FirmwareTextAdapter.label(context, 'explainable_engine'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
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
                  Text(
                    FirmwareTextAdapter.label(context, 'disconnected'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (reading != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${FirmwareTextAdapter.label(context, 'last_reading')}: ${_timeText(reading!.timestamp)}',
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

class _WaitingForReadingCard extends StatelessWidget {
  const _WaitingForReadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 14),
            Expanded(child: Text('Waiting for a validated ESP32 reading…')),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accent;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveAccent, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _CauseRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _CauseRow({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EvidenceBar extends StatelessWidget {
  final String label;
  final double value;

  const _EvidenceBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final bounded = value.clamp(0.0, 100.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${bounded.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: bounded / 100,
          minHeight: 6,
          borderRadius: BorderRadius.circular(99),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _TechnicalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TechnicalRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            flex: 5,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

List<Widget> _separate(List<Widget> widgets) {
  final result = <Widget>[];
  for (var i = 0; i < widgets.length; i++) {
    if (i > 0) result.add(const SizedBox(height: 9));
    result.add(widgets[i]);
  }
  return result;
}

String _friendlyChannel(String raw) {
  final value = raw
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
      .trim();
  if (value.isEmpty) return 'Sensor';
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _durationText(double minutes) {
  if (minutes < 60) return '${minutes.round()} min';
  final hours = minutes / 60;
  return '${hours.toStringAsFixed(hours < 10 ? 1 : 0)} h';
}

String _timeText(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
