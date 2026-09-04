import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/models/edge_intelligence.dart';

void main() {
  test('restored individual plant model is shown READY and retained', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const {},
      data: {
        'adaptivePlantModel': {
          'status': 'RESTORED',
          'confidence': 0.91,
          'learnedSamples': 184,
          'ageSec': 7200,
          'bioBaselineMv': 1788.4,
          'typicalBioVariationMv': 11.2,
          'normalNoiseMv': 4.8,
          'normalSoilRatePctPerHour': -0.32,
        },
      },
      firmwareVersion: 'v8.0',
    );

    expect(edge.plantModel.hasData, isTrue);
    expect(edge.plantModel.displayStatus, 'READY');
    expect(edge.plantModel.modelReady, isTrue);
    expect(edge.plantModel.persisted, isTrue);
    expect(edge.plantModel.learnedSamples, 184);
    expect(edge.plantModel.confidence, closeTo(91, 0.01));
    expect(edge.plantModel.bioBaselineMv, closeTo(1788.4, 0.01));
  });

  test('temporal cause-response reasoning parses without local inference', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const {},
      data: {
        'prediction': {
          'available': true,
          'confidence': 0.82,
          'target': 'water stress',
          'minutesToWarning': 18,
        },
        'causeResponse': {
          'state': 'TRACKING',
          'confidence': 84,
          'primarySequence': 'drying -> bio response -> recovery',
          'environmentToBioLagSec': 52,
          'actionToRecoveryLagSec': 133,
          'explanation': 'Firmware-observed sequence',
        },
      },
      firmwareVersion: 'v8.0',
    );

    expect(edge.temporalReasoning.hasData, isTrue);
    expect(edge.temporalReasoning.state, 'TRACKING');
    expect(edge.temporalReasoning.confidence, 84);
    expect(edge.temporalReasoning.environmentToBioLagSec, 52);
    expect(edge.temporalReasoning.actionToRecoveryLagSec, 133);
    expect(edge.prediction.confidence, closeTo(82, 0.01));
    expect(
      edge.temporalReasoning.explanation,
      'Firmware-observed sequence',
    );
  });

  test('old firmware payload remains backward compatible', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const {},
      data: const {'healthScore': 73},
      firmwareVersion: 'legacy',
    );

    expect(edge.healthScore, 73);
    expect(edge.plantModel.hasData, isFalse);
    expect(edge.temporalReasoning.hasData, isFalse);
  });

  test('farmer home gates adaptive model and prediction compactly', () {
    final source =
        File('lib/screens/live_node_home_screen.dart').readAsStringSync();
    expect(source, contains('Learning this plant'));
    expect(source, contains('prediction.available == true'));
    expect(source, contains('confidence >= 65'));
    expect(source, contains('_FarmerEdgeSignals.visible(edge)'));
  });

  test('Judge View exposes model and cause-response intelligence', () {
    final source = File('lib/screens/judge_view_screen.dart').readAsStringSync();
    expect(source, contains("'Individual Plant Model'"));
    expect(source, contains("'Cause-Response Intelligence'"));
    expect(source, contains("'Prediction confidence'"));
    expect(source, contains("'Baseline retained'"));
  });
}
