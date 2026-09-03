import 'dart:async';
import 'dart:math';

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import '../services/health_analysis_engine.dart';
import '../services/sensor_data_provider.dart';
import 'demo_mode.dart';
import 'simulation_intelligence_v2.dart';

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
        name: 'Tomato East Zone',
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
        name: 'Tomato Centre Zone',
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
        name: 'Tomato West Zone',
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
        name: 'Rice North Zone',
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
  SensorReading? get current =>
      _status == SensorConnectionStatus.ready ? _latest[_selectedNodeId] : null;

  @override
  Map<String, SensorReading> get latestReadings =>
      _status == SensorConnectionStatus.ready
          ? Map<String, SensorReading>.unmodifiable(_latest)
          : const <String, SensorReading>{};

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
    return SimulationIntelligenceV2.build(
      reading: reading,
      history: history,
      mode: _mode,
      crop: crop,
      growthStage: stage,
    );
  }

  @override
  HardwareTelemetry? get hardwareTelemetry {
    final reading = current;
    if (reading == null) return null;
    final history = _history[_selectedNodeId] ?? const <SensorReading>[];
    final crop = _selectedNodeId.startsWith('node-rice') ? 'Rice' : 'Tomato';
    final stage = _selectedNodeId.startsWith('node-rice') ? 'tillering' : 'vegetative';
    return SimulationIntelligenceV2.buildTelemetry(
      reading: reading,
      history: history,
      mode: _mode,
      crop: crop,
      growthStage: stage,
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
      DemoMode.bioticRisk => (90 + noise(4)).clamp(0, 100).toDouble(),
      DemoMode.recovery => (30 + noise(5)).clamp(0, 100).toDouble(),
      DemoMode.lowLight => (52 + noise(7)).clamp(0, 100).toDouble(),
      DemoMode.critical => (68 + noise(8)).clamp(0, 100).toDouble(),
      DemoMode.atmosphericDrying => (8 + noise(4)).clamp(0, 100).toDouble(),
      DemoMode.bioResponse => (18 + noise(5)).clamp(0, 100).toDouble(),
      _ => (14 + _max(0, humidity - 70) * 0.7 + noise(5))
          .clamp(0, 100)
          .toDouble(),
    };
    final wetSeconds = leafWetness >= 60
        ? switch (_mode) {
            DemoMode.overwatered => 5.5 * 3600,
            DemoMode.bioticRisk => 9.0 * 3600,
            DemoMode.critical => 8.0 * 3600,
            DemoMode.recovery => 1.0 * 3600,
            _ => 1.2 * 3600,
          }
        : 0.0;

    final bioStability = switch (_mode) {
      DemoMode.baselineLearning => (96 + noise(2)).clamp(0, 100).toDouble(),
      DemoMode.atmosphericDrying => (63 + noise(5)).clamp(0, 100).toDouble(),
      DemoMode.heatStress => (57 + noise(6)).clamp(0, 100).toDouble(),
      DemoMode.bioResponse => (43 + noise(6)).clamp(0, 100).toDouble(),
      DemoMode.recovery => (80 + noise(4)).clamp(0, 100).toDouble(),
      DemoMode.bioticRisk => (56 + noise(6)).clamp(0, 100).toDouble(),
      DemoMode.critical => (38 + noise(8)).clamp(0, 100).toDouble(),
      DemoMode.dry => (64 + noise(6)).clamp(0, 100).toDouble(),
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
      bioSource: 'simulation',
      healthScore: 75,
      stressScore: 25,
      healthStatus: 'starting',
      analysisOrigin: 'simulation',
      recoveryActive: _mode == DemoMode.recovery,
      vpdKpa: _calculateVpd(temperature, humidity),
      bioticState: _mode == DemoMode.bioticRisk
          ? 'POSSIBLE_BIOTIC_STRESS'
          : 'NONE',
      soilRaw: (3200 - soil * 18.5).round().clamp(0, 4095).toInt(),
      leafRaw: (3900 - leafWetness * 27).round().clamp(0, 4095).toInt(),
      soilCalibrated: true,
      leafCalibrated: true,
      daytime: daytime,
      leafWetDurationSeconds: wetSeconds,
      recentWetExposureSeconds: wetSeconds,
      bioBaselineReady:
          !sensorFault && _mode != DemoMode.baselineLearning,
      bioBaselineSamples:
          _mode == DemoMode.baselineLearning ? 28 : 60,
      bioBaselineMv: baselineMv,
      bioDeviationMv: plantVoltageMv - baselineMv,
      bioNoiseMv: 2.2,
      bioSignalQuality: sensorFault
          ? 20
          : _mode == DemoMode.baselineLearning
              ? 88
              : 93,
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
  void retry() {
    // Refresh the selected practice condition. A pull-to-refresh must never
    // silently replace a critical or recovery demonstration with "healthy".
    _applyConnectionState();
    if (_status == SensorConnectionStatus.ready) {
      _tick();
    } else {
      notifyListeners();
    }
  }

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
