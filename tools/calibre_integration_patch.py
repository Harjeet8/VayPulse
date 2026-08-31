from pathlib import Path
import re

root = Path('competition')

# 1) Static-safety cleanup in the additive calibre widget.
p = root / 'lib/widgets/calibre_upgrade_panels.dart'
s = p.read_text()
s = s.replace('fontWeight: FontWeight.w650', 'fontWeight: FontWeight.w700')
s = s.replace(
    'final persistenceSupport = math.min(100.0, persistenceSeconds / 90 * 100);',
    'final persistenceSupport = math.min(100.0, persistenceSeconds / 90 * 100).toDouble();',
)
s = s.replace(
    'final index = (snapshots.length - 1 - _offset).clamp(0, snapshots.length - 1);',
    'final index = (snapshots.length - 1 - _offset).clamp(0, snapshots.length - 1).toInt();',
)
s = s.replace('                      surface: colors.surfaceContainerHighest,\n', '')
s = s.replace('  final Color surface;\n', '')
s = s.replace('    required this.surface,\n', '')
p.write_text(s)

# 2) Wire the final calibre layer into Home without removing an existing card.
p = root / 'lib/screens/live_node_home_screen.dart'
s = p.read_text()
if "../widgets/calibre_upgrade_panels.dart" not in s:
    s = s.replace(
        "import '../widgets/biotic_stress_card.dart';\n",
        "import '../widgets/biotic_stress_card.dart';\nimport '../widgets/calibre_upgrade_panels.dart';\n",
    )
needle = """              CompetitionIntelligencePanels(\n                current: reading,\n                history: sensors.historyFor(reading.nodeId),\n                edge: edge,\n                telemetry: telemetry,\n                live: live,\n                connectionStatus: sensors.connectionStatus,\n              ),\n"""
addition = needle + """              const SizedBox(height: 12),\n              CalibreUpgradePanels(\n                current: reading,\n                history: sensors.historyFor(reading.nodeId),\n                edge: edge,\n                telemetry: telemetry,\n                live: live,\n                connectionStatus: sensors.connectionStatus,\n              ),\n"""
if 'CalibreUpgradePanels(' not in s:
    if needle not in s:
        raise SystemExit('Home integration anchor not found')
    s = s.replace(needle, addition, 1)
p.write_text(s)

# 3) Upgrade the simulator to the v2 intelligence payload + simulated telemetry.
p = root / 'lib/simulation/simulated_sensor_provider.dart'
s = p.read_text()
if "../models/hardware_telemetry.dart" not in s:
    s = s.replace(
        "import '../models/edge_intelligence.dart';\n",
        "import '../models/edge_intelligence.dart';\nimport '../models/hardware_telemetry.dart';\n",
    )
if "'simulation_intelligence_v2.dart'" not in s:
    s = s.replace(
        "import 'demo_mode.dart';\n",
        "import 'demo_mode.dart';\nimport 'simulation_intelligence_v2.dart';\n",
    )

getter_pattern = re.compile(
    r"  @override\n  EdgeIntelligence\? get edgeIntelligence \{.*?\n  @override\n  void start\(\) \{",
    re.S,
)
new_getters = """  @override\n  EdgeIntelligence? get edgeIntelligence {\n    final reading = current;\n    if (reading == null) return null;\n    final history = _history[_selectedNodeId] ?? const <SensorReading>[];\n    final crop = _selectedNodeId.startsWith('node-rice') ? 'Rice' : 'Tomato';\n    final stage = _selectedNodeId.startsWith('node-rice') ? 'tillering' : 'vegetative';\n    return SimulationIntelligenceV2.build(\n      reading: reading,\n      history: history,\n      mode: _mode,\n      crop: crop,\n      growthStage: stage,\n    );\n  }\n\n  @override\n  HardwareTelemetry? get hardwareTelemetry {\n    final reading = current;\n    if (reading == null) return null;\n    final history = _history[_selectedNodeId] ?? const <SensorReading>[];\n    final crop = _selectedNodeId.startsWith('node-rice') ? 'Rice' : 'Tomato';\n    final stage = _selectedNodeId.startsWith('node-rice') ? 'tillering' : 'vegetative';\n    return SimulationIntelligenceV2.buildTelemetry(\n      reading: reading,\n      history: history,\n      mode: _mode,\n      crop: crop,\n      growthStage: stage,\n    );\n  }\n\n  @override\n  void start() {"""
s, count = getter_pattern.subn(new_getters, s, count=1)
if count != 1:
    raise SystemExit(f'Expected one edge getter block, found {count}')

