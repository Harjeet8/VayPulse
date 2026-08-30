class FirmwareCapabilities {
  final bool edgeDecision;
  final bool plantState;
  final bool sensorConfidence;
  final bool trends;
  final bool rootCause;
  final bool recovery;
  final bool prediction;
  final bool compoundStress;
  final bool responseLag;
  final bool anomaly;
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
    this.compoundStress = false,
    this.responseLag = false,
    this.anomaly = false,
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
      compoundStress ||
      responseLag ||
      anomaly ||
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
  final double? ratePerMinute;
  final double? shortSlopePerMinute;
  final double? longSlopePerMinute;
  final double? confidence;

  const SensorTrend({
    required this.channel,
    this.state,
    this.slope,
    this.variability,
    this.ratePerMinute,
    this.shortSlopePerMinute,
    this.longSlopePerMinute,
    this.confidence,
  });
}

class RootCauseCandidate {
  final String? name;
  final double? confidence;
  final String? evidenceFor;
  final String? evidenceAgainst;

  const RootCauseCandidate({
    this.name,
    this.confidence,
    this.evidenceFor,
    this.evidenceAgainst,
  });

  bool get hasData =>
      name != null || confidence != null || evidenceFor != null || evidenceAgainst != null;
}

class RootCauseAnalysis {
  final String? primary;
  final String? secondary;
  final String? additionalContributor;
  final RootCauseCandidate? primaryCandidate;
  final RootCauseCandidate? secondaryCandidate;
  final List<RootCauseCandidate> ranked;

  const RootCauseAnalysis({
    this.primary,
    this.secondary,
    this.additionalContributor,
    this.primaryCandidate,
    this.secondaryCandidate,
    this.ranked = const [],
  });

  bool get hasAny =>
      primary != null ||
      secondary != null ||
      additionalContributor != null ||
      primaryCandidate?.hasData == true ||
      secondaryCandidate?.hasData == true ||
      ranked.isNotEmpty;
}

class RecoveryInfo {
  final bool active;
  final String? state;
  final double? confidence;
  final bool? environmentImproved;
  final bool? bioResponseDecreasing;
  final String? farmerResult;
  final String? quality;
  final double? durationSeconds;
  final String? improved;
  final String? remainingConcern;

  const RecoveryInfo({
    this.active = false,
    this.state,
    this.confidence,
    this.environmentImproved,
    this.bioResponseDecreasing,
    this.farmerResult,
    this.quality,
    this.durationSeconds,
    this.improved,
    this.remainingConcern,
  });

  bool get hasData =>
      active ||
      state != null ||
      confidence != null ||
      environmentImproved != null ||
      bioResponseDecreasing != null ||
      farmerResult != null ||
      quality != null ||
      improved != null ||
      remainingConcern != null;
}


class BioelectricIntelligence {
  final bool? available;
  final double? voltageMv;
  final double? baselineMv;
  final double? signedChangeMv;
  final double? deviationMv;
  final double? normalizedDeviation;
  final double? noiseMv;
  final double? signalQuality;
  final String? signalQualityState;
  final double? confidence;
  final String? trend;
  final double? stressScore;
  final String? stressState;
  final double? persistenceSeconds;
  final double? stressLoad;
  final String? stressLoadState;
  final bool? baselineReady;
  final int? baselineSamples;
  final int? baselineTarget;
  final double? zScore;
  final double? spanMv;
  final bool? includedInFusion;
  final String? interpretation;
  final bool? baselineLearningPaused;
  final double? rawAdc;
  final bool? corroborated;
  final List<String> corroboratedBy;
  final String? farmerResult;

  const BioelectricIntelligence({
    this.available,
    this.voltageMv,
    this.baselineMv,
    this.signedChangeMv,
    this.deviationMv,
    this.normalizedDeviation,
    this.noiseMv,
    this.signalQuality,
    this.signalQualityState,
    this.confidence,
    this.trend,
    this.stressScore,
    this.stressState,
    this.persistenceSeconds,
    this.stressLoad,
    this.stressLoadState,
    this.baselineReady,
    this.baselineSamples,
    this.baselineTarget,
    this.zScore,
    this.spanMv,
    this.includedInFusion,
    this.interpretation,
    this.baselineLearningPaused,
    this.rawAdc,
    this.corroborated,
    this.corroboratedBy = const [],
    this.farmerResult,
  });

