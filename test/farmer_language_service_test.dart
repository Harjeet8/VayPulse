import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/services/farmer_language_service.dart';

void main() {
  group('FarmerLanguageService', () {
    test('simplifies ESP32 atmospheric drying language', () {
      final problem = FarmerLanguageService.hardwareProblem(
        rootCause: 'High atmospheric drying demand',
        because: 'VPD is high.',
        needsAttention: true,
      );

      expect(
        problem,
        'Hot or dry air may be making the plant lose water too quickly.',
      );
    });

    test('simplifies ESP32 soil probe action', () {
      final solution = FarmerLanguageService.hardwareSolution(
        farmerAction: 'INSERT PROBE IN SOIL / CHECK CALIBRATION',
        problem: 'The soil sensor may not be placed correctly.',
      );

      expect(
        solution,
        'Push the soil sensor firmly into the soil near the roots, then check the reading again.',
      );
    });

    test('simplifies simulation water stress language', () {
      expect(
        FarmerLanguageService.simulationProblem(
          'ai_water_stress',
          'Water-stress pattern detected',
        ),
        'The plant may not be getting enough water.',
      );
      expect(
        FarmerLanguageService.simulationSolution(
          'ai_water_stress_action',
          'Inspect root-zone soil and irrigate after confirming dryness.',
        ),
        'Check the soil near the roots. Water only if the soil is actually dry.',
      );
    });

    test('healthy readings stay reassuring and simple', () {
      expect(
        FarmerLanguageService.hardwareProblem(
          rootCause: '',
          because: '',
          needsAttention: false,
        ),
        'No major problem detected.',
      );
      expect(
        FarmerLanguageService.simulationProblem(
          'ai_healthy',
          'Conditions look balanced',
        ),
        'No major problem detected.',
      );
    });
  });
}
