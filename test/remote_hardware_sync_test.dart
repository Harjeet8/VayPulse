import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phytosense_ai/models/hardware_transport.dart';
import 'package:phytosense_ai/services/esp32_client.dart';
import 'package:phytosense_ai/services/esp32_sensor_provider.dart';
import 'package:phytosense_ai/services/firebase_remote_client.dart';
import 'package:phytosense_ai/services/sensor_data_provider.dart';
import 'package:phytosense_ai/services/sensor_provider_manager.dart';

http.Response _jsonResponse(Map<String, dynamic> payload) => http.Response(
      jsonEncode(payload),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _localPayload() => <String, dynamic>{
      'deviceId': 'phytosense_01',
      'firmwareVersion': 'PhytoSense AI Edge Intelligence',
      'firmwareEdition': 'Final Edge Intelligence',
      'buildState': 'FROZEN_FINAL',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'healthIndex': 91,
      'confidence': 88,
      'status': 'EXCELLENT',
      'plantCondition': 'EXCELLENT',
      'priority': 'CHECK',
      'mainFinding': 'Verify soil probe placement',
      'farmerAction': 'Check probe placement',
      'because': 'The ESP32 marked the soil channel for verification.',
      'airTemperature': 29.4,
      'humidity': 61,
      'light': 74,
      'soilMoisture': 47,
      'soilRaw': 1870,
      'waterBalance': 63,
      'rootTemperature': 28.6,
      'leafWetness': 5,
      'leafRaw': 3880,
      'diseaseRisk': 12,
      'bioState': 'STABLE',
      'bioSource': 'real',
      'bioConfidence': 82,
      'bioVoltage': 1640,
      'bioSignalQuality': 100,
      'bioContactState': 'PLAUSIBLE',
      'bioContactConfidence': 89,
      'bioSlowDriftMv': 7.2,
      'bioContactPlausibleForPlantUse': true,
      'bioOpenLatched': false,
      'bioReconnectVerifying': false,
      'bioReconnectVerifySec': 0,
      'bioAffectsHealth': true,
      'analysisQuality': 'HIGH',
      'reliability': 'FULL',
      'primaryCause': 'No major stress',
      'secondaryCause': 'Continue monitoring',
      'predictionState': 'NONE',
      'recoveryState': 'NONE',
      'recoveryProgressPct': 77,
      'sensorIntegrity': 'FULL',
      'ahtStatus': 'OK',
      'bh1750Status': 'OK',
      'soilStatus': 'OK',
      'ds18b20Status': 'OK',
      'leafStatus': 'OK',
      'bioStatus': 'OK',
      'dayNight': 'DAY',
      'cropProfile': 'Universal',
      'growthStage': 'Vegetative',
    };

Map<String, dynamic> _remotePayload({DateTime? lastSeen}) {
  final payload = _localPayload();
  payload
    ..['lastSeen'] = (lastSeen ?? DateTime.now().toUtc()).toIso8601String()
    ..['connectionMode'] = 'REMOTE'
    ..['remoteNetworkState'] = 'REMOTE_CONNECTED'
    ..['localApActive'] = true
    ..['internetConnected'] = true
    ..['cloudConnected'] = true;
  return payload;
}

Esp32Snapshot _decode(Map<String, dynamic> payload) =>
    Esp32Client('http://192.168.4.1').decodeSnapshot(
      _jsonResponse(payload),
      endpoint: '/api/sensors',
    );

class _StaticRemoteClient implements RemoteHardwareClient {
  final RemoteHardwareSnapshot value;
  int snapshotCalls = 0;

  _StaticRemoteClient(this.value);

  @override
  String? get lastErrorKey => null;

  @override
  Future<void> start() async {}

  @override
  Future<RemoteHardwareSnapshot> getSnapshot() async {
    snapshotCalls++;
    return value;
  }

  @override
  Future<void> dispose() async {}
}

RemoteHardwareSnapshot _remoteSnapshot(
  Map<String, dynamic> payload,
) {
  final snapshot = _decode(payload);
  return RemoteHardwareSnapshot(
    snapshot: snapshot,
    metadata: HardwareConnectionMetadata(
      transport: HardwareTransportKind.remote,
      freshness: RemoteSnapshotFreshness.live,
      connectionMode: 'REMOTE',
      remoteNetworkState: 'REMOTE_CONNECTED',
      internetConnected: true,
      cloudConnected: true,
      lastSeen: DateTime.now().toUtc(),
      firmwareVersion: snapshot.firmwareVersion,
      firmwareEdition: snapshot.reading.firmwareEdition,
      buildState: snapshot.reading.firmwareBuildState,
    ),
  );
}

class _ThrowingRemoteClient implements RemoteHardwareClient {
  int startCalls = 0;
  int snapshotCalls = 0;

  @override
  String? get lastErrorKey => 'remote_auth_unavailable';

  @override
  Future<void> start() async {
    startCalls++;
    throw StateError('auth unavailable');
  }

  @override
  Future<RemoteHardwareSnapshot> getSnapshot() async {
    snapshotCalls++;
    throw StateError('auth unavailable');
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test('local ESP32 snapshot parses authoritative firmware result', () {
    final reading = _decode(_localPayload()).reading;

    expect(reading.healthScore, 91);
    expect(reading.analysisConfidence, 88);
    expect(reading.healthStatus, 'EXCELLENT');
    expect(reading.priority, 'CHECK');
    expect(reading.primaryRootCause, 'Verify soil probe placement');
    expect(reading.farmerAction, 'Check probe placement');
    expect(
      reading.because,
      'The ESP32 marked the soil channel for verification.',
    );
    expect(reading.analysisQuality, 'HIGH');
    expect(reading.firmwareName, 'PhytoSense AI Edge Intelligence');
    expect(reading.firmwareEdition, 'Final Edge Intelligence');
    expect(reading.firmwareBuildState, 'FROZEN_FINAL');
  });

  test('Firebase-shaped flat snapshot normalizes through same SensorReading',
      () {
    final local = _decode(_localPayload()).reading;
    final remote = _decode(_remotePayload()).reading;

    expect(remote.nodeId, local.nodeId);
    expect(remote.healthScore, local.healthScore);
    expect(remote.analysisConfidence, local.analysisConfidence);
    expect(remote.healthStatus, local.healthStatus);
    expect(remote.primaryRootCause, local.primaryRootCause);
    expect(remote.farmerAction, local.farmerAction);
    expect(remote.temperature, local.temperature);
    expect(remote.soilTemperature, local.soilTemperature);
    expect(remote.plantVoltageMv, local.plantVoltageMv);
    expect(remote.bioContactState, local.bioContactState);
  });

  test('OPEN contact with 100 percent signal quality is not plant-usable', () {
    final payload = _remotePayload()
      ..['bioContactState'] = 'OPEN'
      ..['bioSignalQuality'] = 100
      ..['bioContactPlausibleForPlantUse'] = false
      ..['bioAffectsHealth'] = false;

    final reading = _decode(payload).reading;
    expect(reading.bioSignalQuality, 100);
    expect(reading.bioElectricalMeasurementAvailable, isTrue);
    expect(reading.bioPlantUseAllowed, isFalse);
  });

  test('OPEN latch keeps bio unavailable for plant use', () {
    final payload = _remotePayload()
      ..['bioContactState'] = 'PLAUSIBLE'
      ..['bioContactPlausibleForPlantUse'] = true
      ..['bioAffectsHealth'] = true
      ..['bioOpenLatched'] = true;

    final reading = _decode(payload).reading;
    expect(reading.bioOpenLatched, isTrue);
    expect(reading.bioPlantUseAllowed, isFalse);
  });

  test('PLAUSIBLE explicit plant-use-valid bio is usable', () {
    final reading = _decode(_remotePayload()).reading;
    expect(reading.normalizedBioContactState, 'PLAUSIBLE');
    expect(reading.bioContactPlausibleForPlantUse, isTrue);
    expect(reading.bioAffectsHealth, isTrue);
    expect(reading.bioPlantUseAllowed, isTrue);
  });

  test('soil placement VERIFY disables soil use without inventing drought', () {
    final payload = _remotePayload()
      ..['soilMoisture'] = 0
      ..['soilStatus'] = 'VERIFY'
      ..['healthIndex'] = 95
      ..['mainFinding'] = 'Verify soil probe placement'
      ..['farmerAction'] = 'Insert probe correctly and recheck';

    final reading = _decode(payload).reading;
    expect(reading.soilMoistureAvailable, isFalse);
    expect(reading.healthScore, 95);
    expect(reading.primaryRootCause, 'Verify soil probe placement');
    expect(reading.farmerAction, 'Insert probe correctly and recheck');
  });

  test('remote freshness is live for a current snapshot', () {
    final now = DateTime.utc(2026, 9, 5, 3);
    expect(
      RemoteSnapshotFreshnessPolicy.classify(
        lastSeen: now.subtract(const Duration(seconds: 6)),
        now: now,
        internetConnected: true,
        cloudConnected: true,
      ),
      RemoteSnapshotFreshness.live,
    );
  });

  test('remote freshness becomes delayed then stale', () {
    final now = DateTime.utc(2026, 9, 5, 3);
    expect(
      RemoteSnapshotFreshnessPolicy.classify(
        lastSeen: now.subtract(const Duration(seconds: 18)),
        now: now,
        internetConnected: true,
        cloudConnected: true,
      ),
      RemoteSnapshotFreshness.delayed,
    );
    expect(
      RemoteSnapshotFreshnessPolicy.classify(
        lastSeen: now.subtract(const Duration(seconds: 45)),
        now: now,
        internetConnected: true,
        cloudConnected: true,
      ),
      RemoteSnapshotFreshness.stale,
    );
  });

  test('AUTO prefers local when local is healthy', () {
    final controller = HardwareTransportController();
    expect(
      controller.select(
        mode: HardwareTransportMode.auto,
        localAvailable: true,
        remoteFreshness: RemoteSnapshotFreshness.live,
      ),
      HardwareTransportKind.local,
    );
  });

  test('AUTO falls back to remote after local failure debounce', () {
    final controller = HardwareTransportController();
    controller.select(
      mode: HardwareTransportMode.auto,
      localAvailable: true,
      remoteFreshness: RemoteSnapshotFreshness.live,
    );
    expect(
      controller.select(
        mode: HardwareTransportMode.auto,
        localAvailable: false,
        remoteFreshness: RemoteSnapshotFreshness.live,
      ),
      HardwareTransportKind.none,
    );
    expect(
      controller.select(
        mode: HardwareTransportMode.auto,
        localAvailable: false,
        remoteFreshness: RemoteSnapshotFreshness.live,
      ),
      HardwareTransportKind.remote,
    );
  });

  test('AUTO returns to local only after clean recovery debounce', () {
    final controller = HardwareTransportController();
    controller.select(
      mode: HardwareTransportMode.auto,
      localAvailable: false,
      remoteFreshness: RemoteSnapshotFreshness.live,
    );
    expect(controller.active, HardwareTransportKind.remote);

    expect(
      controller.select(
        mode: HardwareTransportMode.auto,
        localAvailable: true,
        remoteFreshness: RemoteSnapshotFreshness.live,
      ),
      HardwareTransportKind.remote,
    );
    expect(
      controller.select(
        mode: HardwareTransportMode.auto,
        localAvailable: true,
        remoteFreshness: RemoteSnapshotFreshness.live,
      ),
      HardwareTransportKind.local,
    );
  });

  test('simulation remains independent from hardware transport choice', () {
    final manager = SensorProviderManager();
    addTearDown(manager.dispose);

    expect(manager.source, SensorDataSource.simulation);
    manager.setHardwareTransportMode(HardwareTransportMode.remote);
    manager.setScenario('critical');
    expect(manager.source, SensorDataSource.simulation);
    expect(manager.scenarioId, 'critical');
  });

  test('recovery NONE never keeps stale non-zero progress', () {
    final payload = _remotePayload()
      ..['recoveryState'] = 'NONE'
      ..['recoveryProgressPct'] = 84;

    final reading = _decode(payload).reading;
    expect(reading.recoveryStatus, 'NONE');
    expect(reading.recoveryProgressPct, isNull);
  });

  test('firmware identity is retained for Technical/Judge presentation', () {
    final snapshot = _decode(_remotePayload());
    expect(snapshot.firmwareVersion, 'PhytoSense AI Edge Intelligence');
    expect(snapshot.reading.firmwareName, 'PhytoSense AI Edge Intelligence');
    expect(snapshot.reading.firmwareEdition, 'Final Edge Intelligence');
    expect(snapshot.reading.firmwareBuildState, 'FROZEN_FINAL');
  });

  test('Firebase auth failure cannot break LOCAL hardware mode', () async {
    final remote = _ThrowingRemoteClient();
    final localClient = Esp32Client(
      'http://192.168.4.1',
      httpClient: MockClient((_) async => _jsonResponse(_localPayload())),
    );
    final provider = Esp32SensorProvider(
      client: localClient,
      remoteClient: remote,
      transportMode: HardwareTransportMode.local,
      pollInterval: const Duration(hours: 1),
    );
    addTearDown(provider.dispose);

    provider.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(provider.connectionStatus, SensorConnectionStatus.ready);
    expect(provider.current?.healthScore, 91);
    expect(provider.activeTransport, HardwareTransportKind.local);
    expect(remote.startCalls, 0);
    expect(remote.snapshotCalls, 0);
  });

  test('old firmware missing remote/contact fields still parses safely', () {
    final reading = _decode(<String, dynamic>{
      'deviceId': 'old-node',
      'temperature': 28,
      'humidity': 60,
      'soilMoisture': 55,
      'light': 65,
      'healthScore': 83,
      'healthStatus': 'GOOD',
      'analysisConfidence': 79,
      'primaryRootCause': 'NONE',
      'farmerAction': 'Continue monitoring.',
    }).reading;

    expect(reading.healthScore, 83);
    expect(reading.bioContactState, isEmpty);
    expect(reading.firmwareEdition, isEmpty);
    expect(reading.analysisQuality, isEmpty);
  });
  test('Firebase client is pinned to the final PhytoSense project and RTDB',
      () {
    expect(FirebaseRemoteClient.projectId, 'phytosense-ai-1b0d8');
    expect(
      FirebaseRemoteClient.databaseUrl,
      'https://phytosense-ai-1b0d8-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    expect(
      FirebaseRemoteClient.defaultPath,
      'phytosense/nodes/phytosense_01/live',
    );
  });
  test('REMOTE Hardware Mode works without local ESP32 reachability', () async {
    final remotePayload = _remotePayload()
      ..['healthIndex'] = 77
      ..['mainFinding'] = 'Remote authoritative result'
      ..['airTemperature'] = 31.2;
    final remote = _StaticRemoteClient(_remoteSnapshot(remotePayload));
    final localClient = Esp32Client(
      'http://192.168.4.1',
      httpClient: MockClient((_) async {
        throw http.ClientException('local AP unavailable');
      }),
    );
    final provider = Esp32SensorProvider(
      client: localClient,
      remoteClient: remote,
      transportMode: HardwareTransportMode.remote,
      pollInterval: const Duration(hours: 1),
    );
    addTearDown(provider.dispose);

    provider.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(provider.connectionStatus, SensorConnectionStatus.ready);
    expect(provider.activeTransport, HardwareTransportKind.remote);
    expect(provider.current?.healthScore, 77);
    expect(provider.current?.primaryRootCause, 'Remote authoritative result');
    expect(provider.current?.temperature, 31.2);
    expect(remote.snapshotCalls, greaterThan(0));
  });

  test('AUTO switches complete snapshots and never field-merges local/remote',
      () async {
    var localReachable = true;
    final localPayload = _localPayload()
      ..['healthIndex'] = 96
      ..['mainFinding'] = 'LOCAL RESULT'
      ..['airTemperature'] = 25.1
      ..['soilMoisture'] = 81;

    final remotePayload = _remotePayload()
      ..['healthIndex'] = 42
      ..['mainFinding'] = 'REMOTE RESULT'
      ..['airTemperature'] = 34.7
      ..['soilMoisture'] = 29;

    final localClient = Esp32Client(
      'http://192.168.4.1',
      httpClient: MockClient((_) async {
        if (!localReachable) {
          throw http.ClientException('local unavailable');
        }
        return _jsonResponse(localPayload);
      }),
    );
    final remote = _StaticRemoteClient(_remoteSnapshot(remotePayload));
    final provider = Esp32SensorProvider(
      client: localClient,
      remoteClient: remote,
      transportMode: HardwareTransportMode.auto,
      pollInterval: const Duration(hours: 1),
    );
    addTearDown(provider.dispose);

    provider.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(provider.activeTransport, HardwareTransportKind.local);
    expect(provider.current?.healthScore, 96);
    expect(provider.current?.primaryRootCause, 'LOCAL RESULT');
    expect(provider.current?.temperature, 25.1);
    expect(provider.current?.soilMoisture, 81);

    localReachable = false;
    provider.retry();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    provider.retry();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(provider.activeTransport, HardwareTransportKind.remote);
    expect(provider.current?.healthScore, 42);
    expect(provider.current?.primaryRootCause, 'REMOTE RESULT');
    expect(provider.current?.temperature, 34.7);
    expect(provider.current?.soilMoisture, 29);
  });

  test('current schema v9 Firebase compact payload parses exactly', () {
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'deviceId': 'PS-NODE-01',
      'firmwareVersion': 'PhytoSense AI Edge Intelligence',
      'firmwareEdition': 'Final Edge Intelligence + Remote Provisioning',
      'buildState': 'FROZEN_FINAL',
      'schemaVersion': 9,
      'lastSeen': now.millisecondsSinceEpoch,
      'timestamp': now.toIso8601String(),
      'healthIndex': 92.7,
      'confidence': 74.2,
      'status': 'WATCH',
      'plantCondition': 'WATCH',
      'priority': 'CHECK',
      'mainFinding': 'Verify soil probe placement',
      'farmerAction': 'INSERT PROBE IN SOIL / CHECK CALIBRATION',
      'because': 'The soil channel needs placement verification.',
      'airTemperature': 31.8,
      'humidity': 62.55,
      'light': 50.8,
      'soilMoisture': 0.0,
      'soilRaw': 3272,
      'soilStatus': 'VERIFY',
      'rootTemperature': 31.2,
      'leafWetness': 0.0,
      'leafRaw': 4095,
      'diseaseRisk': 4.2,
      'bioState': 'LEARNING BASELINE',
      'bioSource': 'real',
      'bioAffectsHealth': false,
      'bioVoltage': 1804.8,
      'bioSignalQuality': 76.0,
      'bioContactState': 'PLAUSIBLE',
      'bioContactConfidence': 90.8,
      'bioContactPlausibleForPlantUse': true,
      'analysisQuality': 'MODERATE',
      'reliability': 'DEGRADED',
      'primaryCause': 'Verify soil probe placement',
      'secondaryCause': 'Continue monitoring',
      'predictionState': 'ACTIVE',
      'predictionTarget': 'soilMoisture',
      'predictionConfidence': 72.0,
      'predictionMinutesToWarning': 18,
      'recoveryState': 'NONE',
      'sensorIntegrity': 'VERIFY',
      'sensorIntegrityIssue': 'Soil probe needs verification',
      'ahtStatus': 'OK',
      'bh1750Status': 'OK',
      'ds18b20Status': 'OK',
      'leafStatus': 'OK',
      'bioStatus': 'PLAUSIBLE',
      'dayNight': 'NIGHT',
      'cropProfile': 'Hibiscus',
      'growthStage': 'Vegetative',
      'connectionMode': 'LOCAL_CLOUD',
      'remoteNetworkState': 'REMOTE_CONNECTED',
      'localApActive': true,
      'internetConnected': true,
      'cloudConnected': true,
      'staSsid': 'JioFiber4g',
      'staIp': '192.168.29.5',
    };

    final reading = Esp32Client('https://firebase.transport.invalid')
        .decodeSnapshot(
          _jsonResponse(payload),
          endpoint: 'firebase:phytosense/nodes/phytosense_01/live',
        )
        .reading;

    expect(reading.nodeId, 'PS-NODE-01');
    expect(reading.lightLux, closeTo(50.8, 0.001));
    expect(reading.light, closeTo(50.8 / 70000 * 100, 0.001));
    expect(reading.soilMoistureAvailable, isFalse);
    expect(reading.crop, 'Hibiscus');
    expect(reading.predictionAvailable, isTrue);
    expect(reading.predictionTarget, 'soilMoisture');
    expect(reading.sensorIntegrityState, 'VERIFY');
    expect(reading.sensorIntegrityPrimaryIssue, 'Soil probe needs verification');
    expect(reading.healthScore, closeTo(92.7, 0.001));
    expect(reading.primaryRootCause, 'Verify soil probe placement');
  });

}
