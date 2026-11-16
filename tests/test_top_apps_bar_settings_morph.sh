#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"
fail() { echo "Top Apps bar settings morph: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$QML" || fail "shared MorphGeometry import missing"
for id in topAppsBarGeometryMorph topAppsBarColorsMorph; do
    grep -Fq "id: $id" "$QML" || fail "$id missing"
done
for id in topAppsBarGeometryContent topAppsBarColorsGroup; do
    grep -Fq "id: $id" "$QML" || fail "$id content target missing"
done
for block in topAppsBarGeometryMorph topAppsBarColorsMorph; do
    grep -Fq 'progress: Config.topAppsShowBars ? 1 : 0' "$QML" || fail "$block does not track the bar visibility toggle"
done
grep -Fq 'toGeometry: Qt.rect(0, 0, parent.width, topAppsBarGeometryContent.implicitHeight)' "$QML" || fail "bar geometry target height is not content-driven"
grep -Fq 'toGeometry: Qt.rect(0, 0, parent.width, topAppsBarColorsGroup.implicitHeight)' "$QML" || fail "bar colors target height is not frame-driven"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$QML" || fail "shared animation duration is not used"
grep -Fq 'animationEasing: Config.animationEasingType("standard", Config.topAppsShowBars ? "enter" : "exit")' "$QML" || fail "shared enter/exit easing is not used"
for key in topAppsBarX topAppsBarY topAppsBarHeight topAppsBarWidth; do
    grep -Fq "targetProperty: \"$key\"" "$QML" || fail "$key editor missing"
done
for key in topAppsCpuBarColor topAppsRamBarColor topAppsCpuBarTrackColor topAppsRamBarTrackColor; do
    grep -Fq "targetProperty: \"$key\"" "$QML" || fail "$key editor missing"
done
# The animated children must remain present while the parent clips their exit transition.
if grep -Fq 'visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2' "$QML"; then
    fail "individual bar controls still disappear before the morph finishes"
fi
# Existing settings writes must remain connected to the same toggle and editors.
grep -Fq 'Config.topAppsShowBars = checked; settings.save()' "$QML" || fail "bar visibility toggle save path changed"
echo "Top Apps bar settings MorphGeometry integration: OK"
