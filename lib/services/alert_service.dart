import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../models/sensor_reading.dart';
import 'farm_repository.dart';
import 'settings_service.dart';
import 'sensor_data_provider.dart';
import 'weather_service.dart';

class AlertService extends ChangeNotifier {
  final SensorDataProvider sensors;
  final SettingsService settings;
  final WeatherService weather;
  final FarmRepository farms;
  final List<PlantAlert> alerts = [];
  final Map<String, DateTime> _lastAlertAt = {};
  final Map<String, bool> _bioticActive = {};
  StreamSubscription<SensorReading>? _subscription;
  SensorDataSource? _lastSource;

  AlertService(this.sensors, this.settings, this.weather, this.farms);

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

    if (sensors.source == SensorDataSource.esp32 &&
        sensors.edgeIntelligence?.hasAuthoritativeAnalysis == true) {
      _evaluateEdgeIntelligence(reading);
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

  void _evaluateEdgeIntelligence(SensorReading reading) {
    final edge = sensors.edgeIntelligence;
    if (edge == null) return;

    final bioticNow = edge.bioticStress.suspected;
    final bioticBefore = _bioticActive[reading.nodeId] ?? false;
    _bioticActive[reading.nodeId] = bioticNow;
    if (!bioticNow && bioticBefore) {
      _lastAlertAt.remove('${reading.nodeId}:alert_possible_biotic');
    }

    if (edge.sensorFaults.isNotEmpty || edge.degradedAnalysis) {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: 'alert_sensor_attention',
        messageKey: 'alert_sensor_attention_message',
        severity: AlertSeverity.warning,
      );
    }

    final state = edge.plantState?.toUpperCase() ?? '';
    if (edge.recovery.active || state == 'RECOVERING') {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: 'alert_plant_recovering',
        messageKey: 'alert_plant_recovering_message',
        severity: AlertSeverity.info,
      );
      return;
    }

    if (bioticNow && !bioticBefore) {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: 'alert_possible_biotic',
        messageKey: 'alert_possible_biotic_message',
        severity: AlertSeverity.warning,
        cooldown: const Duration(hours: 6),
      );
      return;
    }
    if (bioticNow) return;

    final cause =
        (edge.rootCause.primary ?? edge.farmerSummary ?? '').toUpperCase();
    if (cause.contains('WATER') ||
        cause.contains('DRY') ||
        cause.contains('MOISTURE')) {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: 'alert_water_stress_edge',
        messageKey: 'alert_water_stress_edge_message',
        severity: state.contains('CRITICAL')
            ? AlertSeverity.critical
            : AlertSeverity.warning,
      );
    } else if (cause.contains('HEAT') ||
        cause.contains('HOT') ||
        cause.contains('THERMAL')) {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: 'alert_heat_stress_edge',
        messageKey: 'alert_heat_stress_edge_message',
        severity: state.contains('CRITICAL')
            ? AlertSeverity.critical
            : AlertSeverity.warning,
      );
    } else if (cause.contains('ROOT')) {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: 'alert_root_stress_edge',
        messageKey: 'alert_root_stress_edge_message',
        severity: AlertSeverity.warning,
      );
    } else if (state.contains('STRESS') ||
        state.contains('ATTENTION') ||
        state.contains('CRITICAL')) {
      _addAlert(
        nodeId: reading.nodeId,
        titleKey: 'alert_plant_stress_edge',
        messageKey: 'alert_plant_stress_edge_message',
        severity: state.contains('CRITICAL')
            ? AlertSeverity.critical
            : AlertSeverity.warning,
      );
    }
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
      _bioticActive.clear();
      notifyListeners();
    }
    if (sensors.connectionStatus == SensorConnectionStatus.error) {
      _addAlert(
        nodeId: sensors.selectedNodeId,
        titleKey: 'alert_sensor_attention',
        messageKey: 'alert_sensor_attention_message',
        severity: AlertSeverity.warning,
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
        severity: severity,
      ),
    );
    if (alerts.length > 40) alerts.removeLast();
    notifyListeners();
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
    _bioticActive.clear();
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
