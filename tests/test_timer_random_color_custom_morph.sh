#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsTimersSection.qml"
fail() { echo "Timer random custom color MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'id: timerRandomCustomColorsMorph' "$QML" || fail "morph container missing"
grep -Fq 'id: timerRandomCustomColorsContent' "$QML" || fail "custom color content missing"
grep -Fq 'progress: Config.timerRandomColorMode === "custom" ? 1 : 0' "$QML" || fail "custom mode does not drive morph progress"
grep -Fq 'Config.timerRandomColorMode === "custom" || normalizedProgress > 0.001' "$QML" || fail "content is not retained during exit morph"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$QML" || fail "shared animation duration missing"
grep -Fq 'animationEasing: Config.animationEasingType("ease-out", Config.timerRandomColorMode === "custom" ? "enter" : "exit")' "$QML" || fail "shared enter/exit easing missing"
grep -Fq 'targetProperty: "timerRandomColorMin"' "$QML" || fail "minimum color editor missing"
grep -Fq 'targetProperty: "timerRandomColorMax"' "$QML" || fail "maximum color editor missing"
grep -Fq 'Config.timerRandomColorMode = ["full", "light", "dark", "custom"][index]' "$QML" || fail "mode selection/save path changed"
echo "Timer random custom color MorphGeometry integration: OK"
