#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps value column width: FAIL: $*" >&2; exit 1; }
ui="$ROOT/components/TopApps.qml"

# A fixed 52 px column clipped values such as 1001.1 Mb to an ellipsis.
grep -Fq 'function valueColumnWidth(entries)' "$ui" || fail "dynamic value-column sizing function is missing"
grep -Fq 'maxLength * root.displayFontSize * 0.68 + 8' "$ui" || fail "value width does not account for longest text and configured font size"
grep -Fq 'width: root.valueColumnWidth(root.sectionEntries)' "$ui" || fail "value text is not bound to dynamic width"
grep -Fq 'elide: Text.ElideNone' "$ui" || fail "value text is still elided"
if grep -Eq 'width: 52|parent\.width - 52| - 52 - ' "$ui"; then
    fail "fixed 52 px value-column assumptions remain"
fi

# CPU/RAM display layout must reserve the same value column even with bars hidden.
grep -Fq 'parent.width - root.valueColumnWidth(root.sectionEntries) - 2 * appRow.spacing' "$ui" || fail "process name width ignores the value column when bars are hidden"
grep -Fq 'parent.width - 98 - 5 - root.valueColumnWidth(root.sectionEntries) - 5' "$ui" || fail "bar width ignores the dynamic value column"

echo "Top Apps value column width: OK"
