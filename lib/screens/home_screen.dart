import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import 'live_node_home_screen.dart';

/// The single PhytoSense home experience.
///
/// Hardware and simulation remain separate data sources underneath the
/// shared SensorDataProvider contract. The screen listens only while its
/// tab is active, so live packets update immediately without rebuilding
/// the hidden home page in the background.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenFields;

  const HomeScreen({
    super.key,
    this.onOpenAlerts,
    this.onOpenFields,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SensorDataProvider? _sensors;
  bool _active = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppScope.of(context).sensors;
    if (!identical(next, _sensors)) {
      _sensors?.removeListener(_onSensorChange);
      _sensors = next;
      _sensors!.addListener(_onSensorChange);
    }
    _active = TickerMode.valuesOf(context).enabled;
  }

  void _onSensorChange() {
    if (!mounted || !_active) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _active = TickerMode.valuesOf(context).enabled;
    return LiveNodeHomeScreen(onOpenAlerts: widget.onOpenAlerts);
  }

  @override
  void dispose() {
    _sensors?.removeListener(_onSensorChange);
    super.dispose();
  }
}
