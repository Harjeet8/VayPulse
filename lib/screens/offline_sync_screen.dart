import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../services/offline_sync_service.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key});

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  final controller = TextEditingController();
  bool initialized = false;
  String? validationError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      controller.text = AppScope.of(context).settings.value.syncEndpoint;
      initialized = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool _validEndpoint(String endpoint) {
    if (endpoint.trim().isEmpty) return true;
    final uri = Uri.tryParse(endpoint.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _save() async {
    final endpoint = controller.text.trim();
    if (!_validEndpoint(endpoint)) {
      setState(() => validationError = context.tr('endpoint_invalid'));
      return;
    }
    await AppScope.of(context).settings.setSyncEndpoint(endpoint);
    if (!mounted) return;
    setState(() => validationError = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('sync_endpoint_saved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.offlineSync, scope.settings]),
      builder: (context, _) {
        final sync = scope.offlineSync;
        final syncing = sync.status == OfflineSyncStatus.syncing;
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('offline_sync_title'))),
          body: PageFrame(
            children: [
              PhytoPageIntro(
                eyebrow: context.tr('offline_sync_title'),
                title: context.tr('offline_first'),
                body: context.tr('offline_first_body'),
                icon: Icons.cloud_sync_outlined,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: context.tr('pending_records'),
                      value: '${sync.pendingCount}',
                      icon: Icons.storage_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: context.tr('local_history_records'),
                      value: '${sync.historyCount}',
                      icon: Icons.show_chart_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr('last_sync')}: ${sync.lastSyncAt == null ? context.tr('never') : _shortTime(sync.lastSyncAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('sync_server'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(context.tr('sync_server_body')),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: context.tr('sync_endpoint'),
                          hintText: 'https://your-server.example',
                          errorText: validationError,
                          prefixIcon: const Icon(Icons.dns_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(context.tr('save_endpoint')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: syncing
                      ? null
                      : () async {
                          await _save();
                          if (!mounted || validationError != null) return;
                          await sync.syncNow();
                        },
                  icon: syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(context.tr(
                    syncing ? 'syncing_now' : 'sync_now',
                  )),
                ),
              ),
              if (sync.status == OfflineSyncStatus.success) ...[
                const SizedBox(height: 10),
                _SyncMessage(
                  icon: Icons.check_circle_rounded,
                  color: phytoLeaf,
                  message: context.tr('sync_success'),
                ),
              ],
              if (sync.status == OfflineSyncStatus.failed) ...[
                const SizedBox(height: 10),
                _SyncMessage(
                  icon: Icons.cloud_off_outlined,
                  color: phytoAmber,
                  message: context.tr(sync.errorKey ?? 'sync_failed'),
                ),
              ],
              const SizedBox(height: 14),
              Card(
                color: phytoGreen.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security_outlined, color: phytoGreen),
                      const SizedBox(width: 10),
                      Expanded(child: Text(context.tr('sync_privacy_note'))),
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

  String _shortTime(DateTime value) =>
      '${value.day}/${value.month} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: phytoGreen),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _SyncMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _SyncMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 9),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}