  bool get hasData =>
      available != null ||
      voltageMv != null ||
      baselineMv != null ||
      stressScore != null ||
      stressState != null ||
      stressLoad != null ||
      stressLoadState != null ||
      baselineReady != null ||
      baselineSamples != null ||
      includedInFusion != null ||
      interpretation != null ||
      farmerResult != null;

  bool get learningBaseline =>
      baselineReady == false ||
      (baselineTarget != null &&
          baselineSamples != null &&
          baselineSamples! < baselineTarget!);

  /// True only when the firmware says the plant channel is unusable or its
  /// explicit state identifies a contact/noise/rail problem. A bad plant
  /// signal must never be converted into plant stress by Flutter.
  bool get excludedByFirmware {
    if (includedInFusion == false || available == false) return true;
    final value = '${signalQualityState ?? stressState ?? ''}'
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_');
    return value == 'NOISY' ||
        value == 'BAD_CONTACT' ||
        value == 'CONTACT_FAULT' ||
        value == 'SATURATED' ||
        value == 'HIGH_RAIL' ||
        value == 'LOW_RAIL' ||
        value == 'INVALID' ||
        value == 'UNAVAILABLE';
  }
}

class BioticStressInfo {
  final String? state;
  final double? evidenceScore;
  final double? confidence;
  final bool? unexplainedBioResponse;
  final bool? abioticCauseFound;
  final bool? diseaseConduciveSupport;
  final String? reason;
  final String? farmerResult;
  final String? recommendation;
  final bool? pestIdentified;
  final bool? infectionConfirmed;

  const BioticStressInfo({
    this.state,
    this.evidenceScore,
    this.confidence,
    this.unexplainedBioResponse,
    this.abioticCauseFound,
    this.diseaseConduciveSupport,
    this.reason,
    this.farmerResult,
    this.recommendation,
    this.pestIdentified,
    this.infectionConfirmed,
  });

  String? get normalizedState {
    final value = state?.trim().toUpperCase().replaceAll(' ', '_');
    return value == null || value.isEmpty ? null : value;
  }

  /// This is an ESP32-originated suspicion, never a Flutter diagnosis.
  /// `SUSPECTED` remains accepted for older firmware compatibility.
  bool get suspected =>
      (normalizedState == 'POSSIBLE_BIOTIC_STRESS' ||
          normalizedState == 'SUSPECTED') &&
      pestIdentified != true &&
      infectionConfirmed != true;

  bool get insufficientData => normalizedState == 'INSUFFICIENT_DATA';
  bool get lowConfidence => normalizedState == 'LOW_CONFIDENCE';
  bool get none => normalizedState == 'NONE';

  bool get hasData =>
      state != null ||
      evidenceScore != null ||
      confidence != null ||
      reason != null ||
      farmerResult != null ||
      recommendation != null;
}

class PredictionInfo {
  final bool? available;
  final String? state;
  final String? target;
  final String? explanation;
  final String? whatIfExplanation;
  final String? message;
  final double? confidence;
  final double? minutesToWarning;
  final double? minutesToWaterStressWarning;

  const PredictionInfo({
    this.available,
    this.state,
    this.target,
    this.explanation,
    this.whatIfExplanation,
    this.message,
    this.confidence,
    this.minutesToWarning,
    this.minutesToWaterStressWarning,
  });

  bool get hasData =>
      available != null ||
      state != null ||
      target != null ||
      explanation != null ||
      message != null ||
      minutesToWarning != null ||
      minutesToWaterStressWarning != null;
}

class CompoundStressInfo {
  final String? state;
  final double? severity;
  final double? waterEvidence;
  final double? heatEvidence;
  final double? rootEvidence;
  final double? atmosphericEvidence;

  const CompoundStressInfo({
    this.state,
    this.severity,
    this.waterEvidence,
    this.heatEvidence,
    this.rootEvidence,
    this.atmosphericEvidence,
  });

  bool get hasData =>
      state != null ||
      severity != null ||
      waterEvidence != null ||
      heatEvidence != null ||
      rootEvidence != null ||
      atmosphericEvidence != null;
}

