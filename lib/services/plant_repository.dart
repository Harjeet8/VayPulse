import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';

class PlantRepository extends ChangeNotifier {
  final List<Plant> plants = [
    Plant(
      id: 'demo-monstera',
      name: 'Monstera',
      species: 'Monstera deliciosa',
      location: 'Living room',
    ),
  ];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('plants');
    if (raw == null) return;
    final data = jsonDecode(raw) as List;
    plants
      ..clear()
      ..addAll(data.map((e) => Plant.fromJson(Map<String, dynamic>.from(e))));
    notifyListeners();
  }

  Future<void> add(Plant plant) async {
    plants.add(plant);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    plants.removeWhere((p) => p.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      'plants',
      jsonEncode(plants.map((p) => p.toJson()).toList()),
    );
  }
}
