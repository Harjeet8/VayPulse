import 'dart:async';
import 'dart:math';

import '../models/edge_intelligence.dart';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import '../services/health_analysis_engine.dart';
import '../services/sensor_data_provider.dart';
import 'demo_mode.dart';

class SimulationSensorProvider extends SensorDataProvider {
  final _controller = StreamController<SensorReading>.broadcast();
  final _random = Random(42);
  final Map<String, List<SensorReading>> _history = {};
  final Map<String, SensorReading> _latest = {};
  late List<SensorNode> _nodes;
  Timer? _timer;
  DemoMode _mode = DemoMode.healthy;
  String _selectedNodeId = 'node-tomato-a1';
  SensorConnectionStatus _status = SensorConnectionStatus.loading;
  String? _errorMessage;

  SimulationSensorProvider() {
    final now = DateTime.now();
    _nodes = [
      SensorNode(
        id: 'node-tomato-a1',
        name: 'Tomato Simulation Node',
        farmId: 'green-valley',
        fieldId: 'tomato-field',
        zoneId: 'tomato-east',
        batteryPercent: 94,
        signalPercent: 92,
        lastSeen: now,
        isOnline: true,
      ),
      SensorNode(
        id: 'node-tomato-a2',
        name: 'Tomato Node T2',
        farmId: 'green-valley',
        fieldId: 'tomato-field',
        zoneId: 'tomato-east',
        batteryPercent: 89,
        signalPercent: 82,
        lastSeen: now,
        isOnline: true,
      ),
      SensorNode(
        id: 'node-tomato-b1',
        name: 'Tomato Node T3',
        farmId: 'green-valley',
        fieldId: 'tomato-field',
        zoneId: 'tomato-west',
        batteryPercent: 79,
        signalPercent: 74,
        lastSeen: now,
        isOnline: true,
      ),
      SensorNode(
        id: 'node-rice-a1',
        name: 'Rice Node A1',
        farmId: 'green-valley',
        fieldId: 'rice-field',
        zoneId: 'rice-north',
        batteryPercent: 91,
        signalPercent: 88,
        lastSeen: now,
        isOnline: true,
      ),
    ];
  }

  @override
  SensorDataSource get source => SensorDataSource.simulation;

  @override
  SensorReading? get current => _latest[_selectedNodeId];

  @override
  Map<String, SensorReading> get latestReadings =>
      Map<String, SensorReading>.unmodifiable(_latest);

  @override
  List<SensorNode> get nodes => List<SensorNode>.unmodifiable(_nodes);

  @override
  String get selectedNodeId => _selectedNodeId;

  @override
  List<SensorReading> historyFor(String nodeId) =>
      List<SensorReading>.unmodifiable(_history[nodeId] ?? const []);

  @override
  bool get connected => _status == SensorConnectionStatus.ready;

  @override
  SensorConnectionStatus get connectionStatus => _status;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Stream<SensorReading> get stream => _controller.stream;

  @override
  bool get supportsScenarios => true;

  @override
  String get scenarioId => _mode.id;

  @override
  List<String> get scenarioIds =>
      DemoMode.values.map((mode) => mode.id).toList(growable: false);

