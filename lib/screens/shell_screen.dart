import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../services/app_scope.dart';
import '../l10n/app_strings.dart';
import '../services/farmer_language.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/live_motion.dart';
import 'alerts_screen.dart';
import 'app_command_search.dart';
import 'farmer_analysis_screen.dart';
import 'home_screen.dart';
import 'leaf_screening_screen.dart';
import 'live_sensors_screen.dart';
import 'observation_timeline_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  void _select(int value) {
    if (value == index) return;
    AppScope.of(context).voice.stop();
    setState(() => index = value);
  }

  void _openAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlertsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onOpenAlerts: _openAlerts,
        onOpenFields: () => _select(2),
      ),
      const KeyedSubtree(
        key: PageStorageKey<String>('farmer-analysis-page'),
        child: FarmerAnalysisScreen(),
      ),
      const LiveSensorsScreen(),
      const ObservationTimelineScreen(),
      const LeafScreeningScreen(),
      const SettingsScreen(),
    ];

    final railDestinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.home_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.home_rounded),
        label: Text(context.tr('nav_home')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.eco_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.eco_rounded),
        label: Text(FarmerLanguage.label(context, 'analysis')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.sensors_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.sensors_rounded),
        label: Text(FarmerLanguage.label(context, 'sensors')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.timeline_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.timeline_rounded),
        label: Text(FarmerLanguage.label(context, 'history')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.photo_camera_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.photo_camera_rounded),
        label: Text(FarmerLanguage.label(context, 'camera')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.settings_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.settings_rounded),
        label: Text(FarmerLanguage.label(context, 'settings')),
      ),
    ];

    final pageStack = PageStorage(
      bucket: _pageStorageBucket,
      child: IndexedStack(
        index: index,
        children: [
          for (var pageIndex = 0; pageIndex < pages.length; pageIndex++)
            TickerMode(
              enabled: pageIndex == index,
              child: pages[pageIndex],
            ),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
            _select(0),
        const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
            _select(1),
        const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () =>
            _select(2),
        const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () =>
            _select(3),
        const SingleActivator(LogicalKeyboardKey.digit5, alt: true): () =>
            _select(4),
        const SingleActivator(LogicalKeyboardKey.digit6, alt: true): () =>
            _select(5),
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
            if (!wide) {
              return Scaffold(
                body: pageStack,
                bottomNavigationBar: BottomNav(
                  index: index,
                  onChanged: _select,
                ),
              );
            }

            final colors = Theme.of(context).colorScheme;
            return Scaffold(
              body: Row(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.07),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: NavigationRail(
                          extended: constraints.maxWidth >= 1160,
                          selectedIndex: index,
                          onDestinationSelected: _select,
                          leading: Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 22),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: phytoGreen,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const LiveMotionIcon(
                                icon: Icons.eco_rounded,
                                color: Colors.white,
                                style: LiveMotionStyle.sway,
                              ),
                            ),
                          ),
                          destinations: railDestinations,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: pageStack),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
