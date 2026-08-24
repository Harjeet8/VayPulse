import '../models/sensor_reading.dart';

enum InsightLevel { healthy, attention, urgent }

class AiAnalysisResult {
  final String headlineKey;
  final String explanationKey;
  final String recommendationKey;
  final String evidenceKey;
  final InsightLevel level;
  final int confidence;

  const AiAnalysisResult({
    required this.headlineKey,
    required this.explanationKey,
    required this.recommendationKey,
    required this.evidenceKey,
    required this.level,
    required this.confidence,
  });
}

class AiAnalysisService {
  static AiAnalysisResult analyze(
    SensorReading reading,
    List<SensorReading> history, {
    String crop = '',
  }) {
    final confidence = (70 + (history.length * 2).clamp(0, 24)).toInt();
    final cropName = crop.toLowerCase();
    final isFloodedRice =
        cropName.contains('rice') || cropName.contains('paddy');

    if (reading.soilMoisture < 20 && reading.temperature > 31) {
      return AiAnalysisResult(
        headlineKey: 'ai_combined_stress',
        explanationKey: 'ai_combined_stress_explanation',
        recommendationKey: 'ai_combined_stress_action',
        evidenceKey: 'evidence_dry_hot',
        level: InsightLevel.urgent,
        confidence: confidence,
      );
    }
    if (reading.soilMoisture < 30) {
      return AiAnalysisResult(
        headlineKey: 'ai_water_stress',
        explanationKey: 'ai_water_stress_explanation',
        recommendationKey: 'ai_water_stress_action',
        evidenceKey: 'evidence_low_soil',
        level: reading.soilMoisture < 18
            ? InsightLevel.urgent
            : InsightLevel.attention,
        confidence: confidence,
      );
    }
    if (history.length >= 6) {
      final recent = history.sublist(history.length - 6);
      final moistureDrop = recent.first.soilMoisture - recent.last.soilMoisture;
      if (moistureDrop >= 10 && reading.soilMoisture < 45) {
        return AiAnalysisResult(
          headlineKey: 'ai_early_water_stress',
          explanationKey: 'ai_early_water_stress_explanation',
          recommendationKey: 'ai_early_water_stress_action',
          evidenceKey: 'evidence_falling_soil',
          level: InsightLevel.attention,
          confidence: confidence,
        );
      }
    }
    if (reading.plantSignal < 25 && reading.soilMoisture < 45) {
      return AiAnalysisResult(
        headlineKey: 'ai_signal_stress',
        explanationKey: 'ai_signal_stress_explanation',
        recommendationKey: 'ai_signal_stress_action',
        evidenceKey: 'evidence_signal_crosscheck',
        level: InsightLevel.attention,
        confidence: confidence,
      );
    }
    if (reading.soilMoisture > 88 && !isFloodedRice) {
      return AiAnalysisResult(
        headlineKey: 'ai_overwatering',
        explanationKey: 'ai_overwatering_explanation',
        recommendationKey: 'ai_overwatering_action',
        evidenceKey: 'evidence_high_soil',
        level: InsightLevel.attention,
        confidence: confidence,
      );
    }
    if (reading.temperature > 33) {
      return AiAnalysisResult(
        headlineKey: 'ai_heat_stress',
        explanationKey: 'ai_heat_stress_explanation',
        recommendationKey: 'ai_heat_stress_action',
        evidenceKey: 'evidence_high_temp',
        level: InsightLevel.urgent,
        confidence: confidence,
      );
    }
    if (reading.light < 25) {
      return AiAnalysisResult(
        headlineKey: 'ai_low_light',
        explanationKey: 'ai_low_light_explanation',
        recommendationKey: 'ai_low_light_action',
        evidenceKey: 'evidence_low_light',
        level: InsightLevel.attention,
        confidence: confidence,
      );
    }
    if (reading.soilMoisture > 88 && isFloodedRice) {
      return AiAnalysisResult(
        headlineKey: 'ai_paddy_water_expected',
        explanationKey: 'ai_paddy_water_expected_explanation',
        recommendationKey: 'ai_paddy_water_expected_action',
        evidenceKey: 'evidence_paddy_water',
        level: InsightLevel.healthy,
        confidence: confidence,
      );
    }
    return AiAnalysisResult(
      headlineKey: 'ai_healthy',
      explanationKey: 'ai_healthy_explanation',
      recommendationKey: 'ai_healthy_action',
      evidenceKey: 'evidence_balanced',
      level: InsightLevel.healthy,
      confidence: confidence,
    );
  }
}
