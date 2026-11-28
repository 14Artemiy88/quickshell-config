#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps bar overlay stable values: FAIL: $*" >&2; exit 1; }
ui="$ROOT/components/TopApps.qml"
shell="$ROOT/shell.qml"

grep -Fq 'readonly property int layoutContentWidth:' "$ui" || fail "logical module width is missing"
grep -Fq 'readonly property int layoutRowWidth: Math.max(1, root.layoutContentWidth - 20)' "$ui" || fail "live row width is not derived from the host width"
grep -Fq 'x: root.layoutRowWidth - width' "$ui" || fail "numeric values do not anchor to the live host width"
grep -Fq 'readonly property int effectiveBarWidth:' "$ui" || fail "bar width is not constrained by live row extent"
# The bar must be drawn before the numeric Text, so the bar appears underneath it.
python3 - "$ui" <<'PYCODE'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
bar=s.index('id: usageBar')
value=s.index('x: root.layoutRowWidth - width')
assert bar < value, 'bar must be painted before values so it overlays underneath the text'
assert 'clip: false' in s[s.index('Primitives.ModuleFrame {'):s.index('Column {')], 'transparent bar canvas must remain unclipped by the frame'
assert 'visible: Config.topAppsShowBars && root.effectiveBarWidth > 0' in s, 'bar must be hidden rather than overlap the value column'
PYCODE

grep -Fq 'contentWidth: Settings.geometry.topAppsCpu[2]' "$shell" || fail "CPU host does not follow saved width"
grep -Fq 'contentWidth: Settings.geometry.topAppsRam[2]' "$shell" || fail "RAM host does not follow saved width"
echo "Top Apps bar overlay stable values: OK"
