String stressLabel(double score) {
  if (score >= 75) return 'High';
  if (score >= 45) return 'Moderate';
  if (score >= 20) return 'Mild';
  return 'Normal';
}

String recommendation(
  double soil,
  double temperature,
  double humidity,
  double light,
) {
  if (soil < 30) return 'Water the plant and monitor soil moisture.';
  if (soil > 85) return 'Pause watering and allow the soil to drain.';
  if (temperature > 32) return 'Move the plant away from intense heat.';
  if (light < 25) return 'Consider a brighter location with suitable light.';
  return 'Conditions look balanced. Continue monitoring.';
}
