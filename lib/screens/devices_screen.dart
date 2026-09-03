import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/sensor_node.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/data_source_card.dart';
import '../widgets/page_frame.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('devices_title'))),
        body: PageFrame(
          children: [
            const DataSourceCard(),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      sensors.source == SensorDataSource.simulation
                          ? Icons.science_outlined
                          : Icons.memory_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr(
                          sensors.source == SensorDataSource.simulation
                              ? 'devices_demo_note'
                              : 'devices_live_note',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final node in sensors.nodes) ...[
              _NodeCard(node: node),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('device_diagnostics'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    _DiagnosticRow(
                      label: context.tr('diagnostic_provider'),
                      value: context.tr(
                        sensors.source == SensorDataSource.simulation
                            ? 'simulation_mode'
                            : 'esp32_live',
                      ),
                      healthy: true,
                    ),
                    _DiagnosticRow(
                      label: context.tr('diagnostic_connection'),
                      value: context.tr(
                        sensors.connected ? 'online' : 'offline',
                      ),
                      healthy: sensors.connected,
                    ),
                    _DiagnosticRow(
                      label: context.tr('diagnostic_data_quality'),
                      value: context.tr(
                        sensors.current == null ? 'waiting' : 'good',
                      ),
                      healthy: sensors.current != null,
                    ),
                    if (sensors.source == SensorDataSource.esp32) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: sensors.retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(context.tr('reconnect')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
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
                      child: const Icon(Icons.hub_outlined, color: phytoGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('hardware_ready'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Text(context.tr('hardware_ready_body')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final SensorNode node;

  const _NodeCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    final selected = sensors.selectedNodeId == node.id;
    final reading = sensors.latestReadings[node.id];
    final statusColor = node.isOnline ? phytoLeaf : phytoTerracotta;
    return Card(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.35)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          sensors.selectNode(node.id);
          _showNode(context, node);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(Icons.sensors_rounded, color: statusColor),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            node.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          node.isOnline
                              ? context.tr('online')
                              : context.tr('offline'),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      node.zoneId.isEmpty
                          ? node.id
                          : '${node.zoneId} • ${node.id}',
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _NodeMeta(
                          icon: Icons.battery_5_bar_rounded,
                          text: '${node.batteryPercent}%',
                        ),
                        _NodeMeta(
                          icon: Icons.network_cell_rounded,
                          text: '${node.signalPercent}%',
                        ),
                        if (reading != null)
                          _NodeMeta(
                            icon: Icons.eco_outlined,
                            text: '${reading.healthScore.round()}%',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  void _showNode(BuildContext context, SensorNode node) {
    final reading = AppScope.of(context).sensors.latestReadings[node.id];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  node.zoneId.isEmpty ? node.id : '${node.zoneId} • ${node.id}',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: context.tr('battery'),
                  value: '${node.batteryPercent}%',
                ),
                _DetailRow(
                  label: context.tr('signal'),
                  value: '${node.signalPercent}%',
                ),
                if (reading != null) ...[
                  _DetailRow(
                    label: context.tr('soil_moisture'),
                    value: '${reading.soilMoisture.toStringAsFixed(0)}%',
                  ),
                  _DetailRow(
                    label: context.tr('temperature'),
                    value: '${reading.temperature.toStringAsFixed(1)}°C',
                  ),
                  _DetailRow(
                    label: context.tr('humidity'),
                    value: '${reading.humidity.toStringAsFixed(0)}%',
                  ),
                  _DetailRow(
                    label: context.tr('light'),
                    value: '${reading.light.toStringAsFixed(0)}%',
                  ),
                  _DetailRow(
                    label: context.tr('plant_signal'),
                    value: '${reading.plantSignal.toStringAsFixed(0)}%',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final bool healthy;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.healthy,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(
          healthy ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: healthy ? phytoLeaf : phytoAmber,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _NodeMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NodeMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}
