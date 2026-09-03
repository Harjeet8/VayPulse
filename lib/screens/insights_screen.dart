import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/sensor_reading.dart';
import '../services/ai_analysis_service.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';

enum _Metric { health, soil, temperature, humidity, plantSignal }

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int range = 0;
  _Metric metric = _Metric.health;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.sensors, scope.offlineSync]),
      builder: (context, _) {
        final nodeId = scope.sensors.selectedNodeId;
        final combined = <SensorReading>[
          if (scope.sensors.source == SensorDataSource.esp32)
            ...scope.offlineSync.readingsFor(nodeId),
          ...scope.sensors.historyFor(nodeId),
        ];
        final byReading = <String, SensorReading>{
          for (final reading in combined)
            '${reading.nodeId}:${reading.timestamp.toIso8601String()}': reading,
        };
        final allHistory = byReading.values.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final duration = switch (range) {
          0 => const Duration(hours: 24),
          1 => const Duration(days: 7),
          _ => const Duration(days: 30),
        };
        final cutoff = DateTime.now().subtract(duration);
        final inRange = allHistory
            .where((reading) => reading.timestamp.isAfter(cutoff))
            .toList();
        final history = _downsample(inRange, 300);
        final values = history.where(_metricAvailable).map(_valueFor).toList();
        final average = values.isEmpty
            ? 0.0
            : values.reduce((a, b) => a + b) / values.length;
        final minimum =
            values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
        final maximum =
            values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
        final current = scope.sensors.current;
        final hardwareMode = scope.sensors.source == SensorDataSource.esp32;
        final analysis = current == null || hardwareMode
            ? null
            : AiAnalysisService.analyze(
                current,
                allHistory,
                crop: scope.farms.selectedField.crop,
              );
        final hardwareAttention = hardwareMode &&
            current != null &&
            const <String>{'WATCH', 'STRESS', 'CRITICAL'}
                .contains(current.healthStatus.toUpperCase());

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('insights_title'))),
          body: PageFrame(
            children: [
              Text(
                context.tr('insights_subtitle'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                key: ValueKey(scope.sensors.selectedNodeId),
                initialValue: scope.sensors.selectedNodeId,
                decoration: InputDecoration(
                  labelText: context.tr('sensor_nodes'),
                  prefixIcon: const Icon(Icons.sensors_outlined),
                ),
                items: scope.sensors.nodes
                    .map((node) => DropdownMenuItem(
                          value: node.id,
                          child: Text(node.zoneId.isEmpty
                              ? node.name
                              : '${node.name} • ${node.zoneId}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) scope.sensors.selectNode(value);
                },
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_Metric>(
                  segments: [
                    ButtonSegment(
                      value: _Metric.health,
                      icon: const Icon(Icons.eco_outlined),
                      label: Text(context.tr('metric_health')),
                    ),
                    ButtonSegment(
                      value: _Metric.soil,
                      icon: const Icon(Icons.water_drop_outlined),
                      label: Text(context.tr('metric_soil')),
                    ),
                    ButtonSegment(
                      value: _Metric.temperature,
                      icon: const Icon(Icons.thermostat_outlined),
                      label: Text(context.tr('metric_temp')),
                    ),
                    ButtonSegment(
                      value: _Metric.humidity,
                      icon: const Icon(Icons.water_outlined),
                      label: Text(context.tr('metric_humidity')),
                    ),
                    ButtonSegment(
                      value: _Metric.plantSignal,
                      icon: const Icon(Icons.monitor_heart_outlined),
                      label: Text(context.tr('metric_signal')),
                    ),
                  ],
                  selected: {metric},
                  onSelectionChanged: (selection) =>
                      setState(() => metric = selection.first),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                        value: 0, label: Text(context.tr('time_24h'))),
                    ButtonSegment(value: 1, label: Text(context.tr('time_7d'))),
                    ButtonSegment(
                        value: 2, label: Text(context.tr('time_30d'))),
                  ],
                  selected: {range},
                  onSelectionChanged: (selection) =>
                      setState(() => range = selection.first),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 22, 18, 16),
                  child: SizedBox(
                    height: 300,
                    child: values.length < 2
                        ? Center(child: Text(context.tr('not_enough_history')))
                        : LineChart(
                            LineChartData(
                              minY: _minY(values),
                              maxY: _maxY(values),
                              gridData: FlGridData(
                                drawVerticalLine: false,
                                horizontalInterval: _interval,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.7),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineTouchData: const LineTouchData(enabled: true),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  curveSmoothness: 0.28,
                                  color: _metricColor,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: _metricColor.withValues(alpha: 0.12),
                                  ),
                                  spots: List.generate(
                                    values.length,
                                    (index) =>
                                        FlSpot(index.toDouble(), values[index]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _StatCard(
                      label: context.tr('average'),
                      value: _format(average),
                      icon: Icons.horizontal_rule_rounded,
                    ),
                    _StatCard(
                      label: context.tr('minimum'),
                      value: _format(minimum),
                      icon: Icons.south_east_rounded,
                    ),
                    _StatCard(
                      label: context.tr('maximum'),
                      value: _format(maximum),
                      icon: Icons.north_east_rounded,
                    ),
                  ];
                  return constraints.maxWidth >= 680
                      ? Row(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              Expanded(child: cards[i]),
                              if (i < cards.length - 1)
                                const SizedBox(width: 10),
                            ],
                          ],
                        )
                      : Column(
                          children: [
                            for (final card in cards) ...[
                              card,
                              const SizedBox(height: 9),
                            ],
                          ],
                        );
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: phytoGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_graph, color: phytoGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('trend_summary'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(context.tr((hardwareMode
                                        ? !hardwareAttention
                                        : analysis == null ||
                                            analysis.level ==
                                                InsightLevel.healthy)
                                ? 'trend_healthy'
                                : 'trend_attention')),
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
      },
    );
  }

  double _valueFor(SensorReading reading) => switch (metric) {
        _Metric.health => reading.healthScore,
        _Metric.soil => reading.soilMoisture,
        _Metric.temperature => reading.temperature,
        _Metric.humidity => reading.humidity,
        _Metric.plantSignal => reading.plantSignal,
      };

  bool _metricAvailable(SensorReading reading) => switch (metric) {
        _Metric.health => reading.edgeAnalysisAvailable,
        _Metric.soil => reading.soilMoistureAvailable,
        _Metric.temperature => reading.temperatureAvailable,
        _Metric.humidity => reading.humidityAvailable,
        _Metric.plantSignal => reading.plantSignalAvailable,
      };

  List<SensorReading> _downsample(
    List<SensorReading> readings,
    int maximum,
  ) {
    if (readings.length <= maximum) return readings;
    final step = readings.length / maximum;
    return List.generate(
      maximum,
      (index) => readings[(index * step).floor()],
    );
  }

  Color get _metricColor => switch (metric) {
        _Metric.health => phytoGreen,
        _Metric.soil => const Color(0xFF2F85C8),
        _Metric.temperature => phytoTerracotta,
        _Metric.humidity => const Color(0xFF6D78CE),
        _Metric.plantSignal => const Color(0xFF7A5CC7),
      };

  String _format(double value) =>
      '${value.toStringAsFixed(metric == _Metric.temperature ? 1 : 0)}${metric == _Metric.temperature ? '°' : '%'}';

  double _minY(List<double> values) {
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min - (metric == _Metric.temperature ? 4 : 10))
        .clamp(0, 100)
        .toDouble();
  }

  double _maxY(List<double> values) {
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max + (metric == _Metric.temperature ? 4 : 10))
        .clamp(10, 110)
        .toDouble();
  }

  double get _interval => metric == _Metric.temperature ? 5 : 20;
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
