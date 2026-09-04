import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/app/app.dart';
import 'package:phytosense_ai/models/crop_catalog.dart';
import 'package:phytosense_ai/models/edge_intelligence.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';
import 'package:phytosense_ai/screens/splash_screen.dart';
import 'package:phytosense_ai/widgets/calibre_upgrade_panels.dart';
import 'package:phytosense_ai/widgets/home_soil_presentation.dart';
import 'package:phytosense_ai/widgets/live_motion.dart';
import 'package:phytosense_ai/widgets/time_phase_card.dart';

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
  test('startup cannot remain trapped behind a stalled local cache', () async {
    final stalled = Completer<void>();
    await waitForStartupServices(
      [stalled.future],
      timeout: const Duration(milliseconds: 5),
    );

    expect(stalled.isCompleted, isFalse);
  });

  testWidgets('boot presents the approved logo as a smooth squircle',
      (tester) async {
    final stalled = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(initialization: stalled.future)),
    );
    await tester.pump();

    final clip = tester.widget<ClipRRect>(
      find.byKey(const Key('boot-logo-clip')),
    );
    expect(clip.borderRadius, BorderRadius.circular(42));
    expect(clip.clipBehavior, Clip.antiAlias);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion still presents a branded boot before Home',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SplashScreen(initialization: Future<void>.value()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('PhytoSense AI'), findsOneWidget);
    expect(find.byKey(const Key('boot-logo-clip')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Android launch window matches the animated boot handoff', () {
    final colors = File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsStringSync();
    final android12Theme = File(
      'android/app/src/main/res/values-v31/styles.xml',
    ).readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(colors, contains('#04120E'));
    expect(android12Theme, contains('@drawable/ic_launcher_nova'));
    expect(android12Theme, isNot(contains('@mipmap/ic_launcher')));
    expect(manifest, contains('io.flutter.embedding.android.NormalTheme'));
  });

  testWidgets('live icons have clearly changing individual motion',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: LiveMotionIcon(
            key: Key('motion-probe'),
            icon: Icons.electric_bolt_rounded,
            style: LiveMotionStyle.spark,
          ),
        ),
      ),
    );
    await tester.pump();
    final motionFinder = find.descendant(
      of: find.byKey(const Key('motion-probe')),
      matching: find.byType(Transform),
    );
    final before = tester
        .widgetList<Transform>(motionFinder)
        .map((widget) => widget.transform.storage.join(','))
        .join('|');

    await tester.pump(const Duration(milliseconds: 480));
    final after = tester
        .widgetList<Transform>(motionFinder)
        .map((widget) => widget.transform.storage.join(','))
        .join('|');

    expect(after, isNot(before));
    await tester.pumpWidget(const SizedBox.shrink());
  });

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

  testWidgets('time window prefers the ESP32 day or night phase',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TimePhaseCard(live: true, espDayPhase: 'NIGHT'),
        ),
      ),
    );

    expect(find.text('NIGHT'), findsOneWidget);
    expect(find.text('ESP32 PHASE'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Home uses ESP soil states without rewriting technical root cause', () {
    final veryDry = HomeSoilPresentation.fromFirmware('VERY DRY');
    expect(veryDry, isNotNull);
    expect(veryDry!.title(tamil: false), 'VERY DRY');
    expect(
      veryDry.summary(tamil: false),
      'Root-zone moisture is critically low.',
    );
    expect(HomeSoilPresentation.isSoilLedFinding('Water stress'), isTrue);
    expect(HomeSoilPresentation.isSoilLedFinding('Heat stress'), isFalse);

    for (final state in const [
      'VERY DRY',
      'DRY',
      'LOW',
      'GOOD',
      'WET',
      'VERY WET',
    ]) {
      expect(HomeSoilPresentation.fromFirmware(state), isNotNull);
    }
  });
}
