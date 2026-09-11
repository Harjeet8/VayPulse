import '../models/disease_assessment.dart';
import '../models/leaf_screening_result.dart';
import '../models/sensor_reading.dart';
import '../models/weather_snapshot.dart';

/// Camera-side visual decision support.
///
/// Sensor evidence may recommend that the farmer opens the camera workflow via
/// [evaluatePhotoPrompt], but it is deliberately NOT used to rank visual
/// disease/pest candidates in [assess]. This keeps ESP32 sensor evidence and
/// camera evidence independent, as required by the PhytoSense architecture.
///
/// Scores are rule-based visual match scores, not laboratory diagnoses or
/// measured model accuracy.
class MultimodalDiseaseService {
  /// Sensor-side inspection prompt only. This never identifies a disease.
  static DiseasePhotoPrompt evaluatePhotoPrompt(
    SensorReading? reading,
    WeatherSnapshot? weather, {
    String? crop,
  }) {
    if (reading == null && weather == null) return DiseasePhotoPrompt.none;
    final reasons = <String>[];
    var severeSignals = 0;

    if (reading != null) {
      if (reading.plantSignalAvailable &&
          (reading.plantSignal < 38 || reading.plantSignal > 92)) {
        reasons.add('disease_trigger_electrode');
        if (reading.plantSignal < 25 || reading.plantSignal > 97) {
          severeSignals++;
        }
      }
      if (reading.soilMoistureAvailable && reading.soilMoisture < 30) {
        reasons.add('disease_trigger_dry_soil');
        if (reading.soilMoisture < 18) severeSignals++;
      } else if (reading.soilMoistureAvailable &&
          reading.soilMoisture > 88 &&
          !_isFloodedRiceContext(crop)) {
        reasons.add('disease_trigger_wet_soil');
        if (reading.soilMoisture > 95) severeSignals++;
      }
      if (reading.temperatureAvailable && reading.temperature > 34) {
        reasons.add('disease_trigger_heat');
        if (reading.temperature > 39) severeSignals++;
      }
      if (reading.humidityAvailable && reading.humidity > 84) {
        reasons.add('disease_trigger_humidity');
      }
    }
    if (weather?.diseaseRisk ?? false) {
      reasons.add('disease_trigger_weather');
    }

    return DiseasePhotoPrompt(
      shouldPrompt: reasons.isNotEmpty,
      urgent: severeSignals > 0 || reasons.length >= 3,
      reasonKeys: reasons.take(3).toList(growable: false),
    );
  }

  /// Ranks visible candidates using visual evidence and explicit farmer
  /// observations only. Sensor/weather values are intentionally excluded.
  static DiseaseAssessment assess({
    required LeafScreeningResult visual,
    required String crop,
    DiseaseSymptomAnswers symptoms = const DiseaseSymptomAnswers(),
  }) {
    final cropName = crop.trim().toLowerCase();
    final brown = visual.brownPercent / 100;
    final yellow = visual.yellowPercent / 100;
    final green = visual.greenPercent / 100;

    final visiblyBalanced = visual.riskKey == 'leaf_result_low_risk' &&
        brown < 0.07 &&
        yellow < 0.14 &&
        green >= 0.2 &&
        !symptoms.hasPositiveObservation;
    if (visiblyBalanced) {
      return DiseaseAssessment(
        crop: crop,
        candidates: const [
          DiseaseCandidate(
            nameKey: 'disease_no_clear_match',
            categoryKey: 'disease_category_clear',
            reasonKey: 'disease_no_clear_match_reason',
            inspectionKey: 'disease_no_clear_match_inspect',
            matchScore: 88,
          ),
        ],
        evidenceKeys: const [
          'disease_evidence_camera',
          'disease_evidence_visual_balanced'
        ],
        usedSensorEvidence: false,
        usedWeatherEvidence: false,
        sensorTriggered: false,
      );
    }

    final candidates = _candidatesForCrop(
      cropName,
      brown: brown,
      yellow: yellow,
      green: green,
      symptoms: symptoms,
    )..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    final evidence = <String>['disease_evidence_camera'];
    if ((cropName.contains('tomato') || cropName.contains('hibiscus')) &&
        symptoms.hasAnswers) {
      evidence.add('disease_evidence_farmer_observations');
    }

    final ranked = candidates.take(3).toList(growable: false);
    final isInconclusive = ranked.isEmpty ||
        ranked.first.matchScore < 60 ||
        (ranked.length > 1 &&
            ranked.first.matchScore - ranked[1].matchScore < 8);

    return DiseaseAssessment(
      crop: crop,
      candidates: ranked,
      evidenceKeys: evidence,
      usedSensorEvidence: false,
      usedWeatherEvidence: false,
      sensorTriggered: false,
      isInconclusive: isInconclusive,
    );
  }

