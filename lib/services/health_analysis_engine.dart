import 'dart:math' as math;

import '../models/crop_health_profile.dart';
import '../models/phytosense_health_result.dart';
import '../models/sensor_reading.dart';

/// Offline, deterministic and explainable crop-condition analysis.
///
/// The number produced here is a decision-support index, not a laboratory
/// measurement of biological health. Missing channels are excluded rather
/// than scored as zero and separately reduce analysis confidence.
class HealthAnalysisEngine {
  static PhytoSenseHealthResult analyze(
    SensorReading reading,
    List<SensorReading> history, {
    String crop = 'Tomato',
    String growthStage = 'vegetative',
  }) {
    final profile = CropHealthProfile.forCrop(
      crop,
      growthStage: growthStage,
    );
    final recent = history.length <= 12
        ? history
        : history.sublist(history.length - 12);

    final water = reading.soilMoistureAvailable
        ? _persistentRangeScore(
            reading.soilMoisture,
            profile.calibratedSoilMoisture,
            recent
                .where((r) => r.soilMoistureAvailable)
                .map((r) => r.soilMoisture),
          )
        : null;

    final temperatureRange = reading.daytime
        ? profile.dayAirTemperature
        : profile.nightAirTemperature;
    final thermal = reading.temperatureAvailable
        ? _persistentRangeScore(
            reading.temperature,
            temperatureRange,
            recent
                .where((r) => r.temperatureAvailable)
                .map((r) => r.temperature),
          )
        : null;

    final rootZone = reading.soilTemperatureAvailable &&
            reading.soilTemperature != null
        ? _rangeScore(reading.soilTemperature!, profile.rootZoneTemperature)
        : null;

    final atmospheric = reading.humidityAvailable
        ? _rangeScore(reading.humidity, profile.humidity)
        : null;

    final light = !reading.daytime
        ? null
        : reading.lightAvailable && reading.lightLux != null
            ? _persistentRangeScore(
                reading.lightLux!,
                profile.daylightLux,
                recent
                    .where((r) => r.lightAvailable && r.lightLux != null)
                    .map((r) => r.lightLux!),
              )
            : null;

    final diseaseRisk = _diseaseRisk(reading);
    final bioelectric = _bioelectricStability(reading, recent);

    var weightedTotal = 0.0;
    var usedWeight = 0.0;
    void add(double? score, double weight) {
      if (score == null || !score.isFinite) return;
      weightedTotal += score.clamp(0.0, 100.0).toDouble() * weight;
      usedWeight += weight;
    }

    add(water, 0.30);
    add(thermal, 0.19);
    add(rootZone, 0.10);
    add(atmospheric, 0.08);
    if (reading.daytime) add(light, 0.08);
    add(diseaseRisk == null ? null : 100.0 - diseaseRisk, 0.13);
    add(bioelectric, 0.12);

    var index = usedWeight <= 0 ? 50.0 : weightedTotal / usedWeight;

    if (recent.isNotEmpty) {
      final previous = recent.last.healthScore;
      if (previous.isFinite) index = previous * 0.22 + index * 0.78;
    }
    index = index.clamp(0.0, 100.0).toDouble();

    final confidence = _confidence(reading, recent);
    final reasons = <String>[];
    final recommendations = <String>[];

    if (water != null) {
      if (water < 60 &&
          reading.soilMoisture < profile.calibratedSoilMoisture.idealLow) {
        reasons.add(
          'Soil moisture has remained below the preferred calibrated range.',
        );
        recommendations.add(
          'Check the tomato root zone and consider irrigation only after confirming the pot is actually dry.',
        );
      } else if (water < 60 &&
          reading.soilMoisture > profile.calibratedSoilMoisture.idealHigh) {
        reasons.add(
          'Soil moisture has remained above the preferred calibrated range.',
        );
        recommendations.add(
          'Check drainage and pause unnecessary watering until the root zone is inspected.',
        );
      } else {
        reasons.add(
          'Soil moisture is close to the preferred calibrated range.',
        );
      }
    } else {
      reasons.add(
        'Soil-moisture data is unavailable and was excluded from the index.',
      );
    }

    if (thermal != null) {
      if (thermal < 60) {
        reasons.add(
          'Air temperature is outside the preferred ${reading.daytime ? 'daytime' : 'night-time'} range.',
        );
        recommendations.add(
          'Check soil moisture, airflow, shade and visible temperature-stress symptoms.',
        );
      } else {
        reasons.add(
          'Air temperature is within the broad operating range for the selected crop stage.',
        );
      }
    }

    if (diseaseRisk != null) {
      if (diseaseRisk >= 50) {
        final hours = reading.recentWetExposureSeconds / 3600.0;
        reasons.add(
          'Leaf wetness and humid conditions have created a ${_riskLabel(diseaseRisk)} disease-conducive environment${hours > 0.2 ? ' (${hours.toStringAsFixed(1)} h recent wet exposure)' : ''}.',
        );
        recommendations.add(
          'Improve airflow and monitor leaves for symptoms. Environmental risk alone does not confirm infection.',
        );
      } else {
        reasons.add(
          'Current leaf-wetness conditions indicate low to moderate disease-conducive risk.',
        );
      }
    }

    if (reading.plantSignalAvailable && !reading.bioIsPresentation) {
      if (!reading.bioBaselineReady) {
        reasons.add(
          'Plant electrical baseline is still learning, so this channel has limited influence.',
        );
      } else if (bioelectric != null && bioelectric < 60) {
        reasons.add(
          'Plant electrical activity has shifted from its learned baseline.',
        );
        recommendations.add(
          'Check electrode contact and compare other sensors before interpreting the electrical change as stress.',
        );
      } else if (bioelectric != null) {
        reasons.add(
          'Plant electrical activity remains reasonably close to its learned baseline.',
        );
      }
    }

    if (confidence < 70) {
      recommendations.add(
        'Treat this result cautiously because sensor availability, calibration or history currently limits confidence.',
      );
    }

    return PhytoSenseHealthResult(
      healthIndex: index,
      healthStatus: SensorReading.statusForHealth(index),
      confidence: confidence,
      waterScore: water,
      thermalScore: thermal,
      rootZoneScore: rootZone,
      atmosphericScore: atmospheric,
      lightScore: light,
      diseaseRisk: diseaseRisk,
      bioelectricStability: bioelectric,
      reasons: reasons,
      recommendations: recommendations.toSet().toList(growable: false),
      timestamp: reading.timestamp,
    );
  }

