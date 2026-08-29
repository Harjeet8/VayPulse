class HardwareSensorDetail {
  final String channel;
  final String? result;
  final String? explanation;
  final String? contribution;
  final String? trend;
  final double? ratePerHour;
  final double? ratePerMinute;
  final double? shortSlopePerMinute;
  final double? longSlopePerMinute;
  final double? confidence;
  final String? status;
  final String? quality;
  final double? rawValue;

  const HardwareSensorDetail({
    required this.channel,
    this.result,
    this.explanation,
    this.contribution,
    this.trend,
    this.ratePerHour,
    this.ratePerMinute,
    this.shortSlopePerMinute,
    this.longSlopePerMinute,
    this.confidence,
    this.status,
    this.quality,
    this.rawValue,
  });
}

class HardwareTelemetry {
  final String firmwareVersion;
  final String? cropProfile;
  final String? growthStage;
  final String? analysisQuality;
  final String? dayPhase;
  final double? vpdKpa;
  final double? airRootDeltaC;
  final double? bioelectricDeviationPercent;
  final Map<String, HardwareSensorDetail> sensors;

  const HardwareTelemetry({
    required this.firmwareVersion,
    this.cropProfile,
    this.growthStage,
    this.analysisQuality,
    this.dayPhase,
    this.vpdKpa,
    this.airRootDeltaC,
    this.bioelectricDeviationPercent,
    this.sensors = const {},
  });

  HardwareSensorDetail? sensor(String channel) => sensors[channel];

