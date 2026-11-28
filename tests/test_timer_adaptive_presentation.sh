#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
qml="$ROOT/components/TimerWidget.qml"
fail() { echo "Timer adaptive presentation: FAIL: $*" >&2; exit 1; }
for token in \
  'root.compactPresentation ? 0.9' \
  'root.widePresentation ? 1.05 : 1' \
  'readonly property int effectiveTimerRowSpacing' \
  'readonly property int effectiveTimerCommentGap' \
  'readonly property int effectiveTimerCommentWidth' \
  'root.effectiveTimerRowSpacing' \
  'root.effectiveTimerCommentGap' \
  'root.effectiveTimerCommentWidth'; do
  grep -Fq "$token" "$qml" || fail "missing $token"
done
# Regular mode must retain the configured baseline values.
grep -Fq ': Config.timerRowSpacing' "$qml" || fail "regular row spacing baseline missing"
grep -Fq ': Config.timerCommentGap' "$qml" || fail "regular comment gap baseline missing"
grep -Fq ': Config.timerCommentWidth' "$qml" || fail "regular comment width baseline missing"
# Countdown behavior and row interactions remain wired.
grep -Fq 'root.timerRowHeight' "$qml" || fail "adaptive row height is not used"
grep -Fq 'wheel.angleDelta.y > 0 ? "up" : "down"' "$qml" || fail "wheel adjustment handler missing"
grep -Fq 'Qt.LeftButton | Qt.MiddleButton | Qt.RightButton' "$qml" || fail "timer row mouse actions missing"
echo "Timer adaptive presentation: OK"
