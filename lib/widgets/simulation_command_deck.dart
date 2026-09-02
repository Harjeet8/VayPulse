import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_scope.dart';
import '../services/sensor_data_provider.dart';

class SimulationCommandDeck extends StatefulWidget {
  const SimulationCommandDeck({super.key});

  @override
  State<SimulationCommandDeck> createState() => _SimulationCommandDeckState();
}

class _SimulationCommandDeckState extends State<SimulationCommandDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _storyRunning = false;

  static const _story = <String>[
    'healthy',
    'baseline_learning',
    'atmospheric_drying',
    'bio_response',
    'recovery',
  ];

  static const _meta = <String, _ScenarioMeta>{
    'healthy': _ScenarioMeta(
      'Healthy farm',
      'See normal soil, weather and plant readings',
      Icons.eco_rounded,
    ),
    'baseline_learning': _ScenarioMeta(
      'Plant learning',
      'See how the app learns the plant’s normal signal',
      Icons.memory_rounded,
    ),
    'atmospheric_drying': _ScenarioMeta(
      'Dry air',
      'Air pulls water quickly while the soil is still moist',
      Icons.air_rounded,
    ),
    'dry': _ScenarioMeta(
      'Dry soil',
      'See what happens when root-zone moisture falls',
      Icons.water_drop_outlined,
    ),
    'overwatered': _ScenarioMeta(
      'Soil too wet',
      'See how excess root-zone water changes the result',
      Icons.water_rounded,
    ),
    'heat_stress': _ScenarioMeta(
      'Heat stress',
      'Hot air raises water loss and plant stress',
      Icons.device_thermostat_rounded,
    ),
    'bio_response': _ScenarioMeta(
      'Plant signal change',
      'The plant signal changes before one clear cause is found',
      Icons.electric_bolt_rounded,
    ),
    'recovery': _ScenarioMeta(
      'Recovery',
      'See the plant result improve after conditions become safer',
      Icons.restore_rounded,
    ),
    'biotic_risk': _ScenarioMeta(
      'Possible pest or disease',
      'Practice checking visible signs without claiming a diagnosis',
      Icons.biotech_outlined,
    ),
    'low_light': _ScenarioMeta(
      'Low light',
      'Daylight falls below the expected farm range',
      Icons.wb_twilight_rounded,
    ),
    'critical': _ScenarioMeta(
      'Several stresses',
      'Heat, dry soil and plant response all need action',
      Icons.warning_amber_rounded,
    ),
    'sensor_fault': _ScenarioMeta(
      'Sensor problem',
      'A bad sensor is ignored instead of creating a false warning',
      Icons.sensors_off_rounded,
    ),
    'offline': _ScenarioMeta(
      'Farm offline',
      'No new demo reading is shown as live data',
      Icons.wifi_off_rounded,
    ),
  };

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _runStory() async {
    if (_storyRunning) return;
    final scope = AppScope.of(context);
    setState(() => _storyRunning = true);
    await HapticFeedback.mediumImpact();
    try {
      for (final scenario in _story) {
        if (!mounted || scope.sensorManager.source != SensorDataSource.simulation) {
          break;
        }
        if (scope.sensorManager.scenarioIds.contains(scenario)) {
          scope.sensorManager.setScenario(scenario);
        }
        await Future<void>.delayed(const Duration(milliseconds: 1900));
      }
    } finally {
      if (mounted) setState(() => _storyRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.sensorManager, _pulse]),
      builder: (context, _) {
        if (scope.sensorManager.source != SensorDataSource.simulation) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final selected = scope.sensorManager.scenarioId;
        final ids = scope.sensorManager.scenarioIds;
        final meta = _meta[selected] ??
            _ScenarioMeta(
              selected.replaceAll('_', ' '),
              'Clearly-labelled simulated evidence',
              Icons.science_outlined,
            );
        final wave = reduceMotion ? 0.35 : _pulse.value;

        return TweenAnimationBuilder<double>(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.96, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 18),
              child: Transform.scale(scale: value, child: child),
            ),
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer.withValues(alpha: 0.68),
                  colors.surfaceContainerHighest.withValues(alpha: 0.54),
                  colors.surface,
                ],
              ),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.07),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SimulationFieldPainter(
                        phase: wave,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: colors.primary.withValues(alpha: 0.12),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Icon(Icons.science_outlined,
                                color: colors.primary),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FARM PRACTICE MODE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose a farm condition to see how PhytoSense responds',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PulseDot(
                                  phase: wave,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DEMO ONLY',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.03, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Container(
                          key: ValueKey(selected),
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: colors.primary.withValues(alpha: 0.1),
                                ),
                                child: Icon(meta.icon, color: colors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meta.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      meta.description,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        height: 46,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ids.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final id = ids[index];
                            final item = _meta[id] ??
                                _ScenarioMeta(
                                  id.replaceAll('_', ' '),
                                  'Simulated scenario',
                                  Icons.science_outlined,
                                );
                            final active = id == selected;
                            return _ScenarioChip(
                              meta: item,
                              active: active,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                scope.sensorManager.setScenario(id);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Practice with demo farm values. They never mix with ESP32 readings.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonalIcon(
                            onPressed: _storyRunning ? null : _runStory,
                            icon: _storyRunning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              _storyRunning ? 'RUNNING' : 'PLAY DEMO',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScenarioChip extends StatelessWidget {
  final _ScenarioMeta meta;
  final bool active;
  final VoidCallback onTap;

  const _ScenarioChip({
    required this.meta,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? colors.primary.withValues(alpha: 0.13)
                : colors.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active
                  ? colors.primary.withValues(alpha: 0.34)
                  : colors.outlineVariant.withValues(alpha: 0.52),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                scale: active ? 1.08 : 1,
                child: Icon(
                  meta.icon,
                  size: 18,
                  color: active ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                meta.title,
                style: TextStyle(
                  color: active ? colors.primary : null,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  final double phase;
  final Color color;

  const _PulseDot({required this.phase, required this.color});

  @override
  Widget build(BuildContext context) {
    final wave = 0.68 + 0.32 * (1 - (phase * 2 - 1).abs());
    return Transform.scale(
      scale: wave,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulationFieldPainter extends CustomPainter {
  final double phase;
  final Color color;

  const _SimulationFieldPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.07);
    final y = size.height * (0.18 + 0.64 * phase);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final node = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + i * 0.12);
      final dy = size.height * (0.15 + ((i * 0.19 + phase) % 0.7));
      node.color = color.withValues(alpha: 0.04 + (i % 3) * 0.018);
      canvas.drawCircle(Offset(x, dy), 2 + (i % 2).toDouble(), node);
    }
  }

  @override
  bool shouldRepaint(covariant _SimulationFieldPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}

class _ScenarioMeta {
  final String title;
  final String description;
  final IconData icon;

  const _ScenarioMeta(this.title, this.description, this.icon);
}
