import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_reading.dart';

class Esp32Client {
  final String baseUrl;

  Esp32Client(String baseUrl)
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  /// Reads either the full VayPulse hardware contract (`/api/data`) or the
  /// lightweight bring-up endpoint (`/sensors`) used by the first AHT10 test.
  Future<Esp32Snapshot> getSnapshot() async {
    final full = await _tryGet('/api/data');
    if (full != null) {
      return _decodeSnapshot(full, compactEndpoint: false);
    }

    final compact = await _tryGet('/sensors');
    if (compact != null) {
      return _decodeSnapshot(compact, compactEndpoint: true);
    }

    throw Exception('ESP32 did not respond on /api/data or /sensors');
  }

  Future<bool> ping() async {
    try {
      final status = await _tryGet('/api/status');
      if (status != null) return true;
      return await _tryGet('/sensors') != null;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response?> _tryGet(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200 ? response : null;
    } catch (_) {
      return null;
    }
  }

  Esp32Snapshot _decodeSnapshot(
    http.Response response, {
    required bool compactEndpoint,
  }) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid ESP32 JSON');
    }

    final payload = Map<String, dynamic>.from(decoded);
    final readingPayload = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : Map<String, dynamic>.from(payload);

    if (compactEndpoint) {
      // Current bring-up firmware has only the AHT10 connected. Do not invent
      // live values for sensors that are not attached yet. SensorReading keeps
      // neutral internal placeholders but marks those channels unavailable so
      // the live dashboard can display them as "not connected".
      if (!_hasNumber(readingPayload['temperature']) ||
          !_hasNumber(readingPayload['humidity'])) {
        throw const FormatException(
          'ESP32 /sensors payload is missing temperature or humidity',
        );
      }
      readingPayload.putIfAbsent('nodeId', () => payload['deviceId']);
      readingPayload.putIfAbsent(
        'timestamp',
        () => DateTime.now().toIso8601String(),
      );
    } else {
      const requiredFields = [
        'soilMoisture',
        'temperature',
        'humidity',
        'light',
      ];
      if (requiredFields.any(
        (field) => !readingPayload.containsKey(field),
      )) {
        throw const FormatException('ESP32 payload is missing sensor fields');
      }
    }

    return Esp32Snapshot(
      reading: SensorReading.fromJson(readingPayload),
      batteryPercent: _asInt(payload['batteryPercent'], 100),
      signalPercent: _asInt(payload['signalPercent'], 80),
      firmwareVersion:
          '${payload['firmwareVersion'] ?? (compactEndpoint ? 'bring-up' : 'unknown')}',
      compactEndpoint: compactEndpoint,
    );
  }

  static bool _hasNumber(dynamic value) {
    if (value is num) return value.isFinite;
    return double.tryParse('$value')?.isFinite ?? false;
  }

  static int _asInt(dynamic value, int fallback) =>
      (value is num ? value.toInt() : int.tryParse('$value') ?? fallback)
          .clamp(0, 100)
          .toInt();
}

class Esp32Snapshot {
  final SensorReading reading;
  final int batteryPercent;
  final int signalPercent;
  final String firmwareVersion;
  final bool compactEndpoint;

  const Esp32Snapshot({
    required this.reading,
    required this.batteryPercent,
    required this.signalPercent,
    required this.firmwareVersion,
    this.compactEndpoint = false,
  });
}
