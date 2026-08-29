import 'package:flutter/foundation.dart';

import '../models/edge_intelligence.dart';
import '../models/esp32_configuration.dart';
import '../models/hardware_telemetry.dart';
import '../models/sensor_node.dart';
import '../models/sensor_reading.dart';

enum SensorConnectionStatus { loading, ready, offline, error }

enum SensorDataSource { simulation, esp32 }

abstract class SensorDataProvider extends ChangeNotifier {
  SensorDataSource get source;
  SensorReading? get current;
  Map<String, SensorReading> get latestReadings;
  List<SensorNode> get nodes;
  String get selectedNodeId;
  List<SensorReading> historyFor(String nodeId);
  bool get connected;
  SensorConnectionStatus get connectionStatus;
  String? get errorMessage;
  Stream<SensorReading> get stream;
  bool get supportsScenarios;
  String get scenarioId;
  List<String> get scenarioIds;

  /// Rich reasoning produced by the live ESP32. Simulation and old firmware
  /// may legitimately return null. UI must capability-detect rather than
  /// hard-code a firmware version.
  EdgeIntelligence? get edgeIntelligence => null;

  /// Technical transparency payload for the dedicated Live Sensors page.
  /// This is never synthesized in hardware mode when firmware data is absent.
  HardwareTelemetry? get hardwareTelemetry => null;

  /// ESP32 v6.2 configuration/diagnostics flow. Defaults keep simulation and
  /// older providers backward-compatible without UI-side HTTP calls.
  Future<Esp32Config?> fetchHardwareConfig() async => null;
  Future<Esp32Config?> setCropProfile(String cropId) async => null;
  Future<Esp32Config?> setGrowthStage(String stageId) async => null;
  Future<Esp32Config?> resetAdaptiveBaseline() async => null;
  Future<Esp32Diagnostics?> fetchHardwareDiagnostics() async => null;

  void start();
  void stop();
  void selectNode(String nodeId);
  void setScenario(String scenarioId);
  void retry();
}
