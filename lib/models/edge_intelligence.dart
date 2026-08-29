class FirmwareCapabilities {
  final bool edgeDecision;
  final bool plantState;
  final bool sensorConfidence;
  final bool trends;
  final bool rootCause;
  final bool recovery;
  final bool prediction;
  final bool baseline;
  final bool derivedEnvironment;
  final bool stressEvidence;
  final bool sensorFaults;
  final bool irrigation;
  final bool events;
  final bool tinyMl;
  final bool cropProfile;
  final bool growthStage;

  const FirmwareCapabilities({
    this.edgeDecision = false,
    this.plantState = false,
    this.sensorConfidence = false,
    this.trends = false,
    this.rootCause = false,
    this.recovery = false,
    this.prediction = false,
    this.baseline = false,
    this.derivedEnvironment = false,
    this.stressEvidence = false,
    this.sensorFaults = false,
    this.irrigation = false,
    this.events = false,
    this.tinyMl = false,
    this.cropProfile = false,
    this.growthStage = false,
  });

  bool get advanced => sensorConfidence ||
      trends ||
      rootCause ||
      recovery ||
      prediction ||
      baseline ||
      stressEvidence ||
      sensorFaults ||
      irrigation;
}

class SensorConfidence {
  final String channel;
  final double? percent;
  final double? decayPercent;
  final String? state;
  final bool? valid;

  const SensorConfidence({
    required this.channel,
    this.percent,
    this.decayPercent,
    this.state,
    this.valid,
  });
}

class SensorTrend {
  final String channel;
  final String? state;
  final double? slope;
  final double? variability;

  const SensorTrend({
    required this.channel,
    this.state,
    this.slope,
    this.variability,
  });
}

class RootCauseAnalysis {
  final String? primary;
  final String? secondary;
  final String? additionalContributor;

  const RootCauseAnalysis({
    this.primary,
    this.secondary,
    this.additionalContributor,
  });

  bool get hasAny => primary != null || secondary != null || additionalContributor != null;
}

class RecoveryInfo {
  final bool active;
  final String? quality;
  final double? durationSeconds;
  final String? improved;
  final String? remainingConcern;

  const RecoveryInfo({
    this.active = false,
    this.quality,
    this.durationSeconds,
    this.improved,
    this.remainingConcern,
  });

  bool get hasData => active || quality != null || improved != null || remainingConcern != null;
}

class PredictionInfo {
  final String? state;
  final String? explanation;
  final String? whatIfExplanation;
  final double? confidence;
  final double? minutesToWaterStressWarning;

  const PredictionInfo({
    this.state,
    this.explanation,
    this.whatIfExplanation,
    this.confidence,
    this.minutesToWaterStressWarning,
  });

  bool get hasData => state != null || explanation != null || minutesToWaterStressWarning != null;
}

class PlantBaselineInfo {
  final String? status;
  final bool? ready;
  final double? learnedNormal;
  final double? deviation;
  final bool anomalyDetected;
  final bool changePointDetected;

  const PlantBaselineInfo({
    this.status,
    this.ready,
    this.learnedNormal,
    this.deviation,
    this.anomalyDetected = false,
    this.changePointDetected = false,
  });

  bool get hasData => status != null || ready != null || learnedNormal != null || deviation != null || anomalyDetected || changePointDetected;
}

class StressEvidence {
  final double? water;
  final double? heat;
  final double? rootZone;
  final double? diseaseEnvironment;
  final double? sensorFault;

  const StressEvidence({
    this.water,
    this.heat,
    this.rootZone,
    this.diseaseEnvironment,
    this.sensorFault,
  });

  bool get hasData => water != null || heat != null || rootZone != null || diseaseEnvironment != null || sensorFault != null;
}

class SensorFaultInfo {
  final String channel;
  final String? type;
  final String? explanation;
  final double? confidence;
  final bool crossSensorConflict;