  static List<DiseaseCandidate> _candidatesForCrop(
    String crop, {
    required double brown,
    required double yellow,
    required double green,
    required DiseaseSymptomAnswers symptoms,
  }) {
    if (crop.contains('rice') || crop.contains('paddy')) {
      return [
        _candidate(
          name: 'disease_rice_blast',
          category: 'disease_category_fungal',
          reason: 'disease_rice_blast_reason',
          inspect: 'disease_rice_blast_inspect',
          score: 22 + brown * 165 + yellow * 18,
        ),
        _candidate(
          name: 'disease_rice_brown_spot',
          category: 'disease_category_fungal',
          reason: 'disease_rice_brown_spot_reason',
          inspect: 'disease_rice_brown_spot_inspect',
          score: 18 + brown * 132 + yellow * 48,
        ),
        _candidate(
          name: 'disease_rice_blight',
          category: 'disease_category_bacterial',
          reason: 'disease_rice_blight_reason',
          inspect: 'disease_rice_blight_inspect',
          score: 14 + yellow * 118 + brown * 36,
        ),
        _candidate(
          name: 'disease_rice_stem_borer',
          category: 'disease_category_pest',
          reason: 'disease_rice_stem_borer_reason',
          inspect: 'disease_rice_stem_borer_inspect',
          score: 12 + yellow * 92 + brown * 28,
        ),
      ];
    }

    if (crop.contains('tomato')) {
      final rings = symptoms.concentricRings == FieldObservation.yes;
      final waterSoaked = symptoms.waterSoakedLesions == FieldObservation.yes;
      final halos = symptoms.yellowHalos == FieldObservation.yes;
      final curling = symptoms.leafCurling == FieldObservation.yes;
      final whiteflies = symptoms.whitefliesPresent == FieldObservation.yes;
      return [
        _candidate(
          name: 'disease_tomato_early_blight',
          category: 'disease_category_fungal',
          reason: 'disease_tomato_early_blight_reason',
          inspect: 'disease_tomato_early_blight_inspect',
          score: 12 + brown * 88 + yellow * 22 + (rings ? 50 : 0),
        ),
        _candidate(
          name: 'disease_tomato_late_blight',
          category: 'disease_category_fungal',
          reason: 'disease_tomato_late_blight_reason',
          inspect: 'disease_tomato_late_blight_inspect',
          score: 10 + brown * 82 + (waterSoaked ? 52 : 0),
        ),
        _candidate(
          name: 'disease_tomato_bacterial_spot',
          category: 'disease_category_bacterial',
          reason: 'disease_tomato_bacterial_spot_reason',
          inspect: 'disease_tomato_bacterial_spot_inspect',
          score: 11 + brown * 80 + (halos ? 50 : 0),
        ),
        _candidate(
          name: 'disease_tomato_leaf_curl',
          category: 'disease_category_pest',
          reason: 'disease_tomato_leaf_curl_reason',
          inspect: 'disease_tomato_leaf_curl_inspect',
          score: 10 + yellow * 70 + (curling ? 40 : 0) + (whiteflies ? 34 : 0),
        ),
      ];
    }

    if (crop.contains('hibiscus')) {
      final whiteflies = symptoms.whitefliesPresent == FieldObservation.yes;
      final mealybugs = symptoms.mealybugsPresent == FieldObservation.yes;
      final aphids = symptoms.aphidsPresent == FieldObservation.yes;
      final spots = symptoms.visibleSpotting == FieldObservation.yes;
      final damage = symptoms.surfaceDamage == FieldObservation.yes;
      return [
        _candidate(
          name: 'disease_hibiscus_whitefly',
          category: 'disease_category_pest',
          reason: 'disease_hibiscus_whitefly_reason',
          inspect: 'disease_hibiscus_whitefly_inspect',
          score: 8 + yellow * 42 + (whiteflies ? 58 : 0),
        ),
        _candidate(
          name: 'disease_hibiscus_mealybug',
          category: 'disease_category_pest',
          reason: 'disease_hibiscus_mealybug_reason',
          inspect: 'disease_hibiscus_mealybug_inspect',
          score: 8 + (1 - green) * 24 + (mealybugs ? 62 : 0),
        ),
        _candidate(
          name: 'disease_hibiscus_aphid',
          category: 'disease_category_pest',
          reason: 'disease_hibiscus_aphid_reason',
          inspect: 'disease_hibiscus_aphid_inspect',
          score: 8 + yellow * 35 + (aphids ? 60 : 0),
        ),
        _candidate(
          name: 'disease_hibiscus_visible_symptom',
          category: 'disease_category_fungal',
          reason: 'disease_hibiscus_visible_symptom_reason',
          inspect: 'disease_hibiscus_visible_symptom_inspect',
          score: 8 + brown * 56 + (spots ? 38 : 0) + (damage ? 26 : 0),
        ),
      ];
    }

    if (crop.contains('maize') || crop.contains('corn')) {
      return _threeCropCandidates(
        first: 'disease_maize_leaf_blight',
        firstCategory: 'disease_category_fungal',
        firstScore: 20 + brown * 150 + yellow * 18,
        second: 'disease_maize_downy_mildew',
        secondCategory: 'disease_category_fungal',
        secondScore: 14 + yellow * 124 + (1 - green) * 18,
        third: 'disease_maize_fall_armyworm',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + brown * 78 + yellow * 58,
      );
    }
    if (crop.contains('groundnut') || crop.contains('peanut')) {
      return _threeCropCandidates(
        first: 'disease_groundnut_leaf_spot',
        firstCategory: 'disease_category_fungal',
        firstScore: 20 + brown * 154 + yellow * 32,
        second: 'disease_groundnut_rust',
        secondCategory: 'disease_category_fungal',
        secondScore: 15 + brown * 138 + yellow * 18,
        third: 'disease_groundnut_leaf_miner',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 96 + brown * 46,
      );
    }
    if (crop.contains('cotton')) {
      return _threeCropCandidates(
        first: 'disease_cotton_bacterial_blight',
        firstCategory: 'disease_category_bacterial',
        firstScore: 18 + brown * 144 + yellow * 24,
        second: 'disease_cotton_alternaria',
        secondCategory: 'disease_category_fungal',
        secondScore: 16 + brown * 136 + yellow * 34,
        third: 'disease_cotton_sucking_pest',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 124 + brown * 18,
      );
    }
    if (crop.contains('sugarcane') || crop.contains('sugar cane')) {
      return _threeCropCandidates(
        first: 'disease_sugarcane_red_rot',
        firstCategory: 'disease_category_fungal',
        firstScore: 20 + yellow * 92 + brown * 84,
        second: 'disease_sugarcane_smut',
        secondCategory: 'disease_category_fungal',
        secondScore: 14 + yellow * 112 + brown * 22,
        third: 'disease_sugarcane_shoot_borer',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 98 + brown * 46,
      );
    }
    if (crop.contains('banana') || crop.contains('plantain')) {
      return _threeCropCandidates(
        first: 'disease_banana_sigatoka',
        firstCategory: 'disease_category_fungal',
        firstScore: 20 + brown * 154 + yellow * 34,
        second: 'disease_banana_bunchy_top',
        secondCategory: 'disease_category_viral',
        secondScore: 14 + yellow * 126 + (1 - green) * 16,
        third: 'disease_banana_weevil',
        thirdCategory: 'disease_category_pest',
        thirdScore: 11 + yellow * 76 + brown * 58,
      );
    }
    if (crop.contains('coconut')) {
      return _threeCropCandidates(
        first: 'disease_coconut_leaf_rot',
        firstCategory: 'disease_category_fungal',
        firstScore: 18 + brown * 150 + yellow * 28,
        second: 'disease_coconut_bud_rot',
        secondCategory: 'disease_category_fungal',
        secondScore: 14 + yellow * 78 + brown * 92,
        third: 'disease_coconut_caterpillar',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + brown * 90 + yellow * 62,
      );
    }
    if (crop.contains('brinjal') || crop.contains('eggplant')) {
      return _threeCropCandidates(
        first: 'disease_brinjal_leaf_spot',
        firstCategory: 'disease_category_fungal',
        firstScore: 19 + brown * 150 + yellow * 22,
        second: 'disease_brinjal_little_leaf',
        secondCategory: 'disease_category_phytoplasma',
        secondScore: 14 + yellow * 128 + (1 - green) * 14,
        third: 'disease_brinjal_shoot_borer',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 84 + brown * 60,
      );
    }
    if (crop.contains('chilli') ||
        crop.contains('chili') ||
        crop.contains('pepper')) {
      return _threeCropCandidates(
        first: 'disease_chilli_leaf_curl',
        firstCategory: 'disease_category_viral',
        firstScore: 17 + yellow * 132 + (1 - green) * 18,
        second: 'disease_chilli_anthracnose',
        secondCategory: 'disease_category_fungal',
        secondScore: 19 + brown * 154 + yellow * 18,
        third: 'disease_chilli_thrips',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 106 + brown * 32,
      );
    }

    return _threeCropCandidates(
      first: 'disease_generic_leaf_spot',
      firstCategory: 'disease_category_fungal',
      firstScore: 20 + brown * 152 + yellow * 20,
      second: 'disease_generic_pest_damage',
      secondCategory: 'disease_category_pest',
      secondScore: 13 + yellow * 86 + brown * 56,
      third: 'disease_generic_water_stress',
      thirdCategory: 'disease_category_stress',
      thirdScore: 12 + yellow * 112 + (1 - green) * 16,
    );
  }

