import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectionEvent {
  final String id;
  final String nodeId;
  final DateTime timestamp;
  final String titleKey;
  final String? detailKey;

  const InspectionEvent({
    required this.id,
    required this.nodeId,
    required this.timestamp,
    required this.titleKey,
    this.detailKey,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nodeId': nodeId,
        'timestamp': timestamp.toIso8601String(),
        'titleKey': titleKey,
        if (detailKey != null) 'detailKey': detailKey,
      };

  factory InspectionEvent.fromJson(Map<String, dynamic> json) {
    return InspectionEvent(
      id: '${json['id']}',
      nodeId: '${json['nodeId']}',
      timestamp: DateTime.parse('${json['timestamp']}'),
      titleKey: '${json['titleKey']}',
      detailKey: json['detailKey'] == null ? null : '${json['detailKey']}',
    );
  }
}

/// Small, local event log for camera actions that actually happened.
class InspectionHistoryService extends ChangeNotifier {
  static const _storageKey = 'bioticInspectionTimelineV1';
  final List<InspectionEvent> _events = <InspectionEvent>[];

  List<InspectionEvent> eventsFor(String nodeId) => List.unmodifiable(
        _events.where((event) => event.nodeId == nodeId),
      );

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _events
        ..clear()
        ..addAll(decoded.map(
          (item) => InspectionEvent.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ));
      notifyListeners();
    } catch (_) {
      _events.clear();
    }
  }

  Future<void> recordStarted(String nodeId) => _add(
        nodeId: nodeId,
        titleKey: 'camera_inspection_started',
      );

  Future<void> recordCompleted(
    String nodeId, {
    required String? visualResultKey,
  }) =>
      _add(
        nodeId: nodeId,
        titleKey: 'camera_inspection_completed',
        detailKey: visualResultKey ?? 'camera_no_clear_event',
      );

  Future<void> _add({
    required String nodeId,
    required String titleKey,
    String? detailKey,
  }) async {
    final now = DateTime.now();
    final duplicate = _events.any(
      (event) =>
          event.nodeId == nodeId &&
          event.titleKey == titleKey &&
          event.detailKey == detailKey &&
          now.difference(event.timestamp).inSeconds.abs() < 5,
    );
    if (duplicate) return;
    _events.insert(
      0,
      InspectionEvent(
        id: now.microsecondsSinceEpoch.toString(),
        nodeId: nodeId,
        timestamp: now,
        titleKey: titleKey,
        detailKey: detailKey,
      ),
    );
    if (_events.length > 40) _events.removeLast();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(_events.map((event) => event.toJson()).toList()),
    );
    notifyListeners();
  }
}
