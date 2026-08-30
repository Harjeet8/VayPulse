from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Missing expected block: {label}")
    return text.replace(old, new, 1)


# HOME — preserve every existing block; only add new surfaces and transitions.
path = Path("lib/screens/live_node_home_screen.dart")
text = path.read_text(encoding="utf-8")
if "../widgets/competition_intelligence_panels.dart" not in text:
    text = replace_once(
        text,
        "import '../widgets/biotic_stress_card.dart';\n",
        "import '../widgets/biotic_stress_card.dart';\nimport '../widgets/competition_intelligence_panels.dart';\n",
        "home competition import",
    )

if "CompetitionIntelligencePanels(" not in text:
    old = "              _WhatChangedCard(edge: edge),\n              if (edge?.degradedAnalysis == true || edge?.sensorFaults.isNotEmpty == true) ...[\n"
    new = """              _WhatChangedCard(edge: edge),
              const SizedBox(height: 12),
              CompetitionIntelligencePanels(
                current: reading,
                history: sensors.historyFor(reading.nodeId),
                edge: edge,
                telemetry: telemetry,
                live: live,
                connectionStatus: sensors.connectionStatus,
              ),
              if (edge?.degradedAnalysis == true || edge?.sensorFaults.isNotEmpty == true) ...[
"""
    text = replace_once(text, old, new, "home additive panels")

old_title = """          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  height: 1.12,
                ),
          ),
"""
new_title = """          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              title,
              key: ValueKey(title),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1.12,
                  ),
            ),
          ),
"""
if "key: ValueKey(title)" not in text:
    text = replace_once(text, old_title, new_title, "animated home finding")

old_summary = """          Text(
            summary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.38,
                ),
          ),
"""
new_summary = """          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: Text(
              summary,
              key: ValueKey(summary),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.38,
                  ),
            ),
          ),
"""
if "key: ValueKey(summary)" not in text:
    text = replace_once(text, old_summary, new_summary, "animated farmer summary")
path.write_text(text, encoding="utf-8")


# JUDGE VIEW — add evidence matrix beneath all existing diagnostics.
path = Path("lib/screens/judge_view_screen.dart")
text = path.read_text(encoding="utf-8")
if "../widgets/competition_intelligence_panels.dart" not in text:
    text = replace_once(
        text,
        "import '../services/sensor_data_provider.dart';\n",
        "import '../services/sensor_data_provider.dart';\nimport '../widgets/competition_intelligence_panels.dart';\n",
        "judge competition import",
    )
if "JudgeEvidenceMatrix(" not in text:
    old = """              _SensorEvidenceCard(
                telemetry: telemetry,
                edge: edge,
                packetAge: age,
              ),
              if (live) ...[
"""
    new = """              _SensorEvidenceCard(
                telemetry: telemetry,
                edge: edge,
                packetAge: age,
              ),
              const SizedBox(height: 12),
              JudgeEvidenceMatrix(
                edge: edge,
                telemetry: telemetry,
                history: reading == null
                    ? const []
                    : sensors.historyFor(reading.nodeId),
                current: reading,
                live: live,
                connectionStatus: sensors.connectionStatus,
              ),
              if (live) ...[
"""
    text = replace_once(text, old, new, "judge evidence matrix")
path.write_text(text, encoding="utf-8")


# SPLASH — layer technical telemetry over the existing particle/icon sequence.
path = Path("lib/screens/splash_screen.dart")
text = path.read_text(encoding="utf-8")
if "../widgets/boot_intelligence_overlay.dart" not in text:
    text = replace_once(
        text,
        "import '../l10n/app_strings.dart';\n",
        "import '../l10n/app_strings.dart';\nimport '../widgets/boot_intelligence_overlay.dart';\n",
        "splash overlay import",
    )
text = text.replace(
    "duration: const Duration(milliseconds: 3600),",
    "duration: const Duration(milliseconds: 4100),",
    1,
)
text = text.replace(
    "_timer = Timer(const Duration(milliseconds: 4250), _openApp);",
    "_timer = Timer(const Duration(milliseconds: 4750), _openApp);",
    1,
)
if "BootIntelligenceOverlay(" not in text:
    old = """              IgnorePointer(
                child: CustomPaint(
                  painter: _SignalFieldPainter(phase: ambient),
                ),
              ),
              SafeArea(
"""
    new = """              IgnorePointer(
                child: CustomPaint(
                  painter: _SignalFieldPainter(phase: ambient),
                ),
              ),
              IgnorePointer(
                child: BootIntelligenceOverlay(
                  progress: timeline,
                  phase: ambient,
                ),
              ),
              SafeArea(
"""
    text = replace_once(text, old, new, "advanced boot overlay")
path.write_text(text, encoding="utf-8")

print("Final additive integration patched successfully.")
