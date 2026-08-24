import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';

class Esp32Client {
  final String baseUrl;

  Esp32Client(String baseUrl)
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  Future<Esp32Snapshot> getSnapshot() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/data'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('ESP32 returned HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid ESP32 JSON');
    final payload = Map<String, dynamic>.from(decoded);
    final readingPayload = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : payload;
    const requiredFields = [
      'soilMoisture',
      'temperature',
      'humidity',
      'light',
    ];
    if (requiredFields.any((field) => !readingPayload.containsKey(field))) {
      throw const FormatException('ESP32 payload is missing sensor fields');
    }
    return Esp32Snapshot(
      reading: SensorReading.fromJson(readingPayload),
      batteryPercent: _asInt(payload['batteryPercent'], 100),
      signalPercent: _asInt(payload['signalPercent'], 80),
      firmwareVersion: '${payload['firmwareVersion'] ?? 'unknown'}',
    );
  }

  Future<bool> ping() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
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

  const Esp32Snapshot({
    required this.reading,
    required this.batteryPercent,
    required this.signalPercent,
    required this.firmwareVersion,
  });
}
