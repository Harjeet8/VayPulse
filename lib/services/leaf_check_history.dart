import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One saved leaf check (kept on the phone only; the photo never leaves it).
class LeafCheckRecord {
  final int t; // unix seconds, UTC
  final String crop;
  final String result; // condition key, or unsure / other_crop
  final double confidence; // 0..1
  final Uint8List? thumbnail;
  const LeafCheckRecord(
      {required this.t,
      required this.crop,
      required this.result,
      required this.confidence,
      this.thumbnail});

  DateTime get time =>
      DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true).toLocal();

  Map<String, Object?> toJson() => {
        't': t,
        'crop': crop,
        'result': result,
        'confidence': confidence,
        if (thumbnail != null) 'thumb': base64Encode(thumbnail!),
      };

  static LeafCheckRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final t = raw['t'], crop = raw['crop'], result = raw['result'];
    if (t is! int || crop is! String || result is! String) return null;
    Uint8List? thumb;
    try {
      if (raw['thumb'] is String) thumb = base64Decode(raw['thumb'] as String);
    } catch (_) {}
    return LeafCheckRecord(
        t: t,
        crop: crop,
        result: result,
        confidence: (raw['confidence'] as num?)?.toDouble() ?? 0,
        thumbnail: thumb);
  }
}

class LeafCheckHistory extends ChangeNotifier {
  LeafCheckHistory._();
  static final instance = LeafCheckHistory._();

  static const _key = 'leafChecks.v1';
  static const maxRecords = 40;

  final List<LeafCheckRecord> _items = [];
  bool _loaded = false;

  List<LeafCheckRecord> get items => List.unmodifiable(_items);
  LeafCheckRecord? get latest => _items.isEmpty ? null : _items.first;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _items
          ..clear()
          ..addAll((jsonDecode(raw) as List)
              .map(LeafCheckRecord.fromJson)
              .whereType<LeafCheckRecord>());
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> add(LeafCheckRecord record) async {
    await load();
    _items.insert(0, record);
    if (_items.length > maxRecords) _items.removeRange(maxRecords, _items.length);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  @visibleForTesting
  void resetForTest() {
    _items.clear();
    _loaded = false;
  }
}
