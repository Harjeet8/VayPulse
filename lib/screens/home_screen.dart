import 'package:flutter/material.dart';

import 'live_node_home_screen.dart';

/// The single PhytoSense home experience.
///
/// Hardware and simulation remain separate data sources underneath the shared
/// SensorDataProvider contract, but the farmer-facing Home UI is deliberately
/// identical: problem first, one action, plant response, evidence, recovery.
class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenFields;

  const HomeScreen({
    super.key,
    this.onOpenAlerts,
    this.onOpenFields,
  });

  @override
  Widget build(BuildContext context) =>
      LiveNodeHomeScreen(onOpenAlerts: onOpenAlerts);
}
