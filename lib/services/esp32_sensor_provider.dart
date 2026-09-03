import 'dart:async';

import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import 'esp32_client.dart';
import 'hardware_sensor_provider.dart';
import 'sensor_data_provider.dart';

class Esp32SensorProvider extends HardwareSensorProvider {
  static const _fallbackNodeId = 'PHYTO-NODE-001';

  final Duration pollInterval;
  final _controller = StreamController<SensorReading>.broadcast();
  final List<SensorReading> _history = [];
  SensorReading? _current;
  Timer? _timer;
  bool _polling = false;
  SensorConnectionStatus _status = SensorConnectionStatus.offline;
  String? _errorMessage;
  int _consecutiveFailures = 0;
  SensorNode _node = SensorNode(
    id: _fallbackNodeId,
    name: 'PhytoSense Node 01',
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
      : <String, SensorReading>{_current!.nodeId: _current!};

  @override
  List<SensorNode> get nodes => <SensorNode>[_node];

  @override
  String get selectedNodeId => _current?.nodeId ?? _node.id;

  @override
  List<SensorReading> historyFor(String nodeId) =>
      nodeId == selectedNodeId ? List.unmodifiable(_history) : const [];

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
    _status = SensorConnectionStatus.loading;
    _errorMessage = null;
    _consecutiveFailures = 0;
    _node = _node.copyWith(isOnline: false);
    notifyListeners();
    unawaited(_poll());
    _timer = Timer.periodic(pollInterval, (_) => unawaited(_poll()));
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final snapshot = await client.getSnapshot();
      final reading = snapshot.reading;
      _validate(reading);

      // Hardware mode uses the ESP32 edge-intelligence result as the source of
      // truth. Flutter must not run a second crop/health engine over the same
      // packet, because that can contradict the node and previously hard-coded
      // Tomato even when another crop profile was active on the ESP32.
      _current = reading;
      _history.add(reading);
      if (_history.length > 600) _history.removeAt(0);
      _node = SensorNode(
        id: reading.nodeId,
        name: reading.nodeId,
        farmId: _node.farmId,
        fieldId: _node.fieldId,
        zoneId: _node.zoneId,
        batteryPercent: snapshot.batteryPercent,
        signalPercent: snapshot.signalPercent,
        lastSeen: reading.timestamp,
        isOnline: true,
      );
      _consecutiveFailures = 0;
      _status = SensorConnectionStatus.ready;
      _errorMessage = null;
      _controller.add(reading);
    } on FormatException {
      _registerFailure('hardware_invalid_data', invalidData: true);
    } catch (_) {
      _registerFailure('hardware_unreachable');
    } finally {
      _polling = false;
      notifyListeners();
    }
  }

  void _registerFailure(String key, {bool invalidData = false}) {
    _consecutiveFailures++;
    // One missed packet on an AP link should not make the dashboard flicker.
    // After two failures the node is clearly marked unavailable while the last
    // validated reading remains visible for context.
    if (_consecutiveFailures < 2 && _current != null) return;
    _status = invalidData
        ? SensorConnectionStatus.error
        : SensorConnectionStatus.offline;
    _errorMessage = key;
    _node = _node.copyWith(isOnline: false);
  }

  void _validate(SensorReading reading) {
    bool between(double value, double low, double high) =>
        value.isFinite && value >= low && value <= high;

    final valid = (!reading.soilMoistureAvailable ||
            between(reading.soilMoisture, 0, 100)) &&
        (!reading.temperatureAvailable ||
            between(reading.temperature, -20, 70)) &&
        (!reading.humidityAvailable || between(reading.humidity, 0, 100)) &&
        (!reading.lightAvailable ||
            (reading.lightLux == null ||
                between(reading.lightLux!, 0, 200000))) &&
        (!reading.soilTemperatureAvailable ||
            (reading.soilTemperature != null &&
                between(reading.soilTemperature!, -20, 70))) &&
        (!reading.leafWetnessAvailable ||
            (reading.leafWetness != null &&
                between(reading.leafWetness!, 0, 100))) &&
        (!reading.plantSignalAvailable ||
            (reading.plantVoltageMv == null ||
                between(reading.plantVoltageMv!, 0, 5000))) &&
        between(reading.bioSignalQuality, 0, 100);
    if (!valid) throw const FormatException('Out-of-range sensor data');
  }

  @override
  void selectNode(String nodeId) {}

  @override
  void retry() {
    _status = SensorConnectionStatus.loading;
    _errorMessage = null;
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
