import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phytosense_ai/services/esp32_client.dart';

Future<Esp32Snapshot> _snapshot(Map<String, dynamic> bio) {
  final payload = <String, dynamic>{
    'nodeId': 'PHYTO-NODE-001',
    'firmwareName': 'PhytoSense AI Edge Intelligence',
    'buildState': 'FROZEN_FINAL',
    'healthScore': 82,
    'stressScore': 18,
    'healthStatus': 'GOOD',
    'analysisConfidence': 91,
    'readings': <String, dynamic>{
      'air': <String, dynamic>{
        'temperatureC': 29,
        'humidityPercent': 61,
        'valid': true,
      },
      'soil': <String, dynamic>{
        'moisturePercent': 52,
        'temperatureC': 28,
        'valid': true,
      },
      'light': <String, dynamic>{'lux': 900, 'valid': true},
      'leaf': <String, dynamic>{'wetnessPercent': 3, 'valid': true},
      'bioelectric': <String, dynamic>{
        'amplifierOutputMv': 1650,
        'stabilityPercent': 100,
        'signalQualityPercent': 100,
        'source': 'real',
        'valid': true,
        ...bio,
      },
    },
  };

  final client = Esp32Client(
    'http://192.168.4.1',
    httpClient: MockClient(
      (_) async => http.Response(
        jsonEncode(payload),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
  return client.getSnapshot();
}

void main() {
  test('OPEN keeps electrical measurement but disables plant use', () async {
    final reading = (await _snapshot(<String, dynamic>{
      'contactState': 'OPEN',
      'contactConfidence': 0.98,
      'slowDriftMv': 0.4,
      'contactPlausibleForPlantUse': false,
      'affectsHealth': false,
      'openLatched': true,
      'reconnectVerifying': false,
      'reconnectVerifySec': 0,
    }))
        .reading;

    expect(reading.plantSignalAvailable, isTrue);
    expect(reading.bioElectricalMeasurementAvailable, isTrue);
    expect(reading.bioSignalQuality, 100);
    expect(reading.normalizedBioContactState, 'OPEN');
    expect(reading.bioContactConfidence, 0.98);
    expect(reading.bioSlowDriftMv, 0.4);
    expect(reading.bioOpenLatched, isTrue);
    expect(reading.bioPlantUseAllowed, isFalse);
    expect(reading.bioAffectsHealth, isFalse);
  });

  test('VERIFY preserves reconnect verification telemetry', () async {
    final reading = (await _snapshot(<String, dynamic>{
      'contactState': 'VERIFY',
      'contactConfidence': 74,
      'contactPlausibleForPlantUse': false,
      'affectsHealth': false,
      'openLatched': true,
      'reconnectVerifying': true,
      'reconnectVerifySec': 12,
    }))
        .reading;

    expect(reading.normalizedBioContactState, 'VERIFY');
    expect(reading.bioReconnectVerifying, isTrue);
    expect(reading.bioReconnectVerifySec, 12);
    expect(reading.bioPlantUseAllowed, isFalse);
  });

  test('PLAUSIBLE is the normal plant-use path', () async {
    final reading = (await _snapshot(<String, dynamic>{
      'contactState': 'PLAUSIBLE',
      'contactConfidence': 96,
      'slowDriftMv': 1.8,
      'contactPlausibleForPlantUse': true,
      'affectsHealth': true,
      'openLatched': false,
      'reconnectVerifying': false,
    }))
        .reading;

    expect(reading.bioSignalQuality, 100);
    expect(reading.bioPlantUseAllowed, isTrue);
    expect(reading.bioAffectsHealth, isTrue);
  });

  for (final state in <String>[
    'OPEN',
    'UNSTABLE',
    'STATIC',
    'SHORT_SUSPECTED',
    'VERIFY',
  ]) {
    test('$state is excluded from plant analysis despite clean signal',
        () async {
      final reading = (await _snapshot(<String, dynamic>{
        'contactState': state,
        'contactConfidence': 100,
        'contactPlausibleForPlantUse': false,
        'affectsHealth': false,
      }))
          .reading;

      expect(reading.bioElectricalMeasurementAvailable, isTrue);
      expect(reading.bioSignalQuality, 100);
      expect(reading.bioPlantUseAllowed, isFalse);
    });
  }

  test('older firmware without contact gate keeps compatibility', () async {
    final reading = (await _snapshot(const <String, dynamic>{})).reading;

    expect(reading.hasBioContactTelemetry, isFalse);
    expect(reading.plantSignalAvailable, isTrue);
    expect(reading.bioPlantUseAllowed, isTrue);
  });

  test('firmware identity and build state are preserved', () async {
    final reading = (await _snapshot(<String, dynamic>{
      'contactState': 'PLAUSIBLE',
      'contactPlausibleForPlantUse': true,
      'affectsHealth': true,
    }))
        .reading;

    expect(reading.firmwareName, 'PhytoSense AI Edge Intelligence');
    expect(reading.firmwareBuildState, 'FROZEN_FINAL');
  });

  test('Home uses existing single system warning for contact gate', () {
    final source =
        File('lib/screens/live_node_home_screen.dart').readAsStringSync();

    expect(source, contains('Electrodes open — check plant contact'));
    expect(source, contains('Electrode contact unstable'));
    expect(
      source,
      contains('Static/test input — excluded from plant analysis'),
    );
    expect(source, contains('Verifying electrode contact'));
    expect(source, contains('bioContactWarning(reading)'));
    expect(source, isNot(contains('class _ElectrodeContactCard')));
  });

  test('Engineering reliability shows contact and latch details only', () {
    final source =
        File('lib/screens/engineering_center_screen.dart').readAsStringSync();

    expect(source, contains("title: 'Signal & Sensor Reliability'"));
    expect(source, contains("'Electrical signal quality'"));
    expect(source, contains("'Electrode contact state'"));
    expect(source, contains("'Contact confidence'"));
    expect(source, contains("'Slow drift'"));
    expect(source, contains("'Plant-analysis use'"));
    expect(source, contains("'Open-contact latch active'"));
    expect(source, contains("'Reconnect verification'"));
    expect(source, contains("'Firmware'"));
    expect(source, contains("'Build state'"));
  });
}
