import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/edge_alert_language.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

enum _TimelineFilter { all, plant, sensor, alerts }

class ObservationTimelineScreen extends StatefulWidget {
  const ObservationTimelineScreen({super.key});

  @override
  State<ObservationTimelineScreen> createState() =>
      _ObservationTimelineScreenState();
}

class _ObservationTimelineScreenState extends State<ObservationTimelineScreen> {
  _TimelineFilter filter = _TimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.sensors, scope.alerts]),
      builder: (context, _) {
        final history = scope.sensors
            .historyFor(scope.sensors.selectedNodeId)
            .toList(growable: false);
        final recent = history.length <= 60
            ? history
            : history.sublist(history.length - 60);
        final edge = scope.sensors.edgeIntelligence;

        final entries = <_TimelineEntry>[
          for (final event in edge?.recentEvents ?? const <PhytoEvent>[])
            _eventEntry(context, event),
          for (final alert in scope.alerts.alerts)
            _TimelineEntry(
              time: alert.timestamp,
              type: _TimelineFilter.alerts,
              icon: Icons.notification_important_outlined,
              title: EdgeAlertLanguage.text(context, alert.titleKey) ??
                  alert.titleKey,
              body: EdgeAlertLanguage.text(context, alert.messageKey) ??
                  alert.messageKey,
              color: alert.severity.name == 'critical'
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary,
            ),
          if (scope.sensors.current case final reading?)
            _TimelineEntry(
              time: reading.timestamp,
              type: _TimelineFilter.sensor,
              icon: Icons.sensors_rounded,
              title: FarmerLanguage.isTamil(context)
                  ? 'சமீப நேரடி அளவீடு'
                  : 'Latest live reading',
              body: _latestReadingBody(context, scope, reading),
              color: Theme.of(context).colorScheme.primary,
            ),
        ]..sort((a, b) => b.time.compareTo(a.time));

        final visible = filter == _TimelineFilter.all
            ? entries
            : entries.where((entry) => entry.type == filter).toList();

        return Scaffold(
          appBar: AppBar(title: Text(FarmerLanguage.label(context, 'history'))),
          body: PageFrame(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FarmerLanguage.label(context, 'recent_trend'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          FarmerLanguage.isTamil(context)
                              ? 'செடியின் நிலை, வேர் மண் மற்றும் plant response எப்படி மாறுகிறது என்பதைப் பாருங்கள்.'
                              : 'See how plant condition, root soil and plant response are changing over time.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  PhytoStatusBadge(
                    label: scope.sensors.source == SensorDataSource.esp32
                        ? 'ESP32 LIVE'
                        : FarmerLanguage.label(context, 'simulated'),
                    icon: scope.sensors.source == SensorDataSource.esp32
                        ? Icons.memory_rounded
                        : Icons.science_outlined,
                    color: scope.sensors.source == SensorDataSource.esp32
                        ? const Color(0xFF397FC0)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HistoryCharts(history: recent),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.timeline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          FarmerLanguage.label(
                            context,
                            'observed_sequence_note',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_TimelineFilter>(
                  segments: [
                    ButtonSegment(
                      value: _TimelineFilter.all,
                      label: Text(
                        FarmerLanguage.isTamil(context) ? 'அனைத்தும்' : 'All',
                      ),
                    ),
                    ButtonSegment(
                      value: _TimelineFilter.plant,
                      icon: const Icon(Icons.eco_outlined),
                      label: Text(
                        FarmerLanguage.isTamil(context) ? 'செடி' : 'Plant',
                      ),
                    ),
                    ButtonSegment(
                      value: _TimelineFilter.sensor,
                      icon: const Icon(Icons.sensors_outlined),
                      label: Text(FarmerLanguage.label(context, 'sensors')),
                    ),
                    ButtonSegment(
                      value: _TimelineFilter.alerts,
                      icon: const Icon(Icons.notifications_none_rounded),
                      label: Text(
                        FarmerLanguage.isTamil(context)
                            ? 'எச்சரிக்கைகள்'
                            : 'Alerts',
                      ),
                    ),
                  ],
                  selected: {filter},
                  onSelectionChanged: (value) {
                    if (value.isNotEmpty) setState(() => filter = value.first);
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (visible.isEmpty)
                PhytoEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: FarmerLanguage.label(context, 'no_history'),
                  body: FarmerLanguage.isTamil(context)
                      ? 'ESP32 அல்லது Simulation source-ஐ தொடர்ந்து இயக்கினால் நிகழ்வுகள் இங்கே தோன்றும்.'
                      : 'Keep the ESP32 or simulation source running and events will appear here.',
                )
              else
                for (var index = 0; index < visible.length; index++)
                  _TimelineTile(
                    entry: visible[index],
                    last: index == visible.length - 1,
                  ),
            ],
          ),
        );
      },
    );
  }

  _TimelineEntry _eventEntry(BuildContext context, PhytoEvent event) {
    final normalized = event.type.toUpperCase();
    final plantEvent = normalized.contains('PLANT') ||
        normalized.contains('BIO') ||
        normalized.contains('STRESS') ||
        normalized.contains('RECOVER');
    final type = plantEvent ? _TimelineFilter.plant : _TimelineFilter.sensor;
    final severity = event.severity?.toUpperCase() ?? '';
    final color = severity.contains('CRITICAL') || severity.contains('HIGH')
        ? Theme.of(context).colorScheme.error
        : plantEvent
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.primary;
    return _TimelineEntry(
      time: event.timestamp ?? DateTime.now(),
      type: type,
      icon: plantEvent ? Icons.eco_outlined : Icons.sensors_outlined,
      title: plantEvent
          ? FarmerLanguage.label(context, 'plant_event')
          : FarmerLanguage.label(context, 'sensor_event'),
      body: FarmerLanguage.firmware(context, event.message,
          fallback: event.message),
      color: color,
    );
  }
}

