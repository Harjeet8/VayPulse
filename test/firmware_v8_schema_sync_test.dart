import 'package:flutter_test/flutter_test.dart';

import 'package:phytosense_ai/models/edge_intelligence.dart';
import 'package:phytosense_ai/models/hardware_telemetry.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';

void main() {
  const payload = <String, dynamic>{
    'schemaVersion': 8,
    'plantState': 'STRESSED',
    'healthScore': 48.0,
    'healthConfidence': 80.2,
    'priority': 'WATCH',
    'primaryFinding': 'High atmospheric drying demand',
    'primaryAction':
        'Reduce drying stress where practical and monitor root-zone moisture',
    'decisionExplanation':
        'VPD indicates the air is pulling water quickly. Soil/root evidence may still be normal.',
    'rootCause': <String, dynamic>{
      'primary': <String, dynamic>{
        'name': 'High atmospheric drying demand',
        'confidence': 90,
        'evidenceFor': 'VPD indicates the air is pulling water quickly',
        'evidenceAgainst': 'Soil/root evidence may still be normal',
      },
      'secondary': <String, dynamic>{
        'name': 'Heat stress',
        'confidence': 47.4,
        'evidenceFor': 'Air temperature is elevated',
        'evidenceAgainst': 'Root temperature is not strongly abnormal',
      },
      'ranked': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'High atmospheric drying demand',
          'confidence': 90,
          'evidenceFor': 'High VPD',
          'evidenceAgainst': 'Wet soil',
        },
        <String, dynamic>{
          'name': 'Heat stress',
          'confidence': 47.4,
        },
      ],
    },
    'recovery': <String, dynamic>{
      'state': 'NONE',
      'confidence': 0,
      'environmentImproved': false,
      'bioResponseDecreasing': false,
      'farmerResult': 'No recovery event is being verified',
    },
    'bioelectric': <String, dynamic>{
      'available': true,
      'voltageMv': 482.0,
      'baselineMv': 451.0,
      'signedChangeMv': 31.0,
      'deviationMv': 31.0,
      'normalizedDeviation': 9.7,
      'noiseMv': 3.2,
      'signalQuality': 91,
      'signalQualityState': 'GOOD',
      'confidence': 86,
      'trend': 'RISING',
      'stressScore': 84,
      'stressState': 'STRESS_SIGNAL',
      'persistenceSeconds': 28,
      'stressLoad': 36.5,
      'stressLoadState': 'PERSISTENT',
      'baselineLearningPaused': true,
      'rawADC': 411,
      'corroborated': true,
      'corroboratedBy': <String>['vpd'],
      'farmerResult': 'Plant stress detected — likely atmospheric drying stress',
    },
    'bioticStress': <String, dynamic>{
      'state': 'NONE',
      'evidenceScore': 12,
      'confidence': 86,
      'unexplainedBioResponse': false,
      'abioticCauseFound': true,
      'diseaseConduciveSupport': false,
      'pestIdentified': false,
      'infectionConfirmed': false,
    },
    'compoundStress': <String, dynamic>{
      'state': 'NONE',
      'severity': 0,
      'waterEvidence': 25.2,
      'heatEvidence': 47.4,
      'rootEvidence': 0,
      'atmosphericEvidence': 90,
    },
    'responseLag': <String, dynamic>{
      'environmentToBioResponseSeconds': 180,
      'irrigationToBioDecreaseSeconds': 300,
      'interpretation': 'observed timing only; not proof of causation',
    },
    'anomaly': <String, dynamic>{
      'state': 'DETECTED',
      'detected': true,
      'score': 72,
      'confidence': 81,
      'reason': 'Persistent deviation from learned baseline',
    },
    'prediction': <String, dynamic>{
      'available': false,
      'confidence': 0,
      'target': 'soilMoisture',
      'minutesToWarning': null,
      'message': 'Prediction unavailable - trend not stable enough',
    },
    'sensorResults': <String, dynamic>{
      'soilMoisture': <String, dynamic>{
        'result': 'VERY WET',
        'trend': 'STABLE',
        'confidence': 100,
        'effectOnPlant': 'No strong water-stress effect detected',
      },
      'vpd': <String, dynamic>{
        'result': 'HIGH DRYING DEMAND',
        'trend': 'RISING',
        'confidence': 92,
        'effectOnPlant': 'Increasing atmospheric water demand',
      },
    },
    'trends': <String, dynamic>{
      'soilMoisture': <String, dynamic>{
        'state': 'STABLE',
        'ratePerMinute': -0.12,
        'shortSlopePerMinute': -0.15,
        'longSlopePerMinute': -0.07,
        'confidence': 94,
      },
    },
    'sensorConfidence': <String, dynamic>{
      'soilMoisture': <String, dynamic>{'confidence': 100},
      'vpd': <String, dynamic>{'confidence': 92},
    },
  };

  test('schema v8 authoritative intelligence parses without losing new fields', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: payload,
      firmwareVersion: '8.0.0-ULTRA-FINAL',
    );

    expect(edge.schemaVersion, 8);
    expect(edge.hasAuthoritativeAnalysis, isTrue);
    expect(edge.rootCause.primary, 'High atmospheric drying demand');
    expect(edge.rootCause.primaryCandidate?.confidence, 90);
    expect(edge.rootCause.primaryCandidate?.evidenceFor, contains('VPD'));
    expect(edge.rootCause.primaryCandidate?.evidenceAgainst, contains('Soil'));
    expect(edge.rootCause.ranked, hasLength(2));

    expect(edge.recovery.state, 'NONE');
    expect(edge.recovery.environmentImproved, isFalse);
    expect(edge.recovery.farmerResult, contains('No recovery'));

    expect(edge.bioelectric.signalQualityState, 'GOOD');
    expect(edge.bioelectric.stressLoad, 36.5);
    expect(edge.bioelectric.stressLoadState, 'PERSISTENT');
    expect(edge.bioelectric.baselineLearningPaused, isTrue);
    expect(edge.bioelectric.rawAdc, 411);

    expect(edge.compoundStress.atmosphericEvidence, 90);
    expect(edge.responseLag.environmentToBioResponseSeconds, 180);
    expect(edge.responseLag.irrigationToBioDecreaseSeconds, 300);
    expect(edge.anomaly.detected, isTrue);
    expect(edge.anomaly.score, 72);

    expect(edge.prediction.available, isFalse);
    expect(edge.prediction.target, 'soilMoisture');
    expect(edge.prediction.message, contains('unavailable'));

    final soilTrend = edge.trends.singleWhere(
      (trend) => trend.channel == 'soilMoisture',
    );
    expect(soilTrend.ratePerMinute, -0.12);
    expect(soilTrend.shortSlopePerMinute, -0.15);
    expect(soilTrend.longSlopePerMinute, -0.07);
    expect(soilTrend.confidence, 94);
  });

  test('schema v8 sensor effect and per-minute trend reach Live Sensors telemetry', () {
    final telemetry = HardwareTelemetry.fromPayload(
      root: const <String, dynamic>{},
      data: payload,
      firmwareVersion: '8.0.0-ULTRA-FINAL',
    );

    final soil = telemetry.sensor('soilMoisture');
    expect(soil?.result, 'VERY WET');
    expect(soil?.contribution, 'No strong water-stress effect detected');
    expect(soil?.ratePerMinute, -0.12);
    expect(soil?.shortSlopePerMinute, -0.15);
    expect(soil?.longSlopePerMinute, -0.07);

    final vpd = telemetry.sensor('vpd');
    expect(vpd?.result, 'HIGH DRYING DEMAND');
    expect(vpd?.contribution, 'Increasing atmospheric water demand');
  });

  test('ESP32 v8.7.1 structured intelligence remains authoritative', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{
        'schemaVersion': 8,
        'apiVersion': '8',
        'healthIndex': 91,
        'plantState': 'HEALTHY',
        'priority': 'WATCH',
        'mainFinding': 'No major stress detected',
        'farmerAction': 'Continue monitoring',
        'because': 'The active sensors remain within the crop profile.',
        'crop': <String, dynamic>{
          'name': 'Hibiscus',
          'stage': 'Flowering',
          'regionProfile': 'Tamil Nadu warm season',
        },
        'analysisQuality': <String, dynamic>{
          'level': 'REDUCED',
          'degraded': true,
          'reasons': <String>['Humidity sensor unavailable'],
        },
        'bio': <String, dynamic>{
          'available': true,
          'state': 'LEARNING_BASELINE',
          'baselineReady': false,
          'baselineSamples': 32,
          'baselineTarget': 120,
          'zScore': 0.4,
          'spanMv': 19.2,
          'signalQuality': 93,
          'includedInFusion': true,
        },
        'waterBalance': <String, dynamic>{
          'state': 'BALANCED',
          'score': 88,
        },
        'cameraHandoff': <String, dynamic>{
          'recommended': false,
          'reason': 'No visual inspection required',
        },
      },
      firmwareVersion: '8.7.1-MEGA-FINAL',
    );

    expect(edge.hasAuthoritativeAnalysis, isTrue);
    expect(edge.apiVersion, '8');
    expect(edge.firmwareCompatible, isTrue);
    expect(edge.healthScore, 91);
    expect(edge.plantState, 'HEALTHY');
    expect(edge.urgency, 'WATCH');
    expect(edge.farmerSummary, 'No major stress detected');
    expect(edge.recommendation, 'Continue monitoring');
    expect(edge.cropProfile.profile, 'Hibiscus');
    expect(edge.cropProfile.regionProfile, 'Tamil Nadu warm season');
    expect(edge.degradedAnalysis, isTrue);
    expect(edge.degradedReasons, contains('Humidity sensor unavailable'));
    expect(edge.bioelectric.learningBaseline, isTrue);
    expect(edge.bioelectric.baselineSamples, 32);
    expect(edge.bioelectric.baselineTarget, 120);
    expect(edge.bioelectric.includedInFusion, isTrue);
    expect(edge.waterBalance.state, 'BALANCED');
    expect(edge.cameraInspectionRecommended, isFalse);
  });

  test('flat v8.7.1 aliases and bad-signal fail-safe parse safely', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{
        'plantState': 'WATCH',
        'bioState': 'BAD_CONTACT',
        'bioStressScore': 94,
        'bioSignalQuality': 12,
        'bioIncludedInFusion': false,
        'cameraScanRecommended': true,
        'cameraScanReason': 'Inspect visible symptoms',
      },
      firmwareVersion: '8.7.1-MEGA-FINAL',
    );

    expect(edge.bioelectric.stressState, 'BAD_CONTACT');
    expect(edge.bioelectric.stressScore, 94);
    expect(edge.bioelectric.excludedByFirmware, isTrue);
    expect(edge.cameraInspectionRecommended, isTrue);
    expect(edge.cameraHandoff.reason, 'Inspect visible symptoms');
  });

  test('older firmware may omit all v8.7.1 additions without crashing', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{'temperature': 28},
      firmwareVersion: '5.4',
    );

    expect(edge.healthScore, isNull);
    expect(edge.cameraInspectionRecommended, isFalse);
    expect(edge.waterBalance.hasData, isFalse);
    expect(edge.bioelectric.excludedByFirmware, isFalse);
  });

  test('newer unsupported schema is retained and reported safely', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{
        'schemaVersion': 99,
        'apiVersion': '99-preview',
        'plantState': 'HEALTHY',
      },
      firmwareVersion: 'future-build',
    );

    expect(edge.schemaVersion, 99);
    expect(edge.apiVersion, '99-preview');
    expect(edge.firmwareCompatible, isFalse);
    expect(edge.compatibilityIssue, 'Firmware compatibility issue');
  });

  test('all v8.7.1 bad bio states activate the firmware fail-safe', () {
    for (final state in const <String>[
      'SIGNAL NOISY',
      'CHECK CONTACT',
      'SATURATED',
      'AMP HIGH RAIL',
      'AMP LOW RAIL',
    ]) {
      final edge = EdgeIntelligence.fromPayload(
        root: const <String, dynamic>{},
        data: <String, dynamic>{
          'plantState': 'WATCH',
          'bioState': state,
          'bioStressScore': 99,
          'bioSignalQuality': 5,
        },
        firmwareVersion: '8.7.1-MEGA-FINAL',
      );

      expect(
        edge.bioelectric.excludedByFirmware,
        isTrue,
        reason: '$state must never be interpreted as plant stress',
      );
    }
  });

  test('compact hardware history preserves v8.7.1 intelligence fields', () {
    final reading = SensorReading(
      nodeId: 'phytosense-live-01',
      timestamp: DateTime.utc(2026, 8, 30, 7, 30),
      soilMoisture: 41,
      temperature: 29,
      humidity: 0,
      humidityAvailable: false,
      light: 72,
      healthScore: 67,
      stressScore: 33,
      healthStatus: 'RECOVERING',
      analysisConfidence: 84,
      analysisOrigin: 'esp32',
      vpdKpa: 1.72,
      bioticState: 'POSSIBLE_BIOTIC_STRESS',
      recoveryActive: true,
      bioBaselineReady: true,
      bioBaselineSamples: 120,
      bioBaselineMv: 451.2,
      bioDeviationMv: 18.4,
    );

    final restored = SensorReading.fromJson(reading.toJson());
    expect(restored.analysisOrigin, 'esp32');
    expect(restored.humidityAvailable, isFalse);
    expect(restored.vpdKpa, 1.72);
    expect(restored.bioticState, 'POSSIBLE_BIOTIC_STRESS');
    expect(restored.recoveryActive, isTrue);
    expect(restored.bioBaselineMv, 451.2);
    expect(restored.bioDeviationMv, 18.4);
  });
}
