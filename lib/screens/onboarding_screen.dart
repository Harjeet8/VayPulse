import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../widgets/plant_pulse.dart';
import '../widgets/phyto_ui.dart';
import 'shell_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = [
      (
        Icons.map_outlined,
        'onboarding_monitor_title',
        'onboarding_monitor_body',
      ),
      (
        Icons.psychology_alt_outlined,
        'onboarding_understand_title',
        'onboarding_understand_body',
      ),
      (
        Icons.task_alt_rounded,
        'onboarding_act_title',
        'onboarding_act_body',
      ),
      (
        Icons.tune_rounded,
        'onboarding_experience_title',
        'onboarding_experience_body',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [phytoGreen, phytoLeaf],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.eco, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PhytoSense AI',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: (value) => setState(() => page = value),
                itemCount: data.length,
                itemBuilder: (context, index) => SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(42),
                            ),
                            child: Icon(
                              data[index].$1,
                              size: 62,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 240,
                            child: PlantPulse(
                              color: Theme.of(context).colorScheme.primary,
                              height: 42,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.tr(data[index].$2),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.7,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr(data[index].$3),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.5),
                          ),
                          if (index == data.length - 1) ...[
                            const SizedBox(height: 20),
                            ExperienceModeSelector(
                              selected: AppScope.of(context)
                                  .settings
                                  .value
                                  .experienceMode,
                              onChanged: AppScope.of(context)
                                  .settings
                                  .setExperienceMode,
                              farmerTitle: context.tr('farmer_mode'),
                              farmerBody: context.tr('farmer_mode_body'),
                              judgeTitle: context.tr('judge_mode'),
                              judgeBody: context.tr('judge_mode_body'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                data.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: index == page ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: index == page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (page < data.length - 1) {
                        await controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                        return;
                      }
                      await AppScope.of(context).settings.completeOnboarding();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ShellScreen()),
                      );
                    },
                    icon: Icon(page == data.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.navigate_next_rounded),
                    label: Text(context.tr(
                      page == data.length - 1 ? 'get_started' : 'next',
                    )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