  @override
  EdgeIntelligence? get edgeIntelligence {
    final reading = current;
    if (reading == null) return null;
    final history = _history[_selectedNodeId] ?? const <SensorReading>[];
    final crop = _selectedNodeId.startsWith('node-rice') ? 'Rice' : 'Tomato';
    final stage = _selectedNodeId.startsWith('node-rice') ? 'tillering' : 'vegetative';
    final soilTrend = _trend(
      history.length >= 2 ? history[history.length - 2].soilMoisture : reading.soilMoisture,
      reading.soilMoisture,
    );
    final rootTrend = reading.soilTemperatureAvailable &&
            reading.soilTemperature != null &&
            history.length >= 2 &&
            history[history.length - 2].soilTemperature != null
        ? _trend(history[history.length - 2].soilTemperature!, reading.soilTemperature!)
        : 'STABLE';

    final cause = switch (_mode) {
      DemoMode.dry => const RootCauseAnalysis(
          primary: 'Root-zone moisture is low',
          secondary: 'Soil moisture is falling',
        ),
      DemoMode.overwatered => const RootCauseAnalysis(
          primary: 'Root-zone moisture is very high',
          secondary: 'Leaves have remained wet',
        ),
      DemoMode.heatStress => const RootCauseAnalysis(
          primary: 'Air temperature is high',
          secondary: 'Water demand is increasing',
        ),
      DemoMode.critical => const RootCauseAnalysis(
          primary: 'Heat and low soil moisture are occurring together',
          secondary: 'Plant signal has moved away from its baseline',
        ),
      DemoMode.lowLight => const RootCauseAnalysis(primary: 'Light is low'),
      DemoMode.sensorFault => const RootCauseAnalysis(
          primary: 'Some sensor information is unavailable',
        ),
      _ => const RootCauseAnalysis(),
    };

    final recommendation = switch (_mode) {
      DemoMode.dry => 'Check root-zone moisture and consider irrigation.',
      DemoMode.overwatered => 'Avoid watering now and check drainage.',
      DemoMode.heatStress => 'Reduce avoidable heat exposure and keep monitoring root-zone moisture.',
      DemoMode.critical => 'Inspect the root zone now and reduce heat stress where practical.',
      DemoMode.lowLight => 'Check shade or covering before changing field practice.',
      DemoMode.sensorFault => 'Check the unavailable sensor while environmental monitoring continues.',
      _ => 'Conditions are currently acceptable. Continue monitoring.',
    };

    final state = reading.healthScore >= 82
        ? 'HEALTHY'
        : reading.healthScore >= 65
            ? 'WATCH'
            : reading.healthScore >= 42
                ? 'STRESSED'
                : 'CRITICAL';
    final sensorFault = _mode == DemoMode.sensorFault;
    final vpd = _calculateVpd(reading.temperature, reading.humidity);
    final dryingDemandState = vpd < 0.4
        ? 'LOW'
        : vpd < 1.5
            ? 'OPTIMAL'
            : vpd < 2.2
                ? 'HIGH'
                : 'HIGH_ATMOSPHERIC_DRYING_DEMAND';
    final bioStressScore =
        (100 - (reading.bioelectricStability ?? reading.plantSignal))
            .clamp(0.0, 100.0)
            .toDouble();
    final bioState = sensorFault
        ? 'SIGNAL_NOISY'
        : bioStressScore >= 75
            ? 'STRONG_STRESS_SIGNAL'
            : bioStressScore >= 50
                ? 'STRESS_SIGNAL'
                : bioStressScore >= 25
                    ? 'MILD_RESPONSE'
                    : 'NORMAL';
    final waterState = reading.soilMoisture < 20
        ? 'VERY_DRY'
        : reading.soilMoisture < 35
            ? 'DRY'
            : reading.soilMoisture > 86
                ? 'VERY_WET'
                : reading.soilMoisture > 75
                    ? 'WET'
                    : 'OPTIMAL';
    final waterBalanceScore =
        (100 - (reading.soilMoisture - 62).abs() * 1.65)
            .clamp(0.0, 100.0)
            .toDouble();

    return EdgeIntelligence(
      firmwareVersion: 'simulation-model',
      capabilities: const FirmwareCapabilities(
        edgeDecision: true,
        plantState: true,
        sensorConfidence: true,
        trends: true,
        rootCause: true,
        recovery: true,
        cropProfile: true,
        growthStage: true,
      ),
      healthScore: reading.healthScore,
      overallConfidence: _mode == DemoMode.sensorFault ? 62 : 90,
      plantState: state,
      farmerSummary: cause.primary,
      recommendation: recommendation,
      decisionExplanation: cause.primary == null
          ? 'The simulated readings remain within the current crop profile.'
          : '${cause.primary}. ${cause.secondary ?? ''}'.trim(),
      generatedOnDevice: false,
      degradedAnalysis: _mode == DemoMode.sensorFault,
      degradedReason: _mode == DemoMode.sensorFault
          ? 'Simulation scenario includes unavailable sensors.'
          : null,
      analysisQuality: sensorFault ? 'LOW_CONFIDENCE' : 'GOOD',
      rootCause: cause,
      recovery: const RecoveryInfo(active: false),
      bioelectric: BioelectricIntelligence(
        available: !sensorFault,
        voltageMv: reading.plantVoltageMv,
        baselineMv: reading.bioBaselineMv,
        signedChangeMv: reading.bioDeviationMv,
        deviationMv: reading.bioDeviationMv?.abs(),
        normalizedDeviation: reading.bioBaselineMv == null ||
                reading.bioBaselineMv == 0 ||
                reading.bioDeviationMv == null
            ? null
            : reading.bioDeviationMv! / reading.bioBaselineMv! * 100,
        noiseMv: reading.bioNoiseMv,
        signalQuality: reading.bioSignalQuality,
        signalQualityState: sensorFault ? 'SIGNAL_NOISY' : 'GOOD',
        confidence: sensorFault ? 20 : 92,
        trend: bioStressScore >= 25 ? 'RISING' : 'STABLE',
        stressScore: bioStressScore,
        stressState: bioState,
        persistenceSeconds: bioStressScore >= 25 ? 36 : 0,
        stressLoad: bioStressScore * 0.74,
        stressLoadState: bioStressScore >= 50
            ? 'PERSISTENT'
            : bioStressScore >= 25
                ? 'BUILDING'
                : 'LOW',
        baselineReady: !sensorFault,
        baselineSamples: sensorFault ? 0 : 60,
        baselineTarget: 60,
        includedInFusion: !sensorFault,
        interpretation: bioState,
        corroborated: !sensorFault && bioStressScore >= 25,
        corroboratedBy: !sensorFault && bioStressScore >= 25
            ? <String>[
                if (reading.soilMoisture < 35) 'soilMoisture',
                if (vpd >= 1.5) 'vpd',
                if (reading.soilTemperature != null &&
                    reading.soilTemperature! >= 31)
                  'rootTemperature',
              ]
            : const <String>[],
        farmerResult: bioState,
      ),
      baseline: PlantBaselineInfo(
        status: sensorFault ? 'UNAVAILABLE' : 'BASELINE_STABLE',
        ready: !sensorFault,
        learnedNormal: reading.bioBaselineMv,
        deviation: reading.bioDeviationMv,
      ),
      stressEvidence: StressEvidence(
        water: reading.soilMoisture < 35
            ? (35 - reading.soilMoisture) * 2.4
            : 0,
        heat: reading.temperature > 30
            ? (reading.temperature - 30) * 9
            : 0,
        rootZone: reading.soilTemperature != null &&
                reading.soilTemperature! > 30
            ? (reading.soilTemperature! - 30) * 10
            : 0,
        diseaseEnvironment: reading.diseaseRisk,
        sensorFault: sensorFault ? 80 : 0,
      ),
      derivedEnvironment: DerivedEnvironmentInfo(
        vpdKpa: vpd,
        airDryingDemand: vpd,
        vpdState: dryingDemandState,
        dryingDemandState: dryingDemandState,
      ),
      waterBalance: sensorFault
          ? const WaterBalanceInfo()
          : WaterBalanceInfo(
              state: waterState,
              score: waterBalanceScore,
              explanation: waterState,
            ),
      sensorConfidence: [
        SensorConfidence(
            channel: 'airTemperature',
            percent: reading.temperatureAvailable ? 98 : 0,
            valid: reading.temperatureAvailable),
        SensorConfidence(
            channel: 'humidity',
            percent: reading.humidityAvailable ? 98 : 0,
            valid: reading.humidityAvailable),
        SensorConfidence(
            channel: 'light',
            percent: reading.lightAvailable ? 95 : 0,
            valid: reading.lightAvailable),
        SensorConfidence(
            channel: 'soilMoisture',
            percent: reading.soilMoistureAvailable ? 93 : 0,
            valid: reading.soilMoistureAvailable),
        SensorConfidence(
            channel: 'rootTemperature',
            percent: reading.soilTemperatureAvailable ? 97 : 0,
            valid: reading.soilTemperatureAvailable),
        SensorConfidence(
            channel: 'leafWetness',
            percent: reading.leafWetnessAvailable ? 91 : 0,
            valid: reading.leafWetnessAvailable),
        SensorConfidence(
            channel: 'bioelectric',
            percent: reading.plantSignalAvailable ? reading.bioSignalQuality : 0,
            valid: reading.plantSignalAvailable),
      ],
      trends: [
        SensorTrend(channel: 'soilMoisture', state: soilTrend),
        SensorTrend(channel: 'rootTemperature', state: rootTrend),
        const SensorTrend(channel: 'bioelectric', state: 'STABLE'),
      ],
      cropProfile: CropProfileInfo(
        profile: crop,
        growthStage: stage,
        supportedProfiles: const [
          'universal',
          'tomato',
          'hibiscus',
          'rice',
          'sugarcane',
          'banana',
          'eggplant',
          'okra',
          'maize',
          'groundnut',
        ],
        supportedStages: const [
          'general',
          'young',
          'vegetative',
          'flowering',
          'fruiting',
          'mature',
        ],
        switchable: false,
      ),
      diseaseRiskScore: reading.diseaseRisk,
      diseaseRiskLevel: reading.diseaseRisk == null
          ? null
          : reading.diseaseRisk! >= 70
              ? 'HIGH'
              : reading.diseaseRisk! >= 40
                  ? 'MODERATE'
                  : 'LOW',
      activeSensorChannels: <String>[
        'airTemperature',
        'humidity',
        'light',
        if (reading.soilMoistureAvailable) 'soilMoisture',
        if (reading.soilTemperatureAvailable) 'rootTemperature',
        if (reading.leafWetnessAvailable) 'leafWetness',
        if (reading.plantSignalAvailable) 'bioelectric',
      ],
    );
  }

