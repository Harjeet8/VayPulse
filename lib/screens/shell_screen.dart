import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../services/farmer_language.dart';
import '../widgets/bottom_nav.dart';
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
      _TabAccent(
        accent: const Color(0xFF176B4D),
        child: HomeScreen(
          onOpenAlerts: _openAlerts,
          onOpenFields: () => setState(() => index = 2),
        ),
      ),
      const _TabAccent(
        accent: Color(0xFF5A61C9),
        child: KeyedSubtree(
          key: PageStorageKey<String>('farmer-analysis-page'),
          child: FarmerAnalysisScreen(),
        ),
      ),
      const _TabAccent(
        accent: Color(0xFF2879B9),
        child: LiveSensorsScreen(),
      ),
      const _TabAccent(
        accent: Color(0xFF287E83),
        child: ObservationTimelineScreen(),
      ),
      const _TabAccent(
        accent: Color(0xFFB8674E),
        child: LeafScreeningScreen(),
      ),
      const _TabAccent(
        accent: Color(0xFF66727E),
        child: SettingsScreen(),
      ),
    ];

    final railDestinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: Text(context.tr('nav_home')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.psychology_alt_outlined),
        selectedIcon: const Icon(Icons.psychology_alt_rounded),
        label: Text(FarmerLanguage.label(context, 'analysis')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.sensors_outlined),
        selectedIcon: const Icon(Icons.sensors_rounded),
        label: Text(FarmerLanguage.label(context, 'sensors')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.timeline_outlined),
        selectedIcon: const Icon(Icons.timeline_rounded),
        label: Text(FarmerLanguage.label(context, 'history')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.photo_camera_outlined),
        selectedIcon: const Icon(Icons.photo_camera_rounded),
        label: Text(FarmerLanguage.label(context, 'camera')),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_rounded),
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
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: Colors.white,
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

class _TabAccent extends StatelessWidget {
  final Color accent;
  final Widget child;

  const _TabAccent({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final container = Color.alphaBlend(
      accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.11),
      scheme.surface,
    );
    final themed = theme.copyWith(
      colorScheme: scheme.copyWith(
        primary: accent,
        primaryContainer: container,
        onPrimaryContainer: theme.brightness == Brightness.dark
            ? Colors.white
            : Color.alphaBlend(
                Colors.black.withValues(alpha: 0.76),
                accent,
              ),
      ),
    );
    return Theme(data: themed, child: child);
  }
}

