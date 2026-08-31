from pathlib import Path

p = Path('competition/lib/simulation/simulation_intelligence_v2.dart')
text = p.read_text(encoding='utf-8')

if 'final String? secondaryCounterEvidence;' not in text:
    text = text.replace(
        '  final String? secondaryEvidence;\n',
        '  final String? secondaryEvidence;\n  final String? secondaryCounterEvidence;\n',
        1,
    )

if 'this.secondaryCounterEvidence,' not in text:
    text = text.replace(
        '    this.secondaryEvidence,\n',
        '    this.secondaryEvidence,\n    this.secondaryCounterEvidence,\n',
        1,
    )

needle = """              evidenceFor: analysis.secondaryEvidence,
            ),"""
replacement = """              evidenceFor: analysis.secondaryEvidence,
              evidenceAgainst: analysis.secondaryCounterEvidence,
            ),"""
if 'evidenceAgainst: analysis.secondaryCounterEvidence' not in text:
    if needle not in text:
        raise SystemExit('secondary candidate block not found')
    text = text.replace(needle, replacement, 1)

p.write_text(text, encoding='utf-8')
print('Simulation secondary counter-evidence model fixed')
