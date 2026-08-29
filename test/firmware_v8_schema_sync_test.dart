import 'package:flutter_test/flutter_test.dart';

import 'package:phytosense_ai/models/edge_intelligence.dart';
import 'package:phytosense_ai/models/hardware_telemetry.dart';

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
}
