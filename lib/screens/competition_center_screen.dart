import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../widgets/page_frame.dart';
import 'presentation_mode_screen.dart';

class CompetitionCenterScreen extends StatelessWidget {
  const CompetitionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('competition_center'))),
        body: PageFrame(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF102F25), Color(0xFF176B4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      context.tr('judge_ready_workspace'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('competition_hero_title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('competition_hero_body'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: phytoGreen,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PresentationModeScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(context.tr('start_judge_demo')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle(context.tr('project_case')),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final cards = [
                  _CaseCard(
                    icon: Icons.report_problem_outlined,
                    title: context.tr('problem_title'),
                    body: context.tr('problem_body'),
                    color: phytoTerracotta,
                  ),
                  _CaseCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: context.tr('solution_title'),
                    body: context.tr('solution_body'),
                    color: phytoGreen,
                  ),
                ];
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards.first),
                          const SizedBox(width: 12),
                          Expanded(child: cards.last),
                        ],
                      )
                    : Column(
                        children: [
                          cards.first,
                          const SizedBox(height: 12),
                          cards.last
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),
            _SectionTitle(context.tr('innovation_pillars')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pillar(
                  icon: Icons.psychology_alt_outlined,
                  title: context.tr('pillar_explainable'),
                  body: context.tr('pillar_explainable_body'),
                ),
                _Pillar(
                  icon: Icons.translate_rounded,
                  title: context.tr('pillar_accessible'),
                  body: context.tr('pillar_accessible_body'),
                ),
                _Pillar(
                  icon: Icons.offline_bolt_outlined,
                  title: context.tr('pillar_resilient'),
                  body: context.tr('pillar_resilient_body'),
                ),
                _Pillar(
                  icon: Icons.hub_outlined,
                  title: context.tr('pillar_scalable'),
                  body: context.tr('pillar_scalable_body'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(context.tr('system_architecture')),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _ArchitectureStep(
                      index: '01',
                      title: context.tr('architecture_sense'),
                      body: context.tr('architecture_sense_body'),
                    ),
                    _ArchitectureStep(
                      index: '02',
                      title: context.tr('architecture_connect'),
                      body: context.tr('architecture_connect_body'),
                    ),
                    _ArchitectureStep(
                      index: '03',
                      title: context.tr('architecture_understand'),
                      body: context.tr('architecture_understand_body'),
                    ),
                    _ArchitectureStep(
                      index: '04',
                      title: context.tr('architecture_act'),
                      body: context.tr('architecture_act_body'),
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(context.tr('deployment_impact')),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _ImpactRow(
                      icon: Icons.sensors_rounded,
                      label: context.tr('impact_prototype_scope'),
                      value: context.tr('impact_one_node'),
                    ),
                    _ImpactRow(
                      icon: Icons.wifi_tethering_rounded,
                      label: context.tr('impact_connectivity'),
                      value: context.tr('impact_local_first'),
                    ),
                    _ImpactRow(
                      icon: Icons.account_tree_outlined,
                      label: context.tr('impact_scale_path'),
                      value: context.tr('impact_add_nodes'),
                    ),
                    _ImpactRow(
                      icon: Icons.front_hand_outlined,
                      label: context.tr('impact_decision_model'),
                      value: context.tr('impact_farmer_control'),
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(context.tr('evidence_lab')),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('validation_status'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(context.tr('validation_transparency')),
                    const SizedBox(height: 16),
                    _ReadinessRow(
                      label: context.tr('validation_app'),
                      status: context.tr('status_complete'),
                      complete: true,
                    ),
                    _ReadinessRow(
                      label: context.tr('validation_api'),
                      status: context.tr('status_complete'),
                      complete: true,
                    ),
                    _ReadinessRow(
                      label: context.tr('validation_camera'),
                      status: context.tr('status_complete'),
                      complete: true,
                    ),
                    _ReadinessRow(
                      label: context.tr('validation_weather_voice'),
                      status: context.tr('status_complete'),
                      complete: true,
                    ),
                    _ReadinessRow(
                      label: context.tr('validation_offline_sync'),
                      status: context.tr('status_complete'),
                      complete: true,
                    ),
                    _ReadinessRow(
                      label: context.tr('validation_hardware'),
                      status: context.tr('status_ready'),
                      complete: true,
                    ),
                    _ReadinessRow(
                      label: context.tr('validation_trained_model'),
                      status: context.tr('status_complete'),
                      complete: true,
                    ),
                    _ReadinessRow(
                      label: context.tr('validation_field_trials'),
                      status: context.tr('status_ready'),
                      complete: true,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(context.tr('validation_note'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(context.tr('judge_questions')),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _Question(
                    question: context.tr('judge_q_ai'),
                    answer: context.tr('judge_a_ai'),
                  ),
                  const Divider(height: 1),
                  _Question(
                    question: context.tr('judge_q_novel'),
                    answer: context.tr('judge_a_novel'),
                  ),
                  const Divider(height: 1),
                  _Question(
                    question: context.tr('judge_q_scale'),
                    answer: context.tr('judge_a_scale'),
                  ),
                  const Divider(height: 1),
                  _Question(
                    question: context.tr('judge_q_false_alert'),
                    answer: context.tr('judge_a_false_alert'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
      );
}

class _CaseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _CaseCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(body),
            ],
          ),
        ),
      );
}

class _Pillar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Pillar({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 245,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _ArchitectureStep extends StatelessWidget {
  final String index;
  final String title;
  final String body;
  final bool last;
  const _ArchitectureStep({
    required this.index,
    required this.title,
    required this.body,
    this.last = false,
  });
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(index,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900)),
                ),
                if (!last)
                  Container(
                    width: 2,
                    height: 54,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
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
          ),
        ],
      );
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final String status;
  final bool complete;
  const _ReadinessRow({
    required this.label,
    required this.status,
    required this.complete,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(
              complete ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: complete ? phytoLeaf : phytoAmber,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(status,
                style: TextStyle(
                    color: complete ? phytoLeaf : phytoAmber,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _ImpactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;

  const _ImpactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 11),
            Expanded(child: Text(label)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

class _Question extends StatelessWidget {
  final String question;
  final String answer;
  const _Question({required this.question, required this.answer});
  @override
  Widget build(BuildContext context) => ExpansionTile(
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.w800)),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(answer)],
      );
}