  const SensorFaultInfo({
    required this.channel,
    this.type,
    this.explanation,
    this.confidence,
    this.crossSensorConflict = false,
  });
}

class DerivedEnvironmentInfo {
  final double? vpdKpa;
  final double? airDryingDemand;

  const DerivedEnvironmentInfo({this.vpdKpa, this.airDryingDemand});

  bool get hasData => vpdKpa != null || airDryingDemand != null;
}

class PhytoEvent {
  final DateTime? timestamp;
  final String type;
  final String message;
  final String? severity;

  const PhytoEvent({
    this.timestamp,
    required this.type,
    required this.message,
    this.severity,
  });
}

class IrrigationEvent {
  final bool probable;
  final String? response;
  final String? explanation;
  final DateTime? timestamp;

  const IrrigationEvent({
    this.probable = false,
    this.response,
    this.explanation,
    this.timestamp,
  });

  bool get hasData => probable || response != null || explanation != null;
}

class CropProfileInfo {
  final String? profile;
  final String? growthStage;
  final List<String> supportedProfiles;
  final List<String> supportedStages;
  final bool switchable;

  const CropProfileInfo({
    this.profile,
    this.growthStage,
    this.supportedProfiles = const [],
    this.supportedStages = const [],
    this.switchable = false,
  });

  bool get hasData => profile != null || growthStage != null || supportedProfiles.isNotEmpty || supportedStages.isNotEmpty;
}

class TinyMlInfo {
  final String? status;
  final bool ready;
  final bool modelLoaded;
  final bool featureVectorAvailable;

  const TinyMlInfo({
    this.status,
    this.ready = false,
    this.modelLoaded = false,
    this.featureVectorAvailable = false,
  });

  bool get hasData => status != null || ready || modelLoaded || featureVectorAvailable;
}

class EdgeIntelligence {
  final String firmwareVersion;
  final FirmwareCapabilities capabilities;
  final double? healthScore;
  final double? overallConfidence;
  final String? plantState;
  final String? urgency;
  final String? farmerSummary;
  final String? recommendation;
  final String? decisionExplanation;
  final bool generatedOnDevice;
  final bool degradedAnalysis;
  final String? degradedReason;
  final RootCauseAnalysis rootCause;
  final RecoveryInfo recovery;
  final PredictionInfo prediction;
  final PlantBaselineInfo baseline;
  final StressEvidence stressEvidence;
  final DerivedEnvironmentInfo derivedEnvironment;
  final List<SensorConfidence> sensorConfidence;
  final List<SensorTrend> trends;
  final List<SensorFaultInfo> sensorFaults;
  final List<PhytoEvent> recentEvents;
  final IrrigationEvent irrigation;
  final CropProfileInfo cropProfile;
  final TinyMlInfo tinyMl;
  final List<String> activeSensorChannels;
  final List<String> riskFlags;
  final double? diseaseRiskScore;
  final String? diseaseRiskLevel;
  final bool? confirmedDisease;

  const EdgeIntelligence({
    required this.firmwareVersion,
    required this.capabilities,
    this.healthScore,
    this.overallConfidence,
    this.plantState,
    this.urgency,
    this.farmerSummary,
    this.recommendation,
    this.decisionExplanation,
    this.generatedOnDevice = false,
    this.degradedAnalysis = false,
    this.degradedReason,
    this.rootCause = const RootCauseAnalysis(),
    this.recovery = const RecoveryInfo(),
    this.prediction = const PredictionInfo(),
    this.baseline = const PlantBaselineInfo(),
    this.stressEvidence = const StressEvidence(),
    this.derivedEnvironment = const DerivedEnvironmentInfo(),
    this.sensorConfidence = const [],
    this.trends = const [],
    this.sensorFaults = const [],
    this.recentEvents = const [],
    this.irrigation = const IrrigationEvent(),
    this.cropProfile = const CropProfileInfo(),
    this.tinyMl = const TinyMlInfo(),
    this.activeSensorChannels = const [],
    this.riskFlags = const [],
    this.diseaseRiskScore,
    this.diseaseRiskLevel,
    this.confirmedDisease,
  });

