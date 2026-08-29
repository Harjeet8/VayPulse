import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../services/firmware_text_adapter.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/bottom_nav.dart';
import 'alerts_screen.dart';
import 'app_command_search.dart';
import 'devices_screen.dart';
import 'farmer_analysis_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'plants_screen.dart';
import 'profile_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final live = sensors.source == SensorDataSource.esp32;
        final pages = [
          HomeScreen(
            onOpenAlerts: () => setState(() => index = 3),
            onOpenFields: () => setState(() => index = 1),
          ),
          live ? const DevicesScreen() : const PlantsScreen(),
          live ? const FarmerAnalysisScreen() : const InsightsScreen(),
          const AlertsScreen(),
          const ProfileScreen(),
        ];
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
                setState(() => index = 0),
            const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
                setState(() => index = 1),
            const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () =>
                setState(() => index = 2),
            const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () =>
                setState(() => index = 3),
            const SingleActivator(LogicalKeyboardKey.digit5, alt: true): () =>
                setState(() => index = 4),
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
                showSearch<void>(
                  context: context,
                  delegate: AppCommandSearch(
                    searchLabel: context.tr('command_search_hint'),
                  ),
                ),
          },
          child: Focus(
            autofocus: true,
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 880;
              if (wide) {
                return Scaffold(
                  body: Row(
                    children: [
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                  color: Theme.of(context).dividerColor),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: NavigationRail(
                              extended: constraints.maxWidth >= 1160,
                              selectedIndex: index,
                              onDestinationSelected: (value) =>
                                  setState(() => index = value),
                              leading: Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 20),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [phytoGreen, phytoLeaf],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              destinations: [
                                NavigationRailDestination(
                                  icon: const Icon(Icons.home_outlined),
                                  selectedIcon: const Icon(Icons.home_rounded),
                                  label: Text(context.tr('nav_home')),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(live
                                      ? Icons.memory_outlined
                                      : Icons.grid_view_outlined),
                                  selectedIcon: Icon(live
                                      ? Icons.memory_rounded
                                      : Icons.grid_view_rounded),
                                  label: Text(context
                                      .tr(live ? 'nav_device' : 'nav_fields')),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(live
                                      ? Icons.psychology_alt_outlined
                                      : Icons.insights_outlined),
                                  selectedIcon: Icon(live
                                      ? Icons.psychology_alt_rounded
                                      : Icons.insights_rounded),
                                  label: Text(live
                                      ? FirmwareTextAdapter.label(context, 'nav')
                                      : context.tr('nav_insights')),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(
                                      Icons.notifications_none_rounded),
                                  selectedIcon:
                                      const Icon(Icons.notifications_rounded),
                                  label: Text(context.tr('nav_alerts')),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.more_horiz_rounded),
                                  selectedIcon: const Icon(Icons.more_rounded),
                                  label: Text(context.tr('nav_more')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                          child: IndexedStack(index: index, children: pages)),
                    ],
                  ),
                );
              }
              return Scaffold(
                body: IndexedStack(index: index, children: pages),
                bottomNavigationBar: BottomNav(
                  index: index,
                  live: live,
                  onChanged: (value) => setState(() => index = value),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
