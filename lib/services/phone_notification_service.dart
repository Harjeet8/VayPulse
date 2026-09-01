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
/// Simulation and ESP32 each receive at most two tray notifications per app
/// run. Duplicate alert types are suppressed and notifications are spaced out.
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
      final copy = _notificationCopy(alert, strings);

      try {
        await _channel.invokeMethod<void>('showNotification', {
          'title': copy.title,
          'body': copy.body,
          'mode': isEsp32 ? 'esp32' : 'simulation',
          'severity': alert.severity.name,
          'slot': slot,
          'summary': isEsp32 ? 'Live value • ESP32' : 'Simulation • PhytoSense AI',
        });
        sentTypes.add(alert.titleKey);
        _lastPhoneAlertAt[source] = DateTime.now();
      } on MissingPluginException {
        _platformUnavailable = true;
      } on PlatformException {
        // The in-app alert remains authoritative if Android rejects the tray
        // operation for a device-specific reason.
      }
    } finally {
      _draining = false;
    }
  }

  _PhoneCopy _notificationCopy(PlantAlert alert, AppStrings strings) {
    final friendlyTitle = _friendlyTitles[alert.titleKey];
    final friendlyBody = _friendlyBodies[alert.messageKey];

    final localizedTitle = strings.text(alert.titleKey);
    final localizedBody = strings.text(alert.messageKey);

    final titleText = friendlyTitle ??
        (_isRawKey(localizedTitle, alert.titleKey)
            ? _humanize(alert.titleKey)
            : localizedTitle);
    final bodyText = friendlyBody ??
        (_isRawKey(localizedBody, alert.messageKey)
            ? _humanize(alert.messageKey)
            : localizedBody);

    final emoji = _emojiFor(alert.titleKey, alert.severity);
    final cleanTitle = _clean(titleText);
    final cleanBody = _clean(bodyText);

    return _PhoneCopy(
      title: '$emoji $cleanTitle',
      body: cleanBody,
    );
  }

  bool _isRawKey(String value, String key) =>
      value == key || value.startsWith('alert_') || value.contains('_message');

  String _clean(String value) => value
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _humanize(String key) {
    final words = key
        .replaceFirst(RegExp(r'^alert_'), '')
        .replaceFirst(RegExp(r'_message$'), '')
        .split('_')
        .where((part) => part.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'Plant update';
    final sentence = words.join(' ');
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}';
  }

  String _emojiFor(String titleKey, AlertSeverity severity) {
    if (titleKey.contains('recover')) return '🌱';
    if (titleKey.contains('water') ||
        titleKey.contains('moisture') ||
        titleKey.contains('dry')) {
      return severity == AlertSeverity.critical ? '🚨' : '💧';
    }
    if (titleKey.contains('heat') || titleKey.contains('temperature')) return '🌡️';
    if (titleKey.contains('root')) return '🌿';
    if (titleKey.contains('biotic')) return '🦠';
    if (titleKey.contains('battery')) return '🔋';
    if (titleKey.contains('signal')) return '📶';
    if (titleKey.contains('sensor')) return '🛠️';
    if (titleKey.contains('light')) return '☀️';
    return severity == AlertSeverity.critical ? '🚨' : '⚡';
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

  static const Map<String, String> _friendlyTitles = {
    'alert_severe_dryness': 'Soil critically dry',
    'alert_low_moisture': 'Soil moisture is dropping',
    'alert_overwatering': 'Soil is staying too wet',
    'alert_heat_stress': 'Heat stress is rising',
    'alert_low_light': 'Light level is low',
    'alert_sensor_attention': 'Sensor needs attention',
    'alert_plant_recovering': 'Plant is recovering',
    'alert_possible_biotic': 'Possible biotic stress pattern',
    'alert_water_stress_edge': 'Water-stress signal detected',
    'alert_heat_stress_edge': 'Heat-stress signal detected',
    'alert_root_stress_edge': 'Root-zone stress detected',
    'alert_plant_stress_edge': 'Plant stress signal detected',
    'alert_low_battery': 'Sensor battery is low',
    'alert_weak_signal': 'Sensor link is weak',
  };

  static const Map<String, String> _friendlyBodies = {
    'alert_sensor_attention_message':
        'One or more sensor channels need a quick check. Open PhytoSense for signal quality and connection details.',
    'alert_plant_recovering_message':
        'Good news — the plant response is moving back toward its recent baseline. Keep monitoring before changing anything.',
    'alert_possible_biotic_message':
        'PhytoSense found a pattern worth inspecting. Check the plant and leaf surfaces before deciding on any treatment.',
    'alert_water_stress_edge_message':
        'Soil and plant-response evidence point toward water stress. Inspect the root zone before irrigating.',
    'alert_heat_stress_edge_message':
        'Temperature and plant-response evidence indicate rising heat stress. Inspect the crop and reduce avoidable heat exposure.',
    'alert_root_stress_edge_message':
        'Root-zone evidence is outside the preferred range. Check moisture, drainage and root-zone temperature.',
    'alert_plant_stress_edge_message':
        'Multiple signals agree that the plant needs attention. Open PhytoSense to see the leading cause and evidence.',
    'alert_low_battery_message':
        'The sensor node battery is getting low. Recharge or replace its power source before live monitoring is interrupted.',
    'alert_weak_signal_message':
        'The ESP32 connection is weak. Move the node or phone closer to the Wi-Fi source for more reliable live data.',
  };
}

class _PhoneCopy {
  final String title;
  final String body;

  const _PhoneCopy({required this.title, required this.body});
}
