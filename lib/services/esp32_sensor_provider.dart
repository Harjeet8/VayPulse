import 'dart:async';

import '../models/edge_intelligence.dart';
import '../models/esp32_configuration.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import 'esp32_client.dart';
import 'esp32_control_client.dart';
import 'hardware_sensor_provider.dart';
import 'health_analysis_engine.dart';
import 'sensor_data_provider.dart';

class Esp32SensorProvider extends HardwareSensorProvider {
  static const _nodeId = 'phytosense-live-01';

  final Duration pollInterval;
  late final Esp32ControlClient _controlClient;
  final _controller = StreamController<SensorReading>.broadcast();
  final List<SensorReading> _history = [];
  SensorReading? _current;
  EdgeIntelligence? _edgeIntelligence;
  HardwareTelemetry? _hardwareTelemetry;
  Timer? _timer;
  bool _polling = false;
  SensorConnectionStatus _status = SensorConnectionStatus.offline;
  String? _errorMessage;
  int _consecutiveFailures = 0;
  SensorNode _node = SensorNode(
    id: _nodeId,
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
    this.pollInterval = const Duration(seconds: 2),
  }) : super(client) {
    _controlClient = Esp32ControlClient(client.baseUrl);
  }

  String get endpoint => client.baseUrl;

  @override
  SensorReading? get current => _current;

  @override
  EdgeIntelligence? get edgeIntelligence => _edgeIntelligence;

  @override
  HardwareTelemetry? get hardwareTelemetry => _hardwareTelemetry;

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
  Future<Esp32Config?> fetchHardwareConfig() => _controlClient.getConfig();

  @override
  Future<Esp32Config?> setCropProfile(String cropId) async {
    final confirmed = await _controlClient.setCrop(cropId);
    if (confirmed != null) await _poll();
    return confirmed;
  }

  @override
  Future<Esp32Config?> setGrowthStage(String stageId) async {
    final confirmed = await _controlClient.setStage(stageId);
    if (confirmed != null) await _poll();
    return confirmed;
  }

  @override
  Future<Esp32Config?> resetAdaptiveBaseline() async {
    final confirmed = await _controlClient.resetBaseline();
    if (confirmed != null) await _poll();
    return confirmed;
  }

  @override
  Future<Esp32Diagnostics?> fetchHardwareDiagnostics() =>
      _controlClient.getDiagnostics();

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
      final edge = snapshot.edgeIntelligence;
      final raw = snapshot.reading.copyWith(
        nodeId: _nodeId,
        timestamp: DateTime.now(),
      );
      _validate(raw);

      final SensorReading reading;
      if (edge.hasAuthoritativeAnalysis) {
        final health = edge.healthScore ?? raw.healthScore;
        final confidence = edge.overallConfidence ??
            raw.esp32HealthConfidence ??
            raw.analysisConfidence;

        // ESP32 WINS in hardware mode. Flutter only normalizes the firmware
        // result into the existing SensorReading contract for cards/charts.
        // It does not recalculate a competing plant-health conclusion.
        reading = raw.copyWith(
          healthScore: health,
          stressScore: (100.0 - health).clamp(0.0, 100.0).toDouble(),
          healthStatus: edge.plantState ?? raw.healthStatus,
          analysisConfidence: confidence,
          esp32HealthScore: health,
          esp32HealthConfidence: confidence,
          diseaseRisk: edge.diseaseRiskScore ?? raw.diseaseRisk,
        );
      } else {
        // Compatibility fallback for older firmware that only provides raw
        // sensor channels and no authoritative edge decision.
        reading = HealthAnalysisEngine.apply(
          raw,
          _history,
          crop: edge.cropProfile.profile ?? 'Universal',
          growthStage: edge.cropProfile.growthStage ?? 'vegetative',
        );
      }

      _edgeIntelligence = edge;
      _hardwareTelemetry = snapshot.telemetry;
      _current = reading;
      _history.add(reading);
      if (_history.length > 600) _history.removeAt(0);
      _node = _node.copyWith(
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
