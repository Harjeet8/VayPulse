class LeafScreeningResult {
  final String riskKey;
  final String explanationKey;
  final String actionKey;
  final int confidence;
  final double greenPercent;
  final double yellowPercent;
  final double brownPercent;
  final DateTime screenedAt;

  const LeafScreeningResult({
    required this.riskKey,
    required this.explanationKey,
    required this.actionKey,
    required this.confidence,
    required this.greenPercent,
    required this.yellowPercent,
    required this.brownPercent,
    required this.screenedAt,
  });
}
