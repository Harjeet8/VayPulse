class HealthRange {
  final double criticalLow;
  final double warningLow;
  final double idealLow;
  final double idealHigh;
  final double warningHigh;
  final double criticalHigh;

  const HealthRange(
    this.criticalLow,
    this.warningLow,
    this.idealLow,
    this.idealHigh,
    this.warningHigh,
    this.criticalHigh,
  );
}

class CropHealthProfile {
  final String crop;
  final String growthStage;
  final HealthRange dayAirTemperature;
  final HealthRange nightAirTemperature;
  final HealthRange rootZoneTemperature;
  final HealthRange humidity;
  final HealthRange calibratedSoilMoisture;
  final HealthRange daylightLux;

  const CropHealthProfile({
    required this.crop,
    required this.growthStage,
    required this.dayAirTemperature,
    required this.nightAirTemperature,
    required this.rootZoneTemperature,
    required this.humidity,
    required this.calibratedSoilMoisture,
    required this.daylightLux,
  });

  static CropHealthProfile forCrop(
    String crop, {
    String growthStage = 'vegetative',
  }) {
    final normalized = crop.trim().toLowerCase();
    if (normalized.contains('tomato')) {
      return tomato(growthStage);
    }
    // Conservative fallback for crops that do not yet have a fully validated
    // profile. Keeping it explicit prevents pretending one set of ranges is
    // universally correct for every crop.
    return CropHealthProfile(
      crop: crop.isEmpty ? 'Crop' : crop,
      growthStage: growthStage,
      dayAirTemperature: const HealthRange(7, 14, 20, 30, 35, 43),
      nightAirTemperature: const HealthRange(5, 10, 15, 24, 29, 37),
      rootZoneTemperature: const HealthRange(7, 13, 17, 30, 35, 42),
      humidity: const HealthRange(10, 25, 45, 82, 94, 100),
      calibratedSoilMoisture: const HealthRange(5, 25, 40, 78, 92, 100),
      daylightLux: const HealthRange(0, 1000, 4000, 75000, 100000, 130000),
    );
  }

  static CropHealthProfile tomato(String growthStage) {
    final stage = growthStage.trim().toLowerCase();
    var soil = const HealthRange(10, 30, 45, 75, 88, 98);
    var day = const HealthRange(8, 16, 21, 27, 32, 40);

    if (stage.contains('seed') || stage.contains('establish')) {
      soil = const HealthRange(12, 34, 50, 76, 88, 98);
      day = const HealthRange(9, 17, 21, 27, 31, 39);
    } else if (stage.contains('flower')) {
      soil = const HealthRange(10, 32, 47, 73, 86, 97);
      day = const HealthRange(8, 16, 20, 27, 31, 39);
    } else if (stage.contains('fruit')) {
      soil = const HealthRange(10, 30, 45, 72, 85, 97);
    } else if (stage.contains('ripen')) {
      soil = const HealthRange(8, 27, 42, 70, 84, 96);
    }

    return CropHealthProfile(
      crop: 'Tomato',
      growthStage: growthStage,
      dayAirTemperature: day,
      nightAirTemperature: const HealthRange(7, 12, 16, 21, 25, 35),
      rootZoneTemperature: const HealthRange(8, 14, 18, 28, 33, 40),
      humidity: const HealthRange(15, 30, 50, 80, 92, 100),
      calibratedSoilMoisture: soil,
      daylightLux: const HealthRange(0, 1500, 5000, 70000, 90000, 120000),
    );
  }
}
