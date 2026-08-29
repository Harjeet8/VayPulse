import 'dart:async';

import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import '../simulation/simulated_sensor_provider.dart';
import 'esp32_client.dart';
import 'esp32_sensor_provider.dart';
import 'sensor_data_provider.dart';

class SensorProviderManager extends SensorDataProvider {
  final SimulationSensorProvider simulation = SimulationSensorProvider();
  final _controller = StreamController<SensorReading>.broadcast();
  late Esp32SensorProvider _hardware;
  late SensorDataProvider _active;
  StreamSubscription<SensorReading>? _streamSubscription;
  bool _started = false;
  int _attachmentGeneration = 0;

  SensorProviderManager({String endpoint = 'http://192.168.4.1'}) {
    _hardware = _buildHardware(endpoint);
    _active = simulation;
    _attach();
  }

  Esp32SensorProvider _buildHardware(String endpoint) => Esp32SensorProvider(
        client: Esp32Client(endpoint),
      );

  String get hardwareEndpoint => _hardware.endpoint;

  @override
  SensorDataSource get source => _active.source;

  Future<bool> testEndpoint(String endpoint) => Esp32Client(endpoint).ping();

  void configure({
    required SensorDataSource source,
    required String endpoint,
  }) {
    final cleanEndpoint = endpoint.trim().replaceFirst(RegExp(r'/$'), '');
    if (cleanEndpoint.isNotEmpty && cleanEndpoint != _hardware.endpoint) {
      final oldHardware = _hardware;
      final hardwareWasActive = identical(_active, oldHardware);
      if (hardwareWasActive) _detach();
      oldHardware.stop();
      _hardware = _buildHardware(cleanEndpoint);
      if (hardwareWasActive) {
        _active = _hardware;
        _attach();
      }
      oldHardware.dispose();
    }

    final target =
        source == SensorDataSource.simulation ? simulation : _hardware;
    if (!identical(target, _active)) {
      _active.stop();
      _detach();
      _active = target;
      _attach();
    }
    if (_started) _active.start();
    notifyListeners();
  }

  void _attach() {
    final generation = ++_attachmentGeneration;
    _active.addListener(_forwardChange);
    _streamSubscription = _active.stream.listen((reading) {
      if (generation == _attachmentGeneration) {
        _controller.add(reading);
      }
    });
  }

  void _detach() {
    _attachmentGeneration++;
    _active.removeListener(_forwardChange);
    final subscription = _streamSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    _streamSubscription = null;
  }

  void _forwardChange() => notifyListeners();

  @override
  SensorReading? get current => _active.current;

  @override
  Map<String, SensorReading> get latestReadings => _active.latestReadings;

  @override
  List<SensorNode> get nodes => _active.nodes;

  @override
  String get selectedNodeId => _active.selectedNodeId;

  @override
  List<SensorReading> historyFor(String nodeId) => _active.historyFor(nodeId);

  @override
  bool get connected => _active.connected;

  @override
  SensorConnectionStatus get connectionStatus => _active.connectionStatus;

  @override
  String? get errorMessage => _active.errorMessage;

  @override
  Stream<SensorReading> get stream => _controller.stream;

  @override
  bool get supportsScenarios => _active.supportsScenarios;

  @override
  String get scenarioId => _active.scenarioId;

  @override
  List<String> get scenarioIds => _active.scenarioIds;

  @override
  get edgeIntelligence => _active.edgeIntelligence;

  @override
  void start() {
    _started = true;
    _active.start();
  }

  @override
  void stop() {
    _started = false;
    _active.stop();
  }

  @override
  void selectNode(String nodeId) => _active.selectNode(nodeId);

  @override
  void setScenario(String scenarioId) {
    if (_active.source == SensorDataSource.simulation) {
      simulation.setScenario(scenarioId);
    }
  }

  @override
  void retry() => _active.retry();

  @override
  void dispose() {
    _detach();
    simulation.dispose();
    _hardware.dispose();
    _controller.close();
    super.dispose();
  }
}
