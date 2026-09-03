import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/models/crop_catalog.dart';
import 'package:phytosense_ai/models/edge_intelligence.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';
import 'package:phytosense_ai/widgets/calibre_upgrade_panels.dart';

SensorReading reading({String bioSource = 'real'}) => SensorReading(
      nodeId: 'test',
      timestamp: DateTime(2026, 9, 3),
      soilMoisture: 61,
      temperature: 27,
      humidity: 58,
      light: 70,
      plantSignal: 91,
      bioSource: bioSource,
      healthScore: 88,
      stressScore: 12,
      healthStatus: 'HEALTHY',
      soilTemperatureAvailable: true,
      soilTemperature: 26,
      leafWetnessAvailable: true,
      leafWetness: 10,
    );

void main() {
  test('final firmware crop profiles are present', () {
    final names = CropCatalog.supported.map((crop) => crop.name).toSet();
    for (final crop in const [
      'Universal',
      'Tomato',
      'Hibiscus',
      'Rice',
      'Sugarcane',
      'Banana',
      'Papaya',
      'Maize',
      'Groundnut',
      'Okra',
    ]) {
      expect(names, contains(crop));
    }
  });

  test('bio presentation sources use final labels', () {
    expect(reading(bioSource: 'real').bioSourceLabel, 'Live Readings');
    expect(
      reading(bioSource: 'realtime').bioSourceLabel,
      'Real Time Signal',
    );
    expect(
      reading(bioSource: 'simulation').bioSourceLabel,
      'Simulation Signal',
    );
  });

  test('reliability parses full degraded and recovering', () {
    EdgeIntelligence edge(String mode) => EdgeIntelligence.fromPayload(
          root: const {},
          data: {
            'analysisQuality': {'reliabilityMode': mode},
          },
          firmwareVersion: 'test',
        );
    expect(edge('FULL').reliabilityMode, 'FULL');
    expect(edge('DEGRADED').reliabilityMode, 'DEGRADED');
    expect(edge('RECOVERING').reliabilityMode, 'RECOVERING');
  });

  testWidgets('fusion map does not overflow a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final edge = EdgeIntelligence(
      firmwareVersion: 'test',
      capabilities: const FirmwareCapabilities(),
      overallConfidence: 93,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SensorFusionMapCard(
                current: reading(),
                edge: edge,
                telemetry: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
