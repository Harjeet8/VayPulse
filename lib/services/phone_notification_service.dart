import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/alert.dart';
import '../models/edge_intelligence.dart';
import '../models/sensor_reading.dart';
import 'alert_service.dart';
import 'sensor_data_provider.dart';
import 'settings_service.dart';

/// Mirrors meaningful PhytoSense decisions into Android's notification tray.
///
/// This is intentionally not a fixed "two notifications per session" system.
/// A condition-aware throttle allows new or worsening plant conditions through,
/// suppresses repeated copies of the same condition, and applies a short burst
/// guard so live polling can never turn into notification spam.
class PhoneNotificationService {
  static const MethodChannel _channel =
      MethodChannel('ai.phytosense.app/notifications');

  static const Duration _minimumGap = Duration(seconds: 45);
  static const Duration _criticalMinimumGap = Duration(seconds: 18);
  static const Duration _warningRepeatGap = Duration(minutes: 15);
  static const Duration _criticalRepeatGap = Duration(minutes: 6);
  static const Duration _recoveryRepeatGap = Duration(minutes: 20);
  static const Duration _burstWindow = Duration(minutes: 10);
  static const int _softBurstLimit = 3;
  static const int _hardBurstLimit = 4;

  final AlertService alerts;
  final SettingsService settings;

  final Set<String> _seenAlertIds = <String>{};
  final Map<String, DateTime> _lastTypeAt = <String, DateTime>{};
  final Map<SensorDataSource, DateTime> _lastPhoneAlertAt = {};
  final Map<SensorDataSource, int> _lastPriority = {};
  final Map<SensorDataSource, List<DateTime>> _recentSends = {};
  int _sequence = 0;

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
      final candidates = pending.where(_isPhoneWorthy).toList(growable: false)
        ..sort((a, b) => _priority(b).compareTo(_priority(a)));
      if (candidates.isEmpty) return;

      PlantAlert? chosen;
      for (final candidate in candidates) {
        if (_canSend(candidate, source)) {
          chosen = candidate;
          break;
        }
      }
      if (chosen == null) return;

      final allowed = await _ensurePermission();
      if (!allowed) return;

      final strings = AppStrings(settings.value.languageCode);
      final copy = _notificationCopy(chosen, strings, source);
      final isEsp32 = source == SensorDataSource.esp32;
      // Keep one current card per source. When the condition changes or
      // escalates, the new decision replaces the old card instead of stacking.
      final notificationTag =
          'phytosense:${isEsp32 ? 'live-current' : 'demo-current'}';
      final sequence = ++_sequence;

