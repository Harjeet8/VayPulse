import 'dart:math' as math;

class SensorReading {
  final String nodeId;
  final DateTime timestamp;

  /// Calibrated soil-sensor scale (0-100). This is not laboratory VWC.
  final double soilMoisture;
  final double temperature;
  final double humidity;

  /// Legacy normalized light value retained for existing charts/cards.
  final double light;
  final double? lightLux;
  final double? soilTemperature;
  final double? leafWetness;

  /// 0-100 bioelectric stability/response index for legacy UI compatibility.
  final double plantSignal;
  final double? plantVoltageMv;

  /// Main app-side PhytoSense Health Index.
  final double healthScore;
  final double stressScore;
  final String healthStatus;
  final double analysisConfidence;

  /// Embedded ESP32 health output is kept separately for diagnostics.
  final double? esp32HealthScore;
  final double? esp32HealthConfidence;

  final double? waterScore;
  final double? thermalScore;
  final double? rootZoneScore;
  final double? atmosphericScore;
  final double? lightScore;
  final double? diseaseRisk;
  final double? bioelectricStability;

  final int? soilRaw;
  final int? leafRaw;
  final bool soilCalibrated;
  final bool leafCalibrated;
  final bool daytime;
  final double leafWetDurationSeconds;
  final double recentWetExposureSeconds;
  final bool bioBaselineReady;
  final int bioBaselineSamples;
  final double? bioBaselineMv;
  final double? bioDeviationMv;
  final double? bioNoiseMv;
  final double bioSignalQuality;

  final bool soilMoistureAvailable;
  final bool temperatureAvailable;
  final bool humidityAvailable;
  final bool lightAvailable;
  final bool soilTemperatureAvailable;
  final bool leafWetnessAvailable;
  final bool plantSignalAvailable;

  const SensorReading({
    required this.nodeId,
    required this.timestamp,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.light,
    this.lightLux,
    this.soilTemperature,
    this.leafWetness,
    this.plantSignal = 50,
    this.plantVoltageMv,
    required this.healthScore,
    required this.stressScore,
    required this.healthStatus,
    this.analysisConfidence = 0,
    this.esp32HealthScore,
    this.esp32HealthConfidence,
    this.waterScore,
    this.thermalScore,
    this.rootZoneScore,
    this.atmosphericScore,
    this.lightScore,
    this.diseaseRisk,
    this.bioelectricStability,
    this.soilRaw,
    this.leafRaw,
    this.soilCalibrated = false,
    this.leafCalibrated = false,
    this.daytime = true,
    this.leafWetDurationSeconds = 0,
    this.recentWetExposureSeconds = 0,
    this.bioBaselineReady = false,
    this.bioBaselineSamples = 0,
    this.bioBaselineMv,
    this.bioDeviationMv,
    this.bioNoiseMv,
    this.bioSignalQuality = 0,
    this.soilMoistureAvailable = true,
    this.temperatureAvailable = true,
    this.humidityAvailable = true,
    this.lightAvailable = true,
    this.soilTemperatureAvailable = false,
    this.leafWetnessAvailable = false,
    this.plantSignalAvailable = true,
  });

  bool get hasFullCoreReading =>
      soilMoistureAvailable &&
      temperatureAvailable &&
      humidityAvailable &&
      lightAvailable;

