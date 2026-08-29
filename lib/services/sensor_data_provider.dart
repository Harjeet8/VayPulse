import 'package:flutter/foundation.dart';

import '../models/edge_intelligence.dart';
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
  /// This is never synthesized in simulation/hardware fallback paths.
  HardwareTelemetry? get hardwareTelemetry => null;

  void start();
  void stop();
  void selectNode(String nodeId);
  void setScenario(String scenarioId);
  void retry();
}
