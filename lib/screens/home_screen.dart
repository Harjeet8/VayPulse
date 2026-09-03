import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import 'live_node_home_screen.dart';
import 'practice_farm_home_screen.dart';

/// PhytoSense AI exposes two intentionally different home experiences:
/// a farm-scale Practice Farm network for simulation and a single-node deep
/// live view for the physical ESP32 deployment.
class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenFields;

  const HomeScreen({
    super.key,
    this.onOpenAlerts,
    this.onOpenFields,
  });

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        if (sensors.source == SensorDataSource.simulation) {
          return PracticeFarmHomeScreen(onOpenAlerts: onOpenAlerts);
        }
        return LiveNodeHomeScreen(onOpenAlerts: onOpenAlerts);
      },
    );
  }
}
