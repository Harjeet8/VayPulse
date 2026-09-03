import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';

/// Compact, clearly labelled farm demonstration controls.
///
/// Only the farm facts needed at a glance are shown here. Simulated values
/// remain isolated inside the simulation provider and can never be presented
/// as ESP32 readings.
class SimulationCommandDeck extends StatelessWidget {
  const SimulationCommandDeck({super.key});

  static const _meta = <String, _ScenarioMeta>{
    'healthy': _ScenarioMeta(
      'Healthy crop',
      'Soil, climate and plant response are in a safe range.',
      Icons.eco_rounded,
    ),
    'baseline_learning': _ScenarioMeta(
      'Learning plant signal',
      'PhytoSense is learning the plant’s normal electrical pattern.',
      Icons.memory_rounded,
    ),
    'atmospheric_drying': _ScenarioMeta(
      'Dry air',
      'The air is pulling water quickly while the soil remains moist.',
      Icons.air_rounded,
    ),
    'dry': _ScenarioMeta(
      'Dry root zone',
      'Soil moisture has fallen below the preferred range.',
      Icons.water_drop_outlined,
    ),
    'overwatered': _ScenarioMeta(
      'Soil too wet',
      'The root zone is staying wetter than the crop needs.',
      Icons.water_rounded,
    ),
    'heat_stress': _ScenarioMeta(
      'Heat stress',
      'High temperature is increasing plant water loss.',
      Icons.device_thermostat_rounded,
    ),
    'bio_response': _ScenarioMeta(
      'Plant signal change',
      'The plant signal changed before one clear cause was found.',
      Icons.electric_bolt_rounded,
    ),
    'recovery': _ScenarioMeta(
      'Plant recovering',
      'Conditions improved and the plant response is settling.',
      Icons.restore_rounded,
    ),
    'biotic_risk': _ScenarioMeta(
      'Plant needs inspection',
      'The pattern suggests checking for pests or visible damage.',
      Icons.biotech_outlined,
    ),
    'low_light': _ScenarioMeta(
      'Low daylight',
      'Available daylight is below the expected crop range.',
      Icons.wb_twilight_rounded,
    ),
    'critical': _ScenarioMeta(
      'Urgent crop stress',
      'Heat, dry soil and plant response all need attention.',
      Icons.warning_amber_rounded,
    ),
    'sensor_fault': _ScenarioMeta(
      'Sensor needs attention',
      'An unreliable channel is excluded from the result.',
      Icons.sensors_off_rounded,
    ),
    'offline': _ScenarioMeta(
      'Simulation offline',
      'No old reading is shown as current data.',
      Icons.wifi_off_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.sensorManager,
      builder: (context, _) {
        final sensors = scope.sensorManager;
        if (sensors.source != SensorDataSource.simulation) {
          return const SizedBox.shrink();
        }

        final selected = sensors.scenarioId;
        final meta = _meta[selected] ?? _fallbackMeta(selected);
        final profile = _farmProfile(sensors.selectedNodeId);
        const demo = Color(0xFF176B4D);
        final scheme = Theme.of(context).colorScheme;

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => _showConditionPicker(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: demo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.agriculture_rounded, color: demo),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: demo.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'SIMULATED',
                                    style: TextStyle(
                                      color: Color(0xFF176B4D),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    child: Container(
                      key: ValueKey(selected),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: demo.withValues(alpha: 0.065),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: demo.withValues(alpha: 0.16)),
                      ),
                      child: Row(
                        children: [
                          Icon(meta.icon, color: demo, size: 21),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              meta.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CHANGE',
                            style: TextStyle(
                              color: demo,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: demo),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showConditionPicker(BuildContext context) async {
    final scope = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: AnimatedBuilder(
            animation: scope.sensorManager,
            builder: (context, _) {
              final selected = scope.sensorManager.scenarioId;
              final ids = scope.sensorManager.scenarioIds;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Simulation condition',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text('Choose the field situation to demonstrate.'),
                            ],
                          ),
                        ),
                        if (selected != 'healthy')
                          TextButton(
                            onPressed: () => _selectScenario(
                              sheetContext,
                              'healthy',
                              close: false,
                            ),
                            child: const Text('RESET'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                      itemCount: ids.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 3),
                      itemBuilder: (context, index) {
                        final id = ids[index];
                        final item = _meta[id] ?? _fallbackMeta(id);
                        final active = id == selected;
                        return ListTile(
                          selected: active,
                          selectedTileColor: const Color(0xFF176B4D)
                              .withValues(alpha: 0.09),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: Icon(
                            item.icon,
                            color: active ? const Color(0xFF176B4D) : null,
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: active
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF176B4D),
                                )
                              : null,
                          onTap: () => _selectScenario(sheetContext, id),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _selectScenario(
    BuildContext context,
    String scenario, {
    bool close = true,
  }) {
    final scope = AppScope.of(context);
    HapticFeedback.selectionClick();
    scope.sensorManager.setScenario(scenario);
    unawaited(scope.settings.setScenario(scenario));
    if (close) Navigator.pop(context);
  }

  static _FarmProfile _farmProfile(String nodeId) {
    if (nodeId.startsWith('node-rice')) {
      return const _FarmProfile(
        'Simulation · Rice',
        'North zone  •  Clay loam  •  Channel irrigation',
      );
    }
    final zone = nodeId.endsWith('a2')
        ? 'Centre zone'
        : nodeId.endsWith('b1')
            ? 'West zone'
            : 'East zone';
    return _FarmProfile(
      'Simulation · Tomato',
      '$zone  •  Red loam  •  Drip irrigation',
    );
  }

  static _ScenarioMeta _fallbackMeta(String id) => _ScenarioMeta(
        id.replaceAll('_', ' '),
        'Clearly labelled simulated values.',
        Icons.science_outlined,
      );
}

class _FarmProfile {
  final String name;
  final String details;

  const _FarmProfile(this.name, this.details);
}

class _ScenarioMeta {
  final String title;
  final String description;
  final IconData icon;

  const _ScenarioMeta(this.title, this.description, this.icon);
}
