enum DemoMode {
  healthy,
  dry,
  overwatered,
  heatStress,
  lowLight,
  critical,
  offline,
  sensorFault,
}

extension DemoModeLabel on DemoMode {
  String get label => switch (this) {
    DemoMode.healthy => 'Healthy',
    DemoMode.dry => 'Dry',
    DemoMode.overwatered => 'Overwatered',
    DemoMode.heatStress => 'Heat Stress',
    DemoMode.lowLight => 'Low Light',
    DemoMode.critical => 'Critical',
    DemoMode.offline => 'Offline',
    DemoMode.sensorFault => 'Sensor fault',
  };

  String get id => switch (this) {
    DemoMode.healthy => 'healthy',
    DemoMode.dry => 'dry',
    DemoMode.overwatered => 'overwatered',
    DemoMode.heatStress => 'heat_stress',
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
      soilMoisture: 40,
      temperature: 34,
      humidity: 30,
      light: 85,
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
      soilMoisture: 0,
      temperature: 0,
      humidity: 0,
      light: 0,
    ),
  };
}