  @override
  void start() {
    if (_timer != null) return;
    _seedHistory();
    _applyConnectionState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
  }

  void _seedHistory() {
    if (_history.isNotEmpty) return;
    final now = DateTime.now();
    for (final node in _nodes) {
      final readings = <SensorReading>[];
      _history[node.id] = readings;
      for (var hour = 47; hour >= 0; hour--) {
        final timestamp = now.subtract(Duration(hours: hour));
        readings.add(_makeReading(
          node,
          timestamp,
          historicalWave: sin(hour / 5) * 2,
        ));
      }
      _latest[node.id] = readings.last;
    }
  }

  void _tick() {
    if (_status != SensorConnectionStatus.ready) return;
    final now = DateTime.now();
    for (var index = 0; index < _nodes.length; index++) {
      final node = _nodes[index];
      final reading = _makeReading(node, now);
      _latest[node.id] = reading;
      final readings = _history.putIfAbsent(node.id, () => []);
      readings.add(reading);
      if (readings.length > 300) readings.removeAt(0);
      _nodes[index] = node.copyWith(
        lastSeen: now,
        signalPercent: (node.signalPercent + _random.nextInt(5) - 2)
            .clamp(35, 100)
            .toInt(),
      );
      _controller.add(reading);
    }
    notifyListeners();
  }

