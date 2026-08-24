import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/crop_catalog.dart';
import '../models/farm.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../widgets/health_ring.dart';
import '../widgets/page_frame.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.farms, scope.sensors]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('fields_and_zones'))),
        body: scope.farms.farms.isEmpty
            ? Center(child: Text(context.tr('no_farms')))
            : PageFrame(
                children: [
                  Text(
                    context.tr('farm_structure'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final farm in scope.farms.farms)
                    _FarmCard(
                      farm: farm,
                      readings: scope.sensors.latestReadings,
                      activeNodeIds:
                          scope.sensors.nodes.map((node) => node.id).toSet(),
                    ),
                ],
              ),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final Map<String, SensorReading> readings;
  final Set<String> activeNodeIds;

  const _FarmCard({
    required this.farm,
    required this.readings,
    required this.activeNodeIds,
  });

  @override
  Widget build(BuildContext context) {
    final zones = farm.fields.expand((field) => field.zones).toList();
    final nodes = zones
        .expand((zone) => zone.nodeIds)
        .where(activeNodeIds.contains)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF164F3A), Color(0xFF287A59)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.agriculture, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farm.location,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _CountChip(
                            '${farm.fields.length} ${context.tr('fields')}'),
                        _CountChip('${zones.length} ${context.tr('zones')}'),
                        _CountChip('$nodes ${context.tr('sensor_nodes')}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final field in farm.fields) ...[
          _FieldCard(
            farm: farm,
            field: field,
            readings: readings,
            activeNodeIds: activeNodeIds,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String text;

  const _CountChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _FieldCard extends StatelessWidget {
  final Farm farm;
  final FarmField field;
  final Map<String, SensorReading> readings;
  final Set<String> activeNodeIds;

  const _FieldCard({
    required this.farm,
    required this.field,
    required this.readings,
    required this.activeNodeIds,
  });

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.grass_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            field.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${_crop(context, field.crop)} • ${context.tr('area_acres', {
                  'value': field.areaAcres
                })}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            const Divider(),
            for (final zone in field.zones)
              _ZoneTile(
                farm: farm,
                field: field,
                zone: zone,
                readings: readings,
                activeNodeIds: activeNodeIds,
              ),
          ],
        ),
      );
}

class _ZoneTile extends StatelessWidget {
  final Farm farm;
  final FarmField field;
  final FarmZone zone;
  final Map<String, SensorReading> readings;
  final Set<String> activeNodeIds;

  const _ZoneTile({
    required this.farm,
    required this.field,
    required this.zone,
    required this.readings,
    required this.activeNodeIds,
  });

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final score = _score;
    final selected = scope.farms.selectedZoneId == zone.id;
    final deployed = zone.nodeIds.any(activeNodeIds.contains);
    final hasReading = zone.nodeIds.any(readings.containsKey);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: deployed ? () => _select(context) : null,
          onLongPress: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (hasReading)
                  HealthRing(
                    score: score,
                    size: 72,
                    label: context.tr('metric_health'),
                  )
                else
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: (deployed ? phytoAmber : Colors.grey)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      deployed
                          ? Icons.hourglass_top_rounded
                          : Icons.add_link_rounded,
                      color: deployed ? phytoAmber : Colors.grey,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${context.tr('crop_stage')}: ${_stage(context, zone.cropStage)}',
                      ),
                      const SizedBox(height: 3),
                      Text(
                        deployed
                            ? '${zone.nodeIds.where(activeNodeIds.contains).length} ${context.tr('sensor_nodes')}'
                            : context.tr('not_monitored'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Chip(
                    avatar: const Icon(Icons.check_rounded, size: 17),
                    label: Text(context.tr('selected')),
                  )
                else if (deployed)
                  IconButton(
                    tooltip: context.tr('select_zone'),
                    onPressed: () => _select(context),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double get _score {
    final scores = zone.nodeIds
        .map((id) => readings[id]?.healthScore)
        .whereType<double>()
        .toList();
    return scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
  }

  void _select(BuildContext context) {
    final scope = AppScope.of(context);
    scope.farms.selectZone(
      farmId: farm.id,
      fieldId: field.id,
      zoneId: zone.id,
    );
    if (zone.nodeIds.isNotEmpty) scope.sensors.selectNode(zone.nodeIds.first);
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('zone_details'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.eco_outlined),
              title: Text(zone.name),
              subtitle: Text(
                '${_crop(context, field.crop)} • ${_stage(context, zone.cropStage)}',
              ),
              trailing: Text(
                zone.nodeIds.any(readings.containsKey)
                    ? '${_score.round()}%'
                    : zone.nodeIds.any(activeNodeIds.contains)
                        ? context.tr('waiting')
                        : context.tr('not_monitored'),
              ),
            ),
            for (final nodeId in zone.nodeIds)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sensors_outlined),
                title: Text(nodeId),
                trailing: Text(
                  !activeNodeIds.contains(nodeId)
                      ? context.tr('not_monitored')
                      : readings[nodeId] == null
                          ? context.tr('waiting')
                          : '${readings[nodeId]!.healthScore.round()}%',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _crop(BuildContext context, String crop) =>
    context.tr(CropCatalog.profileFor(crop).localizationKey);

String _stage(BuildContext context, String stage) => switch (stage) {
      'Seedling' => context.tr('stage_seedling'),
      'Vegetative' => context.tr('stage_vegetative'),
      'Tillering' => context.tr('stage_tillering'),
      'Flowering' => context.tr('stage_flowering'),
      'Fruit set' => context.tr('stage_fruit_set'),
      'Maturity' => context.tr('stage_maturity'),
      _ => stage,
    };
