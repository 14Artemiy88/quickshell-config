#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps value column width: FAIL: $*" >&2; exit 1; }
ui="$ROOT/components/TopApps.qml"

# A fixed 52 px column clipped values such as 1001.1 Mb to an ellipsis.
grep -Fq 'function valueColumnWidth(entries)' "$ui" || fail "dynamic value-column sizing function is missing"
grep -Fq 'maxLength * root.displayFontSize * 0.68 + 8' "$ui" || fail "value width does not account for longest text and configured font size"
grep -Fq 'property int valueWidth: root.valueColumnWidth(root.sectionEntries)' "$ui" || fail "value column is not bound to dynamic width"
grep -Fq 'width: appRow.valueWidth' "$ui" || fail "value text is not bound to the calculated column width"
grep -Fq 'elide: Text.ElideNone' "$ui" || fail "value text is still elided"
if grep -Eq 'width: 52|parent\.width - 52| - 52 - ' "$ui"; then
    fail "fixed 52 px value-column assumptions remain"
fi

# The process name and values use the logical row width even when the host canvas grows.
grep -Fq 'root.layoutRowWidth - appRow.valueWidth - 2 * appRow.horizontalGap' "$ui" || fail "process name width ignores the value column when bars are hidden"
grep -Fq 'readonly property int layoutRowWidth:' "$ui" || fail "fixed logical row width is missing"
grep -Fq 'x: root.layoutRowWidth - width' "$ui" || fail "value column position changes with host width"
grep -Fq 'readonly property int requiredContentWidth:' "$ui" || fail "widget does not expose host width needed to draw the bar"

echo "Top Apps value column width: OK"
