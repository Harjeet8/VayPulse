import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sensor_reading.dart';
import 'sensor_data_provider.dart';

class ExperimentTrial {
  final String id;
  final String title;
  final String crop;
  final String source;
  final String nodeId;
  final DateTime startedAt;
  final DateTime endedAt;
  final double baselineHealth;
  final double minimumHealth;
  final double maximumStress;
  final int sampleCount;
  final String outcome;
  final String notes;

  const ExperimentTrial({
    required this.id,
    required this.title,
    required this.crop,
    required this.source,
    required this.nodeId,
    required this.startedAt,
    required this.endedAt,
    required this.baselineHealth,
    required this.minimumHealth,
    required this.maximumStress,
    required this.sampleCount,
    required this.outcome,
    required this.notes,
  });

  Duration get duration => endedAt.difference(startedAt);
  double get healthChange => minimumHealth - baselineHealth;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'crop': crop,
        'source': source,
        'nodeId': nodeId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'baselineHealth': baselineHealth,
        'minimumHealth': minimumHealth,
        'maximumStress': maximumStress,
        'sampleCount': sampleCount,
        'outcome': outcome,
        'notes': notes,
      };

  factory ExperimentTrial.fromJson(Map<String, dynamic> json) =>
      ExperimentTrial(
        id: '${json['id']}',
        title: '${json['title']}',
        crop: '${json['crop']}',
        source: '${json['source']}',
        nodeId: '${json['nodeId']}',
        startedAt: DateTime.parse('${json['startedAt']}'),
        endedAt: DateTime.parse('${json['endedAt']}'),
        baselineHealth: (json['baselineHealth'] as num).toDouble(),
        minimumHealth: (json['minimumHealth'] as num).toDouble(),
        maximumStress: (json['maximumStress'] as num).toDouble(),
        sampleCount: (json['sampleCount'] as num).toInt(),
        outcome: '${json['outcome']}',
        notes: '${json['notes'] ?? ''}',
      );
}

class CalibrationProfile {
  final String nodeId;
  final String source;
  final DateTime calibratedAt;
  final int sampleCount;
  final int trustScore;
  final double soilBaseline;
  final double temperatureBaseline;
  final double humidityBaseline;
  final double lightBaseline;
  final double electrodeBaseline;

  const CalibrationProfile({
    required this.nodeId,
    required this.source,
    required this.calibratedAt,
    required this.sampleCount,
    required this.trustScore,
    required this.soilBaseline,
    required this.temperatureBaseline,
    required this.humidityBaseline,
    required this.lightBaseline,
    required this.electrodeBaseline,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'source': source,
        'calibratedAt': calibratedAt.toIso8601String(),
        'sampleCount': sampleCount,
        'trustScore': trustScore,
        'soilBaseline': soilBaseline,
        'temperatureBaseline': temperatureBaseline,
        'humidityBaseline': humidityBaseline,
        'lightBaseline': lightBaseline,
        'electrodeBaseline': electrodeBaseline,
      };

  factory CalibrationProfile.fromJson(Map<String, dynamic> json) =>
      CalibrationProfile(
        nodeId: '${json['nodeId']}',
        source: '${json['source']}',
        calibratedAt: DateTime.parse('${json['calibratedAt']}'),
        sampleCount: (json['sampleCount'] as num).toInt(),
        trustScore: (json['trustScore'] as num).toInt(),
        soilBaseline: (json['soilBaseline'] as num).toDouble(),
        temperatureBaseline: (json['temperatureBaseline'] as num).toDouble(),
        humidityBaseline: (json['humidityBaseline'] as num).toDouble(),
        lightBaseline: (json['lightBaseline'] as num).toDouble(),
        electrodeBaseline: (json['electrodeBaseline'] as num).toDouble(),
      );
}

class FarmerFeedback {
  final String alertId;
  final String source;
  final String nodeId;
  final DateTime recordedAt;
  final bool conditionConfirmed;
  final bool recommendationUseful;
  final bool plantRecovered;
  final bool falseAlert;
  final String notes;

