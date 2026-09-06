import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';
import 'package:phytosense_ai/services/esp32_client.dart';
import 'package:phytosense_ai/services/esp32_config_client.dart';

void main() {
  test('hardware payload preserves ESP32 crop and edge decision', () async {
    final client = Esp32Client(
      'http://192.168.4.1',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/sensors');
        return http.Response(
          jsonEncode({
            'data': {
              'nodeId': 'node-rice-a1',
              'crop': 'Rice',
              'growthStage': 'Tillering',
              'healthScore': 61,
              'stressScore': 39,
              'healthStatus': 'RECOVERING',
              'analysisConfidence': 83,
              'reliability': {'mode': 'RECOVERING'},
              'systemStatus': 'RECOVERY_ACTIVE',
              'recoveryStatus': 'STABILIZING',
              'rootCause': {'label': 'ROOT_ZONE_LOW_OXYGEN', 'confidence': 87},
              'farmerAction': 'Inspect drainage before irrigating.',
              'rankedRootCauses': [
                {'label': 'ROOT_ZONE_LOW_OXYGEN'},
                {'label': 'EXCESS_MOISTURE'},
              ],
              'bioticState': 'POSSIBLE_BIOTIC_STRESS',
              'cameraRecommended': true,
              'cameraReason': 'POSSIBLE_BIOTIC_STRESS',
              'readings': {
                'air': {
                  'temperatureC': 28.2,
                  'humidityPercent': 76,
                  'valid': true,
                },
                'soil': {
                  'moisturePercent': 83,
                  'temperatureC': 27.1,
                  'valid': true,
                },
                'light': {'lux': 22000, 'valid': true},
                'leaf': {'wetnessPercent': 72, 'valid': true},
                'bioelectric': {
                  'source': 'realtime',
                  'amplifierOutputMv': 4095,
                  'stabilityPercent': 20,
                  'valid': false,
                  'status': 'CHECK_CONTACT',
                },
              },
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );

    final reading = (await client.getSnapshot()).reading;

    expect(reading.nodeId, 'node-rice-a1');
    expect(reading.crop, 'Rice');
    expect(reading.growthStage, 'Tillering');
    expect(reading.healthScore, 61);
    expect(reading.stressScore, 39);
    expect(reading.edgeAnalysisAvailable, isTrue);
    expect(reading.reliabilityMode, 'RECOVERING');
    expect(reading.primaryRootCause, 'ROOT_ZONE_LOW_OXYGEN');
    expect(reading.farmerAction, 'Inspect drainage before irrigating.');
    expect(reading.rootCauseConfidence, 87);
    expect(reading.cameraRecommended, isTrue);
    expect(reading.plantSignalAvailable, isFalse);
    expect(reading.sensorStates['plantSignal'], 'CHECK_CONTACT');
    expect(reading.bioSourceLabel, 'Real Time Signal');
  });

  test('real and realtime bio source labels remain distinct', () async {
    final live = await _readingForSource('real');
    final realtime = await _readingForSource('realtime');

    expect(live.bioSourceLabel, 'Live Readings');
    expect(realtime.bioSourceLabel, 'Real Time Signal');
  });

  test(
    'ESP32 baseline telemetry stays authoritative when soil is VERIFY',
    () async {
      final client = Esp32Client(
        'http://192.168.4.1',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': {
                'nodeId': 'node-baseline',
                'healthScore': 94,
                'temperature': 28,
                'soilStatus': 'VERIFY',
                'bioelectric': {
                  'baselineReady': false,
                  'baselineLearningPaused': false,
                  'baselinePauseReason': 'NONE',
                  'baselineSamples': 18,
                  'baselineTargetSamples': 60,
                },
              },
            }),
            200,
          ),
        ),
      );

      final reading = (await client.getSnapshot()).reading;

      expect(reading.bioBaselineReady, isFalse);
      expect(reading.bioBaselineLearningPaused, isFalse);
      expect(reading.bioBaselinePauseReason, 'NONE');
      expect(reading.bioBaselineSamples, 18);
      expect(reading.bioBaselineTargetSamples, 60);
    },
  );

  test('new baseline pause fields remain nullable for older firmware', () async {
    final reading = await _readingForSource('real');

    expect(reading.bioBaselineLearningPaused, isNull);
    expect(reading.bioBaselinePauseReason, isNull);
    expect(reading.bioBaselineTargetSamples, isNull);
  });

  test('crop sync requires POST and persisted GET confirmation', () async {
    var posted = false;
    final client = Esp32ConfigClient(
      'http://192.168.4.1',
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          posted = true;
          expect(request.url.path, '/api/config/crop');
          expect(jsonDecode(request.body), {'crop': 'Rice'});
          return http.Response(
            jsonEncode({'ok': true, 'crop': 'Rice', 'baselineReset': true}),
            200,
          );
        }
        expect(request.url.path, '/api/config');
        return http.Response(
          jsonEncode({
            'crop': 'Rice',
            'growthStage': 'Tillering',
            'availableCrops': ['Universal', 'Rice'],
          }),
          200,
        );
      }),
    );

    final result = await client.setCrop('Rice');

    expect(posted, isTrue);
    expect(result.crop, 'Rice');
    expect(result.baselineReset, isTrue);
  });

  test('crop sync rejects a mismatched node confirmation', () async {
    final client = Esp32ConfigClient(
      'http://192.168.4.1',
      httpClient: MockClient(
        (_) async =>
            http.Response(jsonEncode({'ok': true, 'crop': 'Tomato'}), 200),
      ),
    );

    await expectLater(client.setCrop('Rice'), throwsA(isA<FormatException>()));
  });
}

Future<SensorReading> _readingForSource(String source) async {
  final client = Esp32Client(
    'http://192.168.4.1',
    httpClient: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'nodeId': 'node-1',
          'healthScore': 90,
          'bioSource': source,
          'temperature': 25,
        }),
        200,
      ),
    ),
  );
  return (await client.getSnapshot()).reading;
}
