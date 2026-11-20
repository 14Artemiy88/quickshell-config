#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
fail() { echo "Top Apps value width single pass: FAIL: $*" >&2; exit 1; }
ui="$ROOT/components/TopApps.qml"

grep -Fq 'readonly property int sectionValueColumnWidth: root.valueColumnWidth(root.sectionEntries)' "$ui" || fail "section-level cached width is missing"
grep -Fq 'property int valueWidth: root.sectionValueColumnWidth' "$ui" || fail "delegate does not reuse cached width"
if grep -Fq 'root.valueColumnWidth(root.sectionEntries)' <(sed -n '/Repeater {/,/^[[:space:]]*}/p' "$ui"); then
    fail "value width is still recalculated within a Repeater"
fi

# The width calculation itself still performs one max-length scan, preserving
# support for large values and custom font sizes.
grep -Fq 'for (let i = 0; i < entries.length; ++i)' "$ui" || fail "single-pass max-length scan is missing"
grep -Fq 'maxLength * root.displayFontSize * 0.68 + 8' "$ui" || fail "font-aware sizing formula changed"

echo "Top Apps value width single pass: OK"