  const FarmerFeedback({
    required this.alertId,
    required this.source,
    required this.nodeId,
    required this.recordedAt,
    required this.conditionConfirmed,
    required this.recommendationUseful,
    required this.plantRecovered,
    required this.falseAlert,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'alertId': alertId,
        'source': source,
        'nodeId': nodeId,
        'recordedAt': recordedAt.toIso8601String(),
        'conditionConfirmed': conditionConfirmed,
        'recommendationUseful': recommendationUseful,
        'plantRecovered': plantRecovered,
        'falseAlert': falseAlert,
        'notes': notes,
      };

  factory FarmerFeedback.fromJson(Map<String, dynamic> json) => FarmerFeedback(
        alertId: '${json['alertId']}',
        source: '${json['source'] ?? 'legacy'}',
        nodeId: '${json['nodeId'] ?? 'unknown'}',
        recordedAt: DateTime.parse('${json['recordedAt']}'),
        conditionConfirmed: json['conditionConfirmed'] == true,
        recommendationUseful: json['recommendationUseful'] == true,
        plantRecovered: json['plantRecovered'] == true,
        falseAlert: json['falseAlert'] == true,
        notes: '${json['notes'] ?? ''}',
      );
}

class EngineeringEvidenceService extends ChangeNotifier {
  final SensorDataProvider sensors;
  final List<ExperimentTrial> _trials = [];
  final Map<String, FarmerFeedback> _feedback = {};
  final Map<String, CalibrationProfile> _calibrations = {};
  final List<SensorReading> _calibrationSamples = [];
  StreamSubscription<SensorReading>? _subscription;
  _ActiveExperiment? _active;
  String? _lastSource;

  EngineeringEvidenceService(this.sensors);

  List<ExperimentTrial> get trials => List.unmodifiable(_trials);
  List<FarmerFeedback> get feedback => List.unmodifiable(_feedback.values);
  List<ExperimentTrial> trialsForSource(String source) =>
      List.unmodifiable(_trials.where((item) => item.source == source));
  List<FarmerFeedback> feedbackForSource(String source) => List.unmodifiable(
        _feedback.values.where((item) => item.source == source),
      );
  CalibrationProfile? get calibration => _calibrations[sensors.source.name];
  List<SensorReading> get calibrationSamples =>
      List.unmodifiable(_calibrationSamples);
  bool get trialActive => _active != null;
  int get activeSampleCount => _active?.sampleCount ?? 0;
  double get activeMinimumHealth => _active?.minimumHealth ?? 0;
  double get activeMaximumStress => _active?.maximumStress ?? 0;

  int get confirmedFeedbackCount => feedbackForSource(sensors.source.name)
      .where((item) => item.conditionConfirmed)
      .length;
  int get usefulFeedbackCount => feedbackForSource(sensors.source.name)
      .where((item) => item.recommendationUseful)
      .length;
  int get falseAlertCount => feedbackForSource(sensors.source.name)
      .where((item) => item.falseAlert)
      .length;

  FarmerFeedback? feedbackFor(String alertId) {
    final value = _feedback[alertId];
    return value?.source == sensors.source.name ? value : null;
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final rawTrials = jsonDecode(
        preferences.getString('engineeringTrials') ?? '[]',
      ) as List;
      _trials.addAll(rawTrials.map((item) =>
          ExperimentTrial.fromJson(Map<String, dynamic>.from(item as Map))));
    } catch (_) {
      _trials.clear();
    }
    try {
      final rawFeedback = jsonDecode(
        preferences.getString('farmerFeedback') ?? '[]',
      ) as List;
      for (final item in rawFeedback) {
        final value = FarmerFeedback.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        _feedback[value.alertId] = value;
      }
    } catch (_) {
      _feedback.clear();
    }
    try {
      final rawCalibrations = preferences.getString('sensorCalibrations');
      if (rawCalibrations != null) {
        final values = Map<String, dynamic>.from(
          jsonDecode(rawCalibrations) as Map,
        );
        for (final entry in values.entries) {
          _calibrations[entry.key] = CalibrationProfile.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      } else {
        final legacy = preferences.getString('sensorCalibration');
        if (legacy != null) {
          final value = CalibrationProfile.fromJson(
            Map<String, dynamic>.from(jsonDecode(legacy) as Map),
          );
          _calibrations[value.source] = value;
        }
      }
    } catch (_) {
      _calibrations.clear();
    }
    notifyListeners();
  }

  void start() {
    if (_subscription != null) return;
    _lastSource = sensors.source.name;
    _subscription = sensors.stream.listen(_onReading);
    sensors.addListener(_onProviderChange);
  }

  bool startTrial({required String title, required String crop}) {
    final reading = sensors.current;
    if (reading == null || _active != null) return false;
    _active = _ActiveExperiment(
      title: title.trim().isEmpty ? 'Plant response trial' : title.trim(),
      crop: crop,
      source: sensors.source.name,
      nodeId: reading.nodeId,
      startedAt: DateTime.now(),
      baselineHealth: reading.healthScore,
      minimumHealth: reading.healthScore,
      maximumStress: reading.stressScore,
      sampleCount: 1,
    );
    notifyListeners();
    return true;
  }

