import 'dart:async';
import 'dart:math' as math;

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

class _StartupLoading extends StatefulWidget {
  const _StartupLoading();

  @override
  State<_StartupLoading> createState() => _StartupLoadingState();
}

class _StartupLoadingState extends State<_StartupLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF061017) : const Color(0xFFFFFFFF);
    final end = dark ? const Color(0xFF0B251E) : const Color(0xFFF0FAF5);
    final foreground = dark ? const Color(0xFFF6FCFF) : const Color(0xFF14323B);
    final muted = dark ? const Color(0xFF8298A1) : const Color(0xFF6E858E);

    return Scaffold(
      backgroundColor: background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = _controller.value;
          final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [background, end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: CustomPaint(
                    painter: _StartupPreludePainter(
                      phase: phase,
                      dark: dark,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 148,
                          height: 148,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 134 + pulse * 8,
                                height: 134 + pulse * 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2196F3)
                                        .withValues(alpha: 0.10 + pulse * 0.08),
                                  ),
                                ),
                              ),
                              Container(
                                width: 98,
                                height: 98,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2196F3)
                                          .withValues(alpha: 0.08 + pulse * 0.05),
                                      blurRadius: 28 + pulse * 10,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF16C96B)
                                          .withValues(alpha: 0.10 + pulse * 0.06),
                                      blurRadius: 34 + pulse * 12,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/branding/phytosense_icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'PhytoSense AI',
                          style: TextStyle(
                            color: foreground,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'INITIALIZING PLANT INTELLIGENCE',
                          style: TextStyle(
                            color: muted,
                            fontSize: 9.2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.65,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PreludeDot(
                              color: const Color(0xFF2196F3),
                              active: phase < 0.34,
                            ),
                            const SizedBox(width: 9),
                            _PreludeDot(
                              color: const Color(0xFF16C96B),
                              active: phase >= 0.34 && phase < 0.67,
                            ),
                            const SizedBox(width: 9),
                            _PreludeDot(
                              color: const Color(0xFFFFC107),
                              active: phase >= 0.67,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PreludeDot extends StatelessWidget {
  final Color color;
  final bool active;

  const _PreludeDot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: active ? 22 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 0.95 : 0.28),
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.26), blurRadius: 7)]
              : const [],
        ),
      );
}

class _StartupPreludePainter extends CustomPainter {
  final double phase;
  final bool dark;

  const _StartupPreludePainter({required this.phase, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = (dark ? Colors.white : const Color(0xFF173C47))
          .withValues(alpha: dark ? 0.035 : 0.028);
    const gap = 42.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final scanX = size.width * phase;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF16C96B).withValues(alpha: dark ? 0.16 : 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(scanX - 35, 0, 70, size.height));
    canvas.drawRect(Rect.fromLTWH(scanX - 35, 0, 70, size.height), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _StartupPreludePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.dark != dark;
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