  int get availableChannelCount => <bool>[
        soilMoistureAvailable,
        temperatureAvailable,
        humidityAvailable,
        lightAvailable,
        soilTemperatureAvailable,
        leafWetnessAvailable,
        plantSignalAvailable,
      ].where((value) => value).length;

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'timestamp': timestamp.toIso8601String(),
        'soilMoisture': soilMoistureAvailable ? soilMoisture : null,
        'temperature': temperatureAvailable ? temperature : null,
        'humidity': humidityAvailable ? humidity : null,
        'light': lightAvailable ? light : null,
        'lightLux': lightAvailable ? lightLux : null,
        'soilTemperature': soilTemperatureAvailable ? soilTemperature : null,
        'leafWetness': leafWetnessAvailable ? leafWetness : null,
        'plantSignal': plantSignalAvailable ? plantSignal : null,
        'plantVoltageMv': plantSignalAvailable ? plantVoltageMv : null,
        'healthScore': healthScore,
        'stressScore': stressScore,
        'healthStatus': healthStatus,
        'analysisConfidence': analysisConfidence,
        'esp32HealthScore': esp32HealthScore,
        'esp32HealthConfidence': esp32HealthConfidence,
        'waterScore': waterScore,
        'thermalScore': thermalScore,
        'rootZoneScore': rootZoneScore,
        'atmosphericScore': atmosphericScore,
        'lightScore': lightScore,
        'diseaseRisk': diseaseRisk,
        'bioelectricStability': bioelectricStability,
        'soilRaw': soilRaw,
        'leafRaw': leafRaw,
        'soilCalibrated': soilCalibrated,
        'leafCalibrated': leafCalibrated,
        'daytime': daytime,
        'leafWetDurationSeconds': leafWetDurationSeconds,
        'recentWetExposureSeconds': recentWetExposureSeconds,
        'bioBaselineReady': bioBaselineReady,
        'bioBaselineSamples': bioBaselineSamples,
        'bioBaselineMv': bioBaselineMv,
        'bioDeviationMv': bioDeviationMv,
        'bioNoiseMv': bioNoiseMv,
        'bioSignalQuality': bioSignalQuality,
      };

  factory SensorReading.fromJson(Map<String, dynamic> j) {
    final soilAvailable = _available(j, 'soilMoisture');
    final temperatureAvailable = _available(j, 'temperature');
    final humidityAvailable = _available(j, 'humidity');
    final lightAvailable = _available(j, 'light');
    final soilTemperatureAvailable = _available(j, 'soilTemperature');
    final leafWetnessAvailable = _available(j, 'leafWetness');
    final plantSignalAvailable =
        _available(j, 'plantSignal') || _available(j, 'plantVoltageMv');

    final soil = soilAvailable ? _num(j['soilMoisture']) : 62.0;
    final temperature =
        temperatureAvailable ? _num(j['temperature']) : 25.0;
    final humidity = humidityAvailable ? _num(j['humidity']) : 58.0;
    final light = lightAvailable ? _num(j['light']) : 68.0;
    final plantSignal = _available(j, 'plantSignal')
        ? _num(j['plantSignal'])
        : (_available(j, 'bioelectricStability')
            ? _num(j['bioelectricStability'])
            : 50.0);

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
      nodeId: '${j['nodeId'] ?? 'phytosense-live-01'}',
      timestamp: DateTime.tryParse('${j['timestamp']}') ?? DateTime.now(),
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: light,
      lightLux: _nullableNum(j['lightLux']),
      soilTemperature: _nullableNum(j['soilTemperature']),
      leafWetness: _nullableNum(j['leafWetness']),
      plantSignal: plantSignal.clamp(0, 100).toDouble(),
      plantVoltageMv: _nullableNum(j['plantVoltageMv']),
      healthScore: health,
      stressScore: stress,
      healthStatus: '${j['healthStatus'] ?? statusForHealth(health)}',
      analysisConfidence:
          (_nullableNum(j['analysisConfidence']) ?? 0).clamp(0, 100),
      esp32HealthScore: _nullableNum(j['esp32HealthScore']),
      esp32HealthConfidence: _nullableNum(j['esp32HealthConfidence']),
      waterScore: _nullableNum(j['waterScore']),
      thermalScore: _nullableNum(j['thermalScore']),
      rootZoneScore: _nullableNum(j['rootZoneScore']),
      atmosphericScore: _nullableNum(j['atmosphericScore']),
      lightScore: _nullableNum(j['lightScore']),
      diseaseRisk: _nullableNum(j['diseaseRisk']),
      bioelectricStability: _nullableNum(j['bioelectricStability']),
      soilRaw: _nullableInt(j['soilRaw']),
      leafRaw: _nullableInt(j['leafRaw']),
      soilCalibrated: j['soilCalibrated'] == true,
      leafCalibrated: j['leafCalibrated'] == true,
      daytime: j['daytime'] != false,
      leafWetDurationSeconds: _nullableNum(j['leafWetDurationSeconds']) ?? 0,
      recentWetExposureSeconds:
          _nullableNum(j['recentWetExposureSeconds']) ?? 0,
      bioBaselineReady: j['bioBaselineReady'] == true,
      bioBaselineSamples: _nullableInt(j['bioBaselineSamples']) ?? 0,
      bioBaselineMv: _nullableNum(j['bioBaselineMv']),
      bioDeviationMv: _nullableNum(j['bioDeviationMv']),
      bioNoiseMv: _nullableNum(j['bioNoiseMv']),
      bioSignalQuality:
          (_nullableNum(j['bioSignalQuality']) ?? 0).clamp(0, 100),
      soilMoistureAvailable: soilAvailable,
      temperatureAvailable: temperatureAvailable,
      humidityAvailable: humidityAvailable,
      lightAvailable: lightAvailable,
      soilTemperatureAvailable: soilTemperatureAvailable,
      leafWetnessAvailable: leafWetnessAvailable,
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

  static double? _nullableNum(dynamic value) {
    if (value == null) return null;
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed?.isFinite == true ? parsed : null;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    return value is num ? value.toInt() : int.tryParse('$value');
  }

  /// Legacy fallback used by old persisted/simulation data only. Live and new
  /// simulation readings are re-analysed by HealthAnalysisEngine.
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
    var weighted = 0.0;
    var weight = 0.0;
    void add(double score, double w, bool available) {
      if (!available) return;
      weighted += score.clamp(0, 100) * w;
      weight += w;
    }

    add(100 - (soilMoisture - 62).abs() * 1.2, 0.4, soilMoistureAvailable);
    add(100 - (temperature - 25).abs() * 4.0, 0.3, temperatureAvailable);
    add(100 - (humidity - 60).abs() * 1.1, 0.2, humidityAvailable);
    add(100 - (light - 65).abs() * 0.8, 0.1, lightAvailable);
    return weight == 0 ? 50 : (weighted / weight).clamp(0, 100).toDouble();
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
    double? lightLux,
    double? soilTemperature,
    double? leafWetness,
    double? plantSignal,
    double? plantVoltageMv,
    double? healthScore,
    double? stressScore,
    String? healthStatus,
    double? analysisConfidence,
    double? esp32HealthScore,
    double? esp32HealthConfidence,
    double? waterScore,
    double? thermalScore,
    double? rootZoneScore,
    double? atmosphericScore,
    double? lightScore,
    double? diseaseRisk,
    double? bioelectricStability,
    int? soilRaw,
    int? leafRaw,
    bool? soilCalibrated,
    bool? leafCalibrated,
    bool? daytime,
    double? leafWetDurationSeconds,
    double? recentWetExposureSeconds,
    bool? bioBaselineReady,
    int? bioBaselineSamples,
    double? bioBaselineMv,
    double? bioDeviationMv,
    double? bioNoiseMv,
    double? bioSignalQuality,
    bool? soilMoistureAvailable,
    bool? temperatureAvailable,
    bool? humidityAvailable,
    bool? lightAvailable,
    bool? soilTemperatureAvailable,
    bool? leafWetnessAvailable,
    bool? plantSignalAvailable,
  }) =>
      SensorReading(
        nodeId: nodeId ?? this.nodeId,
        timestamp: timestamp ?? this.timestamp,
        soilMoisture: soilMoisture ?? this.soilMoisture,
        temperature: temperature ?? this.temperature,
        humidity: humidity ?? this.humidity,
        light: light ?? this.light,
        lightLux: lightLux ?? this.lightLux,
        soilTemperature: soilTemperature ?? this.soilTemperature,
        leafWetness: leafWetness ?? this.leafWetness,
        plantSignal: plantSignal ?? this.plantSignal,
        plantVoltageMv: plantVoltageMv ?? this.plantVoltageMv,
        healthScore: healthScore ?? this.healthScore,
        stressScore: stressScore ?? this.stressScore,
        healthStatus: healthStatus ?? this.healthStatus,
        analysisConfidence: analysisConfidence ?? this.analysisConfidence,
        esp32HealthScore: esp32HealthScore ?? this.esp32HealthScore,
        esp32HealthConfidence:
            esp32HealthConfidence ?? this.esp32HealthConfidence,
        waterScore: waterScore ?? this.waterScore,
        thermalScore: thermalScore ?? this.thermalScore,
        rootZoneScore: rootZoneScore ?? this.rootZoneScore,
        atmosphericScore: atmosphericScore ?? this.atmosphericScore,
        lightScore: lightScore ?? this.lightScore,
        diseaseRisk: diseaseRisk ?? this.diseaseRisk,
        bioelectricStability:
            bioelectricStability ?? this.bioelectricStability,
        soilRaw: soilRaw ?? this.soilRaw,
        leafRaw: leafRaw ?? this.leafRaw,
        soilCalibrated: soilCalibrated ?? this.soilCalibrated,
        leafCalibrated: leafCalibrated ?? this.leafCalibrated,
        daytime: daytime ?? this.daytime,
        leafWetDurationSeconds:
            leafWetDurationSeconds ?? this.leafWetDurationSeconds,
        recentWetExposureSeconds:
            recentWetExposureSeconds ?? this.recentWetExposureSeconds,
        bioBaselineReady: bioBaselineReady ?? this.bioBaselineReady,
        bioBaselineSamples: bioBaselineSamples ?? this.bioBaselineSamples,
        bioBaselineMv: bioBaselineMv ?? this.bioBaselineMv,
        bioDeviationMv: bioDeviationMv ?? this.bioDeviationMv,
        bioNoiseMv: bioNoiseMv ?? this.bioNoiseMv,
        bioSignalQuality: bioSignalQuality ?? this.bioSignalQuality,
        soilMoistureAvailable:
            soilMoistureAvailable ?? this.soilMoistureAvailable,
        temperatureAvailable:
            temperatureAvailable ?? this.temperatureAvailable,
        humidityAvailable: humidityAvailable ?? this.humidityAvailable,
        lightAvailable: lightAvailable ?? this.lightAvailable,
        soilTemperatureAvailable:
            soilTemperatureAvailable ?? this.soilTemperatureAvailable,
        leafWetnessAvailable:
            leafWetnessAvailable ?? this.leafWetnessAvailable,
        plantSignalAvailable:
            plantSignalAvailable ?? this.plantSignalAvailable,
      );

  double get vapourPressureDeficit {
    final saturation =
        0.6108 * math.exp((17.27 * temperature) / (temperature + 237.3));
    return saturation * (1 - humidity / 100);
  }
}
