import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Is this the official VayPulse build, signed with Harjeet's release key?
///
/// A modified or repackaged copy has to be re-signed with someone else's key.
/// Such a copy is labelled "unofficial" on the About screen and may not send
/// commands to the node or write farm labels through the cloud.
///
/// This is a deterrent, not unbreakable protection: the real guards are the
/// signing key (kept private) and the Firebase security rules.
class AppIntegrity {
  AppIntegrity._();

  static const _channel = MethodChannel('com.harjeet.phytosense/integrity');

  /// null until checked; true when the check could not run (tests, iOS).
  static bool? _official;
  static Future<bool>? _pending;

  static bool? get official => _official;

  static Future<bool> check() => _pending ??= _check();

  static Future<bool> _check() async {
    try {
      final reply =
          await _channel.invokeMapMethod<String, dynamic>('check');
      _official = reply?['official'] != false;
    } on MissingPluginException {
      _official = true;
    } on PlatformException {
      _official = true;
    }
    return _official!;
  }

  /// Cloud commands and label uploads are only sent by official builds.
  static Future<bool> cloudAllowed() => check();

  @visibleForTesting
  static void overrideForTest(bool? value) {
    _official = value;
    _pending = value == null ? null : Future<bool>.value(value);
  }
}
