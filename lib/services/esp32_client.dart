import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';

class Esp32Client {
  final String baseUrl;

  Esp32Client(String baseUrl)
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  static const _sensorPaths = <String>[
    '/api/sensors',
    '/api/data',
    '/api/v1/sensors',
    '/data',
    '/sensors',
  ];

  // Preserve the existing UI while allowing the same ESP32 node to be reached
  // through its AP address or its current JioFiber/router-side address.
  static const _knownLocalNodeUrls = <String>[
    'http://192.168.4.1',
    'http://192.168.29.5',
  ];

  List<String> get _candidateBaseUrls => <String>[
        baseUrl,
        ..._knownLocalNodeUrls.where((candidate) => candidate != baseUrl),
      ];

  Future<Esp32Snapshot> getSnapshot() async {
    for (final path in _sensorPaths) {
      final response = await _tryGet(path);
      if (response == null) continue;
      try {
        return decodeSnapshot(response, endpoint: path);
      } on FormatException {
        // Try compatibility aliases before declaring the node invalid.
      }
    }
    throw Exception('PhytoSense ESP32 did not return a valid sensor payload');
  }

  Future<bool> ping() async {
    for (final path in const [
      '/api/status',
      '/status',
      '/api/sensors',
      '/api/data',
      '/data',
      '/sensors',
    ]) {
      if (await _tryGet(path) != null) return true;
    }
    return false;
  }

  Future<http.Response?> _tryGet(String path) async {
    final responses = await Future.wait(
      _candidateBaseUrls.map((candidate) async {
        try {
          return await http
              .get(
                Uri.parse('$candidate$path'),
                headers: const {'Accept': 'application/json'},
              )
              .timeout(const Duration(milliseconds: 1500));
        } catch (_) {
          return null;
        }
      }),
    );

    for (final response in responses) {
      if (response?.statusCode == 200) return response;
    }
    return null;
  }