  static bool _isFloodedRiceContext(String? crop) {
    final value = crop?.trim().toLowerCase() ?? '';
    return value.contains('rice') || value.contains('paddy');
  }

  static List<DiseaseCandidate> _threeCropCandidates({
    required String first,
    required String firstCategory,
    required double firstScore,
    required String second,
    required String secondCategory,
    required double secondScore,
    required String third,
    required String thirdCategory,
    required double thirdScore,
  }) =>
      [
        _candidate(
          name: first,
          category: firstCategory,
          reason: '${first}_reason',
          inspect: '${first}_inspect',
          score: firstScore,
        ),
        _candidate(
          name: second,
          category: secondCategory,
          reason: '${second}_reason',
          inspect: '${second}_inspect',
          score: secondScore,
        ),
        _candidate(
          name: third,
          category: thirdCategory,
          reason: '${third}_reason',
          inspect: '${third}_inspect',
          score: thirdScore,
        ),
      ];

  static DiseaseCandidate _candidate({
    required String name,
    required String category,
    required String reason,
    required String inspect,
    required double score,
  }) =>
      DiseaseCandidate(
        nameKey: name,
        categoryKey: category,
        reasonKey: reason,
        inspectionKey: inspect,
        matchScore: score.clamp(18, 96).round(),
      );
}
