import 'dart:math' as math;

import '../models/edge_intelligence.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_reading.dart';
import 'demo_mode.dart';

/// Competition-grade intelligence for Simulation Mode.
///
/// This model exists only for the clearly-labelled simulator. It never runs in
/// ESP32 mode and never overrides a live firmware decision.
class SimulationIntelligenceV2 {
  const SimulationIntelligenceV2._();

  static EdgeIntelligence build({
    required SensorReading reading,
    required List<SensorReading> history,
    required DemoMode mode,
    required String crop,
    required String growthStage,
  }) {
    final previous = history.length >= 2 ? history[history.length - 2] : null;
    final vpd = _vpd(reading.temperature, reading.humidity);
    final bioStress = (100 - (reading.bioelectricStability ?? reading.plantSignal))
        .clamp(0.0, 100.0)
        .toDouble();
    final sensorFault = mode == DemoMode.sensorFault;
    final baselineLearning = mode == DemoMode.baselineLearning;
    final recovering = mode == DemoMode.recovery;
    final bioticRisk = mode == DemoMode.bioticRisk;
    final severe = mode == DemoMode.critical;

    final soilTrend = _trend(previous?.soilMoisture, reading.soilMoisture);
    final airTrend = _trend(previous?.temperature, reading.temperature);
    final humidityTrend = _trend(previous?.humidity, reading.humidity);
    final bioTrend = recovering
        ? 'FALLING'
        : bioStress >= 60
            ? 'RISING_FAST'
            : bioStress >= 28
                ? 'RISING'
                : 'STABLE';

    final analysis = _scenarioAnalysis(
      mode: mode,
      reading: reading,
      vpd: vpd,
      bioStress: bioStress,
    );

    final baselineSamples = baselineLearning ? 28 : 60;
    final baselineReady = !baselineLearning && !sensorFault;
    final baselinePaused = !baselineLearning && !sensorFault && bioStress >= 35;
    final normalizedDeviation = reading.bioBaselineMv == null ||
            reading.bioBaselineMv == 0 ||
            reading.bioDeviationMv == null
        ? null
        : reading.bioDeviationMv! / reading.bioBaselineMv! * 100;

    final sensorConfidences = <SensorConfidence>[
      SensorConfidence(
        channel: 'airTemperature',
        percent: reading.temperatureAvailable ? 98 : 0,
        decayPercent: 0,
        state: reading.temperatureAvailable ? 'GOOD' : 'UNAVAILABLE',
        valid: reading.temperatureAvailable,
      ),
      SensorConfidence(
        channel: 'humidity',
        percent: reading.humidityAvailable ? 97 : 0,
        decayPercent: 0,
        state: reading.humidityAvailable ? 'GOOD' : 'UNAVAILABLE',
        valid: reading.humidityAvailable,
      ),
      SensorConfidence(
        channel: 'light',
        percent: reading.lightAvailable ? 95 : 0,
        decayPercent: 0,
        state: reading.lightAvailable ? 'GOOD' : 'UNAVAILABLE',
        valid: reading.lightAvailable,
      ),
      SensorConfidence(
        channel: 'soilMoisture',
        percent: reading.soilMoistureAvailable ? 94 : 0,
        decayPercent: sensorFault ? 65 : 0,
        state: reading.soilMoistureAvailable ? 'GOOD' : 'UNAVAILABLE',
        valid: reading.soilMoistureAvailable,
      ),
      SensorConfidence(
        channel: 'rootTemperature',
        percent: reading.soilTemperatureAvailable ? 96 : 0,
        decayPercent: sensorFault ? 65 : 0,
        state: reading.soilTemperatureAvailable ? 'GOOD' : 'UNAVAILABLE',
        valid: reading.soilTemperatureAvailable,
      ),
      SensorConfidence(
        channel: 'leafWetness',
        percent: reading.leafWetnessAvailable ? 92 : 0,
        decayPercent: sensorFault ? 65 : 0,
        state: reading.leafWetnessAvailable ? 'GOOD' : 'UNAVAILABLE',
        valid: reading.leafWetnessAvailable,
      ),
      SensorConfidence(
        channel: 'bioelectric',
        percent: reading.plantSignalAvailable ? reading.bioSignalQuality : 0,
        decayPercent: sensorFault ? 80 : 0,
        state: sensorFault
            ? 'NOISY'
            : baselineLearning
                ? 'LEARNING'
                : 'GOOD',
        valid: reading.plantSignalAvailable && !sensorFault,
      ),
    ];

    final validConf = sensorConfidences
        .where((item) => item.valid == true && item.percent != null)
        .map((item) => item.percent!)
        .toList(growable: false);
    final sensorReliability = validConf.isEmpty
        ? 0.0
        : validConf.reduce((a, b) => a + b) / validConf.length;
    final overallConfidence = sensorFault
        ? 58.0
        : baselineLearning
            ? math.min(82.0, sensorReliability * 0.86)
            : math.min(96.0, sensorReliability * 0.94 + 4);

    final rootCause = RootCauseAnalysis(
      primary: analysis.primary,
      secondary: analysis.secondary,
      additionalContributor: analysis.additional,
      primaryCandidate: RootCauseCandidate(
        name: analysis.primary,
        confidence: analysis.primaryConfidence,
        evidenceFor: analysis.evidenceFor,
        evidenceAgainst: analysis.evidenceAgainst,
      ),
      secondaryCandidate: analysis.secondary == null
          ? null
          : RootCauseCandidate(
              name: analysis.secondary,
              confidence: analysis.secondaryConfidence,
              evidenceFor: analysis.secondaryEvidence,
            ),
      ranked: analysis.ranked,
    );

    final recovery = recovering
        ? const RecoveryInfo(
            active: true,
            state: 'RECOVERING',
            confidence: 88,
            environmentImproved: true,
            bioResponseDecreasing: true,
            farmerResult: 'The plant response is easing as conditions improve.',
            quality: 'GOOD',
            durationSeconds: 150,
            improved: 'Atmospheric demand and plant electrical response are decreasing.',
            remainingConcern: 'Continue monitoring until the plant signal settles near baseline.',
          )
        : const RecoveryInfo(active: false);

    final diseaseRisk = reading.diseaseRisk;
    final biotic = bioticRisk
        ? BioticStressInfo(
            state: 'POSSIBLE_BIOTIC_STRESS',
            evidenceScore: diseaseRisk ?? 68,
            confidence: 72,
            unexplainedBioResponse: bioStress >= 28,
            abioticCauseFound: false,
            diseaseConduciveSupport: true,
            reason:
                'Persistent leaf wetness and high humidity create a disease-conducive environment. This is not a confirmed infection.',
            farmerResult: 'Possible biotic stress — inspect the plant visually.',
            recommendation:
                'Inspect leaves and stems for symptoms and improve airflow where practical.',
            pestIdentified: false,
            infectionConfirmed: false,
          )
        : const BioticStressInfo(
            state: 'NONE',
            pestIdentified: false,
            infectionConfirmed: false,
          );

    final prediction = PredictionInfo(
      available: !sensorFault,
      state: recovering
          ? 'RECOVERY_LIKELY'
          : severe || mode == DemoMode.dry || mode == DemoMode.atmosphericDrying
              ? 'STRESS_LIKELY_TO_INCREASE'
              : mode == DemoMode.heatStress || mode == DemoMode.bioResponse
                  ? 'WATCH_TREND'
                  : 'STABLE',
      target: 'plantStressDirection',
      explanation: recovering
          ? 'Recent readings are moving toward a lower-stress state.'
          : severe || mode == DemoMode.dry || mode == DemoMode.atmosphericDrying
              ? 'Recent environmental and plant-response trends are moving in an unfavorable direction.'
              : 'Recent readings do not show a strong worsening direction.',
      whatIfExplanation: analysis.whatIf,
      confidence: sensorFault ? null : math.min(92.0, overallConfidence),
      minutesToWarning: severe ? 5 : mode == DemoMode.dry ? 18 : null,
      minutesToWaterStressWarning: mode == DemoMode.dry ? 18 : null,
    );

    final events = _eventsFor(mode, reading.timestamp, analysis.primary);
    final stressEvidence = StressEvidence(
      water: _waterEvidence(reading.soilMoisture),
      heat: _heatEvidence(reading.temperature),
      rootZone: reading.soilTemperature == null
          ? 0
          : _heatEvidence(reading.soilTemperature!),
      diseaseEnvironment: diseaseRisk ?? 0,
      sensorFault: sensorFault ? 90 : 0,
    );

    return EdgeIntelligence(
      firmwareVersion: 'simulation-intelligence-v2',
      schemaVersion: 8,
      apiVersion: 'simulation-v2',
      capabilities: const FirmwareCapabilities(
        edgeDecision: true,
        plantState: true,
        sensorConfidence: true,
        trends: true,
        rootCause: true,
        recovery: true,
        prediction: true,
        compoundStress: true,
        responseLag: true,
        anomaly: true,
        baseline: true,
        derivedEnvironment: true,
        stressEvidence: true,
        sensorFaults: true,
        irrigation: true,
        events: true,
        tinyMl: false,
        cropProfile: true,
        growthStage: true,
      ),
      healthScore: reading.healthScore,
      overallConfidence: overallConfidence,
      plantState: recovering ? 'RECOVERING' : _stateFor(reading.healthScore),
      urgency: severe
          ? 'HIGH'
          : reading.healthScore < 65
              ? 'WATCH'
              : 'LOW',
      farmerSummary: analysis.primary ?? 'Conditions are currently acceptable.',
      recommendation: analysis.action,
      decisionExplanation: analysis.explanation,
      generatedOnDevice: false,
      degradedAnalysis: sensorFault,
      degradedReason: sensorFault
          ? 'Simulation scenario intentionally removes selected sensor channels.'
          : null,
      degradedReasons: sensorFault
          ? const ['Soil, root, leaf and bioelectric channels are intentionally unavailable.']
          : const [],
      analysisQuality: sensorFault
          ? 'DEGRADED'
          : baselineLearning
              ? 'LEARNING'
              : 'GOOD',
      rootCause: rootCause,
      recovery: recovery,
      bioelectric: BioelectricIntelligence(
        available: !sensorFault,
        voltageMv: reading.plantVoltageMv,
        baselineMv: reading.bioBaselineMv,
        signedChangeMv: reading.bioDeviationMv,
        deviationMv: reading.bioDeviationMv?.abs(),
        normalizedDeviation: normalizedDeviation,
        noiseMv: reading.bioNoiseMv,
        signalQuality: reading.bioSignalQuality,
        signalQualityState: sensorFault
            ? 'SIGNAL_NOISY'
            : baselineLearning
                ? 'LEARNING_BASELINE'
                : 'GOOD',
        confidence: sensorFault
            ? 18
            : baselineLearning
                ? 64
                : 92,
        trend: bioTrend,
        stressScore: baselineLearning ? null : bioStress,
        stressState: baselineLearning
            ? 'LEARNING_BASELINE'
            : _bioState(bioStress, recovering),
        persistenceSeconds: baselineLearning ? 0 : (bioStress >= 25 ? 54 : 0),
        stressLoad: baselineLearning ? null : bioStress * 0.78,
        stressLoadState: baselineLearning
            ? 'LEARNING'
            : bioStress >= 55
                ? 'PERSISTENT'
                : bioStress >= 25
                    ? 'BUILDING'
                    : 'LOW',
        baselineReady: baselineReady,
        baselineSamples: baselineSamples,
        baselineTarget: 60,
        zScore: baselineLearning || reading.bioNoiseMv == null || reading.bioNoiseMv == 0
            ? null
            : (reading.bioDeviationMv ?? 0) / math.max(1.0, reading.bioNoiseMv!),
        spanMv: reading.bioNoiseMv == null ? null : reading.bioNoiseMv! * 6,
        includedInFusion: !sensorFault && baselineReady,
        interpretation: baselineLearning
            ? 'Learning this plant\'s normal electrical signature.'
            : _bioState(bioStress, recovering),
        baselineLearningPaused: baselinePaused,
        corroborated: !sensorFault && !baselineLearning && bioStress >= 25,
        corroboratedBy: <String>[
          if (reading.soilMoisture < 35) 'soilMoisture',
          if (vpd >= 1.5) 'vpd',
          if (reading.temperature >= 32) 'airTemperature',
          if ((reading.leafWetness ?? 0) >= 60) 'leafWetness',
        ],
        farmerResult: baselineLearning
            ? 'Learning baseline'
            : recovering
                ? 'Plant response is easing'
                : _bioState(bioStress, false),
      ),
      bioticStress: biotic,
      prediction: prediction,
      compoundStress: CompoundStressInfo(
        state: severe
            ? 'COMPOUND_STRESS'
            : mode == DemoMode.atmosphericDrying
                ? 'ATMOSPHERIC_DOMINANT'
                : 'NONE',
        severity: severe ? 91 : math.max(_waterEvidence(reading.soilMoisture), _heatEvidence(reading.temperature)),
        waterEvidence: _waterEvidence(reading.soilMoisture),
        heatEvidence: _heatEvidence(reading.temperature),
        rootEvidence: reading.soilTemperature == null ? 0 : _heatEvidence(reading.soilTemperature!),
        atmosphericEvidence: (vpd * 30).clamp(0.0, 100.0).toDouble(),
      ),
      responseLag: ResponseLagInfo(
        environmentToBioResponseSeconds: mode == DemoMode.bioResponse ||
                mode == DemoMode.atmosphericDrying ||
                severe
            ? 42
            : null,
        irrigationToBioDecreaseSeconds: recovering ? 96 : null,
        interpretation: recovering
            ? 'The simulated plant signal is following the environmental improvement.'
            : null,
      ),
      anomaly: AnomalyInfo(
        state: mode == DemoMode.bioResponse || severe ? 'CHANGE_DETECTED' : 'NONE',
        detected: mode == DemoMode.bioResponse || severe,
        changePointDetected: mode == DemoMode.bioResponse || severe,
        score: mode == DemoMode.bioResponse ? 72 : severe ? 94 : 8,
        confidence: sensorFault ? 25 : 88,
        reason: mode == DemoMode.bioResponse
            ? 'Plant electrical response shifted while environmental evidence remains mixed.'
            : severe
                ? 'Multiple stress channels changed together.'
                : null,
      ),
      baseline: PlantBaselineInfo(
        status: sensorFault
            ? 'UNAVAILABLE'
            : baselineLearning
                ? 'LEARNING_BASELINE'
                : baselinePaused
                    ? 'PROTECTED_PAUSED'
                    : 'BASELINE_STABLE',
        ready: baselineReady,
        learnedNormal: reading.bioBaselineMv,
        deviation: reading.bioDeviationMv,
        anomalyDetected: mode == DemoMode.bioResponse || severe,
        changePointDetected: mode == DemoMode.bioResponse || severe,
      ),
      stressEvidence: stressEvidence,
      derivedEnvironment: DerivedEnvironmentInfo(
        vpdKpa: vpd,
        airDryingDemand: vpd,
        vpdState: _vpdState(vpd),
        dryingDemandState: _vpdState(vpd),
      ),
      waterBalance: WaterBalanceInfo(
        state: _waterState(reading.soilMoisture),
        score: (100 - (reading.soilMoisture - 62).abs() * 1.65)
            .clamp(0.0, 100.0)
            .toDouble(),
        explanation: _waterState(reading.soilMoisture),
      ),
      cameraHandoff: bioticRisk
          ? CameraHandoffInfo(
              recommended: true,
              reason: 'Environmental and plant-response evidence supports visual inspection.',
              recommendation: 'Use the camera inspection flow to look for visible symptoms.',
              crop: crop,
            )
          : const CameraHandoffInfo(recommended: false),
      sensorConfidence: sensorConfidences,
      trends: [
        SensorTrend(channel: 'soilMoisture', state: soilTrend, confidence: 91),
        SensorTrend(channel: 'airTemperature', state: airTrend, confidence: 94),
        SensorTrend(channel: 'humidity', state: humidityTrend, confidence: 92),
        SensorTrend(channel: 'bioelectric', state: bioTrend, confidence: sensorFault ? 18 : 88),
      ],
      sensorFaults: sensorFault
          ? const [
              SensorFaultInfo(
                channel: 'simulation-group',
                type: 'INTENTIONAL_SENSOR_FAULT',
                explanation: 'Selected channels are unavailable to demonstrate degraded analysis.',
                confidence: 100,
              ),
            ]
          : const [],
      recentEvents: events,
      irrigation: recovering
          ? IrrigationEvent(
              probable: true,
              response: 'RECOVERY_RESPONSE',
              explanation:
                  'The recovery scenario includes a simulated root-zone improvement followed by a decreasing plant response.',
              timestamp: reading.timestamp.subtract(const Duration(minutes: 2)),
            )
          : const IrrigationEvent(),
      cropProfile: CropProfileInfo(
        profile: crop,
        growthStage: growthStage,
        regionProfile: 'Universal simulation profile',
        supportedProfiles: const [
          'universal',
          'tomato',
          'hibiscus',
          'rice',
          'sugarcane',
          'banana',
          'eggplant',
          'okra',
          'maize',
          'groundnut',
        ],
        supportedStages: const [
          'general',
          'young',
          'vegetative',
          'flowering',
          'fruiting',
          'mature',
        ],
        switchable: false,
      ),
      tinyMl: const TinyMlInfo(
        status: 'DISABLED_NO_MODEL',
        ready: false,
        modelLoaded: false,
        featureVectorAvailable: false,
      ),
      activeSensorChannels: <String>[
        'airTemperature',
        'humidity',
        'light',
        if (reading.soilMoistureAvailable) 'soilMoisture',
        if (reading.soilTemperatureAvailable) 'rootTemperature',
        if (reading.leafWetnessAvailable) 'leafWetness',
        if (reading.plantSignalAvailable) 'bioelectric',
      ],
      riskFlags: <String>[
        if (vpd >= 2.2) 'HIGH_ATMOSPHERIC_DRYING_DEMAND',
        if (reading.soilMoisture < 30) 'LOW_ROOT_ZONE_MOISTURE',
        if (reading.temperature >= 34) 'HEAT_STRESS',
        if ((reading.leafWetness ?? 0) >= 65) 'LEAF_WETNESS_RISK',
        if (bioticRisk) 'POSSIBLE_BIOTIC_STRESS',
        if (sensorFault) 'SENSOR_FAULT',
      ],
      diseaseRiskScore: diseaseRisk,
      diseaseRiskLevel: diseaseRisk == null
          ? null
          : diseaseRisk >= 70
              ? 'HIGH'
              : diseaseRisk >= 40
                  ? 'MODERATE'
                  : 'LOW',
      confirmedDisease: false,
    );
  }

