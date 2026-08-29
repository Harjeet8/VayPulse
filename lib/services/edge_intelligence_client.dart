import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/edge_intelligence.dart';

/// Reads the ESP32's own reasoning payload without making Flutter a second
/// decision engine. Older firmware remains supported because every advanced
/// field is optional and capabilities are inferred from the returned JSON.
class EdgeIntelligenceClient {
  final String baseUrl;

  EdgeIntelligenceClient(String baseUrl)
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  static const _paths = <String>[
    '/api/sensors',
    '/api/v1/sensors',
    '/api/data',
    '/data',
    '/sensors',
  ];

  Future<EdgeIntelligence?> getIntelligence() async {
    for (final path in _paths) {
      final response = await _tryGet(path);
      if (response == null) continue;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) continue;
        final root = Map<String, dynamic>.from(decoded);
        final data = root['data'] is Map
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;
        final firmware = _text(data['firmware']) ??
            _text(data['firmwareVersion']) ??
            _text(root['firmware']) ??
            _text(root['firmwareVersion']) ??
            'unknown';
        return EdgeIntelligence.fromPayload(
          root: root,
          data: data,
          firmwareVersion: firmware,
        );
      } catch (_) {
        // A compatibility path may expose a non-JSON page. Continue to the
        // next alias instead of breaking the live dashboard.
      }
    }
    return null;
  }

  Future<http.Response?> _tryGet(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200 ? response : null;
    } catch (_) {
      return null;
    }
  }

  static String? _text(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }
}