      try {
        await _channel.invokeMethod<void>('showNotification', {
          'title': copy.title,
          'body': copy.body,
          'mode': isEsp32 ? 'esp32' : 'simulation',
          'severity': chosen.severity.name,
          'sequence': sequence,
          'summary': copy.summary,
          'notificationTag': notificationTag,
          'actionLabel': 'Open analysis',
        });
        _recordSend(chosen, source);
      } on MissingPluginException {
        _platformUnavailable = true;
      } on PlatformException {
        // In-app alerts remain authoritative if Android rejects a tray update
        // for a device-specific reason.
      }
    } finally {
      _draining = false;
    }
  }

  bool _canSend(PlantAlert alert, SensorDataSource source) {
    final now = DateTime.now();
    final priority = _priority(alert);
    final typeKey = '$source:${alert.titleKey}:${alert.severity.name}';
    final lastSameType = _lastTypeAt[typeKey];
    final repeatGap = alert.titleKey == 'alert_plant_recovering'
        ? _recoveryRepeatGap
        : alert.severity == AlertSeverity.critical
            ? _criticalRepeatGap
            : _warningRepeatGap;

    if (lastSameType != null && now.difference(lastSameType) < repeatGap) {
      return false;
    }

    final previousPriority = _lastPriority[source] ?? 0;
    final escalating = priority > previousPriority;
    final lastAny = _lastPhoneAlertAt[source];
    if (lastAny != null) {
      final elapsed = now.difference(lastAny);
      if (escalating && alert.severity == AlertSeverity.critical) {
        if (elapsed < _criticalMinimumGap) return false;
      } else if (elapsed < _minimumGap) {
        return false;
      }
    }

    final recent = _recentSends.putIfAbsent(source, () => <DateTime>[]);
    recent.removeWhere((time) => now.difference(time) > _burstWindow);
    if (recent.length >= _hardBurstLimit) return false;
    if (recent.length >= _softBurstLimit &&
        alert.severity != AlertSeverity.critical) {
      return false;
    }

    return true;
  }

  void _recordSend(PlantAlert alert, SensorDataSource source) {
    final now = DateTime.now();
    final typeKey = '$source:${alert.titleKey}:${alert.severity.name}';
    _lastTypeAt[typeKey] = now;
    _lastPhoneAlertAt[source] = now;
    _lastPriority[source] = _priority(alert);
    _recentSends.putIfAbsent(source, () => <DateTime>[]).add(now);
  }

  _PhoneCopy _notificationCopy(
    PlantAlert alert,
    AppStrings strings,
    SensorDataSource source,
  ) {
    final edge = alerts.sensors.edgeIntelligence;
    final reading = alerts.sensors.current;
    final disconnected = source == SensorDataSource.esp32 &&
        alerts.sensors.connectionStatus != SensorConnectionStatus.ready;

    final friendlyTitle = disconnected && alert.titleKey == 'alert_sensor_attention'
        ? 'ESP32 connection lost'
        : _friendlyTitles[alert.titleKey];
    final friendlyBody = disconnected && alert.titleKey == 'alert_sensor_attention'
        ? 'Live analysis is paused. Reconnect the PhytoSense node; old readings will not be treated as current plant data.'
        : _friendlyBodies[alert.messageKey];

    final localizedTitle = strings.text(alert.titleKey);
    final localizedBody = strings.text(alert.messageKey);
    final titleText = friendlyTitle ??
        (_isRawKey(localizedTitle, alert.titleKey)
            ? _humanize(alert.titleKey)
            : localizedTitle);
    final localizedMessage = friendlyBody ??
        (_isRawKey(localizedBody, alert.messageKey)
            ? _humanize(alert.messageKey)
            : localizedBody);

    final metric = _metricContext(alert, reading);
    final bodyText = disconnected && alert.titleKey == 'alert_sensor_attention'
        ? 'Reconnect the sensor to continue live monitoring.'
        : _farmerAction(alert.messageKey, fallback: localizedMessage);

    final confidence = _confidence(edge, reading);
    final sourceLabel = source == SensorDataSource.esp32
        ? 'LIVE ESP32'
        : 'DEMO DATA';
    final summaryParts = <String>[sourceLabel];
    if (metric != null) summaryParts.add(metric);
    if (confidence != null) {
      summaryParts.add('${confidence.round()}% confidence');
    }

    return _PhoneCopy(
      title: _clean(titleText),
      body: _clean(bodyText),
      summary: summaryParts.join(' • '),
    );
  }

  String? _metricContext(PlantAlert alert, SensorReading? reading) {
    if (reading == null) return null;
    final key = alert.titleKey;
    if ((key.contains('water') ||
            key.contains('moisture') ||
            key.contains('dry') ||
            key.contains('overwatering')) &&
        reading.soilMoistureAvailable) {
      return 'Soil ${reading.soilMoisture.round()}%';
    }
    if ((key.contains('heat') || key.contains('temperature')) &&
        reading.temperatureAvailable) {
      return '${reading.temperature.toStringAsFixed(1)}°C';
    }
    if (key.contains('plant_stress') && reading.plantSignalAvailable) {
      return 'Plant signal ${reading.bioSignalQuality.round()}%';
    }
    return null;
  }

  double? _confidence(EdgeIntelligence? edge, SensorReading? reading) {
    final value = edge?.overallConfidence ??
        reading?.esp32HealthConfidence ??
        reading?.analysisConfidence;
    if (value == null || !value.isFinite) return null;
    return value.clamp(0.0, 100.0).toDouble();
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
    'alert_severe_dryness': 'Soil is critically dry',
    'alert_low_moisture': 'Soil moisture is low',
    'alert_overwatering': 'Soil is staying too wet',
    'alert_heat_stress': 'Heat stress is rising',
    'alert_low_light': 'The crop needs more light',
    'alert_sensor_attention': 'Check the plant sensor',
    'alert_plant_recovering': 'The plant is recovering',
    'alert_possible_biotic': 'Inspect the plant for damage',
    'alert_water_stress_edge': 'Water stress is rising',
    'alert_heat_stress_edge': 'Heat stress is rising',
    'alert_root_stress_edge': 'The root zone needs attention',
    'alert_plant_stress_edge': 'Plant stress is confirmed',
    'alert_low_battery': 'Sensor battery is low',
    'alert_weak_signal': 'ESP32 signal is weak',
  };

  static const Map<String, String> _friendlyBodies = {
    'alert_severe_dryness_message':
        'The root zone is critically dry. Check moisture near the active roots and irrigate if the soil is genuinely dry.',
    'alert_low_moisture_message':
        'Root-zone moisture is moving below the preferred range. Check the soil before deciding whether irrigation is needed.',
    'alert_overwatering_message':
        'The root zone is staying unusually wet. Avoid adding more water until drainage and soil condition are checked.',
    'alert_heat_stress_message':
        'The plant is under high heat load. Check water availability and reduce avoidable heat exposure where practical.',
    'alert_low_light_message':
        'Available light is below the expected range. Check shading or placement before making any change.',
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
        'Multiple independent signals agree that the plant needs attention. Open PhytoSense to see the leading cause and evidence.',
    'alert_low_battery_message':
        'The sensor node battery is getting low. Recharge or replace its power source before live monitoring is interrupted.',
    'alert_weak_signal_message':
        'The ESP32 connection is weak. Move the node or phone closer to the Wi-Fi source for more reliable live data.',
  };

  static const Map<String, String> _farmerActions = {
    'alert_severe_dryness_message':
        'Check soil near the roots and water if it is dry.',
    'alert_low_moisture_message':
        'Check soil near the roots before watering.',
    'alert_overwatering_message':
        'Pause watering and check the field drainage.',
    'alert_heat_stress_message':
        'Check water supply and reduce avoidable heat exposure.',
    'alert_low_light_message': 'Check for excess shade around the crop.',
    'alert_sensor_attention_message':
        'Check the sensor contact and connection.',
    'alert_plant_recovering_message':
        'Keep monitoring; no immediate change is needed.',
    'alert_possible_biotic_message':
        'Inspect leaves and stems before choosing a treatment.',
    'alert_water_stress_edge_message':
        'Check soil near the roots before watering.',
    'alert_heat_stress_edge_message':
        'Check water supply and protect the crop from excess heat.',
    'alert_root_stress_edge_message':
        'Check soil moisture, drainage and root temperature.',
    'alert_plant_stress_edge_message':
        'Open the analysis and check the main cause.',
    'alert_low_battery_message': 'Recharge the sensor node soon.',
    'alert_weak_signal_message':
        'Move the node closer to the Wi-Fi source.',
  };

  String _farmerAction(String messageKey, {required String fallback}) {
    final action = _farmerActions[messageKey];
    if (action != null) return action;
    final clean = _clean(fallback);
    if (clean.length <= 110) return clean;
    return 'Open PhytoSense to check the cause and next action.';
  }
}

class _PhoneCopy {
  final String title;
  final String body;
  final String summary;

  const _PhoneCopy({
    required this.title,
    required this.body,
    required this.summary,
  });
}
