import 'package:flutter/widgets.dart';
import 'alert_service.dart';
import 'farm_repository.dart';
import 'engineering_evidence_service.dart';
import 'inspection_history_service.dart';
import 'offline_sync_service.dart';
import 'settings_service.dart';
import 'sensor_data_provider.dart';
import 'sensor_provider_manager.dart';
import 'voice_guidance_service.dart';
import 'weather_service.dart';

class AppScope extends InheritedWidget {
  final SettingsService settings;
  final FarmRepository farms;
  final SensorProviderManager sensorManager;
  final AlertService alerts;
  final WeatherService weather;
  final VoiceGuidanceService voice;
  final OfflineSyncService offlineSync;
  final EngineeringEvidenceService engineeringEvidence;
  final InspectionHistoryService inspectionHistory;

  SensorDataProvider get sensors => sensorManager;

  const AppScope({
    super.key,
    required this.settings,
    required this.farms,
    required this.sensorManager,
    required this.alerts,
    required this.weather,
    required this.voice,
    required this.offlineSync,
    required this.engineeringEvidence,
    required this.inspectionHistory,
    required super.child,
  });

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