  bool get hasAuthoritativeAnalysis => healthScore != null &&
      (capabilities.edgeDecision ||
          generatedOnDevice ||
          recommendation != null ||
          decisionExplanation != null ||
          plantState != null ||
          rootCause.hasAny);

  factory EdgeIntelligence.fromPayload({
    required Map<String, dynamic> root,
    required Map<String, dynamic> data,
    required String firmwareVersion,
  }) {
    final plantHealth = _map(data['plantHealth']);
    final edge = _firstMap([
      data['edgeIntelligence'],
      data['intelligence'],
      data['analysis'],
      data['plantIntelligence'],
      plantHealth['intelligence'],
    ]);
    final decision = _firstMap([
      plantHealth['decision'],
      edge['decision'],
      data['decision'],
    ]);
    final rootCauseMap = _firstMap([
      edge['rootCause'],
      data['rootCause'],
      plantHealth['rootCause'],
    ]);
    final recoveryMap = _firstMap([
      edge['recovery'],
      data['recovery'],
      plantHealth['recovery'],
    ]);
    final predictionMap = _firstMap([
      edge['prediction'],
      data['prediction'],
      plantHealth['prediction'],
      edge['forecast'],
      data['forecast'],
    ]);
    final baselineMap = _firstMap([
      edge['baseline'],
      edge['adaptiveBaseline'],
      data['baseline'],
      data['adaptiveBaseline'],
      plantHealth['baseline'],
    ]);
    final evidenceMap = _firstMap([
      edge['stressEvidence'],
      edge['evidence'],
      data['stressEvidence'],
      data['evidence'],
    ]);
    final derivedMap = _firstMap([
      edge['derivedEnvironment'],
      edge['derived'],
      data['derivedEnvironment'],
      data['derived'],
    ]);
    final irrigationMap = _firstMap([
      edge['irrigation'],
      edge['irrigationEvent'],
      data['irrigation'],
      data['irrigationEvent'],
    ]);
    final cropMap = _firstMap([
      edge['cropProfile'],
      data['cropProfile'],
      data['crop'],
      plantHealth['cropProfile'],
    ]);
    final tinyMlMap = _firstMap([
      edge['tinyMl'],
      edge['tinyML'],
      data['tinyMl'],
      data['tinyML'],
    ]);
    final diseaseMap = _firstMap([
      plantHealth['diseaseConduciveRisk'],
      edge['diseaseConduciveRisk'],
      data['diseaseConduciveRisk'],
    ]);
    final qualityMap = _firstMap([
      edge['analysisQuality'],
      data['analysisQuality'],
      plantHealth['analysisQuality'],
    ]);

    final healthScore = _num(_first([
      edge['healthScore'],
      edge['health'],
      data['healthScore'],
      data['health'],
      plantHealth['score'],
      plantHealth['index'],
    ]));
    final confidence = _percent(_first([
      edge['overallAnalysisConfidence'],
      edge['overallConfidence'],
      edge['healthConfidence'],
      data['overallAnalysisConfidence'],
      data['overallConfidence'],
      data['healthConfidence'],
      data['analysisConfidence'],
      plantHealth['confidence'],
      qualityMap['confidence'],
    ]));
    final plantState = _text(_first([
      edge['plantState'],
      data['plantState'],
      plantHealth['plantCondition'],
      plantHealth['status'],
      data['healthStatus'],
    ]));
    final urgency = _text(_first([
      decision['urgency'],
      edge['priority'],
      data['priority'],
      edge['urgency'],
      data['urgency'],
    ]));
    final recommendation = _text(_first([
      edge['recommendation'],
      edge['primaryAction'],
      data['recommendation'],
      data['primaryAction'],
      decision['action'],
    ]));
    final explanation = _text(_first([
      edge['decisionExplanation'],
      data['decisionExplanation'],
      decision['because'],
      predictionMap['explanation'],
    ]));
    final farmerSummary = _text(_first([
      edge['farmerSummary'],
      data['farmerSummary'],
      decision['farmerFriendly'],
      decision['finding'],
      data['primaryFinding'],
    ]));

    final sensorConfidence = _parseConfidences(_first([
      edge['sensorConfidence'],
      data['sensorConfidence'],
      qualityMap['sensorConfidence'],
    ]));
    final trends = _parseTrends(_first([
      edge['trends'],
      data['trends'],
      plantHealth['trends'],
    ]));
    final faults = _parseFaults(_first([
      edge['sensorFaults'],
      edge['sensorFault'],
      data['sensorFaults'],
      data['sensorFault'],
      qualityMap['sensorFaults'],
    ]));
    final events = _parseEvents(_first([
      edge['recentEvents'],
      edge['events'],
      data['recentEvents'],
      data['events'],
    ]));

    final crossSensorConflict = _bool(_first([
          edge['crossSensorConflict'],
          data['crossSensorConflict'],
          qualityMap['crossSensorConflict'],
        ])) ==
        true;
    final sensorFaultType = _text(_first([
      edge['sensorFaultType'],
      data['sensorFaultType'],
      qualityMap['sensorFaultType'],
    ]));
    if (faults.isEmpty && (crossSensorConflict || sensorFaultType != null)) {
      faults.add(SensorFaultInfo(
        channel: 'system',
        type: sensorFaultType,
        crossSensorConflict: crossSensorConflict,
      ));
    }

    final rootCause = RootCauseAnalysis(
      primary: _text(_first([
        rootCauseMap['primary'],
        rootCauseMap['primaryCause'],
        edge['primaryCause'],
        data['primaryCause'],
        data['primaryFinding'],
      ])),
      secondary: _text(_first([
        rootCauseMap['secondary'],
        rootCauseMap['secondaryCause'],
        edge['secondaryCause'],
        data['secondaryCause'],
      ])),
      additionalContributor: _text(_first([
        rootCauseMap['additionalContributor'],
        rootCauseMap['contributor'],
        edge['additionalContributor'],
        data['additionalContributor'],
      ])),
    );

    final recovery = RecoveryInfo(
      active: _bool(_first([
            recoveryMap['active'],
            edge['recoveryActive'],
            data['recoveryActive'],
          ])) ==
          true ||
          (plantState?.toUpperCase() == 'RECOVERING'),
      quality: _text(_first([
        recoveryMap['quality'],
        edge['recoveryQuality'],
        data['recoveryQuality'],
      ])),
      durationSeconds: _num(_first([
        recoveryMap['durationSeconds'],
        recoveryMap['durationSec'],
        edge['recoveryDurationSeconds'],
        data['recoveryDurationSeconds'],
      ])),
      improved: _text(_first([
        recoveryMap['improved'],
        recoveryMap['whatImproved'],
        edge['recoveryImproved'],
      ])),
      remainingConcern: _text(_first([
        recoveryMap['remainingConcern'],
        recoveryMap['remaining'],
        edge['recoveryRemainingConcern'],
      ])),
    );

    final prediction = PredictionInfo(
      state: _text(_first([
        predictionMap['state'],
        predictionMap['predictionState'],
        edge['predictionState'],
        data['predictionState'],
      ])),
      explanation: _text(_first([
        predictionMap['explanation'],
        predictionMap['predictionExplanation'],
        edge['predictionExplanation'],
        data['predictionExplanation'],
      ])),
      whatIfExplanation: _text(_first([
        predictionMap['whatIfExplanation'],
        predictionMap['whatIf'],
        edge['whatIfExplanation'],
        data['whatIfExplanation'],
      ])),
      confidence: _percent(_first([
        predictionMap['confidence'],
        edge['predictionConfidence'],
        data['predictionConfidence'],
      ])),
      minutesToWaterStressWarning: _minutes(_first([
        predictionMap['minutesToWaterStressWarning'],
        predictionMap['estimatedTimeToWaterStressWarningMinutes'],
        edge['estimatedTimeToWaterStressWarningMinutes'],
        data['estimatedTimeToWaterStressWarningMinutes'],
        edge['estimatedTimeToWaterStressWarning'],
        data['estimatedTimeToWaterStressWarning'],
      ])),
    );

    final baseline = PlantBaselineInfo(
      status: _text(_first([
        baselineMap['status'],
        baselineMap['adaptiveBaselineStatus'],
        edge['adaptiveBaselineStatus'],
        data['adaptiveBaselineStatus'],
      ])),
      ready: _bool(_first([
        baselineMap['ready'],
        baselineMap['baselineReady'],
        edge['baselineReady'],
        data['baselineReady'],
      ])),
      learnedNormal: _num(_first([
        baselineMap['learnedNormal'],
        baselineMap['learnedNormalValue'],
        baselineMap['baseline'],
        edge['learnedNormalValue'],
        data['learnedNormalValue'],
      ])),
      deviation: _num(_first([
        baselineMap['deviation'],
        baselineMap['baselineDeviation'],
        edge['baselineDeviation'],
        data['baselineDeviation'],
      ])),
      anomalyDetected: _bool(_first([
            baselineMap['anomalyDetected'],
            edge['anomalyDetected'],
            data['anomalyDetected'],
            edge['anomaly'],
            data['anomaly'],
          ])) ==
          true,
      changePointDetected: _bool(_first([
            baselineMap['changePointDetected'],
            edge['changePointDetected'],
            data['changePointDetected'],
          ])) ==
          true,
    );

    final stressEvidence = StressEvidence(
      water: _percent(_first([
        evidenceMap['waterStress'],
        evidenceMap['waterStressEvidence'],
        edge['waterStressEvidence'],
        data['waterStressEvidence'],
      ])),
      heat: _percent(_first([
        evidenceMap['heatStress'],
        evidenceMap['heatStressEvidence'],
        edge['heatStressEvidence'],
        data['heatStressEvidence'],
      ])),
      rootZone: _percent(_first([
        evidenceMap['rootZoneStress'],
        evidenceMap['rootZoneStressEvidence'],
        edge['rootZoneStressEvidence'],
        data['rootZoneStressEvidence'],
      ])),
      diseaseEnvironment: _percent(_first([
        evidenceMap['diseaseEnvironment'],
        evidenceMap['environmentalDiseaseRisk'],
        evidenceMap['environmentalDiseaseRiskEvidence'],
        edge['environmentalDiseaseRiskEvidence'],
        data['environmentalDiseaseRiskEvidence'],
        diseaseMap['score'],
      ])),
      sensorFault: _percent(_first([
        evidenceMap['sensorFault'],
        evidenceMap['sensorFaultEvidence'],
        edge['sensorFaultEvidence'],
        data['sensorFaultEvidence'],
      ])),
    );

    final derived = DerivedEnvironmentInfo(
      vpdKpa: _num(_first([
        derivedMap['vpd'],
        derivedMap['vpdKpa'],
        edge['vpd'],
        edge['vpdKpa'],
        data['vpd'],
        data['vpdKpa'],
      ])),
      airDryingDemand: _num(_first([
        derivedMap['airDryingDemand'],
        edge['airDryingDemand'],
        data['airDryingDemand'],
      ])),
    );

    final irrigation = IrrigationEvent(
      probable: _bool(_first([
            irrigationMap['probable'],
            irrigationMap['detected'],
            edge['probableIrrigationEvent'],
            data['probableIrrigationEvent'],
          ])) ==
          true,
      response: _text(_first([
        irrigationMap['response'],
        irrigationMap['irrigationResponse'],
        edge['irrigationResponse'],
        data['irrigationResponse'],
      ])),
      explanation: _text(_first([
        irrigationMap['explanation'],
        edge['irrigationExplanation'],
        data['irrigationExplanation'],
      ])),
      timestamp: _date(_first([
        irrigationMap['timestamp'],
        edge['irrigationTimestamp'],
        data['irrigationTimestamp'],
      ])),
    );

    final cropProfile = CropProfileInfo(
      profile: _text(_first([
        cropMap['profile'],
        cropMap['name'],
        edge['cropProfileName'],
        data['cropProfileName'],
        if (data['crop'] is String) data['crop'],
      ])),
      growthStage: _text(_first([
        cropMap['growthStage'],
        edge['growthStage'],
        data['growthStage'],
      ])),
      supportedProfiles: _strings(_first([
        cropMap['supportedProfiles'],
        edge['supportedCropProfiles'],
        data['supportedCropProfiles'],
      ])),
      supportedStages: _strings(_first([
        cropMap['supportedStages'],
        edge['supportedGrowthStages'],
        data['supportedGrowthStages'],
      ])),
      switchable: _bool(_first([
            cropMap['switchable'],
            cropMap['writable'],
            edge['cropProfileSwitchable'],
            data['cropProfileSwitchable'],
          ])) ==
          true,
    );

    // TinyML is deliberately conservative: modelLoaded is true only when the
    // firmware explicitly says so. Feature-vector availability never implies
    // that inference is running.
    final tinyMl = TinyMlInfo(
      status: _text(_first([
        tinyMlMap['status'],
        edge['tinyMlStatus'],
        data['tinyMlStatus'],
      ])),
      ready: _bool(_first([
            tinyMlMap['ready'],
            edge['tinyMlReady'],
            data['tinyMlReady'],
          ])) ==
          true,
      modelLoaded: _bool(_first([
            tinyMlMap['modelLoaded'],
            edge['tinyMlModelLoaded'],
            data['tinyMlModelLoaded'],
          ])) ==
          true,
      featureVectorAvailable: _bool(_first([
            tinyMlMap['featureVectorAvailable'],
            edge['tinyMlFeatureVectorAvailable'],
            data['tinyMlFeatureVectorAvailable'],
          ])) ==
          true,
    );

    final activeChannels = _strings(_first([
      edge['activeSensorChannels'],
      edge['activeChannels'],
      data['activeSensorChannels'],
      data['activeChannels'],
      root['activeChannels'],
    ]));
    final riskFlags = _strings(_first([
      edge['riskFlags'],
      data['riskFlags'],
      root['riskFlags'],
    ]));
    final degraded = _bool(_first([
          edge['degradedAnalysis'],
          edge['degradedMode'],
          data['degradedAnalysis'],
          data['degradedMode'],
          qualityMap['degraded'],
        ])) ==
        true;
    final degradedReason = _text(_first([
      edge['degradedReason'],
      data['degradedReason'],
      qualityMap['reason'],
      qualityMap['degradedReason'],
    ]));
    final generatedOnDevice = _bool(_first([
          decision['generatedOnDevice'],
          edge['generatedOnDevice'],
          data['generatedOnDevice'],
        ])) ==
        true;

    final capabilities = FirmwareCapabilities(
      edgeDecision: decision.isNotEmpty || recommendation != null || explanation != null,
      plantState: plantState != null,
      sensorConfidence: sensorConfidence.isNotEmpty,
      trends: trends.isNotEmpty,
      rootCause: rootCause.hasAny,
      recovery: recovery.hasData,
      prediction: prediction.hasData,
      baseline: baseline.hasData,
      derivedEnvironment: derived.hasData,
      stressEvidence: stressEvidence.hasData,
      sensorFaults: faults.isNotEmpty,
      irrigation: irrigation.hasData,
      events: events.isNotEmpty,
      tinyMl: tinyMl.hasData,
      cropProfile: cropProfile.profile != null || cropProfile.supportedProfiles.isNotEmpty,
      growthStage: cropProfile.growthStage != null || cropProfile.supportedStages.isNotEmpty,
    );

    return EdgeIntelligence(
      firmwareVersion: firmwareVersion,
      capabilities: capabilities,
      healthScore: healthScore,
      overallConfidence: confidence,
      plantState: plantState,
      urgency: urgency,
      farmerSummary: farmerSummary,
      recommendation: recommendation,
      decisionExplanation: explanation,
      generatedOnDevice: generatedOnDevice,
      degradedAnalysis: degraded,
      degradedReason: degradedReason,
      rootCause: rootCause,
      recovery: recovery,
      prediction: prediction,
      baseline: baseline,
      stressEvidence: stressEvidence,
      derivedEnvironment: derived,
      sensorConfidence: sensorConfidence,
      trends: trends,
      sensorFaults: faults,
      recentEvents: events,
      irrigation: irrigation,
      cropProfile: cropProfile,
      tinyMl: tinyMl,
      activeSensorChannels: activeChannels,
      riskFlags: riskFlags,
      diseaseRiskScore: _percent(_first([
        diseaseMap['score'],
        edge['diseaseRiskScore'],
        data['diseaseRiskPercent'],
        data['diseaseRisk'],
      ])),
      diseaseRiskLevel: _text(_first([
        diseaseMap['level'],
        edge['diseaseRiskLevel'],
        data['diseaseRiskLevel'],
      ])),
      confirmedDisease: _bool(diseaseMap['confirmedDisease']),
    );
  }
}

