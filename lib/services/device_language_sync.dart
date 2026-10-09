import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../firebase_options.dart';
import 'control_seq.dart';
import 'firebase_remote_client.dart';
import 'node_addresses.dart';
import 'node_http.dart';
import 'settings_service.dart';

/// Keeps the PhytoSense node's speaker language identical to the app language.
///
/// The app language is the single source of truth: English app -> English
/// voice (SD folder 02), Tamil app -> Tamil voice (SD folder 01).
///
/// Two routes, either one is enough:
///  * LOCAL  - phone on the node's Wi-Fi: GET <endpoint>/api/audio?language=xx
///  * REMOTE - through Firebase: the node polls .../control and applies
///             `audio.language` whenever `seq` changes.
/// Until one route confirms, it retries quietly every 20 s, so a language
/// chosen while away from the node is applied as soon as the node is reachable.
class DeviceLanguageSync {
  static const controlPath = 'phytosense/nodes/phytosense_01/control';
  static const retryEvery = Duration(seconds: 20);

  final SettingsService settings;
  String? _synced; // language the node has confirmed
  String? _wanted;
  Timer? _retry;
  bool _busy = false;

  DeviceLanguageSync(this.settings);

  static String deviceCode(String appLanguage) =>
      appLanguage == 'ta' ? 'ta' : 'en';

  void start() {
    settings.addListener(_onSettings);
    _onSettings();
  }

  void dispose() {
    settings.removeListener(_onSettings);
    _retry?.cancel();
  }

  void _onSettings() {
    final code = deviceCode(settings.value.languageCode);
    if (code == _wanted && (code == _synced || _retry != null)) return;
    _wanted = code;
    _retry?.cancel();
    _retry = null;
    unawaited(_attempt());
  }

  Future<void> _attempt() async {
    final code = _wanted;
    if (code == null || code == _synced || _busy) return;
    _busy = true;
    try {
      final results = await Future.wait([_pushLocal(code), _pushRemote(code)]);
      if (results.any((ok) => ok) && code == _wanted) {
        _synced = code;
        _retry?.cancel();
        _retry = null;
        return;
      }
    } finally {
      _busy = false;
    }
    _retry ??= Timer.periodic(retryEvery, (_) => unawaited(_attempt()));
  }

  /// Direct to the node, at every known address at once (Wi-Fi routed,
  /// 1.5 s). Success only when HTTP 200 echoes the language that was sent.
  Future<bool> _pushLocal(String code) async {
    await NodeAddresses.load();
    final bases = NodeAddresses.candidates(settings);
    final results = await Future.wait(bases.map((base) async {
      try {
        final response =
            await NodeHttp.get(Uri.parse('$base/api/audio?language=$code'));
        return response.statusCode == 200 &&
            response.body.replaceAll(' ', '').contains('"language":"$code"');
      } catch (_) {
        return false;
      }
    }));
    for (var i = 0; i < bases.length; i++) {
      if (results[i]) {
        NodeAddresses.lastWorking = bases[i];
        return true;
      }
    }
    return false;
  }

  /// Through Firebase. `update` only touches these two keys, so display
  /// settings stored in the same control node are kept. A new `seq` is what
  /// makes the node apply the command.
  Future<bool> _pushRemote(String code) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final app = Firebase.app();
      final auth = FirebaseAuth.instanceFor(app: app);
      if (auth.currentUser == null) await auth.signInAnonymously();
      final db = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL: FirebaseRemoteClient.databaseUrl,
      );
      await db.ref(controlPath).update({
        'seq': await ControlSeq.next(),
        'audio/language': code,
        'audio/source': 'app',
      }).timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      return false;
    }
  }
}