  factory HardwareTelemetry.fromPayload({
    required Map<String, dynamic> root,
    required Map<String, dynamic> data,
    required String firmwareVersion,
  }) {
    final readings = _map(data['readings']);
    final air = _map(readings['air']);
    final soil = _map(readings['soil']);
    final light = _map(readings['light']);
    final leaf = _map(readings['leaf']);
    final bio = _map(readings['bioelectric']);
    final plantHealth = _map(data['plantHealth']);
    final components = _firstMap([
      plantHealth['components'],
      data['healthComponents'],
      data['components'],
    ]);
    final edge = _firstMap([
      data['edgeIntelligence'],
      data['intelligence'],
      data['analysis'],
      data['plantIntelligence'],
      plantHealth['intelligence'],
    ]);
    final quality = _firstMap([
      edge['analysisQuality'],
      data['analysisQuality'],
      plantHealth['analysisQuality'],
    ]);
    final derived = _firstMap([
      edge['derivedEnvironment'],
      edge['derived'],
      data['derivedEnvironment'],
      data['derived'],
    ]);
    final profile = _firstMap([
      edge['cropProfile'],
      data['cropProfile'],
      data['crop'],
      plantHealth['cropProfile'],
    ]);

    final confidenceSource = _first([
      edge['sensorConfidence'],
      data['sensorConfidence'],
      quality['sensorConfidence'],
    ]);
    final trendSource = _first([
      edge['trends'],
      data['trends'],
      plantHealth['trends'],
    ]);
    final resultSource = _first([
      edge['sensorResults'],
      edge['sensorInterpretation'],
      data['sensorResults'],
      data['sensorInterpretation'],
      plantHealth['sensorResults'],
    ]);
    final contributionSource = _first([
      edge['sensorContribution'],
      edge['sensorContributions'],
      data['sensorContribution'],
      data['sensorContributions'],
    ]);

    final aliases = <String, List<String>>{
      'airTemperature': const ['airTemperature', 'temperature', 'air', 'thermal'],
      'humidity': const ['humidity', 'relativeHumidity', 'atmospheric'],
      'light': const ['light', 'lux', 'daylight'],
      'soilMoisture': const ['soilMoisture', 'soil', 'water'],
      'rootTemperature': const ['rootTemperature', 'soilTemperature', 'rootZone'],
      'leafWetness': const ['leafWetness', 'leaf'],
      'plantSignal': const ['plantSignal', 'bioelectric', 'bio'],
      'vpd': const ['vpd', 'airDryingDemand', 'atmosphericDryingDemand'],
      'airDryingDemand': const ['airDryingDemand', 'vpd', 'atmosphericDryingDemand'],
    };

    HardwareSensorDetail build(
      String channel, {
      Map<String, dynamic> readingMap = const {},
      dynamic fallbackResult,
      dynamic fallbackQuality,
      dynamic raw,
    }) {
      final names = aliases[channel] ?? <String>[channel];
      final confidenceValue = _lookupChannel(confidenceSource, names);
      final trendValue = _lookupChannel(trendSource, names);
      final resultValue = _lookupChannel(resultSource, names);
      final contributionValue = _lookupChannel(contributionSource, names);
      final confidenceMap = _map(confidenceValue);
      final trendMap = _map(trendValue);
      final resultMap = _map(resultValue);
      final contributionMap = _map(contributionValue);

      return HardwareSensorDetail(
        channel: channel,
        result: _text(_first([
          resultMap['result'],
          resultMap['label'],
          resultMap['interpretation'],
          resultMap['state'],
          readingMap['result'],
          readingMap['interpretation'],
          readingMap['condition'],
          fallbackResult,
        ])),
        explanation: _text(_first([
          resultMap['explanation'],
          resultMap['message'],
          readingMap['explanation'],
          readingMap['interpretationText'],
        ])),
        contribution: _text(_first([
          contributionMap['description'],
          contributionMap['label'],
          contributionMap['state'],
          contributionValue is String ? contributionValue : null,
          resultMap['effectOnPlant'],
          resultMap['contribution'],
          readingMap['effectOnPlant'],
          readingMap['contribution'],
        ])),
        trend: _text(_first([
          trendMap['state'],
          trendMap['trend'],
          trendValue is String ? trendValue : null,
          readingMap['trend'],
        ])),
        ratePerHour: _num(_first([
          trendMap['ratePerHour'],
          trendMap['slopePerHour'],
          readingMap['ratePerHour'],
          readingMap['rateOfChangePerHour'],
        ])),
        ratePerMinute: _num(_first([
          trendMap['ratePerMinute'],
          readingMap['ratePerMinute'],
          readingMap['rateOfChangePerMinute'],
        ])),
        shortSlopePerMinute: _num(_first([
          trendMap['shortSlopePerMinute'],
          readingMap['shortSlopePerMinute'],
        ])),
        longSlopePerMinute: _num(_first([
          trendMap['longSlopePerMinute'],
          readingMap['longSlopePerMinute'],
        ])),
        confidence: _percent(_first([
          confidenceMap['confidence'],
          confidenceMap['percent'],
          confidenceMap['score'],
          confidenceValue is num ? confidenceValue : null,
          readingMap['confidence'],
        ])),
        status: _text(_first([
          resultMap['status'],
          confidenceMap['state'],
          readingMap['status'],
          readingMap['qualityState'],
        ])),
        quality: _text(_first([
          readingMap['quality'],
          readingMap['signalQuality'],
          fallbackQuality,
        ])),
        rawValue: _num(_first([
          readingMap['raw'],
          readingMap['rawValue'],
          raw,
        ])),
      );
    }

    final sensorMap = <String, HardwareSensorDetail>{
      'airTemperature': build(
        'airTemperature',
        readingMap: air,
        fallbackResult: _first([
          components['thermalCondition'],
          _scoreLabel(components['thermal']),
          _scoreLabel(components['thermalScore']),
        ]),
      ),
      'humidity': build(
        'humidity',
        readingMap: air,
        fallbackResult: _first([
          components['atmosphericCondition'],
          _scoreLabel(components['atmospheric']),
          _scoreLabel(components['atmosphericScore']),
        ]),
      ),
      'light': build(
        'light',
        readingMap: light,
        fallbackResult: _first([
          components['lightCondition'],
          _scoreLabel(components['light']),
          _scoreLabel(components['lightScore']),
        ]),
      ),
      'soilMoisture': build(
        'soilMoisture',
        readingMap: soil,
        fallbackResult: _first([
          components['soilWaterCondition'],
          components['waterCondition'],
          _scoreLabel(components['water']),
          _scoreLabel(components['waterScore']),
        ]),
        raw: _first([soil['moistureRaw'], data['soilMoistureRaw']]),
      ),
      'rootTemperature': build(
        'rootTemperature',
        readingMap: soil,
        fallbackResult: _first([
          components['rootZoneCondition'],
          _scoreLabel(components['rootZone']),
          _scoreLabel(components['rootZoneScore']),
        ]),
      ),
      'leafWetness': build(
        'leafWetness',
        readingMap: leaf,
        fallbackResult: _first([
          leaf['wetnessState'],
          leaf['wetState'],
          leaf['state'],
        ]),
        raw: _first([leaf['raw'], data['leafWetnessRaw']]),
      ),
      'plantSignal': build(
        'plantSignal',
        readingMap: bio,
        fallbackResult: _first([
          bio['electricalState'],
          bio['state'],
          data['plantElectricalCondition'],
          data['plantSignalState'],
        ]),
        fallbackQuality: _first([
          bio['signalQualityState'],
          bio['qualityState'],
          bio['signalQualityPercent'],
          bio['signalQuality'],
          data['bioSignalQuality'],
        ]),
        raw: _first([
          bio['rawADC'],
          bio['rawAdc'],
          bio['raw'],
          bio['adcRaw'],
          data['plantAdcRaw'],
        ]),
      ),
      'vpd': build('vpd'),
      'airDryingDemand': build('airDryingDemand'),
    };

    final airTemp = _num(_first([
      data['airTemperatureC'],
      data['temperatureC'],
      data['temperature'],
      air['temperatureC'],
    ]));
    final rootTemp = _num(_first([
      data['soilTemperatureC'],
      data['soilTemperature'],
      soil['temperatureC'],
    ]));

    return HardwareTelemetry(
      firmwareVersion: firmwareVersion,
      cropProfile: _text(_first([
        profile['profile'],
        profile['name'],
        edge['cropProfileName'],
        data['cropProfileName'],
        data['crop'] is String ? data['crop'] : null,
      ])),
      growthStage: _text(_first([
        profile['growthStage'],
        edge['growthStage'],
        data['growthStage'],
      ])),
      analysisQuality: _text(_first([
        quality['label'],
        quality['state'],
        quality['quality'],
        edge['analysisQualityLabel'],
        data['analysisQualityLabel'],
        data['analysisQuality'] is String ? data['analysisQuality'] : null,
      ])),
      dayPhase: _text(_first([
        data['dayNight'],
        data['dayPhase'],
        light['phase'],
      ])),
      vpdKpa: _num(_first([
        derived['vpdKpa'],
        derived['vpd'],
        edge['vpdKpa'],
        edge['vpd'],
        data['vpdKpa'],
        data['vpd'],
      ])),
      airRootDeltaC: _num(_first([
            derived['airRootTemperatureDifferenceC'],
            derived['airRootDeltaC'],
            edge['airRootTemperatureDifferenceC'],
            data['airRootTemperatureDifferenceC'],
          ])) ??
          ((airTemp != null && rootTemp != null) ? airTemp - rootTemp : null),
      bioelectricDeviationPercent: _num(_first([
        bio['deviationPercent'],
        bio['baselineDeviationPercent'],
        edge['bioelectricDeviationPercent'],
        data['bioelectricDeviationPercent'],
        data['plantElectricalDeviationPercent'],
      ])),
      sensors: sensorMap,
    );
  }
}

