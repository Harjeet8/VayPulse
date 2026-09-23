import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../screens/settings_screen.dart';

class DataSourceCard extends StatelessWidget {
  const DataSourceCard({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.settings, scope.sensorManager]),
      builder: (context, _) {
        final live = scope.sensors.source == SensorDataSource.esp32;
        final ready =
            scope.sensors.connectionStatus == SensorConnectionStatus.ready;
        final ta = FarmerLanguage.isTamil(context);
        return Card(
            child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(live ? Icons.sensors_outlined : Icons.science_outlined),
          title: Text(live
              ? (ta ? 'ESP32 செடி உணரி' : 'ESP32 plant sensor')
              : (ta ? 'சிமுலேஷன்' : 'Simulation')),
          subtitle: Text(live
              ? (ready
                  ? (ta
                      ? 'உங்கள் சாதனத்திலிருந்து புதிய அளவீடுகள்.'
                      : 'Fresh readings from your device.')
                  : (ta
                      ? 'இணைப்புக்காகக் காத்திருக்கிறது. தற்போதைய அளவீடுகள் இல்லை.'
                      : 'Waiting for connection. No current readings.'))
              : (ta
                  ? 'பயிற்சிக்கான தரவு மட்டும். அமைப்புகளில் மாற்றலாம்.'
                  : 'Practice readings only. Change in Settings.')),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ));
      },
    );
  }
}
