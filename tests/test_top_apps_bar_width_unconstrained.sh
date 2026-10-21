#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps unconstrained bar width: FAIL: $*" >&2; exit 1; }
widget="$ROOT/components/TopApps.qml"
shell="$ROOT/shell.qml"

# The rendered bar must use the configured length directly, not remaining row space.
grep -Fq 'property int barStartX: Math.max(45, Number(Config.topAppsBarX))' "$widget" || fail "bar X still depends on available row width"
grep -Fq 'width: Math.max(1, Number(Config.topAppsBarWidth))' "$widget" || fail "bar width is still clamped to remaining row space"

# The host window grows for the full bar extent, but not for a shifted value column.
grep -Fq 'readonly property int requiredContentWidth: Config.topAppsShowBars ? Math.ceil(' "$widget" || fail "required widget width is not exposed or ignores Show bars"
grep -Fq 'Number(Config.topAppsBarX) + Number(Config.topAppsBarWidth) + 20' "$widget" || fail "required width does not include the configured X and length"
if grep -Fq '+ root.valueColumnWidth(root.sectionEntries) + 25' "$widget"; then fail "bar width still reserves space by shifting the value column"; fi
grep -Fq 'contentWidth: Math.max(Settings.geometry.topAppsCpu[2], topAppsCpuView.requiredContentWidth)' "$shell" || fail "CPU Top Apps window does not expand for long bars"
grep -Fq 'contentWidth: Math.max(Settings.geometry.topAppsRam[2], topAppsRamView.requiredContentWidth)' "$shell" || fail "RAM Top Apps window does not expand for long bars"
grep -Fq 'x: root.layoutRowWidth - width' "$widget" || fail "value column is not anchored to the fixed logical row width"

# Exercise the layout: bar settings may grow the transparent host canvas, not the value column.
python3 - "$ROOT" <<'PYCODE'
for x, bar, value_width, should_overlap in ((103, 115, 72, False), (120, 180, 82, True), (240, 300, 96, True)):
    logical_width = 315
    row_width = logical_width - 20
    host_width = max(logical_width, x + bar + 20)
    value_start = row_width - value_width
    assert host_width >= x + bar + 20, (x, bar, host_width)
    assert value_start == (315 - 20 - value_width), (x, bar, value_start)
    assert (x + bar > value_start) == should_overlap, (x, bar, value_start)
PYCODE

echo "Top Apps unconstrained bar width: OK"
