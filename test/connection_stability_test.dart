import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/models/hardware_transport.dart';
import 'package:phytosense_ai/services/control_seq.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('one late upload does not flip live -> offline', () {
    final now = DateTime(2026, 10, 9, 12);
    RemoteSnapshotFreshness at(int seconds) =>
        RemoteSnapshotFreshnessPolicy.classify(
            lastSeen: now.subtract(Duration(seconds: seconds)), now: now);
    expect(at(5), RemoteSnapshotFreshness.live);
    expect(at(25), RemoteSnapshotFreshness.live);
    expect(at(60), RemoteSnapshotFreshness.delayed);
    expect(at(120), RemoteSnapshotFreshness.stale);
    expect(at(600), RemoteSnapshotFreshness.stale);
  });

  test('only real NTP times are trusted, not uptime counters', () {
    final now = DateTime.utc(2026, 10, 9);
    expect(RemoteSnapshotFreshnessPolicy.isTrustedEpoch(
        now.subtract(const Duration(seconds: 3)), now: now), isTrue);
    expect(RemoteSnapshotFreshnessPolicy.isTrustedEpoch(
        DateTime.utc(1970, 1, 1, 0, 5), now: now), isFalse);
    expect(RemoteSnapshotFreshnessPolicy.isTrustedEpoch(
        now.add(const Duration(hours: 2)), now: now), isFalse);
    expect(RemoteSnapshotFreshnessPolicy.isTrustedEpoch(null, now: now), isFalse);
  });

  test('command seq always increases, even for taps in the same second',
      () async {
    SharedPreferences.setMockInitialValues({});
    final seqs = await Future.wait(List.generate(5, (_) => ControlSeq.next()));
    for (var i = 1; i < seqs.length; i++) {
      expect(seqs[i], greaterThan(seqs[i - 1]));
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    expect(seqs.first, greaterThanOrEqualTo(now - 1));
  });

  test('seq continues after a stored value from the future', () async {
    final far = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 5000;
    SharedPreferences.setMockInitialValues({ControlSeq.prefKey: far});
    expect(await ControlSeq.next(), far + 1);
  });
}
