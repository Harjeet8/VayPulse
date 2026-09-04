import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phytosense_ai/services/esp32_client.dart';

Future<Esp32Snapshot> _snapshot(Map<String, dynamic> payload) {
  final client = Esp32Client(
    'http://192.168.4.1',
    httpClient: MockClient(
      (_) async => http.Response(jsonEncode(payload), 200),
    ),
  );
  return client.getSnapshot();
}

Map<String, dynamic> _basePayload({
  String sensorIntegrity = 'FULL',
  String recovery = 'NONE',
  String runtime = 'GOOD',
  String anomaly = 'CLEAR',
  bool prediction = false,
}) =>
    <String, dynamic>{
      'nodeId': 'PHYTO-NODE-001',
      'healthScore': 74,
      'stressScore': 26,
      'healthStatus': 'WATCH',
      'analysisConfidence': 88,
      'primaryRootCause': 'WATER_STRESS',
      'farmerAction': 'Check the root zone before watering.',
      'readings': <String, dynamic>{
        'air': <String, dynamic>{
          'temperatureC': 29.2,
          'humidityPercent': 61,
          'valid': true,
        },
        'soil': <String, dynamic>{
          'moisturePercent': 43,
          'temperatureC': 28.1,
          'valid': true,
        },
        'light': <String, dynamic>{'lux': 1200, 'valid': true},
        'leaf': <String, dynamic>{'wetnessPercent': 4, 'valid': true},
        'bioelectric': <String, dynamic>{
          'amplifierOutputMv': 1650,
          'stabilityPercent': 72,
          'signalQualityPercent': 81,
          'source': 'real',
          'state': 'TRANSIENT',
          'valid': true,
        },
      },
      'sensorIntegrity': <String, dynamic>{
        'state': sensorIntegrity,
        'primaryIssue': sensorIntegrity == 'FULL' ? '' : 'SOIL_PROBE',
        'primaryAction':
            sensorIntegrity == 'FULL' ? '' : 'Check soil probe connection',
        'channels': <String, dynamic>{
          'soilMoisture': <String, dynamic>{'state': sensorIntegrity},
          'bioelectric': <String, dynamic>{'state': 'GOOD'},
        },
      },
      'recovery': <String, dynamic>{
        'state': recovery,
        'progressPct': recovery == 'NONE' ? null : 62,
        'confidence': recovery == 'NONE' ? null : 86,
        'verified': recovery == 'RECOVERY_VERIFIED',
        'farmerResult':
            recovery == 'RECOVERY_VERIFIED' ? 'Plant response recovered.' : '',
      },
      'runtimeHealth': <String, dynamic>{
        'state': runtime,
        'freeHeap': 118000,
        'minFreeHeap': 102000,
        'lastLoopGapMs': 8,
        'maxLoopGapMs': 22,
        'lastSensorCycleMs': 31,
        'maxSensorCycleMs': 48,
        'oledI2cSkipTotal': 1,
        'issue': runtime == 'GOOD' ? '' : 'Runtime timing needs attention',
      },
      'anomaly': <String, dynamic>{
        'state': anomaly,
        'score': anomaly == 'CLEAR' ? 4 : 72,
        'confidence': 90,
        'affectedChannel': anomaly == 'CLEAR' ? '' : 'soilMoisture',
        'explanation':
            anomaly == 'CLEAR' ? '' : 'Soil channel needs verification.',
      },
      'prediction': <String, dynamic>{
        'available': prediction,
        'target': 'WATER_STRESS',
        'confidence': prediction ? 84 : 0,
        'minutesToWarning': prediction ? 18 : null,
        'message': prediction
            ? 'Drying trend may reach the warning range in ~18 min if the current trend continues.'
            : '',
        'direction': 'WORSENING',
      },
    };

