import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';

/// Stays visible across pages and routes while practice data is active.
class SimulationNotice extends StatelessWidget {
  final Widget child;
  const SimulationNotice({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.sensorManager, scope.settings]),
      child: child,
      builder: (context, child) {
        final simulated = scope.sensors.source == SensorDataSource.simulation;
        final dark = Theme.of(context).brightness == Brightness.dark;
        // Keep the Navigator in the same slot when the source changes.
        return Column(children: [
          if (simulated)
            Material(
              key: const Key('simulation-notice'),
              color: dark ? const Color(0xFF423621) : const Color(0xFFFFEBC1),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Icon(Icons.science_outlined,
                        size: 18,
                        color: dark
                            ? const Color(0xFFFFD78B)
                            : const Color(0xFF664710)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      FarmerLanguage.isTamil(context)
                          ? 'சிமுலேஷன் · பயிற்சிக்கான தரவு மட்டும்'
                          : 'Simulation · Practice readings only',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: dark
                                ? const Color(0xFFFFD78B)
                                : const Color(0xFF664710),
                            fontWeight: FontWeight.w700,
                          ),
                    )),
                  ]),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          Expanded(child: child!),
        ]);
      },
    );
  }
}
