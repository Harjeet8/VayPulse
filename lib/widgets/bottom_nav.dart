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

  static const _accents = <Color>[
    Color(0xFF176B4D), // Home / plant health
    Color(0xFF5A61C9), // Analysis / intelligence
    Color(0xFF2879B9), // Sensors / live data
    Color(0xFF287E83), // History / trends
    Color(0xFFB8674E), // Camera / visual inspection
    Color(0xFF66727E), // Settings / neutral system
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _accents[index.clamp(0, _accents.length - 1)];
    final indicator = Color.alphaBlend(
      accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.20 : 0.12),
      scheme.surface,
    );

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.30 : 0.07,
              ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: indicator,
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? accent
                    : scheme.onSurfaceVariant,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? accent
                    : scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
          child: NavigationBar(
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            backgroundColor: Colors.transparent,
            selectedIndex: index,
            onDestinationSelected: onChanged,
            destinations: [
              NavigationDestination(
                icon: LiveIcon(
                  icon: Icons.home_outlined,
                  color: index == 0 ? _accents[0] : null,
                  active: index == 0,
                  kind: LiveIconKind.plant,
                ),
                selectedIcon: const LiveIcon(
                  icon: Icons.home_rounded,
                  color: Color(0xFF176B4D),
                  kind: LiveIconKind.plant,
                ),
                label: context.tr('nav_home'),
              ),
              NavigationDestination(
                icon: LiveIcon(
                  icon: Icons.psychology_alt_outlined,
                  color: index == 1 ? _accents[1] : null,
                  active: index == 1,
                  kind: LiveIconKind.analysis,
                ),
                selectedIcon: const LiveIcon(
                  icon: Icons.psychology_alt_rounded,
                  color: Color(0xFF5A61C9),
                  kind: LiveIconKind.analysis,
                ),
                label: FarmerLanguage.label(context, 'analysis'),
              ),
              NavigationDestination(
                icon: LiveIcon(
                  icon: Icons.sensors_outlined,
                  color: index == 2 ? _accents[2] : null,
                  active: index == 2,
                  kind: LiveIconKind.connectivity,
                ),
                selectedIcon: const LiveIcon(
                  icon: Icons.sensors_rounded,
                  color: Color(0xFF2879B9),
                  kind: LiveIconKind.connectivity,
                ),
                label: FarmerLanguage.label(context, 'sensors'),
              ),
              NavigationDestination(
                icon: LiveIcon(
                  icon: Icons.timeline_outlined,
                  color: index == 3 ? _accents[3] : null,
                  active: index == 3,
                ),
                selectedIcon: const LiveIcon(
                  icon: Icons.timeline_rounded,
                  color: Color(0xFF287E83),
                ),
                label: FarmerLanguage.label(context, 'history'),
              ),
              NavigationDestination(
                icon: LiveIcon(
                  icon: Icons.photo_camera_outlined,
                  color: index == 4 ? _accents[4] : null,
                  active: index == 4,
                ),
                selectedIcon: const LiveIcon(
                  icon: Icons.photo_camera_rounded,
                  color: Color(0xFFB8674E),
                ),
                label: FarmerLanguage.label(context, 'camera'),
              ),
              NavigationDestination(
                icon: LiveIcon(
                  icon: Icons.settings_outlined,
                  color: index == 5 ? _accents[5] : null,
                  active: index == 5,
                ),
                selectedIcon: const LiveIcon(
                  icon: Icons.settings_rounded,
                  color: Color(0xFF66727E),
                ),
                label: FarmerLanguage.label(context, 'settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
