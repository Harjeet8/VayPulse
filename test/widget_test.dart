import 'package:flutter_test/flutter_test.dart';

import 'package:phytosense_ai/models/farm_impact_projection.dart';
import 'package:phytosense_ai/models/crop_catalog.dart';
import 'package:phytosense_ai/models/disease_assessment.dart';
import 'package:phytosense_ai/models/leaf_screening_result.dart';
import 'package:phytosense_ai/models/app_settings.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';
import 'package:phytosense_ai/models/weather_snapshot.dart';
import 'package:phytosense_ai/services/ai_analysis_service.dart';
import 'package:phytosense_ai/services/engineering_evidence_service.dart';
import 'package:phytosense_ai/services/irrigation_advisor.dart';
import 'package:phytosense_ai/services/location_name_resolver.dart';
import 'package:phytosense_ai/services/multimodal_disease_service.dart';
import 'package:phytosense_ai/services/sensor_data_provider.dart';
import 'package:phytosense_ai/services/sensor_provider_manager.dart';

void main() {
  test('new installs start in the farmer-safe experience', () {
    final settings = AppSettings();
    expect(settings.experienceMode, 'farmer');
    expect(settings.largeText, isFalse);
    expect(settings.reducedMotion, isFalse);
    expect(settings.dataSource, 'simulation');
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

  test('legacy persisted sensor JSON receives a calculated health score', () {
    final result = SensorReading.fromJson({
      'soilMoisture': 62,
      'temperature': 25,
      'humidity': 58,
      'light': 68,
      'plantSignal': 70,
    });
    expect(result.healthScore, greaterThan(95));
    expect(result.nodeId, 'PHYTO-NODE-001');
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
    expect(manager.selectedNodeId, 'PHYTO-NODE-001');
    expect(manager.selectedNodeId, isNot(demoNodeId));
    expect(manager.supportsScenarios, isFalse);
    expect(manager.scenarioIds, isEmpty);
    expect(manager.current, isNull);
    manager.setScenario('drought');
    expect(manager.current, isNull);
    manager.dispose();
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

  test('rice screening ranks blast first for brown humid rain evidence', () {
    final weather = WeatherSnapshot(
      location: 'Test farm',
      updatedAt: DateTime.now(),
      temperature: 28,
      humidity: 88,
      windSpeed: 5,
      weatherCode: 63,
      forecast: [
        WeatherDay(
          date: DateTime.now(),
          minimumTemperature: 23,
          maximumTemperature: 30,
          precipitationProbability: 86,
          precipitationMillimetres: 10,
          weatherCode: 63,
        ),
      ],
    );
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
      reading: reading(
        temperature: 28,
        humidity: 88,
        plantSignal: 28,
        health: 57,
      ),
      weather: weather,
    );
    expect(assessment.candidates.first.nameKey, 'disease_rice_blast');
    expect(assessment.usedSensorEvidence, isTrue);
    expect(assessment.usedWeatherEvidence, isTrue);
  });

  test('tomato yellowing plus low plant response ranks leaf curl first', () {
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
      reading: reading(
        soil: 28,
        temperature: 36,
        plantSignal: 24,
        health: 50,
      ),
    );
    expect(
      assessment.candidates.first.nameKey,
      'disease_tomato_leaf_curl',
    );
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
      reading: reading(temperature: 29, humidity: 72, health: 66),
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
      reading: reading(soil: 86, humidity: 88, temperature: 27),
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
      reading: reading(temperature: 34, plantSignal: 30, health: 58),
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

  test('all ten Tamil Nadu crop contexts produce crop-specific candidates', () {
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
        reading: reading(
          soil: 42,
          temperature: 30,
          humidity: 82,
          plantSignal: 32,
          health: 58,
        ),
      );
      expect(assessment.candidates, isNotEmpty, reason: crop.name);
      expect(
        assessment.candidates.every(
          (candidate) => candidate.nameKey.contains(crop.id),
        ),
        isTrue,
        reason: crop.name,
      );
    }
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