  SensorReading _makeReading(
    SensorNode node,
    DateTime timestamp, {
    double historicalWave = 0,
  }) {
    final target = DemoModeTargets.values[_mode]!;
    final zoneOffset = (_nodes.indexOf(node) - 1.5) * 0.8;
    double noise(double amount) => (_random.nextDouble() - 0.5) * amount;

    final soil = (target.soilMoisture + zoneOffset + historicalWave + noise(3.2))
        .clamp(0, 100)
        .toDouble();
    final temperature = (target.temperature + zoneOffset * 0.10 + noise(0.7))
        .clamp(-10, 60)
        .toDouble();
    final humidity = (target.humidity - zoneOffset * 0.2 + noise(3))
        .clamp(0, 100)
        .toDouble();
    final daytime = timestamp.hour >= 6 && timestamp.hour < 19;
    final lightPercent = daytime
        ? (target.light + zoneOffset + noise(4)).clamp(0, 100).toDouble()
        : 0.0;
    final lightLux = daytime ? lightPercent * 700 : 0.0;
    final rootTemperature =
        (temperature - 1.5 + noise(0.5)).clamp(-10, 60).toDouble();

    final leafWetness = switch (_mode) {
      DemoMode.overwatered => (82 + noise(5)).clamp(0, 100).toDouble(),
      DemoMode.lowLight => (52 + noise(7)).clamp(0, 100).toDouble(),
      DemoMode.critical => (68 + noise(8)).clamp(0, 100).toDouble(),
      _ => (14 + _max(0, humidity - 70) * 0.7 + noise(5))
          .clamp(0, 100)
          .toDouble(),
    };
    final wetSeconds = leafWetness >= 60
        ? switch (_mode) {
            DemoMode.overwatered => 5.5 * 3600,
            DemoMode.critical => 8.0 * 3600,
            _ => 1.2 * 3600,
          }
        : 0.0;

    final bioStability = switch (_mode) {
      DemoMode.critical => (42 + noise(8)).clamp(0, 100).toDouble(),
      DemoMode.dry => (68 + noise(6)).clamp(0, 100).toDouble(),
      _ => (90 + noise(5)).clamp(0, 100).toDouble(),
    };
    const baselineMv = 1500.0;
    final plantVoltageMv = baselineMv + (100 - bioStability) * 0.7 + noise(4);

    final sensorFault = _mode == DemoMode.sensorFault;
    final raw = SensorReading(
      nodeId: node.id,
      timestamp: timestamp,
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: lightPercent,
      lightLux: lightLux,
      soilTemperature: rootTemperature,
      leafWetness: leafWetness,
      plantSignal: bioStability,
      plantVoltageMv: plantVoltageMv,
      healthScore: 75,
      stressScore: 25,
      healthStatus: 'starting',
      soilRaw: (3200 - soil * 18.5).round().clamp(0, 4095).toInt(),
      leafRaw: (3900 - leafWetness * 27).round().clamp(0, 4095).toInt(),
      soilCalibrated: true,
      leafCalibrated: true,
      daytime: daytime,
      leafWetDurationSeconds: wetSeconds,
      recentWetExposureSeconds: wetSeconds,
      bioBaselineReady: true,
      bioBaselineSamples: 60,
      bioBaselineMv: baselineMv,
      bioDeviationMv: plantVoltageMv - baselineMv,
      bioNoiseMv: 2.2,
      bioSignalQuality: sensorFault ? 20 : 93,
      bioelectricStability: bioStability,
      soilMoistureAvailable: !sensorFault,
      temperatureAvailable: true,
      humidityAvailable: true,
      lightAvailable: true,
      soilTemperatureAvailable: !sensorFault,
      leafWetnessAvailable: !sensorFault,
      plantSignalAvailable: !sensorFault,
    );

    return HealthAnalysisEngine.apply(
      raw,
      _history[node.id] ?? const <SensorReading>[],
      crop: node.id.startsWith('node-rice') ? 'Rice' : 'Tomato',
      growthStage: node.id.startsWith('node-rice') ? 'tillering' : 'vegetative',
    );
  }