  Future<ExperimentTrial?> finishTrial({
    required String outcome,
    String notes = '',
  }) async {
    final active = _active;
    if (active == null) return null;
    final trial = ExperimentTrial(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: active.title,
      crop: active.crop,
      source: active.source,
      nodeId: active.nodeId,
      startedAt: active.startedAt,
      endedAt: DateTime.now(),
      baselineHealth: active.baselineHealth,
      minimumHealth: active.minimumHealth,
      maximumStress: active.maximumStress,
      sampleCount: active.sampleCount,
      outcome: outcome,
      notes: notes.trim(),
    );
    _trials.insert(0, trial);
    if (_trials.length > 40) _trials.removeLast();
    _active = null;
    await _persist();
    notifyListeners();
    return trial;
  }

  void cancelTrial() {
    _active = null;
    notifyListeners();
  }

  bool captureCalibrationSample() {
    final reading = sensors.current;
    if (reading == null) return false;
    _calibrationSamples.add(reading);
    if (_calibrationSamples.length > 12) _calibrationSamples.removeAt(0);
    notifyListeners();
    return true;
  }

  void resetCalibrationSamples() {
    _calibrationSamples.clear();
    notifyListeners();
  }

  Future<CalibrationProfile?> saveCalibration() async {
    if (_calibrationSamples.length < 3) return null;
    double average(double Function(SensorReading) select) =>
        _calibrationSamples.map(select).reduce((a, b) => a + b) /
        _calibrationSamples.length;
    final soil = average((item) => item.soilMoisture);
    final temperature = average((item) => item.temperature);
    final humidity = average((item) => item.humidity);
    final light = average((item) => item.light);
    final electrode = average((item) => item.plantSignal);
    final variation = <double>[
          _relativeSpread((item) => item.soilMoisture, soil),
          _relativeSpread((item) => item.temperature, temperature),
          _relativeSpread((item) => item.humidity, humidity),
          _relativeSpread((item) => item.light, light),
          _relativeSpread((item) => item.plantSignal, electrode),
        ].reduce((a, b) => a + b) /
        5;
    final trust = (100 - variation * 220).round().clamp(35, 99).toInt();
    final profile = CalibrationProfile(
      nodeId: sensors.selectedNodeId,
      source: sensors.source.name,
      calibratedAt: DateTime.now(),
      sampleCount: _calibrationSamples.length,
      trustScore: trust,
      soilBaseline: soil,
      temperatureBaseline: temperature,
      humidityBaseline: humidity,
      lightBaseline: light,
      electrodeBaseline: electrode,
    );
    _calibrations[profile.source] = profile;
    _calibrationSamples.clear();
    await _persist();
    notifyListeners();
    return profile;
  }

  double _relativeSpread(
    double Function(SensorReading) select,
    double average,
  ) {
    if (average.abs() < 0.001) return 1;
    final difference = _calibrationSamples
            .map((item) => (select(item) - average).abs())
            .reduce((a, b) => a + b) /
        _calibrationSamples.length;
    return difference / average.abs();
  }

  Future<void> saveFeedback(FarmerFeedback value) async {
    _feedback[value.alertId] = value;
    await _persist();
    notifyListeners();
  }

  void _onReading(SensorReading reading) {
    final active = _active;
    if (active == null || active.source != sensors.source.name) return;
    active.sampleCount++;
    if (reading.healthScore < active.minimumHealth) {
      active.minimumHealth = reading.healthScore;
    }
    if (reading.stressScore > active.maximumStress) {
      active.maximumStress = reading.stressScore;
    }
    notifyListeners();
  }

  void _onProviderChange() {
    final source = sensors.source.name;
    if (_lastSource == source) return;
    _lastSource = source;
    _active = null;
    _calibrationSamples.clear();
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'engineeringTrials',
      jsonEncode(_trials.map((item) => item.toJson()).toList()),
    );
    await preferences.setString(
      'farmerFeedback',
      jsonEncode(_feedback.values.map((item) => item.toJson()).toList()),
    );
    await preferences.setString(
      'sensorCalibrations',
      jsonEncode(_calibrations.map(
        (key, value) => MapEntry(key, value.toJson()),
      )),
    );
  }

  @override
  void dispose() {
    sensors.removeListener(_onProviderChange);
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    unawaited(_persist());
    super.dispose();
  }
}

class _ActiveExperiment {
  final String title;
  final String crop;
  final String source;
  final String nodeId;
  final DateTime startedAt;
  final double baselineHealth;
  double minimumHealth;
  double maximumStress;
  int sampleCount;

  _ActiveExperiment({
    required this.title,
    required this.crop,
    required this.source,
    required this.nodeId,
    required this.startedAt,
    required this.baselineHealth,
    required this.minimumHealth,
    required this.maximumStress,
    required this.sampleCount,
  });
}
