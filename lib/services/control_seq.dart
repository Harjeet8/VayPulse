import 'package:shared_preferences/shared_preferences.dart';

/// Ever-increasing sequence number for Firebase control commands.
///
/// The node applies a command only when its `seq` is greater than the last
/// one it applied, so every write uses S = max(nowUnixSeconds, lastSeq + 1),
/// with lastSeq kept in SharedPreferences. Calls are serialized so two quick
/// taps can never get the same number.
class ControlSeq {
  ControlSeq._();

  static const prefKey = 'nodeControl.lastSentSeq';
  static Future<int> _chain = Future<int>.value(0);

  static Future<int> next() {
    final result = _chain.then((_) => _allocate());
    _chain = result.catchError((_) => 0);
    return result;
  }

  static Future<int> _allocate() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(prefKey) ?? 0;
      final seq = now > last ? now : last + 1;
      await prefs.setInt(prefKey, seq);
      return seq;
    } catch (_) {
      return now;
    }
  }
}
