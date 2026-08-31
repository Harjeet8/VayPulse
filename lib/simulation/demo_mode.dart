enum DemoMode {
  healthy,
  baselineLearning,
  atmosphericDrying,
  dry,
  overwatered,
  heatStress,
  bioResponse,
  recovery,
  bioticRisk,
  lowLight,
  critical,
  offline,
  sensorFault,
}

extension DemoModeLabel on DemoMode {
  String get label => switch (this) {
        DemoMode.healthy => 'Healthy',
        DemoMode.baselineLearning => 'Baseline learning',
        DemoMode.atmosphericDrying => 'Atmospheric drying',
        DemoMode.dry => 'Dry',
        DemoMode.overwatered => 'Overwatered',
        DemoMode.heatStress => 'Heat Stress',
        DemoMode.bioResponse => 'Plant response',
        DemoMode.recovery => 'Recovery',
        DemoMode.bioticRisk => 'Biotic-risk environment',
        DemoMode.lowLight => 'Low Light',
        DemoMode.critical => 'Critical',
        DemoMode.offline => 'Offline',
        DemoMode.sensorFault => 'Sensor fault',
      };

  String get id => switch (this) {
        DemoMode.healthy => 'healthy',
        DemoMode.baselineLearning => 'baseline_learning',
        DemoMode.atmosphericDrying => 'atmospheric_drying',
        DemoMode.dry => 'dry',
        DemoMode.overwatered => 'overwatered',
        DemoMode.heatStress => 'heat_stress',
        DemoMode.bioResponse => 'bio_response',
        DemoMode.recovery => 'recovery',
        DemoMode.bioticRisk => 'biotic_risk',
        DemoMode.lowLight => 'low_light',
        DemoMode.critical => 'critical',
        DemoMode.offline => 'offline',
        DemoMode.sensorFault => 'sensor_fault',
      };

  static DemoMode fromId(String id) => DemoMode.values.firstWhere(
        (mode) => mode.id == id,
        orElse: () => DemoMode.healthy,
      );
}

class DemoModeTargets {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final double light;

  const DemoModeTargets({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.light,
  });

  static const values = {
    DemoMode.healthy: DemoModeTargets(
      soilMoisture: 62,
      temperature: 24,
      humidity: 55,
      light: 68,
    ),
    DemoMode.baselineLearning: DemoModeTargets(
      soilMoisture: 63,
      temperature: 24.5,
      humidity: 57,
      light: 66,
    ),
    DemoMode.atmosphericDrying: DemoModeTargets(
      soilMoisture: 61,
      temperature: 33,
      humidity: 29,
      light: 82,
    ),
    DemoMode.dry: DemoModeTargets(
      soilMoisture: 18,
      temperature: 26,
      humidity: 35,
      light: 70,
    ),
    DemoMode.overwatered: DemoModeTargets(
      soilMoisture: 92,
      temperature: 22,
      humidity: 70,
      light: 55,
    ),
    DemoMode.heatStress: DemoModeTargets(
      soilMoisture: 48,
      temperature: 35,
      humidity: 32,
      light: 85,
    ),
    DemoMode.bioResponse: DemoModeTargets(
      soilMoisture: 58,
      temperature: 29,
      humidity: 48,
      light: 72,
    ),
    DemoMode.recovery: DemoModeTargets(
      soilMoisture: 57,
      temperature: 27,
      humidity: 52,
      light: 64,
    ),
    DemoMode.bioticRisk: DemoModeTargets(
      soilMoisture: 72,
      temperature: 26,
      humidity: 88,
      light: 48,
    ),
    DemoMode.lowLight: DemoModeTargets(
      soilMoisture: 58,
      temperature: 21,
      humidity: 60,
      light: 15,
    ),
    DemoMode.critical: DemoModeTargets(
      soilMoisture: 8,
      temperature: 37,
      humidity: 20,
      light: 90,
    ),
    DemoMode.offline: DemoModeTargets(
      soilMoisture: 52,
      temperature: 25,
      humidity: 51,
      light: 64,
    ),
    DemoMode.sensorFault: DemoModeTargets(
      soilMoisture: 54,
      temperature: 26,
      humidity: 58,
      light: 62,
    ),
  };
}