List<SensorConfidence> _parseConfidences(dynamic raw) {
  final result = <SensorConfidence>[];
  if (raw is Map) {
    for (final entry in raw.entries) {
      final channel = '${entry.key}';
      final details = _map(entry.value);
      result.add(SensorConfidence(
        channel: channel,
        percent: _percent(details.isEmpty ? entry.value : _first([
          details['confidence'],
          details['percent'],
          details['score'],
        ])),
        decayPercent: _percent(_first([
          details['decay'],
          details['confidenceDecay'],
          details['decayPercent'],
        ])),
        state: _text(_first([details['state'], details['quality']])),
        valid: _bool(details['valid']),
      ));
    }
  } else if (raw is List) {
    for (final item in raw) {
      final details = _map(item);
      final channel = _text(_first([details['channel'], details['sensor'], details['name']]));
      if (channel == null) continue;
      result.add(SensorConfidence(
        channel: channel,
        percent: _percent(_first([details['confidence'], details['percent'], details['score']])),
        decayPercent: _percent(_first([details['decay'], details['confidenceDecay']])),
        state: _text(_first([details['state'], details['quality']])),
        valid: _bool(details['valid']),
      ));
    }
  }
  return result;
}

List<SensorTrend> _parseTrends(dynamic raw) {
  final result = <SensorTrend>[];
  if (raw is Map) {
    for (final entry in raw.entries) {
      final details = _map(entry.value);
      result.add(SensorTrend(
        channel: '${entry.key}',
        state: _text(details.isEmpty ? entry.value : _first([details['state'], details['trend']])),
        slope: _num(_first([details['slope'], details['rate']])),
        variability: _num(_first([details['variability'], details['variance'], details['noise']])),
      ));
    }
  } else if (raw is List) {
    for (final item in raw) {
      final details = _map(item);
      final channel = _text(_first([details['channel'], details['sensor'], details['name']]));
      if (channel == null) continue;
      result.add(SensorTrend(
        channel: channel,
        state: _text(_first([details['state'], details['trend']])),
        slope: _num(_first([details['slope'], details['rate']])),
        variability: _num(_first([details['variability'], details['variance']])),
      ));
    }
  }
  return result;
}