class ResponseLagInfo {
  final double? environmentToBioResponseSeconds;
  final double? irrigationToBioDecreaseSeconds;
  final String? interpretation;

  const ResponseLagInfo({
    this.environmentToBioResponseSeconds,
    this.irrigationToBioDecreaseSeconds,
    this.interpretation,
  });

  bool get hasData =>
      environmentToBioResponseSeconds != null ||
      irrigationToBioDecreaseSeconds != null ||
      interpretation != null;
}

class AnomalyInfo {
  final String? state;
  final bool? detected;
  final bool? changePointDetected;
  final double? score;
  final double? confidence;
  final String? reason;

  const AnomalyInfo({
    this.state,
    this.detected,
    this.changePointDetected,
    this.score,
    this.confidence,
    this.reason,
  });

  bool get hasData =>
      state != null ||
      detected != null ||
      changePointDetected != null ||
      score != null ||
      confidence != null ||
      reason != null;
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
  final String? vpdState;
  final String? dryingDemandState;

  const DerivedEnvironmentInfo({
    this.vpdKpa,
    this.airDryingDemand,
    this.vpdState,
    this.dryingDemandState,
  });

  bool get hasData =>
      vpdKpa != null ||
      airDryingDemand != null ||
      vpdState != null ||
      dryingDemandState != null;
}

class WaterBalanceInfo {
  final String? state;
  final double? score;
  final String? explanation;

  const WaterBalanceInfo({this.state, this.score, this.explanation});

  bool get hasData => state != null || score != null || explanation != null;
}

class CameraHandoffInfo {
  final bool? recommended;
  final String? reason;
  final String? recommendation;
  final String? crop;

  const CameraHandoffInfo({
    this.recommended,
    this.reason,
    this.recommendation,
    this.crop,
  });

  bool get hasData =>
      recommended != null || reason != null || recommendation != null || crop != null;
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
  final String? regionProfile;
  final List<String> supportedProfiles;
  final List<String> supportedStages;
  final bool switchable;

  const CropProfileInfo({
    this.profile,
    this.growthStage,
    this.regionProfile,
    this.supportedProfiles = const [],
    this.supportedStages = const [],
    this.switchable = false,
  });

  bool get hasData =>
      profile != null ||
      growthStage != null ||
      regionProfile != null ||
      supportedProfiles.isNotEmpty ||
      supportedStages.isNotEmpty;
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
  final int? schemaVersion;
  final String? apiVersion;
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
  final List<String> degradedReasons;
  final String? analysisQuality;
  final RootCauseAnalysis rootCause;
  final RecoveryInfo recovery;
  final BioelectricIntelligence bioelectric;
  final BioticStressInfo bioticStress;
  final PredictionInfo prediction;
  final CompoundStressInfo compoundStress;
  final ResponseLagInfo responseLag;
  final AnomalyInfo anomaly;
  final PlantBaselineInfo baseline;
  final StressEvidence stressEvidence;
  final DerivedEnvironmentInfo derivedEnvironment;
  final WaterBalanceInfo waterBalance;
  final CameraHandoffInfo cameraHandoff;
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
    this.schemaVersion,
    this.apiVersion,
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
    this.degradedReasons = const [],
    this.analysisQuality,
    this.rootCause = const RootCauseAnalysis(),
    this.recovery = const RecoveryInfo(),
    this.bioelectric = const BioelectricIntelligence(),
    this.bioticStress = const BioticStressInfo(),
    this.prediction = const PredictionInfo(),
    this.compoundStress = const CompoundStressInfo(),
    this.responseLag = const ResponseLagInfo(),
    this.anomaly = const AnomalyInfo(),
    this.baseline = const PlantBaselineInfo(),
    this.stressEvidence = const StressEvidence(),
    this.derivedEnvironment = const DerivedEnvironmentInfo(),
    this.waterBalance = const WaterBalanceInfo(),
    this.cameraHandoff = const CameraHandoffInfo(),
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

