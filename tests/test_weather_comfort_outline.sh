#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/WeatherNow.qml" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
start = s.index('id: weatherComfortLabel')
end = s.index('        }\n    }\n\n    Image {', start)
block = s[start:end]
assert 'property string comfortValue:' in block
assert 'property var outlineOffsets:' in block
assert 'Config.weatherComfortOutlineWidth' in block
assert 'color: Config.weatherComfortOutlineColor' in block
assert 'z: -1' in block
assert 'z: 1' in block
assert 'color: Config.textMuted' in block
assert 'style: Text.Outline' not in block, 'Qt Text.Outline has no configurable stroke width'
assert 'Math.max(0, Math.min(4' in block
assert 'var radius = thickness * 0.5' in block, 'one UI step must use a half-pixel radius so level 1 remains subtle'
assert 'var sampleCount = 8' in block
assert 'Math.cos(angle) * radius' in block and 'Math.sin(angle) * radius' in block
assert 'for (var oy = -thickness' not in block, 'do not use a full-pixel square grid for outline offsets'
assert 'visible: Config.weatherShowComfort && comfortValue !== ""' in block
print('Weather comfort temperature outline renderer: OK')
PY
