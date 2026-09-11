import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phytosense_ai/models/farm_impact_projection.dart';
import 'package:phytosense_ai/models/edge_intelligence.dart';
import 'package:phytosense_ai/models/crop_catalog.dart';
import 'package:phytosense_ai/models/disease_assessment.dart';
import 'package:phytosense_ai/models/leaf_screening_result.dart';
import 'package:phytosense_ai/models/app_settings.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';
import 'package:phytosense_ai/models/weather_snapshot.dart';
import 'package:phytosense_ai/services/ai_analysis_service.dart';
import 'package:phytosense_ai/services/alert_service.dart';
import 'package:phytosense_ai/services/app_scope.dart';
import 'package:phytosense_ai/services/engineering_evidence_service.dart';
import 'package:phytosense_ai/services/farm_repository.dart';
import 'package:phytosense_ai/services/firmware_text_adapter.dart';
import 'package:phytosense_ai/services/inspection_history_service.dart';
import 'package:phytosense_ai/services/irrigation_advisor.dart';
import 'package:phytosense_ai/services/location_name_resolver.dart';
import 'package:phytosense_ai/services/multimodal_disease_service.dart';
import 'package:phytosense_ai/services/offline_sync_service.dart';
import 'package:phytosense_ai/services/sensor_data_provider.dart';
import 'package:phytosense_ai/services/sensor_provider_manager.dart';
import 'package:phytosense_ai/services/settings_service.dart';
import 'package:phytosense_ai/services/voice_guidance_service.dart';
import 'package:phytosense_ai/services/weather_service.dart';
import 'package:phytosense_ai/screens/farmer_analysis_screen.dart';
import 'package:phytosense_ai/simulation/simulated_sensor_provider.dart';

