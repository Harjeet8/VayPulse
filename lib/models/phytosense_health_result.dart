class PhytoSenseHealthResult {
  final double healthIndex;
  final String healthStatus;
  final double confidence;
  final double? waterScore;
  final double? thermalScore;
  final double? rootZoneScore;
  final double? atmosphericScore;
  final double? lightScore;
  final double? diseaseRisk;
  final double? bioelectricStability;
  final List<String> reasons;
  final List<String> recommendations;
  final DateTime timestamp;

  const PhytoSenseHealthResult({
    required this.healthIndex,
    required this.healthStatus,
    required this.confidence,
    this.waterScore,
    this.thermalScore,
    this.rootZoneScore,
    this.atmosphericScore,
    this.lightScore,
    this.diseaseRisk,
    this.bioelectricStability,
    this.reasons = const [],
    this.recommendations = const [],
    required this.timestamp,
  });

  String get diseaseRiskLabel {
    final risk = diseaseRisk;
    if (risk == null) return 'unknown';
    if (risk < 25) return 'low';
    if (risk < 50) return 'moderate';
    if (risk < 75) return 'elevated';
    return 'high';
  }

  String get bioelectricLabel {
    final value = bioelectricStability;
    if (value == null) return 'learning';
    if (value >= 80) return 'stable';
    if (value >= 60) return 'mild_deviation';
    return 'significant_deviation';
  }
}
