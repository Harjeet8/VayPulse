import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../models/hardware_transport.dart';
import 'esp32_client.dart';

class RemoteHardwareSnapshot {
  final Esp32Snapshot snapshot;
  final HardwareConnectionMetadata metadata;

  const RemoteHardwareSnapshot({
    required this.snapshot,
    required this.metadata,
  });
}

abstract class RemoteHardwareClient {
  Future<void> start();
  Future<RemoteHardwareSnapshot> getSnapshot();
  String? get lastErrorKey;
  Future<void> dispose();
}

/// Firebase is transport only. The complete ESP32 payload is decoded by the
/// same Verdant parser used for direct local monitoring, so Hardware Mode
/// remains ESP32-authoritative and LOCAL/REMOTE snapshots are never fused.
class FirebaseRemoteClient implements RemoteHardwareClient {
  static const projectId = 'phytosense-ai-1b0d8';
  static const databaseUrl =
      'https://phytosense-ai-1b0d8-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const defaultPath = 'phytosense/nodes/phytosense_01/live';

  final String databasePath;
  final FirebaseDatabase? database;
  final FirebaseAuth? auth;

  StreamSubscription<DatabaseEvent>? _subscription;
  FirebaseDatabase? _resolvedDatabase;
  Map<String, dynamic>? _latest;
  bool _started = false;
  bool _starting = false;
  String? _lastErrorKey;

  FirebaseRemoteClient({
    this.databasePath = defaultPath,
    this.database,
    this.auth,
  });

  @override
  String? get lastErrorKey => _lastErrorKey;

  @override
  Future<void> start() async {
    if (_started || _starting) return;
    _starting = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final app = Firebase.app();
      if (app.options.projectId.trim() != projectId) {
        _lastErrorKey = 'remote_config_mismatch';
        throw StateError('Firebase project does not match PhytoSense.');
      }

      final authClient = auth ?? FirebaseAuth.instanceFor(app: app);
      if (authClient.currentUser == null) {
        await authClient.signInAnonymously();
      }

      final db = database ??
          FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
      _resolvedDatabase = db;
      _subscription = db.ref(databasePath).onValue.listen(
        (event) {
          final value = event.snapshot.value;
          if (value is Map) {
            _latest = Map<String, dynamic>.from(value);
            _lastErrorKey = null;
          }
        },
        onError: (_) => _lastErrorKey = 'remote_cloud_unavailable',
      );
      _started = true;
      _lastErrorKey = null;
    } catch (_) {
      _lastErrorKey ??= 'remote_auth_unavailable';
    } finally {
      _starting = false;
    }
  }

  @override
  Future<RemoteHardwareSnapshot> getSnapshot() async {
    await start();
    if (!_started) {
      throw StateError(_lastErrorKey ?? 'remote_cloud_unavailable');
    }

    var payload = _latest;
    if (payload == null) {
      try {
        final db = _resolvedDatabase ??
            database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: databaseUrl,
            );
        final event = await db
            .ref(databasePath)
            .get()
            .timeout(const Duration(seconds: 4));
        if (event.value is Map) {
          payload = Map<String, dynamic>.from(event.value as Map);
          _latest = payload;
        }
      } catch (_) {
        _lastErrorKey = 'remote_cloud_unavailable';
      }
    }
    if (payload == null || payload.isEmpty) {
      throw StateError(_lastErrorKey ?? 'remote_snapshot_unavailable');
    }

    final data = _map(payload['data']);
    final source = data.isNotEmpty ? data : payload;
    final system = _map(source['system']);
    final network = _firstNonEmptyMap([
      source['network'],
      system['network'],
      payload['network'],
    ]);

    final lastSeen = RemoteSnapshotFreshnessPolicy.parseTimestamp(
      _first([
        source['lastSeen'],
        source['timestamp'],
        payload['lastSeen'],
        payload['timestamp'],
        network['lastSeen'],
      ]),
    );
    final internetConnected = _bool(_first([
      source['internetConnected'],
      network['internetConnected'],
    ]));
    final cloudConnected = _bool(_first([
      source['cloudConnected'],
      network['cloudConnected'],
    ]));
    final freshness = RemoteSnapshotFreshnessPolicy.classify(
      lastSeen: lastSeen,
      internetConnected: internetConnected,
      cloudConnected: cloudConnected,
    );

    final parser = Esp32Client('https://firebase.transport.invalid');
    final response = http.Response(
      jsonEncode(payload),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
    final snapshot = parser.decodeSnapshot(
      response,
      endpoint: 'firebase:$databasePath',
    );

    return RemoteHardwareSnapshot(
      snapshot: snapshot,
      metadata: HardwareConnectionMetadata(
        transport: HardwareTransportKind.remote,
        freshness: freshness,
        connectionMode: _text(_first([
          source['connectionMode'],
          network['connectionMode'],
        ])),
        remoteNetworkState: _text(_first([
          source['remoteNetworkState'],
          network['remoteNetworkState'],
        ])),
        localApActive: _bool(_first([
          source['localApActive'],
          network['localApActive'],
        ])),
        internetConnected: internetConnected,
        cloudConnected: cloudConnected,
        connectedStaSsid: _text(_first([
          source['connectedStaSsid'],
          source['staSsid'],
          network['connectedStaSsid'],
          network['staSsid'],
        ])),
        lastCloudSync: RemoteSnapshotFreshnessPolicy.parseTimestamp(_first([
          source['lastCloudSync'],
          source['lastCloudSyncMs'],
          network['lastCloudSync'],
          network['lastCloudSyncMs'],
        ])),
        lastSeen: lastSeen,
        firmwareVersion: snapshot.firmwareVersion,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _resolvedDatabase = null;
  }

  static dynamic _first(Iterable<dynamic> values) {
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static Map<String, dynamic> _firstNonEmptyMap(Iterable<dynamic> values) {
    for (final value in values) {
      final map = _map(value);
      if (map.isNotEmpty) return map;
    }
    return <String, dynamic>{};
  }

  static String _text(dynamic value) => value == null ? '' : '$value'.trim();

  static bool? _bool(dynamic value) {
    if (value is bool) return value;
    final text = '$value'.trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }
}
