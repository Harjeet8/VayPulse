import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/farmer_language.dart';
import 'live_motion.dart';

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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.08,
            ),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primaryContainer,
          selectedIndex: index > 4 ? 0 : index,
          onDestinationSelected: onChanged,
          destinations: [
            NavigationDestination(
              icon: const LiveMotionIcon(
                  animate: false, icon: Icons.home_outlined),
              selectedIcon: const LiveMotionIcon(
                  animate: false, icon: Icons.home_rounded),
              label: context.tr('nav_home'),
            ),
            NavigationDestination(
              icon: const LiveMotionIcon(
                  animate: false, icon: Icons.spa_outlined),
              selectedIcon:
                  const LiveMotionIcon(animate: false, icon: Icons.spa_rounded),
              label: FarmerLanguage.label(context, 'analysis'),
            ),
            NavigationDestination(
              icon: const LiveMotionIcon(
                  animate: false, icon: Icons.sensors_outlined),
              selectedIcon: const LiveMotionIcon(
                  animate: false, icon: Icons.sensors_rounded),
              label: FarmerLanguage.label(context, 'sensors'),
            ),
            NavigationDestination(
              icon: const LiveMotionIcon(
                  animate: false, icon: Icons.timeline_outlined),
              selectedIcon: const LiveMotionIcon(
                  animate: false, icon: Icons.timeline_rounded),
              label: FarmerLanguage.label(context, 'history'),
            ),
            NavigationDestination(
              icon: const LiveMotionIcon(
                  animate: false, icon: Icons.photo_camera_outlined),
              selectedIcon: const LiveMotionIcon(
                  animate: false, icon: Icons.photo_camera_rounded),
              label: FarmerLanguage.label(context, 'camera'),
            ),
          ],
        ),
      ),
    );
  }
}
