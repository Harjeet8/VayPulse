import 'esp32_client.dart';
import 'sensor_data_provider.dart';

/// Shared hardware contract. Concrete ESP32 implementations use [client] while
/// screens, charts, alerts and analysis continue to consume SensorDataProvider.
abstract class HardwareSensorProvider extends SensorDataProvider {
  final Esp32Client client;

  HardwareSensorProvider(this.client);

  @override
  SensorDataSource get source => SensorDataSource.esp32;

  @override
  bool get supportsScenarios => false;

  @override
  String get scenarioId => '';

  @override
  List<String> get scenarioIds => const [];

  @override
  void setScenario(String scenarioId) {}
}
