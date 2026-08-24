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
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'timestamp': timestamp.toIso8601String(),
        'soilMoisture': soilMoisture,
        'temperature': temperature,
        'humidity': humidity,
        'light': light,
        'plantSignal': plantSignal,
        'healthScore': healthScore,
        'stressScore': stressScore,
        'healthStatus': healthStatus,
      };

  factory SensorReading.fromJson(Map<String, dynamic> j) {
    final soil = _num(j['soilMoisture']);
    final temperature = _num(j['temperature']);
    final humidity = _num(j['humidity']);
    final light = _num(j['light']);
    final plantSignal = _numOr(j['plantSignal'], 50);
    final calculatedHealth = calculateHealth(
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: light,
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
    );
  }

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  static double _numOr(dynamic value, double fallback) {
    if (value == null) return fallback;
    return _num(value);
  }

  static double calculateHealth({
    required double soilMoisture,
    required double temperature,
    required double humidity,
    required double light,
  }) {
    var health = 100.0;
    health -= (soilMoisture - 62).abs() * 0.62;
    health -= (temperature - 25).abs() * 2.25;
    health -= (humidity - 58).abs() * 0.28;
    health -= (light - 68).abs() * 0.2;
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
      );

  double get vapourPressureDeficit {
    final saturation =
        0.6108 * math.exp((17.27 * temperature) / (temperature + 237.3));
    return saturation * (1 - humidity / 100);
  }
}
