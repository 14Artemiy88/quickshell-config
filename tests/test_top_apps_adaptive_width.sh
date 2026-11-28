#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps adaptive width: FAIL: $*" >&2; exit 1; }
widget="$ROOT/components/TopApps.qml"
shell="$ROOT/shell.qml"

# The actual host width must follow saved geometry; no configured bar can force
# the transparent surface to stay wider than the user-selected frame.
grep -Fq 'contentWidth: Settings.geometry.topAppsCpu[2]' "$shell" || fail "CPU Top Apps host width is not tied to saved geometry"
grep -Fq 'contentWidth: Settings.geometry.topAppsRam[2]' "$shell" || fail "RAM Top Apps host width is not tied to saved geometry"
if grep -Fq 'requiredContentWidth' "$widget" "$shell"; then fail "legacy host-width floor remains"; fi

grep -Fq 'readonly property real widthBudget:' "$widget" || fail "host width budget is not forwarded"
grep -Fq 'readonly property int layoutRowWidth: Math.max(1, root.layoutContentWidth - 20)' "$widget" || fail "row width is not derived from live host width"
grep -Fq 'readonly property int effectiveValueColumnWidth:' "$widget" || fail "value column does not adapt to narrow widths"
grep -Fq 'readonly property int effectiveBarStartX:' "$widget" || fail "bar start is not clamped to the available row"
grep -Fq 'readonly property int effectiveBarWidth:' "$widget" || fail "bar width is not constrained to remaining space"
grep -Fq 'visible: Config.topAppsShowBars && root.effectiveBarWidth > 0' "$widget" || fail "bar is not hidden when no safe width remains"
grep -Fq 'x: root.layoutRowWidth - width' "$widget" || fail "value column is not anchored to the live row width"

python3 - <<'PYCODE'
def layout(width, configured_x=103, configured_bar=115, value_width=72):
    row = max(1, width - 20)
    gap = max(2, min(5, round(row * .02)))
    value = max(1, min(value_width, row, max(28, int(row * .34))))
    min_bar = max(1, min(18, int(row * .10)))
    start = max(0, min(max(0, configured_x), max(0, row-value-gap-min_bar)))
    bar = max(0, min(configured_bar, row-value-gap-start))
    value_start = row-value
    assert start + bar <= value_start-gap, (width, start, bar, value_start, gap)
    assert value_start + value <= row, (width, value_start, value, row)
    return row, start, bar, value_start, value

for width in (315, 260, 240, 239, 230, 220, 200, 180, 160, 120, 80):
    layout(width)

# At the original size the user configuration is preserved; at smaller widths
# the bar contracts before it can collide with the right-aligned value column.
assert layout(315)[2] == 115
assert layout(240)[2] < 115
assert layout(200)[2] < layout(240)[2]
PYCODE

echo "Top Apps adaptive width: OK"
