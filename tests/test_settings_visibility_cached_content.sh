#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" "$ROOT/shell.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
shell = Path(sys.argv[2]).read_text(encoding="utf-8")
assert 'property bool cacheContent: false' in qml
assert 'layer.enabled: root.cacheContent' in qml
assert 'layer.smooth: root.cacheContent' in qml
start = shell.index('id: settingsVisibility')
chunk = shell[start:start + 700]
assert 'cacheContent: true' in chunk
assert 'animationStyle: Config.animationSettingsVisibilityStyle' in chunk
# Other panels keep the default, avoiding unnecessary texture layers.
assert 'cacheContent: true' not in shell[:start]
print("Settings panel uses cached content during slide transitions only: OK")
PY
