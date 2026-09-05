import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sensor_reading.dart';
import 'sensor_data_provider.dart';
import 'sensor_provider_manager.dart';
import 'settings_service.dart';

enum OfflineSyncStatus { ready, syncing, success, failed }

class OfflineSyncService extends ChangeNotifier {
  final SensorDataProvider sensors;
  final SettingsService settings;
  final List<Map<String, dynamic>> _pending = [];
  final List<Map<String, dynamic>> _history = [];
  StreamSubscription<SensorReading>? _subscription;
  Timer? _saveTimer;

  OfflineSyncStatus status = OfflineSyncStatus.ready;
  DateTime? lastSyncAt;
  String? errorKey;

  OfflineSyncService(this.sensors, this.settings);

  int get pendingCount => _pending.length;
  int get historyCount => _history.length;
  List<Map<String, dynamic>> get pendingRecords => List.unmodifiable(_pending);

  List<SensorReading> readingsFor(String nodeId) {
    final readings = <SensorReading>[];
    for (final record in _history) {
      if ('${record['nodeId']}' != nodeId) continue;
      try {
        readings.add(SensorReading.fromJson(record));
      } catch (_) {
        // Invalid cached records are ignored rather than breaking a chart.
      }
    }
    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('offlineReadingQueue');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        _pending.addAll(
          decoded.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      } catch (_) {
        _pending.clear();
      }
    }
    final historyRaw = preferences.getString('localReadingHistory');
    if (historyRaw != null) {
      try {
        final decoded = jsonDecode(historyRaw) as List;
        _history.addAll(
          decoded.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      } catch (_) {
        _history.clear();
      }
    }
    final last = preferences.getString('lastDataSyncAt');
    lastSyncAt = last == null ? null : DateTime.tryParse(last);
    notifyListeners();
  }

  void start() {
    _subscription ??= sensors.stream.listen(_queueReading);
  }

  void _queueReading(SensorReading reading) {
    // Demonstration data must never enter a production synchronization queue.
    if (sensors.source == SensorDataSource.simulation) return;
    final transport = sensors is SensorProviderManager
        ? sensors.activeHardwareTransport.name
        : 'unknown';
    final record = <String, dynamic>{
      ...reading.toJson(),
      'source': sensors.source.name,
      'transport': transport,
      'queuedAt': DateTime.now().toIso8601String(),
    };
    _pending.add(record);
    if (_pending.length > 360) _pending.removeAt(0);
    final lastForNode = _history.where(
      (item) => '${item['nodeId']}' == reading.nodeId,
    );
    final lastTimestamp = lastForNode.isEmpty
        ? null
        : DateTime.tryParse('${lastForNode.last['timestamp']}');
    if (lastTimestamp == null ||
        reading.timestamp.difference(lastTimestamp).inMinutes >= 10) {
      _history.add(Map<String, dynamic>.from(record));
      if (_history.length > 4500) _history.removeAt(0);
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_persist());
    });
    status = OfflineSyncStatus.ready;
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('offlineReadingQueue', jsonEncode(_pending));
    await preferences.setString('localReadingHistory', jsonEncode(_history));
  }

  Future<bool> syncNow() async {
    final endpoint = settings.value.syncEndpoint;
    if (endpoint.isEmpty) {
      status = OfflineSyncStatus.failed;
      errorKey = 'sync_endpoint_required';
      notifyListeners();
      return false;
    }
    if (_pending.isEmpty) {
      status = OfflineSyncStatus.success;
      errorKey = null;
      notifyListeners();
      return true;
    }
    status = OfflineSyncStatus.syncing;
    errorKey = null;
    notifyListeners();
    try {
      final response = await http
          .post(
            Uri.parse('$endpoint/api/sync'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device': 'phytosense-mobile',
              'records': _pending,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('sync http');
      }
      _pending.clear();
      lastSyncAt = DateTime.now();
      status = OfflineSyncStatus.success;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('offlineReadingQueue', '[]');
      await preferences.setString(
        'lastDataSyncAt',
        lastSyncAt!.toIso8601String(),
      );
      notifyListeners();
      return true;
    } catch (_) {
      status = OfflineSyncStatus.failed;
      errorKey = 'sync_failed';
      await _persist();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    unawaited(_persist());
    super.dispose();
  }
}
