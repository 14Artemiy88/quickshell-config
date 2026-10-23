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
assert 'Quickshell.iconPath(String(appDelegate.entry.icon), true)' in block, 'app icon resolution must return an empty source for missing theme icons'
assert 'appDelegate.itemData.kind === "app"' in block and 'String(source).length > 0' in block, 'only a non-empty native app icon should hide fallback glyphs'
assert 'Quickshell.iconPath(String(appDelegate.entry.icon))' not in block, 'unchecked iconPath can produce a missing-texture icon instead of the fallback'
assert 'image://icon/' not in s, 'old icon provider URL should not remain'
assert 'visible: !appIconImage.visible' in s, 'fallback glyph should appear when icon is unavailable'
assert 'text: \"󰀻\"' in s and 'appDelegate.itemData.kind === \"app\"' in s, 'generic app fallback should remain available for app entries'
assert 'id: projectFolderFallback' in s and 'height: 22' in s, 'cross-search projects need a font-independent vector folder icon'
assert 'appDelegate.itemData && appDelegate.itemData.project && appDelegate.itemData.project.icon' in s, 'custom project icon binding must be safe for non-project results'
assert 'id: runCommandFallback' in s and 'text: \">_\"' in s, 'cross-search commands need a font-independent terminal icon'
print('Launcher missing-icon fallback: OK')
PY