class _HistoryCharts extends StatelessWidget {
  final List<SensorReading> history;

  const _HistoryCharts({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.show_chart_rounded),
              const SizedBox(width: 12),
              Expanded(child: Text(FarmerLanguage.label(context, 'no_history'))),
            ],
          ),
        ),
      );
    }

    final health = <double?>[
      for (final reading in history)
        reading.esp32HealthScore ?? reading.healthScore,
    ];
    final soil = <double?>[
      for (final reading in history)
        reading.soilMoistureAvailable ? reading.soilMoisture : null,
    ];
    final stress = <double?>[
      for (final reading in history)
        reading.plantSignalAvailable ? reading.stressScore : null,
    ];

    return Column(
      children: [
        _TrendChartCard(
          title: FarmerLanguage.label(context, 'health_history'),
          icon: Icons.eco_rounded,
          values: health,
        ),
        const SizedBox(height: 10),
        _TrendChartCard(
          title: FarmerLanguage.label(context, 'soil_history'),
          icon: Icons.water_drop_outlined,
          values: soil,
          suffix: '%',
        ),
        const SizedBox(height: 10),
        _TrendChartCard(
          title: FarmerLanguage.label(context, 'stress_history'),
          icon: Icons.monitor_heart_outlined,
          values: stress,
        ),
      ],
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<double?> values;
  final String suffix;

  const _TrendChartCard({
    required this.title,
    required this.icon,
    required this.values,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value != null && value.isFinite) {
        spots.add(FlSpot(i.toDouble(), value.clamp(0, 100).toDouble()));
      }
    }
    final latest = spots.isEmpty ? null : spots.last.y;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (latest != null)
                  Text(
                    '${latest.round()}$suffix',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (spots.length < 2)
              SizedBox(
                height: 72,
                child: Center(
                  child: Text(FarmerLanguage.label(context, 'no_history')),
                ),
              )
            else
              SizedBox(
                height: 112,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    minX: 0,
                    maxX: (values.length - 1).toDouble(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.45),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineTouchData: LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        barWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _TimelineEntry entry;
  final bool last;

  const _TimelineTile({required this.entry, required this.last});

  @override
  Widget build(BuildContext context) {
    final hour = entry.time.hour.toString().padLeft(2, '0');
    final minute = entry.time.minute.toString().padLeft(2, '0');
    final date = '${entry.time.day}/${entry.time.month}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(entry.icon, color: entry.color, size: 20),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 82,
                  color: entry.color.withValues(alpha: 0.24),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          '$date • $hour:$minute',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(entry.body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _latestReadingBody(
  BuildContext context,
  AppScope scope,
  SensorReading reading,
) {
  final edge = scope.sensors.edgeIntelligence;
  if (scope.sensors.source == SensorDataSource.esp32 &&
      edge?.hasAuthoritativeAnalysis == true) {
    final state = FarmerLanguage.firmware(
      context,
      edge?.plantState,
      fallback: FarmerLanguage.label(context, 'latest_reading_no_health'),
    );
    final cause = FarmerLanguage.firmware(context, edge?.rootCause.primary);
    return cause.isEmpty ? state : '$state • $cause';
  }
  return '${FarmerLanguage.firmware(context, reading.healthStatus)} • ${reading.healthScore.round()}/100';
}

class _TimelineEntry {
  final DateTime time;
  final _TimelineFilter type;
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _TimelineEntry({
    required this.time,
    required this.type,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}