  String _trend(double previous, double current) {
    final delta = current - previous;
    if (delta > 4) return 'RISING_FAST';
    if (delta > 0.6) return 'RISING';
    if (delta < -4) return 'FALLING_FAST';
    if (delta < -0.6) return 'FALLING';
    return 'STABLE';
  }

  double _max(double a, double b) => a > b ? a : b;

  double _calculateVpd(double temperature, double humidity) {
    final saturation =
        0.6108 * exp((17.27 * temperature) / (temperature + 237.3));
    return (saturation * (1 - humidity / 100))
        .clamp(0.0, 8.0)
        .toDouble();
  }

  @override
  void selectNode(String nodeId) {
    if (_nodes.any((node) => node.id == nodeId)) {
      _selectedNodeId = nodeId;
      notifyListeners();
    }
  }

  @override
  void setScenario(String scenarioId) {
    _mode = DemoModeLabel.fromId(scenarioId);
    _applyConnectionState();
    if (_status == SensorConnectionStatus.ready) {
      _tick();
    } else {
      notifyListeners();
    }
  }

  void _applyConnectionState() {
    _errorMessage = null;
    if (_mode == DemoMode.offline) {
      _status = SensorConnectionStatus.offline;
      _nodes = _nodes.map((node) => node.copyWith(isOnline: false)).toList();
    } else {
      _status = SensorConnectionStatus.ready;
      _nodes = _nodes.map((node) => node.copyWith(isOnline: true)).toList();
      if (_mode == DemoMode.sensorFault) {
        _errorMessage = 'hardware_invalid_data';
      }
    }
  }

  @override
  void retry() => setScenario('healthy');

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
    super.dispose();
  }
}
