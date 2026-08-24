import 'dart:async';
import 'dart:math';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
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
  String _selectedNodeId = 'node-rice-a1';
  SensorConnectionStatus _status = SensorConnectionStatus.loading;
  String? _errorMessage;

  SimulationSensorProvider() {
    final now = DateTime.now();
    _nodes = [
      SensorNode(
          id: 'node-rice-a1',
          name: 'Node A1',
          farmId: 'green-valley',
          fieldId: 'rice-field',
          zoneId: 'rice-north',
          batteryPercent: 91,
          signalPercent: 88,
          lastSeen: now,
          isOnline: true),
      SensorNode(
          id: 'node-rice-a2',
          name: 'Node A2',
          farmId: 'green-valley',
          fieldId: 'rice-field',
          zoneId: 'rice-north',
          batteryPercent: 84,
          signalPercent: 76,
          lastSeen: now,
          isOnline: true),
      SensorNode(
          id: 'node-rice-b1',
          name: 'Node B1',
          farmId: 'green-valley',
          fieldId: 'rice-field',
          zoneId: 'rice-south',
          batteryPercent: 77,
          signalPercent: 70,
          lastSeen: now,
          isOnline: true),
      SensorNode(
          id: 'node-tomato-a1',
          name: 'Node T1',
          farmId: 'green-valley',
          fieldId: 'tomato-field',
          zoneId: 'tomato-east',
          batteryPercent: 89,
          signalPercent: 82,
          lastSeen: now,
          isOnline: true),
      SensorNode(
          id: 'node-tomato-a2',
          name: 'Node T2',
          farmId: 'green-valley',
          fieldId: 'tomato-field',
          zoneId: 'tomato-east',
          batteryPercent: 72,
          signalPercent: 65,
          lastSeen: now,
          isOnline: true),
      SensorNode(
          id: 'node-tomato-b1',
          name: 'Node T3',
          farmId: 'green-valley',
          fieldId: 'tomato-field',
          zoneId: 'tomato-west',
          batteryPercent: 68,
          signalPercent: 61,
          lastSeen: now,
          isOnline: true),
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
      List<SensorReading>.unmodifiable(
        _history[nodeId] ?? const <SensorReading>[],
      );

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
      for (var hour = 47; hour >= 0; hour--) {
        readings.add(_makeReading(
          node,
          now.subtract(Duration(hours: hour)),
          historicalWave: sin(hour / 5) * 2,
        ));
      }
      _history[node.id] = readings;
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
    final zoneOffset = (_nodes.indexOf(node) - 2.5) * 1.25;
    double noise(double amount) => (_random.nextDouble() - 0.5) * amount;

    final soil = (target.soilMoisture + zoneOffset + historicalWave + noise(4))
        .clamp(0, 100)
        .toDouble();
    final temperature = (target.temperature + zoneOffset * 0.12 + noise(0.9))
        .clamp(-10, 60)
        .toDouble();
    final humidity = (target.humidity - zoneOffset * 0.3 + noise(4))
        .clamp(0, 100)
        .toDouble();
    final light =
        (target.light + zoneOffset + noise(5)).clamp(0, 100).toDouble();
    final plantSignal =
        (72 - (100 - target.soilMoisture).abs() * 0.18 + noise(6))
            .clamp(0, 100)
            .toDouble();

    var health = 100.0;
    health -= (soil - 62).abs() * 0.62;
    health -= (temperature - 25).abs() * 2.25;
    health -= (humidity - 58).abs() * 0.28;
    health -= (light - 68).abs() * 0.2;
    health = health.clamp(0, 100).toDouble();

    return SensorReading(
      nodeId: node.id,
      timestamp: timestamp,
      soilMoisture: soil,
      temperature: temperature,
      humidity: humidity,
      light: light,
      plantSignal: plantSignal,
      healthScore: health,
      stressScore: 100 - health,
      healthStatus: health >= 82
          ? 'excellent'
          : health >= 65
              ? 'good'
              : health >= 42
                  ? 'watch'
                  : 'critical',
    );
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
    } else if (_mode == DemoMode.sensorFault) {
      _status = SensorConnectionStatus.error;
      _errorMessage = 'error_message';
      _nodes = _nodes.map((node) => node.copyWith(isOnline: false)).toList();
    } else {
      _status = SensorConnectionStatus.ready;
      _nodes = _nodes.map((node) => node.copyWith(isOnline: true)).toList();
    }
  }

  @override
  void retry() {
    setScenario('healthy');
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
