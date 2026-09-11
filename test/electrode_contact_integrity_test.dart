import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:phytosense_ai/models/edge_intelligence.dart';

EdgeIntelligence _edge(Map<String, dynamic> additions) =>
    EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: <String, dynamic>{
        'schemaVersion': 8,
        'bioSource': 'real',
        ...additions,
      },
      firmwareVersion: 'PhytoSense AI v8.0 ULTRA FINAL',
    );

void main() {
  test('top-level contact integrity aliases parse safely', () {
    final edge = _edge(<String, dynamic>{
      'bioContactState': 'OPEN',
      'bioContactConfidence': 0.93,
      'bioSlowDriftMv': 1.7,
      'bioelectric': <String, dynamic>{
        'signalQuality': 100,
        'baselineReady': false,
        'includedInFusion': true,
      },
    });

    expect(edge.bioelectric.normalizedContactState, 'OPEN');
    expect(edge.bioelectric.contactConfidence, 93);
    expect(edge.bioelectric.slowDriftMv, 1.7);
    expect(edge.bioelectric.signalQuality, 100);
    expect(edge.bioelectric.excludedByFirmware, isTrue);
    expect(edge.bioelectric.learningBaseline, isFalse);
  });

  test('nested contact integrity takes part in plant-use gating', () {
    final edge = _edge(<String, dynamic>{
      'bioelectric': <String, dynamic>{
        'contactState': 'PLAUSIBLE',
        'contactConfidence': 88,
        'contactPlausibleForPlantUse': true,
        'slowDriftMv': 2.1,
        'openEvidence': 0.05,
        'staticEvidence': 0.08,
        'signalQuality': 100,
        'baselineReady': false,
        'baselineSamples': 18,
        'baselineTarget': 60,
        'includedInFusion': true,
      },
    });

    expect(edge.bioelectric.plantContactPlausible, isTrue);
    expect(edge.bioelectric.excludedByFirmware, isFalse);
    expect(edge.bioelectric.learningBaseline, isTrue);
    expect(edge.bioelectric.openEvidence, '0.05');
    expect(edge.bioelectric.staticEvidence, '0.08');
  });

  for (final state in <String>[
    'OPEN',
    'VERIFY',
    'STATIC',
    'SHORT_SUSPECTED',
    'UNSTABLE',
    'SATURATED',
  ]) {
    test('$state contact is excluded even with perfect electrical quality', () {
      final edge = _edge(<String, dynamic>{
        'bioelectric': <String, dynamic>{
          'contactState': state,
          'contactConfidence': 99,
          'contactPlausibleForPlantUse': false,
          'signalQuality': 100,
          'baselineReady': false,
          'includedInFusion': true,
        },
      });

      expect(edge.bioelectric.signalQuality, 100);
      expect(edge.bioelectric.excludedByFirmware, isTrue);
      expect(edge.bioelectric.learningBaseline, isFalse);
    });
  }

  test('explicit plausible-for-plant false excludes contact without state', () {
    final edge = _edge(<String, dynamic>{
      'bioelectric': <String, dynamic>{
        'contactPlausibleForPlantUse': false,
        'signalQuality': 100,
        'includedInFusion': true,
      },
    });

    expect(edge.bioelectric.excludedByFirmware, isTrue);
  });

  test('new contact telemetry requires an explicit PLAUSIBLE state', () {
    final edge = _edge(<String, dynamic>{
      'bioelectric': <String, dynamic>{
        'contactConfidence': 94,
        'contactPlausibleForPlantUse': true,
        'signalQuality': 100,
        'includedInFusion': true,
      },
    });

    expect(edge.bioelectric.contactTelemetryAvailable, isTrue);
    expect(edge.bioelectric.normalizedContactState, isNull);
    expect(edge.bioelectric.excludedByFirmware, isTrue);
  });

  test('older firmware without contact telemetry keeps legacy behavior', () {
    final edge = _edge(<String, dynamic>{
      'bioelectric': <String, dynamic>{
        'signalQuality': 100,
        'signalQualityState': 'GOOD',
        'baselineReady': false,
        'includedInFusion': true,
      },
    });

    expect(edge.bioelectric.contactTelemetryAvailable, isFalse);
    expect(edge.bioelectric.excludedByFirmware, isFalse);
    expect(edge.bioelectric.learningBaseline, isTrue);
  });

  test('Home reuses one compact system-warning slot for contact states', () {
    final source =
        File('lib/screens/live_node_home_screen.dart').readAsStringSync();

    expect(source, contains("title: 'Electrodes open'"));
    expect(source, contains("issue: 'Check plant contact'"));
    expect(source, contains("title: 'Verify electrode contact'"));
    expect(source, contains("title: 'Static/test input'"));
    expect(source, contains("issue: 'Not used for plant analysis'"));
    expect(source, contains("title: 'Electrode contact unstable'"));
    expect(source, contains("title: 'Bio sensor saturated'"));
    expect(source, contains('static _HomeSystemNotice? fromEdge'));
    expect(source, isNot(contains('class _ElectrodeContactCard')));
  });

  test('ESP32 fallback sensor normalization gates invalid plant contact', () {
    final source = File('lib/services/esp32_client.dart').readAsStringSync();

    expect(source, contains('contactValidForPlantUse'));
    expect(source, contains("bioContactState == 'PLAUSIBLE'"));
    expect(source, contains('bioContactPlausibleForPlantUse != false'));
    expect(source, contains("data['bioContactState']"));
    expect(source, contains("data['bioSlowDriftMv']"));
  });

  test('Engineering View distinguishes electrical quality from plant contact',
      () {
    final source =
        File('lib/screens/judge_view_screen.dart').readAsStringSync();

    expect(source, contains("'Electrical signal quality'"));
    expect(source, contains("'Electrode contact state'"));
    expect(source, contains("'Contact confidence'"));
    expect(source, contains("'Slow drift'"));
    expect(source, contains("'Plausible for plant use'"));
    expect(source, contains("'Open-contact evidence'"));
    expect(source, contains("'Static/test evidence'"));
    expect(
      source,
      contains(
        'Electrical signal quality alone is not treated as valid plant contact.',
      ),
    );
  });
}
