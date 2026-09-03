import 'package:flutter/material.dart';

import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/live_icon.dart';
import '../widgets/page_frame.dart';
import 'farmer_analysis_screen.dart';

class PracticeFarmHomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAlerts;

  const PracticeFarmHomeScreen({super.key, this.onOpenAlerts});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final nodes = sensors.nodes;
        final readings = sensors.latestReadings;
        final summary = _summary(readings.values);
        final online = nodes.where((node) => node.isOnline).length;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/branding/phytosense_icon.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                const SizedBox(width: 9),
                const Flexible(child: Text('PhytoSense AI')),
              ],
            ),
            actions: [
              Badge(
                isLabelVisible: scope.alerts.unreadCount > 0,
                label: Text('${scope.alerts.unreadCount}'),
                child: IconButton(
                  tooltip: 'Alerts',
                  onPressed: onOpenAlerts,
                  icon: const LiveIcon(
                    icon: Icons.notifications_none_rounded,
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
                _DeploymentHero(
                  online: online,
                  total: nodes.length,
                  normal: summary.$1,
                  watch: summary.$2,
                  critical: summary.$3,
                ),
                const SizedBox(height: 12),
                _ScenarioPicker(
                  current: sensors.scenarioId,
                  ids: sensors.scenarioIds,
                  onChanged: sensors.setScenario,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    LiveIcon(
                      icon: Icons.hub_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      kind: LiveIconKind.analysis,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Farm sensing network',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(
                      '${nodes.length} zones',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Each card is an independent PhytoSense AI node with its own live Practice Farm reading.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                if (sensors.connectionStatus != SensorConnectionStatus.ready)
                  _OfflineCard(onRetry: sensors.retry)
                else if (readings.isEmpty)
                  const _LoadingCard()
                else
                  ...nodes.map(
                    (node) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ZoneCard(
                        node: node,
                        reading: readings[node.id],
                        selected: sensors.selectedNodeId == node.id,
                        onTap: () {
                          sensors.selectNode(node.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FarmerAnalysisScreen(),
                            ),
                          );
                        },
                      ),
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

class _DeploymentHero extends StatelessWidget {
  final int online;
  final int total;
  final int normal;
  final int watch;
  final int critical;

  const _DeploymentHero({
    required this.online,
    required this.total,
    required this.normal,
    required this.watch,
    required this.critical,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.72),
            scheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LiveIcon(
                  icon: Icons.agriculture_rounded,
                  color: scheme.primary,
                  size: 27,
                  kind: LiveIconKind.plant,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRACTICE FARM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Trichy–Thanjavur deployment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _OnlinePill(online: online, total: total),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CountTile(
                  label: 'Normal',
                  value: normal,
                  icon: Icons.check_circle_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountTile(
                  label: 'Watch',
                  value: watch,
                  icon: Icons.visibility_rounded,
                  color: scheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountTile(
                  label: 'Critical',
                  value: critical,
                  icon: Icons.warning_rounded,
                  color: scheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  final int online;
  final int total;

  const _OnlinePill({required this.online, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = online == total
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveIcon(
            icon: Icons.sensors_rounded,
            color: color,
            size: 14,
            kind: LiveIconKind.connectivity,
            active: online > 0,
          ),
          const SizedBox(width: 5),
          Text(
            '$online/$total',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _CountTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            LiveIcon(icon: icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(
              '$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}

class _ScenarioPicker extends StatelessWidget {
  final String current;
  final List<String> ids;
  final ValueChanged<String> onChanged;

  const _ScenarioPicker({
    required this.current,
    required this.ids,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: DropdownButtonFormField<String>(
            key: ValueKey(current),
            initialValue: current,
            decoration: InputDecoration(
              labelText: 'Farm demonstration condition',
              prefixIcon: LiveIcon(
                icon: _scenarioIcon(current),
                kind: liveIconKindFor(_scenarioIcon(current)),
              ),
              border: InputBorder.none,
            ),
            items: ids
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(_scenarioLabel(id)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      );
}

class _ZoneCard extends StatelessWidget {
  final SensorNode node;
  final SensorReading? reading;
  final bool selected;
  final VoidCallback onTap;

  const _ZoneCard({
    required this.node,
    required this.reading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final severity = _severity(reading);
    final color = severity == 2
        ? scheme.error
        : severity == 1
            ? scheme.tertiary
            : scheme.primary;
    final label = severity == 2
        ? 'CRITICAL'
        : severity == 1
            ? 'WATCH'
            : 'NORMAL';
    final parts = node.name.split(' · ');
    final place = parts.first;
    final crop = parts.length > 1 ? parts.last : 'Crop';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: LiveIcon(
                      icon: severity == 2
                          ? Icons.electric_bolt_rounded
                          : Icons.eco_rounded,
                      color: color,
                      kind: severity == 2
                          ? LiveIconKind.bioelectric
                          : LiveIconKind.plant,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$crop  •  ${_irrigation(node.id)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              if (reading != null) ...[
                const SizedBox(height: 11),
                Row(
                  children: [
                    _Metric(
                      icon: Icons.water_drop_outlined,
                      text: '${reading!.soilMoisture.round()}%',
                      kind: LiveIconKind.environment,
                    ),
                    _Metric(
                      icon: Icons.thermostat_outlined,
                      text: '${reading!.temperature.toStringAsFixed(1)}°C',
                      kind: LiveIconKind.environment,
                    ),
                    _Metric(
                      icon: Icons.electric_bolt_rounded,
                      text: '${reading!.plantSignal.round()}%',
                      kind: LiveIconKind.bioelectric,
                    ),
                    _Metric(
                      icon: Icons.favorite_rounded,
                      text: '${reading!.healthScore.round()}',
                      kind: LiveIconKind.plant,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const LiveIcon(icon: Icons.schedule_rounded, size: 14),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Updated ${_age(reading!.timestamp)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    if (selected)
                      Text(
                        'CURRENT ZONE',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String text;
  final LiveIconKind kind;

  const _Metric({
    required this.icon,
    required this.text,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LiveIcon(icon: icon, size: 13, kind: kind),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _OfflineCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineCard({required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: LiveIcon(
            icon: Icons.wifi_off_rounded,
            color: Theme.of(context).colorScheme.error,
            kind: LiveIconKind.connectivity,
          ),
          title: const Text(
            'Practice Farm network offline',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: const Text('No old value is presented as current data.'),
          trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Card(
        child: ListTile(
          leading: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          title: Text('Starting Practice Farm nodes…'),
        ),
      );
}

(int, int, int) _summary(Iterable<SensorReading> readings) {
  var normal = 0;
  var watch = 0;
  var critical = 0;
  for (final reading in readings) {
    final severity = _severity(reading);
    if (severity == 2) {
      critical++;
    } else if (severity == 1) {
      watch++;
    } else {
      normal++;
    }
  }
  return (normal, watch, critical);
}

int _severity(SensorReading? reading) {
  if (reading == null) return 1;
  final state = reading.healthStatus.toUpperCase();
  if (reading.healthScore < 50 || state.contains('CRITICAL')) return 2;
  if (reading.healthScore < 75 ||
      state.contains('WATCH') ||
      state.contains('STRESS')) {
    return 1;
  }
  return 0;
}

String _scenarioLabel(String id) => switch (id) {
      'healthy' => 'Balanced farm',
      'baseline_learning' => 'Learning plant baseline',
      'atmospheric_drying' => 'Dry-air demand',
      'dry' => 'Dry root zone',
      'overwatered' => 'Excess root-zone moisture',
      'heat_stress' => 'Heat stress',
      'bio_response' => 'Plant electrical response',
      'recovery' => 'Recovery',
      'biotic_risk' => 'Needs visual inspection',
      'low_light' => 'Low daylight',
      'critical' => 'Critical combined stress',
      'offline' => 'Farm network offline',
      'sensor_fault' => 'Sensor fault',
      _ => id.replaceAll('_', ' '),
    };

IconData _scenarioIcon(String id) => switch (id) {
      'healthy' => Icons.eco_rounded,
      'baseline_learning' => Icons.memory_rounded,
      'atmospheric_drying' => Icons.air_rounded,
      'dry' => Icons.water_drop_outlined,
      'overwatered' => Icons.water_rounded,
      'heat_stress' => Icons.thermostat_rounded,
      'bio_response' => Icons.electric_bolt_rounded,
      'recovery' => Icons.restore_rounded,
      'biotic_risk' => Icons.biotech_outlined,
      'low_light' => Icons.wb_twilight_rounded,
      'critical' => Icons.warning_amber_rounded,
      'offline' => Icons.wifi_off_rounded,
      'sensor_fault' => Icons.sensors_off_rounded,
      _ => Icons.science_outlined,
    };

String _irrigation(String nodeId) {
  if (nodeId.contains('rice')) return 'Channel irrigation';
  if (nodeId.contains('groundnut') || nodeId.contains('maize')) {
    return 'Sprinkler irrigation';
  }
  return 'Drip irrigation';
}

String _age(DateTime value) {
  final seconds = DateTime.now().difference(value).inSeconds.abs();
  if (seconds < 5) return 'now';
  if (seconds < 60) return '${seconds}s ago';
  return '${seconds ~/ 60}m ago';
}
