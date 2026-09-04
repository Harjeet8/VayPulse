import 'dart:convert';

import 'package:http/http.dart' as http;

class Esp32ConfigClient {
  final String baseUrl;
  final http.Client _httpClient;

  Esp32ConfigClient(String baseUrl, {http.Client? httpClient})
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
        _httpClient = httpClient ?? http.Client();

  Future<Esp32ConfigSnapshot> getConfig() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/api/config'),
      headers: const {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw Exception('ESP32 config unavailable (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid ESP32 config');
    final root = Map<String, dynamic>.from(decoded);
    final json = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final cropList = json['availableCrops'] ?? json['supportedCrops'];
    final crops = cropList is List
        ? cropList.map((e) => '$e').toList()
        : const <String>[];
    return Esp32ConfigSnapshot(
      crop: '${json['crop'] ?? 'Universal'}',
      growthStage: '${json['growthStage'] ?? 'Vegetative'}',
      availableCrops: crops,
    );
  }

  Future<CropSyncResult> setCrop(String crop) async {
    final response = await _post('/api/config/crop', {'crop': crop});
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    final confirmed = '${data['crop'] ?? ''}';
    if (response['ok'] != true || !_same(crop, confirmed)) {
      throw const FormatException('ESP32 did not confirm crop change');
    }
    final refreshed = await getConfig();
    if (!_same(crop, refreshed.crop)) {
      throw const FormatException('ESP32 crop confirmation did not persist');
    }
    return CropSyncResult(
      crop: refreshed.crop,
      baselineReset: data['baselineReset'] == true,
    );
  }

  Future<String> setGrowthStage(String stage) async {
    final response = await _post('/api/config/stage', {'stage': stage});
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    final confirmed = '${data['growthStage'] ?? data['stage'] ?? ''}';
    if (response['ok'] != true || !_same(stage, confirmed)) {
      throw const FormatException('ESP32 did not confirm growth-stage change');
    }
    final refreshed = await getConfig();
    if (!_same(stage, refreshed.growthStage)) {
      throw const FormatException(
        'ESP32 growth-stage confirmation did not persist',
      );
    }
    return refreshed.growthStage;
  }

  static bool _same(String expected, String actual) =>
      expected.trim().toLowerCase() == actual.trim().toLowerCase();

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpClient
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
