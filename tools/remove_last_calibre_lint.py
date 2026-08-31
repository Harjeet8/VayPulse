from pathlib import Path
p = Path('competition/lib/simulation/simulation_intelligence_v2.dart')
s = p.read_text()
needle = "whatIf: 'If root-zone moisture improves, the system should verify whether heat or plant-response stress remains.',\n          ranked: const ["
replacement = "whatIf: 'If root-zone moisture improves, the system should verify whether heat or plant-response stress remains.',\n          ranked: ["
if needle not in s:
    raise SystemExit('Final lint anchor not found')
p.write_text(s.replace(needle, replacement, 1))
print('Removed final unnecessary const.')
