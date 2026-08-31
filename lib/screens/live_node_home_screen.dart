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
    final crop = telemetry?.cropProfile ?? edge?.cropProfile.profile ?? 'Universal';

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
          IconButton(
            tooltip: FarmerLanguage.isTamil(context)
                ? 'Plant Intelligence'
                : 'Plant Intelligence',
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
            const SizedBox(height: 12),
            _ConnectionStrip(
              status: sensors.connectionStatus,
              timestamp: reading?.timestamp,
              onRetry: sensors.retry,
            ),
            const SizedBox(height: 14),
            if (reading == null)
              _WaitingCard(onRetry: sensors.retry)
            else ...[
              _PlantHero(
                crop: crop,
                reading: reading,
                edge: edge,
              ),
              const SizedBox(height: 14),
              _RecommendationCard(
                recommendation: edge?.recommendation,
                explanation: edge?.decisionExplanation,
                onSpeak: edge?.recommendation == null
                    ? null
                    : () => scope.voice.speak(
                          text: edge!.recommendation!,
                          languageCode: scope.settings.value.languageCode,
                        ),
              ),
              if (edge?.rootCause.hasAny == true) ...[
                const SizedBox(height: 12),
                _CauseCard(edge: edge!),
              ],
              if (edge?.degradedAnalysis == true) ...[
                const SizedBox(height: 12),
                _DegradedCard(edge: edge!),
              ],
              const SizedBox(height: 20),
              Text(
                FarmerLanguage.isTamil(context)
                    ? 'முக்கிய நேரடி அளவீடுகள்'
                    : 'Key live readings',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _QuickReadings(reading: reading, telemetry: telemetry),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(
                    FarmerLanguage.isTamil(context)
                        ? 'Camera plant analysis'
                        : 'Camera plant analysis',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    FarmerLanguage.isTamil(context)
                        ? 'Visible leaf symptoms-ஐ camera மூலம் தனியாக ஆய்வு செய்யவும்.'
                        : 'Use the separate camera system to assess visible leaf symptoms.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeafScreeningScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlantHero extends StatelessWidget {
  final String crop;
  final SensorReading reading;
  final EdgeIntelligence? edge;

  const _PlantHero({
    required this.crop,
    required this.reading,
    required this.edge,
  });

  @override
  Widget build(BuildContext context) {
    final state = FarmerLanguage.firmware(
      context,
      edge?.plantState ?? reading.healthStatus,
      fallback: FarmerLanguage.label(context, 'keep_monitoring'),
    );
    final confidence =
        edge?.overallConfidence ?? reading.esp32HealthConfidence ?? reading.analysisConfidence;
    final mainCause = edge?.rootCause.primary ?? edge?.farmerSummary;
    final recovering = (edge?.plantState ?? reading.healthStatus)
        .toUpperCase()
        .contains('RECOVER');
    final accent = recovering
        ? Theme.of(context).colorScheme.tertiary
        : _stateColor(context, edge?.plantState ?? reading.healthStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      state,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.35), width: 4),
                ),
                child: Text(
                  '${reading.healthScore.round()}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Pill(
                icon: Icons.monitor_heart_outlined,
                text: 'Health ${reading.healthScore.round()} / 100',
                color: accent,
              ),
              _Pill(
                icon: Icons.verified_outlined,
                text:
                    '${FarmerLanguage.label(context, 'analysis_confidence')}: ${FarmerLanguage.confidence(context, confidence)}',
                color: accent,
              ),
            ],
          ),
          if (mainCause != null && mainCause.trim().isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              FarmerLanguage.isTamil(context) ? 'முக்கிய பிரச்சினை' : 'Main problem',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              FarmerLanguage.firmware(context, mainCause),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String? recommendation;
  final String? explanation;
  final VoidCallback? onSpeak;

  const _RecommendationCard({
    required this.recommendation,
    required this.explanation,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final action = FarmerLanguage.firmware(
      context,
      recommendation,
      fallback: FarmerLanguage.label(context, 'keep_monitoring'),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    FarmerLanguage.label(context, 'what_to_do'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (onSpeak != null)
                  IconButton(
                    tooltip: context.tr('hear_guidance'),
                    onPressed: onSpeak,
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (explanation != null && explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                FarmerLanguage.firmware(context, explanation),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CauseCard extends StatelessWidget {
  final EdgeIntelligence edge;

  const _CauseCard({required this.edge});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FarmerLanguage.isTamil(context)
                    ? 'ESP32 கண்ட காரணங்கள்'
                    : 'What the ESP32 found',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (edge.rootCause.primary != null) ...[
                const SizedBox(height: 10),
                _CauseLine('Primary', edge.rootCause.primary!),
              ],
              if (edge.rootCause.secondary != null) ...[
                const SizedBox(height: 8),
                _CauseLine('Secondary', edge.rootCause.secondary!),
              ],
              if (edge.rootCause.additionalContributor != null) ...[
                const SizedBox(height: 8),
                _CauseLine('Additional', edge.rootCause.additionalContributor!),
              ],
            ],
          ),
        ),
      );
}

class _CauseLine extends StatelessWidget {
  final String label;
  final String value;
  const _CauseLine(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              FarmerLanguage.firmware(context, value),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
}

class _DegradedCard extends StatelessWidget {
  final EdgeIntelligence edge;
  const _DegradedCard({required this.edge});

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.45),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  edge.degradedReason == null
                      ? (FarmerLanguage.isTamil(context)
                          ? 'சில sensor தகவல்கள் இல்லாவிட்டாலும் பகுப்பாய்வு குறைந்த coverage-ல் தொடர்கிறது.'
                          : 'Analysis is continuing with reduced sensor coverage.')
                      : FarmerLanguage.firmware(context, edge.degradedReason),
                ),
              ),
            ],
          ),
        ),
      );
}

