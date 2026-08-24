class FarmImpactProjection {
  final double areaAcres;
  final double seasonalValuePerAcre;
  final double lossRiskPercent;
  final double preventableSharePercent;
  final double inputSavingsPerAcre;
  final double systemCost;

  const FarmImpactProjection({
    required this.areaAcres,
    required this.seasonalValuePerAcre,
    required this.lossRiskPercent,
    required this.preventableSharePercent,
    required this.inputSavingsPerAcre,
    required this.systemCost,
  });

  double get seasonalCropValue => areaAcres * seasonalValuePerAcre;

  double get cropValueAtRisk => seasonalCropValue * lossRiskPercent / 100;

  double get estimatedLossPrevented =>
      cropValueAtRisk * preventableSharePercent / 100;

  double get estimatedInputSavings => areaAcres * inputSavingsPerAcre;

  double get grossSeasonalBenefit =>
      estimatedLossPrevented + estimatedInputSavings;

  double get firstSeasonNetBenefit => grossSeasonalBenefit - systemCost;

  double get benefitCostRatio =>
      systemCost <= 0 ? 0 : grossSeasonalBenefit / systemCost;
}
