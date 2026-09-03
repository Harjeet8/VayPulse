import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/disease_assessment.dart';
import '../models/farm.dart';
import '../models/sensor_reading.dart';
import '../services/ai_analysis_service.dart';
import '../services/app_scope.dart';
import '../services/irrigation_advisor.dart';
import '../services/multimodal_disease_service.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/health_ring.dart';
import '../widgets/data_source_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/page_frame.dart';
import '../widgets/plant_pulse.dart';
import '../widgets/sensor_card.dart';
import '../widgets/phyto_ui.dart';
import 'irrigation_advisor_screen.dart';
import 'leaf_screening_screen.dart';
import 'live_node_home_screen.dart';
import 'observation_timeline_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenFields;

  const HomeScreen({super.key, this.onOpenAlerts, this.onOpenFields});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        scope.sensors,
        scope.farms,
        scope.alerts,
        scope.weather,
      ]),
      builder: (context, _) {
        if (scope.sensors.source == SensorDataSource.esp32) {
          return LiveNodeHomeScreen(onOpenAlerts: onOpenAlerts);
        }
        if (!scope.farms.isLoaded) {
          return Scaffold(
            body: Center(child: Text(context.tr('loading_data'))),
          );
        }
        if (scope.farms.farms.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('dashboard'))),
            body: Center(child: Text(context.tr('no_farms'))),
          );
        }

        final farm = scope.farms.selectedFarm;
        final field = scope.farms.selectedField;
        final zone = scope.farms.selectedZone;
        final reading = scope.sensors.current;
        final diseasePrompt = MultimodalDiseaseService.evaluatePhotoPrompt(
          reading,
          scope.weather.isFresh ? scope.weather.snapshot : null,
          crop: field.crop,
        );
        final zoneScore = _zoneScore(zone, scope.sensors.latestReadings);
        final analysis = reading == null
            ? null
            : AiAnalysisService.analyze(
                reading,
                scope.sensors.historyFor(reading.nodeId),
                crop: field.crop,
              );
        final selectableZones = scope.farms.allZones;
        final judgeMode = scope.settings.value.experienceMode == 'judge';

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [phytoGreen, phytoLeaf],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'PhytoSense AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
              scope.sensors.retry();
              await scope.weather.refresh();
            },
            child: PageFrame(
              children: [
                Text(
                  _greeting(context),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(context.tr('farm_status_subtitle')),
                const SizedBox(height: 14),
                const DataSourceCard(),
                const SizedBox(height: 12),
                _DailyBriefing(
                  analysis: analysis,
                  unreadAlerts: scope.alerts.unreadCount,
                  onSpeak: analysis == null
                      ? null
                      : () => scope.voice.speak(
                          text:
                              '${context.tr(analysis.headlineKey)}. ${context.tr(analysis.recommendationKey)}',
                          languageCode: scope.settings.value.languageCode,
                        ),
                ),
                const SizedBox(height: 18),
                _FarmSelector(
                  farm: farm,
                  field: field,
                  zone: zone,
                  zones: selectableZones,
                  onChanged: (zoneId) {
                    if (zoneId == null) return;
                    final selectedZone = scope.farms.zoneById(zoneId);
                    final selectedField = scope.farms.fieldForZone(zoneId);
                    if (selectedZone == null || selectedField == null) return;
                    scope.farms.selectZone(
                      farmId: farm.id,
                      fieldId: selectedField.id,
                      zoneId: selectedZone.id,
                    );
                    if (selectedZone.nodeIds.isNotEmpty) {
                      scope.sensors.selectNode(selectedZone.nodeIds.first);
                    }
                  },
                ),
                const SizedBox(height: 14),
                if (scope.sensors.connectionStatus !=
                    SensorConnectionStatus.ready)
                  _ConnectionPanel(status: scope.sensors.connectionStatus),
                if (scope.sensors.connectionStatus !=
                    SensorConnectionStatus.ready)
                  const SizedBox(height: 14),
                _HealthHero(
                  farmName: farm.name,
                  fieldName: field.name,
                  zoneName: zone.name,
                  score: zoneScore,
                ),
                if (analysis != null) ...[
                  const SizedBox(height: 14),
                  FarmerActionCard(
                    icon: analysis.level == InsightLevel.healthy
                        ? Icons.verified_outlined
                        : Icons.task_alt_rounded,
                    eyebrow: context.tr('farmer_next_action'),
                    title: context.tr(analysis.headlineKey),
                    body: context.tr(analysis.recommendationKey),
                    actionLabel: context.tr('hear_guidance'),
                    onAction: () => scope.voice.speak(
                      text:
                          '${context.tr(analysis.headlineKey)}. ${context.tr(analysis.recommendationKey)}',
                      languageCode: scope.settings.value.languageCode,
                    ),
                    accent: _insightColor(context, analysis.level),
                  ),
                ],
                const SizedBox(height: 14),
                _FarmerTools(onOpenAlerts: onOpenAlerts),
                const SizedBox(height: 22),
                _SectionTitle(title: context.tr('live_conditions')),
                const SizedBox(height: 12),
                if (reading == null)
                  _EmptyCard(message: context.tr('no_data'))
                else if (judgeMode)
                  _SensorGrid(reading: reading),
                if (reading != null && !judgeMode)
                  _CollapsibleSensorDetails(reading: reading),
                if (diseasePrompt.shouldPrompt) ...[
                  const SizedBox(height: 14),
                  _DiseasePhotoPromptCard(
                    prompt: diseasePrompt,
                    crop: field.crop,
                    isLive: scope.sensors.source == SensorDataSource.esp32,
                  ),
                ],
                const SizedBox(height: 22),
                _SectionTitle(title: context.tr('ai_field_insight')),
                const SizedBox(height: 12),
                if (analysis == null)
                  _EmptyCard(message: context.tr('no_data'))
                else ...[
                  InsightCard(
                    title: context.tr(analysis.headlineKey),
                    message: context.tr(analysis.explanationKey),
                    action:
                        '${context.tr('recommended_action')}: ${context.tr(analysis.recommendationKey)}',
                    accent: _insightColor(context, analysis.level),
                  ),
                  if (judgeMode) ...[
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.rule_rounded, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.tr('why_this'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  context.tr('confidence', {
                                    'value': analysis.confidence,
                                  }),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(context.tr(analysis.evidenceKey)),
                            const SizedBox(height: 10),
                            Text(
                              context.tr('decision_support_note'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('analysis_method_note'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 18),
                const _IrrigationSummary(),
                const SizedBox(height: 22),
                _ZonesToWatch(onOpenFields: onOpenFields),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('good_morning');
    if (hour < 17) return context.tr('good_afternoon');
    return context.tr('good_evening');
  }

  static double _zoneScore(FarmZone zone, Map<String, SensorReading> readings) {
    final scores = zone.nodeIds
        .map((id) => readings[id]?.healthScore)
        .whereType<double>()
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  static Color _insightColor(BuildContext context, InsightLevel level) =>
      switch (level) {
        InsightLevel.healthy => Theme.of(context).colorScheme.primary,
        InsightLevel.attention => Theme.of(context).colorScheme.tertiary,
        InsightLevel.urgent => Theme.of(context).colorScheme.error,
      };
}

class _DiseasePhotoPromptCard extends StatelessWidget {
  final DiseasePhotoPrompt prompt;
  final String crop;
  final bool isLive;

  const _DiseasePhotoPromptCard({
    required this.prompt,
    required this.crop,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = prompt.urgent ? phytoTerracotta : phytoAmber;
    return Card(
      color: accent.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.add_a_photo_outlined, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('disease_photo_prompt_title'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              context.tr(
                                isLive
                                    ? 'source_live_badge'
                                    : 'source_demo_badge',
                              ),
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('disease_photo_prompt_body', {'crop': crop}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            for (final reasonKey in prompt.reasonKeys)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, color: accent, size: 8),
                    const SizedBox(width: 9),
                    Expanded(child: Text(context.tr(reasonKey))),
                  ],
                ),
              ),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LeafScreeningScreen(sensorPrompt: true),
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
}

class _DailyBriefing extends StatelessWidget {
  final AiAnalysisResult? analysis;
  final int unreadAlerts;
  final VoidCallback? onSpeak;

  const _DailyBriefing({
    required this.analysis,
    required this.unreadAlerts,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final attention = analysis?.level != InsightLevel.healthy;
    final color = attention
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;
    return Card(
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                attention ? Icons.wb_sunny_outlined : Icons.eco_outlined,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('daily_briefing'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis == null
                        ? context.tr('daily_briefing_waiting')
                        : context.tr(analysis!.explanationKey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('daily_alert_count', {'value': unreadAlerts}),
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('hear_guidance'),
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerTools extends StatelessWidget {
  final VoidCallback? onOpenAlerts;

  const _FarmerTools({required this.onOpenAlerts});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 700
          ? (constraints.maxWidth - 24) / 4
          : (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: width,
            child: _ToolButton(
              icon: Icons.document_scanner_outlined,
              label: context.tr('scan_leaf'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeafScreeningScreen()),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: _ToolButton(
              icon: Icons.water_drop_outlined,
              label: context.tr('irrigation_short'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IrrigationAdvisorScreen(),
                ),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: _ToolButton(
              icon: Icons.notifications_active_outlined,
              label: context.tr('nav_alerts'),
              onTap: onOpenAlerts ?? () {},
            ),
          ),
          SizedBox(
            width: width,
            child: _ToolButton(
              icon: Icons.timeline_rounded,
              label: context.tr('history'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ObservationTimelineScreen(),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}

class _IrrigationSummary extends StatelessWidget {
  const _IrrigationSummary();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.sensors, scope.weather]),
      builder: (context, _) {
        final advice = IrrigationAdvisor.advise(
          scope.sensors.current,
          scope.weather.isFresh ? scope.weather.snapshot : null,
          cropStage: scope.farms.selectedZone.cropStage,
          crop: scope.farms.selectedField.crop,
        );
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 9,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2775B6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                color: Color(0xFF2775B6),
              ),
            ),
            title: Text(
              context.tr(advice.titleKey),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(context.tr(advice.actionKey)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IrrigationAdvisorScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FarmSelector extends StatelessWidget {
  final Farm farm;
  final FarmField field;
  final FarmZone zone;
  final List<FarmZone> zones;
  final ValueChanged<String?> onChanged;

  const _FarmSelector({
    required this.farm,
    required this.field,
    required this.zone,
    required this.zones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = zones.any((item) => item.id == zone.id)
        ? zone.id
        : (zones.isEmpty ? null : zones.first.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.agriculture_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${field.name} • ${farm.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                borderRadius: BorderRadius.circular(16),
                items: zones
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthHero extends StatelessWidget {
  final String farmName;
  final String fieldName;
  final String zoneName;
  final double score;

  const _HealthHero({
    required this.farmName,
    required this.fieldName,
    required this.zoneName,
    required this.score,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0F5A40), Color(0xFF21845D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: phytoGreen.withValues(alpha: 0.24),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.42,
            child: PlantPulse(color: Colors.white.withValues(alpha: 0.32)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('zone_health'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    zoneName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$fieldName • $farmName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      score >= 75
                          ? context.tr('stable')
                          : score >= 45
                          ? context.tr('needs_attention')
                          : context.tr('urgent_check'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
              final ring = HealthRing(
                score: score,
                size: 112,
                label: context.tr('health_score'),
                color: Colors.white,
                textColor: Colors.white,
              );
              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.center, child: ring),
                    const SizedBox(height: 18),
                    details,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  ring,
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _SensorGrid extends StatelessWidget {
  final SensorReading reading;

  const _SensorGrid({required this.reading});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final metric = scope.settings.value.metricUnits;
    final animate = !scope.settings.value.reducedMotion;
    final history = scope.sensors.historyFor(reading.nodeId);
    final previous = history.length > 1 ? history[history.length - 2] : null;
    final temperature = metric
        ? reading.temperature
        : reading.temperature * 9 / 5 + 32;
    final unit = metric ? '°C' : '°F';
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cards = <Widget>[
      SensorCard(
        icon: Icons.water_drop_outlined,
        title: context.tr('soil_moisture'),
        value: reading.soilMoisture.toStringAsFixed(0),
        numericValue: reading.soilMoisture,
        previousValue: previous?.soilMoisture,
        unit: '%',
        preferredRange: context.tr('preferred_soil_range'),
        animate: animate,
        status: reading.soilMoisture < 30
            ? context.tr('low')
            : reading.soilMoisture > 88
            ? context.tr('high')
            : context.tr('good'),
        accent: const Color(0xFF2F85C8),
      ),
      SensorCard(
        icon: Icons.thermostat_outlined,
        title: context.tr('temperature'),
        value: temperature.toStringAsFixed(1),
        numericValue: temperature,
        previousValue: previous == null
            ? null
            : metric
            ? previous.temperature
            : previous.temperature * 9 / 5 + 32,
        unit: unit,
        decimals: 1,
        preferredRange: context.tr('preferred_temperature_range'),
        animate: animate,
        status: reading.temperature > 33
            ? context.tr('high')
            : context.tr('normal'),
        accent: phytoTerracotta,
      ),
      SensorCard(
        icon: Icons.water_outlined,
        title: context.tr('humidity'),
        value: reading.humidity.toStringAsFixed(0),
        numericValue: reading.humidity,
        previousValue: previous?.humidity,
        unit: '%',
        preferredRange: context.tr('preferred_humidity_range'),
        animate: animate,
        status: context.tr('normal'),
        accent: const Color(0xFF6D78CE),
      ),
      SensorCard(
        icon: Icons.wb_sunny_outlined,
        title: context.tr('light'),
        value: reading.light.toStringAsFixed(0),
        numericValue: reading.light,
        previousValue: previous?.light,
        unit: '%',
        preferredRange: context.tr('preferred_light_range'),
        animate: animate,
        status: reading.light < 25 ? context.tr('low') : context.tr('good'),
        accent: phytoAmber,
      ),
      SensorCard(
        icon: Icons.monitor_heart_outlined,
        title: context.tr('plant_signal'),
        value: reading.plantSignal.toStringAsFixed(0),
        numericValue: reading.plantSignal,
        previousValue: previous?.plantSignal,
        unit: '%',
        preferredRange: context.tr('preferred_signal_range'),
        animate: animate,
        status: reading.plantSignal < 30
            ? context.tr('needs_attention')
            : context.tr('stable'),
        accent: const Color(0xFF7A5CC7),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth / textScale;
        final columns = effectiveWidth >= 920
            ? 5
            : effectiveWidth >= 680
            ? 3
            : effectiveWidth >= 360
            ? 2
            : 1;
        const spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _CollapsibleSensorDetails extends StatelessWidget {
  final SensorReading reading;

  const _CollapsibleSensorDetails({required this.reading});

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: const Icon(Icons.sensors_outlined),
      title: Text(
        context.tr('view_sensor_details'),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(context.tr('view_sensor_details_body')),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      children: [_SensorGrid(reading: reading)],
    ),
  );
}

class _ConnectionPanel extends StatelessWidget {
  final SensorConnectionStatus status;

  const _ConnectionPanel({required this.status});

  @override
  Widget build(BuildContext context) {
    final offline = status == SensorConnectionStatus.offline;
    final loading = status == SensorConnectionStatus.loading;
    final scope = AppScope.of(context);
    final hardware = scope.sensors.source == SensorDataSource.esp32;
    final detailKey = loading
        ? 'connecting_sensor_body'
        : hardware
        ? (scope.sensors.errorMessage ?? 'hardware_unreachable')
        : (offline ? 'offline_message' : 'error_message');
    final accent = loading
        ? const Color(0xFF2775B6)
        : (offline ? phytoAmber : phytoTerracotta);
    return Card(
      color: accent.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              loading
                  ? Icons.sync_rounded
                  : offline
                  ? Icons.cloud_off_outlined
                  : Icons.sensors_off_outlined,
              color: accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      loading
                          ? 'connecting_sensor'
                          : offline
                          ? 'sensor_network_offline'
                          : 'sensor_network_error',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(context.tr(detailKey)),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: () {
                  scope.sensors.retry();
                  if (scope.sensors.source == SensorDataSource.simulation) {
                    scope.settings.setScenario('healthy');
                  }
                },
                child: Text(context.tr('retry')),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZonesToWatch extends StatelessWidget {
  final VoidCallback? onOpenFields;

  const _ZonesToWatch({this.onOpenFields});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final flagged = <MapEntry<FarmZone, double>>[];
    for (final zone in scope.farms.allZones) {
      final score = HomeScreen._zoneScore(zone, scope.sensors.latestReadings);
      if (score > 0 && score < 72) flagged.add(MapEntry(zone, score));
    }
    flagged.sort((a, b) => a.value.compareTo(b.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _SectionTitle(title: context.tr('zones_to_watch'))),
            TextButton(
              onPressed: onOpenFields,
              child: Text(context.tr('view_fields')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (flagged.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline, color: phytoLeaf),
              title: Text(context.tr('all_zones_healthy')),
            ),
          )
        else
          ...flagged
              .take(3)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: phytoAmber.withValues(alpha: 0.14),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: phytoAmber,
                        ),
                      ),
                      title: Text(entry.key.name),
                      subtitle: Text(switch (entry.key.cropStage) {
                        'Tillering' => context.tr('stage_tillering'),
                        'Flowering' => context.tr('stage_flowering'),
                        'Fruit set' => context.tr('stage_fruit_set'),
                        _ => entry.key.cropStage,
                      }),
                      trailing: Text(
                        '${entry.value.round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: phytoAmber,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.35),
  );
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message)),
    ),
  );
}
