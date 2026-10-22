#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/WeatherNow.qml" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
block=s[s.index('text: root.weather.temperature?.comfort?.C'):s.index('font.family: Config.ledFont', s.index('text: root.weather.temperature?.comfort?.C'))]
assert 'style: Text.Outline' in block
assert 'styleColor: Config.black' in block
assert 'styleColor: Config.background' not in block
print('Weather comfort temperature outline contrast: OK')
PY
