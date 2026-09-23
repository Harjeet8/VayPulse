import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phytosense_ai/services/settings_service.dart';
import 'package:phytosense_ai/services/sensor_provider_manager.dart';
import 'package:phytosense_ai/services/sensor_data_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install starts with ESP32 and no fabricated readings', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.load();
    expect(settings.value.dataSource, 'esp32');
    final manager = SensorProviderManager();
    expect(manager.source, SensorDataSource.esp32);
    expect(manager.current, isNull);
    expect(manager.latestReadings, isEmpty);
    expect(manager.edgeIntelligence, isNull);
    manager.dispose();
    settings.dispose();
  });

  test('legacy simulation default migrates once without losing connection settings', () async {
    SharedPreferences.setMockInitialValues({
      'dataSource': 'simulation', 'esp32Endpoint': 'http://192.168.29.5',
      'hardwareTransportMode': 'REMOTE', 'languageCode': 'ta',
    });
    final settings = SettingsService();
    await settings.load();
    expect(settings.value.dataSource, 'esp32');
    expect(settings.value.esp32Endpoint, 'http://192.168.29.5');
    expect(settings.value.hardwareTransportMode, 'REMOTE');
    expect(settings.value.languageCode, 'ta');
    await settings.setDataSource('simulation');
    final restored = SettingsService();
    await restored.load();
    expect(restored.value.dataSource, 'simulation');
    await restored.setDataSource('esp32');
    await settings.load();
    expect(settings.value.dataSource, 'esp32');
    restored.dispose();
    settings.dispose();
  });

  test('invalid saved mode safely selects ESP32', () async {
    SharedPreferences.setMockInitialValues({'hardwareFirstModeV1': true, 'dataSource': 'unknown'});
    final settings = SettingsService();
    await settings.load();
    expect(settings.value.dataSource, 'esp32');
    settings.dispose();
  });

  test('leaving simulation hides its readings immediately', () {
    final manager = SensorProviderManager();
    manager.configure(source: SensorDataSource.simulation, endpoint: manager.hardwareEndpoint);
    manager.simulation.start();
    expect(manager.current, isNotNull);
    manager.configure(source: SensorDataSource.esp32, endpoint: manager.hardwareEndpoint);
    expect(manager.current, isNull);
    expect(manager.latestReadings, isEmpty);
    expect(manager.edgeIntelligence, isNull);
    expect(manager.hardwareTelemetry, isNull);
    expect(manager.supportsScenarios, isFalse);
    manager.dispose();
  });
}