  static SensorReading apply(
    SensorReading reading,
    List<SensorReading> history, {
    String crop = 'Tomato',
    String growthStage = 'vegetative',
  }) {
    final result = analyze(
      reading,
      history,
      crop: crop,
      growthStage: growthStage,
    );
    return reading.copyWith(
      healthScore: result.healthIndex,
      stressScore: 100.0 - result.healthIndex,
      healthStatus: result.healthStatus,
      analysisConfidence: result.confidence,
      waterScore: result.waterScore,
      thermalScore: result.thermalScore,
      rootZoneScore: result.rootZoneScore,
      atmosphericScore: result.atmosphericScore,
      lightScore: result.lightScore,
      diseaseRisk: result.diseaseRisk,
      bioelectricStability: result.bioelectricStability,
      plantSignal: result.bioelectricStability ?? reading.plantSignal,
    );
  }

  static double _rangeScore(double value, HealthRange range) {
    if (!value.isFinite) return 0.0;
    if (value >= range.idealLow && value <= range.idealHigh) return 100.0;
    if (value <= range.criticalLow || value >= range.criticalHigh) return 10.0;
    if (value < range.idealLow) {
      if (value <= range.warningLow) {
        return _lerp(
          10,
          65,
          _fraction(value, range.criticalLow, range.warningLow),
        );
      }
      return _lerp(
        65,
        100,
        _fraction(value, range.warningLow, range.idealLow),
      );
    }
    if (value >= range.warningHigh) {
      return _lerp(
        65,
        10,
        _fraction(value, range.warningHigh, range.criticalHigh),
      );
    }
    return _lerp(
      100,
      65,
      _fraction(value, range.idealHigh, range.warningHigh),
    );
  }

  static double _persistentRangeScore(
    double value,
    HealthRange range,
    Iterable<double> history,
  ) {
    final immediate = _rangeScore(value, range);
    final values = history.where((v) => v.isFinite).toList(growable: false);
    if (values.length < 3 || immediate >= 90) return immediate;
    final abnormal = values.where((v) => _rangeScore(v, range) < 70).length;
    final persistence = abnormal / values.length;
    final fullPenalty = 100.0 - immediate;
    return (100.0 - fullPenalty * (0.40 + 0.60 * persistence))
        .clamp(0.0, 100.0)
        .toDouble();
  }

