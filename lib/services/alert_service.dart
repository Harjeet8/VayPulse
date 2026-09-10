import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/alert.dart';
import '../models/sensor_reading.dart';
import 'farm_repository.dart';
import 'farmer_language_service.dart';
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
  final Map<String, AlertSeverity> _lastAlertSeverity = {};
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

    final status = reading.healthStatus.trim().toUpperCase();
    final priority = reading.priority.trim().toUpperCase();
    const healthAttention = <String>{'WATCH', 'STRESS', 'CRITICAL'};
    const priorityAttention = <String>{
      'CHECK',
      'WATCH',
      'STRESS',
      'HIGH',
      'CRITICAL',
      'URGENT',
    };

    final needsAttention = healthAttention.contains(status) ||
        priorityAttention.contains(priority);
    if (!needsAttention) return;

    final critical = status == 'CRITICAL' ||
        priority == 'CRITICAL' ||
        priority == 'URGENT';
    final problem = FarmerLanguageService.hardwareProblem(
      rootCause: reading.primaryRootCause,
      because: reading.because,
      needsAttention: true,
    );
    final solution = FarmerLanguageService.hardwareSolution(
      farmerAction: reading.farmerAction,
      problem: problem,
    );

    _addAlert(
      nodeId: reading.nodeId,
      titleKey: 'alert_edge_decision',
      messageKey: 'alert_abnormal_sensor_message',
      titleText: problem,
      messageText: solution,
      severity: critical ? AlertSeverity.critical : AlertSeverity.warning,
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
      _lastAlertSeverity.clear();
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
    Duration cooldown = const Duration(minutes: 5),
  }) {
    final dedupeKey = '$nodeId:$titleKey';
    final last = _lastAlertAt[dedupeKey];
    final previousSeverity = _lastAlertSeverity[dedupeKey];
    final escalated = previousSeverity != null &&
        severity.index > previousSeverity.index;
    if (last != null &&
        DateTime.now().difference(last) < cooldown &&
        !escalated) {
      return;
    }

    _lastAlertAt[dedupeKey] = DateTime.now();
    _lastAlertSeverity[dedupeKey] = severity;
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
      'alert_severe_dryness' => 'The soil is very dry',
      'alert_low_moisture' => 'The soil is getting dry',
      'alert_overwatering' => 'The soil may be too wet',
      'alert_heat_stress' => 'The plant may be too hot',
      'alert_low_light' => 'The plant may need more light',
      'alert_low_battery' => 'The PhytoSense battery is low',
      'alert_weak_signal' => 'The PhytoSense connection is weak',
      'alert_abnormal_sensor' => 'A sensor needs a quick check',
      'alert_heavy_rain' => 'Heavy rain may affect the field',
      'alert_disease_risk' => 'Check the crop for disease signs',
      'alert_dry_spell' => 'Dry weather may continue',
      _ => 'PhytoSense AI alert',
    };
  }

  String _notificationMessage(String key, String? override) {
    if (override != null && override.trim().isNotEmpty) return override.trim();
    return switch (key) {
      'alert_severe_dryness_message' =>
        'Check the soil near the roots. Water only if it is actually dry.',
      'alert_low_moisture_message' =>
        'Check the soil near the roots before adding water.',
      'alert_overwatering_message' =>
        'Do not add more water now. Check soil wetness and drainage.',
      'alert_heat_stress_message' =>
        'Check the plant and soil moisture during the hottest part of the day.',
      'alert_low_light_message' =>
        'Check for shade or anything blocking the light sensor.',
      'alert_low_battery_message' =>
        'Recharge or replace the sensor node power source soon.',
      'alert_weak_signal_message' =>
        'Check the node power, distance, and network connection.',
      'alert_abnormal_sensor_message' =>
        'Check the sensor connection, then open PhytoSense AI for the latest reading.',
      'alert_heavy_rain_message' =>
        'Check field drainage and protect areas that may collect water.',
      'alert_disease_risk_message' =>
        'Look at the leaves and wet areas for early signs of disease.',
      'alert_dry_spell_message' =>
        'Check the soil before deciding whether the crop needs water.',
      _ => 'Open PhytoSense AI to see what is wrong and what to do next.',
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
    _lastAlertSeverity.clear();
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
