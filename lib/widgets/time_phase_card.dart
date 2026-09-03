import 'dart:async';

import 'package:flutter/material.dart';

import 'live_motion.dart';

/// A compact clock and daylight window for both simulation and ESP32 modes.
/// ESP32 firmware phase always wins when it is available.
class TimePhaseCard extends StatefulWidget {
  final bool live;
  final String? espDayPhase;

  const TimePhaseCard({
    super.key,
    required this.live,
    this.espDayPhase,
  });

  @override
  State<TimePhaseCard> createState() => _TimePhaseCardState();
}

class _TimePhaseCardState extends State<TimePhaseCard> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firmwarePhase = _phaseFromFirmware(widget.espDayPhase);
    final isDay = widget.live && firmwarePhase != null
        ? firmwarePhase
        : _now.hour >= 6 && _now.hour < 19;
    final phase = isDay ? 'DAY' : 'NIGHT';
    final hasFirmwarePhase = widget.live && firmwarePhase != null;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(_now),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final date = MaterialLocalizations.of(context).formatFullDate(_now);
    final accent = isDay ? colors.tertiary : colors.secondary;
    final background = isDay
        ? colors.tertiaryContainer.withValues(alpha: 0.30)
        : colors.secondaryContainer.withValues(alpha: 0.30);

    return Semantics(
      label: '$time, $date, $phase',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardTheme.color ?? colors.surface,
              background,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Container(
                key: ValueKey(phase),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: LiveMotionIcon(
                  icon: isDay
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                  color: accent,
                  size: 27,
                  style: isDay
                      ? LiveMotionStyle.orbit
                      : LiveMotionStyle.breathe,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Text(
                      time,
                      key: ValueKey(time),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.55,
                          ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: Container(
                    key: ValueKey(phase),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      phase,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasFirmwarePhase ? 'ESP32 PHASE' : 'LOCAL PHASE',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool? _phaseFromFirmware(String? raw) {
    final phase = raw?.trim().toUpperCase();
    if (phase == null || phase.isEmpty) return null;
    if (phase.contains('NIGHT') ||
        phase.contains('DARK') ||
        phase.contains('DUSK')) {
      return false;
    }
    if (phase.contains('DAY') ||
        phase.contains('LIGHT') ||
        phase.contains('DAWN')) {
      return true;
    }
    return null;
  }
}