  Esp32Snapshot decodeSnapshot(
    http.Response response, {
    required String endpoint,
  }) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid ESP32 JSON');
    }
    final root = Map<String, dynamic>.from(decoded);
    final originalData = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : Map<String, dynamic>.from(root);
    final data = _normalizeFirmwarePayload(originalData);

    final readings = _map(data['readings']);
    final air = _map(readings['air']);
    final soil = _map(readings['soil']);
    final light = _map(readings['light']);
    final leaf = _map(readings['leaf']);
    final bio = _map(readings['bioelectric']);
    final calibration = _map(data['calibration']);
    final plantHealth = _map(data['plantHealth']);
    final components = _firstNonEmptyMap([
      data['healthComponents'],
      plantHealth['components'],
    ]);

    dynamic first(Iterable<dynamic> values) {
      for (final value in values) {
        if (value != null) return value;
      }
      return null;
    }

    final temperature = first([
      data['airTemperatureC'],
      data['airTemperature'],
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
      data['rootTemperature'],
      data['soilTemperature'],
      soil['temperatureC'],
    ]);
    final schemaVersion =
        _asInt(first([data['schemaVersion'], root['schemaVersion']])) ?? 0;
    final flatLightIsLux =
        endpoint.startsWith('firebase:') || schemaVersion >= 9;
    final lux = first([
      data['lux'],
      data['lightLux'],
      light['lux'],
      if (flatLightIsLux) data['light'],
      if (!flatLightIsLux &&
          _asDouble(data['light']) != null &&
          _asDouble(data['light'])! > 100)
        data['light'],
    ]);
    final legacyLight = first([
      if (!flatLightIsLux &&
          _asDouble(data['light']) != null &&
          _asDouble(data['light'])! <= 100)
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
      data['bioVoltage'],
      data['plantVoltage'],
      bio['voltageMv'],
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
      bio['confidence'],
    ]);

    final airValid =
        air['valid'] != false && _flatSensorStatusUsable(data['ahtStatus']);
    final soilValid = soil['moistureValid'] != false &&
        soil['valid'] != false &&
        _soilStatusUsable(data['soilStatus']);
    final rootValid = soil['temperatureValid'] != false &&
        soil['valid'] != false &&
        _flatSensorStatusUsable(data['ds18b20Status']);
    final lightValid =
        light['valid'] != false && _flatSensorStatusUsable(data['bh1750Status']);
    final leafValid =
        leaf['valid'] != false && _flatSensorStatusUsable(data['leafStatus']);
    final bioAvailable =
        bio['available'] != false && _flatSensorStatusUsable(data['bioStatus']);
    final rawBioContactState = first([
      bio['contactState'],
      bio['bioContactState'],
      data['bioContactState'],
      root['bioContactState'],
    ]);
    final bioContactState = rawBioContactState == null
        ? null
        : '$rawBioContactState'
            .trim()
            .toUpperCase()
            .replaceAll(' ', '_')
            .replaceAll('-', '_');
    final bioContactPlausibleForPlantUse = first([
      bio['contactPlausibleForPlantUse'],
      data['bioContactPlausibleForPlantUse'],
      root['bioContactPlausibleForPlantUse'],
    ]);
    final contactTelemetryAvailable =
        bioContactState != null || bioContactPlausibleForPlantUse != null;
    final contactValidForPlantUse = !contactTelemetryAvailable ||
        (bioContactState == 'PLAUSIBLE' &&
            bioContactPlausibleForPlantUse != false);
    final bioValid =
        bio['valid'] != false && bioAvailable && contactValidForPlantUse;

    final tempValue = airValid ? _asDouble(temperature) : null;
    final humidityValue = airValid ? _asDouble(humidity) : null;
    final soilValue = soilValid ? _asDouble(soilMoisture) : null;
    final rootValue = rootValid ? _asDouble(soilTemperature) : null;
    final luxValue = lightValid ? _asDouble(lux) : null;
    final legacyLightValue = _asDouble(legacyLight);
    final normalizedLight = legacyLightValue ??
        (luxValue == null
            ? null
            : (luxValue / 70000 * 100).clamp(0, 100).toDouble());
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
      data['healthIndex'],
      data['health'],
      plantHealth['score'],
      plantHealth['index'],
    ]));
    final espConfidence = _asDouble(first([
      data['healthConfidence'],
      data['analysisConfidence'],
      data['confidence'],
      data['overallAnalysisConfidence'],
      plantHealth['confidence'],
    ]));

    final normalized = <String, dynamic>{
      'nodeId':
          '${first([data['deviceId'], root['deviceId'], data['device'], 'PHYTO-NODE-001'])}',
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
      'bioSource': '${first([data['bioSource'], data['bioelectricSource'], bio['source'], bio['bioSource'], 'real'])}',
      'healthScore': espHealth,
      'healthStatus': '${first([
        data['plantState'],
        data['plantCondition'],
        data['healthStatus'],
        data['status'],
        plantHealth['plantCondition'],
        plantHealth['status'],
        'starting',
      ])}',
      'analysisConfidence': espConfidence ?? 0,
      'esp32HealthScore': espHealth,
      'esp32HealthConfidence': espConfidence,
      'waterScore': _asDouble(first([
        components['water'],
        components['waterScore'],
        data['waterScore'],
      ])),
      'thermalScore': _asDouble(first([
        components['thermal'],
        components['thermalScore'],
        data['thermalScore'],
      ])),
      'rootZoneScore': _asDouble(first([
        components['rootZone'],
        components['rootZoneScore'],
        data['rootZoneScore'],
      ])),
      'atmosphericScore': _asDouble(first([
        components['atmospheric'],
        components['atmosphericScore'],
        data['atmosphericScore'],
      ])),
      'lightScore': _asDouble(first([
        components['light'],
        components['lightScore'],
        data['lightScore'],
      ])),
      'diseaseRisk': _asDouble(first([
        _map(data['diseaseConduciveRisk'])['score'],
        _map(data['diseaseRisk'])['score'],
        _map(plantHealth['diseaseConduciveRisk'])['score'],
        components['diseaseRiskPercent'],
        data['diseaseRiskPercent'],
        data['diseaseRisk'] is num ? data['diseaseRisk'] : null,
      ])),
      'bioelectricStability': stabilityValue,
      'soilRaw': _asInt(first([
        soil['moistureRaw'],
        soil['raw'],
        data['soilMoistureRaw'],
        data['soilRaw'],
      ])),
      'leafRaw': _asInt(first([
        leaf['raw'],
        data['leafWetnessRaw'],
        data['leafRaw'],
      ])),
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
      'daytime': _isDaytime(
        first([light['daytime'], data['daytime'], data['dayNight']]),
      ),
      'leafWetDurationSeconds': _asDouble(first([
            leaf['continuousWetSeconds'],
            leaf['wetDurationSeconds'],
            data['continuousLeafWetSeconds'],
            data['leafWetDurationSeconds'],
          ])) ??
          0,
      'recentWetExposureSeconds': _asDouble(first([
            leaf['recentWetExposureSeconds'],
            data['recentWetExposureSeconds'],
          ])) ??
          0,
      'bioBaselineReady': first([
            bio['baselineReady'],
            data['baselineReady'],
          ]) ==
          true,
      'bioBaselineSamples': _asInt(first([
            bio['baselineSamples'],
            data['baselineSamples'],
          ])) ??
          0,
      'bioBaselineMv': _asDouble(first([bio['baselineMv'], data['bioBaselineMv']])),
      'bioDeviationMv': _asDouble(first([bio['deviationMv'], data['bioDeviationMv']])),
      'bioNoiseMv': _asDouble(first([bio['noiseMv'], bio['noise'], bio['batchNoiseMv']])),
      'bioSignalQuality': qualityValue ?? 0,
    };

    final firmwareVersion = '${first([
      data['firmware'],
      data['firmwareVersion'],
      root['firmware'],
      root['firmwareVersion'],
      'unknown',
    ])}';

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
      firmwareVersion: firmwareVersion,
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
      edgeIntelligence: EdgeIntelligence.fromPayload(
        root: root,
        data: data,
        firmwareVersion: firmwareVersion,
      ),
      telemetry: HardwareTelemetry.fromPayload(
        root: root,
        data: data,
        firmwareVersion: firmwareVersion,
      ),
    );
  }

  /// Normalizes both nested ESP32 v8.7.1 payloads and older flat payloads.
  /// This does not infer plant intelligence; it only preserves firmware data
  /// under stable keys used by the Flutter models.
  static Map<String, dynamic> _normalizeFirmwarePayload(
      Map<String, dynamic> input) {
    final data = Map<String, dynamic>.from(input);
    final environment = _map(data['environment']);
    final rootZone = _map(data['rootZone']);
    final leafTop = _map(data['leaf']);
    final bioTop = _firstNonEmptyMap([data['bioelectric'], data['bio']]);
    final cropTop = _map(data['crop']);
    final qualityTop = _map(data['analysisQuality']);
    final diseaseTop = _map(data['diseaseRisk']);
    final recoveryTop = _map(data['recovery']);
    final predictionTop = _map(data['prediction']);

    data['healthScore'] ??= data['healthIndex'];
    data['primaryFinding'] ??= data['mainFinding'];
    data['primaryAction'] ??= data['farmerAction'];
    data['decisionExplanation'] ??= data['because'];

    if (environment.isNotEmpty) {
      data['airTemperatureC'] ??=
          _first([environment['airTemperature'], environment['temperatureC'], environment['temperature']]);
      data['humidityPercent'] ??=
          _first([environment['humidity'], environment['relativeHumidity']]);
      data['lux'] ??= _first([environment['lux'], environment['lightLux']]);
      data['vpdKpa'] ??= _first([environment['vpdKpa'], environment['vpd']]);
      data['dayPhase'] ??= environment['dayPhase'];
      final phase = '${environment['dayPhase'] ?? ''}'.toUpperCase();
      if (!data.containsKey('daytime') && phase.isNotEmpty) {
        data['daytime'] = phase == 'DAY' || phase == 'DAWN' || phase == 'DUSK';
      }
    }

    if (rootZone.isNotEmpty) {
      data['soilMoisturePercent'] ??=
          _first([rootZone['soilMoisture'], rootZone['moisturePercent']]);
      data['soilTemperatureC'] ??=
          _first([rootZone['rootTemperature'], rootZone['soilTemperature']]);
      data['airRootTemperatureDifferenceC'] ??=
          _first([rootZone['airRootDelta'], rootZone['airRootTemperatureDifference']]);
    }

    if (leafTop.isNotEmpty) {
      data['leafWetnessPercent'] ??=
          _first([leafTop['wetness'], leafTop['wetnessPercent']]);
      if (!data.containsKey('leafWetDurationSeconds')) {
        final minutes = _asDouble(_first([
          leafTop['wetDurationMinutes'],
          leafTop['continuousWetDurationMinutes'],
        ]));
        final seconds = _asDouble(_first([
          leafTop['wetDurationSeconds'],
          leafTop['continuousWetSeconds'],
        ]));
        data['leafWetDurationSeconds'] = seconds ?? (minutes == null ? null : minutes * 60);
      }
    }

    if (bioTop.isNotEmpty) {
      data['plantVoltageMv'] ??= bioTop['voltageMv'];
      data['bioBaselineMv'] ??= bioTop['baselineMv'];
      data['bioelectricDeviationPercent'] ??= bioTop['deviationPercent'];
      data['bioSignalQuality'] ??=
          _first([bioTop['signalQuality'], bioTop['confidence']]);
      data['bioBaselineSamples'] ??=
          _first([bioTop['baselineSamples'], bioTop['samples']]);
      data['bioBaselineTarget'] ??=
          _first([bioTop['baselineTarget'], bioTop['targetSamples']]);
      data['bioBaselineReady'] ??= bioTop['baselineReady'];
      data['bioState'] ??= _first([bioTop['state'], bioTop['stressState']]);
      data['bioStressScore'] ??= bioTop['stressScore'];
      data['bioIncludedInFusion'] ??=
          _first([bioTop['includedInFusion'], bioTop['usedInFusion']]);
      data['bioContactState'] ??=
          _first([bioTop['contactState'], bioTop['bioContactState']]);
      data['bioContactConfidence'] ??=
          _first([bioTop['contactConfidence'], bioTop['bioContactConfidence']]);
      data['bioSlowDriftMv'] ??=
          _first([bioTop['slowDriftMv'], bioTop['bioSlowDriftMv']]);
      data['bioContactPlausibleForPlantUse'] ??=
          bioTop['contactPlausibleForPlantUse'];
      data['bioOpenEvidence'] ??= bioTop['openEvidence'];
      data['bioStaticEvidence'] ??= bioTop['staticEvidence'];
      data['adaptiveBaselineStatus'] ??= bioTop['baselineStatus'];
      if (!data.containsKey('baselineReady')) {
        data['baselineReady'] = '${bioTop['baselineStatus'] ?? ''}'.toUpperCase() == 'READY';
      }
    }

    if (cropTop.isNotEmpty) {
      final cropProfile = <String, dynamic>{
        ...cropTop,
        'profile': _first([cropTop['name'], cropTop['id']]),
        'growthStage': _first([cropTop['stage'], cropTop['growthStage']]),
      };
      data['cropProfile'] ??= cropProfile;
      data['cropProfileName'] ??= _first([cropTop['name'], cropTop['id']]);
      data['growthStage'] ??= _first([cropTop['stage'], cropTop['growthStage']]);
      data['regionProfile'] ??=
          _first([cropTop['regionProfile'], cropTop['region']]);
    }

    if (qualityTop.isNotEmpty) {
      final quality = Map<String, dynamic>.from(qualityTop);
      quality['label'] ??= qualityTop['level'];
      quality['confidence'] ??= qualityTop['score'];
      data['analysisQuality'] = quality;
      data['degradedMode'] ??= qualityTop['degraded'];
      data['degradedReason'] ??= qualityTop['reason'];
      data['degradedReasons'] ??=
          _first([qualityTop['degradedReasons'], qualityTop['reasons']]);
    }

    if (diseaseTop.isNotEmpty) {
      data['diseaseConduciveRisk'] ??= diseaseTop;
      data['diseaseRiskPercent'] ??= diseaseTop['score'];
      data['diseaseRiskLevel'] ??= diseaseTop['level'];
    }

    if (data['explanation'] != null) {
      data['decisionExplanation'] ??= data['explanation'];
    }

    final cameraHandoff = _map(data['cameraHandoff']);
    if (cameraHandoff.isNotEmpty) {
      data['cameraScanRecommended'] ??= _first([
        cameraHandoff['recommended'],
        cameraHandoff['cameraScanRecommended'],
      ]);
      data['cameraScanReason'] ??= cameraHandoff['reason'];
      data['cameraRecommendation'] ??=
          _first([cameraHandoff['recommendation'], cameraHandoff['action']]);
    }

    if (recoveryTop.isNotEmpty && recoveryTop['durationMinutes'] != null) {
      final recovery = Map<String, dynamic>.from(recoveryTop);
      recovery['durationSeconds'] ??=
          (_asDouble(recoveryTop['durationMinutes']) ?? 0) * 60;
      data['recovery'] = recovery;
    }

    if (predictionTop.isNotEmpty) {
      final prediction = Map<String, dynamic>.from(predictionTop);
      if (predictionTop['available'] == false) {
        prediction['state'] ??= 'UNAVAILABLE';
        prediction['explanation'] ??= predictionTop['reason'];
      }
      data['prediction'] = prediction;
    }

    final trends = _map(data['trends']);
    if (trends.isNotEmpty) {
      final normalizedTrends = <String, dynamic>{};
      for (final entry in trends.entries) {
        final trend = _map(entry.value);
        if (trend.isEmpty) {
          normalizedTrends[entry.key] = entry.value;
        } else {
          final copy = Map<String, dynamic>.from(trend);
          copy['rate'] ??= _first([trend['ratePerHour'], trend['slopePerHour']]);
          normalizedTrends[entry.key] = copy;
        }
      }
      data['trends'] = normalizedTrends;
    }

    final existingReadings = _map(data['readings']);
    final air = _map(existingReadings['air']);
    final soil = _map(existingReadings['soil']);
    final light = _map(existingReadings['light']);
    final leaf = _map(existingReadings['leaf']);
    final bio = _map(existingReadings['bioelectric']);

    final mergedAir = <String, dynamic>{
      ...air,
      if (environment.isNotEmpty) ...{
        'temperatureC': _first([
          air['temperatureC'],
          environment['airTemperature'],
          environment['temperatureC'],
        ]),
        'humidityPercent': _first([
          air['humidityPercent'],
          environment['humidity'],
          environment['relativeHumidity'],
        ]),
      },
    };
    final mergedSoil = <String, dynamic>{
      ...soil,
      if (rootZone.isNotEmpty) ...{
        'moisturePercent': _first([
          soil['moisturePercent'],
          rootZone['soilMoisture'],
          rootZone['moisturePercent'],
        ]),
        'temperatureC': _first([
          soil['temperatureC'],
          rootZone['rootTemperature'],
          rootZone['soilTemperature'],
        ]),
      },
    };
    final mergedLight = <String, dynamic>{
      ...light,
      if (environment.isNotEmpty) ...{
        'lux': _first([light['lux'], environment['lux'], environment['lightLux']]),
        'phase': _first([light['phase'], environment['dayPhase']]),
        'daytime': data['daytime'],
      },
    };
    final mergedLeaf = <String, dynamic>{
      ...leaf,
      ...leafTop,
      'wetnessPercent': _first([
        leaf['wetnessPercent'],
        leafTop['wetness'],
        leafTop['wetnessPercent'],
      ]),
      'continuousWetSeconds': _first([
        leaf['continuousWetSeconds'],
        data['leafWetDurationSeconds'],
      ]),
    };
    final mergedBio = <String, dynamic>{
      ...bio,
      ...bioTop,
      'amplifierOutputMv': _first([
        bio['amplifierOutputMv'],
        bioTop['voltageMv'],
      ]),
      'signalQuality': _first([
        bio['signalQuality'],
        bioTop['signalQuality'],
        bioTop['confidence'],
      ]),
      'baselineReady': _first([
        bio['baselineReady'],
        bioTop['baselineReady'],
        data['bioBaselineReady'],
        data['baselineReady'],
      ]),
    };

    data['readings'] = <String, dynamic>{
      ...existingReadings,
      'air': mergedAir,
      'soil': mergedSoil,
      'light': mergedLight,
      'leaf': mergedLeaf,
      'bioelectric': mergedBio,
    };

    return data;
  }

  static bool _flatSensorStatusUsable(dynamic value) {
    final state = '${value ?? ''}'
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    if (state.isEmpty) return true;
    return !const <String>{
      'UNAVAILABLE',
      'NOT_AVAILABLE',
      'INVALID',
      'FAILED',
      'FAIL',
      'ERROR',
      'MISSING',
      'NOT_CONNECTED',
      'ABSENT',
    }.contains(state);
  }

  static bool _soilStatusUsable(dynamic value) {
    final state = '${value ?? ''}'
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    if (!_flatSensorStatusUsable(state)) return false;
    return !const <String>{
      'VERIFY',
      'VERIFY_PLACEMENT',
      'PLACEMENT_VERIFY',
      'CHECK_PLACEMENT',
      'OUTSIDE_CALIBRATED_RANGE',
      'HEALTH_USE_DISABLED',
      'DISABLED',
    }.contains(state);
  }

  static bool _isDaytime(dynamic value) {
    if (value is bool) return value;
    final state = '${value ?? ''}'.trim().toUpperCase();
    if (state == 'NIGHT') return false;
    if (state == 'DAY') return true;
    return true;
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  static Map<String, dynamic> _firstNonEmptyMap(List<dynamic> values) {
    for (final value in values) {
      final mapped = _map(value);
      if (mapped.isNotEmpty) return mapped;
    }
    return <String, dynamic>{};
  }

  static dynamic _first(List<dynamic> values) {
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }

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
  final EdgeIntelligence edgeIntelligence;
  final HardwareTelemetry telemetry;

  const Esp32Snapshot({
    required this.reading,
    required this.batteryPercent,
    required this.signalPercent,
    required this.firmwareVersion,
    required this.endpoint,
    required this.sensorCount,
    required this.edgeIntelligence,
    required this.telemetry,
  });
}
