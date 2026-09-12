import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phytosense_ai/app/theme.dart';
import 'package:phytosense_ai/services/app_scope.dart';
import 'package:phytosense_ai/services/alert_service.dart';
import 'package:phytosense_ai/services/farm_repository.dart';
import 'package:phytosense_ai/services/engineering_evidence_service.dart';
import 'package:phytosense_ai/services/inspection_history_service.dart';
import 'package:phytosense_ai/services/offline_sync_service.dart';
import 'package:phytosense_ai/services/sensor_provider_manager.dart';
import 'package:phytosense_ai/services/settings_service.dart';
import 'package:phytosense_ai/services/voice_guidance_service.dart';
import 'package:phytosense_ai/services/weather_service.dart';
import 'package:phytosense_ai/screens/home_screen.dart';
import 'package:phytosense_ai/screens/farmer_analysis_screen.dart';
import 'package:phytosense_ai/widgets/verdant_care_hero.dart';
import 'package:phytosense_ai/widgets/bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final tamil = FontLoader('NotoSansTamil')
      ..addFont(rootBundle.load('assets/fonts/NotoSansTamil-Regular.ttf'));
    await tamil.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final path = Platform.environment['FLUTTER_ROOT'];
    if (path != null) {
      final file =
          File('$path/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
      if (file.existsSync()) {
        final font = FontLoader('Roboto')
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        await font.load();
      }
    }
  });
  for (final language in ['en', 'ta'])
    for (final brightness in [Brightness.light, Brightness.dark])
      for (final width in [320.0, 390.0, 900.0]) {
        testWidgets(
            'Home and Plant Care $language $brightness $width fit and render',
            (tester) async {
          SharedPreferences.setMockInitialValues({});
          await tester.binding.setSurfaceSize(Size(width, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final settings = SettingsService();
          settings.value.languageCode = language;
          final farms = FarmRepository(),
              sensors = SensorProviderManager(),
              weather = WeatherService();
          sensors.setScenario('critical');
          sensors.start();
          final alerts = AlertService(sensors, settings, weather, farms),
              voice = VoiceGuidanceService();
          final offline = OfflineSyncService(sensors, settings),
              evidence = EngineeringEvidenceService(sensors),
              inspections = InspectionHistoryService();
          for (final home in [true, false]) {
            final boundary = GlobalKey();
            await tester.pumpWidget(MaterialApp(
                theme: buildTheme(brightness, language),
                home: AppScope(
                    settings: settings,
                    farms: farms,
                    sensorManager: sensors,
                    alerts: alerts,
                    weather: weather,
                    voice: voice,
                    offlineSync: offline,
                    engineeringEvidence: evidence,
                    inspectionHistory: inspections,
                    child: MediaQuery(
                        data: MediaQueryData(
                            size: Size(width, 844),
                            disableAnimations: true,
                            textScaler:
                                TextScaler.linear(width == 320 ? 1.3 : 1)),
                        child: RepaintBoundary(
                            key: boundary,
                            child: Scaffold(
                                body: home
                                    ? const HomeScreen()
                                    : const FarmerAnalysisScreen(),
                                bottomNavigationBar: BottomNav(
                                    index: home ? 0 : 1,
                                    onChanged: (_) {})))))));
            await tester.pump(const Duration(milliseconds: 1200));
            expect(tester.takeException(), isNull);
            expect(
                find.byKey(const Key('farmer-main-problem')), findsOneWidget);
            expect(find.byKey(const Key('farmer-immediate-action')),
                findsOneWidget);
            if (!home && width == 390)
              expect(
                  tester
                      .getBottomLeft(
                          find.byKey(const Key('farmer-immediate-action')))
                      .dy,
                  lessThan(740));
            if (home)
              expect(
                  find.byKey(const Key('plant-health-score')), findsOneWidget);
            if (width == 390 && Platform.environment['PHYTO_PREVIEWS'] == '1') {
              await tester.runAsync(() async {
                final image = await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 1);
                final data =
                    await image.toByteData(format: ui.ImageByteFormat.png);
                final file = File(
                    'build/visual-review/${home ? 'home' : 'care'}-$language-${brightness.name}.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.pumpWidget(const SizedBox.shrink());
          }
          sensors.dispose();
          alerts.dispose();
          offline.dispose();
          evidence.dispose();
          inspections.dispose();
        });
      }
  testWidgets(
      'missing hardware score stays unavailable rather than becoming zero',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: HealthArc()))));
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
