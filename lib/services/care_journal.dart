import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CareEntry {
  final String id, plant, source, kind, note;
  final DateTime time;
  final String? photo;
  const CareEntry(
      {required this.id,
      required this.plant,
      required this.source,
      required this.kind,
      required this.note,
      required this.time,
      this.photo});
  Map<String, dynamic> toJson() => {
        'id': id,
        'plant': plant,
        'source': source,
        'kind': kind,
        'note': note,
        'time': time.toIso8601String(),
        'photo': photo
      };
  factory CareEntry.fromJson(Map<String, dynamic> j) {
    for (final key in ['id', 'plant', 'source', 'kind', 'note', 'time']) {
      if (j[key] is! String) throw const FormatException('Invalid care entry');
    }
    if (!RegExp(r'^\d{1,18}$').hasMatch(j['id'] as String))
      throw const FormatException('Invalid entry ID');
    if (!['hardware', 'simulation', 'manual'].contains(j['source']) ||
        !['water', 'check', 'photo', 'note'].contains(j['kind']) ||
        (j['note'] as String).length > 1000 ||
        (j['plant'] as String).length > 200) {
      throw const FormatException('Invalid care entry');
    }
    final photo = j['photo'];
    if (photo != null) {
      if (photo is! String || photo.length > 800000)
        throw const FormatException('Photo too large');
      final bytes = base64Decode(photo);
      if (bytes.length < 3 || bytes[0] != 255 || bytes[1] != 216)
        throw const FormatException('Invalid photo');
    }
    return CareEntry(
        id: j['id'],
        plant: j['plant'],
        source: j['source'],
        kind: j['kind'],
        note: j['note'],
        time: DateTime.parse(j['time']),
        photo: photo as String?);
  }
}

class CareJournal {
  static const platform = MethodChannel('com.harjeet.phytosense/care');
  static const storageKey = 'phyto.care.journal.v1';
  static Future<void> _writes = Future.value();
  static List<CareEntry> decode(String raw) {
    if (raw.length > 30000000) throw const FormatException('Backup too large');
    final j = jsonDecode(raw);
    if (j is! Map ||
        j['format'] != 'phytosense-care' ||
        j['version'] != 1 ||
        j['entries'] is! List) {
      throw const FormatException('Choose a PhytoSense care backup');
    }
    final entries = j['entries'] as List;
    if (entries.length > 500) throw const FormatException('Too many entries');
    return entries
        .map((e) => CareEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String encode(List<CareEntry> entries) => jsonEncode({
        'format': 'phytosense-care',
        'version': 1,
        'entries': entries.map((e) => e.toJson()).toList()
      });
  Future<List<CareEntry>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(storageKey);
    return raw == null ? [] : decode(raw);
  }

  Future<void> _mutate(List<CareEntry> Function(List<CareEntry>) change) {
    final next = _writes.then((_) async {
      final entries = change(await load());
      if (entries.length > 500)
        throw StateError(
            'The diary is full. Export a backup before removing old entries.');
      final raw = encode(entries);
      if (raw.length > 30000000)
        throw StateError('The photo diary is full. Export a backup first.');
      final ok = await (await SharedPreferences.getInstance())
          .setString(storageKey, raw);
      if (!ok) throw StateError('Could not save');
    });
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> add(CareEntry entry) => _mutate((old) => [entry, ...old]);
  Future<void> remove(String id) =>
      _mutate((old) => old.where((e) => e.id != id).toList());
  Future<void> restore(String raw) {
    final incoming =
        decode(raw); // validate entire backup before touching storage
    return _mutate((old) {
      final map = {
        for (final e in incoming) e.id: e,
        for (final e in old) e.id: e
      };
      return map.values.toList()..sort((a, b) => b.time.compareTo(a.time));
    });
  }

  Future<bool> backup() async =>
      await platform.invokeMethod<bool>('saveFile', {
        'text': encode(await load()),
        'name': 'PhytoSense-care-backup.json'
      }) ??
      false;
  Future<bool> restoreFile() async {
    final raw = await platform.invokeMethod<String>('openFile');
    if (raw == null) return false;
    await restore(raw);
    return true;
  }

  static Future<void> share(String text) =>
      platform.invokeMethod('share', {'text': text});
  static Future<bool> remind(DateTime time, String body, int id) async =>
      await platform.invokeMethod<bool>('remind',
          {'time': time.millisecondsSinceEpoch, 'body': body, 'id': id}) ??
      false;
}
