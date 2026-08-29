import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/farmer_language.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const BottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.32
                        : 0.08,
                  ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          selectedIndex: index,
          onDestinationSelected: onChanged,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: context.tr('nav_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.psychology_alt_outlined),
              selectedIcon: const Icon(Icons.psychology_alt_rounded),
              label: FarmerLanguage.label(context, 'analysis'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.sensors_outlined),
              selectedIcon: const Icon(Icons.sensors_rounded),
              label: FarmerLanguage.label(context, 'sensors'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.timeline_outlined),
              selectedIcon: const Icon(Icons.timeline_rounded),
              label: FarmerLanguage.label(context, 'history'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.photo_camera_outlined),
              selectedIcon: const Icon(Icons.photo_camera_rounded),
              label: FarmerLanguage.label(context, 'camera'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: FarmerLanguage.label(context, 'settings'),
            ),
          ],
        ),
      ),
    );
  }
}
