import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
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

  void _openAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlertsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onOpenAlerts: _openAlerts,
        onOpenFields: () => setState(() => index = 2),
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

    final railDestinations = [
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.home_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.home_rounded),
        label: Text(context.tr('nav_home')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.psychology_alt_outlined),
        selectedIcon:
            const LiveMotionIcon(icon: Icons.psychology_alt_rounded),
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
      child: IndexedStack(index: index, children: pages),
    );

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
        const SingleActivator(LogicalKeyboardKey.digit6, alt: true): () =>
            setState(() => index = 5),
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
            }
            return Scaffold(
              body: pageStack,
              bottomNavigationBar: BottomNav(
                index: index,
                onChanged: (value) => setState(() => index = value),
              ),
            );
          },
        ),
      ),
    );
  }
}
