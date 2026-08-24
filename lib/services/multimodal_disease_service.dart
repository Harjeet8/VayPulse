import '../models/disease_assessment.dart';
import '../models/leaf_screening_result.dart';
import '../models/sensor_reading.dart';
import '../models/weather_snapshot.dart';

/// Explainable candidate ranking based on visible colour patterns and the
/// environmental context already available to VayPulse.
///
/// This is intentionally decision support rather than a laboratory diagnosis.
/// Scores are rule-based match scores, not measured model accuracy.
class MultimodalDiseaseService {
  static DiseasePhotoPrompt evaluatePhotoPrompt(
    SensorReading? reading,
    WeatherSnapshot? weather, {
    String? crop,
  }) {
    if (reading == null && weather == null) return DiseasePhotoPrompt.none;
    final reasons = <String>[];
    var severeSignals = 0;

    if (reading != null) {
      if (reading.plantSignal < 38 || reading.plantSignal > 92) {
        reasons.add('disease_trigger_electrode');
        if (reading.plantSignal < 25 || reading.plantSignal > 97) {
          severeSignals++;
        }
      }
      if (reading.healthScore < 65) {
        reasons.add('disease_trigger_health');
        if (reading.healthScore < 45) severeSignals++;
      }
      if (reading.soilMoisture < 30) {
        reasons.add('disease_trigger_dry_soil');
        if (reading.soilMoisture < 18) severeSignals++;
      } else if (reading.soilMoisture > 88 && !_isFloodedRiceContext(crop)) {
        reasons.add('disease_trigger_wet_soil');
        if (reading.soilMoisture > 95) severeSignals++;
      }
      if (reading.temperature > 34) {
        reasons.add('disease_trigger_heat');
        if (reading.temperature > 39) severeSignals++;
      }
      if (reading.humidity > 84) {
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

  static DiseaseAssessment assess({
    required LeafScreeningResult visual,
    required String crop,
    SensorReading? reading,
    WeatherSnapshot? weather,
    DiseaseSymptomAnswers symptoms = const DiseaseSymptomAnswers(),
  }) {
    final prompt = evaluatePhotoPrompt(reading, weather, crop: crop);
    final cropName = crop.trim().toLowerCase();
    final brown = visual.brownPercent / 100;
    final yellow = visual.yellowPercent / 100;
    final green = visual.greenPercent / 100;
    final highHumidity = (reading?.humidity ?? weather?.humidity ?? 0) >= 80;
    final warm = (reading?.temperature ?? weather?.temperature ?? 25) >= 26;
    final hot = (reading?.temperature ?? weather?.temperature ?? 25) >= 33;
    final drySoil = (reading?.soilMoisture ?? 55) < 35;
    final wetSoil = (reading?.soilMoisture ?? 55) > 82;
    final lowSignal = reading == null
        ? 0.0
        : ((48 - reading.plantSignal) / 48).clamp(0.0, 1.0).toDouble();
    final diseaseWeather = weather?.diseaseRisk ?? false;
    final rainRisk = weather?.heavyRainRisk ?? false;

    final visiblyBalanced = visual.riskKey == 'leaf_result_low_risk' &&
        brown < 0.07 &&
        yellow < 0.14 &&
        green >= 0.2;
    if (visiblyBalanced && !prompt.shouldPrompt) {
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
        evidenceKeys: const ['disease_evidence_visual_balanced'],
        usedSensorEvidence: reading != null,
        usedWeatherEvidence: weather != null,
        sensorTriggered: false,
      );
    }

    final candidates = _candidatesForCrop(
      cropName,
      brown: brown,
      yellow: yellow,
      highHumidity: highHumidity,
      warm: warm,
      hot: hot,
      drySoil: drySoil,
      wetSoil: wetSoil,
      lowSignal: lowSignal,
      diseaseWeather: diseaseWeather,
      rainRisk: rainRisk,
      symptoms: symptoms,
    );

    candidates.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    final evidence = <String>['disease_evidence_camera'];
    if (reading != null) evidence.add('disease_evidence_sensor');
    if (reading != null &&
        (reading.plantSignal < 38 || reading.plantSignal > 92)) {
      evidence.add('disease_evidence_electrode');
    }
    if (weather != null) evidence.add('disease_evidence_weather');
    if (diseaseWeather) evidence.add('disease_evidence_weather_risk');
    if (cropName.contains('tomato') && symptoms.hasAnswers) {
      evidence.add('disease_evidence_farmer_observations');
    }

    final ranked = candidates.take(3).toList(growable: false);
    final isInconclusive = cropName.contains('tomato') &&
        (ranked.isEmpty ||
            ranked.first.matchScore < 60 ||
            (ranked.length > 1 &&
                ranked.first.matchScore - ranked[1].matchScore < 8));

    return DiseaseAssessment(
      crop: crop,
      candidates: ranked,
      evidenceKeys: evidence,
      usedSensorEvidence: reading != null,
      usedWeatherEvidence: weather != null,
      sensorTriggered: prompt.shouldPrompt,
      isInconclusive: isInconclusive,
    );
  }

  static List<DiseaseCandidate> _candidatesForCrop(
    String crop, {
    required double brown,
    required double yellow,
    required bool highHumidity,
    required bool warm,
    required bool hot,
    required bool drySoil,
    required bool wetSoil,
    required double lowSignal,
    required bool diseaseWeather,
    required bool rainRisk,
    required DiseaseSymptomAnswers symptoms,
  }) {
    if (crop.contains('rice') || crop.contains('paddy')) {
      return [
        _candidate(
          name: 'disease_rice_blast',
          category: 'disease_category_fungal',
          reason: 'disease_rice_blast_reason',
          inspect: 'disease_rice_blast_inspect',
          score: 18 +
              brown * 155 +
              (highHumidity ? 17 : 0) +
              (diseaseWeather ? 17 : 0) +
              (warm ? 7 : 0) +
              lowSignal * 10,
        ),
        _candidate(
          name: 'disease_rice_brown_spot',
          category: 'disease_category_fungal',
          reason: 'disease_rice_brown_spot_reason',
          inspect: 'disease_rice_brown_spot_inspect',
          score: 15 +
              brown * 130 +
              yellow * 42 +
              (drySoil ? 12 : 0) +
              lowSignal * 15,
        ),
        _candidate(
          name: 'disease_rice_blight',
          category: 'disease_category_bacterial',
          reason: 'disease_rice_blight_reason',
          inspect: 'disease_rice_blight_inspect',
          score: 12 +
              yellow * 105 +
              brown * 42 +
              (highHumidity ? 16 : 0) +
              (rainRisk || diseaseWeather ? 18 : 0) +
              (wetSoil ? 7 : 0),
        ),
        _candidate(
          name: 'disease_rice_stem_borer',
          category: 'disease_category_pest',
          reason: 'disease_rice_stem_borer_reason',
          inspect: 'disease_rice_stem_borer_inspect',
          score: 10 + yellow * 78 + lowSignal * 31 + (drySoil ? 6 : 0),
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
          score:
              12 + brown * 82 + yellow * 24 + (rings ? 42 : 0) + (warm ? 7 : 0),
        ),
        _candidate(
          name: 'disease_tomato_late_blight',
          category: 'disease_category_fungal',
          reason: 'disease_tomato_late_blight_reason',
          inspect: 'disease_tomato_late_blight_inspect',
          score: 10 +
              brown * 74 +
              (waterSoaked ? 42 : 0) +
              (highHumidity ? 16 : 0) +
              (diseaseWeather ? 16 : 0) +
              (wetSoil ? 5 : 0),
        ),
        _candidate(
          name: 'disease_tomato_bacterial_spot',
          category: 'disease_category_bacterial',
          reason: 'disease_tomato_bacterial_spot_reason',
          inspect: 'disease_tomato_bacterial_spot_inspect',
          score: 11 +
              brown * 76 +
              (halos ? 42 : 0) +
              (highHumidity ? 9 : 0) +
              (rainRisk ? 8 : 0),
        ),
        _candidate(
          name: 'disease_tomato_leaf_curl',
          category: 'disease_category_pest',
          reason: 'disease_tomato_leaf_curl_reason',
          inspect: 'disease_tomato_leaf_curl_inspect',
          score: 10 +
              yellow * 60 +
              lowSignal * 16 +
              (curling ? 32 : 0) +
              (whiteflies ? 28 : 0) +
              (hot ? 6 : 0) +
              (drySoil ? 5 : 0),
        ),
      ];
    }
    if (crop.contains('maize') || crop.contains('corn')) {
      return _threeCropCandidates(
        first: 'disease_maize_leaf_blight',
        firstCategory: 'disease_category_fungal',
        firstScore: 18 + brown * 142 + (warm ? 9 : 0) + (highHumidity ? 14 : 0),
        second: 'disease_maize_downy_mildew',
        secondCategory: 'disease_category_fungal',
        secondScore: 14 +
            yellow * 112 +
            (highHumidity ? 20 : 0) +
            (diseaseWeather ? 12 : 0),
        third: 'disease_maize_fall_armyworm',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + brown * 72 + yellow * 52 + lowSignal * 28,
      );
    }
    if (crop.contains('groundnut') || crop.contains('peanut')) {
      return _threeCropCandidates(
        first: 'disease_groundnut_leaf_spot',
        firstCategory: 'disease_category_fungal',
        firstScore: 18 + brown * 146 + yellow * 36 + (highHumidity ? 15 : 0),
        second: 'disease_groundnut_rust',
        secondCategory: 'disease_category_fungal',
        secondScore:
            14 + brown * 132 + (warm ? 10 : 0) + (diseaseWeather ? 13 : 0),
        third: 'disease_groundnut_leaf_miner',
        thirdCategory: 'disease_category_pest',
        thirdScore: 11 + yellow * 88 + brown * 52 + lowSignal * 22,
      );
    }
    if (crop.contains('cotton')) {
      return _threeCropCandidates(
        first: 'disease_cotton_bacterial_blight',
        firstCategory: 'disease_category_bacterial',
        firstScore:
            17 + brown * 138 + (rainRisk ? 18 : 0) + (highHumidity ? 14 : 0),
        second: 'disease_cotton_alternaria',
        secondCategory: 'disease_category_fungal',
        secondScore: 15 + brown * 132 + yellow * 34 + (warm ? 8 : 0),
        third: 'disease_cotton_sucking_pest',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 112 + (hot ? 10 : 0) + lowSignal * 25,
      );
    }
    if (crop.contains('sugarcane') || crop.contains('sugar cane')) {
      return _threeCropCandidates(
        first: 'disease_sugarcane_red_rot',
        firstCategory: 'disease_category_fungal',
        firstScore: 18 + yellow * 86 + brown * 78 + lowSignal * 24,
        second: 'disease_sugarcane_smut',
        secondCategory: 'disease_category_fungal',
        secondScore: 13 + yellow * 104 + (drySoil ? 10 : 0) + lowSignal * 20,
        third: 'disease_sugarcane_shoot_borer',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 92 + brown * 42 + lowSignal * 28,
      );
    }
    if (crop.contains('banana') || crop.contains('plantain')) {
      return _threeCropCandidates(
        first: 'disease_banana_sigatoka',
        firstCategory: 'disease_category_fungal',
        firstScore: 18 + brown * 148 + yellow * 36 + (highHumidity ? 17 : 0),
        second: 'disease_banana_bunchy_top',
        secondCategory: 'disease_category_viral',
        secondScore: 14 + yellow * 116 + lowSignal * 24,
        third: 'disease_banana_weevil',
        thirdCategory: 'disease_category_pest',
        thirdScore: 11 + yellow * 72 + brown * 48 + lowSignal * 30,
      );
    }
    if (crop.contains('coconut')) {
      return _threeCropCandidates(
        first: 'disease_coconut_leaf_rot',
        firstCategory: 'disease_category_fungal',
        firstScore:
            17 + brown * 142 + (highHumidity ? 18 : 0) + (rainRisk ? 10 : 0),
        second: 'disease_coconut_bud_rot',
        secondCategory: 'disease_category_fungal',
        secondScore: 13 + yellow * 74 + brown * 82 + (diseaseWeather ? 18 : 0),
        third: 'disease_coconut_caterpillar',
        thirdCategory: 'disease_category_pest',
        thirdScore: 11 + brown * 82 + yellow * 58 + lowSignal * 24,
      );
    }
    if (crop.contains('brinjal') || crop.contains('eggplant')) {
      return _threeCropCandidates(
        first: 'disease_brinjal_leaf_spot',
        firstCategory: 'disease_category_fungal',
        firstScore: 17 + brown * 144 + (highHumidity ? 15 : 0),
        second: 'disease_brinjal_little_leaf',
        secondCategory: 'disease_category_phytoplasma',
        secondScore: 13 + yellow * 118 + lowSignal * 24,
        third: 'disease_brinjal_shoot_borer',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 78 + brown * 54 + lowSignal * 27,
      );
    }
    if (crop.contains('chilli') ||
        crop.contains('chili') ||
        crop.contains('pepper')) {
      return _threeCropCandidates(
        first: 'disease_chilli_leaf_curl',
        firstCategory: 'disease_category_viral',
        firstScore: 16 + yellow * 122 + (hot ? 10 : 0) + lowSignal * 27,
        second: 'disease_chilli_anthracnose',
        secondCategory: 'disease_category_fungal',
        secondScore: 17 + brown * 146 + (highHumidity ? 15 : 0),
        third: 'disease_chilli_thrips',
        thirdCategory: 'disease_category_pest',
        thirdScore: 12 + yellow * 96 + (drySoil ? 8 : 0) + lowSignal * 23,
      );
    }
    return _threeCropCandidates(
      first: 'disease_generic_leaf_spot',
      firstCategory: 'disease_category_fungal',
      firstScore: 18 +
          brown * 148 +
          (highHumidity ? 17 : 0) +
          (diseaseWeather ? 16 : 0),
      second: 'disease_generic_pest_damage',
      secondCategory: 'disease_category_pest',
      secondScore: 12 + yellow * 78 + lowSignal * 30,
      third: 'disease_generic_water_stress',
      thirdCategory: 'disease_category_stress',
      thirdScore:
          13 + yellow * 105 + (drySoil || wetSoil ? 24 : 0) + (hot ? 12 : 0),
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
