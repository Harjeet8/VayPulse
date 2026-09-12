import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/biotic_stress_card.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';
import 'leaf_screening_screen.dart';

class FarmerAnalysisScreen extends StatefulWidget {
  const FarmerAnalysisScreen({super.key});

  @override
  State<FarmerAnalysisScreen> createState() => _FarmerAnalysisScreenState();
}

class _FarmerAnalysisScreenState extends State<FarmerAnalysisScreen> {
  bool _advancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final reading = sensors.current;
        final edge = sensors.edgeIntelligence;
        final live = sensors.source == SensorDataSource.esp32;
        final canShowCurrent =
            !live || sensors.connectionStatus == SensorConnectionStatus.ready;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _analysisText(context, 'Plant care', 'செடி பராமரிப்பு'),
            ),
            actions: [
              IconButton(
                tooltip: FarmerLanguage.label(context, 'speak_summary'),
                onPressed: reading == null
                    ? null
                    : () => _speakSummary(
                          context,
                          reading,
                          edge,
                        ),
                icon: const Icon(Icons.volume_up_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              sensors.retry();
              await Future<void>.delayed(const Duration(milliseconds: 450));
            },
            child: PageFrame(
              children: [
                PhytoPageIntro(
                  eyebrow: live
                      ? _analysisText(
                          context,
                          'Real sensor guidance',
                          'நேரடி சென்சார் வழிகாட்டுதல்',
                        )
                      : _analysisText(
                          context,
                          'Simulation practice',
                          'சிமுலேஷன் பயிற்சி',
                        ),
                  title: _analysisText(
                    context,
                    'See the problem. Know what to do.',
                    'பிரச்சினையை அறிந்து, என்ன செய்ய வேண்டும் என்று தெரிந்துகொள்ளுங்கள்.',
                  ),
                  body: _analysisText(
                    context,
                    'The most important answer is shown first in simple words.',
                    'முக்கியமான பதில் எளிய வார்த்தைகளில் முதலில் காட்டப்படும்.',
                  ),
                  icon: Icons.eco_rounded,
                ),
                const SizedBox(height: 18),
                if (!canShowCurrent)
                  _ConnectionNotice(
                    reading: reading,
                    live: live,
                    onRetry: sensors.retry,
                  )
                else if (edge?.firmwareCompatible == false)
                  const _FirmwareCompatibilityNotice()
                else if (reading == null)
                  _WaitingCard(live: live, onRetry: sensors.retry)
                else ...[
                  _FarmerResultHero(
                    reading: reading,
                    edge: edge,
                    live: live,
                  ),
                  const SizedBox(height: 10),
                  if (edge?.bioticStress.suspected == true) ...[
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
                    const SizedBox(height: 10),
                  ],
                  if (edge?.cameraInspectionRecommended == true &&
                      edge?.bioticStress.suspected != true) ...[
                    _CameraRecommendationCard(
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
                    const SizedBox(height: 10),
                  ],
                  _EvidencePanel(
                    reading: reading,
                    edge: edge,
                    live: live,
                  ),
                  const SizedBox(height: 12),
                  _AdvancedDetails(
                    reading: reading,
                    edge: edge,
                    expanded: _advancedExpanded,
                    onExpansionChanged: (value) {
                      if (_advancedExpanded == value) return;
                      setState(() => _advancedExpanded = value);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _speakSummary(
    BuildContext context,
    SensorReading reading,
    EdgeIntelligence? edge,
  ) async {
    final scope = AppScope.of(context);
    final rawState = edge?.plantState ?? reading.healthStatus;
    final possibleBiotic = edge?.bioticStress.suspected == true;
    final recovering = edge?.recovery.active == true ||
        rawState.toUpperCase().contains('RECOVER');
    final healthy =
        !possibleBiotic && !recovering && _isFarmerHealthyState(rawState);
    final problem = _farmerProblem(
      context,
      possibleBiotic
          ? FarmerLanguage.label(context, 'possible_biotic_title')
          : edge?.rootCause.primary ?? edge?.farmerSummary,
      healthy: healthy,
      possibleBiotic: possibleBiotic,
    );
    final action = _farmerAction(
      context,
      edge,
      problem: problem,
      healthy: healthy,
      recovering: recovering,
      possibleBiotic: possibleBiotic,
    );
    final phrases = <String>[
      _farmerStatus(
        context,
        rawState,
        healthy: healthy,
        recovering: recovering,
        possibleBiotic: possibleBiotic,
      ),
      problem,
      action,
    ].where((value) => value.trim().isNotEmpty).toSet().toList();
    if (phrases.isEmpty) return;

    final spoken = await scope.voice.speak(
      text: phrases.join('. '),
      languageCode: scope.settings.value.languageCode,
    );
    if (!context.mounted || spoken) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(FarmerLanguage.label(context, 'voice_unavailable')),
      ),
    );
  }
}

class _FarmerResultHero extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;
  final bool live;

  const _FarmerResultHero({
    required this.reading,
    required this.edge,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final rawState = edge?.plantState ?? reading.healthStatus;
    final possibleBiotic = edge?.bioticStress.suspected == true;
    final recovering = edge?.recovery.active == true ||
        rawState.toUpperCase().contains('RECOVER');
    final healthy =
        !possibleBiotic && !recovering && _isFarmerHealthyState(rawState);
    final rawProblem = possibleBiotic
        ? FarmerLanguage.label(context, 'possible_biotic_title')
        : edge?.rootCause.primary ??
            edge?.farmerSummary ??
            edge?.bioelectric.farmerResult;
    final status = _farmerStatus(
      context,
      rawState,
      healthy: healthy,
      recovering: recovering,
      possibleBiotic: possibleBiotic,
    );
    final problem = _farmerProblem(
      context,
      rawProblem,
      healthy: healthy,
      possibleBiotic: possibleBiotic,
    );
    final action = _farmerAction(
      context,
      edge,
      problem: problem,
      healthy: healthy,
      recovering: recovering,
      possibleBiotic: possibleBiotic,
    );
    final confidence = _finitePercent(
      edge?.overallConfidence ??
          reading.esp32HealthConfidence ??
          reading.analysisConfidence,
    );
    final crop = edge?.cropProfile.profile ?? 'Universal';
    final stage = edge?.cropProfile.growthStage;
    final accent = _conditionColor(context, rawState);
    final sourceColor =
        live ? const Color(0xFF2879B9) : const Color(0xFFE17A22);

    return Semantics(
      key: const Key('farmer-care-summary'),
      container: true,
      label: '$status. $problem. $action',
      child: PhytoSurface(
        color: accent.withValues(alpha: 0.075),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass_rounded, color: accent, size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stage == null || stage.trim().isEmpty
                        ? FarmerLanguage.firmware(context, crop)
                        : '${FarmerLanguage.firmware(context, crop)}  •  ${FarmerLanguage.firmware(context, stage)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: sourceColor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    live ? 'LIVE ESP32' : 'DEMO DATA',
                    style: TextStyle(
                      color: sourceColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    healthy
                        ? Icons.check_rounded
                        : recovering
                            ? Icons.trending_up_rounded
                            : Icons.priority_high_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _analysisText(
                          context,
                          'PLANT CONDITION',
                          'செடியின் நிலை',
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: accent,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: accent.withValues(alpha: 0.18)),
            const SizedBox(height: 18),
            Text(
              _analysisText(context, 'WHAT IS WRONG?', 'என்ன பிரச்சினை?'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.75,
                  ),
            ),
            const SizedBox(height: 7),
            Text(
              problem,
              key: const Key('farmer-main-problem'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 23,
                    height: 1.24,
                  ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _analysisText(
                      context,
                      'WHAT TO DO NOW',
                      'இப்போது என்ன செய்ய வேண்டும்',
                    ),
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    action,
                    key: const Key('farmer-immediate-action'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          height: 1.38,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _ResultMetric(
                    label: FarmerLanguage.label(context, 'confidence'),
                    value: confidence == null
                        ? FarmerLanguage.label(context, 'not_available')
                        : '${FarmerLanguage.confidence(context, confidence)} • ${confidence.round()}%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultMetric(
                    label: FarmerLanguage.label(context, 'trend'),
                    value: _conditionTrend(context, edge),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _EvidencePanel extends StatelessWidget {
  final SensorReading reading;
  final EdgeIntelligence? edge;
  final bool live;

  const _EvidencePanel({
    required this.reading,
    required this.edge,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_EvidenceItem>[];
    if (reading.soilMoistureAvailable) {
      final firmwareState = edge?.waterBalance.state;
      items.add(
        _EvidenceItem(
          icon: Icons.water_drop_outlined,
          label: _analysisText(context, 'Soil near roots', 'வேர் அருகே மண்'),
          value: firmwareState == null
              ? '${reading.soilMoisture.round()}%'
              : '${FarmerLanguage.firmware(context, firmwareState)} • ${reading.soilMoisture.round()}%',
        ),
      );
    }

    final airValues = <String>[
      if (reading.temperatureAvailable)
        '${reading.temperature.toStringAsFixed(1)}°C',
      if (reading.humidityAvailable)
        '${reading.humidity.round()}% ${_analysisText(context, 'humidity', 'ஈரப்பதம்')}',
    ];
    if (airValues.isNotEmpty) {
      items.add(
        _EvidenceItem(
          icon: Icons.air_rounded,
          label: _analysisText(
              context, 'Air around plant', 'செடியை சுற்றிய காற்று'),
          value: airValues.join(' • '),
        ),
      );
    }

    final bio = edge?.bioelectric;
    final presentationSignal =
        bio?.presentationOnly == true || reading.bioIsPresentation;
    if (bio?.hasData == true || reading.plantSignalAvailable) {
      final voltage = bio?.voltageMv ?? reading.plantVoltageMv;
      final signalValue = presentationSignal
          ? voltage == null
              ? 'NORMAL • STABLE'
              : '${voltage.round()} mV • NORMAL • STABLE'
          : bio?.displayAvailable == false
              ? _analysisText(
                  context,
                  'Sensor needs checking',
                  'சென்சாரை சரிபார்க்க வேண்டும்',
                )
              : FarmerLanguage.firmware(
                  context,
                  bio?.stressState ?? bio?.signalQualityState,
                  fallback: voltage == null
                      ? FarmerLanguage.label(context, 'not_available')
                      : '${voltage.round()} mV',
                );
      items.add(
        _EvidenceItem(
          icon: Icons.bolt_rounded,
          label: presentationSignal
              ? 'Real Time Signal'
              : _analysisText(context, 'Plant signal', 'செடி சிக்னல்'),
          value: signalValue,
          note: presentationSignal
              ? _analysisText(
                  context,
                  'Real Time Signal is updating normally. Does not affect plant health.',
                  'Real Time Signal வழக்கம்போல் புதுப்பிக்கப்படுகிறது. இது செடி ஆரோக்கிய முடிவை மாற்றாது.',
                )
              : null,
        ),
      );
    }

    final confidence = _finitePercent(
      edge?.overallConfidence ??
          reading.esp32HealthConfidence ??
          reading.analysisConfidence,
    );
    return PhytoSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _analysisText(
                    context,
                    'Why PhytoSense says this',
                    'PhytoSense ஏன் இதைச் சொல்கிறது',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PhytoStatusBadge(
                label: live
                    ? _analysisText(context, 'REAL DATA', 'நேரடி DATA')
                    : _analysisText(context, 'SIMULATION', 'சிமுலேஷன்'),
                icon: live ? Icons.memory_rounded : Icons.science_outlined,
                color: live
                    ? const Color(0xFF3E789F)
                    : Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(FarmerLanguage.label(context, 'why_unavailable'))
          else
            for (var index = 0; index < items.take(3).length; index++) ...[
              _EvidenceRow(item: items[index]),
              if (index < items.take(3).length - 1) const Divider(height: 22),
            ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ResultMetric(
                    label: FarmerLanguage.label(context, 'trend'),
                    value: _conditionTrend(context, edge),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultMetric(
                    label: FarmerLanguage.label(context, 'confidence'),
                    value: confidence == null
                        ? FarmerLanguage.label(context, 'not_available')
                        : FarmerLanguage.confidence(context, confidence),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceItem {
  final IconData icon;
  final String label;
  final String value;
  final String? note;

  const _EvidenceItem({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });
}

class _EvidenceRow extends StatelessWidget {
  final _EvidenceItem item;

  const _EvidenceRow({required this.item});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(item.value,
                    style: Theme.of(context).textTheme.titleMedium),
                if (item.note != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

// Kept as an engineering-view building block for firmware compatibility.
// ignore: unused_element
class _BioelectricHero extends StatelessWidget {
  final BioelectricIntelligence bio;

  const _BioelectricHero({required this.bio});

  @override
  Widget build(BuildContext context) {
    final displayOnly = bio.presentationOnly;
    final excluded = !displayOnly && bio.excludedByFirmware;
    final learning = !displayOnly && !excluded && bio.learningBaseline;
    final colors = Theme.of(context).colorScheme;
    final accent = excluded
        ? colors.error
        : learning
            ? colors.tertiary
            : colors.primary;
    final state = displayOnly
        ? 'NORMAL • STABLE'
        : excluded
            ? FarmerLanguage.label(context, 'signal_unavailable')
            : learning
                ? FarmerLanguage.label(context, 'learning_baseline')
                : FarmerLanguage.firmware(
                    context,
                    bio.stressState ?? bio.signalQualityState,
                    fallback: FarmerLanguage.label(
                      context,
                      'plant_response_no_result',
                    ),
                  );
    final explanation = displayOnly
        ? 'Real Time Signal is updating normally.'
        : excluded
            ? FarmerLanguage.label(context, 'bio_signal_check_electrodes')
            : learning
                ? FarmerLanguage.label(context, 'bio_learning_body')
                : FarmerLanguage.firmware(
                    context,
                    bio.farmerResult ?? bio.interpretation,
                    fallback: FarmerLanguage.label(
                      context,
                      'plant_response_no_result',
                    ),
                  );

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.electric_bolt_rounded, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  displayOnly
                      ? bio.displayLabel
                      : FarmerLanguage.label(context, 'bioelectric_response'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (displayOnly && bio.voltageMv != null) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Text(
                '${bio.voltageMv!.round()} mV',
                key: ValueKey<int>(bio.voltageMv!.round()),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            state,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 7),
          Text(explanation),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 7,
            children: [
              if (!displayOnly &&
                  !excluded &&
                  !learning &&
                  bio.stressScore != null)
                Text(
                  '${FarmerLanguage.label(context, 'stress_score')}: ${bio.stressScore!.round()} / 100',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              if (bio.signalQuality != null)
                Text(
                  '${FarmerLanguage.label(context, 'bio_signal_quality')}: ${bio.signalQuality!.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              if (displayOnly)
                const Text(
                  'Does not affect plant health',
                  style: TextStyle(fontWeight: FontWeight.w800),
                )
              else if (bio.includedInFusion != null)
                Text(
                  bio.includedInFusion!
                      ? FarmerLanguage.label(context, 'included_in_analysis')
                      : FarmerLanguage.label(context, 'excluded_from_analysis'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
            ],
          ),
          if (learning && bio.baselineSamples != null) ...[
            const SizedBox(height: 11),
            Text(
              bio.baselineTarget == null
                  ? '${FarmerLanguage.label(context, 'baseline_samples')}: ${bio.baselineSamples}'
                  : '${FarmerLanguage.label(context, 'baseline_progress')}: ${bio.baselineSamples}/${bio.baselineTarget}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (bio.baselineTarget != null && bio.baselineTarget! > 0) ...[
              const SizedBox(height: 7),
              LinearProgressIndicator(
                value: (bio.baselineSamples! / bio.baselineTarget!)
                    .clamp(0.0, 1.0),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// Kept for the optional advanced hardware view.
// ignore: unused_element
class _WaterBalanceCard extends StatelessWidget {
  final WaterBalanceInfo waterBalance;

  const _WaterBalanceCard({required this.waterBalance});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.water_drop_outlined, color: color, size: 30),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FarmerLanguage.label(context, 'root_zone_water'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    FarmerLanguage.firmware(
                      context,
                      waterBalance.state,
                      fallback: FarmerLanguage.label(
                        context,
                        'not_available',
                      ),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (waterBalance.score != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      '${waterBalance.score!.round()} / 100',
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w900),
                    ),
                  ],
                  if (waterBalance.explanation != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      FarmerLanguage.firmware(
                        context,
                        waterBalance.explanation,
                      ),
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

class _FirmwareCompatibilityNotice extends StatelessWidget {
  const _FirmwareCompatibilityNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: ListTile(
        leading: Icon(Icons.system_update_alt_rounded,
            color: colors.onErrorContainer),
        title: Text(
          FarmerLanguage.label(context, 'firmware_compatibility_title'),
          style: TextStyle(
            color: colors.onErrorContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          FarmerLanguage.label(context, 'firmware_compatibility_body'),
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}

class _CameraRecommendationCard extends StatelessWidget {
  final EdgeIntelligence edge;
  final VoidCallback onScan;

  const _CameraRecommendationCard({required this.edge, required this.onScan});

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
}

// Kept for downstream extension screens without duplicating farmer guidance.
// ignore: unused_element
class _AnswerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _AnswerCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
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
            const SizedBox(width: 13),
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
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.35,
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

// Kept for the optional engineering confidence surface.
// ignore: unused_element
class _ConfidenceCard extends StatelessWidget {
  final double? value;
  final bool degraded;
  final String? degradedReason;

  const _ConfidenceCard({
    required this.value,
    required this.degraded,
    required this.degradedReason,
  });

  @override
  Widget build(BuildContext context) {
    final band = FarmerLanguage.confidence(context, value);
    final color = value == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : value! >= 80
            ? Theme.of(context).colorScheme.primary
            : value! >= 55
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_outlined, color: color, size: 30),
            const SizedBox(width: 13),
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
                    const SizedBox(height: 5),
                    Text(
                      FarmerLanguage.firmware(
                        context,
                        degradedReason,
                        fallback:
                            FarmerLanguage.label(context, 'degraded_body'),
                      ),
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
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;

  const _AdvancedDetails({
    required this.reading,
    required this.edge,
    required this.expanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bio = edge?.bioelectric;
    final exactConfidence =
        edge?.overallConfidence ?? reading.esp32HealthConfidence;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const PageStorageKey<String>('farmer-analysis-advanced-details'),
        initiallyExpanded: expanded,
        maintainState: true,
        onExpansionChanged: onExpansionChanged,
        leading: const Icon(Icons.tune_rounded),
        title: Text(
          FarmerLanguage.label(context, 'advanced_details'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _Row('Firmware', edge?.firmwareVersion ?? 'Unknown'),
          if (edge?.schemaVersion != null)
            _Row('API schema', 'v${edge!.schemaVersion}'),
          if (edge?.apiVersion != null) _Row('API version', edge!.apiVersion!),
          if (edge?.compatibilityIssue != null)
            _Row('Compatibility', edge!.compatibilityIssue!),
          if (edge?.healthScore != null)
            _Row('Health score', '${edge!.healthScore!.round()} / 100'),
          if (exactConfidence != null)
            _Row('Exact confidence', '${exactConfidence.round()}%'),
          if (edge?.cropProfile.profile != null)
            _Row('Crop profile', edge!.cropProfile.profile!),
          if (edge?.cropProfile.growthStage != null)
            _Row('Growth stage', edge!.cropProfile.growthStage!),
          if (edge?.cropProfile.regionProfile != null)
            _Row('Region profile', edge!.cropProfile.regionProfile!),
          if (edge?.analysisQuality != null)
            _Row('Analysis quality', edge!.analysisQuality!),
          if (edge?.rootCause.primary != null)
            _Row('Primary cause', edge!.rootCause.primary!),
          if (edge?.rootCause.primaryCandidate?.confidence != null)
            _Row(
              'Primary cause confidence',
              '${edge!.rootCause.primaryCandidate!.confidence!.round()}%',
            ),
          if (edge?.rootCause.primaryCandidate?.evidenceFor != null)
            _Row(
                'Evidence for', edge!.rootCause.primaryCandidate!.evidenceFor!),
          if (edge?.rootCause.primaryCandidate?.evidenceAgainst != null)
            _Row('Evidence against',
                edge!.rootCause.primaryCandidate!.evidenceAgainst!),
          if (edge?.rootCause.secondary != null)
            _Row('Secondary cause', edge!.rootCause.secondary!),
          if (edge?.rootCause.secondaryCandidate?.confidence != null)
            _Row(
              'Secondary confidence',
              '${edge!.rootCause.secondaryCandidate!.confidence!.round()}%',
            ),
          if (edge?.rootCause.ranked.isNotEmpty == true)
            _Row(
              'Ranked causes',
              edge!.rootCause.ranked
                  .where((candidate) => candidate.name != null)
                  .map((candidate) => candidate.confidence == null
                      ? candidate.name!
                      : '${candidate.name!} (${candidate.confidence!.round()}%)')
                  .join(' • '),
            ),
          if (edge?.degradedReason != null)
            _Row('Reduced-confidence reason', edge!.degradedReason!),
          if (edge?.degradedReasons.isNotEmpty == true)
            _Row('Reduced-confidence reasons',
                edge!.degradedReasons.join(' • ')),
          if (edge?.derivedEnvironment.vpdKpa != null)
            _Row(
              'VPD',
              '${edge!.derivedEnvironment.vpdKpa!.toStringAsFixed(2)} kPa',
            ),
          if (bio?.voltageMv != null)
            _Row('Plant amplifier output',
                '${bio!.voltageMv!.toStringAsFixed(1)} mV'),
          if (bio?.baselineMv != null)
            _Row('Bioelectric baseline',
                '${bio!.baselineMv!.toStringAsFixed(1)} mV'),
          if (bio?.signedChangeMv != null)
            _Row('Signed change',
                '${bio!.signedChangeMv!.toStringAsFixed(1)} mV'),
          if (bio?.normalizedDeviation != null)
            _Row('Normalized deviation',
                '${bio!.normalizedDeviation!.toStringAsFixed(1)}%'),
          if (bio?.noiseMv != null)
            _Row('Bioelectric noise', '${bio!.noiseMv!.toStringAsFixed(1)} mV'),
          if (bio?.signalQuality != null)
            _Row('Signal quality', '${bio!.signalQuality!.round()}%'),
          if (bio?.persistenceSeconds != null)
            _Row('Persistence', '${bio!.persistenceSeconds!.round()} sec'),
          if (bio?.stressLoadState != null)
            _Row('Stress load state', bio!.stressLoadState!),
          if (bio?.stressLoad != null)
            _Row('Stress load', bio!.stressLoad!.toStringAsFixed(1)),
          if (bio?.signalQualityState != null)
            _Row('Signal quality state', bio!.signalQualityState!),
          if (bio?.baselineReady != null)
            _Row('Baseline ready', bio!.baselineReady! ? 'Yes' : 'No'),
          if (bio?.baselineSamples != null)
            _Row(
              'Baseline samples',
              bio!.baselineTarget == null
                  ? '${bio.baselineSamples}'
                  : '${bio.baselineSamples}/${bio.baselineTarget}',
            ),
          if (bio?.zScore != null)
            _Row('Bio z-score', bio!.zScore!.toStringAsFixed(2)),
          if (bio?.spanMv != null)
            _Row('Bio span', '${bio!.spanMv!.toStringAsFixed(1)} mV'),
          if (bio?.includedInFusion != null)
            _Row(
              'Included in firmware fusion',
              bio!.includedInFusion! ? 'Yes' : 'No',
            ),
          if (edge?.waterBalance.hasData == true) ...[
            const Divider(height: 24),
            if (edge!.waterBalance.state != null)
              _Row('Water balance state', edge!.waterBalance.state!),
            if (edge!.waterBalance.score != null)
              _Row(
                'Water balance score',
                '${edge!.waterBalance.score!.round()} / 100',
              ),
            if (edge!.waterBalance.explanation != null)
              _Row(
                'Water balance explanation',
                edge!.waterBalance.explanation!,
              ),
          ],
          if (edge?.cameraHandoff.hasData == true) ...[
            const Divider(height: 24),
            _Row(
              'Camera scan recommended',
              edge!.cameraHandoff.recommended == true ? 'Yes' : 'No',
            ),
            if (edge!.cameraHandoff.reason != null)
              _Row('Camera handoff reason', edge!.cameraHandoff.reason!),
          ],
          if (edge?.bioticStress.hasData == true) ...[
            const Divider(height: 24),
            _Row(
              FarmerLanguage.label(context, 'biotic_analysis'),
              FarmerLanguage.firmware(
                context,
                edge!.bioticStress.state,
                fallback: FarmerLanguage.label(context, 'not_available'),
              ),
            ),
            if (edge!.bioticStress.evidenceScore != null)
              _Row(
                FarmerLanguage.label(context, 'biotic_evidence'),
                '${edge!.bioticStress.evidenceScore!.round()}%',
              ),
            if (edge!.bioticStress.confidence != null)
              _Row(
                FarmerLanguage.label(context, 'biotic_confidence'),
                '${edge!.bioticStress.confidence!.round()}%',
              ),
            if (bio?.stressScore != null)
              _Row(
                FarmerLanguage.label(context, 'bio_stress_score'),
                '${bio!.stressScore!.round()} / 100',
              ),
            if (bio?.signalQuality != null)
              _Row(
                FarmerLanguage.label(context, 'bio_signal_quality'),
                '${bio!.signalQuality!.round()}%',
              ),
            if (edge!.bioticStress.abioticCauseFound != null)
              _Row(
                FarmerLanguage.label(context, 'environmental_explanation'),
                edge!.bioticStress.abioticCauseFound!
                    ? FarmerLanguage.label(context, 'high')
                    : FarmerLanguage.label(context, 'low'),
              ),
            if (edge!.bioticStress.reason != null)
              _Row(
                FarmerLanguage.label(context, 'primary_interpretation'),
                edge!.bioticStress.reason!,
              ),
            if (edge!.bioticStress.recommendation != null)
              _Row(
                FarmerLanguage.label(context, 'biotic_recommendation'),
                edge!.bioticStress.recommendation!,
              ),
            if (edge!.compoundStress.waterEvidence != null)
              _Row(
                FarmerLanguage.label(context, 'water_stress_evidence'),
                '${edge!.compoundStress.waterEvidence!.round()}%',
              ),
            if (edge!.compoundStress.heatEvidence != null)
              _Row(
                FarmerLanguage.label(context, 'heat_stress_evidence'),
                '${edge!.compoundStress.heatEvidence!.round()}%',
              ),
            if (edge!.compoundStress.rootEvidence != null)
              _Row(
                FarmerLanguage.label(context, 'root_stress_evidence'),
                '${edge!.compoundStress.rootEvidence!.round()}%',
              ),
            if (edge!.compoundStress.atmosphericEvidence != null)
              _Row(
                FarmerLanguage.label(context, 'air_drying_evidence'),
                '${edge!.compoundStress.atmosphericEvidence!.round()}%',
              ),
          ],
          if (bio?.baselineLearningPaused != null)
            _Row(
              'Baseline learning',
              bio!.baselineLearningPaused! ? 'Paused' : 'Active',
            ),
          if (bio?.rawAdc != null)
            _Row('Raw ADC', bio!.rawAdc!.toStringAsFixed(0)),
          if (edge?.recovery.state != null)
            _Row('Recovery state', edge!.recovery.state!),
          if (edge?.recovery.confidence != null)
            _Row('Recovery confidence',
                '${edge!.recovery.confidence!.round()}%'),
          if (edge?.recovery.environmentImproved != null)
            _Row(
              'Environment improved',
              edge!.recovery.environmentImproved! ? 'Yes' : 'No',
            ),
          if (edge?.recovery.bioResponseDecreasing != null)
            _Row(
              'Plant response decreasing',
              edge!.recovery.bioResponseDecreasing! ? 'Yes' : 'No',
            ),
          if (edge?.recovery.farmerResult != null)
            _Row('Recovery result', edge!.recovery.farmerResult!),
          if (edge?.compoundStress.state != null)
            _Row('Compound stress', edge!.compoundStress.state!),
          if (edge?.compoundStress.severity != null)
            _Row('Compound severity',
                '${edge!.compoundStress.severity!.round()} / 100'),
          if (edge?.prediction.hasData == true)
            _Row(
              'Prediction',
              edge!.prediction.message ??
                  edge!.prediction.explanation ??
                  edge!.prediction.state ??
                  'Unavailable',
            ),
          if (edge?.prediction.target != null)
            _Row('Prediction target', edge!.prediction.target!),
          if (edge?.prediction.minutesToWarning != null)
            _Row(
              'Minutes to warning',
              edge!.prediction.minutesToWarning!.toStringAsFixed(0),
            ),
          if (edge?.responseLag.environmentToBioResponseSeconds != null)
            _Row(
              'Environment → plant response lag',
              '${edge!.responseLag.environmentToBioResponseSeconds!.round()} sec',
            ),
          if (edge?.responseLag.irrigationToBioDecreaseSeconds != null)
            _Row(
              'Irrigation → response decrease lag',
              '${edge!.responseLag.irrigationToBioDecreaseSeconds!.round()} sec',
            ),
          if (edge?.responseLag.interpretation != null)
            _Row('Response timing note', edge!.responseLag.interpretation!),
          if (edge?.anomaly.state != null)
            _Row('Anomaly state', edge!.anomaly.state!),
          if (edge?.anomaly.score != null)
            _Row('Anomaly score', '${edge!.anomaly.score!.round()} / 100'),
          if (edge?.anomaly.reason != null)
            _Row('Anomaly reason', edge!.anomaly.reason!),
          if (edge?.sensorFaults.isNotEmpty == true)
            _Row('Sensor issues', edge!.sensorFaults.length.toString()),
          if (edge?.tinyMl.hasData == true)
            _Row(
              'TinyML model',
              edge!.tinyMl.modelLoaded ? 'Loaded' : 'Not loaded',
            ),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _ConnectionNotice extends StatelessWidget {
  final SensorReading? reading;
  final bool live;
  final VoidCallback onRetry;

  const _ConnectionNotice({
    required this.reading,
    required this.live,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => PhytoStatePanel(
        icon: live
            ? Icons.portable_wifi_off_rounded
            : Icons.hourglass_top_rounded,
        title: FarmerLanguage.label(
          context,
          live ? 'disconnected' : 'simulation_waiting',
        ),
        body: live
            ? _analysisText(
                context,
                reading == null
                    ? 'No current reading is shown. Connect to the ESP32 and try again.'
                    : 'The last reading is saved, but it is not shown as live. Last received at ${_time(reading!.timestamp)}.',
                reading == null
                    ? 'தற்போதைய அளவீடு காட்டப்படவில்லை. ESP32-ஐ இணைத்து மீண்டும் முயற்சிக்கவும்.'
                    : 'கடைசி அளவீடு சேமிக்கப்பட்டுள்ளது; அது நேரடி அளவீடாக காட்டப்படாது. கடைசியாக கிடைத்த நேரம் ${_time(reading!.timestamp)}.',
              )
            : FarmerLanguage.label(context, 'simulation_waiting'),
        actionLabel: _analysisText(context, 'Try again', 'மீண்டும் முயற்சி'),
        onAction: onRetry,
      );
}

class _WaitingCard extends StatelessWidget {
  final bool live;
  final VoidCallback onRetry;

  const _WaitingCard({required this.live, required this.onRetry});

  @override
  Widget build(BuildContext context) => PhytoStatePanel(
        icon: Icons.sensors_rounded,
        title: FarmerLanguage.label(
          context,
          live ? 'waiting_esp32' : 'simulation_waiting',
        ),
        body: _analysisText(
          context,
          live
              ? 'PhytoSense will show the plant result after a fresh ESP32 reading arrives.'
              : 'Demo values are being prepared. They will stay separate from real sensor data.',
          live
              ? 'புதிய ESP32 அளவீடு வந்ததும் செடியின் முடிவு காட்டப்படும்.'
              : 'மாதிரி மதிப்புகள் தயாராகின்றன. அவை நேரடி சென்சார் தரவுடன் கலக்கப்படாது.',
        ),
        loading: true,
        actionLabel: _analysisText(context, 'Try again', 'மீண்டும் முயற்சி'),
        onAction: onRetry,
      );
}

String _analysisText(BuildContext context, String english, String tamil) =>
    FarmerLanguage.isTamil(context) ? tamil : english;

double? _finitePercent(double? value) {
  if (value == null || !value.isFinite) return null;
  return value.clamp(0.0, 100.0).toDouble();
}

bool _isFarmerHealthyState(String raw) {
  final value = raw.toUpperCase();
  return value.contains('HEALTHY') ||
      value.contains('EXCELLENT') ||
      value == 'GOOD' ||
      value == 'NORMAL' ||
      value == 'OPTIMAL';
}

String _farmerStatus(
  BuildContext context,
  String raw, {
  required bool healthy,
  required bool recovering,
  required bool possibleBiotic,
}) {
  if (recovering) {
    return _analysisText(
      context,
      'Plant is recovering',
      'செடி மீண்டு வருகிறது',
    );
  }
  if (possibleBiotic) {
    return _analysisText(
      context,
      'Plant needs a closer inspection',
      'செடியை நெருக்கமாக பரிசோதிக்க வேண்டும்',
    );
  }
  if (healthy) {
    return _analysisText(
      context,
      'Plant looks healthy',
      'செடி ஆரோக்கியமாக உள்ளது',
    );
  }
  final value = raw.toUpperCase();
  if (value.contains('CRITICAL') || value.contains('HIGH_STRESS')) {
    return _analysisText(
      context,
      'Plant needs urgent attention',
      'செடிக்கு உடனடி கவனம் தேவை',
    );
  }
  return _analysisText(
    context,
    'Plant needs attention',
    'செடிக்கு கவனம் தேவை',
  );
}

String _farmerProblem(
  BuildContext context,
  String? raw, {
  required bool healthy,
  required bool possibleBiotic,
}) {
  if (healthy) {
    return _analysisText(
      context,
      'No clear problem is detected now.',
      'இப்போது தெளிவான பிரச்சினை இல்லை.',
    );
  }
  if (possibleBiotic) {
    return _analysisText(
      context,
      'The plant response is not fully explained by soil or climate.',
      'மண் அல்லது வானிலை மட்டும் செடியின் பதிலை முழுமையாக விளக்கவில்லை.',
    );
  }
  final value = (raw ?? '').toUpperCase();
  if ((value.contains('HEAT') && value.contains('WATER')) ||
      value.contains('COMPOUND')) {
    return _analysisText(
      context,
      'Heat and dry soil are stressing the plant.',
      'வெப்பமும் உலர்ந்த மண்ணும் செடிக்கு அழுத்தம் தருகின்றன.',
    );
  }
  if (value.contains('OVERWATER') || value.contains('TOO_WET')) {
    return _analysisText(
      context,
      'The root zone is staying too wet.',
      'வேர் பகுதி அதிக நேரம் ஈரமாக உள்ளது.',
    );
  }
  if (value.contains('WATER_STRESS') ||
      value.contains('ROOT_ZONE_IS_DRY') ||
      value.contains('LOW_ROOT')) {
    return _analysisText(
      context,
      'The soil near the roots is too dry.',
      'வேர் அருகிலுள்ள மண் மிகவும் உலர்ந்துள்ளது.',
    );
  }
  if (value.contains('ATMOSPHERIC') || value.contains('DRYING')) {
    return _analysisText(
      context,
      'Dry air is pulling water from the plant quickly.',
      'உலர் காற்று செடியிலிருந்து நீரை வேகமாக இழுக்கிறது.',
    );
  }
  if (value.contains('HEAT')) {
    return _analysisText(
      context,
      'High temperature is stressing the plant.',
      'அதிக வெப்பம் செடிக்கு அழுத்தம் தருகிறது.',
    );
  }
  if (value.contains('SENSOR') &&
      (value.contains('FAULT') ||
          value.contains('MISSING') ||
          value.contains('UNAVAILABLE'))) {
    return _analysisText(
      context,
      'A sensor is not working now.',
      'ஒரு சென்சார் இப்போது வேலை செய்யவில்லை.',
    );
  }
  if (value.contains('NOISY') || value.contains('CONTACT')) {
    return _analysisText(
      context,
      'The plant sensor reading is not clear.',
      'செடி சென்சார் அளவீடு தெளிவாக இல்லை.',
    );
  }
  return FarmerLanguage.firmware(
    context,
    raw,
    fallback: FarmerLanguage.label(context, 'no_problem'),
  );
}

String _farmerAction(
  BuildContext context,
  EdgeIntelligence? edge, {
  required String problem,
  required bool healthy,
  required bool recovering,
  required bool possibleBiotic,
}) {
  if (healthy || recovering) {
    return _analysisText(
      context,
      'Keep monitoring as usual.',
      'வழக்கம்போல் தொடர்ந்து கண்காணிக்கவும்.',
    );
  }
  if (possibleBiotic) {
    return _analysisText(
      context,
      'Check leaves, stems and leaf undersides for pests or visible damage.',
      'இலை, தண்டு மற்றும் இலைகளின் அடிப்பகுதியில் பூச்சி அல்லது சேதம் உள்ளதா பாருங்கள்.',
    );
  }
  final recommendation = edge?.recommendation?.toUpperCase() ?? '';
  final value =
      '${edge?.rootCause.primary ?? ''} $problem $recommendation'.toUpperCase();
  if (recommendation.contains('WATER_ROOT') ||
      recommendation.contains('WATER SOON') ||
      recommendation.contains('WATER THE ROOT')) {
    return _analysisText(
      context,
      'Water the soil near the roots.',
      'வேர் அருகிலுள்ள மண்ணில் நீர் பாய்ச்சவும்.',
    );
  }
  if (recommendation.contains('CHECK_CONTACT') ||
      recommendation.contains('ELECTRODE')) {
    return _analysisText(
      context,
      'Check that the plant sensor touches the plant properly.',
      'செடி சென்சார் செடியை சரியாக தொடுகிறதா பாருங்கள்.',
    );
  }
  if (recommendation.contains('CHECK_SENSOR') ||
      recommendation.contains('CHECK WIRING')) {
    return _analysisText(
      context,
      'Check the sensor and its connection.',
      'சென்சார் மற்றும் அதன் இணைப்பை பாருங்கள்.',
    );
  }
  if (value.contains('TOO WET') || value.contains('OVERWATER')) {
    return _analysisText(
      context,
      'Pause watering and check that the root zone can drain.',
      'நீர் பாய்ச்சுவதை நிறுத்தி, வேர் பகுதியில் வடிகால் உள்ளதா பாருங்கள்.',
    );
  }
  if (value.contains('HEAT') &&
      (value.contains('DRY') || value.contains('WATER'))) {
    return _analysisText(
      context,
      'Check the soil near the roots. If it is dry, water slowly and protect the plant from strong midday heat.',
      'வேர் அருகே மண்ணை பாருங்கள். உலர்ந்தால் மெதுவாக நீர் பாய்ச்சி, முடிந்தால் மதிய வெப்பத்தை குறைக்கவும்.',
    );
  }
  if (value.contains('DRY')) {
    return _analysisText(
      context,
      'Check the soil near the roots. Water it slowly if it is dry.',
      'வேர் பகுதி மண்ணை பார்த்து, உலர்ந்தால் மெதுவாக நீர் பாய்ச்சவும்.',
    );
  }
  if (value.contains('WATER_STRESS') || value.contains('WATER STRESS')) {
    return _analysisText(
      context,
      'Water the soil near the roots.',
      'வேர் அருகிலுள்ள மண்ணில் நீர் பாய்ச்சவும்.',
    );
  }
  if (value.contains('HEAT')) {
    return _analysisText(
      context,
      'Check the soil near the roots. Keep the plant away from strong midday heat.',
      'வேர் பகுதி நீரை பார்த்து, முடிந்தால் அதிக மதிய வெப்பத்தை குறைக்கவும்.',
    );
  }
  return FarmerLanguage.firmware(
    context,
    edge?.recommendation,
    fallback: FarmerLanguage.label(context, 'keep_monitoring'),
  );
}

String _conditionTrend(BuildContext context, EdgeIntelligence? edge) {
  if (edge?.recovery.active == true ||
      edge?.plantState?.toUpperCase() == 'RECOVERING') {
    return FarmerLanguage.label(context, 'recovering');
  }
  final health = edge?.trends.where(
    (item) => item.channel.toLowerCase().contains('health'),
  );
  if (health != null && health.isNotEmpty && health.first.state != null) {
    final value = health.first.state!.toUpperCase();
    if (value.contains('RISING')) {
      return FarmerLanguage.label(context, 'improving');
    }
    if (value.contains('FALLING_FAST') || value.contains('FALLING_QUICK')) {
      return FarmerLanguage.label(context, 'getting_worse_quickly');
    }
    if (value.contains('FALLING')) {
      return FarmerLanguage.label(context, 'getting_worse');
    }
  }
  final bio = edge?.bioelectric.trend?.toUpperCase();
  if (bio != null) {
    if (bio.contains('RISING_FAST') || bio.contains('RISING_QUICK')) {
      return FarmerLanguage.label(context, 'getting_worse_quickly');
    }
    if (bio.contains('RISING')) {
      return FarmerLanguage.label(context, 'getting_worse');
    }
    if (bio.contains('FALLING')) {
      return FarmerLanguage.label(context, 'improving');
    }
  }
  return FarmerLanguage.label(context, 'stable');
}

Color _conditionColor(BuildContext context, String? raw) {
  final value = raw?.toUpperCase() ?? '';
  if (value.contains('CRITICAL') || value.contains('HIGH_STRESS')) {
    return Theme.of(context).colorScheme.error;
  }
  if (value.contains('STRESS') ||
      value.contains('ATTENTION') ||
      value.contains('WATCH')) {
    return Theme.of(context).colorScheme.tertiary;
  }
  return Theme.of(context).colorScheme.primary;
}

String _time(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
