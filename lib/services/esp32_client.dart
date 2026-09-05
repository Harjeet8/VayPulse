import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sensor_reading.dart';

class Esp32Client {
  final String baseUrl;
  final http.Client _httpClient;

  Esp32Client(String baseUrl, {http.Client? httpClient})
      : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
        _httpClient = httpClient ?? http.Client();

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
        return decodeSnapshot(response, endpoint: path);
      } on FormatException {
        // A compatibility endpoint may exist but expose an older shape. Keep
        // trying the remaining aliases before declaring the node invalid.
      }
    }
    throw Exception('PhytoSense ESP32 did not return a valid sensor payload');
  }

  Future<bool> ping() async {
    for (final path in const [
      '/api/status',
      '/status',
      '/api/sensors',
      '/sensors',
    ]) {
      if (await _tryGet(path) != null) return true;
    }
    return false;
  }

  Future<http.Response?> _tryGet(String path) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl$path'),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200 ? response : null;
    } catch (_) {
      return null;
    }
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
    final legacyComponents = _map(data['healthComponents']);
    final plantHealth = _map(data['plantHealth']);
    final components = legacyComponents.isNotEmpty
        ? legacyComponents
        : _map(plantHealth['components']);

    dynamic first(Iterable<dynamic> values) {
      for (final value in values) {
        if (value != null) return value;
      }
      return null;
    }

    final analysis = _map(
      first([data['analysis'], data['edgeAnalysis'], plantHealth['analysis']]),
    );
    final reliability = _map(
      first([
        data['reliability'],
        analysis['reliability'],
        data['systemReliability'],
      ]),
    );
    final system = _map(data['system']);
    final network = _map(first([data['network'], system['network']]));
    final recovery = _map(first([data['recovery'], analysis['recovery']]));
    final biotic = _map(
      first([data['biotic'], analysis['biotic'], plantHealth['biotic']]),
    );
    final validity = _map(first([data['sensorValidity'], data['validity']]));
    final sensorStates = <String, dynamic>{
      ..._map(first([data['sensorStates'], data['sensorStatus']])),
    };
    void addFlatSensorState(String channel, dynamic value) {
      if (value != null && !sensorStates.containsKey(channel)) {
        sensorStates[channel] = value;
      }
    }

    addFlatSensorState('temperature', data['ahtStatus']);
    addFlatSensorState('humidity', data['ahtStatus']);
    addFlatSensorState('light', data['bh1750Status']);
    addFlatSensorState('soilMoisture', data['soilStatus']);
    addFlatSensorState('soilTemperature', data['ds18b20Status']);
    addFlatSensorState('leafWetness', data['leafStatus']);
    addFlatSensorState('plantSignal', data['bioStatus']);

    final plantModel = _map(
      first([
        data['plantModel'],
        data['adaptivePlantModel'],
        analysis['plantModel'],
      ]),
    );
    final temporalReasoning = _map(
      first([
        data['temporalReasoning'],
        data['causeResponse'],
        analysis['temporalReasoning'],
      ]),
    );
    final plausibility = _map(
      first([
        data['plausibility'],
        data['sensorPlausibility'],
        analysis['plausibility'],
      ]),
    );
    final anomaly = _map(
      first([data['anomaly'], data['anomalyDetection'], analysis['anomaly']]),
    );
    final prediction = _map(
      first([
        data['prediction'],
        data['stressPrediction'],
        analysis['prediction'],
      ]),
    );
    final sensorIntegrity = _map(
      first([
        data['sensorIntegrity'],
        system['sensorIntegrity'],
        analysis['sensorIntegrity'],
      ]),
    );
    final runtimeHealth = _map(
      first([
        data['runtimeHealth'],
        system['runtimeHealth'],
        data['nodeHealth'],
      ]),
    );
    final recentEvents = first([
      data['recentEvents'],
      data['events'],
      analysis['recentEvents'],
    ]);

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
    final lux = first([
      data['lux'],
      data['lightLux'],
      light['lux'],
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
      data['bioVoltage'],
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
    final bioSource =
        '${first([data['bioSource'], bio['source'], 'real'])}'.toLowerCase();

    final temperatureValid = _channelValid(
      air,
      explicitValid: first([
        air['temperatureValid'],
        data['temperatureValid'],
        validity['temperature'],
        air['valid'],
      ]),
      externalState: sensorStates['temperature'],
    );
    final humidityValid = _channelValid(
      air,
      explicitValid: first([
        air['humidityValid'],
        data['humidityValid'],
        validity['humidity'],
        air['valid'],
      ]),
      externalState: sensorStates['humidity'],
    );
    final soilValid = _channelValid(
          soil,
          explicitValid: first([
            soil['moistureValid'],
            data['soilMoistureValid'],
            validity['soilMoisture'],
            soil['valid'],
          ]),
          externalState: sensorStates['soilMoisture'],
        ) &&
        !_deploymentVerificationState(sensorStates['soilMoisture']);
    final rootValid = _channelValid(
      soil,
      explicitValid: first([
        soil['temperatureValid'],
        data['soilTemperatureValid'],
        validity['soilTemperature'],
        soil['valid'],
      ]),
      externalState: sensorStates['soilTemperature'],
    );
    final lightValid = _channelValid(
      light,
      explicitValid: first([
        light['valid'],
        data['lightValid'],
        validity['light'],
      ]),
      externalState: sensorStates['light'],
    );
    final leafValid = _channelValid(
      leaf,
      explicitValid: first([
        leaf['valid'],
        data['leafWetnessValid'],
        validity['leafWetness'],
      ]),
      externalState: sensorStates['leafWetness'],
    );
    // Electrical measurement validity is intentionally separate from whether
    // the firmware allows this channel to influence plant analysis.
    final bioMeasurementValid = _channelValid(
      bio,
      explicitValid: first([
        bio['valid'],
        data['bioValid'],
        validity['plantSignal'],
        validity['bioelectric'],
      ]),
      externalState: sensorStates['plantSignal'] ?? sensorStates['bioelectric'],
    );

    final rawBioContactState = first([
      bio['contactState'],
      bio['bioContactState'],
      data['bioContactState'],
      root['bioContactState'],
    ]);
    final bioContactState = rawBioContactState == null
        ? ''
        : '$rawBioContactState'
            .trim()
            .toUpperCase()
            .replaceAll(' ', '_')
            .replaceAll('-', '_');
    final bioContactConfidence = _asDouble(
      first([
        bio['contactConfidence'],
        bio['bioContactConfidence'],
        data['bioContactConfidence'],
        root['bioContactConfidence'],
      ]),
    );
    final bioSlowDriftMv = _asDouble(
      first([
        bio['slowDriftMv'],
        bio['bioSlowDriftMv'],
        data['bioSlowDriftMv'],
        root['bioSlowDriftMv'],
      ]),
    );
    final bioContactPlausibleForPlantUse = _asBool(
      first([
        bio['contactPlausibleForPlantUse'],
        data['bioContactPlausibleForPlantUse'],
        root['bioContactPlausibleForPlantUse'],
      ]),
    );
    final bioAffectsHealth = _asBool(
      first([
        bio['affectsHealth'],
        data['bioAffectsHealth'],
        root['bioAffectsHealth'],
      ]),
    );
    final bioOpenLatched = _asBool(
      first([
        bio['openLatched'],
        data['bioOpenLatched'],
        root['bioOpenLatched'],
      ]),
    );
    final bioReconnectVerifying = _asBool(
      first([
        bio['reconnectVerifying'],
        data['bioReconnectVerifying'],
        root['bioReconnectVerifying'],
      ]),
    );
    final bioReconnectVerifySec = _asInt(
      first([
        bio['reconnectVerifySec'],
        data['bioReconnectVerifySec'],
        root['bioReconnectVerifySec'],
      ]),
    );
    final hasNewBioContactGate = rawBioContactState != null ||
        bioContactConfidence != null ||
        bioSlowDriftMv != null ||
        bioContactPlausibleForPlantUse != null ||
        bioAffectsHealth != null ||
        bioOpenLatched != null ||
        bioReconnectVerifying != null ||
        bioReconnectVerifySec != null;
    final bioPlantUseValid = bioMeasurementValid &&
        (!hasNewBioContactGate ||
            (bioContactPlausibleForPlantUse == true &&
                bioAffectsHealth == true &&
                bioOpenLatched != true &&
                bioReconnectVerifying != true &&
                (bioContactState.isEmpty || bioContactState == 'PLAUSIBLE')));

    final tempValue = temperatureValid ? _asDouble(temperature) : null;
    final humidityValue = humidityValid ? _asDouble(humidity) : null;
    final soilValue = soilValid ? _asDouble(soilMoisture) : null;
    final rootValue = rootValid ? _asDouble(soilTemperature) : null;
    final luxValue = lightValid ? _asDouble(lux) : null;
    final legacyLightValue = _asDouble(legacyLight);
    final normalizedLight = legacyLightValue ??
        (luxValue == null
            ? null
            : (luxValue / 70000 * 100).clamp(0, 100).toDouble());
    final leafValue = leafValid ? _asDouble(leafWetness) : null;
    // Keep the electrical measurement visible to technical diagnostics even
    // when the plant-contact gate rejects it for health/baseline use.
    final voltageValue = bioMeasurementValid ? _asDouble(plantVoltageMv) : null;
    final stabilityValue = bioMeasurementValid ? _asDouble(bioStability) : null;
    final qualityValue = bioMeasurementValid ? _asDouble(bioQuality) : null;

    if (tempValue == null &&
        humidityValue == null &&
        soilValue == null &&
        luxValue == null &&
        leafValue == null &&
        voltageValue == null) {
      throw const FormatException(
        'ESP32 payload contains no usable sensor channels',
      );
    }

    final espHealth = _asDouble(
      first([
        data['healthScore'],
        data['healthIndex'],
        data['health'],
        plantHealth['score'],
        plantHealth['index'],
      ]),
    );
    final espConfidence = _asDouble(
      first([
        data['healthConfidence'],
        data['analysisConfidence'],
        data['confidence'],
        plantHealth['confidence'],
      ]),
    );
    final espStress = _asDouble(
      first([
        data['stressScore'],
        data['stress'],
        plantHealth['stressScore'],
        plantHealth['stress'],
      ]),
    );
    final rawCause = first([
      data['primaryRootCause'],
      data['mainFinding'],
      data['rootCause'],
      data['primaryCause'],
      analysis['primaryRootCause'],
      analysis['rootCause'],
      plantHealth['rootCause'],
    ]);
    final rawAction = first([
      data['farmerAction'],
      data['recommendedAction'],
      data['recommendation'],
      analysis['farmerAction'],
      analysis['recommendedAction'],
      plantHealth['farmerAction'],
      plantHealth['recommendation'],
    ]);
    final rankedCauses = _causeList(
      first([
        data['rankedRootCauses'],
        data['rootCauses'],
        data['causes'],
        analysis['rankedRootCauses'],
        analysis['causes'],
      ]),
    );
    final primaryRootCause = _causeLabel(rawCause) ??
        (rankedCauses.isEmpty ? '' : rankedCauses.first);
    final farmerAction = _textValue(rawAction) ?? '';
    final reliabilityMode = _normalizeReliability(
      first([
        data['reliabilityMode'],
        data['reliability'],
        data['analysisMode'],
        reliability['mode'],
        reliability['status'],
        analysis['mode'],
        system['reliabilityMode'],
      ]),
      degraded: <bool>[
        temperatureValid,
        humidityValid,
        soilValid,
        rootValid,
        lightValid,
        leafValid,
        bioPlantUseValid,
      ].contains(false),
    );
    final bioticState = '${first([
          data['bioticState'],
          data['bioticStatus'],
          biotic['state'],
          biotic['status'],
          analysis['bioticState'],
          ''
        ])}'
        .toUpperCase();
    final cameraRecommended = _asBool(
          first([
            data['cameraRecommended'],
            data['cameraHandoff'],
            biotic['cameraRecommended'],
            analysis['cameraRecommended'],
          ]),
        ) ??
        bioticState == 'POSSIBLE_BIOTIC_STRESS';

    final normalized = <String, dynamic>{
      'nodeId': '${first([
            data['nodeId'],
            data['deviceId'],
            root['nodeId'],
            root['deviceId'],
            data['device'],
            'PHYTO-NODE-001'
          ])}',
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
      'bioSource': bioSource,
      // Hardware mode uses the ESP32 edge-intelligence result directly.
      'healthScore': espHealth ?? 0,
      'stressScore': espStress ?? (espHealth == null ? 0 : 100 - espHealth),
      'healthStatus': '${first([
            data['plantCondition'],
            data['healthStatus'],
            data['status'],
            plantHealth['status'],
            'starting'
          ])}',
      'priority': '${first([data['priority'], analysis['priority'], ''])}',
      'because': '${first([
            data['because'],
            data['explanation'],
            analysis['because'],
            analysis['explanation'],
            ''
          ])}',
      'analysisConfidence': espConfidence ?? 0,
      'edgeAnalysisAvailable': espHealth != null,
      'crop': '${first([
            data['crop'],
            data['selectedCrop'],
            plantHealth['crop'],
            root['crop'],
            'Universal'
          ])}',
      'growthStage': '${first([
            data['growthStage'],
            data['stage'],
            plantHealth['growthStage'],
            root['growthStage'],
            'Vegetative'
          ])}',
      'reliabilityMode': reliabilityMode,
      'analysisQuality': '${first([
            data['analysisQuality'],
            analysis['quality'],
            analysis['analysisQuality'],
            ''
          ])}',
      'systemStatus': '${first([
            data['systemStatus'],
            system['status'],
            data['status'],
            ''
          ])}',
      'recoveryStatus': '${first([
            data['recoveryStatus'],
            data['recoveryState'],
            recovery['status'],
            recovery['state'],
            ''
          ])}',
      'primaryRootCause': primaryRootCause,
      'farmerAction': farmerAction,
      'rootCauseConfidence': _asDouble(
        first([
          data['rootCauseConfidence'],
          _map(rawCause)['confidence'],
          analysis['rootCauseConfidence'],
          espConfidence,
        ]),
      ),
      'rankedRootCauses': _mergeCauses(
        primaryRootCause,
        _causeLabel(first([
          data['secondaryCause'],
          data['secondaryRootCause'],
          analysis['secondaryCause'],
          analysis['secondaryRootCause'],
        ])),
        rankedCauses,
      ),
      'bioticState': bioticState,
      'bioState':
          '${first([data['bioState'], bio['state'], bio['status'], ''])}'
              .toUpperCase(),
      'cameraRecommended': cameraRecommended,
      'cameraReason': '${first([
            data['cameraReason'],
            biotic['cameraReason'],
            analysis['cameraReason'],
            primaryRootCause
          ])}',
      'plantModelStatus': _normalizePlantModelStatus(
        first([
          plantModel['status'],
          plantModel['state'],
          data['plantModelStatus'],
        ]),
      ),
      'plantModelReady': _plantModelReady(plantModel),
      'plantModelConfidence': _asDouble(
        first([
          plantModel['confidence'],
          plantModel['modelConfidence'],
          data['plantModelConfidence'],
        ]),
      ),
      'plantModelLearnedSamples': _asInt(
        first([
          plantModel['learnedSamples'],
          plantModel['samples'],
          data['plantModelLearnedSamples'],
        ]),
      ),
      'plantModelAgeSec': _asInt(
        first([
          plantModel['ageSec'],
          plantModel['ageSeconds'],
          data['plantModelAgeSec'],
        ]),
      ),
      'plantModelPersisted': _asBool(
                first([
                  plantModel['persisted'],
                  plantModel['restored'],
                  data['plantModelPersisted'],
                ]),
              ) ==
              true ||
          '${first([plantModel['status'], plantModel['state'], ''])}'
              .toUpperCase()
              .contains('RESTOR'),
      'plantModelBioBaselineMv': _asDouble(
        first([
          plantModel['bioBaselineMv'],
          plantModel['baselineMv'],
          bio['baselineMv'],
        ]),
      ),
      'plantModelTypicalBioVariationMv': _asDouble(
        first([
          plantModel['typicalBioVariationMv'],
          plantModel['typicalVariationMv'],
        ]),
      ),
      'plantModelNormalNoiseMv': _asDouble(
        first([plantModel['normalNoiseMv'], plantModel['noiseMv']]),
      ),
      'plantModelNormalSoilRatePctPerHour': _asDouble(
        first([
          plantModel['normalSoilRatePctPerHour'],
          plantModel['soilRatePctPerHour'],
        ]),
      ),
      'temporalState': '${first([
            temporalReasoning['state'],
            temporalReasoning['status'],
            ''
          ])}',
      'temporalConfidence': _asDouble(
        first([
          temporalReasoning['confidence'],
          data['temporalReasoningConfidence'],
        ]),
      ),
      'temporalPrimarySequence': '${first([
            temporalReasoning['primarySequence'],
            temporalReasoning['sequence'],
            ''
          ])}',
      'environmentToBioLagSec': _asInt(
        first([
          temporalReasoning['environmentToBioLagSec'],
          temporalReasoning['envToBioLagSec'],
        ]),
      ),
      'actionToRecoveryLagSec': _asInt(
        first([
          temporalReasoning['actionToRecoveryLagSec'],
          recovery['actionToRecoveryLagSec'],
        ]),
      ),
      'temporalExplanation': '${first([
            temporalReasoning['explanation'],
            temporalReasoning['message'],
            ''
          ])}',
      'plausibilityState':
          '${first([plausibility['state'], plausibility['status'], ''])}',
      'plausibilityConfidence': _asDouble(plausibility['confidence']),
      'plausibilityPrimaryIssue':
          '${first([plausibility['primaryIssue'], plausibility['issue'], ''])}',
      'plausibilityRecommendation': '${first([
            plausibility['recommendation'],
            plausibility['action'],
            ''
          ])}',
      'anomalyState': '${first([anomaly['state'], anomaly['status'], ''])}',
      'anomalyScore': _asDouble(anomaly['score']),
      'anomalyConfidence': _asDouble(anomaly['confidence']),
      'anomalyExplanation':
          '${first([anomaly['explanation'], anomaly['message'], ''])}',
      'anomalyAffectedChannel':
          '${first([anomaly['affectedChannel'], anomaly['channel'], ''])}',
      'predictionAvailable': _asBool(
                first([prediction['available'], data['predictionAvailable']]),
              ) ==
              true ||
          _predictionStateAvailable(
            first([prediction['state'], data['predictionState']]),
          ),
      'predictionTarget':
          '${first([prediction['target'], prediction['metric'], ''])}',
      'predictionConfidence': _asDouble(
        first([prediction['confidence'], data['predictionConfidence']]),
      ),
      'predictionMinutesToWarning': _asInt(
        first([
          prediction['minutesToWarning'],
          prediction['etaMinutes'],
          data['predictionMinutesToWarning'],
        ]),
      ),
      'predictionMessage':
          '${first([prediction['message'], prediction['explanation'], ''])}',
      'predictionDirection':
          '${first([prediction['direction'], prediction['trend'], ''])}',
      'recoveryProgressPct': _asDouble(
        first([
          recovery['progressPct'],
          recovery['progress'],
          data['recoveryProgressPct'],
        ]),
      ),
      'recoveryConfidence': _asDouble(
        first([recovery['confidence'], data['recoveryConfidence']]),
      ),
      'recoveryEnvironmentImproved':
          _asBool(recovery['environmentImproved']) == true,
      'recoverySoilImproved': _asBool(recovery['soilImproved']) == true,
      'recoveryStressEvidenceDecreasing':
          _asBool(recovery['stressEvidenceDecreasing']) == true,
      'recoveryBioResponseDecreasing':
          _asBool(recovery['bioResponseDecreasing']) == true,
      'recoveryVerified':
          _asBool(first([recovery['verified'], data['recoveryVerified']])) ==
              true,
      'recoveryFarmerResult':
          '${first([recovery['farmerResult'], recovery['result'], ''])}',
      'recoveryActionToResponseLagSec': _asInt(
        first([recovery['actionToResponseLagSec'], recovery['responseLagSec']]),
      ),
      'sensorIntegrityState': '${first([
            sensorIntegrity['state'],
            sensorIntegrity['status'],
            data['sensorIntegrity'] is String ? data['sensorIntegrity'] : null,
            ''
          ])}',
      'sensorIntegrityPrimaryIssue': '${first([
            sensorIntegrity['primaryIssue'],
            sensorIntegrity['issue'],
            ''
          ])}',
      'sensorIntegrityPrimaryAction': '${first([
            sensorIntegrity['primaryAction'],
            sensorIntegrity['recommendation'],
            ''
          ])}',
      'sensorIntegrityChannels': _stateMap(sensorIntegrity['channels']),
      'runtimeHealthState':
          '${first([runtimeHealth['state'], runtimeHealth['status'], ''])}',
      'runtimeFreeHeap': _asInt(runtimeHealth['freeHeap']),
      'runtimeMinFreeHeap': _asInt(runtimeHealth['minFreeHeap']),
      'runtimeLastLoopGapMs': _asInt(runtimeHealth['lastLoopGapMs']),
      'runtimeMaxLoopGapMs': _asInt(runtimeHealth['maxLoopGapMs']),
      'runtimeLastSensorCycleMs': _asInt(runtimeHealth['lastSensorCycleMs']),
      'runtimeMaxSensorCycleMs': _asInt(runtimeHealth['maxSensorCycleMs']),
      'runtimeOledI2cSkipTotal': _asInt(runtimeHealth['oledI2cSkipTotal']),
      'runtimeHealthIssue':
          '${first([runtimeHealth['issue'], runtimeHealth['message'], ''])}',
      'recentEvents': recentEvents is List ? recentEvents : const <dynamic>[],
      'sensorStates': <String, String>{
        'temperature': _channelState(
          air,
          temperatureValid,
          externalState: sensorStates['temperature'],
        ),
        'humidity': _channelState(
          air,
          humidityValid,
          externalState: sensorStates['humidity'],
        ),
        'soilMoisture': _channelState(
          soil,
          soilValid,
          externalState: sensorStates['soilMoisture'],
        ),
        'soilTemperature': _channelState(
          soil,
          rootValid,
          externalState: sensorStates['soilTemperature'],
        ),
        'light': _channelState(
          light,
          lightValid,
          externalState: sensorStates['light'],
        ),
        'leafWetness': _channelState(
          leaf,
          leafValid,
          externalState: sensorStates['leafWetness'],
        ),
        'plantSignal': _channelState(
          bio,
          bioMeasurementValid,
          externalState:
              sensorStates['plantSignal'] ?? sensorStates['bioelectric'],
        ),
      },
      'esp32HealthScore': espHealth,
      'esp32HealthConfidence': espConfidence,
      'waterScore': _asDouble(
        first([
          components['water'],
          components['waterScore'],
          data['waterScore'],
          data['waterBalance'],
        ]),
      ),
      'thermalScore': _asDouble(
        first([
          components['thermal'],
          components['thermalScore'],
          data['thermalScore'],
        ]),
      ),
      'rootZoneScore': _asDouble(
        first([
          components['rootZone'],
          components['rootZoneScore'],
          data['rootZoneScore'],
        ]),
      ),
      'atmosphericScore': _asDouble(
        first([
          components['atmospheric'],
          components['atmosphericScore'],
          data['atmosphericScore'],
        ]),
      ),
      'lightScore': _asDouble(
        first([
          components['light'],
          components['lightScore'],
          data['lightScore'],
        ]),
      ),
      'diseaseRisk': _asDouble(
        first([
          components['diseaseRiskPercent'],
          data['diseaseRiskPercent'],
          data['diseaseRisk'],
        ]),
      ),
      'bioelectricStability': stabilityValue,
      'soilRaw': _asInt(
        first([soil['moistureRaw'], data['soilMoistureRaw'], data['soilRaw']]),
      ),
      'leafRaw': _asInt(
        first([leaf['raw'], data['leafWetnessRaw'], data['leafRaw']]),
      ),
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
      'leafWetDurationSeconds': _asDouble(
            first([
              leaf['continuousWetSeconds'],
              data['continuousLeafWetSeconds'],
            ]),
          ) ??
          0,
      'recentWetExposureSeconds': _asDouble(
            first([
              leaf['recentWetExposureSeconds'],
              data['recentWetExposureSeconds'],
            ]),
          ) ??
          0,
      'bioBaselineReady': bio['baselineReady'] == true,
      'bioBaselineSamples': _asInt(bio['baselineSamples']) ?? 0,
      'bioBaselineMv': _asDouble(bio['baselineMv']),
      'bioDeviationMv': _asDouble(bio['deviationMv']),
      'bioNoiseMv': _asDouble(bio['noiseMv']),
      'bioSignalQuality': qualityValue ?? 0,
      'bioContactState': bioContactState,
      'bioContactConfidence': bioContactConfidence,
      'bioSlowDriftMv': bioSlowDriftMv,
      'bioContactPlausibleForPlantUse': bioContactPlausibleForPlantUse,
      'bioAffectsHealth': bioAffectsHealth,
      'bioOpenLatched': bioOpenLatched,
      'bioReconnectVerifying': bioReconnectVerifying,
      'bioReconnectVerifySec': bioReconnectVerifySec,
      'firmwareName': '${first([
            data['firmwareName'],
            data['firmwareVersion'],
            data['firmware'],
            root['firmwareName'],
            root['firmwareVersion'],
            root['firmware'],
            ''
          ])}',
      'firmwareEdition':
          '${first([data['firmwareEdition'], root['firmwareEdition'], ''])}',
      'firmwareBuildState': '${first([
            data['buildState'],
            data['firmwareBuildState'],
            system['buildState'],
            root['buildState'],
            ''
          ])}',
    };

    return Esp32Snapshot(
      reading: SensorReading.fromJson(normalized),
      batteryPercent: _percentInt(
        first([data['batteryPercent'], root['batteryPercent']]),
        100,
      ),
      signalPercent: _percentInt(
        first([data['signalPercent'], root['signalPercent']]),
        100,
      ),
      firmwareVersion: '${first([
            data['firmwareVersion'],
            data['firmware'],
            root['firmware'],
            root['firmwareVersion'],
            'unknown'
          ])}',
      connectionMode: '${first([
            data['connectionMode'],
            network['connectionMode'],
            system['connectionMode'],
            ''
          ])}',
      remoteNetworkState: '${first([
            data['remoteNetworkState'],
            network['remoteNetworkState'],
            system['remoteNetworkState'],
            ''
          ])}',
      localApActive: _asBool(
        first([data['localApActive'], network['localApActive']]),
      ),
      internetConnected: _asBool(
        first([data['internetConnected'], network['internetConnected']]),
      ),
      cloudConnected: _asBool(
        first([data['cloudConnected'], network['cloudConnected']]),
      ),
      connectedStaSsid: '${first([
            data['connectedStaSsid'],
            network['connectedStaSsid'],
            data['staSsid'],
            network['staSsid'],
            ''
          ])}',
      lastCloudSync: _dateTime(
        first([
          data['lastCloudSync'],
          network['lastCloudSync'],
          data['lastCloudSyncMs'],
          network['lastCloudSyncMs'],
        ]),
      ),
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

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static Map<String, String> _stateMap(dynamic value) {
    if (value is! Map) return const <String, String>{};
    final result = <String, String>{};
    for (final entry in value.entries) {
      final item = entry.value;
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final state = _textValue(
          map['state'] ?? map['status'] ?? map['quality'] ?? map['issue'],
        );
        if (state != null) result['${entry.key}'] = state;
      } else {
        final state = _textValue(item);
        if (state != null) result['${entry.key}'] = state;
      }
    }
    return result;
  }

  static String _normalizePlantModelStatus(dynamic value) {
    final upper = '${value ?? ''}'.trim().toUpperCase();
    if (upper.contains('RESTOR') || upper == 'READY') return 'READY';
    if (upper.contains('LEARN')) return 'LEARNING';
    return upper;
  }

  static bool _plantModelReady(Map<String, dynamic> plantModel) {
    if (_asBool(plantModel['ready']) == true) return true;
    final state =
        '${plantModel['status'] ?? plantModel['state'] ?? ''}'.toUpperCase();
    return state.contains('READY') || state.contains('RESTOR');
  }

  static bool _channelValid(
    Map<String, dynamic> channel, {
    dynamic explicitValid,
    dynamic externalState,
  }) {
    if (_asBool(explicitValid) == false) return false;
    final state =
        '${externalState ?? channel['state'] ?? channel['status'] ?? channel['quality'] ?? ''}'
            .trim()
            .toUpperCase();
    return !const <String>{
      'UNAVAILABLE',
      'NOT_AVAILABLE',
      'INVALID',
      'BAD_DATA',
      'SIGNAL_NOISY',
      'CHECK_CONTACT',
      'SATURATED',
      'AMP_HIGH_RAIL',
      'AMP_LOW_RAIL',
      'FAILED',
      'ERROR',
    }.contains(state);
  }

  static bool _deploymentVerificationState(dynamic value) {
    final state = '${value ?? ''}'
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    return const {
      'VERIFY',
      'PLACEMENT_VERIFY',
      'CHECK_PLACEMENT',
      'OUTSIDE_CALIBRATED_RANGE',
      'HEALTH_USE_DISABLED',
      'DISABLED',
    }.contains(state);
  }

  static String _channelState(
    Map<String, dynamic> channel,
    bool valid, {
    dynamic externalState,
  }) {
    final state =
        '${externalState ?? channel['state'] ?? channel['status'] ?? channel['quality'] ?? ''}'
            .trim()
            .toUpperCase();
    if (state.isNotEmpty) return state;
    return valid ? 'AVAILABLE' : 'UNAVAILABLE';
  }

  static String _normalizeReliability(dynamic value, {required bool degraded}) {
    final raw = value is Map
        ? '${value['mode'] ?? value['status'] ?? value['state'] ?? ''}'
        : '$value';
    final upper = raw.trim().toUpperCase();
    if (upper.contains('RECOVER')) return 'RECOVERING';
    if (upper.contains('DEGRADED')) return 'DEGRADED';
    if (upper.contains('FULL')) return 'FULL';
    return degraded ? 'DEGRADED' : 'FULL';
  }

  static List<String> _mergeCauses(
    String primary,
    String? secondary,
    List<String> existing,
  ) {
    final result = <String>[];
    for (final item in <String>[primary, secondary ?? '', ...existing]) {
      final clean = item.trim();
      if (clean.isNotEmpty && !result.contains(clean)) result.add(clean);
    }
    return result;
  }

  static bool _predictionStateAvailable(dynamic value) {
    final state = '${value ?? ''}'.trim().toUpperCase();
    return state.isNotEmpty &&
        state != 'NONE' &&
        state != 'UNAVAILABLE' &&
        state != 'DISABLED';
  }

  static bool _isDaytime(dynamic value) {
    if (value is bool) return value;
    final text = '${value ?? ''}'.trim().toUpperCase();
    if (text == 'NIGHT') return false;
    if (text == 'DAY') return true;
    return _asBool(value) ?? true;
  }

  static List<String> _causeList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map(_causeLabel)
        .whereType<String>()
        .where((cause) => cause.isNotEmpty)
        .toList(growable: false);
  }

  static String? _causeLabel(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return _textValue(
        value['label'] ??
            value['cause'] ??
            value['name'] ??
            value['title'] ??
            value['id'],
      );
    }
    return _textValue(value);
  }

  static String? _textValue(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty || text == '{}' ? null : text;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    final normalized = '$value'.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
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

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final raw = value.toInt();
      final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
    final text = '$value'.trim();
    if (text.isEmpty) return null;
    final numeric = int.tryParse(text);
    if (numeric != null) return _dateTime(numeric);
    return DateTime.tryParse(text);
  }

  static String _timestamp(Map<String, dynamic> payload) {
    final direct = payload['timestamp'] ?? payload['lastSeen'];
    if (direct is num) {
      final raw = direct.toInt();
      final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds)
          .toIso8601String();
    }
    if (direct != null) {
      final text = '$direct'.trim();
      final numeric = int.tryParse(text);
      if (numeric != null) {
        final milliseconds =
            numeric.abs() < 100000000000 ? numeric * 1000 : numeric;
        return DateTime.fromMillisecondsSinceEpoch(milliseconds)
            .toIso8601String();
      }
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return parsed.toIso8601String();
    }
    return DateTime.now().toIso8601String();
  }
}

class Esp32Snapshot {
  final SensorReading reading;
  final int batteryPercent;
  final int signalPercent;
  final String firmwareVersion;
  final String connectionMode;
  final String remoteNetworkState;
  final bool? localApActive;
  final bool? internetConnected;
  final bool? cloudConnected;
  final String connectedStaSsid;
  final DateTime? lastCloudSync;
  final String endpoint;
  final int sensorCount;

  const Esp32Snapshot({
    required this.reading,
    required this.batteryPercent,
    required this.signalPercent,
    required this.firmwareVersion,
    this.connectionMode = '',
    this.remoteNetworkState = '',
    this.localApActive,
    this.internetConnected,
    this.cloudConnected,
    this.connectedStaSsid = '',
    this.lastCloudSync,
    required this.endpoint,
    required this.sensorCount,
  });
}