class _QuickReadings extends StatelessWidget {
  final SensorReading reading;
  final HardwareTelemetry? telemetry;

  const _QuickReadings({required this.reading, required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final items = <_QuickItem>[
      _QuickItem(
        Icons.water_drop_outlined,
        FarmerLanguage.label(context, 'soil_moisture'),
        reading.soilMoistureAvailable ? '${reading.soilMoisture.toStringAsFixed(0)}%' : '—',
        telemetry?.sensor('soilMoisture')?.result,
      ),
      _QuickItem(
        Icons.thermostat_rounded,
        FarmerLanguage.label(context, 'air_temp'),
        reading.temperatureAvailable ? '${reading.temperature.toStringAsFixed(1)}°C' : '—',
        telemetry?.sensor('airTemperature')?.result,
      ),
      _QuickItem(
        Icons.water_outlined,
        FarmerLanguage.label(context, 'humidity'),
        reading.humidityAvailable ? '${reading.humidity.toStringAsFixed(0)}%' : '—',
        telemetry?.sensor('humidity')?.result,
      ),
      _QuickItem(
        Icons.device_thermostat_outlined,
        FarmerLanguage.label(context, 'root_temp'),
        reading.soilTemperatureAvailable && reading.soilTemperature != null
            ? '${reading.soilTemperature!.toStringAsFixed(1)}°C'
            : '—',
        telemetry?.sensor('rootTemperature')?.result,
      ),
      _QuickItem(
        Icons.wb_sunny_outlined,
        FarmerLanguage.label(context, 'light_lux'),
        reading.lightAvailable && reading.lightLux != null
            ? '${reading.lightLux!.toStringAsFixed(0)} lux'
            : '—',
        telemetry?.sensor('light')?.result,
      ),
      _QuickItem(
        Icons.eco_outlined,
        FarmerLanguage.label(context, 'leaf_wetness'),
        reading.leafWetnessAvailable && reading.leafWetness != null
            ? '${reading.leafWetness!.toStringAsFixed(0)}%'
            : '—',
        telemetry?.sensor('leafWetness')?.result,
      ),
      _QuickItem(
        Icons.electric_bolt_outlined,
        FarmerLanguage.label(context, 'bio_signal'),
        reading.plantSignalAvailable && reading.plantVoltageMv != null
            ? '${reading.plantVoltageMv!.toStringAsFixed(1)} mV'
            : '—',
        telemetry?.sensor('plantSignal')?.result,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 20) / 3
            : constraints.maxWidth >= 500
                ? (constraints.maxWidth - 10) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => SizedBox(width: width, child: _QuickCard(item: item)))
              .toList(growable: false),
        );
      },
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String title;
  final String value;
  final String? result;
  const _QuickItem(this.icon, this.title, this.value, this.result);
}

class _QuickCard extends StatelessWidget {
  final _QuickItem item;
  const _QuickCard({required this.item});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 3),
                    Text(item.value,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    if (item.result != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        FarmerLanguage.firmware(context, item.result),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
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

class _ConnectionStrip extends StatelessWidget {
  final SensorConnectionStatus status;
  final DateTime? timestamp;
  final VoidCallback onRetry;

  const _ConnectionStrip({
    required this.status,
    required this.timestamp,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ready = status == SensorConnectionStatus.ready;
    return Card(
      child: ListTile(
        leading: Icon(
          ready ? Icons.wifi_tethering_rounded : Icons.portable_wifi_off_rounded,
          color: ready
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(
          ready
              ? (FarmerLanguage.isTamil(context)
                  ? 'ESP32 Live இணைந்துள்ளது'
                  : 'ESP32 Live connected')
              : FarmerLanguage.label(context, 'disconnected'),
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
  const _WaitingCard({required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(
                FarmerLanguage.isTamil(context)
                    ? 'ESP32-இலிருந்து validated reading காத்திருக்கிறது…'
                    : 'Waiting for a validated ESP32 reading…',
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
  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

Color _stateColor(BuildContext context, String raw) {
  final value = raw.toUpperCase();
  if (value.contains('CRITICAL')) return Theme.of(context).colorScheme.error;
  if (value.contains('STRESS') || value.contains('WATCH') || value.contains('ATTENTION')) {
    return Theme.of(context).colorScheme.tertiary;
  }
  return Theme.of(context).colorScheme.primary;
}

String _time(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
