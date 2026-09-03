import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/models/sensor_reading.dart';
import 'package:phytosense_ai/services/health_analysis_engine.dart';

SensorReading _reading({
  double soil = 60,
  double airTemp = 25,
  double humidity = 65,
  double lux = 35000,
  double rootTemp = 24,
  double leafWetness = 15,
  double wetSeconds = 0,
  double bioStability = 90,
  bool daytime = true,
  bool soilAvailable = true,
  bool leafAvailable = true,
  bool bioAvailable = true,
}) {
  return SensorReading(
    nodeId: 'test-node',
    timestamp: DateTime.now(),
    soilMoisture: soil,
    temperature: airTemp,
    humidity: humidity,
    light: (lux / 70000 * 100).clamp(0, 100).toDouble(),
    lightLux: lux,
    soilTemperature: rootTemp,
    leafWetness: leafWetness,
    plantSignal: bioStability,
    plantVoltageMv: 1500,
    healthScore: 80,
    stressScore: 20,
    healthStatus: 'good',
    soilCalibrated: true,
    leafCalibrated: true,
    daytime: daytime,
    leafWetDurationSeconds: wetSeconds,
    recentWetExposureSeconds: wetSeconds,
    bioBaselineReady: true,
    bioBaselineSamples: 80,
    bioBaselineMv: 1500,
    bioDeviationMv: 0,
    bioNoiseMv: 2,
    bioSignalQuality: 95,
    bioelectricStability: bioStability,
    soilMoistureAvailable: soilAvailable,
    temperatureAvailable: true,
    humidityAvailable: true,
    lightAvailable: true,
    soilTemperatureAvailable: true,
    leafWetnessAvailable: leafAvailable,
    plantSignalAvailable: bioAvailable,
  );
}

void main() {
  group('HealthAnalysisEngine', () {
    test('healthy calibrated tomato produces a strong index', () {
      final result = HealthAnalysisEngine.analyze(_reading(), const []);
      expect(result.healthIndex, greaterThan(70));
      expect(result.confidence, greaterThan(70));
      expect(result.diseaseRisk, lessThan(50));
    });

    test('missing soil sensor is excluded instead of scored as zero', () {
      final complete = HealthAnalysisEngine.analyze(_reading(), const []);
      final missing = HealthAnalysisEngine.analyze(
        _reading(soilAvailable: false),
        const [],
      );
      expect(missing.healthIndex, greaterThan(45));
      expect(missing.confidence, lessThan(complete.confidence));
    });

    test('night darkness does not create a low-light penalty', () {
      final night = HealthAnalysisEngine.analyze(
        _reading(daytime: false, lux: 0),
        const [],
      );
      expect(night.lightScore, isNull);
      expect(night.healthIndex, greaterThan(60));
    });

    test('prolonged leaf wetness raises disease-conducive risk', () {
      final dry = HealthAnalysisEngine.analyze(
        _reading(leafWetness: 10),
        const [],
      );
      final wet = HealthAnalysisEngine.analyze(
        _reading(
          leafWetness: 90,
          wetSeconds: 7 * 3600,
          humidity: 90,
          airTemp: 24,
        ),
        const [],
      );
      expect(wet.diseaseRisk, greaterThan(dry.diseaseRisk!));
      expect(wet.diseaseRisk, greaterThan(50));
    });

    test(
      'bioelectric baseline deviation lowers stability only when available',
      () {
        final stable = HealthAnalysisEngine.analyze(
          _reading(bioStability: 92),
          const [],
        );
        final unstable = HealthAnalysisEngine.analyze(
          _reading(bioStability: 35),
          const [],
        );
        expect(
          unstable.bioelectricStability!,
          lessThan(stable.bioelectricStability!),
        );
      },
    );
  });
}
