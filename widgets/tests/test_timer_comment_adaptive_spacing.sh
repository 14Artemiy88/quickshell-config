#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Timer comment adaptive spacing: FAIL: $*" >&2; exit 1; }
qml="$ROOT/components/TimerWidget.qml"
[[ -f "$qml" ]] || fail "TimerWidget.qml missing"

# The countdown width must be derived from the real rendered string, so comments
# stay at a steady visual distance for values with different digit counts.
grep -Fq ': Math.ceil(textMetrics.advanceWidth) + 2' "$qml" || \
  fail "default countdown width is not based on measured text width"
grep -Fq 'id: textMetrics' "$qml" || fail "TextMetrics instance missing"
grep -Fq 'font.family: Config.ledFont' "$qml" || fail "metrics do not use the countdown font"
grep -Fq 'font.pixelSize: timerDisplay.displaySize' "$qml" || fail "metrics do not follow responsive countdown font size"
grep -Fq 'text: timerDisplay.displayText' "$qml" || fail "metrics do not measure the current countdown/sign text"
grep -Fq 'spacing: Config.timerCommentGap' "$qml" || fail "user-configurable comment spacing was removed"
if grep -Fq 'width: 100' "$qml"; then
  fail "fixed-width countdown column still present"
fi

echo "Timer comment adaptive spacing: OK"
