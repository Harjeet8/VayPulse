import 'dart:async';

import '../models/hardware_transport.dart';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';
import 'esp32_client.dart';
import 'firebase_remote_client.dart';
import 'hardware_sensor_provider.dart';
import 'sensor_data_provider.dart';

class Esp32SensorProvider extends HardwareSensorProvider {
  static const _fallbackNodeId = 'PHYTO-NODE-001';

  final Duration pollInterval;
  final RemoteHardwareClient remoteClient;
  final HardwareTransportController _transportController;

  final _controller = StreamController<SensorReading>.broadcast();
  final List<SensorReading> _history = [];

  SensorReading? _current;
  Timer? _timer;
  bool _polling = false;
  SensorConnectionStatus _status = SensorConnectionStatus.offline;
  String? _errorMessage;
  int _consecutiveFailures = 0;
  HardwareTransportMode _transportMode;
  HardwareConnectionMetadata _connectionMetadata =
      const HardwareConnectionMetadata();

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
    RemoteHardwareClient? remoteClient,
    HardwareTransportMode transportMode = HardwareTransportMode.auto,
    HardwareTransportController? transportController,
    this.pollInterval = const Duration(seconds: 3),
  })  : remoteClient = remoteClient ?? FirebaseRemoteClient(),
        _transportMode = transportMode,
        _transportController =
            transportController ?? HardwareTransportController(),
        super(client);

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
    if (_transportMode != HardwareTransportMode.local) {
      // Remote initialization is isolated. A Firebase/auth/config failure is
      // not allowed to break direct local monitoring.
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
            _accept(
              local,
              HardwareConnectionMetadata(
                transport: HardwareTransportKind.local,
                freshness: RemoteSnapshotFreshness.live,
                connectionMode: 'LOCAL_DIRECT',
                localApActive: true,
                lastSeen: local.reading.timestamp,
                firmwareVersion: local.firmwareVersion,
                firmwareEdition: local.reading.firmwareEdition,
                buildState: local.reading.firmwareBuildState,
              ),
            );
          }
          break;

        case HardwareTransportMode.remote:
          final remote = await _tryRemote();
          if (remote == null) {
            _registerFailure(
                remoteClient.lastErrorKey ?? 'remote_cloud_unavailable');
          } else if (!remote.metadata.freshness.usable) {
            _connectionMetadata = remote.metadata;
            _registerFailure(
              remote.metadata.freshness == RemoteSnapshotFreshness.stale
                  ? 'remote_snapshot_stale'
                  : 'remote_node_offline',
              immediate: true,
            );
          } else {
            _accept(remote.snapshot, remote.metadata);
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

    final remoteFreshness =
        remote?.metadata.freshness ?? RemoteSnapshotFreshness.offline;
    final selected = _transportController.select(
      mode: HardwareTransportMode.auto,
      localAvailable: local != null,
      remoteFreshness: remoteFreshness,
    );

    if (selected == HardwareTransportKind.local && local != null) {
      _accept(
        local,
        HardwareConnectionMetadata(
          transport: HardwareTransportKind.local,
          freshness: RemoteSnapshotFreshness.live,
          connectionMode: 'LOCAL_DIRECT',
          localApActive: true,
          lastSeen: local.reading.timestamp,
          firmwareVersion: local.firmwareVersion,
          firmwareEdition: local.reading.firmwareEdition,
          buildState: local.reading.firmwareBuildState,
        ),
      );
      return;
    }

    if (selected == HardwareTransportKind.remote &&
        remote != null &&
        remote.metadata.freshness.usable) {
      _accept(remote.snapshot, remote.metadata);
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
      final snapshot = await client.getSnapshot();
      _validate(snapshot.reading);
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<RemoteHardwareSnapshot?> _tryRemote() async {
    try {
      final remote = await remoteClient.getSnapshot();
      _validate(remote.snapshot.reading);
      return remote;
    } catch (_) {
      return null;
    }
  }

  void _accept(
    Esp32Snapshot snapshot,
    HardwareConnectionMetadata metadata,
  ) {
    final reading = snapshot.reading;

    // Hardware mode uses the ESP32 edge-intelligence result as the source of
    // truth. Local and Firebase are only transports for the same complete
    // snapshot; Flutter never fuses them or runs a second plant-health engine.
    _current = reading;
    _connectionMetadata = metadata;
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
      lastSeen: metadata.lastSeen ?? reading.timestamp,
      isOnline: true,
    );
    _consecutiveFailures = 0;
    _status = SensorConnectionStatus.ready;
    _errorMessage = null;
    _controller.add(reading);
  }

  void _registerFailure(String key, {bool immediate = false}) {
    _consecutiveFailures++;
    // A stale cloud snapshot is never allowed to retain a LIVE connection
    // state. Ordinary transient local failures still get one-cycle debounce.
    if (!immediate && _consecutiveFailures < 2 && _current != null) return;
    _status = SensorConnectionStatus.offline;
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
