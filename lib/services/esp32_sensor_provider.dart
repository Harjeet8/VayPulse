import 'dart:async';

import '../models/edge_intelligence.dart';
import '../models/esp32_configuration.dart';
import '../models/hardware_telemetry.dart';
import '../models/hardware_transport.dart';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import 'esp32_client.dart';
import 'esp32_control_client.dart';
import 'firebase_remote_client.dart';
import 'hardware_sensor_provider.dart';
import 'health_analysis_engine.dart';
import 'sensor_data_provider.dart';

class Esp32SensorProvider extends HardwareSensorProvider {
  static const _nodeId = 'phytosense-live-01';

  final Duration pollInterval;
  final RemoteHardwareClient remoteClient;
  final HardwareTransportController _transportController;
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
  HardwareTransportMode _transportMode;
  HardwareConnectionMetadata _connectionMetadata =
      const HardwareConnectionMetadata();

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
    RemoteHardwareClient? remoteClient,
    HardwareTransportMode transportMode = HardwareTransportMode.auto,
    HardwareTransportController? transportController,
    this.pollInterval = const Duration(seconds: 2),
  })  : remoteClient = remoteClient ?? FirebaseRemoteClient(),
        _transportMode = transportMode,
        _transportController =
            transportController ?? HardwareTransportController(),
        super(client) {
    _controlClient = Esp32ControlClient(client.baseUrl);
  }

  String get endpoint => client.baseUrl;
  HardwareTransportMode get transportMode => _transportMode;
  HardwareTransportKind get activeTransport => _connectionMetadata.transport;
  HardwareConnectionMetadata get connectionMetadata => _connectionMetadata;

  void setTransportMode(HardwareTransportMode mode) {
    if (_transportMode == mode) return;
    _transportMode = mode;
    _transportController.reset();
    _connectionMetadata = const HardwareConnectionMetadata();
    _status = SensorConnectionStatus.loading;
    _errorMessage = null;
    _consecutiveFailures = 0;
    if (mode != HardwareTransportMode.local) {
      unawaited(remoteClient.start());
    }
    if (_timer != null) unawaited(_poll());
    notifyListeners();
  }

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

  // Configuration writes remain local/AP operations. Remote Firebase data is
  // read-only transport and never becomes a second intelligence authority.
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
    if (_transportMode != HardwareTransportMode.local) {
      unawaited(remoteClient.start());
    }
    notifyListeners();
    unawaited(_poll());
    _timer = Timer.periodic(pollInterval, (_) => unawaited(_poll()));
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      switch (_transportMode) {
        case HardwareTransportMode.local:
          final local = await _tryLocal();
          if (local == null) {
            _registerFailure('hardware_unreachable');
          } else {
            _acceptSnapshot(local, _localMetadata(local));
          }
          break;
        case HardwareTransportMode.remote:
          final remote = await _tryRemote();
          if (remote == null) {
            _registerFailure(
              remoteClient.lastErrorKey ?? 'remote_cloud_unavailable',
            );
          } else if (!remote.metadata.freshness.usable) {
            _connectionMetadata = remote.metadata;
            _registerFailure(
              remote.metadata.freshness == RemoteSnapshotFreshness.stale
                  ? 'remote_snapshot_stale'
                  : 'remote_node_offline',
              immediate: true,
            );
          } else {
            _acceptSnapshot(remote.snapshot, remote.metadata);
          }
          break;
        case HardwareTransportMode.auto:
          await _pollAuto();
          break;
      }
    } finally {
      _polling = false;
      notifyListeners();
    }
  }

  Future<void> _pollAuto() async {
    final local = await _tryLocal();

    RemoteHardwareSnapshot? remote;
    if (local == null ||
        _transportController.active == HardwareTransportKind.remote) {
      remote = await _tryRemote();
    }

    final selected = _transportController.select(
      mode: HardwareTransportMode.auto,
      localAvailable: local != null,
      remoteFreshness:
          remote?.metadata.freshness ?? RemoteSnapshotFreshness.offline,
    );

    if (selected == HardwareTransportKind.local && local != null) {
      _acceptSnapshot(local, _localMetadata(local));
      return;
    }

    if (selected == HardwareTransportKind.remote &&
        remote != null &&
        remote.metadata.freshness.usable) {
      _acceptSnapshot(remote.snapshot, remote.metadata);
      return;
    }

    if (remote != null && !remote.metadata.freshness.usable) {
      _connectionMetadata = remote.metadata;
      _registerFailure(
        remote.metadata.freshness == RemoteSnapshotFreshness.stale
            ? 'remote_snapshot_stale'
            : 'remote_node_offline',
        immediate: true,
      );
      return;
    }

    _registerFailure(
      local == null
          ? (remoteClient.lastErrorKey ?? 'hardware_unreachable')
          : 'hardware_unreachable',
    );
  }

  Future<Esp32Snapshot?> _tryLocal() async {
    try {
      return await client.getSnapshot();
    } catch (_) {
      return null;
    }
  }

  Future<RemoteHardwareSnapshot?> _tryRemote() async {
    try {
      return await remoteClient.getSnapshot();
    } catch (_) {
      return null;
    }
  }

  HardwareConnectionMetadata _localMetadata(Esp32Snapshot snapshot) =>
      HardwareConnectionMetadata(
        transport: HardwareTransportKind.local,
        freshness: RemoteSnapshotFreshness.live,
        connectionMode: 'LOCAL_DIRECT',
        localApActive: true,
        lastSeen: snapshot.reading.timestamp,
        firmwareVersion: snapshot.firmwareVersion,
      );

  void _acceptSnapshot(
    Esp32Snapshot snapshot,
    HardwareConnectionMetadata metadata,
  ) {
    final edge = snapshot.edgeIntelligence;
    if (!edge.firmwareCompatible) {
      _edgeIntelligence = edge;
      _hardwareTelemetry = snapshot.telemetry;
      _connectionMetadata = metadata;
      _status = SensorConnectionStatus.error;
      _errorMessage = 'firmware_compatibility';
      _node = _node.copyWith(isOnline: false);
      return;
    }

    final raw = snapshot.reading.copyWith(
      nodeId: _nodeId,
      timestamp: metadata.transport == HardwareTransportKind.remote
          ? (metadata.lastSeen ?? snapshot.reading.timestamp)
          : DateTime.now(),
    );
    _validate(raw);

    final SensorReading reading;
    if (edge.hasAuthoritativeAnalysis) {
      final firmwareHealth = edge.healthScore ?? raw.esp32HealthScore;
      final health = firmwareHealth ?? 50.0;
      final confidence =
          edge.overallConfidence ?? raw.esp32HealthConfidence ?? 0.0;
      final stress = edge.bioelectric.excludedByFirmware
          ? (firmwareHealth == null
              ? 50.0
              : (100.0 - health).clamp(0.0, 100.0).toDouble())
          : edge.bioelectric.stressScore ??
              (firmwareHealth == null
                  ? 50.0
                  : (100.0 - health).clamp(0.0, 100.0).toDouble());

      // ESP32 WINS in Hardware Mode. Flutter only normalizes the complete
      // selected snapshot; it never merges LOCAL and REMOTE fields.
      reading = raw.copyWith(
        healthScore: health,
        stressScore: stress,
        healthStatus: edge.plantState ?? raw.healthStatus,
        analysisConfidence: confidence,
        analysisOrigin: 'esp32',
        primaryRootCause: edge.rootCause.primary,
        secondaryRootCause: edge.rootCause.secondary,
        degradedAnalysis: edge.degradedAnalysis,
        healthTrend:
            _trendFor(edge, const ['health', 'healthScore', 'plantHealth']),
        diseaseRiskTrend: _trendFor(
          edge,
          const ['diseaseRisk', 'environmentalDiseaseRisk'],
        ),
        recoveryActive: edge.recovery.active,
        vpdKpa: edge.derivedEnvironment.vpdKpa,
        bioticState: edge.bioticStress.state,
        esp32HealthScore: firmwareHealth,
        esp32HealthConfidence:
            edge.overallConfidence ?? raw.esp32HealthConfidence,
        diseaseRisk: edge.diseaseRiskScore ?? raw.diseaseRisk,
      );
    } else {
      reading = HealthAnalysisEngine.apply(
        raw,
        _history,
        crop: edge.cropProfile.profile ?? 'Universal',
        growthStage: edge.cropProfile.growthStage ?? 'vegetative',
      ).copyWith(analysisOrigin: 'flutterFallback');
    }

    _edgeIntelligence = edge;
    _hardwareTelemetry = snapshot.telemetry;
    _connectionMetadata = metadata;
    _current = reading;
    _history.add(reading);
    if (_history.length > 600) _history.removeAt(0);
    _node = _node.copyWith(
      batteryPercent: snapshot.batteryPercent,
      signalPercent: snapshot.signalPercent,
      lastSeen: metadata.lastSeen ?? reading.timestamp,
      isOnline: true,
    );
    _consecutiveFailures = 0;
    _status = SensorConnectionStatus.ready;
    _errorMessage = null;
    _controller.add(reading);
  }

  void _registerFailure(
    String key, {
    bool invalidData = false,
    bool immediate = false,
  }) {
    _consecutiveFailures++;
    if (!immediate && _consecutiveFailures < 2 && _current != null) return;
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

  String? _trendFor(EdgeIntelligence edge, List<String> aliases) {
    final normalized = aliases
        .map((value) =>
            value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .toSet();
    for (final trend in edge.trends) {
      final channel = trend.channel
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalized.contains(channel)) return trend.state;
    }
    return null;
  }

  @override
  void selectNode(String nodeId) {}

  @override
  void retry() {
    _status = SensorConnectionStatus.loading;
    _errorMessage = null;
    _consecutiveFailures = 0;
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
    unawaited(remoteClient.dispose());
    _controller.close();
    super.dispose();
  }
}