  static HardwareTelemetry buildTelemetry({
    required SensorReading reading,
    required List<SensorReading> history,
    required DemoMode mode,
    required String crop,
    required String growthStage,
  }) {
    final previous = history.length >= 2 ? history[history.length - 2] : null;
    final vpd = _vpd(reading.temperature, reading.humidity);
    HardwareSensorDetail detail({
      required String channel,
      required bool available,
      required String result,
      required String trend,
      required double confidence,
      required double? rawValue,
      String? quality,
      String? explanation,
      String? contribution,
    }) =>
        HardwareSensorDetail(
          channel: channel,
          result: available ? result : 'UNAVAILABLE',
          explanation: explanation,
          contribution: contribution,
          trend: trend,
          confidence: available ? confidence : 0,
          status: available ? 'OK' : 'UNAVAILABLE',
          quality: available ? quality : 'UNAVAILABLE',
          rawValue: rawValue,
        );

    return HardwareTelemetry(
      firmwareVersion: 'simulation-intelligence-v2',
      cropProfile: crop,
      growthStage: growthStage,
      analysisQuality: mode == DemoMode.sensorFault ? 'DEGRADED' : 'GOOD',
      dayPhase: reading.daytime ? 'DAY' : 'NIGHT',
      vpdKpa: vpd,
      airRootDeltaC: reading.soilTemperature == null
          ? null
          : reading.temperature - reading.soilTemperature!,
      bioelectricDeviationPercent: reading.bioBaselineMv == null ||
              reading.bioBaselineMv == 0 ||
              reading.bioDeviationMv == null
          ? null
          : reading.bioDeviationMv! / reading.bioBaselineMv! * 100,
      sensors: {
        'airTemperature': detail(
          channel: 'airTemperature',
          available: reading.temperatureAvailable,
          result: reading.temperature >= 34 ? 'HIGH' : 'NORMAL',
          trend: _trend(previous?.temperature, reading.temperature),
          confidence: 98,
          rawValue: reading.temperature,
          quality: 'GOOD',
          explanation: 'Simulated AHT-class air-temperature channel.',
        ),
        'humidity': detail(
          channel: 'humidity',
          available: reading.humidityAvailable,
          result: reading.humidity >= 82 ? 'HIGH' : 'NORMAL',
          trend: _trend(previous?.humidity, reading.humidity),
          confidence: 97,
          rawValue: reading.humidity,
          quality: 'GOOD',
        ),
        'light': detail(
          channel: 'light',
          available: reading.lightAvailable,
          result: reading.daytime && reading.light < 25 ? 'LOW' : 'NORMAL',
          trend: _trend(previous?.light, reading.light),
          confidence: 95,
          rawValue: reading.lightLux ?? reading.light,
          quality: 'GOOD',
        ),
        'soilMoisture': detail(
          channel: 'soilMoisture',
          available: reading.soilMoistureAvailable,
          result: _waterState(reading.soilMoisture),
          trend: _trend(previous?.soilMoisture, reading.soilMoisture),
          confidence: 94,
          rawValue: reading.soilMoisture,
          quality: reading.soilCalibrated ? 'CALIBRATED' : 'ESTIMATED',
          contribution: reading.soilMoisture < 35 ? 'Supports water-stress evidence' : 'Counters water-stress evidence',
        ),
        'rootTemperature': detail(
          channel: 'rootTemperature',
          available: reading.soilTemperatureAvailable,
          result: (reading.soilTemperature ?? 0) >= 32 ? 'HIGH' : 'NORMAL',
          trend: _trend(previous?.soilTemperature, reading.soilTemperature),
          confidence: 96,
          rawValue: reading.soilTemperature,
          quality: 'GOOD',
        ),
        'leafWetness': detail(
          channel: 'leafWetness',
          available: reading.leafWetnessAvailable,
          result: (reading.leafWetness ?? 0) >= 60 ? 'WET' : 'DRY',
          trend: _trend(previous?.leafWetness, reading.leafWetness),
          confidence: 92,
          rawValue: reading.leafWetness,
          quality: 'GOOD',
          contribution: (reading.leafWetness ?? 0) >= 60 ? 'Supports disease-conducive risk' : 'Low surface-wetness evidence',
        ),
        'plantSignal': detail(
          channel: 'plantSignal',
          available: reading.plantSignalAvailable,
          result: mode == DemoMode.baselineLearning
              ? 'LEARNING_BASELINE'
              : mode == DemoMode.sensorFault
                  ? 'SIGNAL_NOISY'
                  : _bioState(100 - (reading.bioelectricStability ?? reading.plantSignal), mode == DemoMode.recovery),
          trend: mode == DemoMode.recovery ? 'FALLING' : 'STABLE',
          confidence: mode == DemoMode.sensorFault ? 18 : 92,
          rawValue: reading.plantVoltageMv,
          quality: mode == DemoMode.sensorFault ? 'NOISY' : 'GOOD',
          contribution: mode == DemoMode.sensorFault ? 'Excluded from fusion' : 'Available to fusion',
        ),
        'vpd': detail(
          channel: 'vpd',
          available: reading.temperatureAvailable && reading.humidityAvailable,
          result: _vpdState(vpd),
          trend: 'DERIVED',
          confidence: 96,
          rawValue: vpd,
          quality: 'DERIVED',
          explanation: 'Derived from simulated air temperature and relative humidity.',
        ),
      },
    );
  }