old_leaf = """    final leafWetness = switch (_mode) {\n      DemoMode.overwatered => (82 + noise(5)).clamp(0, 100).toDouble(),\n      DemoMode.lowLight => (52 + noise(7)).clamp(0, 100).toDouble(),\n      DemoMode.critical => (68 + noise(8)).clamp(0, 100).toDouble(),\n      _ => (14 + _max(0, humidity - 70) * 0.7 + noise(5))\n          .clamp(0, 100)\n          .toDouble(),\n    };\n"""
new_leaf = """    final leafWetness = switch (_mode) {\n      DemoMode.overwatered => (82 + noise(5)).clamp(0, 100).toDouble(),\n      DemoMode.bioticRisk => (90 + noise(4)).clamp(0, 100).toDouble(),\n      DemoMode.recovery => (30 + noise(5)).clamp(0, 100).toDouble(),\n      DemoMode.lowLight => (52 + noise(7)).clamp(0, 100).toDouble(),\n      DemoMode.critical => (68 + noise(8)).clamp(0, 100).toDouble(),\n      DemoMode.atmosphericDrying => (8 + noise(4)).clamp(0, 100).toDouble(),\n      DemoMode.bioResponse => (18 + noise(5)).clamp(0, 100).toDouble(),\n      _ => (14 + _max(0, humidity - 70) * 0.7 + noise(5))\n          .clamp(0, 100)\n          .toDouble(),\n    };\n"""
if old_leaf not in s:
    raise SystemExit('Leaf switch anchor not found')
s = s.replace(old_leaf, new_leaf, 1)

old_wet = """      ? switch (_mode) {\n            DemoMode.overwatered => 5.5 * 3600,\n            DemoMode.critical => 8.0 * 3600,\n            _ => 1.2 * 3600,\n          }\n"""
new_wet = """      ? switch (_mode) {\n            DemoMode.overwatered => 5.5 * 3600,\n            DemoMode.bioticRisk => 9.0 * 3600,\n            DemoMode.critical => 8.0 * 3600,\n            DemoMode.recovery => 1.0 * 3600,\n            _ => 1.2 * 3600,\n          }\n"""
if old_wet not in s:
    raise SystemExit('Wet-duration anchor not found')
s = s.replace(old_wet, new_wet, 1)

old_bio = """    final bioStability = switch (_mode) {\n      DemoMode.critical => (42 + noise(8)).clamp(0, 100).toDouble(),\n      DemoMode.dry => (68 + noise(6)).clamp(0, 100).toDouble(),\n      _ => (90 + noise(5)).clamp(0, 100).toDouble(),\n    };\n"""
new_bio = """    final bioStability = switch (_mode) {\n      DemoMode.baselineLearning => (96 + noise(2)).clamp(0, 100).toDouble(),\n      DemoMode.atmosphericDrying => (63 + noise(5)).clamp(0, 100).toDouble(),\n      DemoMode.heatStress => (57 + noise(6)).clamp(0, 100).toDouble(),\n      DemoMode.bioResponse => (43 + noise(6)).clamp(0, 100).toDouble(),\n      DemoMode.recovery => (80 + noise(4)).clamp(0, 100).toDouble(),\n      DemoMode.bioticRisk => (56 + noise(6)).clamp(0, 100).toDouble(),\n      DemoMode.critical => (38 + noise(8)).clamp(0, 100).toDouble(),\n      DemoMode.dry => (64 + noise(6)).clamp(0, 100).toDouble(),\n      _ => (90 + noise(5)).clamp(0, 100).toDouble(),\n    };\n"""
if old_bio not in s:
    raise SystemExit('Bio switch anchor not found')
s = s.replace(old_bio, new_bio, 1)

s = s.replace(
    "      healthStatus: 'starting',\n      soilRaw:",
    "      healthStatus: 'starting',\n      analysisOrigin: 'simulation',\n      recoveryActive: _mode == DemoMode.recovery,\n      vpdKpa: _calculateVpd(temperature, humidity),\n      bioticState: _mode == DemoMode.bioticRisk\n          ? 'POSSIBLE_BIOTIC_STRESS'\n          : 'NONE',\n      soilRaw:",
    1,
)
s = s.replace(
    "      bioBaselineReady: true,\n      bioBaselineSamples: 60,",
    "      bioBaselineReady:\n          !sensorFault && _mode != DemoMode.baselineLearning,\n      bioBaselineSamples:\n          _mode == DemoMode.baselineLearning ? 28 : 60,",
    1,
)
s = s.replace(
    "      bioSignalQuality: sensorFault ? 20 : 93,",
    "      bioSignalQuality: sensorFault\n          ? 20\n          : _mode == DemoMode.baselineLearning\n              ? 88\n              : 93,",
    1,
)
p.write_text(s)

print('Calibre integration patch applied successfully.')
