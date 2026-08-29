import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import '../services/app_scope.dart';
import '../services/engineering_evidence_service.dart';
import '../services/edge_alert_language.dart';
import '../widgets/page_frame.dart';

enum _AlertFilter { all, action, monitor, resolved, system }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertFilter filter = _AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).alerts;
    final evidence = AppScope.of(context).engineeringEvidence;
    return AnimatedBuilder(
      animation: Listenable.merge([service, evidence]),
      builder: (context, _) {
        final visible = service.alerts.where((alert) {
          final resolved = evidence.feedbackFor(alert.id) != null;
          final system = alert.nodeId == 'weather' ||
              alert.titleKey == 'alert_abnormal_sensor' ||
              alert.titleKey == 'alert_low_battery' ||
              alert.titleKey == 'alert_weak_signal';
          return switch (filter) {
            _AlertFilter.all => true,
            _AlertFilter.action =>
              alert.severity == AlertSeverity.critical && !resolved,
            _AlertFilter.monitor =>
              alert.severity != AlertSeverity.critical && !resolved && !system,
            _AlertFilter.resolved => resolved,
            _AlertFilter.system => system && !resolved,
          };
        }).toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('alerts_title')),
            actions: [
              if (service.alerts.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'read') service.markAllRead();
                    if (value == 'clear') _confirmClear(context, service);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'read',
                      child: Text(context.tr('mark_all_read')),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(context.tr('clear_alerts')),
                    ),
                  ],
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: PageFrame(
            children: [
              Text(
                context.tr('alerts_subtitle'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              if (service.unreadCount > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.fiber_manual_record, size: 12),
                    label: Text(context.tr('unread_count', {
                      'value': service.unreadCount,
                    })),
                  ),
                ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_AlertFilter>(
                  segments: [
                    ButtonSegment(
                      value: _AlertFilter.all,
                      label: Text(context.tr('all')),
                    ),
                    ButtonSegment(
                      value: _AlertFilter.action,
                      label: Text(context.tr('alert_needs_action')),
                    ),
                    ButtonSegment(
                      value: _AlertFilter.monitor,
                      label: Text(context.tr('monitor')),
                    ),
                    ButtonSegment(
                      value: _AlertFilter.resolved,
                      label: Text(context.tr('resolved')),
                    ),
                    ButtonSegment(
                      value: _AlertFilter.system,
                      label: Text(context.tr('system')),
                    ),
                  ],
                  selected: {filter},
                  onSelectionChanged: (selection) =>
                      setState(() => filter = selection.first),
                ),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                const _AlertsEmpty()
              else
                for (final alert in visible) ...[
                  Dismissible(
                    key: ValueKey(alert.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.archive_outlined,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    onDismissed: (_) =>
                        _dismissAlert(context, service, alert.id),
                    child: _AlertCard(alert: alert),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    AlertService service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('clear_alerts_confirm_title')),
        content: Text(context.tr('clear_alerts_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('clear_alerts')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HapticFeedback.mediumImpact();
      service.clear();
    }
  }

  Future<void> _dismissAlert(
    BuildContext context,
    AlertService service,
    String id,
  ) async {
    await HapticFeedback.selectionClick();
    final removed = service.remove(id);
    if (!context.mounted || removed == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr('alert_archived')),
          action: SnackBarAction(
            label: context.tr('undo'),
            onPressed: () => service.restore(removed),
          ),
        ),
      );
  }
}

class _AlertCard extends StatelessWidget {
  final PlantAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).alerts;
    final evidence = AppScope.of(context).engineeringEvidence;
    final recordedFeedback = evidence.feedbackFor(alert.id);
    final urgent = alert.severity == AlertSeverity.critical;
    final color = urgent ? phytoTerracotta : phytoAmber;
    final hour = alert.timestamp.hour.toString().padLeft(2, '0');
    final minute = alert.timestamp.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';
    return Card(
      color: alert.isRead ? null : color.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => service.markRead(alert.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  urgent
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            EdgeAlertLanguage.text(context, alert.titleKey) ?? context.tr(alert.titleKey),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(EdgeAlertLanguage.text(context, alert.messageKey) ?? context.tr(alert.messageKey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaPill(
                          icon: alert.nodeId == 'weather'
                              ? Icons.cloud_outlined
                              : Icons.sensors,
                          text: alert.nodeId == 'weather'
                              ? context.tr('weather_source')
                              : alert.nodeId,
                        ),
                        _MetaPill(icon: Icons.schedule, text: time),
                      ],
                    ),
                    const SizedBox(height: 9),
                    if (recordedFeedback != null)
                      Chip(
                        avatar: const Icon(Icons.verified_outlined, size: 17),
                        label: Text(context.tr('feedback_recorded')),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _showFeedbackSheet(
                          context,
                          alert,
                          evidence,
                        ),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: Text(context.tr('record_outcome')),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showFeedbackSheet(
  BuildContext context,
  PlantAlert alert,
  EngineeringEvidenceService evidence,
) async {
  var confirmed = false;
  var useful = false;
  var recovered = false;
  var falseAlert = false;
  final notes = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('farmer_outcome_title'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(context.tr('farmer_outcome_body')),
              const SizedBox(height: 12),
              SwitchListTile(
                value: confirmed,
                title: Text(context.tr('condition_confirmed')),
                onChanged: (value) => setSheetState(() {
                  confirmed = value;
                  if (value) falseAlert = false;
                }),
              ),
              SwitchListTile(
                value: useful,
                title: Text(context.tr('recommendation_useful')),
                onChanged: (value) => setSheetState(() => useful = value),
              ),
              SwitchListTile(
                value: recovered,
                title: Text(context.tr('plant_recovered')),
                onChanged: (value) => setSheetState(() => recovered = value),
              ),
              SwitchListTile(
                value: falseAlert,
                title: Text(context.tr('mark_false_alert')),
                onChanged: (value) => setSheetState(() {
                  falseAlert = value;
                  if (value) confirmed = false;
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: context.tr('notes')),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await evidence.saveFeedback(FarmerFeedback(
                      alertId: alert.id,
                      source: evidence.sensors.source.name,
                      nodeId: alert.nodeId,
                      recordedAt: DateTime.now(),
                      conditionConfirmed: confirmed,
                      recommendationUseful: useful,
                      plantRecovered: recovered,
                      falseAlert: falseAlert,
                      notes: notes.text.trim(),
                    ));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.tr('save_outcome')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  notes.dispose();
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 5),
            Text(text, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}

class _AlertsEmpty extends StatelessWidget {
  const _AlertsEmpty();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: phytoGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('no_alerts'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('no_alerts_body'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
