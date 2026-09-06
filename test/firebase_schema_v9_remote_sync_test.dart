import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phytosense_ai/services/esp32_client.dart';

void main() {
  test('Verdant accepts authoritative flat Firebase schema v9', () {
    final payload = <String, dynamic>{
      'schemaVersion': 9,
      'deviceId': 'PS-NODE-01',
      'firmwareVersion': 'PhytoSense AI Edge Intelligence',
      'timestamp': '2026-09-05T22:47:41',
      'healthIndex': 95.6,
      'confidence': 76.9,
      'status': 'WATCH',
      'plantCondition': 'EXCELLENT',
      'mainFinding': 'Verify soil probe placement',
      'farmerAction': 'INSERT PROBE IN SOIL / CHECK CALIBRATION',
      'because': 'The ESP32 excluded the unverified soil channel.',
      'airTemperature': 32.71,
      'humidity': 64.4,
      'light': 11.0,
      'soilMoisture': 0.0,
      'soilRaw': 3272,
      'soilStatus': 'VERIFY',
      'rootTemperature': 32.25,
      'ds18b20Status': 'OK',
      'leafWetness': 0.0,
      'leafRaw': 4095,
      'diseaseRisk': 4.2,
      'bioSource': 'real',
      'bioVoltage': 1791.0,
      'bioSignalQuality': 58.0,
      'bioContactState': 'PLAUSIBLE',
      'bioContactConfidence': 90.8,
      'bioContactPlausibleForPlantUse': true,
      'bioAffectsHealth': true,
      'ahtStatus': 'OK',
      'bh1750Status': 'OK',
      'leafStatus': 'OK',
      'bioStatus': 'OK',
      'internetConnected': true,
      'cloudConnected': true,
    };

    final response = http.Response(
      jsonEncode(payload),
      200,
      headers: const {'content-type': 'application/json'},
    );
    final snapshot = Esp32Client('http://192.168.4.1').decodeSnapshot(
      response,
      endpoint: 'firebase:phytosense/nodes/phytosense_01/live',
    );

    expect(snapshot.edgeIntelligence.schemaVersion, 9);
    expect(snapshot.edgeIntelligence.firmwareCompatible, isTrue);
    expect(snapshot.edgeIntelligence.healthScore, closeTo(95.6, 0.01));
    expect(snapshot.edgeIntelligence.overallConfidence, closeTo(76.9, 0.01));
    expect(
      snapshot.edgeIntelligence.rootCause.primary,
      'Verify soil probe placement',
    );
    expect(snapshot.reading.temperature, closeTo(32.71, 0.01));
    expect(snapshot.reading.soilTemperature, closeTo(32.25, 0.01));
    expect(snapshot.reading.lightLux, closeTo(11.0, 0.01));
    expect(snapshot.reading.soilMoistureAvailable, isFalse);
    expect(snapshot.reading.plantVoltageMv, closeTo(1791.0, 0.01));
  });
}
