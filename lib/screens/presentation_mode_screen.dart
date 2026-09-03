import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../services/ai_analysis_service.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';

class PresentationModeScreen extends StatefulWidget {
  const PresentationModeScreen({super.key});

  @override
  State<PresentationModeScreen> createState() => _PresentationModeScreenState();
}

class _PresentationModeScreenState extends State<PresentationModeScreen> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final content = _content(context)[step];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('presentation_mode')),
        actions: [
          IconButton(
            tooltip: context.tr('reset_presentation'),
            onPressed: scope.sensorManager.source == SensorDataSource.simulation
                ? () async {
                    await scope.settings.setScenario('healthy');
                    scope.sensorManager.setScenario('healthy');
                    if (mounted) setState(() => step = 0);
                  }
                : null,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${step + 1}/${_content(context).length}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (step + 1) / _content(context).length,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: content.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            content.icon,
                            color: content.color,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          content.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          content.body,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        for (final point in content.points)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: phytoLeaf,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(point)),
                              ],
                            ),
                          ),
                        if (step == 3) ...[
                          const SizedBox(height: 8),
                          _DemoControls(
                            onScenarioChanged: (_) => setState(() {}),
                          ),
                        ],
                        if (step == 4) ...[
                          const SizedBox(height: 8),
                          const _PresentationSnapshot(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Row(
                children: [
                  if (step > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => step--),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(context.tr('previous')),
                      ),
                    ),
                  if (step > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (step == _content(context).length - 1) {
                          Navigator.pop(context);
                        } else {
                          setState(() => step++);
                        }
                      },
                      icon: Icon(
                        step == _content(context).length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        context.tr(
                          step == _content(context).length - 1
                              ? 'finish'
                              : 'next',
                        ),
                      ),
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

  List<_PresentationContent> _content(BuildContext context) => [
        _PresentationContent(
          icon: Icons.agriculture_outlined,
          color: phytoGreen,
          title: context.tr('presentation_problem_title'),
          body: context.tr('presentation_problem_body'),
          points: [
            context.tr('presentation_problem_1'),
            context.tr('presentation_problem_2'),
          ],
        ),
        _PresentationContent(
          icon: Icons.hub_outlined,
          color: const Color(0xFF2775B6),
          title: context.tr('presentation_system_title'),
          body: context.tr('presentation_system_body'),
          points: [
            context.tr('presentation_system_1'),
            context.tr('presentation_system_2'),
            context.tr('presentation_system_3'),
          ],
        ),
        _PresentationContent(
          icon: Icons.auto_awesome_outlined,
          color: phytoLeaf,
          title: context.tr('presentation_intelligence_title'),
          body: context.tr('presentation_intelligence_body'),
          points: [
            context.tr('presentation_intelligence_1'),
            context.tr('presentation_intelligence_2'),
            context.tr('presentation_intelligence_3'),
          ],
        ),
        _PresentationContent(
          icon: Icons.science_outlined,
          color: phytoAmber,
          title: context.tr('presentation_demo_title'),
          body: context.tr('presentation_demo_body'),
          points: [
            context.tr('presentation_demo_1'),
            context.tr('presentation_demo_2'),
          ],
        ),
        _PresentationContent(
          icon: Icons.space_dashboard_outlined,
          color: const Color(0xFF397FC0),
          title: context.tr('presentation_dashboard_title'),
          body: context.tr('presentation_dashboard_body'),
          points: [
            context.tr('presentation_dashboard_1'),
            context.tr('presentation_dashboard_2'),
          ],
        ),
        _PresentationContent(
          icon: Icons.psychology_alt_outlined,
          color: const Color(0xFF7A5CC7),
          title: context.tr('presentation_ai_title'),
          body: context.tr('presentation_ai_body'),
          points: [
            context.tr('presentation_ai_1'),
            context.tr('presentation_ai_2'),
          ],
        ),
        _PresentationContent(
          icon: Icons.public_rounded,
          color: phytoLeaf,
          title: context.tr('presentation_impact_title'),
          body: context.tr('presentation_impact_body'),
          points: [
            context.tr('presentation_impact_1'),
            context.tr('presentation_impact_2'),
            context.tr('presentation_impact_3'),
          ],
        ),
      ];
}

class _PresentationSnapshot extends StatelessWidget {
  const _PresentationSnapshot();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.sensors,
      builder: (context, _) {
        final reading = scope.sensors.current;
        if (reading == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text(context.tr('no_data'))),
            ),
          );
        }
        final hardwareMode = scope.sensors.source == SensorDataSource.esp32;
        final analysis = hardwareMode
            ? null
            : AiAnalysisService.analyze(
                reading,
                scope.sensors.historyFor(reading.nodeId),
                crop: scope.farms.selectedField.crop,
              );
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      scope.sensors.source == SensorDataSource.esp32
                          ? Icons.memory_rounded
                          : Icons.science_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(
                          scope.sensors.source == SensorDataSource.esp32
                              ? 'live_session_badge'
                              : 'source_demo_badge',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      reading.nodeId,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SnapshotMetric(
                      label: context.tr('health_score'),
                      value: reading.edgeAnalysisAvailable || !hardwareMode
                          ? '${reading.healthScore.round()}%'
                          : '—',
                    ),
                    _SnapshotMetric(
                      label: context.tr('soil_moisture'),
                      value: reading.soilMoistureAvailable
                          ? '${reading.soilMoisture.round()}%'
                          : '—',
                    ),
                    _SnapshotMetric(
                      label: context.tr('temperature'),
                      value: reading.temperatureAvailable
                          ? '${reading.temperature.toStringAsFixed(1)}°C'
                          : '—',
                    ),
                    _SnapshotMetric(
                      label: context.tr('plant_signal'),
                      value: reading.plantSignalAvailable
                          ? '${reading.plantSignal.round()}%'
                          : '—',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hardwareMode
                            ? reading.healthStatus.replaceAll('_', ' ')
                            : context.tr(analysis!.headlineKey),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hardwareMode
                            ? (reading.primaryRootCause.isEmpty
                                ? 'ESP32 analysis unavailable'
                                : reading.primaryRootCause.replaceAll(
                                    '_',
                                    ' ',
                                  ))
                            : context.tr(analysis!.evidenceKey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _DemoControls extends StatelessWidget {
  final ValueChanged<String> onScenarioChanged;
  const _DemoControls({required this.onScenarioChanged});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isSimulation =
        scope.sensorManager.source == SensorDataSource.simulation;
    return Card(
      color: phytoAmber.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('demo_console'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(context.tr('demo_console_body')),
            const SizedBox(height: 14),
            if (!isSimulation)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await scope.settings.setDataSource('simulation');
                    scope.alerts.clear();
                    scope.sensorManager.configure(
                      source: SensorDataSource.simulation,
                      endpoint: scope.settings.value.esp32Endpoint,
                    );
                    onScenarioChanged('healthy');
                  },
                  icon: const Icon(Icons.science_outlined),
                  label: Text(context.tr('switch_to_demo')),
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['healthy', 'dry', 'heat_stress', 'critical']
                    .map(
                      (scenario) => ChoiceChip(
                        label: Text(context.tr('scenario_$scenario')),
                        selected: scope.sensorManager.scenarioId == scenario,
                        onSelected: (_) {
                          scope.settings.setScenario(scenario);
                          scope.sensorManager.setScenario(scenario);
                          onScenarioChanged(scenario);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: scope.sensorManager,
                builder: (context, _) {
                  final reading = scope.sensorManager.current;
                  if (reading == null) {
                    return Text(context.tr('no_data'));
                  }
                  final analysis = AiAnalysisService.analyze(
                    reading,
                    scope.sensorManager.historyFor(reading.nodeId),
                    crop: scope.farms.selectedField.crop,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniMetric(
                              label: context.tr('health_score'),
                              value: '${reading.healthScore.round()}%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniMetric(
                              label: context.tr('soil_moisture'),
                              value: '${reading.soilMoisture.round()}%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniMetric(
                              label: context.tr('temperature'),
                              value:
                                  '${reading.temperature.toStringAsFixed(1)}°',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          context.tr(analysis.headlineKey),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _PresentationContent {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<String> points;
  const _PresentationContent({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.points,
  });
}
