import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/live_icon.dart';
import 'live_node_home_screen.dart';
import 'practice_farm_home_screen.dart';

/// Farmer-first PhytoSense AI Home.
///
/// Practice Farm never replaces this proven Home layout. In simulation a
/// single compact entry opens the farm deployment screen.
class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenFields;

  const HomeScreen({super.key, this.onOpenAlerts, this.onOpenFields});

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final simulation = sensors.source == SensorDataSource.simulation;
        return Stack(
          children: [
            LiveNodeHomeScreen(onOpenAlerts: onOpenAlerts),
            if (simulation)
              Positioned(
                right: 14,
                top: MediaQuery.paddingOf(context).top + 58,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PracticeFarmHomeScreen(
                          onOpenAlerts: onOpenAlerts,
                        ),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LiveIcon(
                            icon: Icons.hub_rounded,
                            color: Color(0xFF2879B9),
                            size: 18,
                            kind: LiveIconKind.connectivity,
                          ),
                          SizedBox(width: 6),
                          Text('Farm', style: TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
