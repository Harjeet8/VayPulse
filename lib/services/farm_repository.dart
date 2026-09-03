import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/farm.dart';

class FarmRepository extends ChangeNotifier {
  final List<Farm> farms = [];
  String selectedFarmId = 'green-valley';
  String selectedFieldId = 'rice-field';
  String selectedZoneId = 'rice-north';
  bool isLoaded = false;
  String? errorMessage;

  Farm get selectedFarm => farms.firstWhere(
        (farm) => farm.id == selectedFarmId,
        orElse: () => farms.first,
      );

  FarmField get selectedField => selectedFarm.fields.firstWhere(
        (field) => field.id == selectedFieldId,
        orElse: () => selectedFarm.fields.first,
      );

  FarmZone get selectedZone => selectedField.zones.firstWhere(
        (zone) => zone.id == selectedZoneId,
        orElse: () => selectedField.zones.first,
      );

  List<FarmZone> get allZones => [
        for (final farm in farms)
          for (final field in farm.fields) ...field.zones,
      ];

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('farmHierarchy');
      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        farms.addAll(
          decoded.map(
            (item) => Farm.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      }
      if (farms.isEmpty) farms.add(_demoFarm);
      selectedFarmId =
          preferences.getString('selectedFarmId') ?? farms.first.id;
      selectedFieldId = preferences.getString('selectedFieldId') ??
          farms.first.fields.first.id;
      selectedZoneId = preferences.getString('selectedZoneId') ??
          farms.first.fields.first.zones.first.id;
    } catch (error) {
      farms
        ..clear()
        ..add(_demoFarm);
      errorMessage = '$error';
    } finally {
      isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> selectZone({
    required String farmId,
    required String fieldId,
    required String zoneId,
  }) async {
    selectedFarmId = farmId;
    selectedFieldId = fieldId;
    selectedZoneId = zoneId;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('selectedFarmId', farmId);
    await preferences.setString('selectedFieldId', fieldId);
    await preferences.setString('selectedZoneId', zoneId);
    notifyListeners();
  }

  Future<void> updateFieldCrop({
    required String farmId,
    required String fieldId,
    required String crop,
  }) async {
    final farmIndex = farms.indexWhere((farm) => farm.id == farmId);
    if (farmIndex < 0) return;
    final farm = farms[farmIndex];
    final fields = List<FarmField>.from(farm.fields);
    final fieldIndex = fields.indexWhere((field) => field.id == fieldId);
    if (fieldIndex < 0) return;
    fields[fieldIndex] = fields[fieldIndex].copyWith(crop: crop);
    farms[farmIndex] = farm.copyWith(fields: fields);
    await _saveHierarchy();
    notifyListeners();
  }

  Future<void> updateZoneStage({
    required String farmId,
    required String fieldId,
    required String zoneId,
    required String cropStage,
  }) async {
    final farmIndex = farms.indexWhere((farm) => farm.id == farmId);
    if (farmIndex < 0) return;
    final farm = farms[farmIndex];
    final fields = List<FarmField>.from(farm.fields);
    final fieldIndex = fields.indexWhere((field) => field.id == fieldId);
    if (fieldIndex < 0) return;
    final zones = List<FarmZone>.from(fields[fieldIndex].zones);
    final zoneIndex = zones.indexWhere((zone) => zone.id == zoneId);
    if (zoneIndex < 0) return;
    zones[zoneIndex] = zones[zoneIndex].copyWith(cropStage: cropStage);
    fields[fieldIndex] = fields[fieldIndex].copyWith(zones: zones);
    farms[farmIndex] = farm.copyWith(fields: fields);
    await _saveHierarchy();
    notifyListeners();
  }

  Future<void> _saveHierarchy() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'farmHierarchy',
      jsonEncode(farms.map((farm) => farm.toJson()).toList()),
    );
  }

  FarmZone? zoneById(String zoneId) {
    for (final zone in allZones) {
      if (zone.id == zoneId) return zone;
    }
    return null;
  }

  FarmField? fieldForZone(String zoneId) {
    for (final farm in farms) {
      for (final field in farm.fields) {
        if (field.zones.any((zone) => zone.id == zoneId)) return field;
      }
    }
    return null;
  }

  static const _demoFarm = Farm(
    id: 'green-valley',
    name: 'Green Valley Farm',
    location: 'Coimbatore, Tamil Nadu',
    fields: [
      FarmField(
        id: 'rice-field',
        name: 'North Field',
        crop: 'Rice',
        areaAcres: 3.2,
        zones: [
          FarmZone(
            id: 'rice-north',
            name: 'Rice Zone A',
            cropStage: 'Tillering',
            nodeIds: ['node-rice-a1', 'node-rice-a2'],
          ),
          FarmZone(
            id: 'rice-south',
            name: 'Rice Zone B',
            cropStage: 'Tillering',
            nodeIds: ['node-rice-b1'],
          ),
        ],
      ),
      FarmField(
        id: 'tomato-field',
        name: 'East Field',
        crop: 'Tomato',
        areaAcres: 1.8,
        zones: [
          FarmZone(
            id: 'tomato-east',
            name: 'Tomato Zone A',
            cropStage: 'Flowering',
            nodeIds: ['node-tomato-a1', 'node-tomato-a2'],
          ),
          FarmZone(
            id: 'tomato-west',
            name: 'Tomato Zone B',
            cropStage: 'Fruit set',
            nodeIds: ['node-tomato-b1'],
          ),
        ],
      ),
    ],
  );
}
