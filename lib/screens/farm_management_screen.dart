import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/crop_catalog.dart';
import '../models/farm.dart';
import '../services/app_scope.dart';
import '../widgets/page_frame.dart';

class FarmManagementScreen extends StatelessWidget {
  const FarmManagementScreen({super.key});

  static final crops = CropCatalog.supported
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
              onChanged: (crop) {
                if (crop == null) return;
                AppScope.of(context).farms.updateFieldCrop(
                      farmId: farm.id,
                      fieldId: field.id,
                      crop: crop,
                    );
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
                  onChanged: (stage) {
                    if (stage == null) return;
                    AppScope.of(context).farms.updateZoneStage(
                          farmId: farm.id,
                          fieldId: field.id,
                          zoneId: zone.id,
                          cropStage: stage,
                        );
                  },
                ),
              ),
          ],
        ),
      );
}

String _cropName(BuildContext context, String crop) =>
    context.tr(CropCatalog.profileFor(crop).localizationKey);

String _stageName(BuildContext context, String stage) => switch (stage) {
      'Seedling' => context.tr('stage_seedling'),
      'Vegetative' => context.tr('stage_vegetative'),
      'Tillering' => context.tr('stage_tillering'),
      'Flowering' => context.tr('stage_flowering'),
      'Fruit set' => context.tr('stage_fruit_set'),
      'Maturity' => context.tr('stage_maturity'),
      _ => stage,
    };
