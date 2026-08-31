from pathlib import Path
import re

p = Path('competition/lib/simulation/simulated_sensor_provider.dart')
s = p.read_text()
s, count = re.subn(
    r"\n  String _trend\(double previous, double current\) \{.*?\n  \}\n\n  double _max",
    "\n  double _max",
    s,
    count=1,
    flags=re.S,
)
if count != 1:
    raise SystemExit(f'Expected one obsolete _trend helper, found {count}')
p.write_text(s)
print('Removed obsolete simulator helper.')
