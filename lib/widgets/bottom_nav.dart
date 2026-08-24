import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final bool live;
  final ValueChanged<int> onChanged;

  const BottomNav({
    super.key,
    required this.index,
    required this.live,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
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
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          height: 68,
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
              icon:
                  Icon(live ? Icons.memory_outlined : Icons.grid_view_outlined),
              selectedIcon:
                  Icon(live ? Icons.memory_rounded : Icons.grid_view_rounded),
              label: context.tr(live ? 'nav_device' : 'nav_fields'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: context.tr('nav_insights'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_none_rounded),
              selectedIcon: const Icon(Icons.notifications_rounded),
              label: context.tr('nav_alerts'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz_rounded),
              selectedIcon: const Icon(Icons.more_rounded),
              label: context.tr('nav_more'),
            ),
          ],
        ),
      ),
    );
  }
}
