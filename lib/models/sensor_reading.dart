import 'dart:math' as math;

class SensorReading {
  final String nodeId;
  final DateTime timestamp;
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final double light;
  final double plantSignal;
  final double healthScore;
  final double stressScore;
  final String healthStatus;

  /// Availability flags let early hardware prototypes expose only the sensors
  /// that are physically connected without presenting placeholder values as
  /// real measurements.
  final bool soilMoistureAvailable;
  final bool temperatureAvailable;
  final bool humidityAvailable;
  final bool lightAvailable;
  final bool plantSignalAvailable;

  const SensorReading({
    required this.nodeId,
    required this.timestamp,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.light,
    this.plantSignal = 50,
    required this.healthScore,
    required this.stressScore,
    required this.healthStatus,
    this.soilMoistureAvailable = true,
    this.temperatureAvailable = true,
    this.humidityAvailable = true,
    this.lightAvailable = true,
    this.plantSignalAvailable = true,
  });

  bool get hasFullCoreReading =>
      soilMoistureAvailable &&
      temperatureAvailable &&
      humidityAvailable &&
      lightAvailable;

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'timestamp': timestamp.toIso8601String(),
        'soilMoisture': soilMoistureAvailable ? soilMoisture : null,
        'temperature': temperatureAvailable ? temperature : null,
        'humidity': humidityAvailable ? humidity : null,
        'light': lightAvailable ? light : null,
        'plantSignal': plantSignalAvailable ? plantSignal : null,
        'healthScore': healthScore,
        'stressScore': stressScore,
        'healthStatus': healthStatus,
      };

  factory SensorReading.fromJson(Map<String, dynamic> j) {
    final soilAvailable = _available(j, 'soilMoisture');
    final temperatureAvailable = _available(j, 'temperature');
    final humidityAvailable = _available(j, 'humidity');
    final lightAvailable = _available(j, 'light');
    final plantSignalAvailable = _available(j, 'plantSignal');

    // Neutral placeholders are internal only and are never presented as live
    // measurements when the corresponding availability flag is false.
    final soil = soilAvailable ? _num(j['soilMoisture']) : 62.0;
    final temperature = temperatureAvailable ? _num(j['temperature']) : 25.0;
    final humidity = humidityAvailable ? _num(j['humidity']) : 58.0;
    final light = lightAvailable ? _num(j['light']) : 68.0;
    final plantSignal = plantSignalAvailable ? _num(j['plantSignal']) : 50.0;

    final calculatedHealth = calculateHealth(
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: light,
      soilMoistureAvailable: soilAvailable,
      temperatureAvailable: temperatureAvailable,
      humidityAvailable: humidityAvailable,
      lightAvailable: lightAvailable,
    );
    final health = j['healthScore'] == null
        ? calculatedHealth
        : _num(j['healthScore']).clamp(0, 100).toDouble();
    final stress = j['stressScore'] == null
        ? 100 - health
        : _num(j['stressScore']).clamp(0, 100).toDouble();

    return SensorReading(
      nodeId: '${j['nodeId'] ?? 'node-rice-a1'}',
      timestamp: DateTime.tryParse('${j['timestamp']}') ?? DateTime.now(),
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: light,
      plantSignal: plantSignal,
      healthScore: health,
      stressScore: stress,
      healthStatus: '${j['healthStatus'] ?? statusForHealth(health)}',
      soilMoistureAvailable: soilAvailable,
      temperatureAvailable: temperatureAvailable,
      humidityAvailable: humidityAvailable,
      lightAvailable: lightAvailable,
      plantSignalAvailable: plantSignalAvailable,
    );
  }

  static bool _available(Map<String, dynamic> j, String key) =>
      j.containsKey(key) && j[key] != null && _isNumber(j[key]);

  static bool _isNumber(dynamic value) {
    if (value is num) return value.isFinite;
    return double.tryParse('$value')?.isFinite ?? false;
  }

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  static double calculateHealth({
    required double soilMoisture,
    required double temperature,
    required double humidity,
    required double light,
    bool soilMoistureAvailable = true,
    bool temperatureAvailable = true,
    bool humidityAvailable = true,
    bool lightAvailable = true,
  }) {
    var health = 100.0;
    if (soilMoistureAvailable) {
      health -= (soilMoisture - 62).abs() * 0.62;
    }
    if (temperatureAvailable) {
      health -= (temperature - 25).abs() * 2.25;
    }
    if (humidityAvailable) {
      health -= (humidity - 58).abs() * 0.28;
    }
    if (lightAvailable) {
      health -= (light - 68).abs() * 0.2;
    }
    return health.clamp(0, 100).toDouble();
  }

  static String statusForHealth(double health) => health >= 82
      ? 'excellent'
      : health >= 65
          ? 'good'
          : health >= 42
              ? 'watch'
              : 'critical';

  SensorReading copyWith({
    String? nodeId,
    DateTime? timestamp,
    double? soilMoisture,
    double? temperature,
    double? humidity,
    double? light,
    double? plantSignal,
    double? healthScore,
    double? stressScore,
    String? healthStatus,
    bool? soilMoistureAvailable,
    bool? temperatureAvailable,
    bool? humidityAvailable,
    bool? lightAvailable,
    bool? plantSignalAvailable,
  }) =>
      SensorReading(
        nodeId: nodeId ?? this.nodeId,
        timestamp: timestamp ?? this.timestamp,
        soilMoisture: soilMoisture ?? this.soilMoisture,
        temperature: temperature ?? this.temperature,
        humidity: humidity ?? this.humidity,
        light: light ?? this.light,
        plantSignal: plantSignal ?? this.plantSignal,
        healthScore: healthScore ?? this.healthScore,
        stressScore: stressScore ?? this.stressScore,
        healthStatus: healthStatus ?? this.healthStatus,
        soilMoistureAvailable:
            soilMoistureAvailable ?? this.soilMoistureAvailable,
        temperatureAvailable: temperatureAvailable ?? this.temperatureAvailable,
        humidityAvailable: humidityAvailable ?? this.humidityAvailable,
        lightAvailable: lightAvailable ?? this.lightAvailable,
        plantSignalAvailable: plantSignalAvailable ?? this.plantSignalAvailable,
      );

  double get vapourPressureDeficit {
    final saturation =
        0.6108 * math.exp((17.27 * temperature) / (temperature + 237.3));
    return saturation * (1 - humidity / 100);
  }
}
