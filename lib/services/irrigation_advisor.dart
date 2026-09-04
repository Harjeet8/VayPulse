import '../models/sensor_reading.dart';
import '../models/weather_snapshot.dart';

enum IrrigationPriority { none, watch, irrigate, urgent }

class IrrigationAdvice {
  final String titleKey;
  final String bodyKey;
  final String actionKey;
  final String evidenceKey;
  final IrrigationPriority priority;

  const IrrigationAdvice({
    required this.titleKey,
    required this.bodyKey,
    required this.actionKey,
    required this.evidenceKey,
    required this.priority,
  });
}

class IrrigationAdvisor {
  static IrrigationAdvice advise(
    SensorReading? reading,
    WeatherSnapshot? weather, {
    String cropStage = '',
    String crop = '',
  }) {
    if (reading == null) {
      return const IrrigationAdvice(
        titleKey: 'irrigation_waiting',
        bodyKey: 'irrigation_waiting_body',
        actionKey: 'irrigation_waiting_action',
        evidenceKey: 'irrigation_no_sensor_evidence',
        priority: IrrigationPriority.watch,
      );
    }
    final rainSoon =
        weather?.forecast
            .take(2)
            .any(
              (day) =>
                  day.precipitationProbability >= 70 ||
                  day.precipitationMillimetres >= 8,
            ) ??
        false;
    if (rainSoon && reading.soilMoisture >= 24) {
      return const IrrigationAdvice(
        titleKey: 'irrigation_delay',
        bodyKey: 'irrigation_delay_body',
        actionKey: 'irrigation_delay_action',
        evidenceKey: 'irrigation_rain_evidence',
        priority: IrrigationPriority.none,
      );
    }
    if (reading.soilMoisture < 18) {
      return const IrrigationAdvice(
        titleKey: 'irrigation_urgent',
        bodyKey: 'irrigation_urgent_body',
        actionKey: 'irrigation_urgent_action',
        evidenceKey: 'irrigation_dry_evidence',
        priority: IrrigationPriority.urgent,
      );
    }
    final preferredMinimum = switch (cropStage) {
      'Seedling' || 'Flowering' || 'Fruit set' => 38.0,
      'Maturity' => 28.0,
      _ => 32.0,
    };
    if (reading.soilMoisture < preferredMinimum) {
      return const IrrigationAdvice(
        titleKey: 'irrigation_recommended',
        bodyKey: 'irrigation_recommended_body',
        actionKey: 'irrigation_recommended_action',
        evidenceKey: 'irrigation_low_evidence',
        priority: IrrigationPriority.irrigate,
      );
    }
    final cropName = crop.toLowerCase();
    final isFloodedRice =
        cropName.contains('rice') || cropName.contains('paddy');
    if (reading.soilMoisture > 86 && isFloodedRice) {
      return const IrrigationAdvice(
        titleKey: 'irrigation_paddy_water',
        bodyKey: 'irrigation_paddy_water_body',
        actionKey: 'irrigation_paddy_water_action',
        evidenceKey: 'irrigation_paddy_water_evidence',
        priority: IrrigationPriority.none,
      );
    }
    if (reading.soilMoisture > 86) {
      return const IrrigationAdvice(
        titleKey: 'irrigation_stop',
        bodyKey: 'irrigation_stop_body',
        actionKey: 'irrigation_stop_action',
        evidenceKey: 'irrigation_wet_evidence',
        priority: IrrigationPriority.watch,
      );
    }
    return const IrrigationAdvice(
      titleKey: 'irrigation_balanced',
      bodyKey: 'irrigation_balanced_body',
      actionKey: 'irrigation_balanced_action',
      evidenceKey: 'irrigation_balanced_evidence',
      priority: IrrigationPriority.none,
    );
  }
}
