import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';

class DataSourceCard extends StatelessWidget {
  const DataSourceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.settings, scope.sensorManager]),
      builder: (context, _) {
        final live = scope.sensorManager.source == SensorDataSource.esp32;
        final connected = scope.sensorManager.connected;
        final realtimeBio = live &&
            scope.sensors.current?.bioSource.toLowerCase() == 'realtime';
        final accent = live
            ? const Color(0xFF4E9DDB)
            : Theme.of(context).colorScheme.primary;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showSourcePicker(context),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      live ? Icons.memory_rounded : Icons.science_outlined,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          live
                              ? context.tr('esp32_live')
                              : context.tr('simulation_mode'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          live
                              ? (connected
                                  ? context.tr('live_data_connected')
                                  : context.tr('live_data_waiting'))
                              : context.tr('simulation_active_scenario', {
                                  'value': context.tr(
                                    'scenario_${scope.sensorManager.scenarioId}',
                                  ),
                                }),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (realtimeBio) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Real Time Signal',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      context
                          .tr(live ? 'source_live_badge' : 'source_demo_badge'),
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSourcePicker(BuildContext context) async {
    final scope = AppScope.of(context);
    final selected = await showModalBottomSheet<SensorDataSource>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.86,
        child: Scrollbar(
          child: ListView(
            primary: true,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            children: [
              Text(
                context.tr('choose_data_source'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('data_source_separation_note'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              _SourceOption(
                icon: Icons.science_outlined,
                title: context.tr('simulation_mode'),
                body: context.tr('simulation_description'),
                selected:
                    scope.sensorManager.source == SensorDataSource.simulation,
                onTap: () => Navigator.pop(
                  sheetContext,
                  SensorDataSource.simulation,
                ),
              ),
              const SizedBox(height: 10),
              _SourceOption(
                icon: Icons.memory_rounded,
                title: context.tr('esp32_live'),
                body: context.tr('esp32_description'),
                selected: scope.sensorManager.source == SensorDataSource.esp32,
                onTap: () => Navigator.pop(
                  sheetContext,
                  SensorDataSource.esp32,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    if (selected == scope.sensorManager.source) return;
    await HapticFeedback.mediumImpact();
    final sourceId =
        selected == SensorDataSource.esp32 ? 'esp32' : 'simulation';
    await scope.settings.setDataSource(sourceId);
    scope.alerts.clear();
    scope.sensorManager.configure(
      source: selected,
      endpoint: scope.settings.value.esp32Endpoint,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(
          selected == SensorDataSource.esp32
              ? 'live_workspace_enabled'
              : 'demo_workspace_enabled',
        )),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        color: selected
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.4)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(body),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color:
                      selected ? Theme.of(context).colorScheme.primary : null,
                ),
              ],
            ),
          ),
        ),
      );
}
