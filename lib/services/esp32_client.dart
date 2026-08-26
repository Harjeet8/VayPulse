import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_reading.dart';

class Esp32Client {
  final String baseUrl;

  Esp32Client(String baseUrl)
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  static const _sensorPaths = <String>[
    '/api/sensors',
    '/api/v1/sensors',
    '/api/data',
    '/data',
    '/sensors',
  ];

  /// Reads the production PhytoSense firmware first, while keeping aliases for
  /// earlier bring-up builds. No internet or router is required: this is a
  /// direct HTTP request to the ESP32 access point at 192.168.4.1.
  Future<Esp32Snapshot> getSnapshot() async {
    for (final path in _sensorPaths) {
      final response = await _tryGet(path);
      if (response == null) continue;
      try {
        return _decodeSnapshot(response, endpoint: path);
      } on FormatException {
        // A compatibility endpoint may exist but expose an older shape. Keep
        // trying the remaining aliases before declaring the node invalid.
      }
    }
    throw Exception('PhytoSense ESP32 did not return a valid sensor payload');
  }

  Future<bool> ping() async {
    for (final path in const ['/api/status', '/status', '/api/sensors', '/sensors']) {
      if (await _tryGet(path) != null) return true;
    }
    return false;
  }

  Future<http.Response?> _tryGet(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200 ? response : null;
    } catch (_) {
      return null;
    }
  }

  Esp32Snapshot _decodeSnapshot(
    http.Response response, {
    required String endpoint,
  }) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid ESP32 JSON');
    }
    final root = Map<String, dynamic>.from(decoded);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final readings = _map(data['readings']);
    final air = _map(readings['air']);
    final soil = _map(readings['soil']);
    final light = _map(readings['light']);
    final leaf = _map(readings['leaf']);
    final bio = _map(readings['bioelectric']);
    final calibration = _map(data['calibration']);
    final components = _map(data['healthComponents']);
    final plantHealth = _map(data['plantHealth']);

    dynamic first(Iterable<dynamic> values) {
      for (final value in values) {
        if (value != null) return value;
      }
      return null;
    }

    final temperature = first([
      data['airTemperatureC'],
      data['temperatureC'],
      data['temperature'],
      air['temperatureC'],
      air['temperature'],
    ]);
    final humidity = first([
      data['humidityPercent'],
      data['humidity'],
      air['humidityPercent'],
      air['humidity'],
    ]);
    final soilMoisture = first([
      data['soilMoisturePercent'],
      data['soilMoisture'],
      soil['moisturePercent'],
      soil['soilMoisturePercent'],
    ]);
    final soilTemperature = first([
      data['soilTemperatureC'],
      data['soilTemperature'],
      soil['temperatureC'],
    ]);
    final lux = first([
      data['lux'],
      data['lightLux'],
      light['lux'],
      // Current production firmware may keep `light` as a flat lux alias.
      if (_asDouble(data['light']) != null && _asDouble(data['light'])! > 100)
        data['light'],
    ]);
    final legacyLight = first([
      if (_asDouble(data['light']) != null && _asDouble(data['light'])! <= 100)
        data['light'],
      data['lightPercent'],
    ]);
    final leafWetness = first([
      data['leafWetnessPercent'],
      data['leafWetness'],
      leaf['wetnessPercent'],
    ]);
    final plantVoltageMv = first([
      data['plantVoltageMv'],
      data['plantVoltage'],
      bio['amplifierOutputMv'],
    ]);
    final bioStability = first([
      data['bioelectricStability'],
      data['bioStability'],
      bio['stabilityPercent'],
      bio['stability'],
    ]);
    final bioQuality = first([
      data['bioSignalQuality'],
      bio['signalQualityPercent'],
      bio['signalQuality'],
    ]);

    final airValid = air['valid'] != false;
    final soilValid = soil['moistureValid'] != false;
    final rootValid = soil['temperatureValid'] != false;
    final lightValid = light['valid'] != false;
    final leafValid = leaf['valid'] != false;
    final bioValid = bio['valid'] != false;

    final tempValue = airValid ? _asDouble(temperature) : null;
    final humidityValue = airValid ? _asDouble(humidity) : null;
    final soilValue = soilValid ? _asDouble(soilMoisture) : null;
    final rootValue = rootValid ? _asDouble(soilTemperature) : null;
    final luxValue = lightValid ? _asDouble(lux) : null;
    final legacyLightValue = _asDouble(legacyLight);
    final normalizedLight = legacyLightValue ??
        (luxValue == null ? null : (luxValue / 70000 * 100).clamp(0, 100).toDouble());
    final leafValue = leafValid ? _asDouble(leafWetness) : null;
    final voltageValue = bioValid ? _asDouble(plantVoltageMv) : null;
    final stabilityValue = bioValid ? _asDouble(bioStability) : null;
    final qualityValue = bioValid ? _asDouble(bioQuality) : null;

    if (tempValue == null &&
        humidityValue == null &&
        soilValue == null &&
        luxValue == null &&
        leafValue == null &&
        voltageValue == null) {
      throw const FormatException('ESP32 payload contains no usable sensor channels');
    }

    final espHealth = _asDouble(first([
      data['healthScore'],
      data['health'],
      plantHealth['score'],
    ]));
    final espConfidence = _asDouble(first([
      data['healthConfidence'],
      data['analysisConfidence'],
      plantHealth['confidence'],
    ]));

    final normalized = <String, dynamic>{
      'nodeId': '${first([data['deviceId'], root['deviceId'], data['device'], 'PHYTO-NODE-001'])}',
      'timestamp': _timestamp(data),
      'soilMoisture': soilValue,
      'temperature': tempValue,
      'humidity': humidityValue,
      'light': normalizedLight,
      'lightLux': luxValue,
      'soilTemperature': rootValue,
      'leafWetness': leafValue,
      'plantSignal': stabilityValue,
      'plantVoltageMv': voltageValue,
      // The provider replaces this fallback with the app-side Health Index.
      'healthScore': espHealth,
      'healthStatus': '${first([data['healthStatus'], plantHealth['status'], 'starting'])}',
      'analysisConfidence': 0,
      'esp32HealthScore': espHealth,
      'esp32HealthConfidence': espConfidence,
      'waterScore': _asDouble(first([components['waterScore'], data['waterScore']])),
      'thermalScore': _asDouble(first([components['thermalScore'], data['thermalScore']])),
      'rootZoneScore': _asDouble(first([components['rootZoneScore'], data['rootZoneScore']])),
      'atmosphericScore': _asDouble(first([components['atmosphericScore'], data['atmosphericScore']])),
      'lightScore': _asDouble(first([components['lightScore'], data['lightScore']])),
      'diseaseRisk': _asDouble(first([
        components['diseaseRiskPercent'],
        data['diseaseRiskPercent'],
        data['diseaseRisk'],
      ])),
      'bioelectricStability': stabilityValue,
      'soilRaw': _asInt(first([soil['moistureRaw'], data['soilMoistureRaw']])),
      'leafRaw': _asInt(first([leaf['raw'], data['leafWetnessRaw']])),
      'soilCalibrated': first([
            soil['calibrated'],
            calibration['soilConfirmed'],
            calibration['soilCalibrated'],
          ]) ==
          true,
      'leafCalibrated': first([
            leaf['calibrated'],
            calibration['leafConfirmed'],
            calibration['leafCalibrated'],
          ]) ==
          true,
      'daytime': first([light['daytime'], data['daytime']]) != false,
      'leafWetDurationSeconds': _asDouble(first([
            leaf['continuousWetSeconds'],
            data['continuousLeafWetSeconds'],
          ])) ??
          0,
      'recentWetExposureSeconds': _asDouble(first([
            leaf['recentWetExposureSeconds'],
            data['recentWetExposureSeconds'],
          ])) ??
          0,
      'bioBaselineReady': bio['baselineReady'] == true,
      'bioBaselineSamples': _asInt(bio['baselineSamples']) ?? 0,
      'bioBaselineMv': _asDouble(bio['baselineMv']),
      'bioDeviationMv': _asDouble(bio['deviationMv']),
      'bioNoiseMv': _asDouble(bio['noiseMv']),
      'bioSignalQuality': qualityValue ?? 0,
    };

    return Esp32Snapshot(
      reading: SensorReading.fromJson(normalized),
      batteryPercent: _percentInt(first([
        data['batteryPercent'],
        root['batteryPercent'],
      ]), 100),
      signalPercent: _percentInt(first([
        data['signalPercent'],
        root['signalPercent'],
      ]), 100),
      firmwareVersion: '${first([
        data['firmware'],
        data['firmwareVersion'],
        root['firmware'],
        root['firmwareVersion'],
        'unknown',
      ])}',
      endpoint: endpoint,
      sensorCount: [
        soilValue,
        tempValue,
        humidityValue,
        luxValue,
        rootValue,
        leafValue,
        voltageValue,
      ].where((v) => v != null).length,
    );
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed?.isFinite == true ? parsed : null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    return value is num ? value.toInt() : int.tryParse('$value');
  }

  static int _percentInt(dynamic value, int fallback) =>
      (_asInt(value) ?? fallback).clamp(0, 100).toInt();

  static String _timestamp(Map<String, dynamic> payload) {
    final direct = payload['timestamp'];
    if (direct != null && DateTime.tryParse('$direct') != null) return '$direct';
    return DateTime.now().toIso8601String();
  }
}

class Esp32Snapshot {
  final SensorReading reading;
  final int batteryPercent;
  final int signalPercent;
  final String firmwareVersion;
  final String endpoint;
  final int sensorCount;

  const Esp32Snapshot({
    required this.reading,
    required this.batteryPercent,
    required this.signalPercent,
    required this.firmwareVersion,
    required this.endpoint,
    required this.sensorCount,
  });
}