List<SensorFaultInfo> _parseFaults(dynamic raw) {
  final result = <SensorFaultInfo>[];
  if (raw is Map) {
    final looksLikeSingle = raw.containsKey('channel') || raw.containsKey('sensor') || raw.containsKey('type');
    if (looksLikeSingle) {
      final details = Map<String, dynamic>.from(raw);
      result.add(_faultFromMap(details, fallbackChannel: 'system'));
    } else {
      for (final entry in raw.entries) {
        final details = _map(entry.value);
        if (details.isEmpty && entry.value == false) continue;
        result.add(_faultFromMap(details, fallbackChannel: '${entry.key}', fallbackType: _text(entry.value)));
      }
    }
  } else if (raw is List) {
    for (final item in raw) {
      final details = _map(item);
      if (details.isNotEmpty) result.add(_faultFromMap(details, fallbackChannel: 'system'));
    }
  }
  return result;
}

SensorFaultInfo _faultFromMap(Map<String, dynamic> details, {required String fallbackChannel, String? fallbackType}) {
  return SensorFaultInfo(
    channel: _text(_first([details['channel'], details['sensor'], details['name']])) ?? fallbackChannel,
    type: _text(_first([details['type'], details['faultType'], fallbackType])),
    explanation: _text(_first([details['explanation'], details['message'], details['reason']])),
    confidence: _percent(_first([details['confidence'], details['score']])),
    crossSensorConflict: _bool(_first([details['crossSensorConflict'], details['conflict']])) == true,
  );
}