  static _ScenarioAnalysis _scenarioAnalysis({
    required DemoMode mode,
    required SensorReading reading,
    required double vpd,
    required double bioStress,
  }) {
    switch (mode) {
      case DemoMode.baselineLearning:
        return const _ScenarioAnalysis(
          primary: 'No active stress detected',
          primaryConfidence: 78,
          evidenceFor: 'Environmental readings are broadly stable while the plant electrical baseline is still learning.',
          evidenceAgainst: 'Bioelectric stress classification is intentionally withheld until baseline learning completes.',
          action: 'Keep the electrodes stable and allow baseline learning to finish.',
          explanation: 'Simulation is demonstrating protected plant-baseline learning.',
          whatIf: 'If a strong environmental stress appears during learning, baseline adaptation pauses instead of learning the stressed state.',
        );
      case DemoMode.atmosphericDrying:
        return _ScenarioAnalysis(
          primary: 'High atmospheric drying demand',
          secondary: 'Air temperature is increasing water demand',
          primaryConfidence: 91,
          secondaryConfidence: 78,
          evidenceFor: 'VPD is ${vpd.toStringAsFixed(2)} kPa while root-zone moisture remains adequate.',
          evidenceAgainst: 'Soil moisture does not currently support root-zone drought as the dominant cause.',
          secondaryEvidence: 'Air temperature is ${reading.temperature.toStringAsFixed(1)} °C.',
          action: 'Check root-zone moisture first. If the soil is drying, irrigate during the cooler part of the day; otherwise reduce avoidable heat, wind or direct exposure where practical.',
          explanation: 'Atmospheric demand is high, but the root zone is not currently dry.',
          whatIf: 'If soil moisture also fell below the preferred range, water stress would gain much stronger support.',
          ranked: const [
            RootCauseCandidate(name: 'High atmospheric drying demand', confidence: 91, evidenceFor: 'High VPD', evidenceAgainst: 'Soil moisture remains adequate'),
            RootCauseCandidate(name: 'Root-zone water stress', confidence: 24, evidenceFor: 'High water demand', evidenceAgainst: 'Soil moisture is not low'),
          ],
        );
      case DemoMode.dry:
        return _ScenarioAnalysis(
          primary: 'Root-zone moisture is low',
          secondary: 'Atmospheric demand is adding pressure',
          primaryConfidence: 94,
          secondaryConfidence: vpd >= 1.5 ? 74 : 42,
          evidenceFor: 'Soil moisture is ${reading.soilMoisture.toStringAsFixed(0)}% and remains below the preferred range.',
          evidenceAgainst: 'No evidence currently contradicts the low root-zone reading.',
          secondaryEvidence: 'VPD is ${vpd.toStringAsFixed(2)} kPa.',
          action: 'Confirm the root zone is actually dry, then irrigate appropriately for the plant and pot.',
          explanation: 'Low root-zone moisture is the strongest simulated cause.',
          whatIf: 'If soil moisture recovered while bioelectric stress stayed high, another cause would become more important.',
          ranked: const [
            RootCauseCandidate(name: 'Root-zone moisture is low', confidence: 94, evidenceFor: 'Low soil moisture'),
            RootCauseCandidate(name: 'Atmospheric drying demand', confidence: 68, evidenceFor: 'Elevated VPD'),
          ],
        );
      case DemoMode.overwatered:
        return _ScenarioAnalysis(
          primary: 'Root-zone moisture is very high',
          secondary: 'Persistent leaf wetness is increasing environmental risk',
          primaryConfidence: 92,
          secondaryConfidence: 80,
          evidenceFor: 'Soil moisture is ${reading.soilMoisture.toStringAsFixed(0)}%.',
          evidenceAgainst: 'Dry-root evidence is absent.',
          secondaryEvidence: 'Leaf wetness remains elevated.',
          action: 'Avoid unnecessary watering and check drainage and root-zone aeration.',
          explanation: 'Excess root-zone moisture is the dominant simulated condition.',
          whatIf: 'If root-zone moisture returned to range while leaf wetness stayed high, environmental disease risk would remain relevant.',
        );
      case DemoMode.heatStress:
        return _ScenarioAnalysis(
          primary: 'Heat stress is the strongest environmental signal',
          secondary: 'Atmospheric drying demand is elevated',
          primaryConfidence: 89,
          secondaryConfidence: 84,
          evidenceFor: 'Air temperature is ${reading.temperature.toStringAsFixed(1)} °C.',
          evidenceAgainst: 'Root-zone moisture is not critically low.',
          secondaryEvidence: 'VPD is ${vpd.toStringAsFixed(2)} kPa.',
          action: 'Check root-zone moisture and reduce avoidable heat exposure where practical.',
          explanation: 'Heat and atmospheric demand are stronger than water-deficit evidence.',
          whatIf: 'If root-zone moisture also dropped, the condition would become a compound heat + water stress event.',
        );
      case DemoMode.bioResponse:
        return _ScenarioAnalysis(
          primary: 'Plant electrical response needs attention',
          secondary: 'Environmental evidence is mixed',
          primaryConfidence: 76,
          secondaryConfidence: 48,
          evidenceFor: 'Bioelectric stress score is ${bioStress.toStringAsFixed(0)}/100 with usable signal quality.',
          evidenceAgainst: 'No single environmental channel is severe enough to fully explain the response.',
          secondaryEvidence: 'Soil, temperature and VPD evidence are not strongly aligned.',
          action: 'Keep monitoring the plant response and inspect the plant if the signal persists without an environmental explanation.',
          explanation: 'This scenario demonstrates a plant-response anomaly without pretending it is a disease diagnosis.',
          whatIf: 'If leaf wetness and humidity also became strongly disease-conducive, visual inspection would become more important.',
        );
      case DemoMode.recovery:
        return const _ScenarioAnalysis(
          primary: 'Plant response is recovering',
          secondary: 'Environmental pressure is easing',
          primaryConfidence: 90,
          secondaryConfidence: 85,
          evidenceFor: 'Stress direction is falling and environmental conditions are improving.',
          evidenceAgainst: 'The plant signal has not fully returned to its learned baseline yet.',
          secondaryEvidence: 'VPD and temperature are moving toward a lower-demand range.',
          action: 'Continue monitoring and avoid unnecessary intervention while recovery continues.',
          explanation: 'The simulator is demonstrating before → stress → recovery behaviour.',
          whatIf: 'If the plant response rose again while the environment stayed improved, PhytoSense would reopen competing causes.',
        );
      case DemoMode.bioticRisk:
        return const _ScenarioAnalysis(
          primary: 'Disease-conducive environmental risk',
          secondary: 'Possible unexplained plant response',
          primaryConfidence: 82,
          secondaryConfidence: 68,
          evidenceFor: 'High humidity and persistent leaf wetness support environmental risk.',
          evidenceAgainst: 'Environmental risk alone cannot confirm disease or infection.',
          secondaryEvidence: 'Plant-response evidence is present but not diagnostic.',
          action: 'Improve airflow where practical and inspect leaves and stems for visible symptoms.',
          explanation: 'PhytoSense reports risk and suspicion, never a confirmed disease from these sensors alone.',
          whatIf: 'If visible symptoms are captured by the camera workflow, they can be assessed separately from the sensor risk signal.',
        );
      case DemoMode.lowLight:
        return const _ScenarioAnalysis(
          primary: 'Light availability is low',
          primaryConfidence: 86,
          evidenceFor: 'Daylight reading remains below the normal simulated range.',
          evidenceAgainst: 'Water and temperature conditions remain broadly acceptable.',
          action: 'Check shade, cover or placement before changing irrigation.',
          explanation: 'Low light is the dominant simulated environmental condition.',
          whatIf: 'If low light is temporary or it is night, it should not be treated as plant stress.',
        );
      case DemoMode.critical:
        return const _ScenarioAnalysis(
          primary: 'Compound heat and water stress',
          secondary: 'Plant electrical response is strongly elevated',
          additional: 'Atmospheric drying demand is extreme',
          primaryConfidence: 97,
          secondaryConfidence: 91,
          evidenceFor: 'Very low soil moisture, high temperature and high VPD agree.',
          evidenceAgainst: 'There is little counter-evidence in this simulated scenario.',
          secondaryEvidence: 'Bioelectric response is strong and corroborated by environmental channels.',
          action: 'Inspect the root zone immediately and reduce heat exposure where practical.',
          explanation: 'Multiple independent channels agree on a high-stress condition.',
          whatIf: 'If root-zone moisture improves, the system should verify whether heat or plant-response stress remains.',
          ranked: const [
            RootCauseCandidate(name: 'Compound heat and water stress', confidence: 97, evidenceFor: 'Water + heat + VPD agreement'),
            RootCauseCandidate(name: 'Bioelectric plant response', confidence: 91, evidenceFor: 'Strong persistent plant signal'),
          ],
        );
      case DemoMode.sensorFault:
        return const _ScenarioAnalysis(
          primary: 'Analysis is degraded because sensor information is unavailable',
          primaryConfidence: 100,
          evidenceFor: 'The scenario intentionally removes multiple channels.',
          evidenceAgainst: 'Missing channels cannot be interpreted as normal readings.',
          action: 'Check sensor connections or switch back to a healthy simulation scenario.',
          explanation: 'Faulty channels are excluded rather than converted into plant stress.',
          whatIf: 'Restoring the missing channels increases evidence coverage and confidence.',
        );
      case DemoMode.offline:
        return const _ScenarioAnalysis(
          primary: 'Simulation node is offline',
          primaryConfidence: 100,
          evidenceFor: 'No new simulated packet is being generated.',
          action: 'Retry the simulation connection or choose another scenario.',
          explanation: 'Offline data is never represented as live.',
          whatIf: 'When packets resume, the app updates from fresh simulated readings.',
        );
      case DemoMode.healthy:
        return const _ScenarioAnalysis(
          primary: 'No important problem detected',
          primaryConfidence: 93,
          evidenceFor: 'Root-zone, atmosphere and plant-response channels broadly agree on a stable state.',
          evidenceAgainst: 'No persistent high-severity evidence is present.',
          action: 'Continue normal monitoring.',
          explanation: 'The simulated channels are within their broad operating ranges.',
          whatIf: 'If one channel changes, PhytoSense compares it with the remaining evidence before changing the main finding.',
        );
    }
  }