void main() {
  test('old firmware JSON remains backward compatible', () async {
    final snapshot = await _snapshot(<String, dynamic>{
      'nodeId': 'OLD-NODE',
      'temperature': 28,
      'humidity': 60,
      'soilMoisture': 55,
      'light': 65,
      'healthScore': 83,
      'healthStatus': 'GOOD',
      'analysisConfidence': 79,
      'primaryRootCause': 'NONE',
      'farmerAction': 'Continue monitoring.',
    });

    final reading = snapshot.reading;
    expect(reading.healthScore, 83);
    expect(reading.plantModelStatus, isEmpty);
    expect(reading.predictionAvailable, isFalse);
    expect(reading.recentEvents, isEmpty);
    expect(reading.runtimeHealthState, isEmpty);
  });

  test('full new firmware JSON preserves ESP32 edge intelligence', () async {
    final payload = _basePayload(
      sensorIntegrity: 'VERIFY',
      recovery: 'RECOVERY_VERIFIED',
      runtime: 'WATCH',
      anomaly: 'VERIFY',
      prediction: true,
    )..addAll(<String, dynamic>{
        'healthScore': 42,
        'analysisConfidence': 91,
        'plantModel': <String, dynamic>{
          'status': 'RESTORED',
          'ready': true,
          'confidence': 93,
          'learnedSamples': 428,
          'ageSec': 9000,
          'persisted': true,
          'bioBaselineMv': 1642.4,
          'typicalBioVariationMv': 18.2,
          'normalNoiseMv': 4.1,
          'normalSoilRatePctPerHour': -1.8,
        },
        'temporalReasoning': <String, dynamic>{
          'state': 'SUPPORTED',
          'confidence': 87,
          'primarySequence': 'Drying increased → plant response increased',
          'environmentToBioLagSec': 38,
          'actionToRecoveryLagSec': 95,
          'explanation':
              'Soil moisture fell before the plant electrical response increased.',
        },
        'plausibility': <String, dynamic>{
          'state': 'VERIFY',
          'confidence': 92,
          'primaryIssue': 'SOIL_PROBE',
          'recommendation': 'Check soil probe connection',
        },
        'recentEvents': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'evt-2',
            'timestamp': '2026-09-04T10:00:05Z',
            'type': 'RECOVERY_VERIFIED',
            'message': 'Recovery verified',
          },
          <String, dynamic>{
            'id': 'evt-2',
            'timestamp': '2026-09-04T10:00:05Z',
            'type': 'RECOVERY_VERIFIED',
            'message': 'Recovery verified duplicate',
          },
          <String, dynamic>{
            'id': 'evt-1',
            'timestamp': '2026-09-04T09:58:00Z',
            'type': 'STRESS_DETECTED',
            'message': 'Water stress detected',
          },
        ],
      });

    final reading = (await _snapshot(payload)).reading;
    expect(reading.healthScore, 42);
    expect(reading.plantModelReady, isTrue);
    expect(reading.plantModelStatus, 'READY');
    expect(reading.plantModelPersisted, isTrue);
    expect(reading.plantModelLearnedSamples, 428);
    expect(reading.environmentToBioLagSec, 38);
    expect(reading.predictionAvailable, isTrue);
    expect(reading.predictionMinutesToWarning, 18);
    expect(reading.anomalyState, 'VERIFY');
    expect(reading.sensorIntegrityState, 'VERIFY');
    expect(reading.bioState, 'TRANSIENT');
    expect(reading.recoveryVerified, isTrue);
    expect(reading.runtimeHealthState, 'WATCH');
    expect(reading.recentEvents, hasLength(2));
  });

  test('restored plant model is ready and retained without local invention',
      () async {
    final payload = _basePayload()
      ..['plantModel'] = <String, dynamic>{
        'status': 'RESTORED',
        'confidence': 92,
        'learnedSamples': 320,
        'bioBaselineMv': 1640.5,
      };

    final reading = (await _snapshot(payload)).reading;
    expect(reading.plantModelReady, isTrue);
    expect(reading.plantModelStatus, 'READY');
    expect(reading.plantModelPersisted, isTrue);
    expect(reading.plantModelBioBaselineMv, 1640.5);
  });

  test('plant model learning and missing optional objects are safe', () async {
    final payload = _basePayload()
      ..['plantModel'] = <String, dynamic>{
        'status': 'LEARNING',
        'ready': false,
        'learnedSamples': 14,
      };

    final reading = (await _snapshot(payload)).reading;
    expect(reading.plantModelReady, isFalse);
    expect(reading.plantModelStatus, 'LEARNING');
    expect(reading.plantModelLearnedSamples, 14);
    expect(reading.temporalState, isEmpty);
    expect(reading.plausibilityState, isEmpty);
  });

  test('prediction available and unavailable states remain distinct', () async {
    expect(
      (await _snapshot(_basePayload(prediction: true)))
          .reading
          .predictionAvailable,
      isTrue,
    );
    expect(
      (await _snapshot(_basePayload(prediction: false)))
          .reading
          .predictionAvailable,
      isFalse,
    );
  });

  test('anomaly CLEAR and VERIFY are preserved', () async {
    expect(
      (await _snapshot(_basePayload(anomaly: 'CLEAR'))).reading.anomalyState,
      'CLEAR',
    );
    expect(
      (await _snapshot(_basePayload(anomaly: 'VERIFY'))).reading.anomalyState,
      'VERIFY',
    );
  });

  test('sensor integrity FULL VERIFY and DEGRADED are preserved', () async {
    for (final state in <String>['FULL', 'VERIFY', 'DEGRADED']) {
      final reading =
          (await _snapshot(_basePayload(sensorIntegrity: state))).reading;
      expect(reading.sensorIntegrityState, state);
    }
  });

  test('bio TRANSIENT remains a firmware-reported state', () async {
    final reading = (await _snapshot(_basePayload())).reading;
    expect(reading.bioState, 'TRANSIENT');
    expect(reading.plantSignalAvailable, isTrue);
  });

  test('recovery NONE IMPROVING RECOVERING and VERIFIED are preserved',
      () async {
    for (final state in <String>[
      'NONE',
      'CONDITIONS_IMPROVING',
      'RECOVERING',
      'RECOVERY_VERIFIED',
    ]) {
      final reading = (await _snapshot(_basePayload(recovery: state))).reading;
      expect(reading.recoveryStatus, state);
      expect(reading.recoveryVerified, state == 'RECOVERY_VERIFIED');
    }
  });

  test('runtime GOOD WATCH and DEGRADED are preserved', () async {
    for (final state in <String>['GOOD', 'WATCH', 'DEGRADED']) {
      final reading = (await _snapshot(_basePayload(runtime: state))).reading;
      expect(reading.runtimeHealthState, state);
    }
  });
}
