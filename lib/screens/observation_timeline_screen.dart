import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

enum _TimelineFilter { all, alerts, trials, system }

class ObservationTimelineScreen extends StatefulWidget {
  const ObservationTimelineScreen({super.key});

  @override
  State<ObservationTimelineScreen> createState() =>
      _ObservationTimelineScreenState();
}

class _ObservationTimelineScreenState extends State<ObservationTimelineScreen> {
  _TimelineFilter filter = _TimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        scope.sensors,
        scope.alerts,
        scope.engineeringEvidence,
        scope.weather,
      ]),
      builder: (context, _) {
        final source = scope.sensors.source.name;
        final entries = <_TimelineEntry>[
          if (scope.sensors.current case final reading?)
            _TimelineEntry(
              time: reading.timestamp,
              type: _TimelineFilter.system,
              icon: Icons.sensors_rounded,
              title: context.tr('timeline_latest_reading'),
              body: context.tr('timeline_latest_reading_body', {
                'health': reading.healthScore.round(),
                'node': reading.nodeId,
              }),
              color: Theme.of(context).colorScheme.primary,
            ),
          for (final alert in scope.alerts.alerts)
            _TimelineEntry(
              time: alert.timestamp,
              type: _TimelineFilter.alerts,
              icon: Icons.notification_important_outlined,
              title: alert.titleText ?? context.tr(alert.titleKey),
              body: alert.messageText ?? context.tr(alert.messageKey),
              color: alert.severity.name == 'critical'
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary,
            ),
          for (final trial in scope.engineeringEvidence.trialsForSource(source))
            _TimelineEntry(
              time: trial.endedAt,
              type: _TimelineFilter.trials,
              icon: Icons.science_outlined,
              title: trial.title,
              body: context.tr('timeline_trial_body', {
                'samples': trial.sampleCount,
                'outcome': context.tr('outcome_${trial.outcome}'),
              }),
              color: Theme.of(context).colorScheme.secondary,
            ),
          if (scope.engineeringEvidence.calibration case final calibration?)
            _TimelineEntry(
              time: calibration.calibratedAt,
              type: _TimelineFilter.system,
              icon: Icons.verified_outlined,
              title: context.tr('timeline_calibration'),
              body: context.tr('timeline_calibration_body', {
                'score': calibration.trustScore,
                'samples': calibration.sampleCount,
              }),
              color: Theme.of(context).colorScheme.primary,
            ),
          if (scope.sensors.source == SensorDataSource.simulation &&
              scope.weather.snapshot != null)
            _TimelineEntry(
              time: scope.weather.snapshot!.updatedAt,
              type: _TimelineFilter.system,
              icon: Icons.cloud_outlined,
              title: context.tr('timeline_weather'),
              body: scope.weather.snapshot!.location,
              color: const Color(0xFF397FC0),
            ),
        ]..sort((a, b) => b.time.compareTo(a.time));
        final visible = filter == _TimelineFilter.all
            ? entries
            : entries.where((entry) => entry.type == filter).toList();

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('observation_timeline'))),
          body: PageFrame(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('observation_timeline_body'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 10),
                  PhytoStatusBadge(
                    label: context.tr(
                        scope.sensors.source == SensorDataSource.esp32
                            ? 'source_live_badge'
                            : 'source_demo_badge'),
                    icon: scope.sensors.source == SensorDataSource.esp32
                        ? Icons.memory_rounded
                        : Icons.science_outlined,
                    color: scope.sensors.source == SensorDataSource.esp32
                        ? const Color(0xFF397FC0)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_TimelineFilter>(
                  segments: [
                    ButtonSegment(
                      value: _TimelineFilter.all,
                      label: Text(context.tr('all')),
                    ),
                    ButtonSegment(
                      value: _TimelineFilter.alerts,
                      label: Text(context.tr('nav_alerts')),
                    ),
                    ButtonSegment(
                      value: _TimelineFilter.trials,
                      label: Text(context.tr('recorded_trials')),
                    ),
                    ButtonSegment(
                      value: _TimelineFilter.system,
                      label: Text(context.tr('timeline_system')),
                    ),
                  ],
                  selected: {filter},
                  onSelectionChanged: (value) =>
                      setState(() => filter = value.first),
                ),
              ),
              const SizedBox(height: 18),
              if (visible.isEmpty)
                PhytoEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: context.tr('timeline_empty'),
                  body: context.tr('timeline_empty_body'),
                )
              else
                for (var index = 0; index < visible.length; index++)
                  _TimelineTile(
                    entry: visible[index],
                    last: index == visible.length - 1,
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _TimelineEntry entry;
  final bool last;

  const _TimelineTile({required this.entry, required this.last});

  @override
  Widget build(BuildContext context) {
    final hour = entry.time.hour.toString().padLeft(2, '0');
    final minute = entry.time.minute.toString().padLeft(2, '0');
    final date = '${entry.time.day}/${entry.time.month}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(entry.icon, color: entry.color, size: 20),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 82,
                  color: entry.color.withValues(alpha: 0.24),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          '$date • $hour:$minute',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(entry.body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineEntry {
  final DateTime time;
  final _TimelineFilter type;
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _TimelineEntry({
    required this.time,
    required this.type,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}