  static List<PhytoEvent> _eventsFor(DemoMode mode, DateTime now, String? primary) {
    final events = <PhytoEvent>[
      PhytoEvent(
        timestamp: now.subtract(const Duration(minutes: 8)),
        type: 'BASELINE',
        message: mode == DemoMode.baselineLearning
            ? 'Plant baseline learning started'
            : 'Plant baseline available',
        severity: 'INFO',
      ),
    ];
    if (mode != DemoMode.healthy && mode != DemoMode.baselineLearning) {
      events.add(PhytoEvent(
        timestamp: now.subtract(const Duration(minutes: 4)),
        type: 'EVIDENCE_CHANGE',
        message: primary ?? 'Condition changed',
        severity: mode == DemoMode.critical ? 'HIGH' : 'WATCH',
      ));
    }
    if (mode == DemoMode.recovery) {
      events.add(PhytoEvent(
        timestamp: now.subtract(const Duration(minutes: 2)),
        type: 'RECOVERY',
        message: 'Recovery trend detected',
        severity: 'INFO',
      ));
    }
    if (mode == DemoMode.sensorFault) {
      events.add(PhytoEvent(
        timestamp: now.subtract(const Duration(minutes: 1)),
        type: 'SENSOR_FAULT',
        message: 'Unavailable channels excluded from analysis',
        severity: 'WATCH',
      ));
    }
    return events;
  }

