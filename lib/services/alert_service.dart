import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/alert.dart';
import '../models/sensor_reading.dart';
import 'farm_repository.dart';
import 'local_notification_service.dart';
import 'settings_service.dart';
import 'sensor_data_provider.dart';
import 'weather_service.dart';

class AlertService extends ChangeNotifier {
  final SensorDataProvider sensors;
  final SettingsService settings;
  final WeatherService weather;
  final FarmRepository farms;
  final LocalNotificationService localNotifications;
  final List<PlantAlert> alerts = [];
  final Map<String, DateTime> _lastAlertAt = {};
  StreamSubscription<SensorReading>? _subscription;
  SensorDataSource? _lastSource;

  AlertService(
    this.sensors,
    this.settings,
    this.weather,
    this.farms,
    this.localNotifications,
  );

  int get unreadCount => alerts.where((alert) => !alert.isRead).length;

  void start() {
    _lastSource = sensors.source;
    _subscription ??= sensors.stream.listen(_evaluate);
    sensors.addListener(_evaluateProviderState);
    weather.addListener(_evaluateWeather);
    _evaluateWeather();
  }

  void _evaluate(SensorReading reading) {
    if (!settings.value.notificationsEnabled) return;
    if (sensors.source == SensorDataSource.esp32) {
      _evaluateEdgeDecision(reading);
      _evaluateNodeHealth(reading.nodeId);
      return;
    }
    String? titleKey;
    String? messageKey;
    var severity = AlertSeverity.warning;

    if (reading.soilMoisture < 18) {
      titleKey = 'alert_severe_dryness';
      messageKey = 'alert_severe_dryness_message';
      severity = AlertSeverity.critical;
    } else if (reading.soilMoisture < 30) {
      titleKey = 'alert_low_moisture';
      messageKey = 'alert_low_moisture_message';
    } else if (reading.soilMoisture > 88 &&
        !_isFloodedRiceNode(reading.nodeId)) {
      titleKey = 'alert_overwatering';
      messageKey = 'alert_overwatering_message';
    } else if (reading.temperature > 34) {
      titleKey = 'alert_heat_stress';
      messageKey = 'alert_heat_stress_message';
      severity = AlertSeverity.critical;
    } else if (reading.light < 22) {
      titleKey = 'alert_low_light';
      messageKey = 'alert_low_light_message';
    }

    if (titleKey != null && messageKey != null) {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: titleKey,
        messageKey: messageKey,
        severity: severity,
      );
    }
    _evaluateNodeHealth(reading.nodeId);
  }

  void _evaluateEdgeDecision(SensorReading reading) {
    if (!reading.edgeAnalysisAvailable) return;
    final status = reading.healthStatus.toUpperCase();
    if (!const <String>{'WATCH', 'STRESS', 'CRITICAL'}.contains(status)) {
      return;
    }
    _addAlert(
      nodeId: reading.nodeId,
      titleKey: 'alert_edge_decision',
      messageKey: 'alert_abnormal_sensor_message',
      titleText: reading.primaryRootCause.isEmpty
          ? 'ESP32 plant-health alert'
          : reading.primaryRootCause.replaceAll('_', ' '),
      messageText: reading.farmerAction.isEmpty
          ? 'Open the live dashboard for the ESP32 recommendation.'
          : reading.farmerAction,
      severity:
          status == 'CRITICAL' ? AlertSeverity.critical : AlertSeverity.warning,
    );
  }

  bool _isFloodedRiceNode(String nodeId) {
    final matchingNodes = sensors.nodes.where((node) => node.id == nodeId);
    if (matchingNodes.isEmpty) return false;
    final fieldId = matchingNodes.first.fieldId;
    for (final farm in farms.farms) {
      for (final field in farm.fields) {
        if (field.id == fieldId) {
          final crop = field.crop.toLowerCase();
          return crop.contains('rice') || crop.contains('paddy');
        }
      }
    }
    return false;
  }

  void _evaluateNodeHealth(String nodeId) {
    final matchingNodes = sensors.nodes.where((item) => item.id == nodeId);
    final node = matchingNodes.isEmpty ? null : matchingNodes.first;
    if (node == null) return;
    if (node.batteryPercent <= 15) {
      _addAlert(
        nodeId: nodeId,
        titleKey: 'alert_low_battery',
        messageKey: 'alert_low_battery_message',
        severity: AlertSeverity.warning,
      );
    }
    if (node.signalPercent <= 25) {
      _addAlert(
        nodeId: nodeId,
        titleKey: 'alert_weak_signal',
        messageKey: 'alert_weak_signal_message',
        severity: AlertSeverity.warning,
      );
    }
  }

  void _evaluateProviderState() {
    if (_lastSource != sensors.source) {
      _lastSource = sensors.source;
      alerts.clear();
      _lastAlertAt.clear();
      notifyListeners();
    }
    if (sensors.connectionStatus == SensorConnectionStatus.error) {
      _addAlert(
        nodeId: sensors.selectedNodeId,
        titleKey: 'alert_abnormal_sensor',
        messageKey: 'alert_abnormal_sensor_message',
        severity: AlertSeverity.critical,
      );
    }
  }

  void _evaluateWeather() {
    if (sensors.source == SensorDataSource.esp32) return;
    final snapshot = weather.snapshot;
    if (snapshot == null ||
        !weather.isFresh ||
        !settings.value.notificationsEnabled) {
      return;
    }
    if (snapshot.heavyRainRisk) {
      _addAlert(
        nodeId: 'weather',
        titleKey: 'alert_heavy_rain',
        messageKey: 'alert_heavy_rain_message',
        severity: AlertSeverity.critical,
        cooldown: const Duration(hours: 6),
      );
    }
    if (snapshot.diseaseRisk) {
      _addAlert(
        nodeId: 'weather',
        titleKey: 'alert_disease_risk',
        messageKey: 'alert_disease_risk_message',
        severity: AlertSeverity.warning,
        cooldown: const Duration(hours: 6),
      );
    }
    if (snapshot.drySpellRisk) {
      _addAlert(
        nodeId: 'weather',
        titleKey: 'alert_dry_spell',
        messageKey: 'alert_dry_spell_message',
        severity: AlertSeverity.warning,
        cooldown: const Duration(hours: 6),
      );
    }
  }

  void _addAlert({
    required String nodeId,
    required String titleKey,
    required String messageKey,
    required AlertSeverity severity,
    String? titleText,
    String? messageText,
    Duration cooldown = const Duration(seconds: 25),
  }) {
    final dedupeKey = '$nodeId:$titleKey';
    final last = _lastAlertAt[dedupeKey];
    if (last != null && DateTime.now().difference(last) < cooldown) return;
    _lastAlertAt[dedupeKey] = DateTime.now();
    alerts.insert(
      0,
      PlantAlert(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nodeId: nodeId,
        timestamp: DateTime.now(),
        titleKey: titleKey,
        messageKey: messageKey,
        titleText: titleText,
        messageText: messageText,
        severity: severity,
      ),
    );
    if (alerts.length > 40) alerts.removeLast();
    notifyListeners();

    if (settings.value.notificationsEnabled) {
      unawaited(
        localNotifications.showAlert(
          title: _notificationTitle(titleKey, titleText),
          body: _notificationMessage(messageKey, messageText),
          critical: severity == AlertSeverity.critical,
        ),
      );
    }
  }

  String _notificationTitle(String key, String? override) {
    if (override != null && override.trim().isNotEmpty) return override.trim();
    return switch (key) {
      'alert_severe_dryness' => 'Severe dryness detected',
      'alert_low_moisture' => 'Low soil moisture',
      'alert_overwatering' => 'Very high soil moisture',
      'alert_heat_stress' => 'High temperature pattern',
      'alert_low_light' => 'Low light level',
      'alert_low_battery' => 'PhytoSense node battery low',
      'alert_weak_signal' => 'PhytoSense node signal weak',
      'alert_abnormal_sensor' => 'Sensor needs attention',
      'alert_heavy_rain' => 'Heavy rain risk',
      'alert_disease_risk' => 'Disease-favouring weather',
      'alert_dry_spell' => 'Dry spell risk',
      _ => 'PhytoSense AI alert',
    };
  }

  String _notificationMessage(String key, String? override) {
    if (override != null && override.trim().isNotEmpty) return override.trim();
    return switch (key) {
      'alert_severe_dryness_message' =>
        'Soil moisture is very low. Inspect this node and verify irrigation.',
      'alert_low_moisture_message' =>
        'Moisture dropped below the preferred range. Check the zone before watering.',
      'alert_overwatering_message' =>
        'The soil remains unusually wet. Check drainage and pause irrigation if needed.',
      'alert_heat_stress_message' =>
        'Air temperature is above the preferred range. Inspect for heat stress.',
      'alert_low_light_message' =>
        'Light has fallen below the expected range for this zone.',
      'alert_low_battery_message' =>
        'The sensor node battery is low. Recharge or replace its power source soon.',
      'alert_weak_signal_message' =>
        'The node connection is weak. Check distance, power and network conditions.',
      'alert_abnormal_sensor_message' =>
        'A live sensor or connection needs attention. Open PhytoSense AI for details.',
      'alert_heavy_rain_message' =>
        'Weather conditions indicate a heavy-rain risk. Check drainage and field exposure.',
      'alert_disease_risk_message' =>
        'Current weather may favour crop disease. Inspect leaves and wet areas early.',
      'alert_dry_spell_message' =>
        'Dry conditions may continue. Review soil moisture before planning irrigation.',
      _ => 'Open PhytoSense AI to review the latest farm condition.',
    };
  }

  void markAllRead() {
    for (final alert in alerts) {
      alert.isRead = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    for (final alert in alerts) {
      if (alert.id == id) alert.isRead = true;
    }
    notifyListeners();
  }

  void clear() {
    alerts.clear();
    _lastAlertAt.clear();
    notifyListeners();
  }

  PlantAlert? remove(String id) {
    final index = alerts.indexWhere((alert) => alert.id == id);
    if (index < 0) return null;
    final removed = alerts.removeAt(index);
    notifyListeners();
    return removed;
  }

  void restore(PlantAlert alert) {
    if (alerts.any((item) => item.id == alert.id)) return;
    alerts.insert(0, alert);
    notifyListeners();
  }

  @override
  void dispose() {
    sensors.removeListener(_evaluateProviderState);
    weather.removeListener(_evaluateWeather);
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }
}
