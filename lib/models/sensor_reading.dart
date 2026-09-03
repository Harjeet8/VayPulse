import 'dart:math' as math;

class SensorReading {
  final String nodeId;
  final DateTime timestamp;
  final double soilMoisture;
  final double temperature;
  final double humidity;

  /// Legacy normalized light (0-100) retained for existing cards/charts.
  final double light;
  final double? lightLux;
  final double? soilTemperature;
  final double? leafWetness;

  /// Legacy 0-100 plant-signal display value. In the SUPREME pipeline this is
  /// bioelectric stability, not raw electrode voltage.
  final double plantSignal;
  final double? plantVoltageMv;
  final String bioSource;

  /// Main decision-support index. In ESP32 hardware mode this comes from the
  /// edge firmware; simulation can continue using its own provider engine.
  final double healthScore;
  final double stressScore;
  final String healthStatus;
  final double analysisConfidence;
  final bool edgeAnalysisAvailable;
  final String crop;
  final String growthStage;
  final String reliabilityMode;
  final String systemStatus;
  final String recoveryStatus;
  final String primaryRootCause;
  final String farmerAction;
  final double? rootCauseConfidence;
  final List<String> rankedRootCauses;
  final String bioticState;
  final String bioState;
  final bool cameraRecommended;
  final String cameraReason;
  final Map<String, String> sensorStates;

  /// Embedded firmware result retained for diagnostics/comparison.
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
    this.bioSource = 'real',
    required this.healthScore,
    required this.stressScore,
    required this.healthStatus,
    this.analysisConfidence = 0,
    this.edgeAnalysisAvailable = true,
    this.crop = 'Universal',
    this.growthStage = 'Vegetative',
    this.reliabilityMode = 'FULL',
    this.systemStatus = '',
    this.recoveryStatus = '',
    this.primaryRootCause = '',
    this.farmerAction = '',
    this.rootCauseConfidence,
    this.rankedRootCauses = const <String>[],
    this.bioticState = '',
    this.bioState = '',
    this.cameraRecommended = false,
    this.cameraReason = '',
    this.sensorStates = const <String, String>{},
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

  bool get bioIsRealtime => bioSource.toLowerCase() == 'realtime';

  bool get bioIsLiveReading => bioSource.toLowerCase() == 'real';

  String get bioSourceLabel => bioIsRealtime
      ? 'Real Time Signal'
      : bioIsLiveReading
          ? 'Live Readings'
          : bioSource;

  bool get isReliabilityFull => reliabilityMode.toUpperCase() == 'FULL';

  bool get isReliabilityDegraded => reliabilityMode.toUpperCase() == 'DEGRADED';

  bool get isReliabilityRecovering =>
      reliabilityMode.toUpperCase() == 'RECOVERING';

  int get availableChannelCount => <bool>[
        soilMoistureAvailable,
        temperatureAvailable,
        humidityAvailable,
        lightAvailable,
        soilTemperatureAvailable,
        leafWetnessAvailable,
        plantSignalAvailable,
      ].where((value) => value).length;

