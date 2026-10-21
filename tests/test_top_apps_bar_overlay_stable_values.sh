#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps bar overlay stable values: FAIL: $*" >&2; exit 1; }
ui="$ROOT/components/TopApps.qml"
shell="$ROOT/shell.qml"

grep -Fq 'readonly property int layoutContentWidth:' "$ui" || fail "logical module width is missing"
grep -Fq 'readonly property int layoutRowWidth: Math.max(1, root.layoutContentWidth - 20)' "$ui" || fail "logical row width is not stable"
grep -Fq 'x: root.layoutRowWidth - width' "$ui" || fail "numeric values still anchor to the expanded host width"
grep -Fq 'Number(Config.topAppsBarX) + Number(Config.topAppsBarWidth) + 20' "$ui" || fail "host canvas does not fit the full bar extent"
# The bar must be drawn before the numeric Text, so the bar appears underneath it.
python3 - "$ui" <<'PYCODE'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
bar=s.index('id: usageBar')
value=s.index('x: root.layoutRowWidth - width')
assert bar < value, 'bar must be painted before values so it overlays underneath the text'
assert 'clip: false' in s[s.index('Primitives.ModuleFrame {'):s.index('Column {')], 'bar canvas must not be clipped at the original frame width'
PYCODE

grep -Fq 'contentWidth: Math.max(Settings.geometry.topAppsCpu[2], topAppsCpuView.requiredContentWidth)' "$shell" || fail "CPU host does not grow for full bar"
grep -Fq 'contentWidth: Math.max(Settings.geometry.topAppsRam[2], topAppsRamView.requiredContentWidth)' "$shell" || fail "RAM host does not grow for full bar"
echo "Top Apps bar overlay stable values: OK"
