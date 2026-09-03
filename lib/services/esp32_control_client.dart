import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/esp32_configuration.dart';

class Esp32ControlClient {
  final String baseUrl;

  Esp32ControlClient(String baseUrl)
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  Future<Esp32Config?> getConfig() async {
    final json = await _getJson('/api/config');
    return json == null ? null : Esp32Config.fromJson(json);
  }

  Future<Esp32Config?> setCrop(String cropId) async {
    final requested = _normalizeCrop(cropId);
    final response = await _postJson(
      '/api/config/crop',
      {'crop': _firmwareCropName(requested)},
    );
    if (response == null || response['ok'] == false) return null;

    final responseCrop = _normalizeCrop(
      '${response['crop'] ?? response['cropName'] ?? ''}',
    );
    final baselineReset = response['baselineReset'] == true;
    final confirmed = await getConfig();
    if (confirmed == null) return null;

    final confirmedId = _normalizeCrop(confirmed.cropId);
    final confirmedName = _normalizeCrop(confirmed.cropName);
    final responseMatches = responseCrop.isEmpty || responseCrop == requested;
    if (!responseMatches ||
        (confirmedId != requested && confirmedName != requested)) {
      return null;
    }
    return confirmed.copyWith(baselineReset: baselineReset);
  }

  Future<Esp32Config?> setStage(String stageId) async {
    final response = await _postJson('/api/config/stage', {'stage': stageId});
    if (response == null || response['ok'] == false) return null;
    return getConfig();
  }

  Future<Esp32Config?> resetBaseline() async {
    final response = await _postJson('/api/config/baseline/reset', const {});
    if (response == null || response['ok'] == false) return null;
    final confirmed = await getConfig();
    return confirmed?.copyWith(baselineReset: true);
  }

  Future<Esp32Diagnostics?> getDiagnostics() async {
    final json = await _getJson('/api/diagnostics');
    return json == null ? null : Esp32Diagnostics.fromJson(json);
  }

  Future<Map<String, dynamic>?> _getJson(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.body.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return null;
    }
  }

  static String _normalizeCrop(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized == 'brinjal' || normalized == 'aubergine') {
      return 'eggplant';
    }
    if (normalized == 'ladyfinger' || normalized == 'bhindi') return 'okra';
    return normalized;
  }

  static String _firmwareCropName(String cropId) {
    if (cropId.isEmpty) return 'Universal';
    return '${cropId[0].toUpperCase()}${cropId.substring(1)}';
  }
}
