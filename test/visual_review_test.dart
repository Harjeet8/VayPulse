import 'dart:async';
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
import 'package:phytosense_ai/screens/about_screen.dart';
import 'package:phytosense_ai/services/firmware_text_adapter.dart';
import 'package:phytosense_ai/services/farmer_language.dart';
import 'package:phytosense_ai/screens/voice_studio_screen.dart';
import 'package:phytosense_ai/screens/splash_screen.dart';
import 'package:phytosense_ai/screens/farmer_analysis_screen.dart';
import 'package:phytosense_ai/widgets/verdant_care_hero.dart';
import 'package:phytosense_ai/widgets/bottom_nav.dart';
import 'package:phytosense_ai/services/sensor_data_provider.dart';
import 'package:phytosense_ai/widgets/simulation_notice.dart';
import 'package:phytosense_ai/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async {
      if (call.method == 'getVoices') {
        return [
          {
            'name': 'english',
            'locale': 'en-IN',
            'quality': 500,
            'network_required': false
          },
          {
            'name': 'tamil',
            'locale': 'ta-IN',
            'quality': 400,
            'network_required': false
          },
        ];
      }
      return 1;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.harjeet.phytosense/care'),
            (_) async => null);
  });
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
            'Home, Plant Care and voice $language $brightness $width fit and render',
            (tester) async {
          SharedPreferences.setMockInitialValues({});
          await tester.binding.setSurfaceSize(Size(width, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final settings = SettingsService();
          settings.value.languageCode = language;
          final farms = FarmRepository(),
              sensors = SensorProviderManager(),
              weather = WeatherService();
          sensors.configure(
              source: SensorDataSource.simulation,
              endpoint: sensors.hardwareEndpoint);
          sensors.setScenario('critical');
          sensors.start();
          final alerts = AlertService(sensors, settings, weather, farms),
              voice = VoiceGuidanceService();
          final offline = OfflineSyncService(sensors, settings),
              evidence = EngineeringEvidenceService(sensors),
              inspections = InspectionHistoryService();
          for (final scene in [
            'home',
            'care',
            'voice',
            'creator',
            'offline',
            'practice'
          ]) {
            if (scene == 'offline') {
              sensors.stop();
              sensors.configure(
                  source: SensorDataSource.esp32,
                  endpoint: sensors.hardwareEndpoint);
            }
            final home = scene == 'home';
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
                            child: SimulationNotice(
                                child: Scaffold(
                                    body: scene == 'practice'
                                        ? const SingleChildScrollView(
                                            child: SimulationModeControl())
                                        : scene == 'offline'
                                            ? const HomeScreen()
                                            : scene == 'creator'
                                                ? const SingleChildScrollView(
                                                    padding: EdgeInsets.all(20),
                                                    child: CreatorProfile())
                                                : scene == 'voice'
                                                    ? const VoiceStudioScreen()
                                                    : home
                                                        ? const HomeScreen()
                                                        : const FarmerAnalysisScreen(),
                                    bottomNavigationBar: BottomNav(
                                        index: home ? 0 : 1,
                                        onChanged: (_) {}))))))));
            await tester.pump(const Duration(milliseconds: 1200));
            // Let controls finish their loading-to-ready colour transition.
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull, reason: 'Scene: $scene');
            if (scene == 'offline') {
              expect(find.byKey(const Key('plant-health-score')), findsNothing);
              expect(find.byKey(const Key('simulation-notice')), findsNothing);
              expect(find.byKey(const Key('simulation-mode-switch')),
                  findsNothing);
              expect(
                  find.text(
                      language == 'ta' ? 'சாதனத்தை இணை' : 'Connect my sensor'),
                  findsOneWidget);
            }
            if (scene == 'practice') {
              await tester.tap(find.byKey(const Key('simulation-mode-switch')));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));
              expect(sensors.source, SensorDataSource.simulation);
              expect(settings.value.dataSource, 'simulation');
              expect(
                  find.byKey(const Key('simulation-notice')), findsOneWidget);
              expect(tester.takeException(), isNull);
              await tester.tap(find.byKey(const Key('simulation-mode-switch')));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));
              expect(sensors.source, SensorDataSource.esp32);
              expect(sensors.current, isNull);
              expect(find.byKey(const Key('simulation-notice')), findsNothing);
              expect(tester.takeException(), isNull);
            }
            if (scene == 'home' || scene == 'care') {
              expect(
                  find.byKey(const Key('farmer-main-problem')), findsOneWidget);
              expect(find.byKey(const Key('farmer-immediate-action')),
                  findsOneWidget);
            }
            if (scene == 'creator') {
              expect(find.text('Harjeet D.'), findsOneWidget);
              expect(
                  find.text(
                      language == 'ta' ? 'எனது அணுகுமுறை' : 'How I build'),
                  findsOneWidget);
            }
            if (home && language == 'ta') {
              final context = tester.element(find.byType(HomeScreen));
              expect(FarmerLanguage.firmware(context, 'Tomato'), 'தக்காளி');
              expect(FarmerLanguage.firmware(context, 'vegetative'),
                  'இலை வளர்ச்சி');
              expect(
                  FirmwareTextAdapter.text(context,
                      'Inspect the root zone immediately and reduce heat exposure where practical.'),
                  isNot(matches(RegExp('[A-Za-z]'))));
            }
            if (scene == 'voice') {
              expect(
                  find.byType(DropdownButtonFormField<String>), findsOneWidget);
            }
            if (scene == 'care' && width == 390)
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
                    'build/visual-review/$scene-$language-${brightness.name}.png');
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
          voice.dispose();
        });
      }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final reduced in [false, true]) {
      testWidgets(
          'Growing boot $brightness reduced motion $reduced fits narrow phone',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final waiting = Completer<void>();
        final boundary = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(brightness, 'en'),
          home: MediaQuery(
            data: MediaQueryData(
                size: const Size(320, 640),
                disableAnimations: reduced,
                textScaler: TextScaler.linear(1.3)),
            child: RepaintBoundary(
                key: boundary,
                child: SplashScreen(initialization: waiting.future)),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 950));
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(tester.takeException(), isNull);
        expect(find.byType(SplashScreen), findsOneWidget);
        if (Platform.environment['PHYTO_PREVIEWS'] == '1' && !reduced) {
          await tester.runAsync(() async {
            final picture = await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
            final bytes =
                await picture.toByteData(format: ui.ImageByteFormat.png);
            final file =
                File('build/visual-review/boot-${brightness.name}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        waiting.complete();
        await tester.pump();
      });
    }
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
