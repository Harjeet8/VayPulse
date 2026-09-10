import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../services/ai_analysis_service.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/farmer_analysis_dock.dart';
import 'alerts_screen.dart';
import 'app_command_search.dart';
import 'devices_screen.dart';
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
      animation: Listenable.merge([sensors, scope.farms]),
      builder: (context, _) {
        final live = sensors.source == SensorDataSource.esp32;
        final pages = [
          _withFarmerAnalysis(
            context,
            HomeScreen(
              onOpenAlerts: () => setState(() => index = 3),
              onOpenFields: () => setState(() => index = 1),
            ),
          ),
          live ? const DevicesScreen() : const PlantsScreen(),
          _withFarmerAnalysis(context, const InsightsScreen()),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: NavigationRail(
                                extended: constraints.maxWidth >= 1160,
                                selectedIndex: index,
                                onDestinationSelected: (value) =>
                                    setState(() => index = value),
                                leading: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 20,
                                  ),
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
                                    selectedIcon: const Icon(
                                      Icons.home_rounded,
                                    ),
                                    label: Text(context.tr('nav_home')),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(
                                      live
                                          ? Icons.memory_outlined
                                          : Icons.grid_view_outlined,
                                    ),
                                    selectedIcon: Icon(
                                      live
                                          ? Icons.memory_rounded
                                          : Icons.grid_view_rounded,
                                    ),
                                    label: Text(
                                      context.tr(
                                        live ? 'nav_device' : 'nav_fields',
                                      ),
                                    ),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.insights_outlined),
                                    selectedIcon: const Icon(
                                      Icons.insights_rounded,
                                    ),
                                    label: Text(context.tr('nav_insights')),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                    ),
                                    selectedIcon: const Icon(
                                      Icons.notifications_rounded,
                                    ),
                                    label: Text(context.tr('nav_alerts')),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.more_horiz_rounded),
                                    selectedIcon: const Icon(
                                      Icons.more_rounded,
                                    ),
                                    label: Text(context.tr('nav_more')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: IndexedStack(index: index, children: pages),
                        ),
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
              },
            ),
          ),
        );
      },
    );
  }

  Widget _withFarmerAnalysis(BuildContext context, Widget child) {
    final scope = AppScope.of(context);
    final current = scope.sensors.current;
    if (current == null) return child;

    String problem;
    String solution;
    Color accent;

    if (scope.sensors.source == SensorDataSource.esp32) {
      if (!current.edgeAnalysisAvailable) return child;
      final status = current.healthStatus.trim().toUpperCase();
      final cause = _cleanEdgeText(current.primaryRootCause);
      final healthy = !const {'WATCH', 'STRESS', 'CRITICAL'}.contains(status);
      problem = healthy && cause.isEmpty
          ? 'No major problem detected.'
          : cause.isEmpty
              ? _cleanEdgeText(status)
              : cause;
      solution = current.farmerAction.trim().isEmpty
          ? 'Continue monitoring the crop and follow the latest ESP32 guidance.'
          : current.farmerAction.trim();
      accent = status == 'CRITICAL'
          ? Theme.of(context).colorScheme.error
          : status == 'WATCH' || status == 'STRESS'
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.primary;
    } else {
      if (!scope.farms.isLoaded || scope.farms.farms.isEmpty) return child;
      final analysis = AiAnalysisService.analyze(
        current,
        scope.sensors.historyFor(current.nodeId),
        crop: scope.farms.selectedField.crop,
      );
      problem = analysis.level == InsightLevel.healthy
          ? 'No major problem detected.'
          : context.tr(analysis.headlineKey);
      solution = context.tr(analysis.recommendationKey);
      accent = switch (analysis.level) {
        InsightLevel.healthy => Theme.of(context).colorScheme.primary,
        InsightLevel.attention => Theme.of(context).colorScheme.tertiary,
        InsightLevel.urgent => Theme.of(context).colorScheme.error,
      };
    }

    return Column(
      children: [
        Expanded(child: child),
        FarmerAnalysisDock(
          problem: problem,
          solution: solution,
          accent: accent,
        ),
      ],
    );
  }

  String _cleanEdgeText(String value) =>
      value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
}
