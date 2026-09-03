import 'package:flutter_test/flutter_test.dart';

import 'package:phytosense_ai/models/esp32_configuration.dart';
import 'package:phytosense_ai/simulation/simulated_sensor_provider.dart';

void main() {
  test('ESP32 config accepts firmware availableCrops and baseline reset', () {
    final config = Esp32Config.fromJson({
      'crop': 'Papaya',
      'availableCrops': [
        'Universal',
        'Tomato',
        'Hibiscus',
        'Rice',
        'Sugarcane',
        'Banana',
        'Papaya',
        'Eggplant',
        'Okra',
        'Maize',
        'Groundnut',
      ],
      'baselineReset': true,
    });

    expect(config.cropId, 'papaya');
    expect(config.cropName, 'Papaya');
    expect(config.supportedCrops, contains('papaya'));
    expect(config.supportedCrops, contains('sugarcane'));
    expect(config.baselineReset, isTrue);
  });

  test('Practice Farm exposes a multi-node Tamil Nadu deployment', () {
    final provider = SimulationSensorProvider();
    addTearDown(provider.dispose);

    expect(provider.nodes, hasLength(6));
    expect(provider.nodes.first.name, contains('Sugarcane'));
    expect(provider.nodes.any((node) => node.name.contains('Rice')), isTrue);
    expect(provider.nodes.any((node) => node.name.contains('Banana')), isTrue);
    expect(provider.nodes.any((node) => node.name.contains('Papaya')), isFalse);

    provider.start();
    expect(provider.latestReadings, hasLength(6));
    expect(
      provider.latestReadings.values
          .map((reading) => reading.soilMoisture.round())
          .toSet()
          .length,
      greaterThan(1),
    );
  });
}
