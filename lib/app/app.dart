import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../screens/splash_screen.dart';
import '../services/alert_service.dart';
import '../services/app_scope.dart';
import '../services/farm_repository.dart';
import '../services/engineering_evidence_service.dart';
import '../services/inspection_history_service.dart';
import '../services/offline_sync_service.dart';
import '../services/phone_notification_service.dart';
import '../services/settings_service.dart';
import '../services/sensor_data_provider.dart';
import '../services/sensor_provider_manager.dart';
import '../services/voice_guidance_service.dart';
import '../services/weather_service.dart';
import 'theme.dart';

class VayPulseApp extends StatefulWidget {
  const VayPulseApp({super.key});
  @override
  State<VayPulseApp> createState() => _VayPulseAppState();
}

class _VayPulseAppState extends State<VayPulseApp> {
  late final SettingsService settings;
  late final FarmRepository farms;
  late final SensorProviderManager sensors;
  late final AlertService alerts;
  late final WeatherService weather;
  late final VoiceGuidanceService voice;
  late final OfflineSyncService offlineSync;
  late final EngineeringEvidenceService engineeringEvidence;
  late final PhoneNotificationService phoneNotifications;
  late final InspectionHistoryService inspectionHistory;
  late final Future<void> initialization;

  @override
  void initState() {
    super.initState();
    settings = SettingsService();
    farms = FarmRepository();
    sensors = SensorProviderManager();
    weather = WeatherService();
    voice = VoiceGuidanceService();
    offlineSync = OfflineSyncService(sensors, settings);
    engineeringEvidence = EngineeringEvidenceService(sensors);
    inspectionHistory = InspectionHistoryService();
    alerts = AlertService(sensors, settings, weather, farms);
    phoneNotifications = PhoneNotificationService(alerts, settings);
    initialization = _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      settings.load(),
      farms.load(),
      offlineSync.load(),
      engineeringEvidence.load(),
      inspectionHistory.load(),
    ]);
    sensors.setScenario(settings.value.demoScenario);
    sensors.simulation.selectNode(settings.value.demoNodeId);
    sensors.configure(
      source: settings.value.dataSource == 'esp32'
          ? SensorDataSource.esp32
          : SensorDataSource.simulation,
      endpoint: settings.value.esp32Endpoint,
    );
    sensors.start();
    offlineSync.start();
    engineeringEvidence.start();
    alerts.start();
    phoneNotifications.start();
    unawaited(weather.load());
  }

  @override
  void dispose() {
    phoneNotifications.dispose();
    alerts.dispose();
    offlineSync.dispose();
    engineeringEvidence.dispose();
    inspectionHistory.dispose();
    unawaited(voice.stop());
    sensors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: settings,
      farms: farms,
      sensorManager: sensors,
      alerts: alerts,
      weather: weather,
      voice: voice,
      offlineSync: offlineSync,
      engineeringEvidence: engineeringEvidence,
      inspectionHistory: inspectionHistory,
      child: AnimatedBuilder(
        animation: settings,
        builder: (_, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PhytoSense AI',
          theme: buildTheme(Brightness.light, settings.value.languageCode),
          darkTheme: buildTheme(Brightness.dark, settings.value.languageCode),
          themeMode: settings.value.themeMode,
          themeAnimationDuration: settings.value.reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          themeAnimationCurve: Curves.easeOutCubic,
          locale: Locale(settings.value.languageCode),
          supportedLocales: const [Locale('en'), Locale('ta')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final systemScale = media.textScaler.scale(1.0);
            final scale =
                (systemScale * (settings.value.largeText ? 1.14 : 1.0))
                    .clamp(0.8, 2.0)
                    .toDouble();
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: settings.value.reducedMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: SplashScreen(initialization: initialization),
        ),
      ),
    );
  }
}
