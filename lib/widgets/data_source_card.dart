import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';

class DataSourceCard extends StatelessWidget {
  const DataSourceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.settings, scope.sensorManager]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final live = scope.sensorManager.source == SensorDataSource.esp32;
        final connected = scope.sensorManager.connected;
        final accent = live
            ? const Color(0xFF2879B9)
            : const Color(0xFFE18A28);
        final scenario = context.tr(
          'scenario_${scope.sensorManager.scenarioId}',
        );
        final statusText = live
            ? (connected
                ? _sourceText(
                    context,
                    'Real readings are coming from the ESP32 node.',
                    'ESP32 node-இலிருந்து நேரடி மதிப்புகள் வருகின்றன.',
                  )
                : _sourceText(
                    context,
                    'Waiting for ESP32 — no live plant values are shown.',
                    'ESP32-க்காக காத்திருக்கிறது — நேரடி செடி மதிப்புகள் காட்டப்படவில்லை.',
                  ))
            : _sourceText(
                context,
                'Practice farm: $scenario. These are demo values.',
                'பயிற்சி பண்ணை: $scenario. இவை demo மதிப்புகள்.',
              );

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.97, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(opacity: value, child: child),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(27),
              onTap: () => _showSourcePicker(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.12),
                      colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      colors.surface,
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: live && connected ? 0.3 : 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 340),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Icon(
                          live ? Icons.memory_rounded : Icons.science_outlined,
                          key: ValueKey(live),
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  child: Text(
                                    live
                                        ? _sourceText(
                                            context,
                                            'ESP32 real sensors',
                                            'ESP32 நேரடி சென்சார்கள்',
                                          )
                                        : _sourceText(
                                            context,
                                            'Practice Farm',
                                            'பயிற்சி பண்ணை',
                                          ),
                                    key: ValueKey(live),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusDot(
                                color: accent,
                                active: live ? connected : true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.12),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: Text(
                              statusText,
                              key: ValueKey(statusText),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            live
                                ? _sourceText(
                                    context,
                                    'REAL DATA',
                                    'நேரடி DATA',
                                  )
                                : _sourceText(
                                    context,
                                    'DEMO DATA',
                                    'DEMO DATA',
                                  ),
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSourcePicker(BuildContext context) async {
    final scope = AppScope.of(context);
    final selected = await showModalBottomSheet<SensorDataSource>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.86,
        child: Scrollbar(
          child: ListView(
            primary: true,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('choose_data_source'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FarmerLanguage.label(context, 'source_separation'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SourceOption(
                icon: Icons.agriculture_outlined,
                title: _sourceText(
                  context,
                  'Practice Farm',
                  'பயிற்சி பண்ணை',
                ),
                body: _sourceText(
                  context,
                  'Practice common farm conditions without an ESP32. Every value is clearly marked as demo data.',
                  'ESP32 இல்லாமல் பண்ணை நிலைகளை பயிற்சி செய்யலாம். எல்லா மதிப்புகளும் demo data என்று தெளிவாக காட்டப்படும்.',
                ),
                selected:
                    scope.sensorManager.source == SensorDataSource.simulation,
                badge: 'PRACTICE FARM',
                onTap: () => Navigator.pop(
                  sheetContext,
                  SensorDataSource.simulation,
                ),
              ),
              const SizedBox(height: 11),
              _SourceOption(
                icon: Icons.memory_rounded,
                title: _sourceText(
                  context,
                  'ESP32 real sensors',
                  'ESP32 நேரடி சென்சார்கள்',
                ),
                body: _sourceText(
                  context,
                  'Shows only fresh readings measured by the physical plant node. If it disconnects, live analysis stops.',
                  'Plant node அளக்கும் புதிய மதிப்புகளை மட்டும் காட்டும். இணைப்பு துண்டித்தால் நேரடி பகுப்பாய்வு நிற்கும்.',
                ),
                selected: scope.sensorManager.source == SensorDataSource.esp32,
                badge: 'REAL SENSORS',
                onTap: () => Navigator.pop(
                  sheetContext,
                  SensorDataSource.esp32,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _sourceText(
                          context,
                          'Demo and ESP32 readings always stay separate. They are never mixed.',
                          'Demo மற்றும் ESP32 மதிப்புகள் எப்போதும் தனித்தனியாக இருக்கும். அவை கலக்கப்படாது.',
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    if (selected == scope.sensorManager.source) return;
    await HapticFeedback.mediumImpact();
    final sourceId =
        selected == SensorDataSource.esp32 ? 'esp32' : 'simulation';
    await scope.settings.setDataSource(sourceId);
    scope.alerts.clear();
    scope.sensorManager.configure(
      source: selected,
      endpoint: scope.settings.value.esp32Endpoint,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          selected == SensorDataSource.esp32
              ? context.tr('live_workspace_enabled')
              : FarmerLanguage.label(context, 'simulation_enabled'),
        ),
      ),
    );
  }
}

String _sourceText(BuildContext context, String english, String tamil) =>
    FarmerLanguage.isTamil(context) ? tamil : english;

class _StatusDot extends StatelessWidget {
  final Color color;
  final bool active;

  const _StatusDot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : Theme.of(context).colorScheme.outline,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      );
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String badge;
  final bool selected;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.42)
                : colors.surfaceContainerHighest.withValues(alpha: 0.38),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.34)
                  : colors.outlineVariant.withValues(alpha: 0.46),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: colors.primary),
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
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(selected),
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
