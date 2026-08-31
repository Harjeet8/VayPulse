from pathlib import Path

ROOT = Path('competition')

def replace(path, old, new, count=1):
    p = ROOT / path
    text = p.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'Expected block not found in {path}: {old[:80]!r}')
    p.write_text(text.replace(old, new, count), encoding='utf-8')

# Home: add dedicated Simulation Lab directly beneath the source selector.
replace(
    'lib/screens/live_node_home_screen.dart',
    "import '../widgets/data_source_card.dart';\n",
    "import '../widgets/data_source_card.dart';\nimport '../widgets/simulation_command_deck.dart';\n",
)
replace(
    'lib/screens/live_node_home_screen.dart',
    "            const DataSourceCard(),\n            const SizedBox(height: 10),\n            _ConnectionStrip(",
    "            const DataSourceCard(),\n            if (!live) ...[\n              const SizedBox(height: 12),\n              const SimulationCommandDeck(),\n            ],\n            const SizedBox(height: 10),\n            _ConnectionStrip(",
)

# Splash: retain both existing layers and add refined signal-flow motion.
replace(
    'lib/screens/splash_screen.dart',
    "import '../widgets/boot_intelligence_overlay.dart';\n",
    "import '../widgets/boot_intelligence_overlay.dart';\nimport '../widgets/boot_motion_polish.dart';\n",
)
replace(
    'lib/screens/splash_screen.dart',
    "              IgnorePointer(\n                child: BootIntelligenceOverlay(\n                  progress: timeline,\n                  phase: ambient,\n                ),\n              ),\n              SafeArea(",
    "              IgnorePointer(\n                child: BootIntelligenceOverlay(\n                  progress: timeline,\n                  phase: ambient,\n                ),\n              ),\n              IgnorePointer(\n                child: BootMotionPolish(\n                  progress: timeline,\n                  phase: ambient,\n                ),\n              ),\n              SafeArea(",
)

# Calibre UI: remove stale local, upgrade plant twin core, and premium-card motion.
replace(
    'lib/widgets/calibre_upgrade_panels.dart',
    "    final colors = Theme.of(context).colorScheme;\n",
    "",
)
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
replace(
    'lib/widgets/calibre_upgrade_panels.dart',
    old_core,
    "                _BreathingTwinCore(accent: accent, stress: stress),\n",
)
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
replace('lib/widgets/calibre_upgrade_panels.dart', old_premium, new_premium)

insert_before = "class _TwinBadge extends StatelessWidget {\n"
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
replace('lib/widgets/calibre_upgrade_panels.dart', insert_before, breathing + insert_before)

# Strict-analyzer cleanup from the simulator v2 upgrade.
replace(
    'lib/simulation/simulation_intelligence_v2.dart',
    "          secondaryEvidence: 'Air temperature is ${reading.temperature.toStringAsFixed(1)} °C.',\n",
    "          secondaryEvidence: 'Air temperature is ${reading.temperature.toStringAsFixed(1)} °C.',\n          secondaryCounterEvidence: 'Root-zone moisture remains adequate, so air demand is a contributor rather than a complete water-deficit diagnosis.',\n",
)
text_path = ROOT / 'lib/simulation/simulation_intelligence_v2.dart'
text = text_path.read_text(encoding='utf-8')
text = text.replace('          ranked: [\n            RootCauseCandidate(', '          ranked: const [\n            RootCauseCandidate(', 2)
text = text.replace('      case DemoMode.critical:\n        return _ScenarioAnalysis(', '      case DemoMode.critical:\n        return const _ScenarioAnalysis(', 1)
text_path.write_text(text, encoding='utf-8')

# Human-readable labels for newly-added simulator states.
replace(
    'lib/l10n/app_strings.dart',
    "      'scenario_healthy': 'Healthy farm',\n",
    "      'scenario_healthy': 'Healthy farm',\n      'scenario_baseline_learning': 'Baseline learning',\n      'scenario_atmospheric_drying': 'Atmospheric drying',\n      'scenario_bio_response': 'Plant bioelectric response',\n      'scenario_recovery': 'Recovery',\n      'scenario_biotic_risk': 'Disease-conducive risk',\n",
)

print('UI polish patch applied successfully')
