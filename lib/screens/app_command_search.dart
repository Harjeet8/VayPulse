import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'about_screen.dart';
import 'competition_center_screen.dart';
import 'devices_screen.dart';
import 'engineering_center_screen.dart';
import 'irrigation_advisor_screen.dart';
import 'leaf_screening_screen.dart';
import 'observation_timeline_screen.dart';
import 'offline_sync_screen.dart';
import 'presentation_mode_screen.dart';
import 'settings_screen.dart';
import 'weather_center_screen.dart';

class AppCommandSearch extends SearchDelegate<void> {
  AppCommandSearch({required String searchLabel})
      : super(searchFieldLabel: searchLabel);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: context.tr('clear_search'),
            onPressed: () => query = '',
            icon: const Icon(Icons.close_rounded),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_rounded),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final commands = <_Command>[
      _Command(
        Icons.document_scanner_outlined,
        context.tr('leaf_screening_title'),
        context.tr('leaf_screening_menu_body'),
        const LeafScreeningScreen(),
      ),
      _Command(
        Icons.water_drop_outlined,
        context.tr('irrigation_advisor'),
        context.tr('irrigation_menu_body'),
        const IrrigationAdvisorScreen(),
      ),
      _Command(
        Icons.timeline_rounded,
        context.tr('observation_timeline'),
        context.tr('observation_timeline_menu_body'),
        const ObservationTimelineScreen(),
      ),
      _Command(
        Icons.memory_outlined,
        context.tr('devices'),
        context.tr('devices_subtitle'),
        const DevicesScreen(),
      ),
      _Command(
        Icons.cloud_outlined,
        context.tr('weather_center'),
        context.tr('weather_menu_body'),
        const WeatherCenterScreen(),
      ),
      _Command(
        Icons.cloud_sync_outlined,
        context.tr('offline_sync_title'),
        context.tr('offline_sync_menu_body'),
        const OfflineSyncScreen(),
      ),
      _Command(
        Icons.engineering_outlined,
        context.tr('engineering_center'),
        context.tr('engineering_center_menu_body'),
        const EngineeringCenterScreen(),
      ),
      _Command(
        Icons.emoji_events_outlined,
        context.tr('competition_center'),
        context.tr('competition_center_subtitle'),
        const CompetitionCenterScreen(),
      ),
      _Command(
        Icons.slideshow_outlined,
        context.tr('presentation_mode'),
        context.tr('presentation_mode_body'),
        const PresentationModeScreen(),
      ),
      _Command(
        Icons.settings_outlined,
        context.tr('settings'),
        context.tr('settings_subtitle'),
        const SettingsScreen(),
      ),
      _Command(
        Icons.info_outline_rounded,
        context.tr('about'),
        context.tr('version'),
        const AboutVayPulseScreen(),
      ),
    ];
    final needle = query.trim().toLowerCase();
    final visible = commands
        .where(
          (item) =>
              needle.isEmpty ||
              item.title.toLowerCase().contains(needle) ||
              item.subtitle.toLowerCase().contains(needle),
        )
        .toList();
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                context.tr('command_no_results'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final command = visible[index];
        return Card(
          child: ListTile(
            leading: Icon(command.icon),
            title: Text(
              command.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(command.subtitle),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: () {
              final navigator = Navigator.of(context);
              close(context, null);
              navigator.push(
                MaterialPageRoute(builder: (_) => command.destination),
              );
            },
          ),
        );
      },
    );
  }
}

class _Command {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget destination;

  const _Command(this.icon, this.title, this.subtitle, this.destination);
}
