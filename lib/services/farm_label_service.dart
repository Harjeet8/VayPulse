import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'app_integrity.dart';
import 'firebase_remote_client.dart';

/// Farmer labels ("I watered", "Leaves have spots", leaf checks ...) for
/// training the node's own model later.
///
/// Every tap is saved on the phone first, with the time of the tap (unix
/// seconds, UTC), then sent to Firebase:
///   phytosense/nodes/phytosense_01/labels/<pushId>
/// The push id is made at tap time (same format as Firebase push()), so a
/// retry after a lost connection rewrites the same event, never a duplicate.
/// Without internet the events wait in a local queue and are sent later.
class FarmLabelService extends ChangeNotifier {
  FarmLabelService._();
  static final instance = FarmLabelService._();

  static const labelsPath = 'phytosense/nodes/phytosense_01/labels';
  static const types = <String>[
    'watered',
    'fertilizer',
    'wilted',
    'spots',
    'healthy',
    'pests',
  ];
  static const _prefKey = 'farmLabels.v1';
  static const keepDays = 7;
  static const retryEvery = Duration(seconds: 30);

  /// Replaced in tests; returns true when the event reached Firebase.
  @visibleForTesting
  Future<bool> Function(String id, Map<String, Object> payload) sender =
      _sendToFirebase;

  final List<LabelEvent> _events = [];
  bool _loaded = false;
  bool _flushing = false;
  Timer? _retry;

  List<LabelEvent> get events => List.unmodifiable(_events);
  int get pendingCount => _events.where((e) => !e.sent).length;

  List<LabelEvent> today() {
    final now = DateTime.now();
    return _events.where((e) {
      final local = e.time;
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).toList();
  }

  Future<void> start() async {
    await _load();
    unawaited(flush());
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  /// One-tap label. Returns the saved event (already stored on the phone).
  Future<LabelEvent> record(String type) {
    assert(types.contains(type));
    return _add({'type': type, 'source': 'app'});
  }

  /// Text-only record of a leaf check. The photo is never sent.
  Future<LabelEvent> recordLeafCheck(
      {required String crop,
      required String result,
      required double confidence}) {
    return _add({
      'type': 'leaf_check',
      'crop': crop,
      'result': result,
      'confidence': (confidence.clamp(0.0, 1.0) * 1000).round() / 1000,
      'source': 'app',
    });
  }

  Future<LabelEvent> _add(Map<String, Object> fields) async {
    await _load();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final event = LabelEvent(
      id: PushId.generate(nowMs),
      payload: {'t': nowMs ~/ 1000, ...fields},
      sent: false,
    );
    _events.insert(0, event);
    await _save();
    notifyListeners();
    unawaited(flush());
    return event;
  }

  /// Sends every queued event. Safe to call often.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      for (final event in _events.reversed.toList()) {
        if (event.sent) continue;
        var ok = false;
        try {
          ok = await sender(event.id, event.payload);
        } catch (_) {
          ok = false;
        }
        if (!ok) break; // offline: keep order, try again later
        event.sent = true;
        await _save();
        notifyListeners();
      }
    } finally {
      _flushing = false;
    }
    _retry?.cancel();
    _retry =
        pendingCount > 0 ? Timer(retryEvery, () => unawaited(flush())) : null;
  }

  static Future<bool> _sendToFirebase(
      String id, Map<String, Object> payload) async {
    if (!await AppIntegrity.cloudAllowed()) return false;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    final app = Firebase.app();
    final auth = FirebaseAuth.instanceFor(app: app);
    if (auth.currentUser == null) {
      await auth.signInAnonymously().timeout(const Duration(seconds: 10));
    }
    final db = FirebaseDatabase.instanceFor(
        app: app, databaseURL: FirebaseRemoteClient.databaseUrl);
    await db
        .ref('$labelsPath/$id')
        .set(payload)
        .timeout(const Duration(seconds: 10));
    return true;
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        _events
          ..clear()
          ..addAll((jsonDecode(raw) as List)
              .map(LabelEvent.fromJson)
              .whereType<LabelEvent>());
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    // Keep a week of sent events for the "today" list; never drop unsent.
    final cutoff = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 -
        keepDays * 86400;
    _events.removeWhere((e) => e.sent && e.t < cutoff);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_events.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  @visibleForTesting
  void resetForTest() {
    _events.clear();
    _loaded = false;
    _flushing = false;
    _retry?.cancel();
    _retry = null;
    sender = _sendToFirebase;
  }
}

class LabelEvent {
  final String id;
  final Map<String, Object> payload;
  bool sent;
  LabelEvent({required this.id, required this.payload, required this.sent});

  int get t => payload['t'] as int;
  String get type => payload['type'] as String;
  DateTime get time =>
      DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true).toLocal();

  Map<String, Object> toJson() => {'id': id, 'payload': payload, 'sent': sent};

  static LabelEvent? fromJson(Object? raw) {
    if (raw is! Map || raw['id'] is! String || raw['payload'] is! Map) {
      return null;
    }
    final payload = Map<String, Object>.from(raw['payload'] as Map);
    if (payload['t'] is! int || payload['type'] is! String) return null;
    return LabelEvent(
        id: raw['id'] as String, payload: payload, sent: raw['sent'] == true);
  }
}

/// Firebase-compatible push id: 8 chars of time + 12 random chars, so keys
/// sort by time exactly like push().
class PushId {
  PushId._();
  static const _chars =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
  static final _random = Random.secure();
  static int _lastMs = -1;
  static final _last = List<int>.filled(12, 0);

  static String generate(int nowMs) {
    final same = nowMs == _lastMs;
    _lastMs = nowMs;
    final time = List<String>.filled(8, '');
    var ms = nowMs;
    for (var i = 7; i >= 0; i--) {
      time[i] = _chars[ms % 64];
      ms ~/= 64;
    }
    if (!same) {
      for (var i = 0; i < 12; i++) {
        _last[i] = _random.nextInt(64);
      }
    } else {
      var i = 11;
      while (i >= 0 && _last[i] == 63) {
        _last[i] = 0;
        i--;
      }
      if (i >= 0) _last[i]++;
    }
    return time.join() + _last.map((v) => _chars[v]).join();
  }
}
