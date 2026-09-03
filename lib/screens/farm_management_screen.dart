import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/crop_catalog.dart';
import '../models/farm.dart';
import '../services/app_scope.dart';
import '../services/esp32_config_client.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';

class FarmManagementScreen extends StatelessWidget {
  const FarmManagementScreen({super.key});

  static final crops = CropCatalog.supported
      .where((profile) => CropCatalog.firmwareSupports(profile.name))
      .map((profile) => profile.name)
      .toList(growable: false);
  static const stages = [
    'Seedling',
    'Vegetative',
    'Tillering',
    'Flowering',
    'Fruit set',
    'Maturity',
  ];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.farms,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('crop_management'))),
        body: PageFrame(
          children: [
            Card(
              color: phytoGreen.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.edit_note_rounded, color: phytoGreen),
                    const SizedBox(width: 10),
                    Expanded(child: Text(context.tr('crop_management_body'))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final farm in scope.farms.farms) ...[
              Text(
                farm.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(farm.location),
              const SizedBox(height: 10),
              for (final field in farm.fields) ...[
                _ManagedField(farm: farm, field: field),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ManagedField extends StatelessWidget {
  final Farm farm;
  final FarmField field;

  const _ManagedField({required this.farm, required this.field});

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
          title: Text(field.name,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(
            '${field.crop} • ${context.tr('area_acres', {
                  'value': field.areaAcres
                })}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(),
            DropdownButtonFormField<String>(
              initialValue: FarmManagementScreen.crops.contains(field.crop)
                  ? field.crop
                  : FarmManagementScreen.crops.first,
              decoration: InputDecoration(
                labelText: context.tr('field_crop'),
                prefixIcon: const Icon(Icons.eco_outlined),
              ),
              items: FarmManagementScreen.crops
                  .map((crop) => DropdownMenuItem(
                        value: crop,
                        child: Text(_cropName(context, crop)),
                      ))
                  .toList(),
              onChanged: (crop) async {
                if (crop == null) return;
                final scope = AppScope.of(context);
                final canonicalCrop = CropCatalog.normalize(crop);

                await scope.farms.updateFieldCrop(
                  farmId: farm.id,
                  fieldId: field.id,
                  crop: canonicalCrop,
                );

                if (scope.sensorManager.source != SensorDataSource.esp32) {
                  return;
                }

                try {
                  final result = await Esp32ConfigClient(
                    scope.sensorManager.hardwareEndpoint,
                  ).setCrop(canonicalCrop);
                  scope.sensors.retry();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result.crop} profile synchronized with the PhytoSense node${result.baselineReset ? ' • bio baseline restarted' : ''}',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Crop saved in the app, but the PhytoSense node could not confirm the change. Reconnect to PhytoSense_AI and retry.',
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('growth_stages'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            for (final zone in field.zones)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: DropdownButtonFormField<String>(
                  initialValue:
                      FarmManagementScreen.stages.contains(zone.cropStage)
                          ? zone.cropStage
                          : FarmManagementScreen.stages.first,
                  decoration: InputDecoration(
                    labelText: zone.name,
                    prefixIcon: const Icon(Icons.timeline_rounded),
                  ),
                  items: FarmManagementScreen.stages
                      .map((stage) => DropdownMenuItem(
                            value: stage,
                            child: Text(_stageName(context, stage)),
                          ))
                      .toList(),
                  onChanged: (stage) async {
                    if (stage == null) return;
                    final scope = AppScope.of(context);
                    await scope.farms.updateZoneStage(
                      farmId: farm.id,
                      fieldId: field.id,
                      zoneId: zone.id,
                      cropStage: stage,
                    );

                    if (scope.sensorManager.source != SensorDataSource.esp32) {
                      return;
                    }

                    try {
                      await Esp32ConfigClient(
                        scope.sensorManager.hardwareEndpoint,
                      ).setGrowthStage(stage);
                      scope.sensors.retry();
                    } catch (_) {
                      // Local farm editing remains usable even when the node is
                      // temporarily disconnected. A later crop/stage edit can
                      // synchronize again once PhytoSense_AI is reachable.
                    }
                  },
                ),
              ),
          ],
        ),
      );
}

String _cropName(BuildContext context, String crop) {
  final profile = CropCatalog.profileFor(crop);
  final translated = context.tr(profile.localizationKey);
  return translated == profile.localizationKey ? profile.name : translated;
}

String _stageName(BuildContext context, String stage) => switch (stage) {
      'Seedling' => context.tr('stage_seedling'),
      'Vegetative' => context.tr('stage_vegetative'),
      'Tillering' => context.tr('stage_tillering'),
      'Flowering' => context.tr('stage_flowering'),
      'Fruit set' => context.tr('stage_fruit_set'),
      'Maturity' => context.tr('stage_maturity'),
      _ => stage,
    };