  static double _vpd(double temperature, double humidity) {
    final saturation =
        0.6108 * math.exp((17.27 * temperature) / (temperature + 237.3));
    return (saturation * (1 - humidity / 100)).clamp(0.0, 8.0).toDouble();
  }

  static String _vpdState(double vpd) {
    if (vpd < 0.4) return 'LOW';
    if (vpd < 1.5) return 'OPTIMAL';
    if (vpd < 2.2) return 'HIGH';
    return 'VERY_HIGH';
  }

  static String _waterState(double soil) {
    if (soil < 20) return 'VERY_DRY';
    if (soil < 35) return 'DRY';
    if (soil > 86) return 'VERY_WET';
    if (soil > 75) return 'WET';
    return 'OPTIMAL';
  }

  static String _stateFor(double health) {
    if (health >= 82) return 'HEALTHY';
    if (health >= 65) return 'WATCH';
    if (health >= 42) return 'STRESSED';
    return 'CRITICAL';
  }

  static String _bioState(double stress, bool recovering) {
    if (recovering) return 'RECOVERING';
    if (stress >= 75) return 'STRONG_STRESS_SIGNAL';
    if (stress >= 50) return 'STRESS_SIGNAL';
    if (stress >= 25) return 'MILD_RESPONSE';
    return 'NORMAL';
  }

