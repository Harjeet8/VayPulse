import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/alert.dart';
import 'alert_service.dart';
import 'sensor_data_provider.dart';
import 'settings_service.dart';

/// Mirrors only high-value in-app alerts into Android's notification tray.
///
/// Deliberately conservative: Simulation and ESP32 each receive at most two
/// tray notifications per app run, duplicate alert types are ignored, and two
/// phone notifications from the same mode can never arrive as a burst.
class PhoneNotificationService {
  static const MethodChannel _channel =
      MethodChannel('ai.phytosense.app/notifications');
  static const Duration _minimumGap = Duration(seconds: 90);

  final AlertService alerts;
  final SettingsService settings;

  final Set<String> _seenAlertIds = <String>{};
  final Set<String> _simulationTypes = <String>{};
  final Set<String> _esp32Types = <String>{};
  final Map<SensorDataSource, DateTime> _lastPhoneAlertAt = {};

  bool _started = false;
  bool _draining = false;
  bool _permissionResolved = false;
  bool _permissionGranted = false;
  bool _platformUnavailable = false;

  PhoneNotificationService(this.alerts, this.settings);

  bool get _supportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void start() {
    if (_started || !_supportedPlatform) return;
    _started = true;
    _seenAlertIds.addAll(alerts.alerts.map((alert) => alert.id));
    alerts.addListener(_onAlertsChanged);
  }

  void _onAlertsChanged() {
    unawaited(_drainAlerts());
  }

  Future<void> _drainAlerts() async {
    if (_platformUnavailable || !settings.value.notificationsEnabled) return;
    if (_draining) return;

    _draining = true;
    try {
      final pending = alerts.alerts
          .where((alert) => !_seenAlertIds.contains(alert.id))
          .toList(growable: false);
      if (pending.isEmpty) return;

      // Mark the batch consumed even when only one item is mirrored. In-app
      // alert history remains complete; the phone tray intentionally stays calm.
      _seenAlertIds.addAll(pending.map((alert) => alert.id));

      final source = alerts.sensors.source;
      final sentTypes =
          source == SensorDataSource.esp32 ? _esp32Types : _simulationTypes;
      if (sentTypes.length >= 2) return;

      final lastSent = _lastPhoneAlertAt[source];
      if (lastSent != null && DateTime.now().difference(lastSent) < _minimumGap) {
        return;
      }

      final candidates = pending
          .where(_isPhoneWorthy)
          .where((alert) => !sentTypes.contains(alert.titleKey))
          .toList(growable: false)
        ..sort((a, b) => _priority(b).compareTo(_priority(a)));
      if (candidates.isEmpty) return;

      final allowed = await _ensurePermission();
      if (!allowed) return;

      final alert = candidates.first;
      final strings = AppStrings(settings.value.languageCode);
      final isEsp32 = source == SensorDataSource.esp32;
      final slot = sentTypes.length + 1;

      try {
        await _channel.invokeMethod<void>('showNotification', {
          'title': strings.text(alert.titleKey),
          'body': strings.text(alert.messageKey),
          'mode': isEsp32 ? 'esp32' : 'simulation',
          'severity': alert.severity.name,
          'slot': slot,
        });
        sentTypes.add(alert.titleKey);
        _lastPhoneAlertAt[source] = DateTime.now();
      } on MissingPluginException {
        _platformUnavailable = true;
      } on PlatformException {
        // The in-app alert is still authoritative if Android rejects the tray
        // operation for any device-specific reason.
      }
    } finally {
      _draining = false;
    }
  }

  int _priority(PlantAlert alert) {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return 3;
      case AlertSeverity.warning:
        return 2;
      case AlertSeverity.info:
        return 1;
    }
  }

  bool _isPhoneWorthy(PlantAlert alert) {
    if (alert.nodeId == 'weather') return false;
    if (alert.severity == AlertSeverity.critical ||
        alert.severity == AlertSeverity.warning) {
      return true;
    }
    return alert.titleKey == 'alert_plant_recovering';
  }

  Future<bool> _ensurePermission() async {
    if (_permissionResolved) return _permissionGranted;
    _permissionResolved = true;
    try {
      _permissionGranted =
          await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      _platformUnavailable = true;
      _permissionGranted = false;
    } on PlatformException {
      _permissionGranted = false;
    }
    return _permissionGranted;
  }

  void dispose() {
    if (!_started) return;
    alerts.removeListener(_onAlertsChanged);
    _started = false;
  }
}
