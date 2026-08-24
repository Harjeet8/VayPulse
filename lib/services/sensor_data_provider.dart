import 'package:flutter/foundation.dart';
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

  void start();
  void stop();
  void selectNode(String nodeId);
  void setScenario(String scenarioId);
  void retry();
}
