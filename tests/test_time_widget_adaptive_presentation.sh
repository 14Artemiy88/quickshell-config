#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/TimeWidget.qml"
fail() { echo "FAIL: $*" >&2; exit 1; }
grep -q 'timePresentationScale' "$FILE" || fail 'presentation scale missing'
grep -q 'root.compactPresentation ? 0.86' "$FILE" || fail 'compact scale missing'
grep -q 'root.widePresentation ? 1.04' "$FILE" || fail 'wide scale missing'
grep -q 'root.widePresentation ? 1.04 : 1.0' "$FILE" || fail 'regular-width clock size must preserve its configured baseline'
grep -q 'root.compactPresentation ? 0.86 : 1.0' "$FILE" || fail 'date scale must preserve the regular baseline'
grep -q 'configuredDateMetrics.width' "$FILE" || fail 'date width is not measured'
grep -q 'availableContentWidth - Math.ceil(configuredTimeMetrics.width) - 2 - 6' "$FILE" || fail 'date fitting does not account for the clock, gap, and right padding'
grep -q 'Math.ceil(.*' "$FILE" || fail 'clock width does not follow its measured text'
grep -q 'root.effectiveTimeWidth' "$FILE" || fail 'adaptive time width missing'
grep -q 'effectiveDateLayoutScale' "$FILE" || fail 'date-only responsive scale missing'
grep -q 'effectiveCompactLayoutScale' "$FILE" || fail 'compact layout must scale the combined time/date composition'
grep -q 'timePresentationScale \* effectiveCompactScale' "$FILE" || fail 'clock font must preserve regular scale and apply compact scaling only'
grep -q 'elide: Text.ElideRight' "$FILE" || fail 'date/weekday elision missing'
grep -q 'root.calendarRequested()' "$FILE" || fail 'calendar click action missing'
grep -q 'root.settingsRequested()' "$FILE" || fail 'settings click action missing'
grep -q 'root.clock.time' "$FILE" || fail 'clock time binding missing'
grep -q 'root.clock.dateText' "$FILE" || fail 'date binding missing'
grep -q 'root.clock.weekday' "$FILE" || fail 'weekday binding missing'
echo 'PASS: TimeWidget adaptive presentation contract'