  static double? _diseaseRisk(SensorReading reading) {
    if (!reading.leafWetnessAvailable || reading.leafWetness == null) {
      return null;
    }
    var risk = reading.leafWetness! * 0.28;
    final wetHours = reading.recentWetExposureSeconds / 3600.0;
    risk += math.min(42.0, wetHours * 7.0).toDouble();
    if (reading.temperatureAvailable &&
        reading.temperature >= 18 &&
        reading.temperature <= 30) {
      risk += 8.0;
    }
    if (reading.humidityAvailable && reading.humidity >= 80) risk += 10.0;
    if (reading.leafWetness! < 40) risk *= 0.82;
    return risk.clamp(0.0, 100.0).toDouble();
  }

  static double? _bioelectricStability(
    SensorReading reading,
    List<SensorReading> history,
  ) {
    if (!reading.plantSignalAvailable || reading.bioIsPresentation) return null;
    if (reading.bioelectricStability != null &&
        reading.bioelectricStability!.isFinite) {
      final quality =
          reading.bioSignalQuality.clamp(0.0, 100.0).toDouble() / 100.0;
      return (reading.bioelectricStability! * (0.65 + 0.35 * quality))
          .clamp(0.0, 100.0)
          .toDouble();
    }
    if (!reading.bioBaselineReady ||
        reading.bioBaselineMv == null ||
        reading.plantVoltageMv == null) {
      return null;
    }
    final deviation =
        (reading.plantVoltageMv! - reading.bioBaselineMv!).abs();
    final noise = math.max(1.0, reading.bioNoiseMv ?? 2.0).toDouble();
    final normalized = deviation / (noise * 4.0);
    var score = (100.0 - normalized * 35.0)
        .clamp(0.0, 100.0)
        .toDouble();
    final recentBio =
        history.where((r) => r.bioDeviationMv != null).toList(growable: false);
    if (recentBio.length >= 3) {
      final repeated = recentBio
          .where((r) => r.bioDeviationMv!.abs() > noise * 4.0)
          .length;
      if (repeated < 2) score = math.max(score, 70.0).toDouble();
    }
    return score;
  }

  static double _confidence(
    SensorReading reading,
    List<SensorReading> history,
  ) {
    const weights = <String, double>{
      'soil': 20,
      'airTemp': 16,
      'humidity': 10,
      'light': 10,
      'root': 12,
      'leaf': 14,
      'bio': 10,
    };
    var available = 0.0;
    if (reading.soilMoistureAvailable) available += weights['soil']!;
    if (reading.temperatureAvailable) available += weights['airTemp']!;
    if (reading.humidityAvailable) available += weights['humidity']!;
    if (!reading.daytime || reading.lightAvailable) available += weights['light']!;
    if (reading.soilTemperatureAvailable) available += weights['root']!;
    if (reading.leafWetnessAvailable) available += weights['leaf']!;
    if (reading.plantSignalAvailable &&
        reading.bioBaselineReady &&
        !reading.bioIsPresentation) {
      final quality =
          reading.bioSignalQuality.clamp(0.0, 100.0).toDouble() / 100.0;
      available += weights['bio']! * quality;
    }

    var confidence = 12.0 + available;
    if (reading.soilMoistureAvailable && !reading.soilCalibrated) {
      confidence -= 8.0;
    }
    if (reading.leafWetnessAvailable && !reading.leafCalibrated) {
      confidence -= 6.0;
    }
    confidence += math.min(12.0, history.length * 1.2).toDouble();
    final age = DateTime.now().difference(reading.timestamp).abs();
    if (age > const Duration(seconds: 15)) confidence -= 20.0;
    return confidence.clamp(20.0, 100.0).toDouble();
  }

  static String _riskLabel(double risk) => risk < 25
      ? 'low'
      : risk < 50
          ? 'moderate'
          : risk < 75
              ? 'elevated'
              : 'high';

  static double _fraction(double value, double low, double high) => high == low
      ? 0.0
      : ((value - low) / (high - low)).clamp(0.0, 1.0).toDouble();

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