  Map<String, dynamic> toJson() => <String, dynamic>{
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
        'bioSource': bioSource,
        'healthScore': healthScore,
        'stressScore': stressScore,
        'healthStatus': healthStatus,
        'analysisConfidence': analysisConfidence,
        'edgeAnalysisAvailable': edgeAnalysisAvailable,
        'crop': crop,
        'growthStage': growthStage,
        'reliabilityMode': reliabilityMode,
        'systemStatus': systemStatus,
        'recoveryStatus': recoveryStatus,
        'primaryRootCause': primaryRootCause,
        'farmerAction': farmerAction,
        'rootCauseConfidence': rootCauseConfidence,
        'rankedRootCauses': rankedRootCauses,
        'bioticState': bioticState,
        'bioState': bioState,
        'cameraRecommended': cameraRecommended,
        'cameraReason': cameraReason,
        'sensorStates': sensorStates,
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

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    final soilAvailable = _available(json, 'soilMoisture');
    final temperatureAvailable = _available(json, 'temperature');
    final humidityAvailable = _available(json, 'humidity');
    final lightAvailable = _available(json, 'light');
    final soilTemperatureAvailable = _available(json, 'soilTemperature');
    final leafWetnessAvailable = _available(json, 'leafWetness');
    final plantSignalAvailable =
        _available(json, 'plantSignal') || _available(json, 'plantVoltageMv');

    final soil = soilAvailable ? _num(json['soilMoisture']) : 62.0;
    final temperature = temperatureAvailable ? _num(json['temperature']) : 25.0;
    final humidity = humidityAvailable ? _num(json['humidity']) : 58.0;
    final light = lightAvailable ? _num(json['light']) : 68.0;
    final plantSignal = _available(json, 'plantSignal')
        ? _num(json['plantSignal'])
        : (_available(json, 'bioelectricStability')
            ? _num(json['bioelectricStability'])
            : 50.0);

    final fallbackHealth = calculateHealth(
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: light,
      soilMoistureAvailable: soilAvailable,
      temperatureAvailable: temperatureAvailable,
      humidityAvailable: humidityAvailable,
      lightAvailable: lightAvailable,
    );
    final health = json['healthScore'] == null
        ? fallbackHealth
        : _bounded(_num(json['healthScore']));
    final stress = json['stressScore'] == null
        ? 100.0 - health
        : _bounded(_num(json['stressScore']));

    return SensorReading(
      nodeId: '${json['nodeId'] ?? 'PHYTO-NODE-001'}',
      timestamp: DateTime.tryParse('${json['timestamp']}') ?? DateTime.now(),
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: light,
      lightLux: _nullableNum(json['lightLux']),
      soilTemperature: _nullableNum(json['soilTemperature']),
      leafWetness: _nullableNum(json['leafWetness']),
      plantSignal: _bounded(plantSignal),
      plantVoltageMv: _nullableNum(json['plantVoltageMv']),
      bioSource: '${json['bioSource'] ?? 'real'}',
      healthScore: health,
      stressScore: stress,
      healthStatus: '${json['healthStatus'] ?? statusForHealth(health)}',
      analysisConfidence: _bounded(
        _nullableNum(json['analysisConfidence']) ?? 0,
      ),
      edgeAnalysisAvailable: json['edgeAnalysisAvailable'] != false,
      crop: '${json['crop'] ?? 'Universal'}',
      growthStage: '${json['growthStage'] ?? 'Vegetative'}',
      reliabilityMode: '${json['reliabilityMode'] ?? 'FULL'}'.toUpperCase(),
      systemStatus: '${json['systemStatus'] ?? ''}',
      recoveryStatus: '${json['recoveryStatus'] ?? ''}',
      primaryRootCause: '${json['primaryRootCause'] ?? ''}',
      farmerAction: '${json['farmerAction'] ?? ''}',
      rootCauseConfidence: _nullableNum(json['rootCauseConfidence']),
      rankedRootCauses: _stringList(json['rankedRootCauses']),
      bioticState: '${json['bioticState'] ?? ''}',
      bioState: '${json['bioState'] ?? ''}',
      cameraRecommended: json['cameraRecommended'] == true,
      cameraReason: '${json['cameraReason'] ?? ''}',
      sensorStates: _stringMap(json['sensorStates']),
      esp32HealthScore: _nullableNum(json['esp32HealthScore']),
      esp32HealthConfidence: _nullableNum(json['esp32HealthConfidence']),
      waterScore: _nullableNum(json['waterScore']),
      thermalScore: _nullableNum(json['thermalScore']),
      rootZoneScore: _nullableNum(json['rootZoneScore']),
      atmosphericScore: _nullableNum(json['atmosphericScore']),
      lightScore: _nullableNum(json['lightScore']),
      diseaseRisk: _nullableNum(json['diseaseRisk']),
      bioelectricStability: _nullableNum(json['bioelectricStability']),
      soilRaw: _nullableInt(json['soilRaw']),
      leafRaw: _nullableInt(json['leafRaw']),
      soilCalibrated: json['soilCalibrated'] == true,
      leafCalibrated: json['leafCalibrated'] == true,
      daytime: json['daytime'] != false,
      leafWetDurationSeconds: _nullableNum(json['leafWetDurationSeconds']) ?? 0,
      recentWetExposureSeconds:
          _nullableNum(json['recentWetExposureSeconds']) ?? 0,
      bioBaselineReady: json['bioBaselineReady'] == true,
      bioBaselineSamples: _nullableInt(json['bioBaselineSamples']) ?? 0,
      bioBaselineMv: _nullableNum(json['bioBaselineMv']),
      bioDeviationMv: _nullableNum(json['bioDeviationMv']),
      bioNoiseMv: _nullableNum(json['bioNoiseMv']),
      bioSignalQuality: _bounded(_nullableNum(json['bioSignalQuality']) ?? 0),
      soilMoistureAvailable: soilAvailable,
      temperatureAvailable: temperatureAvailable,
      humidityAvailable: humidityAvailable,
      lightAvailable: lightAvailable,
      soilTemperatureAvailable: soilTemperatureAvailable,
      leafWetnessAvailable: leafWetnessAvailable,
      plantSignalAvailable: plantSignalAvailable,
    );
  }

  static bool _available(Map<String, dynamic> json, String key) =>
      json.containsKey(key) && json[key] != null && _isNumber(json[key]);

  static bool _isNumber(dynamic value) {
    if (value is num) return value.isFinite;
    return double.tryParse('$value')?.isFinite ?? false;
  }

