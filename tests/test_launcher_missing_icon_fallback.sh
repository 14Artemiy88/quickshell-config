#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="$ROOT/components/launcher/Launcher.qml"
python3 - "$FILE" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
start = s.index('id: appIconImage')
end = s.index('\n                            }', start)
block = s[start:end]
assert 'Quickshell.iconPath(String(appDelegate.entry.icon))' in block, 'app icon should resolve through Quickshell.iconPath'
assert 'visible: source !== ""' in block, 'empty icon path should hide image'
assert 'image://icon/' not in s, 'old icon provider URL should not remain'
assert 'visible: !appIconImage.visible' in s, 'fallback glyph should appear when icon is unavailable'
assert 'text: "󰀻"' in s, 'fallback glyph should be configured'
print('Launcher missing-icon fallback: OK')
PY
