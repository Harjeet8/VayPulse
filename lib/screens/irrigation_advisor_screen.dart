import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../services/irrigation_advisor.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';

class IrrigationAdvisorScreen extends StatelessWidget {
  const IrrigationAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.sensors, scope.weather]),
      builder: (context, _) {
        final reading = scope.sensors.current;
        final hardwareMode = scope.sensors.source == SensorDataSource.esp32;
        final weather = !hardwareMode && scope.weather.isFresh
            ? scope.weather.snapshot
            : null;
        final cropStage = hardwareMode
            ? reading?.growthStage ?? 'Vegetative'
            : scope.farms.selectedZone.cropStage;
        final advice = hardwareMode
            ? null
            : IrrigationAdvisor.advise(
                reading,
                weather,
                cropStage: cropStage,
                crop: scope.farms.selectedField.crop,
              );
        final color = hardwareMode
            ? (reading?.healthStatus.toUpperCase() == 'CRITICAL'
                  ? phytoTerracotta
                  : phytoLeaf)
            : switch (advice!.priority) {
                IrrigationPriority.none => phytoLeaf,
                IrrigationPriority.watch => phytoAmber,
                IrrigationPriority.irrigate => const Color(0xFF2775B6),
                IrrigationPriority.urgent => phytoTerracotta,
              };
        final title = hardwareMode
            ? 'ESP32 farmer guidance'
            : context.tr(advice!.titleKey);
        final body = hardwareMode
            ? (reading?.primaryRootCause.isNotEmpty == true
                  ? reading!.primaryRootCause.replaceAll('_', ' ')
                  : 'The ESP32 has not reported a root cause.')
            : context.tr(advice!.bodyKey);
        final action = hardwareMode
            ? (reading?.farmerAction.isNotEmpty == true
                  ? reading!.farmerAction
                  : 'Awaiting ESP32 guidance.')
            : context.tr(advice!.actionKey);
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('irrigation_advisor'))),
          body: PageFrame(
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D668F), Color(0xFF3B9FAD)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('smart_irrigation'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            context.tr('smart_irrigation_body'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                color: color.withValues(alpha: 0.07),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.recommend_outlined, color: color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(body),
                      const SizedBox(height: 14),
                      _EvidenceRow(
                        icon: Icons.sensors_outlined,
                        text: reading == null || !reading.soilMoistureAvailable
                            ? context.tr('waiting')
                            : '${context.tr('soil_moisture')}: ${reading.soilMoisture.round()}%',
                      ),
                      _EvidenceRow(
                        icon: Icons.cloud_outlined,
                        text: weather?.today == null
                            ? context.tr('weather_unavailable')
                            : '${context.tr('rain_probability')}: ${weather!.today!.precipitationProbability.round()}%',
                      ),
                      _EvidenceRow(
                        icon: Icons.timeline_rounded,
                        text:
                            '${context.tr('crop_stage')}: ${_stageLabel(context, cropStage)}',
                      ),
                      _EvidenceRow(
                        icon: Icons.rule_rounded,
                        text: hardwareMode
                            ? 'ESP32 reliability: ${reading?.reliabilityMode ?? 'unavailable'}'
                            : context.tr(advice!.evidenceKey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${context.tr('recommended_action')}: $action',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _speak(context, title, body, action),
                        icon: const Icon(Icons.volume_up_outlined),
                        label: Text(context.tr('listen_guidance')),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                color: phytoAmber.withValues(alpha: 0.07),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.touch_app_outlined, color: phytoAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(context.tr('irrigation_confirmation_note')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _speak(
    BuildContext context,
    String title,
    String body,
    String action,
  ) async {
    final scope = AppScope.of(context);
    final spoken = await scope.voice.speak(
      text: '$title. $body. $action',
      languageCode: scope.settings.value.languageCode,
    );
    if (!spoken && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('voice_unavailable'))));
    }
  }
}

String _stageLabel(BuildContext context, String stage) => switch (stage) {
  'Seedling' => context.tr('stage_seedling'),
  'Vegetative' => context.tr('stage_vegetative'),
  'Tillering' => context.tr('stage_tillering'),
  'Flowering' => context.tr('stage_flowering'),
  'Fruit set' => context.tr('stage_fruit_set'),
  'Maturity' => context.tr('stage_maturity'),
  _ => stage,
};

class _EvidenceRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EvidenceRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
