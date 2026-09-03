import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/farmer_language.dart';
import 'live_icon.dart';

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
              icon: LiveIcon(
                icon: Icons.home_outlined,
                active: index == 0,
                kind: LiveIconKind.plant,
              ),
              selectedIcon: const LiveIcon(
                icon: Icons.home_rounded,
                kind: LiveIconKind.plant,
              ),
              label: context.tr('nav_home'),
            ),
            NavigationDestination(
              icon: LiveIcon(
                icon: Icons.psychology_alt_outlined,
                active: index == 1,
                kind: LiveIconKind.analysis,
              ),
              selectedIcon: const LiveIcon(
                icon: Icons.psychology_alt_rounded,
                kind: LiveIconKind.analysis,
              ),
              label: FarmerLanguage.label(context, 'analysis'),
            ),
            NavigationDestination(
              icon: LiveIcon(
                icon: Icons.sensors_outlined,
                active: index == 2,
                kind: LiveIconKind.connectivity,
              ),
              selectedIcon: const LiveIcon(
                icon: Icons.sensors_rounded,
                kind: LiveIconKind.connectivity,
              ),
              label: FarmerLanguage.label(context, 'sensors'),
            ),
            NavigationDestination(
              icon: LiveIcon(
                icon: Icons.timeline_outlined,
                active: index == 3,
              ),
              selectedIcon: const LiveIcon(icon: Icons.timeline_rounded),
              label: FarmerLanguage.label(context, 'history'),
            ),
            NavigationDestination(
              icon: LiveIcon(
                icon: Icons.photo_camera_outlined,
                active: index == 4,
              ),
              selectedIcon: const LiveIcon(icon: Icons.photo_camera_rounded),
              label: FarmerLanguage.label(context, 'camera'),
            ),
            NavigationDestination(
              icon: LiveIcon(
                icon: Icons.settings_outlined,
                active: index == 5,
              ),
              selectedIcon: const LiveIcon(icon: Icons.settings_rounded),
              label: FarmerLanguage.label(context, 'settings'),
            ),
          ],
        ),
      ),
    );
  }
}
