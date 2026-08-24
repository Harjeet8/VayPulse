import 'dart:async';

import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import 'esp32_client.dart';
import 'hardware_sensor_provider.dart';
import 'sensor_data_provider.dart';

class Esp32SensorProvider extends HardwareSensorProvider {
  static const _nodeId = 'phytosense-live-01';

  final Duration pollInterval;
  final _controller = StreamController<SensorReading>.broadcast();
  final List<SensorReading> _history = [];
  SensorReading? _current;
  Timer? _timer;
  bool _polling = false;
  SensorConnectionStatus _status = SensorConnectionStatus.offline;
  String? _errorMessage;
  SensorNode _node = SensorNode(
    id: _nodeId,
    name: 'VayPulse Node 01',
    farmId: '',
    fieldId: '',
    zoneId: '',
    batteryPercent: 100,
    signalPercent: 0,
    lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
    isOnline: false,
  );

  Esp32SensorProvider({
    required Esp32Client client,
    this.pollInterval = const Duration(seconds: 3),
  }) : super(client);

  String get endpoint => client.baseUrl;

  @override
  SensorReading? get current => _current;

  @override
  Map<String, SensorReading> get latestReadings => _current == null
      ? const <String, SensorReading>{}
      : <String, SensorReading>{_nodeId: _current!};

  @override
  List<SensorNode> get nodes => <SensorNode>[_node];

  @override
  String get selectedNodeId => _nodeId;

  @override
  List<SensorReading> historyFor(String nodeId) =>
      nodeId == _nodeId ? List.unmodifiable(_history) : const [];

  @override
  bool get connected => _status == SensorConnectionStatus.ready;

  @override
  SensorConnectionStatus get connectionStatus => _status;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Stream<SensorReading> get stream => _controller.stream;

  @override
  void start() {
    if (_timer != null) return;
    _current = null;
    _status = SensorConnectionStatus.loading;
    _errorMessage = null;
    _node = _node.copyWith(
      signalPercent: 0,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
      isOnline: false,
    );
    notifyListeners();
    unawaited(_poll());
    _timer = Timer.periodic(pollInterval, (_) {
      unawaited(_poll());
    });
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final snapshot = await client.getSnapshot();
      final reading = snapshot.reading.copyWith(
        nodeId: _nodeId,
        timestamp: DateTime.now(),
      );
      _validate(reading);
      _current = reading;
      _history.add(reading);
      if (_history.length > 600) _history.removeAt(0);
      _node = _node.copyWith(
        batteryPercent: snapshot.batteryPercent,
        signalPercent: snapshot.signalPercent,
        lastSeen: reading.timestamp,
        isOnline: true,
      );
      _status = SensorConnectionStatus.ready;
      _errorMessage = null;
      _controller.add(reading);
    } on FormatException {
      _status = SensorConnectionStatus.error;
      _errorMessage = 'hardware_invalid_data';
      _node = _node.copyWith(isOnline: false);
    } catch (_) {
      _status = SensorConnectionStatus.offline;
      _errorMessage = 'hardware_unreachable';
      _node = _node.copyWith(isOnline: false);
    } finally {
      _polling = false;
      notifyListeners();
    }
  }

  void _validate(SensorReading reading) {
    final valid = reading.soilMoisture.isFinite &&
        reading.soilMoisture >= 0 &&
        reading.soilMoisture <= 100 &&
        reading.temperature.isFinite &&
        reading.temperature >= -10 &&
        reading.temperature <= 65 &&
        reading.humidity.isFinite &&
        reading.humidity >= 0 &&
        reading.humidity <= 100 &&
        reading.light.isFinite &&
        reading.light >= 0 &&
        reading.light <= 100 &&
        reading.plantSignal.isFinite &&
        reading.plantSignal >= 0 &&
        reading.plantSignal <= 100;
    if (!valid) throw const FormatException('Out-of-range sensor data');
  }

  @override
  void selectNode(String nodeId) {}

  @override
  void retry() {
    _status = SensorConnectionStatus.loading;
    notifyListeners();
    unawaited(_poll());
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
