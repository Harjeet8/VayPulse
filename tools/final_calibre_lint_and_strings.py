from pathlib import Path
import re

root = Path('competition')

# Clean strict-analyzer issues in simulation intelligence.
p = root / 'lib/simulation/simulation_intelligence_v2.dart'
s = p.read_text()
s = s.replace('          ranked: [\n            RootCauseCandidate(name: \'High atmospheric drying demand\'',
              '          ranked: const [\n            RootCauseCandidate(name: \'High atmospheric drying demand\'', 1)
s = s.replace('          ranked: [\n            RootCauseCandidate(name: \'Root-zone moisture is low\'',
              '          ranked: const [\n            RootCauseCandidate(name: \'Root-zone moisture is low\'', 1)
s = s.replace('      case DemoMode.critical:\n        return _ScenarioAnalysis(',
              '      case DemoMode.critical:\n        return const _ScenarioAnalysis(', 1)
s = s.replace('              evidenceAgainst: analysis.secondaryCounterEvidence,\n', '')
s = s.replace('  final String? secondaryCounterEvidence;\n', '')
s = s.replace('    this.secondaryCounterEvidence,\n', '')
p.write_text(s)

# Remove unused local from Digital Plant Twin.
p = root / 'lib/widgets/calibre_upgrade_panels.dart'
s = p.read_text()
s = s.replace('    final colors = Theme.of(context).colorScheme;\n', '', 1)
p.write_text(s)

# Add polished labels for every new simulation scenario in both languages.
p = root / 'lib/l10n/app_strings.dart'
s = p.read_text()
keys = [
    'scenario_baseline_learning',
    'scenario_atmospheric_drying',
    'scenario_bio_response',
    'scenario_recovery',
    'scenario_biotic_risk',
]
if not all(f"'{key}':" in s for key in keys):
    matches = list(re.finditer(r"(?m)^(\s*)'scenario_healthy':\s*'[^']*',\s*$", s))
    if len(matches) < 2:
        raise SystemExit(f'Expected English and Tamil scenario_healthy markers, found {len(matches)}')

    inserts = [
        [
            "'scenario_baseline_learning': 'Baseline learning'",
            "'scenario_atmospheric_drying': 'Atmospheric drying demand'",
            "'scenario_bio_response': 'Plant electrical response'",
            "'scenario_recovery': 'Recovery'",
            "'scenario_biotic_risk': 'Biotic-risk environment'",
        ],
        [
            "'scenario_baseline_learning': 'Baseline கற்றல்'",
            "'scenario_atmospheric_drying': 'வளிமண்டல உலர்வு அழுத்தம்'",
            "'scenario_bio_response': 'செடி மின்சார பதில்'",
            "'scenario_recovery': 'மீட்பு'",
            "'scenario_biotic_risk': 'உயிரியல் ஆபத்து சூழல்'",
        ],
    ]
    # Insert from bottom to top so offsets stay stable.
    for idx in (1, 0):
        match = matches[idx]
        indent = match.group(1)
        addition = '\n' + '\n'.join(f"{indent}{line}," for line in inserts[idx])
        s = s[:match.end()] + addition + s[match.end():]

p.write_text(s)
print('Final calibre lint + simulation labels cleanup applied.')
