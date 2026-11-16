#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsVolumeSection.qml"
fail() { echo "Volume stream animation duration MorphGeometry: FAIL: $*" >&2; exit 1; }

for token in \
    'id: volumeStreamsAnimationDurationMorph' \
    'id: volumeStreamsAnimationDurationContent' \
    'Config.animationVolumeStreamsVisibilityStyle !== "none" || normalizedProgress > 0.001' \
    'progress: Config.animationVolumeStreamsVisibilityStyle !== "none" ? 1 : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'Config.animationEasingType("standard", Config.animationVolumeStreamsVisibilityStyle !== "none" ? "enter" : "exit")' \
    'targetProperty: "volumeStreamsAnimationDuration"'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done
[ "$(grep -Fc 'text: "Длительность (мс)"' "$QML")" -eq 1 ] || fail "duration editor duplicated or removed"
grep -Fq 'keys: ["animationVolumeStreamsVisibilityStyle", "volumeStreamsAnimationDuration"]' "$QML" || fail "animation style setting missing"
echo "Volume stream animation duration MorphGeometry integration: OK"