List<PhytoEvent> _parseEvents(dynamic raw) {
  final result = <PhytoEvent>[];
  if (raw is! List) return result;
  for (final item in raw) {
    if (item is String) {
      final message = item.trim();
      if (message.isNotEmpty) result.add(PhytoEvent(type: 'event', message: message));
      continue;
    }
    final details = _map(item);
    if (details.isEmpty) continue;
    final message = _text(_first([details['message'], details['description'], details['event'], details['type']]));
    if (message == null) continue;
    result.add(PhytoEvent(
      timestamp: _date(_first([details['timestamp'], details['time']])),
      type: _text(_first([details['type'], details['eventType']])) ?? 'event',
      message: message,
      severity: _text(_first([details['severity'], details['level']])),
    ));
  }
  return result;
}

Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Map<String, dynamic> _firstMap(List<dynamic> values) {
  for (final value in values) {
    final mapped = _map(value);
    if (mapped.isNotEmpty) return mapped;
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

double? _minutes(dynamic value) {
  final direct = _num(value);
  if (direct != null) return direct < 0 ? null : direct;
  final text = _text(value)?.toLowerCase();
  if (text == null) return null;
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
  if (match == null) return null;
  final amount = double.tryParse(match.group(1)!);
  if (amount == null) return null;
  if (text.contains('hour')) return amount * 60;
  if (text.contains('sec')) return amount / 60;
  return amount;
}

String? _text(dynamic value) {
  if (value == null || value is Map || value is List) return null;
  final text = '$value'.trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

bool? _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _text(value)?.toLowerCase();
  if (text == 'true' || text == 'yes' || text == '1' || text == 'active') return true;
  if (text == 'false' || text == 'no' || text == '0' || text == 'inactive') return false;
  return null;
}

DateTime? _date(dynamic value) {
  final text = _text(value);
  return text == null ? null : DateTime.tryParse(text);
}

List<String> _strings(dynamic value) {
  if (value is List) {
    return value.map(_text).whereType<String>().toList(growable: false);
  }
  if (value is Map) {
    return value.entries.where((entry) => entry.value == true || entry.value is num).map((entry) => '${entry.key}').toList(growable: false);
  }
  final text = _text(value);
  if (text == null) return const [];
  if (text.contains(',')) {
    return text.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList(growable: false);
  }
  return <String>[text];
}
