import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/data_source_card.dart';
import '../widgets/home_soil_presentation.dart';
import '../widgets/live_motion.dart';
import '../widgets/simulation_command_deck.dart';
import '../widgets/biotic_stress_card.dart';
import '../widgets/calibre_upgrade_panels.dart';
import '../widgets/competition_intelligence_panels.dart';
import '../widgets/page_frame.dart';
import '../widgets/verdant_care_hero.dart';
import '../widgets/care_actions.dart';
import 'settings_screen.dart';
import 'care_journal_screen.dart';
import 'setup_guide_screen.dart';
import '../widgets/time_phase_card.dart';
import 'judge_view_screen.dart';
import 'leaf_screening_screen.dart';
import 'plant_intelligence_settings_screen.dart';
import 'weather_center_screen.dart';

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
    final canShowCurrent =
        !live || sensors.connectionStatus == SensorConnectionStatus.ready;
    final homeSystemNotice = live ? _HomeSystemNotice.fromEdge(edge) : null;

    Future<void> useSimulation() async {
      await scope.settings.setDataSource('simulation');
      scope.alerts.clear();
      scope.sensorManager.configure(
        source: SensorDataSource.simulation,
        endpoint: scope.settings.value.esp32Endpoint,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JudgeViewScreen()),
          ),
          child: Row(
            children: [
              LiveMotion(
                style: LiveMotionStyle.signal,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/branding/phytosense_icon.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Flexible(child: Text('PhytoSense AI')),
            ],
          ),
        ),
        actions: [
          IconButton(
              tooltip: _competitionText(context, 'Settings', 'அமைப்புகள்'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              icon: const Icon(Icons.settings_outlined)),
          if (live)
            IconButton(
              tooltip: 'Plant Intelligence',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlantIntelligenceSettingsScreen(),
                ),
              ),
              icon: const LiveMotionIcon(icon: Icons.tune_rounded),
            ),
          Badge(
            isLabelVisible: scope.alerts.unreadCount > 0,
            label: Text('${scope.alerts.unreadCount}'),
            child: IconButton(
              tooltip: context.tr('alerts_title'),
              onPressed: onOpenAlerts,
              icon: const LiveMotionIcon(
                icon: Icons.notifications_none_rounded,
                style: LiveMotionStyle.sway,
              ),
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
            if (live) ...[
              const SizedBox(height: 10),
              _ConnectionStrip(
                status: sensors.connectionStatus,
                timestamp: reading?.timestamp,
                onRetry: sensors.retry,
                live: true,
              ),
            ],
            if (live &&
                sensors.connectionStatus != SensorConnectionStatus.ready) ...[
              const SizedBox(height: 10),
              _HardwareUnavailableBanner(
                hasValidatedReading: reading != null,
                onRetry: sensors.retry,
                onUseSimulation: useSimulation,
              ),
            ],
            const SizedBox(height: 14),
            if (!canShowCurrent)
              const SizedBox.shrink()
            else if (edge?.firmwareCompatible == false)
              const _FirmwareCompatibilityCard()
            else if (reading == null)
              _WaitingCard(
                onRetry: sensors.retry,
                onUseSimulation: useSimulation,
                live: live,
              )
            else ...[
              _ConditionCard(
                reading: reading,
                edge: edge,
                telemetry: telemetry,
                live: live,
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(
                    avatar: const Icon(Icons.edit_note_rounded),
                    label: Text(_competitionText(
                        context, 'Care diary', 'பராமரிப்பு பதிவு')),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CareJournalScreen()))),
                ActionChip(
                    avatar: const Icon(Icons.explore_outlined),
                    label: Text(_competitionText(
                        context, 'Getting started', 'தொடங்குவோம்')),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SetupGuideScreen()))),
              ]),
              const SizedBox(height: 16),
              const _WeatherHomeCard(),
              const SizedBox(height: 12),
              TimePhaseCard(
                live: live,
                espDayPhase: telemetry?.dayPhase,
              ),
              if (live && _FarmerEdgeSignals.visible(edge)) ...[
                const SizedBox(height: 10),
                _FarmerEdgeSignals(edge: edge!),
              ],
              if (live && edge?.recovery.visibleOnHome == true) ...[
                const SizedBox(height: 12),
                _RecoveryStatusCard(recovery: edge!.recovery),
              ],
              if (homeSystemNotice != null) ...[
                const SizedBox(height: 12),
                _SystemQualityCard(notice: homeSystemNotice),
              ],
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
              if (_changes(context, edge).isNotEmpty) ...[
                const SizedBox(height: 12),
                _WhatChangedCard(edge: edge),
              ],
              if (!live &&
                  (edge?.degradedAnalysis == true ||
                      edge?.sensorFaults.isNotEmpty == true)) ...[
                const SizedBox(height: 12),
                _CoverageCard(edge: edge!),
              ],
              const SizedBox(height: 12),
              _AdvancedHomeIntelligence(
                current: reading,
                history: sensors.historyFor(reading.nodeId),
                edge: edge,
                telemetry: telemetry,
                live: live,
                connectionStatus: sensors.connectionStatus,
              ),
            ],
            const SizedBox(height: 16),
            const DataSourceCard(),
            if (!live) ...[
              const SizedBox(height: 12),
              const SimulationCommandDeck()
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
            Icon(Icons.system_update_alt_rounded,
                color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FarmerLanguage.label(
                        context, 'firmware_compatibility_title'),
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    FarmerLanguage.label(
                        context, 'firmware_compatibility_body'),
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
  final bool live;

  const _ConditionCard({
    required this.reading,
    required this.edge,
    required this.telemetry,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final rawState = edge?.plantState ?? reading.healthStatus;
    final recovering = rawState.toUpperCase() == 'RECOVERING';
    final possibleBiotic = edge?.bioticStress.suspected == true;
    final main = possibleBiotic
        ? FarmerLanguage.label(context, 'possible_biotic_title')
        : edge?.rootCause.primary ??
            edge?.farmerSummary ??
            edge?.bioelectric.farmerResult;
    final soilPresentation = live
        ? HomeSoilPresentation.fromFirmware(
            telemetry?.sensor('soilMoisture')?.result,
          )
        : null;
    final useSoilPresentation = soilPresentation != null &&
        !recovering &&
        !possibleBiotic &&
        HomeSoilPresentation.isSoilLedFinding(edge?.rootCause.primary);
    final healthy = !recovering && !possibleBiotic && _isHealthyState(rawState);
    final conditionStatus = recovering
        ? _competitionText(
            context,
            'Plant is recovering',
            'செடி மீண்டு வருகிறது',
          )
        : healthy
            ? _competitionText(
                context,
                'Plant looks healthy',
                'செடி ஆரோக்கியமாக உள்ளது',
              )
            : _competitionText(
                context,
                'Plant needs attention',
                'செடிக்கு கவனம் தேவை',
              );
    final title = useSoilPresentation
        ? soilPresentation.title(tamil: FarmerLanguage.isTamil(context))
        : _simpleConditionTitle(
            context,
            rawState: rawState,
            main: main,
            recovering: recovering,
            possibleBiotic: possibleBiotic,
          );
    final rawAction = recovering
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
    final action = _simpleFarmerAction(
      context,
      rawAction,
      title: title,
      healthy: healthy,
    );
    final accent = recovering
        ? Theme.of(context).colorScheme.primary
        : _stateColor(context, rawState);
    final crop =
        telemetry?.cropProfile ?? edge?.cropProfile.profile ?? 'Universal';
    final stage = telemetry?.growthStage ?? edge?.cropProfile.growthStage;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      VerdantCareHero(
        condition: conditionStatus,
        problem: title,
        action: action,
        crop: stage == null
            ? FarmerLanguage.firmware(context, crop)
            : '${FarmerLanguage.firmware(context, crop)} · ${FarmerLanguage.firmware(context, stage)}',
        source: _competitionText(context, live ? 'Live sensor' : 'Simulation',
            live ? 'நேரடி சென்சார்' : 'சிமுலேஷன்'),
        score: live
            ? edge?.healthScore ?? reading.esp32HealthScore
            : reading.healthScore,
        tamil: FarmerLanguage.isTamil(context),
        accent: accent,
        controls: CareActions(
            condition: conditionStatus,
            problem: title,
            action: action,
            plant: crop,
            source: live ? 'hardware' : 'simulation',
            timestamp: reading.timestamp),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth < 350 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2
            ? 1
            : 3;
        final width = (box.maxWidth - 10 * (columns - 1)) / columns;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final item in [
            (
              label: _competitionText(context, 'Soil moisture', 'மண் ஈரப்பதம்'),
              value: reading.soilMoistureAvailable
                  ? '${reading.soilMoisture.round()}%'
                  : '—',
              icon: Icons.water_drop_outlined,
              color: const Color(0xFF397F96)
            ),
            (
              label: _competitionText(context, 'Temperature', 'வெப்பநிலை'),
              value: reading.temperatureAvailable
                  ? '${reading.temperature.round()}°C'
                  : '—',
              icon: Icons.thermostat_rounded,
              color: const Color(0xFFAE703B)
            ),
            (
              label: _competitionText(context, 'Humidity', 'காற்று ஈரப்பதம்'),
              value: reading.humidityAvailable
                  ? '${reading.humidity.round()}%'
                  : '—',
              icon: Icons.air_rounded,
              color: const Color(0xFF727AA3)
            ),
          ])
            SizedBox(
                width: width,
                child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: item.color.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.icon, color: item.color),
                          const SizedBox(height: 10),
                          Text(item.value,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(item.label,
                              style: Theme.of(context).textTheme.bodySmall),
                        ]))),
        ]);
      }),
      const SizedBox(height: 10),
      TextButton.icon(
          onPressed: () => _showWhy(context, edge, live: live),
          icon: const Icon(Icons.info_outline),
          label: Text(_competitionText(
              context, 'Why this result?', 'இந்த முடிவு ஏன்?'))),
    ]);
  }

  void _showWhy(
    BuildContext context,
    EdgeIntelligence? edge, {
    required bool live,
  }) {
    final evidence = _evidence(context, edge);
    final confidence =
        FarmerLanguage.confidence(context, edge?.overallConfidence);
    final bio = edge?.bioelectric;
    final conclusion = FarmerLanguage.firmware(
      context,
      edge?.farmerSummary ?? edge?.rootCause.primary,
      fallback: FarmerLanguage.label(context, 'why_unavailable'),
    );
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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    Icons.verified_outlined,
                    '${FarmerLanguage.label(context, 'analysis_confidence')}: $confidence',
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _competitionText(
                  context,
                  'What PhytoSense checked',
                  'PhytoSense சரிபார்த்தது',
                ),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              if (evidence.isEmpty)
                Text(FarmerLanguage.label(context, 'why_unavailable'))
              else
                for (final item in evidence.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 19),
                        const SizedBox(width: 9),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              if (bio?.hasData == true) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        bio!.excludedByFirmware
                            ? Icons.shield_outlined
                            : Icons.electric_bolt_rounded,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          bio.excludedByFirmware
                              ? _competitionText(
                                  context,
                                  'The plant signal was not reliable, so it was safely left out of this result.',
                                  'Bioelectric signal தரம் போதுமானதாக இல்லாததால் பகுப்பாய்வில் சேர்க்கப்படவில்லை.',
                                )
                              : live
                                  ? _competitionText(
                                      context,
                                      'The live plant signal supports this ESP32 result.',
                                      'நேரடி செடி சிக்னல் இந்த ESP32 முடிவை ஆதரிக்கிறது.',
                                    )
                                  : _competitionText(
                                      context,
                                      'The practice plant signal supports this demo result.',
                                      'பயிற்சி செடி சிக்னல் இந்த demo முடிவை ஆதரிக்கிறது.',
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                _competitionText(context, 'Main finding', 'முக்கிய முடிவு'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                conclusion,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Retained only as a reusable engineering visualization; Home intentionally
// presents the ESP32 conclusion in words instead of a calculated-looking dial.
// ignore: unused_element
class _PlantHealthMeter extends StatelessWidget {
  final double score;
  final String status;

  const _PlantHealthMeter({required this.score, required this.status});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Plant health ${score.round()} out of 100. $status',
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: score),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: double.infinity,
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PlantHealthMeterPainter(score: value),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Column(
                      children: [
                        Text(
                          '${value.round()}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          status,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: _meterColor(value),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _PlantHealthMeterPainter extends CustomPainter {
  final double score;

  const _PlantHealthMeterPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    // Keep the whole semicircle above the score band. This prevents the hub
    // and needle from ever touching the number on narrow Android screens.
    final center = Offset(size.width / 2, size.height * 0.46);
    final radius = math.min(size.width * 0.39, size.height * 0.40);
    const start = math.pi;
    const totalSweep = math.pi;
    const gap = 0.035;
    const colors = [
      Color(0xFFE34B3F),
      Color(0xFFF18C2E),
      Color(0xFFF2C94C),
      Color(0xFF21A85B),
    ];
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 17;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var index = 0; index < colors.length; index++) {
      arcPaint.color = colors[index];
      canvas.drawArc(
        rect,
        start + index * totalSweep / colors.length + gap,
        totalSweep / colors.length - gap * 2,
        false,
        arcPaint,
      );
    }

    final angle = start + totalSweep * (score.clamp(0, 100) / 100);
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.76);
    final needlePaint = Paint()
      ..color = const Color(0xFF17343A)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, needlePaint);
    canvas.drawCircle(center, 9, needlePaint);
    canvas.drawCircle(
      center,
      3.5,
      Paint()..color = const Color(0xFFF4FAF7),
    );
  }

  @override
  bool shouldRepaint(covariant _PlantHealthMeterPainter oldDelegate) =>
      oldDelegate.score != score;
}

class _WeatherHomeCard extends StatelessWidget {
  const _WeatherHomeCard();

  @override
  Widget build(BuildContext context) {
    final weather = AppScope.of(context).weather;
    return AnimatedBuilder(
      animation: weather,
      builder: (context, _) {
        final snapshot = weather.snapshot;
        final title = snapshot == null
            ? _competitionText(context, 'Weather & location', 'வானிலை & இடம்')
            : snapshot.location;
        final detail = snapshot == null
            ? _competitionText(
                context,
                'Tap to load local farm weather.',
                'உள்ளூர் பண்ணை வானிலையைப் பார்க்க தொடவும்.',
              )
            : '${snapshot.temperature.round()}°C  •  ${snapshot.humidity.round()}% humidity';
        final freshness = weather.usingCachedData
            ? _competitionText(
                context, 'Saved forecast', 'சேமித்த முன்னறிவிப்பு')
            : _competitionText(
                context, 'Weather updated', 'வானிலை புதுப்பிக்கப்பட்டது');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeatherCenterScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4D9ED1), Color(0xFF88D5E8)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: LiveMotionIcon(
                      icon: snapshot == null
                          ? Icons.location_searching_rounded
                          : _homeWeatherIcon(snapshot.weatherCode),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _competitionText(
                            context,
                            'Weather & location',
                            'வானிலை & இடம்',
                          ),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (snapshot != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            freshness,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlantResponseCard extends StatelessWidget {
  final BioelectricIntelligence bio;
  const _PlantResponseCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    final displayOnly = bio.presentationOnly;
    final excluded = !displayOnly && bio.excludedByFirmware;
    final learning = !displayOnly && !excluded && bio.learningBaseline;
    final state = displayOnly
        ? bio.displayLabel
        : excluded
            ? FarmerLanguage.label(context, 'signal_unavailable')
            : learning
                ? FarmerLanguage.label(context, 'learning_baseline')
                : _plantResponse(context, bio);
    final result = displayOnly
        ? 'Signal readings are updating normally.'
        : FarmerLanguage.firmware(
            context,
            excluded
                ? bio.interpretation
                : bio.farmerResult ?? bio.interpretation,
            fallback: excluded
                ? FarmerLanguage.label(context, 'bio_signal_check_electrodes')
                : learning
                    ? FarmerLanguage.label(context, 'bio_learning_body')
                    : FarmerLanguage.label(
                        context,
                        'plant_response_no_result',
                      ),
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
              child: LiveMotionIcon(
                icon: Icons.electric_bolt_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayOnly
                        ? bio.displayLabel
                        : FarmerLanguage.label(context, 'plant_response'),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  if (displayOnly) ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        bio.voltageMv == null
                            ? '— mV'
                            : '${bio.voltageMv!.round()} mV',
                        key: ValueKey<int?>(
                          bio.voltageMv?.round(),
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NORMAL • STABLE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.35,
                          ),
                    ),
                  ] else
                    Text(
                      state,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    result,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children: [
                      if (bio.confidence != null)
                        Text(
                            '${FarmerLanguage.label(context, 'confidence')}: ${FarmerLanguage.confidence(context, bio.confidence)}'),
                      if (bio.trend != null)
                        Text(
                            '${FarmerLanguage.label(context, 'trend')}: ${FarmerLanguage.firmware(context, bio.trend)}'),
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
                    if (bio.baselineTarget != null &&
                        bio.baselineTarget! > 0) ...[
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
                  icon: const LiveMotionIcon(
                    icon: Icons.camera_alt_outlined,
                  ),
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
                      const LiveMotionIcon(
                        icon: Icons.arrow_right_rounded,
                        size: 20,
                        style: LiveMotionStyle.drift,
                      ),
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
    final issue = edge.sensorFaults.isNotEmpty ? edge.sensorFaults.first : null;
    final text = issue?.explanation ?? edge.degradedReason;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LiveMotionIcon(
              icon: Icons.sensors_off_outlined,
              style: LiveMotionStyle.signal,
            ),
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

class _HomeSystemNotice {
  final String title;
  final String? issue;
  final String? action;
  final bool severe;

  const _HomeSystemNotice({
    required this.title,
    required this.issue,
    required this.action,
    required this.severe,
  });

  static _HomeSystemNotice? fromEdge(EdgeIntelligence? edge) {
    if (edge == null) return null;
    final integrity = edge.sensorIntegrity;
    final plausibility = edge.plausibility;
    final runtime = edge.runtimeHealth;
    final bio = edge.bioelectric;
    final contact = bio.normalizedContactState;

    // Keep plant-contact integrity in the existing single Home warning slot.
    // This prevents a clean electrical trace from being presented as valid
    // plant bioelectric data when the firmware says plant contact is invalid.
    if (!bio.presentationOnly && contact != null && contact != 'PLAUSIBLE') {
      return switch (contact) {
        'OPEN' => const _HomeSystemNotice(
            title: 'Plant sensors are loose',
            issue: 'The plant reading is not clear.',
            action: 'Make sure both sensors touch the plant firmly.',
            severe: false,
          ),
        'VERIFY' => const _HomeSystemNotice(
            title: 'Check the plant sensors',
            issue: 'The plant reading is not ready yet.',
            action: 'Make sure both sensors touch the plant firmly.',
            severe: false,
          ),
        'STATIC' || 'SHORT_SUSPECTED' => const _HomeSystemNotice(
            title: 'Static/test input',
            issue: 'Not used for plant analysis',
            action: null,
            severe: false,
          ),
        'UNSTABLE' => const _HomeSystemNotice(
            title: 'Plant sensors are moving',
            issue: 'The plant reading keeps changing.',
            action: 'Keep both sensors still and touching the plant.',
            severe: false,
          ),
        'SATURATED' => const _HomeSystemNotice(
            title: 'Plant sensor needs attention',
            issue: 'The plant reading is too strong to use.',
            action: 'Check the plant sensor and its wire.',
            severe: true,
          ),
        _ => const _HomeSystemNotice(
            title: 'Check the plant sensors',
            issue: 'The plant reading is not clear enough to use.',
            action: 'Make sure both sensors touch the plant firmly.',
            severe: false,
          ),
      };
    }
    if (!bio.presentationOnly &&
        bio.contactPlausibleForPlantUse == false &&
        contact == null) {
      return const _HomeSystemNotice(
        title: 'Check the plant sensors',
        issue: 'The plant reading is not clear enough to use.',
        action: 'Make sure both sensors touch the plant firmly.',
        severe: false,
      );
    }

    if (integrity.degraded) {
      return _HomeSystemNotice(
        title: 'Sensor check needed',
        issue: integrity.primaryIssue,
        action: integrity.primaryAction ?? plausibility.recommendation,
        severe: true,
      );
    }
    if (runtime.degraded) {
      return _HomeSystemNotice(
        title: 'Sensor node needs attention',
        issue: runtime.issue,
        action: null,
        severe: true,
      );
    }
    if (integrity.verify || plausibility.verify) {
      return _HomeSystemNotice(
        title: 'Please verify one sensor',
        issue: integrity.primaryIssue ?? plausibility.primaryIssue,
        action: integrity.primaryAction ?? plausibility.recommendation,
        severe: false,
      );
    }

    // Older firmware has no sensorIntegrity object. Keep its existing single
    // compact fallback instead of creating extra cards.
    if (!integrity.hasData &&
        (edge.degradedAnalysis || edge.sensorFaults.isNotEmpty)) {
      final fault = edge.sensorFaults.isEmpty ? null : edge.sensorFaults.first;
      return _HomeSystemNotice(
        title: 'Sensor check needed',
        issue: fault?.explanation ?? edge.degradedReason,
        action: null,
        severe: edge.degradedAnalysis,
      );
    }
    return null;
  }
}

class _SystemQualityCard extends StatelessWidget {
  final _HomeSystemNotice notice;

  const _SystemQualityCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = notice.severe ? scheme.error : scheme.tertiary;
    final issue = FarmerLanguage.firmware(
      context,
      notice.issue,
      fallback: notice.severe
          ? 'The sensor node needs a quick check.'
          : 'One reading should be verified before relying on it.',
    );
    final action = notice.action == null
        ? null
        : FarmerLanguage.firmware(context, notice.action);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiveMotionIcon(
              icon: notice.severe
                  ? Icons.sensors_off_outlined
                  : Icons.fact_check_outlined,
              color: accent,
              style: LiveMotionStyle.signal,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(issue),
                  if (action != null && action.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      action,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _FarmerEdgeSignals extends StatelessWidget {
  final EdgeIntelligence edge;

  const _FarmerEdgeSignals({required this.edge});

  static bool visible(EdgeIntelligence? edge) {
    if (edge == null) return false;
    return edge.plantModel.learning || _predictionVisible(edge.prediction);
  }

  static bool _predictionVisible(PredictionInfo prediction) {
    final confidence = prediction.confidence ?? 0;
    final eta =
        prediction.minutesToWarning ?? prediction.minutesToWaterStressWarning;
    final hasMessage =
        (prediction.message ?? prediction.explanation)?.trim().isNotEmpty ==
            true;
    final hasTargetEta =
        prediction.target?.trim().isNotEmpty == true && eta != null;
    return prediction.available == true &&
        confidence >= 65 &&
        (hasMessage || hasTargetEta);
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (edge.plantModel.learning) {
      items.add(
        _FarmerEdgeSignalRow(
          icon: Icons.psychology_alt_outlined,
          title: _competitionText(
            context,
            'Learning this plant',
            'இந்த தாவரத்தை கற்றுக்கொள்கிறது',
          ),
          detail: _competitionText(
            context,
            'Building its normal baseline from live readings.',
            'நேரடி அளவீடுகளில் இருந்து இயல்பான அடிப்படை கற்றுக்கொள்ளப்படுகிறது.',
          ),
        ),
      );
    }

    final prediction = edge.prediction;
    if (_predictionVisible(prediction)) {
      final eta =
          prediction.minutesToWarning ?? prediction.minutesToWaterStressWarning;
      final firmwareText =
          (prediction.message ?? prediction.explanation)?.trim();
      final fallback = eta == null
          ? (prediction.target ?? 'A stress change may be developing.')
          : '${prediction.target ?? 'Stress warning'} in about ${eta.round()} min';
      items.add(
        _FarmerEdgeSignalRow(
          icon: Icons.schedule_outlined,
          title: _competitionText(
            context,
            'Early warning',
            'முன்கூட்டிய எச்சரிக்கை',
          ),
          detail: FarmerLanguage.firmware(
            context,
            firmwareText,
            fallback: fallback,
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          items[index],
          if (index != items.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _FarmerEdgeSignalRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _FarmerEdgeSignalRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title  ',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(text: detail),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryStatusCard extends StatelessWidget {
  final RecoveryInfo recovery;

  const _RecoveryStatusCard({required this.recovery});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verified = recovery.recoveryVerified;
    final recovering = recovery.recovering;
    final title = verified
        ? 'Recovery verified'
        : recovering
            ? 'Plant recovering'
            : 'Conditions improving';
    final fallback = verified
        ? 'The ESP32 has verified recovery across the available evidence.'
        : recovering
            ? 'Stress evidence is decreasing while the plant response is monitored.'
            : 'Conditions are improving while the ESP32 verifies the plant response.';
    final summary = FarmerLanguage.firmware(
      context,
      recovery.farmerResult,
      fallback: fallback,
    );
    final progress = verified
        ? 1.0
        : recovery.progressPct == null
            ? null
            : (recovery.progressPct! / 100).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiveMotionIcon(
              icon: verified ? Icons.verified_rounded : Icons.eco_outlined,
              color: scheme.primary,
              style: LiveMotionStyle.sway,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(summary),
                  if (recovering || verified) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
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

class _AdvancedHomeIntelligence extends StatelessWidget {
  final SensorReading current;
  final List<SensorReading> history;
  final EdgeIntelligence? edge;
  final HardwareTelemetry? telemetry;
  final bool live;
  final SensorConnectionStatus connectionStatus;

  const _AdvancedHomeIntelligence({
    required this.current,
    required this.history,
    required this.edge,
    required this.telemetry,
    required this.live,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const PageStorageKey<String>('home-full-plant-intelligence'),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: LiveMotionIcon(
              icon: Icons.auto_awesome_rounded,
              color: colors.onPrimaryContainer,
              style: LiveMotionStyle.spark,
            ),
          ),
          title: Text(
            _competitionText(
              context,
              'Full plant intelligence',
              'முழு தாவர நுண்ணறிவு',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            _competitionText(
              context,
              'Evidence, trends, predictions and engineering detail',
              'ஆதாரம், போக்குகள், கணிப்புகள் மற்றும் தொழில்நுட்ப விவரம்',
            ),
          ),
          initiallyExpanded: false,
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            CompetitionIntelligencePanels(
              current: current,
              history: history,
              edge: edge,
              telemetry: telemetry,
              live: live,
              connectionStatus: connectionStatus,
            ),
            const SizedBox(height: 12),
            CalibreUpgradePanels(
              current: current,
              history: history,
              edge: edge,
              telemetry: telemetry,
              live: live,
              connectionStatus: connectionStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStrip extends StatefulWidget {
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
  State<_ConnectionStrip> createState() => _ConnectionStripState();
}

class _ConnectionStripState extends State<_ConnectionStrip> {
  Timer? _clock;
  Timer? _stageTimer;
  int _connectionStage = 0;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (widget.live && widget.status == SensorConnectionStatus.ready) {
      _connectionStage = 3;
    }
  }

  @override
  void didUpdateWidget(covariant _ConnectionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.live) {
      _stageTimer?.cancel();
      _connectionStage = 0;
      return;
    }
    final becameReady = oldWidget.status != SensorConnectionStatus.ready &&
        widget.status == SensorConnectionStatus.ready;
    if (becameReady) {
      _runConnectionSequence();
    } else if (widget.status != SensorConnectionStatus.ready) {
      _stageTimer?.cancel();
      _connectionStage = 0;
    }
  }

  void _runConnectionSequence() {
    _stageTimer?.cancel();
    _connectionStage = 1;
    var ticks = 0;
    _stageTimer = Timer.periodic(const Duration(milliseconds: 360), (timer) {
      ticks++;
      if (!mounted || widget.status != SensorConnectionStatus.ready) {
        timer.cancel();
        return;
      }
      setState(() => _connectionStage = (1 + ticks).clamp(1, 3).toInt());
      if (_connectionStage >= 3) timer.cancel();
    });
  }

  Duration? get _age {
    final timestamp = widget.timestamp;
    if (timestamp == null) return null;
    final difference = DateTime.now().difference(timestamp);
    return difference.isNegative ? Duration.zero : difference;
  }

  bool get _stale {
    final age = _age;
    return widget.live &&
        widget.status == SensorConnectionStatus.ready &&
        age != null &&
        age > const Duration(seconds: 6);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _stageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ready = widget.status == SensorConnectionStatus.ready;
    final stale = _stale;
    final disconnected = widget.live && !ready;
    final accent = disconnected || stale ? colors.error : colors.primary;

    final sourceLabel = !widget.live
        ? _competitionText(context, 'SIMULATION', 'SIMULATION')
        : disconnected
            ? _competitionText(context, 'DISCONNECTED', 'இணைப்பு இல்லை')
            : stale
                ? _competitionText(context, 'STALE', 'தாமதம்')
                : _competitionText(context, 'LIVE', 'LIVE');

    String title;
    if (!widget.live) {
      title = FarmerLanguage.label(context, 'simulation_active');
    } else if (disconnected) {
      title = _competitionText(context, 'Searching for PhytoSense node…',
          'PhytoSense node தேடப்படுகிறது…');
    } else if (stale) {
      title = _competitionText(
          context, 'Latest packet is delayed', 'புதிய packet தாமதமாகிறது');
    } else {
      title = switch (_connectionStage) {
        1 => _competitionText(context, 'Node detected', 'Node கண்டறியப்பட்டது'),
        2 => _competitionText(
            context, 'Sensors verified', 'சென்சார்கள் சரிபார்க்கப்பட்டன'),
        _ => _competitionText(
            context, 'Plant intelligence online', 'செடி நுண்ணறிவு இயங்குகிறது'),
      };
    }

    final age = _age;
    final subtitle = age == null
        ? null
        : '${_competitionText(context, 'Updated', 'புதுப்பிக்கப்பட்டது')} ${_relativeAge(age)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        dense: true,
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Icon(
            !widget.live
                ? Icons.science_outlined
                : disconnected
                    ? Icons.portable_wifi_off_rounded
                    : stale
                        ? Icons.schedule_rounded
                        : Icons.wifi_tethering_rounded,
            key: ValueKey('$sourceLabel-$stale'),
            color: accent,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                sourceLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.35,
                ),
              ),
            ),
          ],
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: IconButton(
          tooltip: context.tr('reconnect'),
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    );
  }
}

class _HardwareUnavailableBanner extends StatelessWidget {
  final bool hasValidatedReading;
  final VoidCallback onRetry;
  final Future<void> Function() onUseSimulation;

  const _HardwareUnavailableBanner({
    required this.hasValidatedReading,
    required this.onRetry,
    required this.onUseSimulation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.error.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sensors_off_rounded, color: colors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FarmerLanguage.label(context, 'disconnected'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasValidatedReading
                          ? _competitionText(
                              context,
                              'Showing the last validated reading while PhytoSense reconnects.',
                              'PhytoSense மீண்டும் இணையும் வரை கடைசியாக சரிபார்க்கப்பட்ட reading காட்டப்படுகிறது.')
                          : FarmerLanguage.label(context, 'waiting_esp32'),
                      style: const TextStyle(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('reconnect')),
              ),
              OutlinedButton.icon(
                onPressed: () => onUseSimulation(),
                icon: const Icon(Icons.science_outlined),
                label: Text(context.tr('switch_to_demo')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final VoidCallback onRetry;
  final Future<void> Function() onUseSimulation;
  final bool live;

  const _WaitingCard({
    required this.onRetry,
    required this.onUseSimulation,
    required this.live,
  });

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
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 9,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.tr('reconnect')),
                  ),
                  if (live)
                    FilledButton.tonalIcon(
                      onPressed: () => onUseSimulation(),
                      icon: const Icon(Icons.science_outlined),
                      label: Text(context.tr('switch_to_demo')),
                    ),
                ],
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
            Flexible(
                child: Text(text,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w800))),
          ],
        ),
      );
}

List<String> _changes(BuildContext context, EdgeIntelligence? edge) {
  if (edge == null) return const [];
  // Recovery already has one dedicated farmer card. Do not repeat the same
  // firmware result in the generic change list.
  if (edge.recovery.visibleOnHome ||
      edge.plantState?.toUpperCase() == 'RECOVERING') return const [];
  return edge.trends
      .where((item) {
        final state = item.state?.toUpperCase() ?? '';
        return state.isNotEmpty && state != 'STABLE' && state != 'NORMAL';
      })
      .map((item) =>
          '${_friendlyChannel(context, item.channel)}: ${FarmerLanguage.firmware(context, item.state)}')
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

  add(edge.rootCause.primaryCandidate?.evidenceFor);
  add(edge.rootCause.secondaryCandidate?.evidenceFor);
  if (edge.bioelectric.corroborated == true &&
      !edge.bioelectric.excludedByFirmware) {
    result.add(
      _competitionText(
        context,
        'The plant signal agrees with the soil and climate readings.',
        'செடி சிக்னல் மண் மற்றும் வானிலை மதிப்புகளுடன் ஒத்துள்ளது.',
      ),
    );
  }
  if (result.isEmpty) {
    add(edge.rootCause.primary);
    add(edge.decisionExplanation);
  }
  return result;
}

bool _isHealthyState(String raw) {
  final value = raw.toUpperCase();
  return value.contains('HEALTHY') ||
      value.contains('EXCELLENT') ||
      value == 'GOOD' ||
      value == 'NORMAL' ||
      value == 'OPTIMAL';
}

String _simpleConditionTitle(
  BuildContext context, {
  required String rawState,
  required String? main,
  required bool recovering,
  required bool possibleBiotic,
}) {
  if (recovering) {
    return _competitionText(
      context,
      'Plant is recovering',
      'செடி மீண்டு வருகிறது',
    );
  }
  if (possibleBiotic) {
    return _competitionText(
      context,
      'Check for pests or leaf damage',
      'பூச்சி அல்லது இலை சேதம் உள்ளதா பாருங்கள்',
    );
  }
  if (_isHealthyState(rawState)) {
    return _competitionText(
      context,
      'Plant looks healthy',
      'செடி ஆரோக்கியமாக உள்ளது',
    );
  }
  final value = (main ?? rawState).toUpperCase();
  if ((value.contains('HEAT') && value.contains('WATER')) ||
      value.contains('COMPOUND')) {
    return _competitionText(
      context,
      'Heat and dry soil need urgent attention',
      'வெப்பம் மற்றும் உலர் மண்ணை உடனே கவனிக்கவும்',
    );
  }
  if (value.contains('ATMOSPHERIC') || value.contains('DRYING_DEMAND')) {
    return _competitionText(
      context,
      'Dry air is stressing the plant',
      'உலர் காற்று செடிக்கு அழுத்தம் தருகிறது',
    );
  }
  if (value.contains('WATER_STRESS') || value.contains('ROOT_ZONE_IS_DRY')) {
    return _competitionText(
      context,
      'Root-zone soil is too dry',
      'வேர் பகுதி மண் மிகவும் உலர்ந்துள்ளது',
    );
  }
  if (value.contains('OVERWATER') || value.contains('TOO_WET')) {
    return _competitionText(
      context,
      'Root-zone soil is too wet',
      'வேர் பகுதி மண் அதிக ஈரமாக உள்ளது',
    );
  }
  if (value.contains('HEAT')) {
    return _competitionText(
      context,
      'The plant is under heat stress',
      'செடி வெப்ப அழுத்தத்தில் உள்ளது',
    );
  }
  if (value.contains('LOW_CONFIDENCE') || value.contains('INSUFFICIENT')) {
    return _competitionText(
      context,
      'More sensor data is needed',
      'மேலும் சென்சார் தகவல் தேவை',
    );
  }
  return FarmerLanguage.firmware(context, main ?? rawState);
}

String _simpleFarmerAction(
  BuildContext context,
  String raw, {
  required String title,
  required bool healthy,
}) {
  if (healthy) {
    return _competitionText(
      context,
      'Keep monitoring as usual.',
      'வழக்கம்போல் தொடர்ந்து கண்காணிக்கவும்.',
    );
  }
  final value = '$title $raw'.toUpperCase();
  if (value.contains('TOO WET') || value.contains('OVERWATER')) {
    return _competitionText(
      context,
      'Pause watering and check that the root zone can drain.',
      'நீர் பாய்ச்சுவதை நிறுத்தி, வேர் பகுதியில் வடிகால் உள்ளதா பாருங்கள்.',
    );
  }
  if ((value.contains('HEAT') &&
          (value.contains('DRY') || value.contains('WATER'))) ||
      value.contains('URGENT')) {
    return _competitionText(
      context,
      'Check the soil near the roots. If it is dry, water slowly and protect the plant from strong midday heat.',
      'வேர் அருகே மண்ணை பாருங்கள். உலர்ந்தால் மெதுவாக நீர் பாய்ச்சி, முடிந்தால் மதிய வெப்பத்தை குறைக்கவும்.',
    );
  }
  if (value.contains('DRYING') || value.contains('ROOT-ZONE MOISTURE')) {
    return _competitionText(
      context,
      'Check the soil near the roots. Water only if it is dry, and give shade during the hottest hours.',
      'வேர் பகுதி மண்ணை பாருங்கள். மண் உலர்ந்தால் மட்டும் நீர் ஊற்றி, அதிக வெப்ப நேரத்தில் நிழல் கொடுங்கள்.',
    );
  }
  return FarmerLanguage.firmware(
    context,
    raw,
    fallback: FarmerLanguage.label(context, 'keep_monitoring'),
  );
}

// ignore: unused_element
String _simpleMeterStatus(BuildContext context, double score, String rawState) {
  if (rawState.toUpperCase().contains('RECOVER')) {
    return FarmerLanguage.label(context, 'recovering');
  }
  if (score >= 80) {
    return _competitionText(context, 'Healthy', 'ஆரோக்கியம்');
  }
  if (score >= 65) {
    return _competitionText(context, 'Watch', 'கவனிக்கவும்');
  }
  if (score >= 45) {
    return _competitionText(context, 'Stressed', 'அழுத்தம்');
  }
  return _competitionText(context, 'Needs help', 'உதவி தேவை');
}

Color _meterColor(double score) {
  if (score >= 80) return const Color(0xFF159454);
  if (score >= 65) return const Color(0xFFC79A08);
  if (score >= 45) return const Color(0xFFE27D26);
  return const Color(0xFFD73F35);
}

IconData _homeWeatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 3) return Icons.cloud_outlined;
  if (code >= 95) return Icons.thunderstorm_rounded;
  if (code >= 51 && code <= 82) return Icons.water_drop_outlined;
  return Icons.cloud_queue_rounded;
}

String _plantResponse(BuildContext context, BioelectricIntelligence bio) {
  if (bio.available == false)
    return FarmerLanguage.label(context, 'signal_unavailable');
  final state = bio.stressState?.toUpperCase() ?? '';
  if (state.contains('RECOVER'))
    return FarmerLanguage.label(context, 'recovering');
  if (state.contains('STRONG') ||
      (bio.stressScore != null && bio.stressScore! >= 80)) {
    return FarmerLanguage.label(context, 'strongly_stressed');
  }
  if (state.contains('STRESS') ||
      (bio.stressScore != null && bio.stressScore! >= 55)) {
    return FarmerLanguage.label(context, 'stressed');
  }
  if (state.contains('MILD') ||
      (bio.stressScore != null && bio.stressScore! >= 30)) {
    return FarmerLanguage.label(context, 'mild_response');
  }
  return FarmerLanguage.label(context, 'calm');
}

String _friendlyChannel(BuildContext context, String raw) {
  final value = raw.toLowerCase();
  if (value.contains('soil') && value.contains('moist'))
    return FarmerLanguage.label(context, 'soil_moisture');
  if (value.contains('vpd') || value.contains('drying'))
    return FarmerLanguage.label(context, 'air_drying');
  if (value.contains('bio') || value.contains('plant'))
    return FarmerLanguage.label(context, 'plant_response');
  if (value.contains('root') && value.contains('temp'))
    return FarmerLanguage.label(context, 'root_temp');
  if (value.contains('air') && value.contains('temp'))
    return FarmerLanguage.label(context, 'air_temp');
  if (value.contains('humid')) return FarmerLanguage.label(context, 'humidity');
  if (value.contains('leaf'))
    return FarmerLanguage.label(context, 'leaf_wetness');
  return raw.replaceAll('_', ' ');
}

Color _stateColor(BuildContext context, String raw) {
  final value = raw.toUpperCase();
  if (value.contains('CRITICAL')) return Theme.of(context).colorScheme.error;
  if (value.contains('STRESS') ||
      value.contains('WATCH') ||
      value.contains('ATTENTION')) {
    return Theme.of(context).colorScheme.tertiary;
  }
  return Theme.of(context).colorScheme.primary;
}

String _competitionText(BuildContext context, String english, String tamil) =>
    FarmerLanguage.isTamil(context) ? tamil : english;

String _relativeAge(Duration age) {
  if (age.inSeconds < 2) return 'now';
  if (age.inSeconds < 60) return '${age.inSeconds}s ago';
  if (age.inMinutes < 60) return '${age.inMinutes}m ago';
  return '${age.inHours}h ago';
}