String? _scoreLabel(dynamic raw) {
  final value = _num(raw);
  if (value == null) return null;
  if (value >= 85) return 'GOOD';
  if (value >= 65) return 'ACCEPTABLE';
  if (value >= 40) return 'NEEDS_ATTENTION';
  return 'POOR';
}

dynamic _lookupChannel(dynamic source, List<String> aliases) {
  if (source is Map) {
    for (final alias in aliases) {
      if (source.containsKey(alias)) return source[alias];
      final normalizedAlias = _norm(alias);
      for (final entry in source.entries) {
        if (_norm('${entry.key}') == normalizedAlias) return entry.value;
      }
    }
  }
  if (source is List) {
    for (final item in source) {
      final map = _map(item);
      final name = _text(_first([map['channel'], map['sensor'], map['name']]));
      if (name == null) continue;
      if (aliases.any((alias) => _norm(alias) == _norm(name))) return item;
    }
  }
  return null;
}

String _norm(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Map<String, dynamic> _firstMap(List<dynamic> values) {
  for (final value in values) {
    final map = _map(value);
    if (map.isNotEmpty) return map;
  }
  return <String, dynamic>{};
}

dynamic _first(List<dynamic> values) {
  for (final value in values) {
    if (value != null) return value;
  }
  return null;
}

double? _num(dynamic value) {
  if (value == null || value is bool) return null;
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return parsed?.isFinite == true ? parsed : null;
}

double? _percent(dynamic value) {
  final parsed = _num(value);
  return parsed?.clamp(0.0, 100.0).toDouble();
}

String? _text(dynamic value) {
  if (value == null || value is Map || value is List) return null;
  final text = '$value'.trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}
