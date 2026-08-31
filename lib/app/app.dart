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
          home: FutureBuilder<void>(
            future: initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const _StartupError();
              if (snapshot.connectionState != ConnectionState.done) {
                return const _StartupLoading();
              }
              return const SplashScreen();
            },
          ),
        ),
      ),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background =
        dark ? const Color(0xFF08131B) : const Color(0xFFF9FBFF);
    final backgroundEnd =
        dark ? const Color(0xFF102A25) : const Color(0xFFEAF8F0);
    final foreground = dark ? Colors.white : const Color(0xFF18342B);
    final signal = dark ? const Color(0xFF38C98B) : const Color(0xFF08A85C);

    return Scaffold(
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [background, backgroundEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1187E8)
                              .withValues(alpha: dark ? 0.14 : 0.09),
                          blurRadius: 28,
                        ),
                        BoxShadow(
                          color: const Color(0xFF14BC6A)
                              .withValues(alpha: dark ? 0.12 : 0.08),
                          blurRadius: 34,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/branding/phytosense_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 21),
                  Text(
                    'PhytoSense AI',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: 148,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: signal,
                      backgroundColor: foreground.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.all(Radius.circular(99)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Card(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 46),
                      SizedBox(height: 14),
                      Text(
                        'PhytoSense AI could not start',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Close and reopen the app. Your locally saved records remain safe.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
