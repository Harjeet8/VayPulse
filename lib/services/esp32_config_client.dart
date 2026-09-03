import 'dart:convert';

import 'package:http/http.dart' as http;

class Esp32ConfigClient {
  final String baseUrl;

  Esp32ConfigClient(String baseUrl)
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  Future<Esp32ConfigSnapshot> getConfig() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/config'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw Exception('ESP32 config unavailable (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid ESP32 config');
    final json = Map<String, dynamic>.from(decoded);
    final crops = (json['availableCrops'] is List)
        ? (json['availableCrops'] as List).map((e) => '$e').toList()
        : const <String>[];
    return Esp32ConfigSnapshot(
      crop: '${json['crop'] ?? 'Universal'}',
      growthStage: '${json['growthStage'] ?? 'Vegetative'}',
      availableCrops: crops,
    );
  }

  Future<CropSyncResult> setCrop(String crop) async {
    final response = await _post('/api/config/crop', {'crop': crop});
    final confirmed = '${response['crop'] ?? ''}';
    if (response['ok'] != true || confirmed.isEmpty) {
      throw const FormatException('ESP32 did not confirm crop change');
    }
    return CropSyncResult(
      crop: confirmed,
      baselineReset: response['baselineReset'] == true,
    );
  }

  Future<String> setGrowthStage(String stage) async {
    final response = await _post('/api/config/stage', {'stage': stage});
    final confirmed = '${response['growthStage'] ?? ''}';
    if (response['ok'] != true || confirmed.isEmpty) {
      throw const FormatException('ESP32 did not confirm growth-stage change');
    }
    return confirmed;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw Exception('ESP32 rejected configuration (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid ESP32 response');
    return Map<String, dynamic>.from(decoded);
  }
}

class Esp32ConfigSnapshot {
  final String crop;
  final String growthStage;
  final List<String> availableCrops;

  const Esp32ConfigSnapshot({
    required this.crop,
    required this.growthStage,
    required this.availableCrops,
  });
}

class CropSyncResult {
  final String crop;
  final bool baselineReset;

  const CropSyncResult({required this.crop, required this.baselineReset});
}
