import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'control_seq.dart';
import 'firebase_remote_client.dart';
import 'node_addresses.dart';
import 'node_http.dart';
import 'settings_service.dart';

enum NodeLightMode { on, off, auto }

enum NodeLightDelivery { idle, sending, confirmed, queued, failed }

/// Controls the PhytoSense node's light (firmware v12.4 contract).
///
/// Every command goes out on both routes at once:
///  * LOCAL  `GET /api/led?state=..&brightness=..` (1.5 s, Wi-Fi routed);
///    success only when HTTP 200 echoes what was sent -> "✓ Done".
///  * REMOTE one Firebase `update()` with an ever-increasing `seq`; the node
///    polls every 8 s -> "Sent — node will apply within ~10 s".
/// If both fail, the optimistic UI change is undone -> "Node not reachable".
class NodeLightControl extends ChangeNotifier {
  static const controlPath = 'phytosense/nodes/phytosense_01/control';
  static const _prefMode = 'nodeLight.mode';
  static const _prefBrightness = 'nodeLight.brightness';

  final SettingsService settings;
  final List<String> extraAddresses;

  /// Replaced in tests; returns true when Firebase accepted the write.
  @visibleForTesting
  Future<bool> Function(Map<String, Object> update) remote = _firebaseUpdate;

  NodeLightControl(this.settings,
      {this.extraAddresses = NodeAddresses.known});

  NodeLightMode _mode = NodeLightMode.auto;
  int _brightness = 70;
  int? _preview;
  NodeLightDelivery _delivery = NodeLightDelivery.idle;
  bool _locating = false;
  bool _disposed = false;
  int _generation = 0;
  Timer? _settle;

  // Last state a route accepted; a command that fails on both routes
  // reverts the UI to this instead of pretending the light changed.
  NodeLightMode _lastGoodMode = NodeLightMode.auto;
  int _lastGoodBrightness = 70;

  NodeLightMode get mode => _mode;
  int get brightness => _preview ?? _brightness;
  NodeLightDelivery get delivery => _delivery;
  bool get locating => _locating;

  Future<void> load() async {
    await NodeAddresses.load();
    unawaited(NodeAddresses.refreshHomeIp());
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = NodeLightMode.values.firstWhere(
          (m) => m.name == prefs.getString(_prefMode),
          orElse: () => NodeLightMode.auto);
      _brightness = (prefs.getInt(_prefBrightness) ?? 70).clamp(5, 100);
      _lastGoodMode = _mode;
      _lastGoodBrightness = _brightness;
      _notify();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _settle?.cancel();
    super.dispose();
  }

  Future<void> setMode(NodeLightMode mode) async {
    _mode = mode;
    _persist();
    await _send();
  }

  /// Slider drag: UI only, nothing is sent.
  void previewBrightness(double value) {
    _preview = value.round().clamp(5, 100);
    _notify();
  }

  /// Slider released: sent once, always with state on.
  Future<void> commitBrightness(num value) async {
    _preview = null;
    _brightness = value.round().clamp(5, 100);
    _mode = NodeLightMode.on;
    _persist();
    await _send();
  }

  Future<void> locate() async {
    final generation = ++_generation;
    _setDelivery(NodeLightDelivery.sending);
    final results = await Future.wait([
      _local({'action': 'locate'}),
      _remoteSend({'led/action': 'locate'}),
    ]);
    if (generation != _generation) return;
    if (results[0] || results[1]) {
      // The node blinks for a few seconds; mirror it in the UI.
      _locating = true;
      _notify();
      Timer(const Duration(seconds: 6), () {
        _locating = false;
        _notify();
      });
    }
    _setDelivery(results[0]
        ? NodeLightDelivery.confirmed
        : results[1]
            ? NodeLightDelivery.queued
            : NodeLightDelivery.failed);
  }