  static String _trend(double? previous, double? current) {
    if (previous == null || current == null) return 'STABLE';
    final delta = current - previous;
    if (delta > 4) return 'RISING_FAST';
    if (delta > 0.6) return 'RISING';
    if (delta < -4) return 'FALLING_FAST';
    if (delta < -0.6) return 'FALLING';
    return 'STABLE';
  }

  static double _waterEvidence(double soil) {
    if (soil < 20) return 96;
    if (soil < 35) return (35 - soil) * 4 + 35;
    if (soil > 86) return math.min(92.0, (soil - 86) * 4 + 55);
    return 8;
  }

  static double _heatEvidence(double temperature) {
    if (temperature >= 37) return 96;
    if (temperature >= 32) return math.min(92.0, 45 + (temperature - 32) * 9);
    return 8;
  }
}

class _ScenarioAnalysis {
  final String? primary;
  final String? secondary;
  final String? additional;
  final double? primaryConfidence;
  final double? secondaryConfidence;
  final String? evidenceFor;
  final String? evidenceAgainst;
  final String? secondaryEvidence;
  final String action;
  final String explanation;
  final String whatIf;
  final List<RootCauseCandidate> ranked;

  const _ScenarioAnalysis({
    this.primary,
    this.secondary,
    this.additional,
    this.primaryConfidence,
    this.secondaryConfidence,
    this.evidenceFor,
    this.evidenceAgainst,
    this.secondaryEvidence,
    required this.action,
    required this.explanation,
    required this.whatIf,
    this.ranked = const [],
  });
}
