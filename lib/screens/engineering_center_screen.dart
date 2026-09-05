import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/hardware_transport.dart';
import '../models/sensor_reading.dart';
import '../services/ai_analysis_service.dart';
import '../services/app_scope.dart';
import '../services/engineering_evidence_service.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/health_ring.dart';
import '../widgets/page_frame.dart';

class EngineeringCenterScreen extends StatelessWidget {
  const EngineeringCenterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('engineering_center'))),
        body: PageFrame(
          children: [
            const _EngineeringHero(),
            const SizedBox(height: 18),
            Text(
              context.tr('engineering_center_body'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _ToolCard(
              icon: Icons.account_tree_outlined,
              title: context.tr('system_xray'),
              body: context.tr('system_xray_body'),
              onTap: () => _open(context, const SystemXrayScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.science_outlined,
              title: context.tr('experiment_lab'),
              body: context.tr('experiment_lab_body'),
              onTap: () => _open(context, const ExperimentLabScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.tune_rounded,
              title: context.tr('calibration_wizard'),
              body: context.tr('calibration_wizard_body'),
              onTap: () => _open(context, const CalibrationWizardScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.description_outlined,
              title: context.tr('judge_report'),
              body: context.tr('judge_report_body'),
              onTap: () => _open(context, const JudgeReportScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.how_to_reg_outlined,
              title: context.tr('feedback_evidence'),
              body: context.tr('feedback_evidence_body'),
              onTap: () => _open(context, const FeedbackSummaryScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.policy_outlined,
              title: context.tr('responsible_ai_card'),
              body: context.tr('responsible_ai_card_body'),
              onTap: () => _open(context, const ResponsibleAiModelCardScreen()),
            ),
          ],
        ),
      );

  static void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class SystemXrayScreen extends StatelessWidget {
  const SystemXrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        scope.sensors,
        scope.alerts,
        scope.offlineSync,
        scope.engineeringEvidence,
      ]),
      builder: (context, _) {
        final sensors = scope.sensors;
        final reading = sensors.current;
        final hardwareMode = sensors.source == SensorDataSource.esp32;
        final analysis = reading == null || hardwareMode
            ? null
            : AiAnalysisService.analyze(
                reading,
                sensors.historyFor(reading.nodeId),
                crop: scope.farms.selectedField.crop,
              );
        final analysisAvailable = hardwareMode
            ? reading?.edgeAnalysisAvailable == true
            : analysis != null;
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('system_xray'))),
          body: PageFrame(
            children: [
              _StatusBanner(
                icon: Icons.account_tree_rounded,
                title: context.tr('xray_live_pipeline'),
                body: context.tr('xray_live_pipeline_body'),
                live: sensors.source == SensorDataSource.esp32,
              ),
              if (hardwareMode &&
                  reading != null &&
                  _EdgeIntelligencePanel.hasTelemetry(reading)) ...[
                const SizedBox(height: 14),
                _EdgeIntelligencePanel(reading: reading),
              ],
              const SizedBox(height: 18),
              _PipelineStep(
                number: '01',
                icon: sensors.source == SensorDataSource.esp32
                    ? Icons.memory_rounded
                    : Icons.science_outlined,
                title: context.tr('xray_source'),
                detail: context.tr(
                  sensors.source == SensorDataSource.esp32
                      ? 'esp32_live'
                      : 'simulation_mode',
                ),
                complete: true,
              ),
              _PipelineStep(
                number: '02',
                icon: Icons.verified_outlined,
                title: context.tr('xray_validation'),
                detail: context.tr(
                  reading == null
                      ? 'waiting_validation'
                      : 'xray_validation_complete',
                ),
                complete: reading != null,
              ),
              _PipelineStep(
                number: '03',
                icon: Icons.hub_outlined,
                title: context.tr('xray_fusion'),
                detail: context.tr('xray_fusion_detail'),
                complete: reading != null,
              ),
              _PipelineStep(
                number: '04',
                icon: Icons.psychology_alt_outlined,
                title: context.tr('xray_reasoning'),
                detail: !analysisAvailable
                    ? context.tr('no_data')
                    : hardwareMode
                        ? (reading!.primaryRootCause.isEmpty
                            ? reading.healthStatus.replaceAll('_', ' ')
                            : reading.primaryRootCause.replaceAll('_', ' '))
                        : context.tr(analysis!.headlineKey),
                complete: analysisAvailable,
              ),
              _PipelineStep(
                number: '05',
                icon: Icons.notifications_active_outlined,
                title: context.tr('xray_action'),
                detail: hardwareMode && reading != null
                    ? (reading.farmerAction.isEmpty
                        ? context.tr('xray_no_alert')
                        : reading.farmerAction)
                    : context.tr(
                        scope.alerts.alerts.isEmpty
                            ? 'xray_no_alert'
                            : 'xray_alert_ready',
                      ),
                complete: analysisAvailable,
              ),
              _PipelineStep(
                number: '06',
                icon: Icons.cloud_done_outlined,
                title: context.tr('xray_evidence'),
                detail: context.tr('xray_evidence_detail', {
                  'trials': scope.engineeringEvidence
                      .trialsForSource(sensors.source.name)
                      .length,
                  'records': sensors.source == SensorDataSource.esp32
                      ? scope.offlineSync.historyCount
                      : 0,
                }),
                complete: scope.engineeringEvidence
                        .trialsForSource(sensors.source.name)
                        .isNotEmpty ||
                    (sensors.source == SensorDataSource.esp32 &&
                        scope.offlineSync.historyCount > 0),
                last: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExperimentLabScreen extends StatefulWidget {
  const ExperimentLabScreen({super.key});

  @override
  State<ExperimentLabScreen> createState() => _ExperimentLabScreenState();
}

class _ExperimentLabScreenState extends State<ExperimentLabScreen> {
  final titleController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final service = scope.engineeringEvidence;
    return AnimatedBuilder(
      animation: Listenable.merge([service, scope.sensors]),
      builder: (context, _) {
        final crop = scope.sensors.source == SensorDataSource.esp32
            ? scope.sensors.current?.crop ?? 'Universal'
            : scope.farms.selectedField.crop;
        final sourceTrials = service.trialsForSource(scope.sensors.source.name);
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('experiment_lab'))),
          body: PageFrame(
            children: [
              _StatusBanner(
                icon: Icons.science_rounded,
                title: context.tr('experiment_evidence_title'),
                body: context.tr('experiment_evidence_body'),
                live: scope.sensors.source == SensorDataSource.esp32,
              ),
              const SizedBox(height: 16),
              if (!service.trialActive)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: context.tr('trial_name'),
                            hintText: context.tr('trial_name_hint'),
                            prefixIcon: const Icon(Icons.edit_note_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: context.tr('crop'), value: crop),
                        _InfoRow(
                          label: context.tr('diagnostic_provider'),
                          value: context.tr(
                            scope.sensors.source == SensorDataSource.esp32
                                ? 'esp32_live'
                                : 'simulation_mode',
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: scope.sensors.current == null
                                ? null
                                : () {
                                    final started = service.startTrial(
                                      title: titleController.text,
                                      crop: crop,
                                    );
                                    if (!started) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.tr('trial_started'),
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(context.tr('start_trial')),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _ActiveTrialCard(service: service),
              const SizedBox(height: 20),
              Text(
                context.tr('recorded_trials'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (sourceTrials.isEmpty)
                _EmptyEvidence(message: context.tr('no_trials'))
              else
                for (final trial in sourceTrials) ...[
                  _TrialCard(trial: trial),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class CalibrationWizardScreen extends StatelessWidget {
  const CalibrationWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final service = scope.engineeringEvidence;
    return AnimatedBuilder(
      animation: Listenable.merge([service, scope.sensors]),
      builder: (context, _) {
        final samples = service.calibrationSamples.length;
        final savedProfile = service.calibration;
        final profile = savedProfile?.source == scope.sensors.source.name
            ? savedProfile
            : null;
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('calibration_wizard'))),
          body: PageFrame(
            children: [
              _StatusBanner(
                icon: Icons.tune_rounded,
                title: context.tr('calibration_trust_title'),
                body: context.tr('calibration_trust_body'),
                live: scope.sensors.source == SensorDataSource.esp32,
              ),
              const SizedBox(height: 16),
              if (profile != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        HealthRing(
                          score: profile.trustScore.toDouble(),
                          size: 92,
                          label: context.tr('trust_score'),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('saved_calibration'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(profile.nodeId),
                              Text(
                                context.tr('calibration_samples_count', {
                                  'value': profile.sampleCount,
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (profile != null) const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CalibrationStep(
                        number: '1',
                        title: context.tr('calibration_step_connect'),
                        body: context.tr('calibration_step_connect_body'),
                        complete: scope.sensors.current != null,
                      ),
                      _CalibrationStep(
                        number: '2',
                        title: context.tr('calibration_step_stabilize'),
                        body: context.tr('calibration_step_stabilize_body'),
                        complete: samples >= 3,
                      ),
                      _CalibrationStep(
                        number: '3',
                        title: context.tr('calibration_step_save'),
                        body: context.tr('calibration_step_save_body'),
                        complete: profile != null && samples == 0,
                        last: true,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (samples / 5).clamp(0, 1).toDouble(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('calibration_progress', {'value': samples}),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: scope.sensors.current == null
                                  ? null
                                  : service.captureCalibrationSample,
                              icon: const Icon(Icons.add_chart_rounded),
                              label: Text(context.tr('capture_sample')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: samples < 3
                                  ? null
                                  : () async {
                                      final saved =
                                          await service.saveCalibration();
                                      if (!context.mounted || saved == null) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.tr(
                                              'calibration_saved',
                                              {'value': saved.trustScore},
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.verified_rounded),
                              label: Text(context.tr('save_calibration')),
                            ),
                          ),
                        ],
                      ),
                      if (samples > 0) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: service.resetCalibrationSamples,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: Text(context.tr('reset_samples')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.info_outline_rounded,
                title: context.tr('calibration_note_title'),
                body: context.tr('calibration_note_body'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class JudgeReportScreen extends StatelessWidget {
  const JudgeReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        scope.sensors,
        scope.engineeringEvidence,
        scope.offlineSync,
      ]),
      builder: (context, _) {
        final report = _buildReport(context);
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('judge_report'))),
          body: PageFrame(
            children: [
              _StatusBanner(
                icon: Icons.description_rounded,
                title: context.tr('report_snapshot_title'),
                body: context.tr('report_snapshot_body'),
                live: scope.sensors.source == SensorDataSource.esp32,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SelectableText(
                    report,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.55, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: report));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('report_copied'))),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded),
                  label: Text(context.tr('copy_report')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildReport(BuildContext context) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;
    final evidence = scope.engineeringEvidence;
    final reading = sensors.current;
    final savedCalibration = evidence.calibration;
    final calibration = savedCalibration?.source == sensors.source.name
        ? savedCalibration
        : null;
    final savedReadingCount = sensors.source == SensorDataSource.esp32
        ? scope.offlineSync.historyCount
        : 0;
    final source = context.tr(
      sensors.source == SensorDataSource.esp32
          ? 'esp32_live'
          : 'simulation_mode',
    );
    final buffer = StringBuffer()
      ..writeln('PHYTOSENSE AI — ENGINEERING EVIDENCE REPORT')
      ..writeln('PhytoSense AI Version 9.0.0 • Powered by VayPulse')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('1. ACTIVE SYSTEM')
      ..writeln('Data source: $source')
      ..writeln('Node: ${sensors.selectedNodeId}')
      ..writeln('Connection: ${sensors.connectionStatus.name}')
      ..writeln('Validated reading: ${reading != null ? 'Yes' : 'No'}');
    if (reading != null) {
      buffer
        ..writeln('Health: ${reading.healthScore.toStringAsFixed(1)}%')
        ..writeln('Soil moisture: ${reading.soilMoisture.toStringAsFixed(1)}%')
        ..writeln('Temperature: ${reading.temperature.toStringAsFixed(1)} C')
        ..writeln('Humidity: ${reading.humidity.toStringAsFixed(1)}%')
        ..writeln('Light: ${reading.light.toStringAsFixed(1)}%')
        ..writeln(
          'Plant electrode: ${reading.plantSignal.toStringAsFixed(1)}%',
        );
    }
    buffer
      ..writeln()
      ..writeln('2. VALIDATION EVIDENCE')
      ..writeln(
        'Completed trials: ${evidence.trialsForSource(sensors.source.name).length}',
      )
      ..writeln('Saved reading history: $savedReadingCount')
      ..writeln(
        'Farmer outcomes: ${evidence.feedbackForSource(sensors.source.name).length}',
      )
      ..writeln('Confirmed conditions: ${evidence.confirmedFeedbackCount}')
      ..writeln('False alerts recorded: ${evidence.falseAlertCount}')
      ..writeln(
        'Calibration trust score: ${calibration?.trustScore ?? 'Not calibrated'}',
      )
      ..writeln()
      ..writeln('3. ARCHITECTURE')
      ..writeln(
        'SensorDataProvider -> range validation -> multimodal analysis '
        '-> explainable recommendation -> farmer alert -> offline evidence',
      )
      ..writeln()
      ..writeln('4. RESPONSIBLE-AI LIMITS')
      ..writeln(
        'Disease results are potential candidate rankings, not '
        'confirmed diagnoses. Match scores are not accuracy claims. Farmers '
        'must inspect the crop and use qualified local advice before treatment.',
      )
      ..writeln()
      ..writeln('5. DEPLOYMENT')
      ..writeln(
        'Local-first, bilingual English/Tamil, one-node ESP32 ready, '
        'with isolated simulation fallback and optional server synchronization.',
      );
    return buffer.toString();
  }
}

class FeedbackSummaryScreen extends StatelessWidget {
  const FeedbackSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).engineeringEvidence;
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('feedback_evidence'))),
        body: PageFrame(
          children: [
            _StatusBanner(
              icon: Icons.how_to_reg_rounded,
              title: context.tr('feedback_loop_title'),
              body: context.tr('feedback_loop_body'),
              live: service.sensors.source == SensorDataSource.esp32,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 620
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      width: width,
                      icon: Icons.fact_check_outlined,
                      label: context.tr('feedback_total'),
                      value:
                          '${service.feedbackForSource(service.sensors.source.name).length}',
                    ),
                    _MetricCard(
                      width: width,
                      icon: Icons.check_circle_outline_rounded,
                      label: context.tr('feedback_confirmed'),
                      value: '${service.confirmedFeedbackCount}',
                    ),
                    _MetricCard(
                      width: width,
                      icon: Icons.thumb_up_alt_outlined,
                      label: context.tr('feedback_useful'),
                      value: '${service.usefulFeedbackCount}',
                    ),
                    _MetricCard(
                      width: width,
                      icon: Icons.error_outline_rounded,
                      label: context.tr('feedback_false_alerts'),
                      value: '${service.falseAlertCount}',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.notifications_active_outlined,
              title: context.tr('record_feedback_how'),
              body: context.tr('record_feedback_how_body'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsibleAiModelCardScreen extends StatelessWidget {
  const ResponsibleAiModelCardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('responsible_ai_card'))),
        body: PageFrame(
          children: [
            _StatusBanner(
              icon: Icons.policy_rounded,
              title: context.tr('model_card_title'),
              body: context.tr('model_card_intro'),
              live: false,
            ),
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.flag_outlined,
              title: context.tr('model_intended_use'),
              body: context.tr('model_intended_use_body'),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.dataset_outlined,
              title: context.tr('model_inputs'),
              body: context.tr('model_inputs_body'),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.psychology_alt_outlined,
              title: context.tr('model_method'),
              body: context.tr('model_method_body'),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.warning_amber_outlined,
              title: context.tr('model_limitations'),
              body: context.tr('model_limitations_body'),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.privacy_tip_outlined,
              title: context.tr('model_privacy'),
              body: context.tr('model_privacy_body'),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              icon: Icons.rule_folder_outlined,
              title: context.tr('model_validation'),
              body: context.tr('model_validation_body'),
            ),
          ],
        ),
      );
}

class _EngineeringHero extends StatelessWidget {
  const _EngineeringHero();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D4934), Color(0xFF267B5B)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.engineering_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('engineering_evidence'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('engineering_evidence_subtitle'),
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(body),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool live;

  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.body,
    required this.live,
  });

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (live)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(context.tr('source_live_badge')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _EdgeIntelligencePanel extends StatelessWidget {
  final SensorReading reading;

  const _EdgeIntelligencePanel({required this.reading});

  static bool hasTelemetry(SensorReading reading) =>
      reading.plantModelStatus.trim().isNotEmpty ||
      reading.plantModelConfidence != null ||
      reading.plantModelLearnedSamples != null ||
      reading.temporalState.trim().isNotEmpty ||
      reading.temporalPrimarySequence.trim().isNotEmpty ||
      reading.temporalConfidence != null ||
      reading.plausibilityState.trim().isNotEmpty ||
      reading.anomalyState.trim().isNotEmpty ||
      reading.predictionAvailable ||
      reading.predictionTarget.trim().isNotEmpty ||
      reading.predictionConfidence != null ||
      reading.sensorIntegrityState.trim().isNotEmpty ||
      reading.sensorIntegrityChannels.isNotEmpty ||
      reading.runtimeHealthState.trim().isNotEmpty ||
      reading.runtimeHealthIssue.trim().isNotEmpty ||
      reading.recoveryProgressPct != null ||
      reading.recoveryConfidence != null ||
      reading.recoveryVerified ||
      reading.bioContactState.trim().isNotEmpty ||
      reading.bioContactConfidence != null ||
      reading.bioSlowDriftMv != null ||
      reading.bioOpenLatched != null ||
      reading.bioReconnectVerifying != null ||
      reading.firmwareName.trim().isNotEmpty ||
      reading.firmwareBuildState.trim().isNotEmpty ||
      reading.recentEvents.isNotEmpty;

  static double _confidencePercent(double? value) {
    if (value == null || !value.isFinite) return 0;
    return value <= 1 ? value * 100 : value;
  }

  static String _confidence(double? value) => value == null
      ? ''
      : '${_confidencePercent(value).clamp(0, 100).round()}%';

  static String _label(String value) => value
      .trim()
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  bool get _hasPlantModel =>
      reading.plantModelStatus.trim().isNotEmpty ||
      reading.plantModelConfidence != null ||
      reading.plantModelLearnedSamples != null ||
      reading.plantModelBioBaselineMv != null;

  bool get _hasTemporal =>
      reading.temporalState.trim().isNotEmpty ||
      reading.temporalPrimarySequence.trim().isNotEmpty ||
      reading.temporalExplanation.trim().isNotEmpty ||
      reading.environmentToBioLagSec != null ||
      reading.actionToRecoveryLagSec != null;

  bool get _hasReliability =>
      reading.sensorIntegrityState.trim().isNotEmpty ||
      reading.plausibilityState.trim().isNotEmpty ||
      reading.anomalyState.trim().isNotEmpty ||
      reading.bioState.trim().isNotEmpty ||
      reading.bioSignalQuality > 0 ||
      reading.hasBioContactTelemetry ||
      reading.firmwareName.trim().isNotEmpty ||
      reading.firmwareBuildState.trim().isNotEmpty ||
      reading.reliabilityMode.trim().isNotEmpty;

  bool get _hasRecovery {
    final state = reading.recoveryStatus.trim().toUpperCase();
    return (state.isNotEmpty && state != 'NONE') ||
        reading.recoveryVerified ||
        reading.recoveryProgressPct != null ||
        reading.recoveryFarmerResult.trim().isNotEmpty;
  }

  bool get _hasRuntime =>
      reading.runtimeHealthState.trim().isNotEmpty ||
      reading.runtimeHealthIssue.trim().isNotEmpty ||
      reading.runtimeFreeHeap != null ||
      reading.runtimeLastLoopGapMs != null ||
      reading.runtimeLastSensorCycleMs != null;

  @override
  Widget build(BuildContext context) {
    final secondary =
        reading.rankedRootCauses.length > 1 ? reading.rankedRootCauses[1] : '';
    final connection =
        AppScope.of(context).sensorManager.hardwareConnectionMetadata;
    final activeTransport =
        AppScope.of(context).sensorManager.activeHardwareTransport;
    final events = [...reading.recentEvents]..sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'ESP32 Edge Intelligence',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(_label(reading.reliabilityMode)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _EdgeSection(
              title: 'Edge Analysis',
              children: [
                _EdgeDetailRow(
                  label: 'Plant state',
                  value: _label(reading.healthStatus),
                ),
                if (reading.primaryRootCause.trim().isNotEmpty)
                  _EdgeDetailRow(
                    label: 'Root cause',
                    value: _label(reading.primaryRootCause),
                  ),
                if (secondary.trim().isNotEmpty)
                  _EdgeDetailRow(
                    label: 'Secondary cause',
                    value: _label(secondary),
                  ),
                if (reading.analysisConfidence > 0)
                  _EdgeDetailRow(
                    label: 'Analysis confidence',
                    value: _confidence(reading.analysisConfidence),
                  ),
              ],
            ),
            if (_hasPlantModel)
              _EdgeSection(
                title: 'Individual Plant Model',
                children: [
                  _EdgeDetailRow(
                    label: 'Model status',
                    value: reading.plantModelReady
                        ? 'Ready'
                        : _label(
                            reading.plantModelStatus.isEmpty
                                ? 'LEARNING'
                                : reading.plantModelStatus,
                          ),
                  ),
                  if (reading.plantModelConfidence != null)
                    _EdgeDetailRow(
                      label: 'Confidence',
                      value: _confidence(reading.plantModelConfidence),
                    ),
                  if (reading.plantModelLearnedSamples != null)
                    _EdgeDetailRow(
                      label: 'Learned samples',
                      value: '${reading.plantModelLearnedSamples}',
                    ),
                  _EdgeDetailRow(
                    label: 'Baseline retained',
                    value: reading.plantModelPersisted ? 'Yes' : 'No',
                  ),
                  if (reading.plantModelBioBaselineMv != null)
                    _EdgeDetailRow(
                      label: 'Bio baseline',
                      value:
                          '${reading.plantModelBioBaselineMv!.toStringAsFixed(1)} mV',
                    ),
                  if (reading.plantModelTypicalBioVariationMv != null)
                    _EdgeDetailRow(
                      label: 'Typical variation',
                      value:
                          '${reading.plantModelTypicalBioVariationMv!.toStringAsFixed(1)} mV',
                    ),
                ],
              ),
            if (_hasTemporal)
              _EdgeSection(
                title: 'Cause-Response Intelligence',
                children: [
                  if (reading.temporalPrimarySequence.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Main sequence',
                      value: reading.temporalPrimarySequence.trim(),
                    )
                  else if (reading.temporalExplanation.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Main sequence',
                      value: reading.temporalExplanation.trim(),
                    ),
                  if (reading.environmentToBioLagSec != null)
                    _EdgeDetailRow(
                      label: 'Environment → bio lag',
                      value: '${reading.environmentToBioLagSec} s',
                    ),
                  if (reading.actionToRecoveryLagSec != null)
                    _EdgeDetailRow(
                      label: 'Action → recovery lag',
                      value: '${reading.actionToRecoveryLagSec} s',
                    ),
                  if (reading.temporalConfidence != null)
                    _EdgeDetailRow(
                      label: 'Confidence',
                      value: _confidence(reading.temporalConfidence),
                    ),
                ],
              ),
            if (reading.predictionAvailable)
              _EdgeSection(
                title: 'Prediction',
                children: [
                  if (reading.predictionTarget.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Target',
                      value: _label(reading.predictionTarget),
                    ),
                  if (reading.predictionMinutesToWarning != null)
                    _EdgeDetailRow(
                      label: 'Estimated time',
                      value: '~${reading.predictionMinutesToWarning} min',
                    ),
                  if (reading.predictionConfidence != null)
                    _EdgeDetailRow(
                      label: 'Confidence',
                      value: _confidence(reading.predictionConfidence),
                    ),
                  if (reading.predictionDirection.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Trend',
                      value: _label(reading.predictionDirection),
                    ),
                  if (reading.predictionMessage.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Outlook',
                      value: reading.predictionMessage.trim(),
                    ),
                ],
              ),
            if (_hasReliability)
              _EdgeSection(
                title: 'Signal & Sensor Reliability',
                children: [
                  if (reading.sensorIntegrityState.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Sensor integrity',
                      value: _label(reading.sensorIntegrityState),
                    ),
                  if (reading.sensorIntegrityPrimaryIssue.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Primary issue',
                      value: reading.sensorIntegrityPrimaryIssue.trim(),
                    ),
                  for (final entry in reading.sensorIntegrityChannels.entries)
                    _EdgeDetailRow(
                      label: _label(entry.key),
                      value: _label(entry.value),
                    ),
                  if (reading.plausibilityState.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Plausibility',
                      value: _label(reading.plausibilityState),
                    ),
                  if (reading.plausibilityConfidence != null)
                    _EdgeDetailRow(
                      label: 'Plausibility confidence',
                      value: _confidence(reading.plausibilityConfidence),
                    ),
                  if (reading.anomalyState.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Anomaly',
                      value: _label(reading.anomalyState),
                    ),
                  if (reading.anomalyConfidence != null)
                    _EdgeDetailRow(
                      label: 'Anomaly confidence',
                      value: _confidence(reading.anomalyConfidence),
                    ),
                  if (reading.anomalyExplanation.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Anomaly detail',
                      value: reading.anomalyExplanation.trim(),
                    ),
                  if (reading.anomalyAffectedChannel.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Affected channel',
                      value: _label(reading.anomalyAffectedChannel),
                    ),
                  if (reading.bioElectricalMeasurementAvailable)
                    _EdgeDetailRow(
                      label: 'Electrical signal quality',
                      value: '${reading.bioSignalQuality.round()}%',
                    ),
                  if (reading.bioContactState.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Electrode contact state',
                      value: _label(reading.bioContactState),
                    ),
                  if (reading.bioContactConfidence != null)
                    _EdgeDetailRow(
                      label: 'Contact confidence',
                      value: _confidence(reading.bioContactConfidence),
                    ),
                  if (reading.bioSlowDriftMv != null)
                    _EdgeDetailRow(
                      label: 'Slow drift',
                      value: '${reading.bioSlowDriftMv!.toStringAsFixed(1)} mV',
                    ),
                  if (reading.hasBioContactTelemetry)
                    _EdgeDetailRow(
                      label: 'Plant-analysis use',
                      value:
                          reading.bioPlantUseAllowed ? 'Enabled' : 'Disabled',
                    ),
                  if (reading.bioOpenLatched == true)
                    const _EdgeDetailRow(
                      label: 'Open-contact latch',
                      value: 'Open-contact latch active',
                    ),
                  if (reading.bioReconnectVerifying == true &&
                      reading.bioReconnectVerifySec != null)
                    _EdgeDetailRow(
                      label: 'Reconnect verification',
                      value: '${reading.bioReconnectVerifySec} / 26 s',
                    ),
                  if (reading.firmwareName.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Firmware',
                      value: reading.firmwareName.trim(),
                    ),
                  if (reading.firmwareBuildState.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Build state',
                      value: _label(reading.firmwareBuildState),
                    ),
                  _EdgeDetailRow(
                    label: 'Analysis reliability',
                    value: _label(reading.reliabilityMode),
                  ),
                ],
              ),
            _EdgeSection(
              title: 'Node & Connectivity',
              children: [
                _EdgeDetailRow(
                  label: 'Firmware',
                  value: reading.firmwareName.trim().isNotEmpty
                      ? reading.firmwareName.trim()
                      : (connection.firmwareVersion.trim().isEmpty
                          ? 'Not reported'
                          : connection.firmwareVersion.trim()),
                ),
                if (reading.firmwareEdition.trim().isNotEmpty ||
                    connection.firmwareEdition.trim().isNotEmpty)
                  _EdgeDetailRow(
                    label: 'Firmware edition',
                    value: reading.firmwareEdition.trim().isNotEmpty
                        ? reading.firmwareEdition.trim()
                        : connection.firmwareEdition.trim(),
                  ),
                if (reading.firmwareBuildState.trim().isNotEmpty ||
                    connection.buildState.trim().isNotEmpty)
                  _EdgeDetailRow(
                    label: 'Build state',
                    value: _label(
                      reading.firmwareBuildState.trim().isNotEmpty
                          ? reading.firmwareBuildState
                          : connection.buildState,
                    ),
                  ),
                _EdgeDetailRow(
                  label: 'Transport',
                  value: switch (activeTransport) {
                    HardwareTransportKind.local => 'Local direct',
                    HardwareTransportKind.remote => 'Remote cloud',
                    HardwareTransportKind.none => 'Unavailable',
                  },
                ),
                if (connection.localApActive != null)
                  _EdgeDetailRow(
                    label: 'Local AP active',
                    value: connection.localApActive! ? 'Yes' : 'No',
                  ),
                if (connection.internetConnected != null)
                  _EdgeDetailRow(
                    label: 'Internet connected',
                    value: connection.internetConnected! ? 'Yes' : 'No',
                  ),
                if (connection.cloudConnected != null)
                  _EdgeDetailRow(
                    label: 'Cloud sync connected',
                    value: connection.cloudConnected! ? 'Yes' : 'No',
                  ),
                if (connection.remoteNetworkState.trim().isNotEmpty)
                  _EdgeDetailRow(
                    label: 'Remote network state',
                    value: _label(connection.remoteNetworkState),
                  ),
                if (connection.lastSeen != null &&
                    activeTransport == HardwareTransportKind.remote)
                  _EdgeDetailRow(
                    label: 'Last cloud sync',
                    value:
                        '${connection.lastSeen!.toLocal().hour.toString().padLeft(2, '0')}:${connection.lastSeen!.toLocal().minute.toString().padLeft(2, '0')}:${connection.lastSeen!.toLocal().second.toString().padLeft(2, '0')}',
                  ),
                if (activeTransport == HardwareTransportKind.remote)
                  _EdgeDetailRow(
                    label: 'Snapshot freshness',
                    value: _label(connection.freshness.name),
                  ),
              ],
            ),
            if (_hasRecovery)
              _EdgeSection(
                title: 'Recovery',
                children: [
                  _EdgeDetailRow(
                    label: 'State',
                    value: reading.recoveryVerified
                        ? 'Recovery verified'
                        : _label(reading.recoveryStatus),
                  ),
                  if (reading.recoveryProgressPct != null)
                    _EdgeDetailRow(
                      label: 'Progress',
                      value:
                          '${reading.recoveryProgressPct!.clamp(0, 100).round()}%',
                    ),
                  if (reading.recoveryConfidence != null)
                    _EdgeDetailRow(
                      label: 'Confidence',
                      value: _confidence(reading.recoveryConfidence),
                    ),
                  if (reading.recoveryActionToResponseLagSec != null)
                    _EdgeDetailRow(
                      label: 'Action → response lag',
                      value: '${reading.recoveryActionToResponseLagSec} s',
                    ),
                  if (reading.recoveryFarmerResult.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Result',
                      value: reading.recoveryFarmerResult.trim(),
                    ),
                ],
              ),
            if (events.isNotEmpty)
              _EdgeSection(
                title: 'Recent Edge Events',
                children: [
                  for (final event in events.take(6))
                    _EdgeEventRow(event: event),
                ],
              ),
            if (_hasRuntime)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: const Text(
                  'Node Health',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: reading.runtimeHealthState.trim().isEmpty
                    ? null
                    : Text(_label(reading.runtimeHealthState)),
                children: [
                  if (reading.runtimeHealthIssue.trim().isNotEmpty)
                    _EdgeDetailRow(
                      label: 'Issue',
                      value: reading.runtimeHealthIssue.trim(),
                    ),
                  if (reading.runtimeFreeHeap != null)
                    _EdgeDetailRow(
                      label: 'Free heap',
                      value: '${reading.runtimeFreeHeap} B',
                    ),
                  if (reading.runtimeMinFreeHeap != null)
                    _EdgeDetailRow(
                      label: 'Minimum heap',
                      value: '${reading.runtimeMinFreeHeap} B',
                    ),
                  if (reading.runtimeLastLoopGapMs != null)
                    _EdgeDetailRow(
                      label: 'Last loop gap',
                      value: '${reading.runtimeLastLoopGapMs} ms',
                    ),
                  if (reading.runtimeMaxLoopGapMs != null)
                    _EdgeDetailRow(
                      label: 'Maximum loop gap',
                      value: '${reading.runtimeMaxLoopGapMs} ms',
                    ),
                  if (reading.runtimeLastSensorCycleMs != null)
                    _EdgeDetailRow(
                      label: 'Last sensor cycle',
                      value: '${reading.runtimeLastSensorCycleMs} ms',
                    ),
                  if (reading.runtimeMaxSensorCycleMs != null)
                    _EdgeDetailRow(
                      label: 'Maximum sensor cycle',
                      value: '${reading.runtimeMaxSensorCycleMs} ms',
                    ),
                  if (reading.runtimeOledI2cSkipTotal != null)
                    _EdgeDetailRow(
                      label: 'OLED I²C skips',
                      value: '${reading.runtimeOledI2cSkipTotal}',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EdgeSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _EdgeSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.7)),
          const SizedBox(height: 5),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }
}

class _EdgeDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _EdgeDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 138,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

class _EdgeEventRow extends StatelessWidget {
  final EdgeEvent event;

  const _EdgeEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final label = event.message.trim().isNotEmpty
        ? event.message.trim()
        : _EdgeIntelligencePanel._label(event.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 9,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
          if (event.timestamp != null) ...[
            const SizedBox(width: 8),
            Text(
              '${event.timestamp!.hour.toString().padLeft(2, '0')}:${event.timestamp!.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String detail;
  final bool complete;
  final bool last;

  const _PipelineStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.detail,
    required this.complete,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.13),
                foregroundColor: color,
                child: Text(
                  number,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (!last)
                Container(
                  width: 3,
                  height: 70,
                  color: color.withValues(alpha: 0.24),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(detail),
                      ],
                    ),
                  ),
                  Icon(
                    complete
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveTrialCard extends StatelessWidget {
  final EngineeringEvidenceService service;

  const _ActiveTrialCard({required this.service});

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio_button_checked_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('trial_recording'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Chip(label: Text(context.tr('active'))),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SmallMetric(
                    label: context.tr('samples'),
                    value: '${service.activeSampleCount}',
                  ),
                  _SmallMetric(
                    label: context.tr('minimum_health'),
                    value: '${service.activeMinimumHealth.toStringAsFixed(0)}%',
                  ),
                  _SmallMetric(
                    label: context.tr('maximum_stress'),
                    value: '${service.activeMaximumStress.toStringAsFixed(0)}%',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: service.cancelTrial,
                      child: Text(context.tr('cancel_trial')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showFinishTrial(context, service),
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(context.tr('finish_trial')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

Future<void> _showFinishTrial(
  BuildContext context,
  EngineeringEvidenceService service,
) async {
  var outcome = 'detected';
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
                context.tr('finish_trial'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: outcome,
                decoration: InputDecoration(
                  labelText: context.tr('trial_outcome'),
                ),
                items:
                    const ['detected', 'recovered', 'no_change', 'inconclusive']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(context.tr('outcome_$value')),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setSheetState(() => outcome = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: context.tr('notes')),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await service.finishTrial(
                      outcome: outcome,
                      notes: notes.text,
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: Text(context.tr('save_trial')),
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

class _TrialCard extends StatelessWidget {
  final ExperimentTrial trial;

  const _TrialCard({required this.trial});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trial.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Chip(label: Text(context.tr('outcome_${trial.outcome}'))),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${trial.crop} • ${trial.nodeId} • ${trial.source.toUpperCase()}',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 7,
                children: [
                  _InlineMetric(
                    icon: Icons.timer_outlined,
                    text: context.tr('trial_minutes', {
                      'value': trial.duration.inMinutes,
                    }),
                  ),
                  _InlineMetric(
                    icon: Icons.data_usage_rounded,
                    text: context
                        .tr('trial_samples', {'value': trial.sampleCount}),
                  ),
                  _InlineMetric(
                    icon: Icons.monitor_heart_outlined,
                    text: '${trial.minimumHealth.toStringAsFixed(0)}%',
                  ),
                ],
              ),
              if (trial.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(trial.notes),
              ],
            ],
          ),
        ),
      );
}

class _CalibrationStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final bool complete;
  final bool last;

  const _CalibrationStep({
    required this.number,
    required this.title,
    required this.body,
    required this.complete,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: complete
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: complete
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              child: complete
                  ? const Icon(Icons.check_rounded, size: 18)
                  : Text(number),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SmallMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineMetric({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 5), Text(text)],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _EmptyEvidence extends StatelessWidget {
  final String message;

  const _EmptyEvidence({required this.message});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(message, textAlign: TextAlign.center)),
        ),
      );
}