void main() {
  test('new installs use safe source and accessibility defaults', () {
    final settings = AppSettings();
    expect(settings.largeText, isFalse);
    expect(settings.reducedMotion, isFalse);
    expect(settings.dataSource, 'simulation');
  });

  test('v6.2 bioelectric and biotic fields parse without a health score', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{
        'plantState': 'STRESSED',
        'recommendation': 'Check the root-zone soil and water if it is dry.',
        'rootCause': <String, dynamic>{
          'primary': 'WATER_STRESS',
          'secondary': 'HIGH_ATMOSPHERIC_DRYING_DEMAND',
        },
        'bioelectric': <String, dynamic>{
          'available': true,
          'voltageMv': 482.0,
          'baselineMv': 451.0,
          'signedChangeMv': 31.0,
          'deviationMv': 31.0,
          'normalizedDeviation': 9.7,
          'noiseMv': 3.2,
          'signalQuality': 91,
          'confidence': 86,
          'trend': 'RISING',
          'stressScore': 84,
          'stressState': 'STRESS_SIGNAL',
          'persistenceSeconds': 28,
          'corroborated': true,
          'corroboratedBy': <String>['soilMoisture', 'vpd'],
          'farmerResult': 'Plant stress detected — likely water stress',
        },
        'bioticStress': <String, dynamic>{
          'state': 'SUSPECTED',
          'evidenceScore': 68,
          'confidence': 74,
          'unexplainedBioResponse': true,
          'abioticCauseFound': false,
          'diseaseConduciveSupport': true,
          'reason': 'Stress remains partly unexplained.',
          'farmerResult':
              'Possible biotic stress — inspect for pests or infection',
          'pestIdentified': false,
          'infectionConfirmed': false,
        },
      },
      firmwareVersion: '6.2',
    );
    expect(edge.hasAuthoritativeAnalysis, isTrue);
    expect(edge.healthScore, isNull);
    expect(edge.bioelectric.stressScore, 84);
    expect(edge.bioelectric.persistenceSeconds, 28);
    expect(edge.bioelectric.corroboratedBy, contains('vpd'));
    expect(edge.bioticStress.suspected, isTrue);
  });

  test('biotic suspicion is not retained after explicit confirmation fields', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{
        'bioticStress': <String, dynamic>{
          'state': 'SUSPECTED',
          'pestIdentified': true,
          'infectionConfirmed': false,
        },
      },
      firmwareVersion: '6.2',
    );
    expect(edge.bioticStress.suspected, isFalse);
  });

  test('new flat biotic API aliases parse as nullable ESP32 intelligence', () {
    final edge = EdgeIntelligence.fromPayload(
      root: const <String, dynamic>{},
      data: const <String, dynamic>{
        'bioticState': 'POSSIBLE_BIOTIC_STRESS',
        'bioticEvidence': 72,
        'bioticReason': 'Unexplained persistent bioelectric stress',
        'bioticConfidence': 81,
        'bioticRecommendation': 'Inspect plant visually and run camera analysis',
      },
      firmwareVersion: '8.0.0-ULTRA-FINAL',
    );

    expect(edge.bioticStress.normalizedState, 'POSSIBLE_BIOTIC_STRESS');
    expect(edge.bioticStress.suspected, isTrue);
    expect(edge.bioticStress.evidenceScore, 72);
    expect(edge.bioticStress.confidence, 81);
    expect(edge.bioticStress.reason, contains('Unexplained'));
    expect(edge.bioticStress.recommendation, contains('camera'));
    expect(edge.bioticStress.unexplainedBioResponse, isNull);
  });

  test('all non-suspicion biotic states remain non-diagnostic', () {
    for (final state in const <String>[
      'NONE',
      'INSUFFICIENT_DATA',
      'LOW_CONFIDENCE',
    ]) {
      final info = BioticStressInfo(state: state);
      expect(info.suspected, isFalse, reason: state);
    }
    expect(
      const BioticStressInfo(state: 'POSSIBLE_BIOTIC_STRESS').suspected,
      isTrue,
    );
    expect(const BioticStressInfo().hasData, isFalse);
  });

  SensorReading reading({
    double soil = 62,
    double temperature = 25,
    double humidity = 58,
    double light = 68,
    double plantSignal = 50,
    double health = 90,
  }) =>
      SensorReading(
        nodeId: 'test-node',
        timestamp: DateTime(2026, 8, 23),
        soilMoisture: soil,
        temperature: temperature,
        humidity: humidity,
        light: light,
        plantSignal: plantSignal,
        healthScore: health,
        stressScore: 100 - health,
        healthStatus: SensorReading.statusForHealth(health),
      );

  test('healthy readings produce a balanced insight', () {
    final current = reading();
    final result = AiAnalysisService.analyze(current, [current, current]);
    expect(result.headlineKey, 'ai_healthy');
    expect(result.level, InsightLevel.healthy);
  });

  test('dry and hot readings receive urgent priority', () {
    final current = reading(soil: 12, temperature: 36);
    final result = AiAnalysisService.analyze(current, [current]);
    expect(result.headlineKey, 'ai_combined_stress');
    expect(result.level, InsightLevel.urgent);
  });

  test('raw ESP32 JSON receives a calculated health score', () {
    final result = SensorReading.fromJson({
      'soilMoisture': 62,
      'temperature': 25,
      'humidity': 58,
      'light': 68,
      'plantSignal': 70,
    });
    expect(result.healthScore, greaterThan(95));
    expect(result.nodeId, 'phytosense-live-01');
  });

  test('falling moisture is detected before the dry threshold', () {
    final history = <SensorReading>[
      reading(soil: 52),
      reading(soil: 49),
      reading(soil: 46),
      reading(soil: 43),
      reading(soil: 40),
      reading(soil: 37),
    ];
    final result = AiAnalysisService.analyze(history.last, history);
    expect(result.headlineKey, 'ai_early_water_stress');
    expect(result.level, InsightLevel.attention);
  });

  test('provider manager switches sources without changing its contract', () {
    final manager = SensorProviderManager();
    expect(manager.source, SensorDataSource.simulation);
    final demoNodeId = manager.selectedNodeId;
    manager.configure(
      source: SensorDataSource.esp32,
      endpoint: 'http://192.168.4.1',
    );
    expect(manager.source, SensorDataSource.esp32);
    expect(manager.selectedNodeId, 'phytosense-live-01');
    expect(manager.selectedNodeId, isNot(demoNodeId));
    expect(manager.supportsScenarios, isFalse);
    expect(manager.scenarioIds, isEmpty);
    expect(manager.current, isNull);
    expect(manager.edgeIntelligence, isNull);
    expect(manager.hardwareTelemetry, isNull);
    manager.setScenario('drought');
    expect(manager.current, isNull);
    manager.dispose();
  });

  test('refresh keeps the selected critical Practice Farm condition', () {
    final provider = SimulationSensorProvider();
    provider.setScenario('critical');
    provider.start();
    provider.selectNode('node-rice-a1');

    expect(provider.scenarioId, 'critical');
    expect(provider.selectedNodeId, 'node-rice-a1');

    provider.retry();

    expect(provider.scenarioId, 'critical');
    expect(provider.selectedNodeId, 'node-rice-a1');
    expect(provider.current, isNotNull);
    provider.dispose();
  });

  test('an offline Practice Farm node does not expose an old reading', () {
    final provider = SimulationSensorProvider()..start();
    expect(provider.current, isNotNull);

    provider.setScenario('offline');

    expect(provider.current, isNull);
    expect(provider.latestReadings, isEmpty);
    expect(provider.edgeIntelligence, isNull);
    expect(provider.hardwareTelemetry, isNull);
    provider.dispose();
  });

  test('Practice Farm condition and zone survive a settings reload', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final settings = SettingsService();
    await settings.load();
    await settings.setScenario('critical');
    await settings.setDemoNode('node-rice-a1');

    final restored = SettingsService();
    await restored.load();

    expect(restored.value.demoScenario, 'critical');
    expect(restored.value.demoNodeId, 'node-rice-a1');
  });

  testWidgets('farmer analysis stays rendered and keeps details open on refresh',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final settings = SettingsService();
    final farms = FarmRepository();
    final sensors = SensorProviderManager();
    sensors.setScenario('critical');
    sensors.start();
    final weather = WeatherService();
    final alerts = AlertService(sensors, settings, weather, farms);
    final voice = VoiceGuidanceService();
    final offlineSync = OfflineSyncService(sensors, settings);
    final evidence = EngineeringEvidenceService(sensors);
    final inspections = InspectionHistoryService();

    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          settings: settings,
          farms: farms,
          sensorManager: sensors,
          alerts: alerts,
          weather: weather,
          voice: voice,
          offlineSync: offlineSync,
          engineeringEvidence: evidence,
          inspectionHistory: inspections,
          child: const FarmerAnalysisScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Plant needs urgent attention'), findsOneWidget);
    expect(find.byKey(const Key('farmer-main-problem')), findsOneWidget);
    expect(find.byKey(const Key('farmer-immediate-action')), findsOneWidget);
    expect(find.text('WHAT IS WRONG?'), findsOneWidget);
    expect(find.text('WHAT TO DO NOW'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('More details'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('More details'));
    await tester.pumpAndSettle();
    expect(find.text('Firmware'), findsOneWidget);

    sensors.retry();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Firmware'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    sensors.dispose();
  });

  test('real ESP32 output is translated into plain farmer English', () {
    expect(
      FirmwareTextAdapter.farmerEnglish(
        'VPD indicates the air is pulling water quickly',
      ),
      'Dry air is pulling water from the plant quickly.',
    );
    expect(
      FirmwareTextAdapter.farmerEnglish(
        'Plant electrical response uncertain - check electrode signal',
      ),
      'The plant sensor reading is not clear. Check that it touches the plant properly.',
    );
    expect(
      FirmwareTextAdapter.farmerEnglish(
        'Check the root-zone soil and water if it is genuinely dry',
      ),
      'Check the soil near the roots. Water it if it is dry.',
    );
    expect(
      FirmwareTextAdapter.farmerEnglish(
        'Root temperature is unavailable; analysis continues with remaining sensors',
      ),
      'The root-temperature sensor is not working. The other sensors are still active.',
    );
  });

  test('simulation supplies environment and bioelectric intelligence', () {
    final provider = SimulationSensorProvider()..start();
    final edge = provider.edgeIntelligence;

    expect(provider.current, isNotNull);
    expect(edge, isNotNull);
    expect(edge!.derivedEnvironment.vpdKpa, isNotNull);
    expect(edge.derivedEnvironment.dryingDemandState, isNotNull);
    expect(edge.bioelectric.available, isTrue);
    expect(edge.bioelectric.stressState, isNotNull);
    expect(edge.bioelectric.signalQualityState, 'GOOD');
    expect(edge.bioelectric.includedInFusion, isTrue);

    provider.dispose();
  });

  test('Trichy GPS coordinates resolve to a readable place name', () {
    final name = LocationNameResolver.resolve(10.7905, 78.7047);
    expect(name, contains('Trichy'));
    expect(name, contains('Tamil Nadu'));
  });

  test('experiment evidence survives JSON serialization', () {
    final trial = ExperimentTrial(
      id: 'trial-1',
      title: 'Tomato baseline',
      crop: 'Tomato',
      source: 'esp32',
      nodeId: 'phytosense-live-01',
      startedAt: DateTime(2026, 8, 24, 10),
      endedAt: DateTime(2026, 8, 24, 10, 5),
      baselineHealth: 91,
      minimumHealth: 74,
      maximumStress: 26,
      sampleCount: 100,
      outcome: 'detected',
      notes: 'Controlled observation',
    );
    final restored = ExperimentTrial.fromJson(trial.toJson());
    expect(restored.title, trial.title);
    expect(restored.source, 'esp32');
    expect(restored.duration, const Duration(minutes: 5));
    expect(restored.sampleCount, 100);
  });

  test('farmer feedback preserves false-alert evidence', () {
    final feedback = FarmerFeedback(
      alertId: 'alert-1',
      source: 'esp32',
      nodeId: 'phytosense-live-01',
      recordedAt: DateTime(2026, 8, 24),
      conditionConfirmed: false,
      recommendationUseful: false,
      plantRecovered: false,
      falseAlert: true,
      notes: 'Crop inspection did not confirm the alert.',
    );
    final restored = FarmerFeedback.fromJson(feedback.toJson());
    expect(restored.falseAlert, isTrue);
    expect(restored.conditionConfirmed, isFalse);
    expect(restored.source, 'esp32');
  });

  test('rain forecast can safely delay non-critical irrigation', () {
    final weather = WeatherSnapshot(
      location: 'Test farm',
      updatedAt: DateTime(2026, 8, 23),
      temperature: 26,
      humidity: 70,
      windSpeed: 8,
      weatherCode: 61,
      forecast: [
        WeatherDay(
          date: DateTime(2026, 8, 23),
          minimumTemperature: 22,
          maximumTemperature: 29,
          precipitationProbability: 85,
          precipitationMillimetres: 12,
          weatherCode: 61,
        ),
      ],
    );
    final advice = IrrigationAdvisor.advise(reading(soil: 29), weather);
    expect(advice.titleKey, 'irrigation_delay');
    expect(advice.priority, IrrigationPriority.none);
  });

  test('weather snapshot identifies heavy rain and disease risk', () {
    final weather = WeatherSnapshot(
      location: 'Test farm',
      updatedAt: DateTime(2026, 8, 23),
      temperature: 25,
      humidity: 88,
      windSpeed: 6,
      weatherCode: 65,
      forecast: [
        WeatherDay(
          date: DateTime(2026, 8, 23),
          minimumTemperature: 22,
          maximumTemperature: 28,
          precipitationProbability: 94,
          precipitationMillimetres: 34,
          weatherCode: 65,
        ),
      ],
    );
    expect(weather.heavyRainRisk, isTrue);
    expect(weather.diseaseRisk, isTrue);
  });

  test('abnormal electrode response requests a representative leaf photo', () {
    final prompt = MultimodalDiseaseService.evaluatePhotoPrompt(
      reading(plantSignal: 24, health: 58),
      null,
    );
    expect(prompt.shouldPrompt, isTrue);
    expect(prompt.reasonKeys, contains('disease_trigger_electrode'));
  });

  test('balanced readings do not create a disease photo prompt', () {
    final prompt = MultimodalDiseaseService.evaluatePhotoPrompt(
      reading(),
      null,
    );
    expect(prompt.shouldPrompt, isFalse);
  });

  test('rice visual screening ranks blast first from brown evidence', () {
    final assessment = MultimodalDiseaseService.assess(
      visual: LeafScreeningResult(
        riskKey: 'leaf_result_spot_risk',
        explanationKey: 'leaf_result_spot_risk_body',
        actionKey: 'leaf_action_spot',
        confidence: 80,
        greenPercent: 55,
        yellowPercent: 8,
        brownPercent: 18,
        screenedAt: DateTime.now(),
      ),
      crop: 'Rice',
    );
    expect(assessment.candidates.first.nameKey, 'disease_rice_blast');
    expect(assessment.usedSensorEvidence, isFalse);
    expect(assessment.usedWeatherEvidence, isFalse);
    expect(assessment.sensorTriggered, isFalse);
  });

  test('tomato yellowing with visible curl and whiteflies ranks leaf curl', () {
    final assessment = MultimodalDiseaseService.assess(
      visual: LeafScreeningResult(
        riskKey: 'leaf_result_yellowing',
        explanationKey: 'leaf_result_yellowing_body',
        actionKey: 'leaf_action_yellowing',
        confidence: 78,
        greenPercent: 48,
        yellowPercent: 35,
        brownPercent: 5,
        screenedAt: DateTime.now(),
      ),
      crop: 'Tomato',
      symptoms: const DiseaseSymptomAnswers(
        concentricRings: FieldObservation.no,
        waterSoakedLesions: FieldObservation.no,
        yellowHalos: FieldObservation.no,
        leafCurling: FieldObservation.yes,
        whitefliesPresent: FieldObservation.yes,
      ),
    );
    expect(
      assessment.candidates.first.nameKey,
      'disease_tomato_leaf_curl',
    );
    expect(assessment.usedSensorEvidence, isFalse);
  });

  test('tomato target-like rings rank early blight first', () {
    final assessment = MultimodalDiseaseService.assess(
      visual: LeafScreeningResult(
        riskKey: 'leaf_result_spot_risk',
        explanationKey: 'leaf_result_spot_risk_body',
        actionKey: 'leaf_action_spot',
        confidence: 78,
        greenPercent: 57,
        yellowPercent: 10,
        brownPercent: 20,
        screenedAt: DateTime.now(),
      ),
      crop: 'Tomato',
      symptoms: const DiseaseSymptomAnswers(
        concentricRings: FieldObservation.yes,
        waterSoakedLesions: FieldObservation.no,
        yellowHalos: FieldObservation.no,
        leafCurling: FieldObservation.no,
        whitefliesPresent: FieldObservation.no,
      ),
    );
    expect(
      assessment.candidates.first.nameKey,
      'disease_tomato_early_blight',
    );
    expect(assessment.isInconclusive, isFalse);
  });

  test('tomato water-soaked lesions and humid weather rank late blight', () {
    final assessment = MultimodalDiseaseService.assess(
      visual: LeafScreeningResult(
        riskKey: 'leaf_result_spot_risk',
        explanationKey: 'leaf_result_spot_risk_body',
        actionKey: 'leaf_action_spot',
        confidence: 79,
        greenPercent: 52,
        yellowPercent: 8,
        brownPercent: 22,
        screenedAt: DateTime.now(),
      ),
      crop: 'Tomato',
      symptoms: const DiseaseSymptomAnswers(
        concentricRings: FieldObservation.no,
        waterSoakedLesions: FieldObservation.yes,
        yellowHalos: FieldObservation.no,
        leafCurling: FieldObservation.no,
        whitefliesPresent: FieldObservation.no,
      ),
    );
    expect(
      assessment.candidates.first.nameKey,
      'disease_tomato_late_blight',
    );
  });

  test('tomato curling and whiteflies rank leaf curl first', () {
    final assessment = MultimodalDiseaseService.assess(
      visual: LeafScreeningResult(
        riskKey: 'leaf_result_yellowing',
        explanationKey: 'leaf_result_yellowing_body',
        actionKey: 'leaf_action_yellowing',
        confidence: 73,
        greenPercent: 45,
        yellowPercent: 32,
        brownPercent: 5,
        screenedAt: DateTime.now(),
      ),
      crop: 'Tomato',
      symptoms: const DiseaseSymptomAnswers(
        concentricRings: FieldObservation.no,
        waterSoakedLesions: FieldObservation.no,
        yellowHalos: FieldObservation.no,
        leafCurling: FieldObservation.yes,
        whitefliesPresent: FieldObservation.yes,
      ),
    );
    expect(
      assessment.candidates.first.nameKey,
      'disease_tomato_leaf_curl',
    );
  });

  test('all supported crop contexts produce safe visual candidates', () {
    final visual = LeafScreeningResult(
      riskKey: 'leaf_result_spot_risk',
      explanationKey: 'leaf_result_spot_risk_body',
      actionKey: 'leaf_action_spot',
      confidence: 78,
      greenPercent: 42,
      yellowPercent: 24,
      brownPercent: 22,
      screenedAt: DateTime.now(),
    );
    expect(CropCatalog.supported, hasLength(14));
    for (final crop in CropCatalog.supported) {
      final assessment = MultimodalDiseaseService.assess(
        visual: visual,
        crop: crop.name,
      );
      expect(assessment.candidates, isNotEmpty, reason: crop.name);
      if (crop.id != 'universal' &&
          crop.id != 'okra' &&
          crop.id != 'papaya' &&
          crop.id != 'eggplant') {
        expect(
          assessment.candidates.every(
            (candidate) => candidate.nameKey.contains(crop.id),
          ),
          isTrue,
          reason: crop.name,
        );
      }
    }
  });

  test('unknown firmware crops fall back to Universal, never Rice or Tomato', () {
    expect(CropCatalog.profileFor('New experimental crop').name, 'Universal');
    expect(CropCatalog.profileFor('').name, 'Universal');
    expect(CropCatalog.normalize('செம்பருத்தி'), 'Hibiscus');
    expect(CropCatalog.normalize('Lady finger'), 'Okra');
  });

  test('hibiscus visible whitefly observation stays a possible camera match', () {
    final assessment = MultimodalDiseaseService.assess(
      visual: LeafScreeningResult(
        riskKey: 'leaf_result_low_risk',
        explanationKey: 'leaf_result_low_risk_body',
        actionKey: 'leaf_action_monitor',
        confidence: 74,
        greenPercent: 70,
        yellowPercent: 7,
        brownPercent: 3,
        screenedAt: DateTime.now(),
      ),
      crop: 'Hibiscus',
      symptoms: const DiseaseSymptomAnswers(
        whitefliesPresent: FieldObservation.yes,
        mealybugsPresent: FieldObservation.no,
        aphidsPresent: FieldObservation.no,
        visibleSpotting: FieldObservation.no,
        surfaceDamage: FieldObservation.no,
      ),
    );

    expect(assessment.candidates.first.nameKey, 'disease_hibiscus_whitefly');
    expect(assessment.usedSensorEvidence, isFalse);
  });

  test('expected paddy flooding is not treated as generic overwatering', () {
    final ricePrompt = MultimodalDiseaseService.evaluatePhotoPrompt(
      reading(soil: 94),
      null,
      crop: 'Rice',
    );
    final tomatoPrompt = MultimodalDiseaseService.evaluatePhotoPrompt(
      reading(soil: 94),
      null,
      crop: 'Tomato',
    );
    expect(ricePrompt.reasonKeys, isNot(contains('disease_trigger_wet_soil')));
    expect(tomatoPrompt.reasonKeys, contains('disease_trigger_wet_soil'));

    final riceInsight = AiAnalysisService.analyze(
      reading(soil: 94),
      [reading(soil: 94)],
      crop: 'Rice',
    );
    final tomatoInsight = AiAnalysisService.analyze(
      reading(soil: 94),
      [reading(soil: 94)],
      crop: 'Tomato',
    );
    expect(riceInsight.headlineKey, 'ai_paddy_water_expected');
    expect(tomatoInsight.headlineKey, 'ai_overwatering');

    final riceIrrigation = IrrigationAdvisor.advise(
      reading(soil: 94),
      null,
      crop: 'Rice',
    );
    expect(riceIrrigation.titleKey, 'irrigation_paddy_water');
  });

  test('farm impact estimator calculates an honest first-season projection',
      () {
    const projection = FarmImpactProjection(
      areaAcres: 3.2,
      seasonalValuePerAcre: 60000,
      lossRiskPercent: 15,
      preventableSharePercent: 35,
      inputSavingsPerAcre: 1500,
      systemCost: 6000,
    );
    expect(projection.seasonalCropValue, closeTo(192000, 0.01));
    expect(projection.cropValueAtRisk, closeTo(28800, 0.01));
    expect(projection.estimatedLossPrevented, closeTo(10080, 0.01));
    expect(projection.estimatedInputSavings, closeTo(4800, 0.01));
    expect(projection.grossSeasonalBenefit, closeTo(14880, 0.01));
    expect(projection.firstSeasonNetBenefit, closeTo(8880, 0.01));
    expect(projection.benefitCostRatio, closeTo(2.48, 0.01));
  });
}