  Future<void> _send() async {
    final generation = ++_generation;
    _setDelivery(NodeLightDelivery.sending);
    final query = <String, String>{'state': _mode.name};
    final update = <String, Object>{'led/state': _mode.name, 'led/source': 'app'};
    if (_mode == NodeLightMode.on) {
      query['brightness'] = '$_brightness';
      update['led/brightness'] = _brightness; // int, never a string
    }
    final results = await Future.wait([_local(query), _remoteSend(update)]);
    // A newer command superseded this one while it was in flight.
    if (generation != _generation) return;
    if (results[0] || results[1]) {
      _lastGoodMode = _mode;
      _lastGoodBrightness = _brightness;
    } else {
      // Both routes failed: undo the optimistic change.
      _mode = _lastGoodMode;
      _brightness = _lastGoodBrightness;
      _persist();
    }
    _setDelivery(results[0]
        ? NodeLightDelivery.confirmed
        : results[1]
            ? NodeLightDelivery.queued
            : NodeLightDelivery.failed);
  }

  /// Sends [query] to every node address at once (1.5 s each). Success only
  /// when a reply is HTTP 200 and echoes what was sent.
  Future<bool> _local(Map<String, String> query) async {
    final bases = NodeAddresses.candidates(settings, extra: extraAddresses);
    final results =
        await Future.wait(bases.map((base) => _localAt(base, query)));
    for (var i = 0; i < bases.length; i++) {
      if (results[i]) {
        NodeAddresses.lastWorking = bases[i];
        if (bases[i] == NodeAddresses.apAddress) {
          unawaited(NodeAddresses.refreshHomeIp());
        }
        return true;
      }
    }
    return false;
  }

  Future<bool> _localAt(String base, Map<String, String> query) async {
    try {
      final uri = Uri.parse('$base/api/led').replace(queryParameters: query);
      final response = await NodeHttp.get(uri);
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return false;
      return echoes(decoded, query);
    } catch (_) {
      return false;
    }
  }

  /// True when the node's reply echoes the command that was sent.
  @visibleForTesting
  static bool echoes(Map<dynamic, dynamic> reply, Map<String, String> query) {
    if (reply['ok'] == false) return false;
    final led = reply['led'] is Map ? reply['led'] as Map : reply;
    final action = query['action'];
    if (action != null) {
      return reply['ok'] == true ||
          led['action']?.toString().toLowerCase() == action;
    }
    final state = query['state'];
    if (state != null &&
        led['state']?.toString().trim().toLowerCase() != state) {
      return false;
    }
    final brightness = int.tryParse(query['brightness'] ?? '');
    if (brightness != null) {
      final echoed = led['brightness'];
      final value = echoed is num ? echoed.round() : int.tryParse('$echoed');
      if (value != brightness) return false;
    }
    return true;
  }

  Future<bool> _remoteSend(Map<String, Object> fields) async {
    try {
      final seq = await ControlSeq.next();
      return await remote({'seq': seq, ...fields});
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _firebaseUpdate(Map<String, Object> update) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    final app = Firebase.app();
    final auth = FirebaseAuth.instanceFor(app: app);
    if (auth.currentUser == null) {
      await auth.signInAnonymously().timeout(const Duration(seconds: 8));
    }
    final db = FirebaseDatabase.instanceFor(
        app: app, databaseURL: FirebaseRemoteClient.databaseUrl);
    await db.ref(controlPath).update(update).timeout(const Duration(seconds: 8));
    return true;
  }

  void _setDelivery(NodeLightDelivery value) {
    _delivery = value;
    _notify();
    _settle?.cancel();
    if (value == NodeLightDelivery.confirmed) {
      _settle = Timer(const Duration(seconds: 4), () {
        _delivery = NodeLightDelivery.idle;
        _notify();
      });
    }
  }

  void _persist() {
    _notify();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefMode, _mode.name);
      prefs.setInt(_prefBrightness, _brightness);
    }).catchError((_) {});
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
