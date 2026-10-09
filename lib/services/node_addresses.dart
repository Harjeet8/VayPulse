import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'node_http.dart';
import 'settings_service.dart';

/// Every address the node can be reached at, most likely first.
///
///  * `http://192.168.4.1` - phone on the node's own Wi-Fi "PhytoSense AI".
///  * the node's home-Wi-Fi IP - phone on the same home network. Learned once
///    from `GET http://192.168.4.1/api/clouddebug` (field `homeWifiIp`) and
///    cached in SharedPreferences. `phytosense.local` is not used: Android
///    often cannot resolve `.local` names.
class NodeAddresses {
  NodeAddresses._();

  static const apAddress = 'http://192.168.4.1';
  static const known = <String>[apAddress];
  static const _prefHomeIp = 'node.homeWifiIp';

  /// Last address that answered a command; tried first next time.
  static String? lastWorking;

  /// Cached `http://<homeWifiIp>`, if the node has reported one.
  static String? homeAddress;

  static bool _loaded = false;
  static Future<void>? _refreshing;
  static DateTime? _lastRefresh;

  static String normalize(String value) =>
      value.trim().replaceFirst(RegExp(r'/$'), '');

  static List<String> candidates(
    SettingsService settings, {
    List<String> extra = known,
  }) {
    final result = <String>[];
    for (final raw in <String>[
      if (lastWorking != null) lastWorking!,
      if (homeAddress != null) homeAddress!,
      settings.value.esp32Endpoint,
      ...extra,
    ]) {
      final base = normalize(raw);
      if (base.isNotEmpty && !result.contains(base)) result.add(base);
    }
    return result;
  }

  /// Loads the cached home IP once per app run.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefHomeIp);
      if (stored != null && stored.isNotEmpty) homeAddress = stored;
    } catch (_) {}
  }

  /// Asks the node (over its own Wi-Fi) for its home-Wi-Fi IP and caches it.
  /// Cheap and throttled; safe to call often.
  static Future<void> refreshHomeIp() {
    final last = _lastRefresh;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 2)) {
      return Future<void>.value();
    }
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  static Future<void> _refresh() async {
    _lastRefresh = DateTime.now();
    try {
      final response =
          await NodeHttp.get(Uri.parse('$apAddress/api/clouddebug'));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;
      final ip = decoded['homeWifiIp']?.toString().trim() ?? '';
      if (!isPrivateIpv4(ip)) return;
      final address = 'http://$ip';
      homeAddress = address;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefHomeIp, address);
    } catch (_) {
      // Not on the node's Wi-Fi right now; keep the cached value.
    }
  }

  /// Only real LAN addresses are cached (never 0.0.0.0 or public IPs).
  static bool isPrivateIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final n = parts.map(int.tryParse).toList();
    if (n.any((v) => v == null || v < 0 || v > 255)) return false;
    final a = n[0]!, b = n[1]!;
    if (n.every((v) => v == 0)) return false;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }
}
