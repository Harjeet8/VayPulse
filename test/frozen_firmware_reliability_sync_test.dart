import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:phytosense_ai/models/edge_intelligence.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';
import 'package:phytosense_ai/services/health_analysis_engine.dart';

EdgeIntelligence _edge(Map<String, dynamic> additions) {
  return EdgeIntelligence.fromPayload(
    root: const <String, dynamic>{},
    data: <String, dynamic>{
      'schemaVersion': 8,
      'plantState': 'WATCH',
      'healthScore': 72,
      'healthConfidence': 91,
      'primaryFinding': 'Water stress',
      'primaryAction': 'Check the root zone before watering',
      ...additions,
    },
    firmwareVersion: 'PhytoSense AI v8.0 ULTRA FINAL',
  );
}

void main() {
  test('FULL sensor integrity and CLEAR plausibility parse cleanly', () {
    final edge = _edge(<String, dynamic>{
      'sensorIntegrity': <String, dynamic>{
        'state': 'FULL',
        'faultCount': 0,
        'verifyCount': 0,
        'channels': <String, dynamic>{
          'air': 'GOOD',
          'light': 'GOOD',
          'soilMoisture': 'GOOD',
          'rootTemperature': 'GOOD',
          'leafWetness': 'GOOD',
          'bioelectric': 'LEARNING',
        },
      },
      'plausibility': <String, dynamic>{
        'state': 'CLEAR',
        'issueCount': 0,
        'confidence': 96,
      },
      'buildState': 'FROZEN_FINAL',
    });

    expect(edge.sensorIntegrity.full, isTrue);
    expect(edge.sensorIntegrity.faultCount, 0);
    expect(edge.sensorIntegrity.channels['bioelectric'], 'LEARNING');
    expect(edge.plausibility.clear, isTrue);
    expect(edge.plausibility.confidence, 96);
    expect(edge.buildState, 'FROZEN_FINAL');
  });

  test('VERIFY merges integrity, plausibility and TRANSIENT bio safely', () {
    final edge = _edge(<String, dynamic>{
      'sensorIntegrity': <String, dynamic>{
        'state': 'VERIFY',
        'faultCount': 0,
        'verifyCount': 2,
        'primaryIssue': 'Bio contact is changing',
        'primaryAction': 'Check that both electrode pads are secure',
        'channels': <String, dynamic>{
          'air': <String, dynamic>{'state': 'GOOD'},
          'bioelectric': <String, dynamic>{'state': 'TRANSIENT'},
        },
      },
      'plausibility': <String, dynamic>{
        'state': 'VERIFY',
        'issueCount': 1,
        'confidence': 67,
        'primaryIssue': 'One channel changed faster than expected',
        'recommendation': 'Wait for one more sensor cycle',
      },
      'bioSource': 'real',
      'bioelectric': <String, dynamic>{
        'state': 'TRANSIENT',
        'signalQualityState': 'TRANSIENT',
        'includedInFusion': true,
      },
    });

    expect(edge.sensorIntegrity.verify, isTrue);
    expect(edge.sensorIntegrity.verifyCount, 2);
    expect(edge.sensorIntegrity.channels['bioelectric'], 'TRANSIENT');
    expect(edge.plausibility.verify, isTrue);
    expect(edge.plausibility.primaryIssue, contains('changed'));
    expect(edge.bioelectric.signalQualityState, 'TRANSIENT');
    expect(edge.bioelectric.excludedByFirmware, isFalse);
  });

  test('DEGRADED integrity keeps one authoritative issue and action', () {
    final edge = _edge(<String, dynamic>{
      'sensorIntegrity': <String, dynamic>{
        'state': 'DEGRADED',
        'faultCount': 2,
        'verifyCount': 1,
        'primaryIssue': 'Root temperature sensor is unavailable',
        'primaryAction': 'Check the probe connection',
        'channels': <String, dynamic>{
          'rootTemperature': 'UNAVAILABLE',
          'bioelectric': 'CHECK_CONTACT',
        },
      },
    });

    expect(edge.sensorIntegrity.degraded, isTrue);
    expect(edge.sensorIntegrity.faultCount, 2);
    expect(edge.sensorIntegrity.primaryIssue, contains('unavailable'));
    expect(edge.sensorIntegrity.primaryAction, contains('connection'));
  });

  test('RECOVERING exposes progress without inventing verification', () {
    final edge = _edge(<String, dynamic>{
      'recovery': <String, dynamic>{
        'state': 'RECOVERING',
        'confidence': 88,
        'progressPct': 64,
        'verificationSeconds': 180,
        'evidenceCount': 3,
        'environmentImproved': true,
        'soilImproved': true,
        'stressEvidenceDecreasing': true,
        'bioResponseDecreasing': false,
        'verified': false,
        'farmerResult': 'The plant response is moving in the right direction',
      },
    });

    expect(edge.recovery.active, isTrue);
    expect(edge.recovery.recovering, isTrue);
    expect(edge.recovery.visibleOnHome, isTrue);
    expect(edge.recovery.progressPct, 64);
    expect(edge.recovery.evidenceCount, 3);
    expect(edge.recovery.recoveryVerified, isFalse);
  });

  test('RECOVERY_VERIFIED is the only authoritative recovery confirmation', () {
    final edge = _edge(<String, dynamic>{
      'recovery': <String, dynamic>{
        'state': 'RECOVERY_VERIFIED',
        'confidence': 94,
        'progressPct': 100,
        'verificationSeconds': 420,
        'evidenceCount': 4,
        'environmentImproved': true,
        'soilImproved': true,
        'stressEvidenceDecreasing': true,
        'bioResponseDecreasing': true,
        'verified': true,
        'farmerResult': 'Recovery verified by the sensor node',
      },
    });

    expect(edge.recovery.active, isTrue);
    expect(edge.recovery.recoveryVerified, isTrue);
    expect(edge.recovery.progressPct, 100);
    expect(edge.recovery.farmerResult, contains('verified'));
  });

  test('runtime WATCH diagnostics parse without becoming plant stress', () {
    final edge = _edge(<String, dynamic>{
      'runtimeHealth': <String, dynamic>{
        'state': 'WATCH',
        'freeHeap': 148224,
        'minFreeHeap': 112640,
        'lastLoopGapMs': 17,
        'maxLoopGapMs': 89,
        'lastSensorCycleMs': 46,
        'maxSensorCycleMs': 132,
        'oledI2cSkipTotal': 3,
        'heapWarning': false,
        'timingWarning': true,
        'i2cWarning': false,
        'issue': 'One sensor cycle was slower than usual',
      },
    });

    expect(edge.runtimeHealth.normalizedState, 'WATCH');
    expect(edge.runtimeHealth.degraded, isFalse);
    expect(edge.runtimeHealth.freeHeap, 148224);
    expect(edge.runtimeHealth.maxSensorCycleMs, 132);
    expect(edge.plantState, 'WATCH');
    expect(edge.rootCause.primary, isNot(contains('sensor cycle')));
  });

  test('event timeline deduplicates by id and sorts newest first', () {
    final edge = _edge(<String, dynamic>{
      'recentEvents': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'soil-1',
          'timestamp': '2026-09-04T08:00:00Z',
          'uptimeMs': 1000,
          'severity': 'WARN',
          'type': 'SOIL_CRITICAL_DRY',
          'message': 'Soil entered critical dryness',
        },
        <String, dynamic>{
          'id': 'irrigation-1',
          'timestamp': '2026-09-04T08:01:00Z',
          'uptimeMs': 61000,
          'severity': 'INFO',
          'type': 'IRRIGATION_DETECTED',
          'message': 'Irrigation detected',
        },
        <String, dynamic>{
          'id': 'soil-1',
          'timestamp': '2026-09-04T08:02:00Z',
          'uptimeMs': 121000,
          'severity': 'INFO',
          'type': 'SOIL_LEFT_CRITICAL_DRY',
          'message': 'Soil left critical dryness',
        },
      ],
    });

    expect(edge.recentEvents, hasLength(2));
    expect(edge.recentEvents.first.id, 'soil-1');
    expect(edge.recentEvents.first.message, 'Soil left critical dryness');
    expect(edge.recentEvents.last.id, 'irrigation-1');
  });

  test('all frozen additions remain optional for older firmware', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{'temperature': 29},
      firmwareVersion: 'legacy',
    );

    expect(edge.sensorIntegrity.hasData, isFalse);
    expect(edge.plausibility.hasData, isFalse);
    expect(edge.runtimeHealth.hasData, isFalse);
    expect(edge.recovery.progressPct, isNull);
    expect(edge.recentEvents, isEmpty);
    expect(edge.buildState, isNull);
  });

  test('presentation bio is visible but excluded from fallback diagnosis', () {
    final reading = SensorReading(
      nodeId: 'presentation-node',
      timestamp: DateTime.now(),
      soilMoisture: 50,
      temperature: 28,
      humidity: 60,
      light: 70,
      plantSignal: 2,
      bioelectricStability: 2,
      bioSignalQuality: 100,
      bioBaselineReady: true,
      bioSource: 'realtime',
      healthScore: 50,
      stressScore: 50,
      healthStatus: 'WATCH',
    );

    final result = HealthAnalysisEngine.analyze(reading, const []);
    expect(reading.bioIsPresentation, isTrue);
    expect(reading.bioSourceLabel, 'Presentation Signal');
    expect(result.bioelectricStability, isNull);
  });

  test('Home has one merged system-warning slot and separate active recovery',
      () {
    final source =
        File('lib/screens/live_node_home_screen.dart').readAsStringSync();
    expect(
      RegExp(r'_SystemQualityCard\(notice: homeSystemNotice\)')
          .allMatches(source),
      hasLength(1),
    );
    expect(source, contains('edge?.recovery.visibleOnHome == true'));
    expect(source, contains('_RecoveryStatusCard(recovery: edge!.recovery)'));
    expect(source, contains('if (!live &&'));
  });

  test('Judge View exposes reliability, runtime and deduplicated events', () {
    final source = File('lib/screens/judge_view_screen.dart').readAsStringSync();
    expect(source, contains("title: 'Node reliability'"));
    expect(source, contains("_Metric('Sensor plausibility'"));
    expect(source, contains("'Sensor-cycle latency'"));
    expect(source, contains("title: 'Event timeline'"));
    expect(source, contains("_Metric('Build state'"));
  });
}
