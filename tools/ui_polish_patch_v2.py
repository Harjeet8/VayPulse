from pathlib import Path

ROOT = Path('competition')

def edit(path, fn):
    p = ROOT / path
    text = p.read_text(encoding='utf-8')
    new = fn(text)
    p.write_text(new, encoding='utf-8')

# Home integration.
def home_patch(text):
    if "import '../widgets/simulation_command_deck.dart';" not in text:
        text = text.replace(
            "import '../widgets/data_source_card.dart';\n",
            "import '../widgets/data_source_card.dart';\nimport '../widgets/simulation_command_deck.dart';\n",
            1,
        )
    marker = "            const DataSourceCard(),\n            const SizedBox(height: 10),\n            _ConnectionStrip("
    if 'const SimulationCommandDeck()' not in text and marker in text:
        text = text.replace(
            marker,
            "            const DataSourceCard(),\n            if (!live) ...[\n              const SizedBox(height: 12),\n              const SimulationCommandDeck(),\n            ],\n            const SizedBox(height: 10),\n            _ConnectionStrip(",
            1,
        )
    return text
edit('lib/screens/live_node_home_screen.dart', home_patch)

# Splash motion integration.
def splash_patch(text):
    if "import '../widgets/boot_motion_polish.dart';" not in text:
        text = text.replace(
            "import '../widgets/boot_intelligence_overlay.dart';\n",
            "import '../widgets/boot_intelligence_overlay.dart';\nimport '../widgets/boot_motion_polish.dart';\n",
            1,
        )
    if 'child: BootMotionPolish(' not in text:
        marker = """              IgnorePointer(
                child: BootIntelligenceOverlay(
                  progress: timeline,
                  phase: ambient,
                ),
              ),
              SafeArea("""
        replacement = """              IgnorePointer(
                child: BootIntelligenceOverlay(
                  progress: timeline,
                  phase: ambient,
                ),
              ),
              IgnorePointer(
                child: BootMotionPolish(
                  progress: timeline,
                  phase: ambient,
                ),
              ),
              SafeArea("""
        if marker in text:
            text = text.replace(marker, replacement, 1)
    return text
edit('lib/screens/splash_screen.dart', splash_patch)

# Calibre card and Digital Plant Twin motion.
def calibre_patch(text):
    old_core = """                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.38),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 54,
                    color: accent,
                  ),
                ),
"""
    if '_BreathingTwinCore(accent: accent, stress: stress)' not in text and old_core in text:
        text = text.replace(old_core, "                _BreathingTwinCore(accent: accent, stress: stress),\n", 1)

    old_premium = """  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
"""
    new_premium = """  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.975, end: 1),
      builder: (context, value, content) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: Transform.scale(scale: value, child: content),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.22),
              colors.surfaceContainerHighest.withValues(alpha: 0.32),
              colors.surface,
            ],
          ),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.045),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.14)),
                    ),
                    child: Icon(icon, color: colors.primary),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
"""
    if 'TweenAnimationBuilder<double>(' not in text[text.find('class _PremiumCard'):text.find('class _TwinBadge')]:
        if old_premium in text:
            text = text.replace(old_premium, new_premium, 1)

    breathing = """class _BreathingTwinCore extends StatefulWidget {
  final Color accent;
  final double stress;

  const _BreathingTwinCore({required this.accent, required this.stress});

  @override
  State<_BreathingTwinCore> createState() => _BreathingTwinCoreState();
}

class _BreathingTwinCoreState extends State<_BreathingTwinCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = reduceMotion ? 0.35 : Curves.easeInOut.transform(_controller.value);
        final severity = (widget.stress / 100).clamp(0.0, 1.0).toDouble();
        final scale = 1 + phase * (0.018 + severity * 0.018);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.accent.withValues(alpha: 0.18 + phase * 0.04),
                  widget.accent.withValues(alpha: 0.07),
                ],
              ),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.34 + phase * 0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.09 + phase * 0.07),
                  blurRadius: 28 + phase * 12,
                  spreadRadius: 2 + phase * 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.eco_rounded, size: 54, color: widget.accent),
                Positioned(
                  bottom: 15,
                  child: Container(
                    width: 30 + severity * 18,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: widget.accent.withValues(alpha: 0.55),
                    ),
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

"""
    if 'class _BreathingTwinCore extends StatefulWidget' not in text:
        marker = 'class _TwinBadge extends StatelessWidget {\n'
        if marker in text:
            text = text.replace(marker, breathing + marker, 1)
    return text
edit('lib/widgets/calibre_upgrade_panels.dart', calibre_patch)

# Finish the remaining simulator warning by actually supplying counter-evidence.
def sim_patch(text):
    if 'Root-zone moisture remains adequate, so air demand is a contributor' not in text:
        marker = "          secondaryEvidence: 'Air temperature is ${reading.temperature.toStringAsFixed(1)} °C.',\n"
        if marker in text:
            text = text.replace(
                marker,
                marker + "          secondaryCounterEvidence: 'Root-zone moisture remains adequate, so air demand is a contributor rather than a complete water-deficit diagnosis.',\n",
                1,
            )
    return text
edit('lib/simulation/simulation_intelligence_v2.dart', sim_patch)

# Human-readable labels for the new simulation states.
def strings_patch(text):
    if "'scenario_baseline_learning': 'Baseline learning'" not in text:
        marker = "      'scenario_healthy': 'Healthy farm',\n"
        if marker in text:
            text = text.replace(
                marker,
                marker +
                "      'scenario_baseline_learning': 'Baseline learning',\n"
                "      'scenario_atmospheric_drying': 'Atmospheric drying',\n"
                "      'scenario_bio_response': 'Plant bioelectric response',\n"
                "      'scenario_recovery': 'Recovery',\n"
                "      'scenario_biotic_risk': 'Disease-conducive risk',\n",
                1,
            )
    return text
edit('lib/l10n/app_strings.dart', strings_patch)

print('UI polish v2 applied')