  static double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static double? _nullableNum(dynamic value) {
    if (value == null) return null;
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed?.isFinite == true ? parsed : null;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    return value is num ? value.toInt() : int.tryParse('$value');
  }

  static List<String> _stringList(dynamic value) => value is List
      ? value.map((item) => '$item').where((item) => item.isNotEmpty).toList()
      : const <String>[];

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return const <String, String>{};
    return value.map((key, item) => MapEntry('$key', '$item'));
  }

  static double _bounded(double value) => value.clamp(0.0, 100.0).toDouble();

  /// Compatibility fallback for old persisted data. Current ESP32 hardware
  /// values already include the edge-computed health score.
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
    var usedWeight = 0.0;

    void add(double score, double weight, bool available) {
      if (!available) return;
      weighted += _bounded(score) * weight;
      usedWeight += weight;
    }

    add(100 - (soilMoisture - 62).abs() * 1.2, 0.4, soilMoistureAvailable);
    add(100 - (temperature - 25).abs() * 4.0, 0.3, temperatureAvailable);
    add(100 - (humidity - 60).abs() * 1.1, 0.2, humidityAvailable);
    add(100 - (light - 65).abs() * 0.8, 0.1, lightAvailable);
    return usedWeight == 0
        ? 50.0
        : (weighted / usedWeight).clamp(0.0, 100.0).toDouble();
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
    String? bioSource,
    double? healthScore,
    double? stressScore,
    String? healthStatus,
    double? analysisConfidence,
    bool? edgeAnalysisAvailable,
    String? crop,
    String? growthStage,
    String? reliabilityMode,
    String? systemStatus,
    String? recoveryStatus,
    String? primaryRootCause,
    String? farmerAction,
    double? rootCauseConfidence,
    List<String>? rankedRootCauses,
    String? bioticState,
    String? bioState,
    bool? cameraRecommended,
    String? cameraReason,
    Map<String, String>? sensorStates,
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
  }) {
    return SensorReading(
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
      bioSource: bioSource ?? this.bioSource,
      healthScore: healthScore ?? this.healthScore,
      stressScore: stressScore ?? this.stressScore,
      healthStatus: healthStatus ?? this.healthStatus,
      analysisConfidence: analysisConfidence ?? this.analysisConfidence,
      edgeAnalysisAvailable:
          edgeAnalysisAvailable ?? this.edgeAnalysisAvailable,
      crop: crop ?? this.crop,
      growthStage: growthStage ?? this.growthStage,
      reliabilityMode: reliabilityMode ?? this.reliabilityMode,
      systemStatus: systemStatus ?? this.systemStatus,
      recoveryStatus: recoveryStatus ?? this.recoveryStatus,
      primaryRootCause: primaryRootCause ?? this.primaryRootCause,
      farmerAction: farmerAction ?? this.farmerAction,
      rootCauseConfidence: rootCauseConfidence ?? this.rootCauseConfidence,
      rankedRootCauses: rankedRootCauses ?? this.rankedRootCauses,
      bioticState: bioticState ?? this.bioticState,
      bioState: bioState ?? this.bioState,
      cameraRecommended: cameraRecommended ?? this.cameraRecommended,
      cameraReason: cameraReason ?? this.cameraReason,
      sensorStates: sensorStates ?? this.sensorStates,
      esp32HealthScore: esp32HealthScore ?? this.esp32HealthScore,
      esp32HealthConfidence:
          esp32HealthConfidence ?? this.esp32HealthConfidence,
      waterScore: waterScore ?? this.waterScore,
      thermalScore: thermalScore ?? this.thermalScore,
      rootZoneScore: rootZoneScore ?? this.rootZoneScore,
      atmosphericScore: atmosphericScore ?? this.atmosphericScore,
      lightScore: lightScore ?? this.lightScore,
      diseaseRisk: diseaseRisk ?? this.diseaseRisk,
      bioelectricStability: bioelectricStability ?? this.bioelectricStability,
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
      temperatureAvailable: temperatureAvailable ?? this.temperatureAvailable,
      humidityAvailable: humidityAvailable ?? this.humidityAvailable,
      lightAvailable: lightAvailable ?? this.lightAvailable,
      soilTemperatureAvailable:
          soilTemperatureAvailable ?? this.soilTemperatureAvailable,
      leafWetnessAvailable: leafWetnessAvailable ?? this.leafWetnessAvailable,
      plantSignalAvailable: plantSignalAvailable ?? this.plantSignalAvailable,
    );
  }

  double get vapourPressureDeficit {
    final saturation =
        0.6108 * math.exp((17.27 * temperature) / (temperature + 237.3));
    return saturation * (1 - humidity / 100);
  }
}
