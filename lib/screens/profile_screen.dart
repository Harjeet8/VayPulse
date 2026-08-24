import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';
import '../widgets/plant_pulse.dart';
import '../widgets/data_source_card.dart';
import '../widgets/phyto_ui.dart';
import 'app_command_search.dart';
import 'about_screen.dart';
import 'competition_center_screen.dart';
import 'devices_screen.dart';
import 'engineering_center_screen.dart';
import 'farm_management_screen.dart';
import 'irrigation_advisor_screen.dart';
import 'leaf_screening_screen.dart';
import 'offline_sync_screen.dart';
import 'observation_timeline_screen.dart';
import 'settings_screen.dart';
import 'weather_center_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.sensorManager, scope.settings]),
      builder: (context, _) {
        final live = scope.sensors.source == SensorDataSource.esp32;
        final judge = scope.settings.value.experienceMode == 'judge';
        final farm =
            scope.farms.farms.isEmpty ? null : scope.farms.selectedFarm;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr(live ? 'more_title_live' : 'more_title')),
            actions: [
              if (judge)
                IconButton(
                  tooltip: context.tr('command_search'),
                  onPressed: () => showSearch<void>(
                    context: context,
                    delegate: AppCommandSearch(
                      searchLabel: context.tr('command_search_hint'),
                    ),
                  ),
                  icon: const Icon(Icons.manage_search_rounded),
                ),
            ],
          ),
          body: PageFrame(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF124D38), Color(0xFF2A805E)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.35,
                        child: PlantPulse(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('farmer_profile'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                live
                                    ? context.tr('profile_live_workspace')
                                    : farm?.name ?? context.tr('demo_farm'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const DataSourceCard(),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('experience_mode'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(context.tr('experience_mode_body')),
                      const SizedBox(height: 14),
                      ExperienceModeSelector(
                        selected: scope.settings.value.experienceMode,
                        onChanged: scope.settings.setExperienceMode,
                        farmerTitle: context.tr('farmer_mode'),
                        farmerBody: context.tr('farmer_mode_body'),
                        judgeTitle: context.tr('judge_mode'),
                        judgeBody: context.tr('judge_mode_body'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    if (judge) ...[
                      _MenuTile(
                        icon: Icons.emoji_events_outlined,
                        title: context.tr('competition_center'),
                        subtitle: context.tr('competition_center_subtitle'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CompetitionCenterScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 70),
                      _MenuTile(
                        icon: Icons.engineering_outlined,
                        title: context.tr('engineering_center'),
                        subtitle: context.tr('engineering_center_menu_body'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EngineeringCenterScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 70),
                    ],
                    _MenuTile(
                      icon: Icons.document_scanner_outlined,
                      title: context.tr('leaf_screening_title'),
                      subtitle: context.tr('leaf_screening_menu_body'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeafScreeningScreen(),
                        ),
                      ),
                    ),
                    if (!live) ...[
                      const Divider(height: 1, indent: 70),
                      _MenuTile(
                        icon: Icons.water_drop_outlined,
                        title: context.tr('irrigation_advisor'),
                        subtitle: context.tr('irrigation_menu_body'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IrrigationAdvisorScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 70),
                      _MenuTile(
                        icon: Icons.cloud_outlined,
                        title: context.tr('weather_center'),
                        subtitle: context.tr('weather_menu_body'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WeatherCenterScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 70),
                      _MenuTile(
                        icon: Icons.edit_note_rounded,
                        title: context.tr('crop_management'),
                        subtitle: context.tr('crop_management_menu_body'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FarmManagementScreen(),
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 1, indent: 70),
                    _MenuTile(
                      icon: Icons.timeline_rounded,
                      title: context.tr('observation_timeline'),
                      subtitle: context.tr('observation_timeline_menu_body'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ObservationTimelineScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 70),
                    _MenuTile(
                      icon: Icons.cloud_sync_outlined,
                      title: context.tr('offline_sync_title'),
                      subtitle: context.tr('offline_sync_menu_body'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfflineSyncScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 70),
                    _MenuTile(
                      icon: Icons.sensors_outlined,
                      title: context.tr('devices'),
                      subtitle: context.tr('devices_subtitle'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DevicesScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 70),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      title: context.tr('settings'),
                      subtitle: context.tr('settings_subtitle'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 70),
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      title: context.tr('about'),
                      subtitle: context.tr('version'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutVayPulseScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(context.tr('about_body'))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}