  bool get hasAuthoritativeAnalysis =>
      capabilities.edgeDecision ||
      generatedOnDevice ||
      healthScore != null ||
      overallConfidence != null ||
      recommendation != null ||
      decisionExplanation != null ||
      plantState != null ||
      rootCause.hasAny ||
      bioelectric.farmerResult != null ||
      bioticStress.hasData ||
      cameraHandoff.hasData;

  /// Camera inspection is shown only when the ESP32 explicitly recommends it
  /// or reports its own POSSIBLE_BIOTIC_STRESS state.
  bool get cameraInspectionRecommended =>
      cameraHandoff.recommended == true || bioticStress.suspected;

  /// Versionless legacy packets and schemas 1-8 are supported. Newer schemas
  /// remain visible in diagnostics but are not silently treated as compatible.
  bool get firmwareCompatible =>
      schemaVersion == null || (schemaVersion! >= 1 && schemaVersion! <= 8);

  String? get compatibilityIssue =>
      firmwareCompatible ? null : 'Firmware compatibility issue';

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
    final bioelectricMap = _firstMap([
      edge['bioelectric'],
      data['bioelectric'],
      edge['bio'],
      data['bio'],
      plantHealth['bioelectric'],
      _map(data['readings'])['bioelectric'],
    ]);
    final bioticStressMap = _firstMap([
      edge['bioticStress'],
      edge['bioticAnalysis'],
      data['bioticStress'],
      data['bioticAnalysis'],
      plantHealth['bioticStress'],
      plantHealth['bioticAnalysis'],
    ]);
    final predictionMap = _firstMap([
      edge['prediction'],
      data['prediction'],
      plantHealth['prediction'],
      edge['forecast'],
      data['forecast'],
    ]);
    final compoundStressMap = _firstMap([
      edge['compoundStress'],
      data['compoundStress'],
      plantHealth['compoundStress'],
    ]);
    final responseLagMap = _firstMap([
      edge['responseLag'],
      data['responseLag'],
      plantHealth['responseLag'],
    ]);
    final anomalyMap = _firstMap([
      edge['anomaly'],
      data['anomaly'],
      plantHealth['anomaly'],
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
    final waterBalanceMap = _firstMap([
      edge['waterBalance'],
      data['waterBalance'],
      plantHealth['waterBalance'],
    ]);
    final cameraHandoffMap = _firstMap([
      edge['cameraHandoff'],
      data['cameraHandoff'],
      plantHealth['cameraHandoff'],
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
      edge['healthIndex'],
      edge['health'],
      data['healthScore'],
      data['healthIndex'],
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
      edge['farmerAction'],
      edge['primaryAction'],
      data['recommendation'],
      data['farmerAction'],
      data['primaryAction'],
      decision['action'],
    ]));
    final explanation = _text(_first([
      edge['decisionExplanation'],
      edge['because'],
      data['decisionExplanation'],
      data['because'],
      data['explanation'],
      decision['because'],
    ]));
    final farmerSummary = _text(_first([
      edge['farmerSummary'],
      data['farmerSummary'],
      decision['farmerFriendly'],
      decision['finding'],
      edge['mainFinding'],
      data['mainFinding'],
      data['primaryFinding'],
      bioelectricMap['farmerResult'],
      bioticStressMap['farmerResult'],
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

    final primaryCandidate = _rootCauseCandidate(
      _first([rootCauseMap['primary'], rootCauseMap['primaryCause']]),
    );
    final secondaryCandidate = _rootCauseCandidate(
      _first([rootCauseMap['secondary'], rootCauseMap['secondaryCause']]),
    );
    final rankedCandidates = _parseRootCauseCandidates(_first([
      rootCauseMap['ranked'],
      rootCauseMap['causes'],
      edge['rootCauses'],
      data['rootCauses'],
    ]));
    final rootCause = RootCauseAnalysis(
      primary: primaryCandidate?.name ?? _text(_first([
        rootCauseMap['primary'],
        rootCauseMap['primaryCause'],
        edge['primaryCause'],
        data['primaryCause'],
        data['rootCausePrimary'],
        data['primaryFinding'],
      ])),
      secondary: secondaryCandidate?.name ?? _text(_first([
        rootCauseMap['secondary'],
        rootCauseMap['secondaryCause'],
        edge['secondaryCause'],
        data['secondaryCause'],
        data['secondaryCause1'],
        data['rootCauseSecondary'],
      ])),
      additionalContributor: _text(_first([
        rootCauseMap['additionalContributor'],
        rootCauseMap['contributor'],
        edge['additionalContributor'],
        data['additionalContributor'],
        data['secondaryCause2'],
      ])),
      primaryCandidate: primaryCandidate,
      secondaryCandidate: secondaryCandidate,
      ranked: rankedCandidates,
    );

    final recoveryState = _text(_first([
      recoveryMap['state'],
      edge['recoveryState'],
      data['recoveryState'],
    ]));
    final recovery = RecoveryInfo(
      active: _bool(_first([
            recoveryMap['active'],
            edge['recoveryActive'],
            data['recoveryActive'],
          ])) ==
          true ||
          (plantState?.toUpperCase() == 'RECOVERING') ||
          (recoveryState?.toUpperCase() == 'RECOVERING'),
      state: recoveryState,
      confidence: _percent(_first([
        recoveryMap['confidence'],
        edge['recoveryConfidence'],
        data['recoveryConfidence'],
      ])),
      environmentImproved: _bool(_first([
        recoveryMap['environmentImproved'],
        edge['environmentImproved'],
        data['environmentImproved'],
      ])),
      bioResponseDecreasing: _bool(_first([
        recoveryMap['bioResponseDecreasing'],
        edge['bioResponseDecreasing'],
        data['bioResponseDecreasing'],
      ])),
      farmerResult: _text(_first([
        recoveryMap['farmerResult'],
        edge['recoveryFarmerResult'],
        data['recoveryFarmerResult'],
      ])),
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


    final bioelectric = BioelectricIntelligence(
      available: _bool(_first([
        bioelectricMap['available'],
        edge['bioAvailable'],
        data['bioAvailable'],
      ])),
      voltageMv: _num(_first([
        bioelectricMap['voltageMv'],
        bioelectricMap['plantVoltageMv'],
        edge['bioVoltageMv'],
        data['bioVoltageMv'],
        data['plantVoltageMv'],
      ])),
      baselineMv: _num(_first([
        bioelectricMap['baselineMv'],
        edge['bioBaselineMv'],
        data['bioBaselineMv'],
      ])),
      signedChangeMv: _num(_first([
        bioelectricMap['signedChangeMv'],
        bioelectricMap['signedChange'],
      ])),
      deviationMv: _num(_first([
        bioelectricMap['deviationMv'],
        edge['bioDeviationMv'],
        data['bioDeviationMv'],
      ])),
      normalizedDeviation: _num(_first([
        bioelectricMap['normalizedDeviation'],
        bioelectricMap['deviationPercent'],
        bioelectricMap['normalizedDeviationPercent'],
        edge['bioDeviationPercent'],
        data['bioDeviationPercent'],
        data['bioelectricDeviationPercent'],
      ])),
      noiseMv: _num(_first([
        bioelectricMap['noiseMv'],
        bioelectricMap['noise'],
        edge['bioNoiseMv'],
        data['bioNoiseMv'],
      ])),
      signalQuality: _percent(_first([
        bioelectricMap['signalQuality'],
        bioelectricMap['signalQualityPercent'],
        edge['bioSignalQuality'],
        data['bioSignalQuality'],
      ])),
      signalQualityState: _text(_first([
        bioelectricMap['signalQualityState'],
        bioelectricMap['qualityState'],
        edge['bioSignalQualityState'],
        data['bioSignalQualityState'],
      ])),
      confidence: _percent(_first([
        bioelectricMap['confidence'],
        edge['bioConfidence'],
        data['bioConfidence'],
      ])),
      trend: _text(_first([
        bioelectricMap['trend'],
        edge['bioTrend'],
        data['bioTrend'],
      ])),
      stressScore: _percent(_first([
        bioelectricMap['stressScore'],
        edge['bioStressScore'],
        data['bioStressScore'],
      ])),
      stressState: _text(_first([
        bioelectricMap['stressState'],
        bioelectricMap['state'],
        edge['bioState'],
        data['bioState'],
      ])),
      persistenceSeconds: _num(_first([
        bioelectricMap['persistenceSeconds'],
        bioelectricMap['persistentSeconds'],
      ])),
      stressLoad: _num(_first([
        bioelectricMap['stressLoad'],
        edge['bioStressLoad'],
        data['bioStressLoad'],
      ])),
      stressLoadState: _text(_first([
        bioelectricMap['stressLoadState'],
        edge['bioStressLoadState'],
        data['bioStressLoadState'],
      ])),
      baselineReady: _bool(_first([
        bioelectricMap['baselineReady'],
        edge['bioBaselineReady'],
        data['bioBaselineReady'],
        data['baselineReady'],
      ])),
      baselineSamples: _int(_first([
        bioelectricMap['baselineSamples'],
        bioelectricMap['samples'],
        edge['bioBaselineSamples'],
        data['bioBaselineSamples'],
      ])),
      baselineTarget: _int(_first([
        bioelectricMap['baselineTarget'],
        bioelectricMap['targetSamples'],
        edge['bioBaselineTarget'],
        data['bioBaselineTarget'],
      ])),
      zScore: _num(_first([
        bioelectricMap['zScore'],
        bioelectricMap['zscore'],
        edge['bioZScore'],
        data['bioZScore'],
      ])),
      spanMv: _num(_first([
        bioelectricMap['spanMv'],
        edge['bioSpanMv'],
        data['bioSpanMv'],
      ])),
      includedInFusion: _bool(_first([
        bioelectricMap['includedInFusion'],
        bioelectricMap['usedInFusion'],
        edge['bioIncludedInFusion'],
        data['bioIncludedInFusion'],
      ])),
      interpretation: _text(_first([
        bioelectricMap['interpretation'],
        edge['bioInterpretation'],
        data['bioInterpretation'],
      ])),
      baselineLearningPaused: _bool(_first([
        bioelectricMap['baselineLearningPaused'],
        bioelectricMap['learningPaused'],
      ])),
      rawAdc: _num(_first([
        bioelectricMap['rawADC'],
        bioelectricMap['rawAdc'],
        bioelectricMap['adcRaw'],
        bioelectricMap['raw'],
      ])),
      corroborated: _bool(bioelectricMap['corroborated']),
      corroboratedBy: _strings(bioelectricMap['corroboratedBy']),
      farmerResult: _text(_first([
        bioelectricMap['farmerResult'],
        edge['bioFarmerResult'],
        data['bioFarmerResult'],
      ])),
    );

    final bioticStress = BioticStressInfo(
      state: _text(_first([
        bioticStressMap['state'],
        edge['bioticState'],
        data['bioticState'],
        plantHealth['bioticState'],
      ])),
      evidenceScore: _percent(_first([
        bioticStressMap['evidenceScore'],
        bioticStressMap['evidence'],
        edge['bioticEvidence'],
        data['bioticEvidence'],
        plantHealth['bioticEvidence'],
      ])),
      confidence: _percent(_first([
        bioticStressMap['confidence'],
        edge['bioticConfidence'],
        data['bioticConfidence'],
        plantHealth['bioticConfidence'],
      ])),
      unexplainedBioResponse: _bool(_first([
        bioticStressMap['unexplainedBioResponse'],
        edge['unexplainedBioResponse'],
        data['unexplainedBioResponse'],
      ])),
      abioticCauseFound: _bool(_first([
        bioticStressMap['abioticCauseFound'],
        edge['abioticCauseFound'],
        data['abioticCauseFound'],
      ])),
      diseaseConduciveSupport: _bool(_first([
        bioticStressMap['diseaseConduciveSupport'],
        edge['diseaseConduciveSupport'],
        data['diseaseConduciveSupport'],
      ])),
      reason: _text(_first([
        bioticStressMap['reason'],
        edge['bioticReason'],
        data['bioticReason'],
        plantHealth['bioticReason'],
      ])),
      farmerResult: _text(bioticStressMap['farmerResult']),
      recommendation: _text(_first([
        bioticStressMap['recommendation'],
        edge['bioticRecommendation'],
        data['bioticRecommendation'],
        plantHealth['bioticRecommendation'],
      ])),
      pestIdentified: _bool(bioticStressMap['pestIdentified']),
      infectionConfirmed: _bool(bioticStressMap['infectionConfirmed']),
    );

    final prediction = PredictionInfo(
      available: _bool(predictionMap['available']),
      state: _text(_first([
        predictionMap['state'],
        predictionMap['predictionState'],
        edge['predictionState'],
        data['predictionState'],
      ])),
      target: _text(predictionMap['target']),
      explanation: _text(_first([
        predictionMap['explanation'],
        predictionMap['message'],
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
      message: _text(predictionMap['message']),
      confidence: _percent(_first([
        predictionMap['confidence'],
        edge['predictionConfidence'],
        data['predictionConfidence'],
      ])),
      minutesToWarning: _minutes(predictionMap['minutesToWarning']),
      minutesToWaterStressWarning: _minutes(_first([
        predictionMap['minutesToWaterStressWarning'],
        predictionMap['estimatedTimeToWaterStressWarningMinutes'],
        edge['estimatedTimeToWaterStressWarningMinutes'],
        data['estimatedTimeToWaterStressWarningMinutes'],
        edge['estimatedTimeToWaterStressWarning'],
        data['estimatedTimeToWaterStressWarning'],
      ])),
    );

    final compoundStress = CompoundStressInfo(
      state: _text(compoundStressMap['state']),
      severity: _percent(compoundStressMap['severity']),
      waterEvidence: _percent(compoundStressMap['waterEvidence']),
      heatEvidence: _percent(compoundStressMap['heatEvidence']),
      rootEvidence: _percent(compoundStressMap['rootEvidence']),
      atmosphericEvidence: _percent(compoundStressMap['atmosphericEvidence']),
    );

    final responseLag = ResponseLagInfo(
      environmentToBioResponseSeconds:
          _num(responseLagMap['environmentToBioResponseSeconds']),
      irrigationToBioDecreaseSeconds:
          _num(responseLagMap['irrigationToBioDecreaseSeconds']),
      interpretation: _text(responseLagMap['interpretation']),
    );

    final anomaly = AnomalyInfo(
      state: _text(_first([anomalyMap['state'], anomalyMap['status']])),
      detected: _bool(_first([anomalyMap['detected'], anomalyMap['anomalyDetected']])),
      changePointDetected: _bool(anomalyMap['changePointDetected']),
      score: _percent(_first([anomalyMap['score'], anomalyMap['anomalyScore']])),
      confidence: _percent(anomalyMap['confidence']),
      reason: _text(_first([anomalyMap['reason'], anomalyMap['explanation']])),
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
      vpdState: _text(_first([
        derivedMap['vpdState'],
        edge['vpdState'],
        data['vpdState'],
      ])),
      dryingDemandState: _text(_first([
        derivedMap['airDryingDemandState'],
        derivedMap['dryingDemandState'],
        edge['airDryingDemandState'],
        data['airDryingDemandState'],
      ])),
    );

    final waterBalance = WaterBalanceInfo(
      state: _text(_first([
        waterBalanceMap['state'],
        waterBalanceMap['status'],
        edge['waterBalanceState'],
        data['waterBalanceState'],
      ])),
      score: _percent(_first([
        waterBalanceMap['score'],
        waterBalanceMap['index'],
        edge['waterBalanceScore'],
        data['waterBalanceScore'],
      ])),
      explanation: _text(_first([
        waterBalanceMap['explanation'],
        waterBalanceMap['farmerResult'],
        edge['waterBalanceExplanation'],
        data['waterBalanceExplanation'],
      ])),
    );

    final cameraHandoff = CameraHandoffInfo(
      recommended: _bool(_first([
        cameraHandoffMap['recommended'],
        cameraHandoffMap['cameraScanRecommended'],
        edge['cameraScanRecommended'],
        data['cameraScanRecommended'],
        plantHealth['cameraScanRecommended'],
      ])),
      reason: _text(_first([
        cameraHandoffMap['reason'],
        edge['cameraScanReason'],
        data['cameraScanReason'],
      ])),
      recommendation: _text(_first([
        cameraHandoffMap['recommendation'],
        cameraHandoffMap['action'],
        edge['cameraRecommendation'],
        data['cameraRecommendation'],
      ])),
      crop: _text(_first([
        cameraHandoffMap['crop'],
        edge['cameraCrop'],
        data['cameraCrop'],
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
      regionProfile: _text(_first([
        cropMap['regionProfile'],
        cropMap['region'],
        edge['regionProfile'],
        data['regionProfile'],
        data['region'],
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
    final degradedReasons = _strings(_first([
      qualityMap['degradedReasons'],
      qualityMap['reasons'],
      edge['degradedReasons'],
      data['degradedReasons'],
      degradedReason,
    ]));
    final analysisQuality = _text(_first([
      qualityMap['label'],
      qualityMap['level'],
      qualityMap['state'],
      if (data['analysisQuality'] is! Map) data['analysisQuality'],
      if (edge['analysisQuality'] is! Map) edge['analysisQuality'],
    ]));
    final generatedOnDevice = _bool(_first([
          decision['generatedOnDevice'],
          edge['generatedOnDevice'],
          data['generatedOnDevice'],
        ])) ==
        true;

    final capabilities = FirmwareCapabilities(
      edgeDecision: decision.isNotEmpty ||
          recommendation != null ||
          explanation != null ||
          rootCause.hasAny ||
          bioelectric.farmerResult != null ||
          bioticStress.hasData,
      plantState: plantState != null,
      sensorConfidence: sensorConfidence.isNotEmpty,
      trends: trends.isNotEmpty,
      rootCause: rootCause.hasAny,
      recovery: recovery.hasData,
      prediction: prediction.hasData,
      compoundStress: compoundStress.hasData,
      responseLag: responseLag.hasData,
      anomaly: anomaly.hasData,
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
      schemaVersion: _int(_first([
        data['schemaVersion'],
        data['apiSchemaVersion'],
        root['schemaVersion'],
        root['apiSchemaVersion'],
      ])),
      apiVersion: _text(_first([
        data['apiVersion'],
        _map(data['api'])['version'],
        root['apiVersion'],
        _map(root['api'])['version'],
      ])),
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
      degradedReasons: degradedReasons,
      analysisQuality: analysisQuality,
      rootCause: rootCause,
      recovery: recovery,
      bioelectric: bioelectric,
      bioticStress: bioticStress,
      prediction: prediction,
      compoundStress: compoundStress,
      responseLag: responseLag,
      anomaly: anomaly,
      baseline: baseline,
      stressEvidence: stressEvidence,
      derivedEnvironment: derived,
      waterBalance: waterBalance,
      cameraHandoff: cameraHandoff,
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

RootCauseCandidate? _rootCauseCandidate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String || raw is num) {
    final name = _text(raw);
    return name == null ? null : RootCauseCandidate(name: name);
  }
  final map = _map(raw);
  if (map.isEmpty) return null;
  final candidate = RootCauseCandidate(
    name: _text(_first([map['name'], map['cause'], map['label'], map['result']])),
    confidence: _percent(_first([map['confidence'], map['score'], map['probability']])),
    evidenceFor: _text(_first([map['evidenceFor'], map['for'], map['supportingEvidence']])),
    evidenceAgainst:
        _text(_first([map['evidenceAgainst'], map['against'], map['counterEvidence']])),
  );
  return candidate.hasData ? candidate : null;
}

List<RootCauseCandidate> _parseRootCauseCandidates(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map(_rootCauseCandidate)
      .whereType<RootCauseCandidate>()
      .toList(growable: false);
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
        slope: _num(_first([details['slope'], details['rate'], details['ratePerMinute']])),
        variability: _num(_first([details['variability'], details['variance'], details['noise']])),
        ratePerMinute: _num(details['ratePerMinute']),
        shortSlopePerMinute: _num(details['shortSlopePerMinute']),
        longSlopePerMinute: _num(details['longSlopePerMinute']),
        confidence: _percent(details['confidence']),
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
        slope: _num(_first([details['slope'], details['rate'], details['ratePerMinute']])),
        variability: _num(_first([details['variability'], details['variance']])),
        ratePerMinute: _num(details['ratePerMinute']),
        shortSlopePerMinute: _num(details['shortSlopePerMinute']),
        longSlopePerMinute: _num(details['longSlopePerMinute']),
        confidence: _percent(details['confidence']),
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

int? _int(dynamic value) {
  if (value == null || value is bool) return null;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
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
